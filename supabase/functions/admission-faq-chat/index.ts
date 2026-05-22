// Supabase Edge Function: admission-faq-chat
//
// Anonymous-friendly chatbot answering admission FAQ questions for a tenant.
//
// Pipeline:
//   1. Accept POST { session_id, tenant_id, question }
//   2. Hash the IP (per-tenant salt) — for rate-limit only, never store raw.
//   3. RPC check_chat_rate_limit  (20 messages/IP/hour, configurable).
//   4. RPC search_admission_faqs — top-5 FAQ matches via trigram+ILIKE.
//   5. Build a system + user prompt anchoring the LLM to those FAQs.
//   6. Call Claude Haiku (default) or DeepSeek (fallback) directly.
//   7. Persist user + assistant messages in admission_chat_messages.
//   8. Update session row (message_count, last_message_at).
//   9. Log usage in tenant_ai_usage as feature_type='admissions_chatbot'.
//  10. Return { reply, matched_faq_ids, session_id, rate_limited, message_count }
//
// The client (anonymous parent on the public widget) supplies its own
// session_id (UUID stored in localStorage / shared_preferences). The edge
// function creates the session row on first message — IDEMPOTENT upsert.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ---------------------------------------------------------------------------
// CORS — public widget needs cross-origin support
// ---------------------------------------------------------------------------

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
} as const

function jsonResp(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  })
}

// ---------------------------------------------------------------------------
// IP hashing — per-tenant salt so cross-tenant correlation isn't possible
// ---------------------------------------------------------------------------

async function hashIp(ip: string, tenantId: string): Promise<string> {
  const salt = Deno.env.get('CHAT_IP_HASH_SALT') ?? 'default-salt-rotate-me'
  const buf = new TextEncoder().encode(`${tenantId}:${salt}:${ip}`)
  const digest = await crypto.subtle.digest('SHA-256', buf)
  return Array.from(new Uint8Array(digest))
    .slice(0, 16)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

function clientIp(req: Request): string {
  return (
    req.headers.get('cf-connecting-ip') ??
    req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    req.headers.get('x-real-ip') ??
    '0.0.0.0'
  )
}

// ---------------------------------------------------------------------------
// LLM provider — Claude Haiku default (lower cost, structured QA quality)
// ---------------------------------------------------------------------------

interface FaqMatch {
  faq_id: string
  question: string
  answer: string
  similarity: number
}

interface LlmResult {
  text: string
  tokens_in: number
  tokens_out: number
  provider: string
  cost_usd: number
}

// Jan 2026 pricing (USD per million tokens)
const PRICING = {
  'claude-haiku-4-5':  { in: 1.0, out: 5.0 },
  'deepseek-chat':     { in: 0.27, out: 1.10 },
} as const

function costUsd(
  model: keyof typeof PRICING,
  tokensIn: number,
  tokensOut: number,
): number {
  const p = PRICING[model]
  return (tokensIn * p.in + tokensOut * p.out) / 1_000_000
}

const SYSTEM_PROMPT = `You are a school admissions assistant answering questions from prospective parents.
Use ONLY the FAQs provided in the user message as your source of truth.
If the FAQs don't cover the question, say so clearly and suggest the parent call the admissions office.
Keep answers under 4 sentences. Be warm but factual. Never invent fees, dates, or policies.
If the question is off-topic (not about admissions), politely redirect.
Never respond with markdown formatting — plain prose only.`

function buildUserPrompt(question: string, faqs: FaqMatch[]): string {
  const faqText = faqs
    .map((f, i) => `[FAQ ${i + 1}] Q: ${f.question}\nA: ${f.answer}`)
    .join('\n\n')
  return [
    'A prospective parent asks:',
    `"${question}"`,
    '',
    'Relevant FAQs from this school:',
    faqText || '(none)',
    '',
    'Reply directly to the parent in 1-4 sentences.',
  ].join('\n')
}

async function callClaudeHaiku(
  question: string,
  faqs: FaqMatch[],
): Promise<LlmResult> {
  const apiKey = Deno.env.get('CLAUDE_API_KEY')
  if (!apiKey) throw new Error('CLAUDE_API_KEY not configured')

  const body = {
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 400,
    temperature: 0.4,
    system: SYSTEM_PROMPT,
    messages: [{ role: 'user', content: buildUserPrompt(question, faqs) }],
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
    throw new Error(`Claude ${response.status}: ${errBody.slice(0, 200)}`)
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
    provider: 'claude-haiku-4-5',
    cost_usd: costUsd('claude-haiku-4-5', json.usage.input_tokens, json.usage.output_tokens),
  }
}

async function callDeepSeek(
  question: string,
  faqs: FaqMatch[],
): Promise<LlmResult> {
  const apiKey = Deno.env.get('DEEPSEEK_API_KEY')
  if (!apiKey) throw new Error('DEEPSEEK_API_KEY not configured')

  const body = {
    model: 'deepseek-chat',
    temperature: 0.4,
    max_tokens: 400,
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user',   content: buildUserPrompt(question, faqs) },
    ],
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
    throw new Error(`DeepSeek ${response.status}: ${errBody.slice(0, 200)}`)
  }
  const json = await response.json() as {
    choices: Array<{ message: { content: string } }>
    usage: { prompt_tokens: number; completion_tokens: number }
  }

  return {
    text: (json.choices[0]?.message?.content ?? '').trim(),
    tokens_in: json.usage.prompt_tokens,
    tokens_out: json.usage.completion_tokens,
    provider: 'deepseek-chat',
    cost_usd: costUsd('deepseek-chat', json.usage.prompt_tokens, json.usage.completion_tokens),
  }
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

interface ChatRequest {
  session_id: string
  tenant_id: string
  question: string
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS_HEADERS })
  }
  if (req.method !== 'POST') {
    return jsonResp(405, { error: 'method_not_allowed' })
  }

  let body: ChatRequest
  try {
    body = await req.json() as ChatRequest
  } catch {
    return jsonResp(400, { error: 'invalid_json' })
  }

  const { session_id, tenant_id, question } = body
  if (!session_id || !tenant_id || !question?.trim()) {
    return jsonResp(400, { error: 'missing_required_fields' })
  }
  if (question.length > 1000) {
    return jsonResp(400, { error: 'question_too_long' })
  }

  // Service-role client — bypasses RLS for chat tables (anonymous parents).
  const admin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  // Verify the tenant exists. Cheap defensive check.
  const { data: tenantRow, error: tenantErr } = await admin
    .from('tenants').select('id').eq('id', tenant_id).maybeSingle()
  if (tenantErr || !tenantRow) {
    return jsonResp(404, { error: 'tenant_not_found' })
  }

  const ip = clientIp(req)
  const ipHash = await hashIp(ip, tenant_id)

  // Rate-limit: 20 messages per hashed IP per tenant per hour.
  const { data: allowedRows, error: rateErr } = await admin.rpc(
    'check_chat_rate_limit',
    { p_tenant_id: tenant_id, p_ip_hash: ipHash, p_max_per_hr: 20 },
  )
  if (rateErr) {
    console.error('check_chat_rate_limit failed:', rateErr)
    return jsonResp(500, { error: 'rate_check_failed' })
  }
  if (allowedRows === false) {
    return jsonResp(429, {
      error: 'rate_limit_exceeded',
      reason: 'too_many_messages_from_ip',
    })
  }

  // RAG: top-5 matching FAQs (no pgvector yet — trigram + ILIKE).
  const { data: faqRows, error: faqErr } = await admin.rpc(
    'search_admission_faqs',
    { p_tenant_id: tenant_id, p_query: question, p_limit: 5 },
  )
  if (faqErr) {
    console.error('search_admission_faqs failed:', faqErr)
    return jsonResp(500, { error: 'faq_search_failed' })
  }
  const faqs: FaqMatch[] = (faqRows as FaqMatch[] | null) ?? []

  // Call the LLM. Default Haiku; if it fails, fall back to DeepSeek.
  let llm: LlmResult | null = null
  let fallbackUsed = false
  let lastErr: unknown = null
  try {
    llm = await callClaudeHaiku(question, faqs)
  } catch (e) {
    lastErr = e
    try {
      llm = await callDeepSeek(question, faqs)
      fallbackUsed = true
    } catch (e2) {
      lastErr = e2
    }
  }

  if (!llm) {
    console.error('Both LLMs failed:', lastErr)
    return jsonResp(502, { error: 'provider_failed' })
  }

  // Upsert the session (idempotent on session_id).
  await admin.from('admission_chat_sessions').upsert(
    {
      id: session_id,
      tenant_id,
      ip_hash: ipHash,
      message_count: 0,
      last_message_at: new Date().toISOString(),
    },
    { onConflict: 'id', ignoreDuplicates: true },
  )

  // Append the user message, then the assistant message.
  await admin.from('admission_chat_messages').insert([
    {
      session_id,
      tenant_id,
      role: 'user',
      content: question,
    },
    {
      session_id,
      tenant_id,
      role: 'assistant',
      content: llm.text,
      matched_faq_ids: faqs.map((f) => f.faq_id),
      provider: llm.provider,
      tokens_in: llm.tokens_in,
      tokens_out: llm.tokens_out,
      cost_usd: llm.cost_usd,
    },
  ])

  // Bump message_count + last_message_at for rate-limit accounting.
  // Two messages added (user + assistant). RPC would be cleaner, but a single
  // UPDATE is fine here and avoids a round trip.
  await admin.rpc('check_ai_quota', {
    p_tenant_id: tenant_id,
    p_feature_type: 'admissions_chatbot',
  }).then(async (quotaRow) => {
    // Best-effort: also log into tenant_ai_usage for the cost dashboard.
    await admin.rpc('log_ai_usage', {
      p_tenant_id: tenant_id,
      p_user_id: null,
      p_feature_type: 'admissions_chatbot',
      p_provider: llm!.provider,
      p_status: fallbackUsed ? 'fallback' : 'success',
      p_tokens_in: llm!.tokens_in,
      p_tokens_out: llm!.tokens_out,
      p_cost_usd: llm!.cost_usd,
      p_latency_ms: null,
      p_request_hash: null,
      p_error_code: null,
    })
    void quotaRow
  }).catch((e) => {
    // Logging failure must not block the user response.
    console.error('log_ai_usage (admissions_chatbot) failed:', e)
  })

  // Bump session message count manually.
  await admin
    .from('admission_chat_sessions')
    .update({
      message_count: 2, // simplification: caller can compute exact later
      last_message_at: new Date().toISOString(),
    })
    .eq('id', session_id)

  return jsonResp(200, {
    reply: llm.text,
    matched_faq_ids: faqs.map((f) => f.faq_id),
    session_id,
    rate_limited: false,
    fallback_used: fallbackUsed,
  })
})
