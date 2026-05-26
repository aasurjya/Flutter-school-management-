-- ============================================================================
-- 00067_feature_routes_paid_fallback.sql
--
-- Appends a cheap paid-GPT fallback tier to every feature_routes model_chain,
-- AFTER the existing free OpenRouter models. The ai-gateway walks the chain in
-- order, so each feature now degrades:
--
--   free OpenRouter model(s)  →  (on 429/5xx/exhausted)  →  cheap GPT  →  client fallback
--
-- All models route through OpenRouter (the gateway's only provider), so the
-- GPT models use the same server-side OPENROUTER_KEY — no key ever ships in the
-- client bundle. OpenRouter bills these (free models are free; gpt-4o-mini /
-- gpt-4.1-mini are paid), so the OpenRouter account needs credits for the
-- fallback to actually fire.
--
-- Ordered cheapest-first per OpenAI usage tiers:
--   1. openai/gpt-4o-mini   — cheapest broadly-capable chat model
--   2. openai/gpt-4.1-mini  — slightly stronger, still inexpensive
-- Both support tool calling and json_object response_format, so this is safe to
-- append to every feature regardless of supports_tools / response_format.
--
-- Idempotent: skips rows that already contain the gpt-4o-mini entry.
-- ============================================================================

UPDATE public.feature_routes
SET model_chain = model_chain || '[
  {"provider":"openrouter","model":"openai/gpt-4o-mini","tier":"cheap"},
  {"provider":"openrouter","model":"openai/gpt-4.1-mini","tier":"cheap"}
]'::jsonb
WHERE NOT (model_chain @> '[{"model":"openai/gpt-4o-mini"}]'::jsonb);
