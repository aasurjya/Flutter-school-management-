// ============================================================================
// supabase/functions/enforce-subscription
//
// Subscription enforcement gate. Called by:
//   • ai-gateway (before quota check) — blocks AI for free-tier over budget
//   • Flutter SubscriptionGuard (HTTP GET) — decides whether to show upgrade
//   • Razorpay webhook (internal) — flips tenant plan after payment
//
// Flow:
//   1. Auth: parse JWT, extract tenant_id from app_metadata.
//   2. Look up tenant_plan_limits(tenant_id) — returns plan row + is_paid.
//   3. Optionally check a feature flag: GET ?feature=whatsapp
//      → returns {allowed: bool, reason}
//   4. Optionally check student-count cap: POST {check: 'student_count'}
//      → returns {allowed, current, max}
//
// Returns a JSON verdict. Never blocks on RLS — that's the DB's job when
// tenants.enforcement_enabled = true. This fn is the *advisory* gate.
// ============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import {
  createClient,
  SupabaseClient,
} from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

interface PlanLimits {
  plan_id: string;
  display_name: string;
  max_students: number;
  ai_credits_usd: number;
  feature_flags: Record<string, boolean>;
  is_paid: boolean;
}

async function loadPlanLimits(
  supabase: SupabaseClient,
  tenantId: string,
): Promise<PlanLimits | null> {
  const { data, error } = await supabase.rpc('tenant_plan_limits', {
    p_tenant_id: tenantId,
  });
  if (error || !data || data.length === 0) return null;
  const row = data[0];
  return {
    plan_id: row.plan_id ?? 'free',
    display_name: row.display_name ?? 'Free',
    max_students: row.max_students ?? 100,
    ai_credits_usd: Number(row.ai_credits_usd ?? 0.5),
    feature_flags: row.feature_flags ?? {},
    is_paid: !!row.is_paid,
  };
}

function extractTenantId(req: Request): string | null {
  const authHeader = req.headers.get('authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) return null;
  const jwt = authHeader.replace(/^Bearer\s+/i, '');
  try {
    const parts = jwt.split('.');
    if (parts.length !== 3) return null;
    const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
    return (payload?.app_metadata?.tenant_id as string) ?? null;
  } catch (_) {
    return null;
  }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const tenantId = extractTenantId(req);
  if (!tenantId) {
    return jsonResponse({ allowed: false, reason: 'no_tenant_in_jwt' }, 403);
  }

  if (!SUPABASE_URL || !SERVICE_ROLE) {
    return jsonResponse({ allowed: false, reason: 'server_misconfigured' }, 500);
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { persistSession: false },
  });

  const limits = await loadPlanLimits(supabase, tenantId);
  if (!limits) {
    return jsonResponse({ allowed: false, reason: 'tenant_not_found' }, 404);
  }

  // ---- GET: feature-flag check -------------------------------------------------
  if (req.method === 'GET') {
    const url = new URL(req.url);
    const feature = url.searchParams.get('feature');
    if (feature) {
      const allowed = limits.feature_flags[feature] === true;
      return jsonResponse({
        allowed,
        reason: allowed ? 'ok' : 'feature_not_in_plan',
        plan: limits.plan_id,
        is_paid: limits.is_paid,
      });
    }
    // No feature param → return full plan summary
    return jsonResponse({
      allowed: true,
      plan: limits.plan_id,
      display_name: limits.display_name,
      is_paid: limits.is_paid,
      max_students: limits.max_students,
      ai_credits_usd: limits.ai_credits_usd,
      feature_flags: limits.feature_flags,
    });
  }

  // ---- POST: capacity / custom checks -----------------------------------------
  if (req.method === 'POST') {
    let body: { check?: string };
    try {
      body = await req.json();
    } catch (_) {
      return jsonResponse({ allowed: false, reason: 'invalid_json' }, 400);
    }

    if (body.check === 'student_count') {
      // Use the SECURITY DEFINER RPC — one round-trip, no RLS overhead.
      const { data: current, error } = await supabase.rpc(
        'get_student_count',
        { p_tenant_id: tenantId },
      );
      if (error) {
        return jsonResponse({ allowed: false, reason: 'count_failed' }, 500);
      }
      const count = (current as number) ?? 0;
      const allowed = count < limits.max_students;
      return jsonResponse({
        allowed,
        reason: allowed ? 'ok' : 'student_cap_reached',
        current: count,
        max: limits.max_students,
        plan: limits.plan_id,
      });
    }

    if (body.check === 'ai_budget') {
      // ai-gateway already enforces this via tenant_ai_usage count; this is
      // a pre-flight check for the UI to show remaining budget.
      const today = new Date().toISOString().slice(0, 10);
      const { count } = await supabase
        .from('tenant_ai_usage')
        .select('id', { count: 'exact', head: true })
        .eq('tenant_id', tenantId)
        .gte('created_at', today);
      return jsonResponse({
        allowed: (count ?? 0) < limits.ai_credits_usd,
        used_today: count ?? 0,
        budget: limits.ai_credits_usd,
        plan: limits.plan_id,
      });
    }

    return jsonResponse({ allowed: false, reason: 'unknown_check' }, 400);
  }

  return jsonResponse({ allowed: false, reason: 'method_not_allowed' }, 405);
});
