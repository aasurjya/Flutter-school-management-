// ============================================================================
// supabase/functions/razorpay-webhook
//
// Razorpay webhook receiver for SaaS subscription payments.
//
// Flow:
//   1. Verify X-Razorpay-Signature using HMAC-SHA256(RAZORPAY_WEBHOOK_SECRET).
//   2. Parse the event payload. We only act on `payment.captured`.
//   3. Read notes.tenant_id + notes.plan_id + notes.kind='subscription'.
//      Ignore non-subscription payments (student fees are handled elsewhere).
//   4. Upsert subscription_invoices on razorpay_payment_id (idempotent).
//   5. On paid: bump tenants.subscription_plan + subscription_expires_at
//      (period_end = +1 year). The DB trigger syncs tenant_ai_credits.
//
// Secrets required:
//   RAZORPAY_WEBHOOK_SECRET  — from Razorpay dashboard webhook settings
//   SUPABASE_URL             — auto-provisioned
//   SUPABASE_SERVICE_ROLE_KEY — auto-provisioned
// ============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createHmac } from 'https://deno.land/std@0.168.0/node/crypto.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const WEBHOOK_SECRET = Deno.env.get('RAZORPAY_WEBHOOK_SECRET') ?? '';

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function verifySignature(rawBody: string, signature: string, secret: string): boolean {
  if (!secret || !signature) return false;
  const expected = createHmac('sha256', secret).update(rawBody).digest('hex');
  return expected === signature;
}

interface RazorpayWebhookEvent {
  event: string;
  payload: {
    payment: {
      entity: {
        id: string;            // pay_xxx
        order_id: string | null;
        status: string;        // captured | failed | ...
        amount: number;        // paise
        currency: string;
        notes?: Record<string, string>;
      };
    };
  };
}

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return jsonResponse({ ok: false, reason: 'method_not_allowed' }, 405);
  }

  const rawBody = await req.text();
  const signature = req.headers.get('x-razorpay-signature') ?? '';

  if (!verifySignature(rawBody, signature, WEBHOOK_SECRET)) {
    return jsonResponse({ ok: false, reason: 'invalid_signature' }, 401);
  }

  let event: RazorpayWebhookEvent;
  try {
    event = JSON.parse(rawBody) as RazorpayWebhookEvent;
  } catch (_) {
    return jsonResponse({ ok: false, reason: 'invalid_json' }, 400);
  }

  // Only act on captured payments. Razorpay retries webhooks; idempotency
  // is enforced by the unique index on razorpay_payment_id.
  if (event.event !== 'payment.captured') {
    return jsonResponse({ ok: true, skipped: true, reason: `ignored_event_${event.event}` });
  }

  const payment = event.payload?.payment?.entity;
  if (!payment) {
    return jsonResponse({ ok: false, reason: 'no_payment_entity' }, 400);
  }

  const notes = payment.notes ?? {};
  if (notes.kind !== 'subscription') {
    // Not a SaaS subscription payment — let student-fee handlers deal with it.
    return jsonResponse({ ok: true, skipped: true, reason: 'not_subscription' });
  }

  const tenantId = notes.tenant_id;
  const planId = notes.plan_id;
  if (!tenantId || !planId) {
    return jsonResponse({ ok: false, reason: 'missing_tenant_or_plan' }, 400);
  }

  if (!SUPABASE_URL || !SERVICE_ROLE) {
    return jsonResponse({ ok: false, reason: 'server_misconfigured' }, 500);
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { persistSession: false },
  });

  // Look up the plan to get the price + billing period.
  const { data: planRow, error: planErr } = await supabase
    .from('subscription_plans')
    .select('id, billing_period, price_inr_paise')
    .eq('id', planId)
    .eq('billing_period', 'yearly')
    .single();
  if (planErr || !planRow) {
    return jsonResponse({ ok: false, reason: 'plan_not_found' }, 404);
  }

  const periodStart = new Date();
  const periodEnd = new Date(periodStart);
  periodEnd.setFullYear(periodEnd.getFullYear() + 1);

  // 1. Upsert the subscription invoice (idempotent on razorpay_payment_id).
  const { error: upsertErr } = await supabase
    .from('subscription_invoices')
    .upsert(
      {
        tenant_id: tenantId,
        plan_id: planId,
        billing_period: 'yearly',
        amount_inr_paise: payment.amount,
        razorpay_payment_id: payment.id,
        razorpay_order_id: payment.order_id,
        status: 'paid',
        period_start: periodStart.toISOString(),
        period_end: periodEnd.toISOString(),
      },
      { onConflict: 'razorpay_payment_id' },
    );
  if (upsertErr) {
    return jsonResponse({ ok: false, reason: 'invoice_upsert_failed', detail: upsertErr.message }, 500);
  }

  // 2. Bump the tenant's plan + expiry. The DB trigger
  //    tg_sync_ai_credits_on_plan_change will sync tenant_ai_credits.
  const { error: tenantErr } = await supabase
    .from('tenants')
    .update({
      subscription_plan: planId,
      subscription_expires_at: periodEnd.toISOString(),
      is_active: true,
    })
    .eq('id', tenantId);
  if (tenantErr) {
    return jsonResponse({ ok: false, reason: 'tenant_update_failed', detail: tenantErr.message }, 500);
  }

  return jsonResponse({ ok: true, tenant_id: tenantId, plan_id: planId, period_end: periodEnd.toISOString() });
});
