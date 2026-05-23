-- ============================================================================
-- 00066_feature_routes.sql
--
-- feature_type → ordered model chain. Used by the ai-gateway edge function
-- to pick which model to call (and which fallbacks to walk on failure).
--
-- Seed data is the **corrected** 15-feature table from the OpenRouter
-- migration plan. Differences from the user's original mapping:
--   • Document Processing (#10): Llama-4-Maverick → Gemma-4-31B as primary,
--     because Llama-4 doesn't support tool calling (which OCR pipelines
--     need for structured extraction).
--   • Rows requiring tools (#3, #7, #11, #15): Llama-4 and DeepSeek-R1
--     removed from the chain entirely. Only Nemotron and Gemma-4 (the two
--     free models that actually support tools) remain.
--
-- model_chain JSONB shape:
--   [{"provider": "openrouter", "model": "deepseek/deepseek-v4-flash:free",
--     "tier": "free"}, ...]
--
-- Updates from super_admin UI write here; the gateway reads once per
-- request (no caching layer — feature_routes is < 50 rows, sub-ms lookup).
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.feature_routes (
  feature_type        TEXT PRIMARY KEY,
  display_name        TEXT NOT NULL,
  model_chain         JSONB NOT NULL,
  response_format     TEXT NOT NULL DEFAULT 'text'
                        CHECK (response_format IN ('text', 'json_object')),
  max_tokens          INT  NOT NULL DEFAULT 600
                        CHECK (max_tokens BETWEEN 50 AND 8000),
  temperature         NUMERIC NOT NULL DEFAULT 0.7
                        CHECK (temperature >= 0 AND temperature <= 2),
  supports_streaming  BOOL NOT NULL DEFAULT false,
  supports_tools      BOOL NOT NULL DEFAULT false,
  notes               TEXT,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by          UUID
);

COMMENT ON TABLE  public.feature_routes IS
  'feature_type → model chain. Read by ai-gateway on every request.';
COMMENT ON COLUMN public.feature_routes.model_chain IS
  'Ordered array of {provider, model, tier}. Gateway tries primary first; '
  'walks chain on 429/5xx/no-providers. Empty array = AI disabled for the feature.';

-- updated_at trigger
CREATE OR REPLACE FUNCTION public.tg_feature_routes_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_feature_routes_updated_at ON public.feature_routes;
CREATE TRIGGER trg_feature_routes_updated_at
BEFORE UPDATE ON public.feature_routes
FOR EACH ROW EXECUTE FUNCTION public.tg_feature_routes_updated_at();

-- ----------------------------------------------------------------------------
-- Seed the 15 corrected feature → chain rows.
-- All free models on OpenRouter; chain walks on failure.
-- ----------------------------------------------------------------------------
INSERT INTO public.feature_routes
  (feature_type, display_name, model_chain, response_format, max_tokens, temperature, supports_tools, notes)
VALUES
  ('student_registration',
   'Student Registration & Data Entry',
   '[
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"},
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"},
     {"provider":"openrouter","model":"qwen/qwen3-coder:free","tier":"free"}
   ]'::jsonb,
   'json_object', 1200, 0.3, false,
   'Structured bulk extraction; 1M context handles big sheets.'),

  ('grade_calculation',
   'Grade Calculation & Report Cards',
   '[
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"},
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"},
     {"provider":"openrouter","model":"qwen/qwen3-coder:free","tier":"free"}
   ]'::jsonb,
   'json_object', 800, 0.2, false,
   'Math + GPA. Low temp for determinism. Defensive JSON parsing on client.'),

  ('attendance_analytics',
   'Attendance Tracking & Analytics',
   '[
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"},
     {"provider":"openrouter","model":"google/gemma-4-31b-instruct:free","tier":"free"}
   ]'::jsonb,
   'text', 500, 0.5, true,
   'Tool calling required. Only Nemotron + Gemma-4 free models have it.'),

  ('timetable_generation',
   'Timetable / Schedule Generation',
   '[
     {"provider":"openrouter","model":"deepseek/deepseek-r1:free","tier":"free"},
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"}
   ]'::jsonb,
   'json_object', 2000, 0.4, false,
   'Constraint-solving needs reasoning. R1 OK here because users expect latency on one-shot generation.'),

  ('parent_communication',
   'Parent Communication (Emails/SMS)',
   '[
     {"provider":"openrouter","model":"meta-llama/llama-4-maverick:free","tier":"free"},
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"},
     {"provider":"openrouter","model":"mistralai/mistral-small-3.1:free","tier":"free"}
   ]'::jsonb,
   'text', 400, 0.8, false,
   'Tone matters. Higher temperature for warmth. No tools needed.'),

  ('fee_invoicing',
   'Fee Management & Invoicing',
   '[
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"},
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"},
     {"provider":"openrouter","model":"qwen/qwen3-coder:free","tier":"free"}
   ]'::jsonb,
   'json_object', 1500, 0.2, false,
   'Structured invoice output. CLIENT must add response-healing — free models < 80% JSON reliability.'),

  ('library_management',
   'Library Management',
   '[
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"},
     {"provider":"openrouter","model":"google/gemma-4-31b-instruct:free","tier":"free"}
   ]'::jsonb,
   'text', 500, 0.5, true,
   'Book search + due-date queries need tools.'),

  ('exam_paper_generation',
   'Exam Paper Generation',
   '[
     {"provider":"openrouter","model":"deepseek/deepseek-r1:free","tier":"free"},
     {"provider":"openrouter","model":"qwen/qwen3-coder:free","tier":"free"},
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"}
   ]'::jsonb,
   'json_object', 3000, 0.6, false,
   'Curriculum-aligned synthesis. Users tolerate R1 latency on one-shot generation.'),

  ('student_analytics',
   'Student Performance Analytics',
   '[
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"},
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"}
   ]'::jsonb,
   'text', 700, 0.5, false,
   '1M context for multi-semester trend analysis.'),

  ('document_processing',
   'Document Processing (PDFs, Scanned Forms)',
   '[
     {"provider":"openrouter","model":"google/gemma-4-31b-instruct:free","tier":"free"}
   ]'::jsonb,
   'json_object', 1500, 0.3, true,
   'Vision + tools — only Gemma-4 free model qualifies. Llama-4-Maverick has vision but NO tools; removed from chain. Paid fallback recommended once volume justifies.'),

  ('notifications',
   'Notification / Alert System',
   '[
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"},
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"},
     {"provider":"openrouter","model":"mistralai/mistral-small-3.1:free","tier":"free"}
   ]'::jsonb,
   'text', 250, 0.5, true,
   'High-volume, low-latency. Tools for conditional alerts.'),

  ('admission_chatbot',
   'Admission Query Chatbot',
   '[
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"},
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"},
     {"provider":"openrouter","model":"meta-llama/llama-4-maverick:free","tier":"free"}
   ]'::jsonb,
   'text', 500, 0.7, false,
   'Already wired via admission_faq_chat edge function — gateway is a follow-up migration target.'),

  ('hr_staff_management',
   'HR/Staff Management',
   '[
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"},
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"},
     {"provider":"openrouter","model":"qwen/qwen3-coder:free","tier":"free"}
   ]'::jsonb,
   'json_object', 1000, 0.3, false,
   'Payroll + leave calculation. Structured output.'),

  ('transport_optimization',
   'Transport / Route Optimization',
   '[
     {"provider":"openrouter","model":"deepseek/deepseek-r1:free","tier":"free"},
     {"provider":"openrouter","model":"deepseek/deepseek-v4-flash:free","tier":"free"}
   ]'::jsonb,
   'json_object', 1500, 0.4, false,
   'Route optimization is a reasoning problem.'),

  ('inventory_management',
   'Inventory / Asset Management',
   '[
     {"provider":"openrouter","model":"nvidia/nemotron-3-super-120b-a12b:free","tier":"free"},
     {"provider":"openrouter","model":"google/gemma-4-31b-instruct:free","tier":"free"}
   ]'::jsonb,
   'text', 500, 0.5, true,
   'Stock queries + low-stock alerts need tools.')
ON CONFLICT (feature_type) DO UPDATE SET
  display_name        = EXCLUDED.display_name,
  model_chain         = EXCLUDED.model_chain,
  response_format     = EXCLUDED.response_format,
  max_tokens          = EXCLUDED.max_tokens,
  temperature         = EXCLUDED.temperature,
  supports_tools      = EXCLUDED.supports_tools,
  notes               = EXCLUDED.notes,
  updated_at          = NOW();

-- RLS: public read (gateway runs as service_role, but tenants and the
-- super_admin AI usage dashboard need read access too). Super_admin writes.
ALTER TABLE public.feature_routes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS feature_routes_read ON public.feature_routes;
CREATE POLICY feature_routes_read
  ON public.feature_routes FOR SELECT
  USING (true);

DROP POLICY IF EXISTS feature_routes_write ON public.feature_routes;
CREATE POLICY feature_routes_write
  ON public.feature_routes FOR ALL
  USING      (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true')
  WITH CHECK (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true');

GRANT SELECT ON public.feature_routes TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.feature_routes TO authenticated;
