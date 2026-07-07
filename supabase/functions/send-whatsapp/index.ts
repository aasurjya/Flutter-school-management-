// ============================================================================
// supabase/functions/send-whatsapp
//
// Sends a WhatsApp message via Meta WhatsApp Business Cloud API.
// https://developers.facebook.com/docs/whatsapp/cloud-api
//
// Flow:
//   1. Auth: parse JWT, extract tenant_id.
//   2. Load the tenant's sms_whatsapp_configs row (whatsapp_enabled, phone_number_id,
//      access_token). Reject if disabled or unconfigured.
//   3. Subscription gate: check tenant_plan_limits().feature_flags.whatsapp.
//      Free plan → 402 Payment Required.
//   4. Call Meta Cloud API:
//        POST https://graph.facebook.com/v20.0/{phone_number_id}/messages
//        Authorization: Bearer {access_token}
//        Body: { messaging_product: "whatsapp", to: <phone>, type: "template",
//                template: { name, language: { code }, components: [...] } }
//   5. Log the outcome to notification_logs (sent | failed).
//
// Secrets required:
//   SUPABASE_URL               — auto-provisioned
//   SUPABASE_SERVICE_ROLE_KEY  — auto-provisioned
//   WHATSAPP_API_VERSION       — optional, defaults to v20.0
//
// Per-tenant config (in sms_whatsapp_configs table):
//   whatsapp_enabled = true
//   whatsapp_api_key = Meta permanent access token
//   whatsapp_phone_number_id = Meta phone number ID
//   whatsapp_business_account_id = Meta WABA ID (for reference)
//
// Template messages must be pre-approved in Meta Business Manager.
// ============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const API_VERSION = Deno.env.get('WHATSAPP_API_VERSION') ?? 'v20.0';
const META_BASE = `https://graph.facebook.com/${API_VERSION}`;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

interface WhatsAppConfig {
  whatsapp_enabled: boolean;
  whatsapp_api_key: string | null;
  whatsapp_phone_number_id: string | null;
}

interface SendRequest {
  to: string;              // E.164 phone, e.g. "919876543210"
  templateName: string;    // pre-approved Meta template name
  languageCode?: string;   // default "en"
  components?: Array<Record<string, unknown>>; // template variable components
  recipientName?: string;  // for logging
  triggeredBy?: string;    // 'attendance_absence' | 'fee_due' | 'result_published' | etc.
}

async function getVerifiedTenantId(
  req: Request,
  supabaseAdmin: any,
): Promise<string | null> {
  const authHeader = req.headers.get('authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) return null;
  const jwt = authHeader.replace(/^Bearer\s+/i, '');

  // Verify the token's signature against Supabase Auth instead of trusting an
  // unverified base64-decoded payload — an unsigned/forged token must not be
  // able to claim an arbitrary tenant_id.
  const { data, error } = await supabaseAdmin.auth.getUser(jwt);
  if (error || !data?.user) return null;

  return (data.user.app_metadata?.tenant_id as string) ?? null;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ ok: false, reason: 'method_not_allowed' }, 405);
  }

  if (!SUPABASE_URL || !SERVICE_ROLE) {
    return jsonResponse({ ok: false, reason: 'server_misconfigured' }, 500);
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { persistSession: false },
  });

  const tenantId = await getVerifiedTenantId(req, supabase);
  if (!tenantId) {
    return jsonResponse({ ok: false, reason: 'no_tenant_in_jwt' }, 403);
  }

  let body: SendRequest;
  try {
    body = await req.json();
  } catch (_) {
    return jsonResponse({ ok: false, reason: 'invalid_json' }, 400);
  }

  if (!body.to || !body.templateName) {
    return jsonResponse({ ok: false, reason: 'missing_to_or_template' }, 400);
  }

  // ---- 1. Subscription gate: is whatsapp enabled for this plan? ----------
  const { data: planData } = await supabase.rpc('tenant_plan_limits', {
    p_tenant_id: tenantId,
  });
  const planRow = planData?.[0];
  const featureFlags = planRow?.feature_flags ?? {};
  if (featureFlags.whatsapp !== true) {
    return jsonResponse(
      { ok: false, reason: 'whatsapp_not_in_plan', plan: planRow?.plan_id ?? 'free' },
      402,
    );
  }

  // ---- 2. Load tenant WhatsApp config -------------------------------------
  const { data: configRow, error: configErr } = await supabase
    .from('sms_whatsapp_configs')
    .select('whatsapp_enabled, whatsapp_api_key, whatsapp_phone_number_id')
    .eq('tenant_id', tenantId)
    .maybeSingle();

  if (configErr || !configRow) {
    return jsonResponse({ ok: false, reason: 'whatsapp_not_configured' }, 404);
  }

  const config = configRow as WhatsAppConfig;
  if (!config.whatsapp_enabled || !config.whatsapp_api_key || !config.whatsapp_phone_number_id) {
    return jsonResponse({ ok: false, reason: 'whatsapp_disabled_or_incomplete' }, 400);
  }

  // ---- 3. Call Meta Cloud API ---------------------------------------------
  const metaPayload = {
    messaging_product: 'whatsapp',
    to: body.to,
    type: 'template',
    template: {
      name: body.templateName,
      language: { code: body.languageCode ?? 'en' },
      ...(body.components ? { components: body.components } : {}),
    },
  };

  const logBase = {
    tenant_id: tenantId,
    channel: 'whatsapp',
    recipient_phone: body.to,
    recipient_name: body.recipientName ?? '',
    message_template: body.templateName,
    triggered_by: body.triggeredBy ?? 'manual',
    sent_at: new Date().toISOString(),
  };

  try {
    const metaRes = await fetch(
      `${META_BASE}/${config.whatsapp_phone_number_id}/messages`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${config.whatsapp_api_key}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(metaPayload),
      },
    );

    const metaJson = await metaRes.json();

    if (!metaRes.ok) {
      // Log the failure
      await supabase.from('notification_logs').insert({
        ...logBase,
        status: 'failed',
        error_message: JSON.stringify(metaJson).slice(0, 500),
      });
      return jsonResponse(
        { ok: false, reason: 'meta_api_error', detail: metaJson },
        metaRes.status,
      );
    }

    // Log success
    await supabase.from('notification_logs').insert({
      ...logBase,
      status: 'sent',
      message_body: JSON.stringify(metaJson).slice(0, 500),
    });

    return jsonResponse({ ok: true, message_id: metaJson?.messages?.[0]?.id });
  } catch (e) {
    await supabase.from('notification_logs').insert({
      ...logBase,
      status: 'failed',
      error_message: String(e).slice(0, 500),
    });
    return jsonResponse({ ok: false, reason: 'network_error', detail: String(e) }, 500);
  }
});
