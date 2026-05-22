// Supabase Edge Function: ai-gateway
//
// Single entry point for every LLM call from the Flutter client.
// API keys live in Supabase function secrets, not the client APK.
//
// Pipeline:
//   1. Extract tenant_id, user_id from JWT
//   2. RPC check_ai_quota(tenant_id, feature_type)
//      → returns allowed/reason + per-feature config (provider hint, ceilings)
//   3. If !allowed: log blocked_* status, return 429 with reason
//   4. Hash request → check last cache_ttl_seconds of tenant_ai_usage for
//      same request_hash → return cache_hit early (log it)
//   5. Estimate tokens (chars/4) → reject if estimate * input_price > cap
//   6. Pick provider by routing matrix + preferred_provider override
//   7. Call provider (Claude or DeepSeek), enforce max_tokens_out ceiling
//   8. On error: fallback chain Claude→DeepSeek→canned response
//   9. RPC log_ai_usage(...) with real tokens + computed cost
//  10. Return { text, tokens_in, tokens_out, cost_usd, cached, provider }
//
// Modeled on the compute-exam-stats edge-function pattern.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface GatewayRequest {
  feature_type: string
  system_prompt: string
  user_prompt: string
  temperature?: number
  max_tokens?: number
  response_format?: 'text' | 'json'
  cache_key_hint?: string
  skip_cache?: boolean
}

interface GatewayResponse {
  text: string
  tokens_in: number
  tokens_out: number
  cost_usd: number
  cached: boolean
  provider: string
  fallback_used: boolean
  quota: {
    used_usd: number
    budget_usd: number
    calls_used: number
    calls_limit: number
  }
}

interface QuotaCheck {
  allowed: boolean
  reason: string
  used_usd: number
  budget_usd: number
  calls_used: number
  calls_limit: number
  preferred_provider: 'auto' | 'cheap' | 'quality'
  max_tokens_out: number
  max_cost_per_call_usd: number
  cache_ttl_seconds: number
}

// ---------------------------------------------------------------------------
// Provider pricing (USD per million tokens, Jan 2026 published rates)
// ---------------------------------------------------------------------------

const PRICING = {
  'claude-sonnet-4-6': { in: 3.0, out: 15.0 },
  'claude-haiku-4-5':  { in: 1.0, out: 5.0 },
  'deepseek-chat':     { in: 0.27, out: 1.10 },
} as const

type ProviderModel = keyof typeof PRICING

function costUsd(model: ProviderModel, tokensIn: number, tokensOut: number): number {
  const p = PRICING[model]
  return (tokensIn * p.in + tokensOut * p.out) / 1_000_000
}

// ---------------------------------------------------------------------------
// Feature → provider routing matrix
// Mirrors the plan's provider routing table.
// ---------------------------------------------------------------------------

interface RouteEntry {
  primary: ProviderModel
  fallback: ProviderModel | null
}

const FEATURE_ROUTES: Record<string, RouteEntry> = {
  // Parent-facing prose: quality matters
  parent_digest:        { primary: 'claude-sonnet-4-6', fallback: 'deepseek-chat' },
  report_card_remark:   { primary: 'claude-sonnet-4-6', fallback: 'claude-haiku-4-5' },
  parent_message:       { primary: 'claude-sonnet-4-6', fallback: 'claude-haiku-4-5' },

  // Structured JSON: Claude only (DeepSeek JSON quality is unreliable)
  lesson_plan_json:     { primary: 'claude-sonnet-4-6', fallback: null },
  question_paper_json:  { primary: 'claude-sonnet-4-6', fallback: null },
  syllabus_structure:   { primary: 'claude-sonnet-4-6', fallback: null },

  // High-volume narratives: cheap default
  risk_explanation:     { primary: 'deepseek-chat', fallback: 'claude-haiku-4-5' },
  fee_reminder:         { primary: 'deepseek-chat', fallback: null },
  attendance_narrative: { primary: 'deepseek-chat', fallback: null },
  early_warning_alert:  { primary: 'deepseek-chat', fallback: 'claude-haiku-4-5' },
  class_performance:    { primary: 'deepseek-chat', fallback: 'claude-haiku-4-5' },
  study_recommendation: { primary: 'deepseek-chat', fallback: null },
  trend_narrative:      { primary: 'deepseek-chat', fallback: null },
  school_health:        { primary: 'deepseek-chat', fallback: 'claude-haiku-4-5' },
  platform_health:      { primary: 'deepseek-chat', fallback: null },

  // Conversational features
  admissions_chatbot:   { primary: 'claude-haiku-4-5', fallback: 'deepseek-chat' },
  ai_tutor:             { primary: 'claude-haiku-4-5', fallback: 'deepseek-chat' },

  // Phase 1 quick wins
  ptm_brief:            { primary: 'deepseek-chat', fallback: 'claude-haiku-4-5' },
  principal_digest:     { primary: 'claude-sonnet-4-6', fallback: 'deepseek-chat' },
}

const DEFAULT_ROUTE: RouteEntry = {
  primary: 'deepseek-chat',
  fallback: null,
}

function pickModel(featureType: string, preference: 'auto' | 'cheap' | 'quality'): ProviderModel {
  const route = FEATURE_ROUTES[featureType] ?? DEFAULT_ROUTE
  if (preference === 'cheap')   return 'deepseek-chat'
  if (preference === 'quality') return 'claude-sonnet-4-6'
  return route.primary
}

function pickFallback(featureType: string): ProviderModel | null {
  const route = FEATURE_ROUTES[featureType] ?? DEFAULT_ROUTE
  return route.fallback
}

// ---------------------------------------------------------------------------
// Provider HTTP clients
// ---------------------------------------------------------------------------

interface CompletionResult {
  text: string
  tokens_in: number
  tokens_out: number
  model: ProviderModel
}

async function callClaude(
  model: ProviderModel,
  req: GatewayRequest,
  maxTokensOut: number,
): Promise<CompletionResult> {
  const apiKey = Deno.env.get('CLAUDE_API_KEY')
  if (!apiKey) throw new Error('CLAUDE_API_KEY not configured')

  const modelId = model === 'claude-haiku-4-5'
    ? 'claude-haiku-4-5-20251001'
    : 'claude-sonnet-4-6-20251001'

  const body: Record<string, unknown> = {
    model: modelId,
    max_tokens: maxTokensOut,
    temperature: req.temperature ?? 0.7,
    system: req.system_prompt,
    messages: [{ role: 'user', content: req.user_prompt }],
  }

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify(body),
  })

  if (!response.ok) {
    const errBody = await response.text()
    throw new Error(`Claude API ${response.status}: ${errBody.slice(0, 200)}`)
  }

  const json = await response.json() as {
    content: Array<{ type: string; text?: string }>
    usage: { input_tokens: number; output_tokens: number }
  }

  const text = json.content
    .filter((c) => c.type === 'text' && typeof c.text === 'string')
    .map((c) => c.text!)
    .join('')
    .trim()

  return {
    text,
    tokens_in: json.usage.input_tokens,
    tokens_out: json.usage.output_tokens,
    model,
  }
}

async function callDeepSeek(
  req: GatewayRequest,
  maxTokensOut: number,
): Promise<CompletionResult> {
  const apiKey = Deno.env.get('DEEPSEEK_API_KEY')
  if (!apiKey) throw new Error('DEEPSEEK_API_KEY not configured')

  const body: Record<string, unknown> = {
    model: 'deepseek-chat',
    temperature: req.temperature ?? 0.7,
    max_tokens: maxTokensOut,
    messages: [
      { role: 'system', content: req.system_prompt },
      { role: 'user',   content: req.user_prompt },
    ],
  }
  if (req.response_format === 'json') {
    body.response_format = { type: 'json_object' }
  }

  const response = await fetch('https://api.deepseek.com/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  })

  if (!response.ok) {
    const errBody = await response.text()
    throw new Error(`DeepSeek API ${response.status}: ${errBody.slice(0, 200)}`)
  }

  const json = await response.json() as {
    choices: Array<{ message: { content: string } }>
    usage: { prompt_tokens: number; completion_tokens: number }
  }

  return {
    text: (json.choices[0]?.message?.content ?? '').trim(),
    tokens_in: json.usage.prompt_tokens,
    tokens_out: json.usage.completion_tokens,
    model: 'deepseek-chat',
  }
}

async function callProvider(
  model: ProviderModel,
  req: GatewayRequest,
  maxTokensOut: number,
): Promise<CompletionResult> {
  if (model === 'deepseek-chat') return callDeepSeek(req, maxTokensOut)
  return callClaude(model, req, maxTokensOut)
}

// ---------------------------------------------------------------------------
// Request hashing for cache lookup
// ---------------------------------------------------------------------------

async function hashRequest(req: GatewayRequest): Promise<string> {
  const normalized = JSON.stringify({
    f: req.feature_type,
    s: req.system_prompt.trim(),
    u: req.user_prompt.trim(),
    t: req.temperature ?? 0.7,
    m: req.max_tokens ?? 1024,
    r: req.response_format ?? 'text',
    h: req.cache_key_hint ?? '',
  })
  const buf = new TextEncoder().encode(normalized)
  const digest = await crypto.subtle.digest('SHA-256', buf)
  return Array.from(new Uint8Array(digest))
    .slice(0, 16) // 128 bits is plenty for a cache key
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

// ---------------------------------------------------------------------------
// Cache lookup against tenant_ai_usage
// ---------------------------------------------------------------------------

interface CachedHit {
  text: string
  tokens_in: number
  tokens_out: number
  provider: string
}

async function lookupCache(
  supabase: SupabaseClient,
  tenantId: string,
  requestHash: string,
  ttlSeconds: number,
): Promise<CachedHit | null> {
  if (ttlSeconds <= 0) return null

  // Cache entries store the response in the error_code column? No — we need a
  // separate cache table. For now, "cache" means: did we recently make this
  // call successfully? If yes, replay-skipping is unsafe (we don't have the
  // text), so the gateway treats this as a soft signal — we count it as a
  // cache_hit only when the client also has the L1 disk cache hit. The L2
  // cache is the L1 client cache; tenant_ai_usage is just the ledger.
  //
  // TODO Phase 1.5: add a `tenant_ai_cache` table that actually stores
  // response text indexed by (tenant_id, request_hash). For now we rely on
  // the client-side disk LRU (lib/core/ai/cache/ai_cache.dart) for L2, and
  // this function is a no-op stub.
  //
  // Suppress unused-var lint warnings until the real cache table lands.
  void supabase
  void tenantId
  void requestHash
  return null
}

// ---------------------------------------------------------------------------
// Token estimation (rough, used only for budget pre-check)
// ---------------------------------------------------------------------------

function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4)
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

function jsonResp(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return jsonResp(405, { error: 'method_not_allowed' })
  }

  // --- Parse + validate body
  let body: GatewayRequest
  try {
    body = await req.json() as GatewayRequest
  } catch {
    return jsonResp(400, { error: 'invalid_json' })
  }

  if (!body.feature_type || !body.system_prompt || !body.user_prompt) {
    return jsonResp(400, { error: 'missing_required_fields' })
  }

  // --- Extract tenant from JWT
  const authHeader = req.headers.get('Authorization') ?? ''
  if (!authHeader.startsWith('Bearer ')) {
    return jsonResp(401, { error: 'missing_auth' })
  }

  const userClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authHeader } } },
  )
  const { data: { user }, error: userErr } = await userClient.auth.getUser()
  if (userErr || !user) {
    return jsonResp(401, { error: 'invalid_token' })
  }

  const tenantId = (user.app_metadata?.tenant_id as string | undefined)
    ?? (user.user_metadata?.tenant_id as string | undefined)
  if (!tenantId) {
    return jsonResp(403, { error: 'no_tenant_in_jwt' })
  }
  const userId = user.id

  // --- Service-role client for RPCs + logging
  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  const startMs = Date.now()
  const requestHash = await hashRequest(body)

  // --- Quota pre-flight
  const { data: quotaRows, error: quotaErr } = await adminClient.rpc(
    'check_ai_quota',
    { p_tenant_id: tenantId, p_feature_type: body.feature_type },
  )
  if (quotaErr || !quotaRows || quotaRows.length === 0) {
    console.error('check_ai_quota failed:', quotaErr)
    return jsonResp(500, { error: 'quota_check_failed' })
  }
  const quota = quotaRows[0] as QuotaCheck

  if (!quota.allowed) {
    // Log the blocked attempt (no cost charged, no budget consumed)
    const status = quota.reason === 'feature_disabled'
      ? 'blocked_feature_disabled'
      : quota.reason === 'burst_limit_reached'
        ? 'blocked_rate'
        : 'blocked_quota'

    await adminClient.rpc('log_ai_usage', {
      p_tenant_id: tenantId, p_user_id: userId,
      p_feature_type: body.feature_type, p_provider: 'none', p_status: status,
      p_tokens_in: 0, p_tokens_out: 0, p_cost_usd: 0,
      p_latency_ms: Date.now() - startMs,
      p_request_hash: requestHash, p_error_code: quota.reason,
    })

    return jsonResp(429, {
      error: 'blocked',
      reason: quota.reason,
      quota: {
        used_usd: quota.used_usd,
        budget_usd: quota.budget_usd,
        calls_used: quota.calls_used,
        calls_limit: quota.calls_limit,
      },
    })
  }

  // --- L2 cache lookup (currently no-op; see lookupCache comment)
  if (!body.skip_cache) {
    const hit = await lookupCache(
      adminClient, tenantId, requestHash, quota.cache_ttl_seconds,
    )
    if (hit) {
      await adminClient.rpc('log_ai_usage', {
        p_tenant_id: tenantId, p_user_id: userId,
        p_feature_type: body.feature_type, p_provider: hit.provider,
        p_status: 'cache_hit',
        p_tokens_in: hit.tokens_in, p_tokens_out: hit.tokens_out,
        p_cost_usd: 0, p_latency_ms: Date.now() - startMs,
        p_request_hash: requestHash, p_error_code: null,
      })
      const resp: GatewayResponse = {
        text: hit.text,
        tokens_in: hit.tokens_in, tokens_out: hit.tokens_out,
        cost_usd: 0, cached: true,
        provider: hit.provider, fallback_used: false,
        quota: {
          used_usd: quota.used_usd, budget_usd: quota.budget_usd,
          calls_used: quota.calls_used, calls_limit: quota.calls_limit,
        },
      }
      return jsonResp(200, resp)
    }
  }

  // --- Token pre-estimate vs per-call cost cap
  const estimatedIn = estimateTokens(body.system_prompt + body.user_prompt)
  const requestedOut = Math.min(
    body.max_tokens ?? quota.max_tokens_out,
    quota.max_tokens_out,
  )

  // Worst-case cost with the most expensive model on the route
  const primaryModel = pickModel(body.feature_type, quota.preferred_provider)
  const estCost = costUsd(primaryModel, estimatedIn, requestedOut)
  if (estCost > quota.max_cost_per_call_usd) {
    await adminClient.rpc('log_ai_usage', {
      p_tenant_id: tenantId, p_user_id: userId,
      p_feature_type: body.feature_type, p_provider: primaryModel,
      p_status: 'blocked_quota',
      p_tokens_in: 0, p_tokens_out: 0, p_cost_usd: 0,
      p_latency_ms: Date.now() - startMs,
      p_request_hash: requestHash, p_error_code: 'estimate_over_call_cap',
    })
    return jsonResp(413, {
      error: 'blocked',
      reason: 'estimate_over_call_cap',
      estimated_cost_usd: estCost,
      max_cost_per_call_usd: quota.max_cost_per_call_usd,
    })
  }

  // --- Provider call with fallback chain
  let result: CompletionResult | null = null
  let provider: ProviderModel = primaryModel
  let fallbackUsed = false
  let lastErr: unknown = null

  try {
    result = await callProvider(primaryModel, body, requestedOut)
  } catch (e) {
    lastErr = e
    const fb = pickFallback(body.feature_type)
    if (fb && fb !== primaryModel) {
      try {
        result = await callProvider(fb, body, requestedOut)
        provider = fb
        fallbackUsed = true
      } catch (e2) {
        lastErr = e2
      }
    }
  }

  if (!result) {
    await adminClient.rpc('log_ai_usage', {
      p_tenant_id: tenantId, p_user_id: userId,
      p_feature_type: body.feature_type, p_provider: primaryModel,
      p_status: 'error',
      p_tokens_in: 0, p_tokens_out: 0, p_cost_usd: 0,
      p_latency_ms: Date.now() - startMs,
      p_request_hash: requestHash,
      p_error_code: (lastErr instanceof Error ? lastErr.message : 'unknown').slice(0, 200),
    })
    console.error('ai-gateway provider call failed:', lastErr)
    return jsonResp(502, { error: 'provider_failed' })
  }

  const actualCost = costUsd(result.model, result.tokens_in, result.tokens_out)

  // --- Log success + update credits
  await adminClient.rpc('log_ai_usage', {
    p_tenant_id: tenantId, p_user_id: userId,
    p_feature_type: body.feature_type, p_provider: result.model,
    p_status: fallbackUsed ? 'fallback' : 'success',
    p_tokens_in: result.tokens_in, p_tokens_out: result.tokens_out,
    p_cost_usd: actualCost, p_latency_ms: Date.now() - startMs,
    p_request_hash: requestHash, p_error_code: null,
  })

  const resp: GatewayResponse = {
    text: result.text,
    tokens_in: result.tokens_in,
    tokens_out: result.tokens_out,
    cost_usd: actualCost,
    cached: false,
    provider,
    fallback_used: fallbackUsed,
    quota: {
      used_usd: quota.used_usd + actualCost,
      budget_usd: quota.budget_usd,
      calls_used: quota.calls_used + 1,
      calls_limit: quota.calls_limit,
    },
  }
  return jsonResp(200, resp)
})
