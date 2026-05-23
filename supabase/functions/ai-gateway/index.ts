// ============================================================================
// supabase/functions/ai-gateway
//
// Multi-model AI gateway. Sits between Flutter clients and OpenRouter.
//
// Flow per request:
//   1. Auth: parse JWT, extract tenant_id from app_metadata.
//   2. Idempotency: dedupe on (tenant_id, idempotency_key) → return cached row.
//   3. Quota: count today's tenant_ai_usage rows against tenant_ai_credits.budget_usd.
//   4. Chain lookup: feature_routes[feature_type].model_chain.
//   5. Walk chain: for each model, call OpenRouter chat completions.
//      Circuit-breaker: skip models marked degraded in the last 5 min.
//      Mark a model degraded after 3 consecutive failures in 5 min.
//   6. Log every outcome to tenant_ai_usage with status taxonomy.
//
// Secrets required on the Supabase project:
//   OPENROUTER_KEY        — single platform free key for demo phase
//   SUPABASE_URL          — auto-provisioned
//   SUPABASE_SERVICE_ROLE_KEY — auto-provisioned
// ============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ---- Config -----------------------------------------------------------------

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const OPENROUTER_KEY = Deno.env.get('OPENROUTER_KEY') ?? '';
const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';

// Circuit breaker tunables.
const DEGRADED_THRESHOLD = 3;        // consecutive failures within window
const DEGRADED_WINDOW_MS = 5 * 60_000; // 5 min
const REQUEST_TIMEOUT_MS = 30_000;   // hard ceiling per OpenRouter call

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-idempotency-key',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// In-memory degraded marker (process-local — fine, gateway has one instance
// per request burst; cross-instance staleness is at most 5 min).
const degradedSince = new Map<string, number>();
function markDegraded(model: string) {
  degradedSince.set(model, Date.now());
}
function isDegraded(model: string): boolean {
  const t = degradedSince.get(model);
  if (!t) return false;
  if (Date.now() - t > DEGRADED_WINDOW_MS) {
    degradedSince.delete(model);
    return false;
  }
  return true;
}

// ---- Types ------------------------------------------------------------------

interface GatewayRequest {
  feature_type: string;
  system_prompt: string;
  user_prompt: string;
  // Optional per-call overrides (server still validates against feature_routes).
  response_format?: 'text' | 'json_object';
  max_tokens?: number;
  temperature?: number;
  idempotency_key?: string;
}

interface GatewayResponse {
  text: string;
  model: string;
  status: 'success' | 'fallback' | 'cache_hit' | 'blocked_quota'
        | 'blocked_all_exhausted' | 'error_invalid_request';
  tokens_in?: number;
  tokens_out?: number;
  cost_usd?: number;
  latency_ms?: number;
}

interface ChainEntry {
  provider: string;
  model: string;
  tier: string;
}

// ---- Handler ----------------------------------------------------------------

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ status: 'error_invalid_request', message: 'method_not_allowed' }, 405);
  }

  if (!OPENROUTER_KEY) {
    return jsonResponse(
      { status: 'error_invalid_request', message: 'OPENROUTER_KEY not configured on gateway' },
      500,
    );
  }

  // ---- 1. Auth ---------------------------------------------------------------
  const authHeader = req.headers.get('authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return jsonResponse({ status: 'error_invalid_request', message: 'missing_bearer_token' }, 401);
  }
  const userJwt = authHeader.replace(/^Bearer\s+/i, '');

  // Decode JWT payload manually (we trust Supabase's edge runtime to have
  // validated the token signature already since the function is invoked via
  // the authenticated endpoint).
  let tenantId: string | null = null;
  try {
    const parts = userJwt.split('.');
    if (parts.length !== 3) throw new Error('jwt_malformed');
    const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
    tenantId = (payload?.app_metadata?.tenant_id as string) ?? null;
  } catch (_) {
    return jsonResponse({ status: 'error_invalid_request', message: 'jwt_decode_failed' }, 401);
  }
  if (!tenantId) {
    return jsonResponse({ status: 'error_invalid_request', message: 'no_tenant_in_jwt' }, 403);
  }

  // ---- 2. Parse body ---------------------------------------------------------
  let body: GatewayRequest;
  try {
    body = (await req.json()) as GatewayRequest;
  } catch (_) {
    return jsonResponse({ status: 'error_invalid_request', message: 'json_parse_failed' }, 400);
  }
  if (!body.feature_type || !body.user_prompt) {
    return jsonResponse(
      { status: 'error_invalid_request', message: 'feature_type and user_prompt required' },
      400,
    );
  }

  const db = createClient(SUPABASE_URL, SERVICE_ROLE, {
    global: { headers: { Authorization: `Bearer ${SERVICE_ROLE}` } },
  });

  const idempotencyKey =
    body.idempotency_key ?? req.headers.get('x-idempotency-key') ?? null;

  // ---- 3. Idempotency check --------------------------------------------------
  if (idempotencyKey) {
    const { data: prior } = await db
      .from('tenant_ai_usage')
      .select('model, status, cost_usd, tokens_in, tokens_out, error_message')
      .eq('tenant_id', tenantId)
      .eq('idempotency_key', idempotencyKey)
      .maybeSingle();
    if (prior) {
      // We don't persist the response text in tenant_ai_usage today (PII /
      // size); for cache-hit we return a synthetic body indicating the
      // original call already succeeded with the named model. Callers that
      // want the actual text must re-issue without an idempotency key — but
      // that's an anti-pattern; this branch should only fire when a flaky
      // client retried after a network blip post-server-success.
      return jsonResponse({
        text: '',
        model: prior.model as string,
        status: 'cache_hit',
        tokens_in: prior.tokens_in as number ?? undefined,
        tokens_out: prior.tokens_out as number ?? undefined,
        cost_usd: prior.cost_usd as number ?? undefined,
      } as GatewayResponse);
    }
  }

  // ---- 4. Quota gate ---------------------------------------------------------
  const { data: credits } = await db
    .from('tenant_ai_credits')
    .select('tier, budget_usd')
    .eq('tenant_id', tenantId)
    .maybeSingle();
  const dailyCap = (credits?.budget_usd as number) ?? 20; // demo default
  if (dailyCap > 0) {
    const startOfDay = new Date();
    startOfDay.setUTCHours(0, 0, 0, 0);
    const { count } = await db
      .from('tenant_ai_usage')
      .select('id', { count: 'exact', head: true })
      .eq('tenant_id', tenantId)
      .gte('created_at', startOfDay.toISOString());
    if ((count ?? 0) >= dailyCap) {
      await logUsage(db, {
        tenantId, featureType: body.feature_type, model: 'none',
        status: 'blocked_quota', idempotencyKey,
        errorMessage: `daily cap ${dailyCap} reached`,
      });
      return jsonResponse(
        {
          text: '',
          model: 'none',
          status: 'blocked_quota',
        } as GatewayResponse,
        429,
      );
    }
  }

  // ---- 5. Chain lookup -------------------------------------------------------
  const { data: route, error: routeErr } = await db
    .from('feature_routes')
    .select('model_chain, response_format, max_tokens, temperature, supports_tools')
    .eq('feature_type', body.feature_type)
    .maybeSingle();
  if (routeErr || !route) {
    return jsonResponse(
      {
        status: 'error_invalid_request',
        message: `unknown feature_type: ${body.feature_type}`,
      },
      400,
    );
  }
  const chain = (route.model_chain as ChainEntry[]) ?? [];
  if (chain.length === 0) {
    return jsonResponse(
      { status: 'error_invalid_request', message: 'feature has no models configured' },
      503,
    );
  }

  // ---- 6. Walk chain ---------------------------------------------------------
  const responseFormat = body.response_format ?? (route.response_format as string);
  const maxTokens = body.max_tokens ?? (route.max_tokens as number);
  const temperature = body.temperature ?? (route.temperature as number);

  let lastError: string | undefined;
  for (let i = 0; i < chain.length; i++) {
    const { model } = chain[i];

    if (isDegraded(model)) {
      lastError = `model ${model} is degraded; skipped`;
      continue;
    }

    const t0 = Date.now();
    try {
      const result = await callOpenRouter({
        model,
        systemPrompt: body.system_prompt,
        userPrompt: body.user_prompt,
        maxTokens,
        temperature,
        responseFormat,
      });
      const latency = Date.now() - t0;
      const status: GatewayResponse['status'] = i === 0 ? 'success' : 'fallback';

      await logUsage(db, {
        tenantId,
        featureType: body.feature_type,
        model,
        status,
        tokensIn: result.usage?.prompt_tokens,
        tokensOut: result.usage?.completion_tokens,
        latencyMs: latency,
        idempotencyKey,
      });

      return jsonResponse(
        {
          text: result.text,
          model,
          status,
          tokens_in: result.usage?.prompt_tokens,
          tokens_out: result.usage?.completion_tokens,
          latency_ms: latency,
        } as GatewayResponse,
        200,
      );
    } catch (e) {
      lastError = e instanceof Error ? e.message : String(e);
      // Record per-model failure for circuit-breaker accounting.
      const recentFailures = await countRecentFailures(db, model);
      if (recentFailures + 1 >= DEGRADED_THRESHOLD) {
        markDegraded(model);
      }
      await logUsage(db, {
        tenantId,
        featureType: body.feature_type,
        model,
        status: i === chain.length - 1 ? 'blocked_all_exhausted' : 'fallback',
        latencyMs: Date.now() - t0,
        idempotencyKey: i === chain.length - 1 ? idempotencyKey : null,
        errorMessage: lastError,
      });
      // Continue to next model.
    }
  }

  // Every model failed.
  return jsonResponse(
    {
      text: '',
      model: 'none',
      status: 'blocked_all_exhausted',
      latency_ms: 0,
    } as GatewayResponse,
    503,
  );
});

// ---- OpenRouter call --------------------------------------------------------

async function callOpenRouter(opts: {
  model: string;
  systemPrompt: string;
  userPrompt: string;
  maxTokens: number;
  temperature: number;
  responseFormat: string;
}): Promise<{ text: string; usage?: { prompt_tokens?: number; completion_tokens?: number } }> {
  const messages: Array<Record<string, string>> = [];
  if (opts.systemPrompt) {
    messages.push({ role: 'system', content: opts.systemPrompt });
  }
  messages.push({ role: 'user', content: opts.userPrompt });

  const requestBody: Record<string, unknown> = {
    model: opts.model,
    messages,
    max_tokens: opts.maxTokens,
    temperature: opts.temperature,
  };
  if (opts.responseFormat === 'json_object') {
    requestBody.response_format = { type: 'json_object' };
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const res = await fetch(OPENROUTER_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_KEY}`,
        'Content-Type': 'application/json',
        // OpenRouter analytics — optional but recommended per their docs.
        'HTTP-Referer': 'https://school-management.app',
        'X-Title': 'School Management SaaS',
      },
      body: JSON.stringify(requestBody),
      signal: controller.signal,
    });
    if (!res.ok) {
      const errBody = await res.text();
      throw new Error(`openrouter ${res.status}: ${errBody.slice(0, 200)}`);
    }
    const j = await res.json();
    const text = (j?.choices?.[0]?.message?.content as string) ?? '';
    if (!text) {
      throw new Error('openrouter empty content');
    }
    return { text, usage: j?.usage };
  } finally {
    clearTimeout(timeoutId);
  }
}

// ---- Helpers ---------------------------------------------------------------

interface LogUsageArgs {
  tenantId: string;
  featureType: string;
  model: string;
  status: string;
  tokensIn?: number;
  tokensOut?: number;
  latencyMs?: number;
  idempotencyKey?: string | null;
  errorMessage?: string;
}

async function logUsage(db: SupabaseClient, args: LogUsageArgs): Promise<void> {
  try {
    await db.from('tenant_ai_usage').insert({
      tenant_id: args.tenantId,
      feature_type: args.featureType,
      model: args.model,
      status: args.status,
      tokens_in: args.tokensIn,
      tokens_out: args.tokensOut,
      latency_ms: args.latencyMs,
      idempotency_key: args.idempotencyKey,
      error_message: args.errorMessage,
    });
  } catch (_) {
    // Logging failures must not break the request path.
  }
}

async function countRecentFailures(
  db: SupabaseClient,
  model: string,
): Promise<number> {
  const since = new Date(Date.now() - DEGRADED_WINDOW_MS).toISOString();
  const { count } = await db
    .from('tenant_ai_usage')
    .select('id', { count: 'exact', head: true })
    .eq('model', model)
    .gte('created_at', since)
    .in('status', ['blocked_all_exhausted', 'fallback']);
  return count ?? 0;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
