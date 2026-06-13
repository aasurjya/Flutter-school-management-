-- ============================================================================
-- 00068_feature_routes_agentic.sql
--
-- Adds the agentic tool-calling substrate to feature_routes.
--
--   • agentic_mode        — opt-in flag. When true AND the request carries
--                           mode:"agentic", the gateway runs a bounded,
--                           read-only server-side tool loop instead of a
--                           single-shot completion.
--   • tools               — allow-list of read-only tool NAMES this feature may
--                           call. The gateway maps each name to a fixed,
--                           tenant-scoped SELECT (see ai-gateway/tools.ts).
--                           Storing names (not SQL) keeps the catalog
--                           server-controlled: the model can never widen scope.
--   • branch_cap          — max parallel branches for FUTURE branch/merge
--                           (orchestrator-workers + evaluator). v1 keeps 1
--                           (single agent). >1 is the Phase-C escalation,
--                           reserved for high-value batch features.
--   • max_tool_iterations — hard ceiling on tool-loop rounds; bounds cost
--                           (multi-call agentic requests can be ~15x a chat).
--
-- Non-breaking: with these at their defaults the existing single-shot path is
-- unchanged. Re-runnable (IF NOT EXISTS + ON CONFLICT).
-- ============================================================================

ALTER TABLE public.feature_routes
  ADD COLUMN IF NOT EXISTS agentic_mode        BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS tools               JSONB   NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS branch_cap          INT     NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS max_tool_iterations INT     NOT NULL DEFAULT 4;

-- Constraints added separately so re-runs don't error if they already exist.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'feature_routes_branch_cap_chk'
  ) THEN
    ALTER TABLE public.feature_routes
      ADD CONSTRAINT feature_routes_branch_cap_chk CHECK (branch_cap BETWEEN 1 AND 3);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'feature_routes_max_tool_iter_chk'
  ) THEN
    ALTER TABLE public.feature_routes
      ADD CONSTRAINT feature_routes_max_tool_iter_chk CHECK (max_tool_iterations BETWEEN 1 AND 8);
  END IF;
END$$;

COMMENT ON COLUMN public.feature_routes.agentic_mode IS
  'When true, requests with mode:"agentic" run a bounded read-only tool loop.';
COMMENT ON COLUMN public.feature_routes.tools IS
  'Allow-list of read-only tool names (see ai-gateway/tools.ts). Names only, never SQL.';
COMMENT ON COLUMN public.feature_routes.branch_cap IS
  'Max parallel branches for branch/merge orchestration. 1 = single agent (v1).';
COMMENT ON COLUMN public.feature_routes.max_tool_iterations IS
  'Hard ceiling on tool-loop rounds; bounds cost of multi-call agentic requests.';

-- ----------------------------------------------------------------------------
-- Seed the first agentic feature: "Ask Campusly" — a data Q&A assistant that
-- can read (read-only) student records, attendance, marks, and fee status
-- under tenant RLS. Reuses the two free OpenRouter models that support tool
-- calling (Nemotron + Gemma-4, same as attendance_analytics / library).
--
-- A paid Grok fallback (grok-4.3: 1M ctx, function calling, OpenAI-compatible)
-- is intentionally left OUT of the chain until its exact OpenRouter model id is
-- verified live — model ids drift, and an invalid id would silently fail the
-- chain. See docs/research/ai-agentic-flow-2026-06-13.md.
-- ----------------------------------------------------------------------------
INSERT INTO public.feature_routes
  (feature_type, display_name, model_chain, response_format, max_tokens,
   temperature, supports_tools, agentic_mode, tools, branch_cap,
   max_tool_iterations, notes)
VALUES
  ('admin_assistant',
   'Ask Campusly (data Q&A assistant)',
   '[
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"},
     {"provider":"openrouter","model":"google/gemma-4-31b-instruct:free","tier":"free"}
   ]'::jsonb,
   'text', 800, 0.3, true, true,
   '["find_students","get_attendance_summary","get_student_marks","get_fee_status"]'::jsonb,
   1, 5,
   'Single agent + read-only tools under tenant RLS. branch_cap=1 (branch/merge reserved for Phase C per research eval). Add Grok paid fallback once OpenRouter id is verified.')
ON CONFLICT (feature_type) DO UPDATE SET
  display_name        = EXCLUDED.display_name,
  model_chain         = EXCLUDED.model_chain,
  response_format     = EXCLUDED.response_format,
  max_tokens          = EXCLUDED.max_tokens,
  temperature         = EXCLUDED.temperature,
  supports_tools      = EXCLUDED.supports_tools,
  agentic_mode        = EXCLUDED.agentic_mode,
  tools               = EXCLUDED.tools,
  branch_cap          = EXCLUDED.branch_cap,
  max_tool_iterations = EXCLUDED.max_tool_iterations,
  notes               = EXCLUDED.notes;
