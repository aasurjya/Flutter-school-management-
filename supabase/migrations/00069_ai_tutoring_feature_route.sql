-- ============================================================================
-- 00069_ai_tutoring_feature_route.sql
--
-- Adds the `ai_tutoring` feature_route so the ai-gateway accepts AI Tutor
-- chat requests (see lib/features/ai_tutoring). Conversational text task — no
-- tools, not agentic; the student's question + recent transcript are folded
-- into the user prompt by the Flutter client.
--
-- Re-runnable (ON CONFLICT). Depends on 00066 (feature_routes table) and
-- 00068 (agentic columns).
-- ============================================================================
INSERT INTO public.feature_routes
  (feature_type, display_name, model_chain, response_format, max_tokens,
   temperature, supports_tools, agentic_mode, tools, branch_cap,
   max_tool_iterations, notes)
VALUES
  ('ai_tutoring',
   'AI Tutor (student Q&A)',
   '[
     {"provider":"openrouter","model":"meta-llama/llama-4-maverick:free","tier":"free"},
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"},
     {"provider":"openrouter","model":"mistralai/mistral-small-3.1:free","tier":"free"}
   ]'::jsonb,
   'text', 700, 0.6, false, false, '[]'::jsonb, 1, 4,
   'Conversational tutoring. Warm, step-by-step. Transcript folded into the user prompt client-side.')
ON CONFLICT (feature_type) DO UPDATE SET
  display_name    = EXCLUDED.display_name,
  model_chain     = EXCLUDED.model_chain,
  response_format = EXCLUDED.response_format,
  max_tokens      = EXCLUDED.max_tokens,
  temperature     = EXCLUDED.temperature,
  notes           = EXCLUDED.notes;
