-- Migration: 00058_admission_ai
-- Purpose: Sprint 2.1 — admissions AI features:
--   (a) Lead scoring on admission_inquiries (pure SQL heuristic, no LLM)
--   (b) FAQ corpus for the public admissions chatbot
--   (c) Chat session tracking for rate-limit + transcript
--
-- Lead scoring is a 0-100 composite score with a parallel TEXT[] of reasons
-- explaining what drove it. Heuristics chosen so even a school with no LLM
-- access gets useful triage today; LLM enrichment lands in a later sprint
-- via a wrapper that calls the gateway over the heuristic baseline.
--
-- FAQ corpus uses `pg_trgm` + a GIN index for fast ILIKE search at our
-- current scale (~50-500 FAQs per tenant). Embedding column is left
-- nullable so we can backfill via pgvector in Phase 3 without a schema
-- migration. Public read uses a slug-based grant via the edge function
-- (service role) — RLS still requires admin role for the table itself.
--
-- Chat sessions are append-only and indexed by session_id (UUID picked by
-- the client + stashed in shared_preferences). Rate limiting (20 messages
-- per IP per hour) is enforced by the edge function using these rows.
--
-- Follows the 00054 RLS pattern: (SELECT public.tenant_id()), service role
-- writes via dedicated RPCs.

-- ============================================================================
-- 1. Lead scoring columns on admission_inquiries
-- ============================================================================

ALTER TABLE public.admission_inquiries
  ADD COLUMN IF NOT EXISTS lead_score INT
    CHECK (lead_score >= 0 AND lead_score <= 100);

ALTER TABLE public.admission_inquiries
  ADD COLUMN IF NOT EXISTS lead_score_reasons TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE public.admission_inquiries
  ADD COLUMN IF NOT EXISTS lead_score_computed_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_admission_inquiries_lead_score
  ON public.admission_inquiries (tenant_id, lead_score DESC NULLS LAST);

COMMENT ON COLUMN public.admission_inquiries.lead_score IS
  '0-100 composite lead score from compute_admission_lead_score(). Recomputed lazily on read or via cron.';
COMMENT ON COLUMN public.admission_inquiries.lead_score_reasons IS
  'Ordered top contributing factors (highest weight first). Used by the LeadScoreBadge tooltip.';

-- ============================================================================
-- 2. RPC: compute_admission_lead_score
-- ============================================================================
-- Heuristic — pure SQL, no LLM. Caller passes an inquiry id, gets back
-- (score, reasons[]). Also UPDATEs the row so the LeadScoreBadge can read
-- the cached value on next render.

CREATE OR REPLACE FUNCTION public.compute_admission_lead_score(
  p_inquiry_id UUID
) RETURNS TABLE (
  score   INT,
  reasons TEXT[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  r admission_inquiries%ROWTYPE;
  v_score INT := 0;
  v_reasons TEXT[] := '{}';
BEGIN
  SELECT * INTO r FROM admission_inquiries WHERE id = p_inquiry_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 0, '{}'::TEXT[];
    RETURN;
  END IF;

  -- Status overrides — short-circuit converted/lost
  IF r.status = 'converted' THEN
    UPDATE admission_inquiries
       SET lead_score = 100,
           lead_score_reasons = ARRAY['Already converted to application'],
           lead_score_computed_at = NOW()
     WHERE id = p_inquiry_id;
    RETURN QUERY SELECT 100, ARRAY['Already converted to application']::TEXT[];
    RETURN;
  END IF;

  IF r.status = 'lost' THEN
    UPDATE admission_inquiries
       SET lead_score = 0,
           lead_score_reasons = ARRAY[COALESCE('Lost: ' || r.lost_reason, 'Marked as lost')],
           lead_score_computed_at = NOW()
     WHERE id = p_inquiry_id;
    RETURN QUERY SELECT 0, ARRAY[COALESCE('Lost: ' || r.lost_reason, 'Marked as lost')]::TEXT[];
    RETURN;
  END IF;

  -- Visit signals — highest-intent indicators
  IF r.visit_completed THEN
    v_score := v_score + 20;
    v_reasons := array_append(v_reasons, 'Campus visit completed (+20)');
  ELSIF r.visit_scheduled_date IS NOT NULL
     AND r.visit_scheduled_date >= CURRENT_DATE THEN
    v_score := v_score + 15;
    v_reasons := array_append(v_reasons, 'Campus visit scheduled (+15)');
  END IF;

  -- Pipeline ownership signal
  IF r.assigned_to IS NOT NULL THEN
    v_score := v_score + 10;
    v_reasons := array_append(v_reasons, 'Assigned to a counselor (+10)');
  END IF;

  -- Contact completeness — multiple channels = serious intent
  IF r.parent_email IS NOT NULL AND length(trim(r.parent_email)) > 0 THEN
    v_score := v_score + 8;
    v_reasons := array_append(v_reasons, 'Email provided (+8)');
  END IF;
  IF r.alternate_phone IS NOT NULL AND length(trim(r.alternate_phone)) > 0 THEN
    v_score := v_score + 6;
    v_reasons := array_append(v_reasons, 'Backup phone provided (+6)');
  END IF;

  -- Specificity — target class + previous school = real research
  IF r.target_class_id IS NOT NULL THEN
    v_score := v_score + 10;
    v_reasons := array_append(v_reasons, 'Target class specified (+10)');
  END IF;
  IF r.previous_school IS NOT NULL AND length(trim(r.previous_school)) > 0 THEN
    v_score := v_score + 7;
    v_reasons := array_append(v_reasons, 'Previous school listed (+7)');
  END IF;
  IF r.address IS NOT NULL AND length(trim(r.address)) > 0 THEN
    v_score := v_score + 5;
    v_reasons := array_append(v_reasons, 'Address provided (+5)');
  END IF;

  -- Referral signals — sibling/staff referrals convert at much higher rates
  IF r.referral_details ILIKE '%sibling%' OR r.referral_details ILIKE '%brother%' OR r.referral_details ILIKE '%sister%' THEN
    v_score := v_score + 12;
    v_reasons := array_append(v_reasons, 'Sibling referral (+12)');
  ELSIF r.referral_details ILIKE '%staff%' OR r.referral_details ILIKE '%teacher%' THEN
    v_score := v_score + 8;
    v_reasons := array_append(v_reasons, 'Staff referral (+8)');
  END IF;

  -- Engagement freshness
  IF r.last_contacted_at IS NOT NULL
     AND r.last_contacted_at >= NOW() - INTERVAL '14 days' THEN
    v_score := v_score + 8;
    v_reasons := array_append(v_reasons, 'Recently engaged (+8)');
  ELSIF r.last_contacted_at IS NOT NULL
     AND r.last_contacted_at < NOW() - INTERVAL '60 days' THEN
    v_score := v_score - 10;
    v_reasons := array_append(v_reasons, 'Stale: no contact 60+ days (-10)');
  END IF;

  -- Inquiry recency
  IF r.inquiry_date >= CURRENT_DATE - INTERVAL '7 days' THEN
    v_score := v_score + 5;
    v_reasons := array_append(v_reasons, 'New inquiry (<7 days) (+5)');
  ELSIF r.inquiry_date < CURRENT_DATE - INTERVAL '90 days'
        AND NOT r.visit_completed THEN
    v_score := v_score - 8;
    v_reasons := array_append(v_reasons, 'Cold: 90+ days, no visit (-8)');
  END IF;

  -- Clamp to [0,100]
  v_score := GREATEST(0, LEAST(100, v_score));

  UPDATE admission_inquiries
     SET lead_score = v_score,
         lead_score_reasons = v_reasons,
         lead_score_computed_at = NOW()
   WHERE id = p_inquiry_id;

  RETURN QUERY SELECT v_score, v_reasons;
END $$;

REVOKE EXECUTE ON FUNCTION public.compute_admission_lead_score(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.compute_admission_lead_score(UUID) TO authenticated;

COMMENT ON FUNCTION public.compute_admission_lead_score IS
  'Sprint 2.1: composite 0-100 lead score from inquiry signals. Pure SQL heuristic; updates lead_score / lead_score_reasons / lead_score_computed_at columns.';

-- ============================================================================
-- 3. admission_faqs — the chatbot's RAG corpus
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.admission_faqs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  question        TEXT NOT NULL,
  answer          TEXT NOT NULL,
  category        TEXT,
  is_public       BOOLEAN NOT NULL DEFAULT TRUE,
  display_order   INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- NOTE: embedding column intentionally NOT created here. pgvector is
-- not enabled until Phase 3.1; that migration will ALTER TABLE to add
-- `embedding vector(384)` and backfill via the embedding edge function.

CREATE INDEX IF NOT EXISTS idx_admission_faqs_tenant
  ON public.admission_faqs (tenant_id);

CREATE INDEX IF NOT EXISTS idx_admission_faqs_question_trgm
  ON public.admission_faqs USING gin (question gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_admission_faqs_answer_trgm
  ON public.admission_faqs USING gin (answer gin_trgm_ops);

DROP TRIGGER IF EXISTS trg_admission_faqs_modtime ON public.admission_faqs;
CREATE TRIGGER trg_admission_faqs_modtime
  BEFORE UPDATE ON public.admission_faqs
  FOR EACH ROW
  EXECUTE PROCEDURE moddatetime(updated_at);

COMMENT ON TABLE public.admission_faqs IS
  'Sprint 2.1: RAG corpus for the public admissions chatbot. Trigram-indexed for ILIKE search at current scale.';

-- ============================================================================
-- 4. admission_chat_sessions + admission_chat_messages
-- ============================================================================
-- Anonymous parents talk to the chatbot via a UUID session_id stashed in
-- their browser. The edge function writes both the session row (on first
-- message) and every message under it. Rate limiting uses the ip_hash
-- column (we hash the IP before storing — never store raw IPs).

CREATE TABLE IF NOT EXISTS public.admission_chat_sessions (
  id              UUID PRIMARY KEY,
  tenant_id       UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  ip_hash         TEXT,
  user_agent_hash TEXT,
  message_count   INT NOT NULL DEFAULT 0,
  converted_to_inquiry_id UUID REFERENCES public.admission_inquiries(id)
                                  ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admission_chat_sessions_tenant_recent
  ON public.admission_chat_sessions (tenant_id, last_message_at DESC);

CREATE INDEX IF NOT EXISTS idx_admission_chat_sessions_ip_recent
  ON public.admission_chat_sessions (ip_hash, last_message_at DESC)
  WHERE ip_hash IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.admission_chat_messages (
  id              BIGSERIAL PRIMARY KEY,
  session_id      UUID NOT NULL REFERENCES public.admission_chat_sessions(id)
                       ON DELETE CASCADE,
  tenant_id       UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  role            TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content         TEXT NOT NULL,
  matched_faq_ids UUID[] NOT NULL DEFAULT '{}',
  provider        TEXT,
  tokens_in       INT,
  tokens_out      INT,
  cost_usd        NUMERIC(10, 6),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admission_chat_messages_session
  ON public.admission_chat_messages (session_id, created_at);

CREATE INDEX IF NOT EXISTS idx_admission_chat_messages_tenant_created
  ON public.admission_chat_messages (tenant_id, created_at DESC);

COMMENT ON TABLE public.admission_chat_sessions IS
  'Sprint 2.1: anonymous chatbot session tracking. Hashed IP for rate-limit only — never raw.';

-- ============================================================================
-- 5. RLS
-- ============================================================================

ALTER TABLE public.admission_faqs           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_chat_sessions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_chat_messages  ENABLE ROW LEVEL SECURITY;

-- admission_faqs: admins manage; service role reads via edge function.
DROP POLICY IF EXISTS "Tenant reads own faqs" ON public.admission_faqs;
CREATE POLICY "Tenant reads own faqs"
ON public.admission_faqs FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()));

DROP POLICY IF EXISTS "Admins manage faqs" ON public.admission_faqs;
CREATE POLICY "Admins manage faqs"
ON public.admission_faqs FOR ALL
USING (
  tenant_id = (SELECT public.tenant_id())
  AND (SELECT public.is_admin())
);

-- admission_chat_*: ONLY admins (within tenant) + service role read.
-- Anonymous chat traffic goes through the edge function which uses the
-- service-role key and authorizes by validating the session_id.
DROP POLICY IF EXISTS "Admins read own chat sessions" ON public.admission_chat_sessions;
CREATE POLICY "Admins read own chat sessions"
ON public.admission_chat_sessions FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id())
  AND (SELECT public.is_admin())
);

DROP POLICY IF EXISTS "Admins read own chat messages" ON public.admission_chat_messages;
CREATE POLICY "Admins read own chat messages"
ON public.admission_chat_messages FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id())
  AND (SELECT public.is_admin())
);

REVOKE INSERT, UPDATE, DELETE ON public.admission_chat_sessions  FROM authenticated, anon;
REVOKE INSERT, UPDATE, DELETE ON public.admission_chat_messages  FROM authenticated, anon;

-- ============================================================================
-- 6. RPC: search_admission_faqs  (called by the edge function as RAG)
-- ============================================================================
-- ILIKE + trigram-similarity ranking. Returns top-N most relevant FAQs for
-- a parent's question. No pgvector needed at this scale.

CREATE OR REPLACE FUNCTION public.search_admission_faqs(
  p_tenant_id UUID,
  p_query     TEXT,
  p_limit     INT DEFAULT 5
) RETURNS TABLE (
  faq_id      UUID,
  question    TEXT,
  answer      TEXT,
  similarity  REAL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  RETURN QUERY
  SELECT f.id, f.question, f.answer,
         GREATEST(
           similarity(f.question, p_query),
           similarity(f.answer,   p_query) * 0.6
         ) AS similarity
    FROM admission_faqs f
   WHERE f.tenant_id = p_tenant_id
     AND f.is_public = TRUE
     AND (
       f.question ILIKE '%' || p_query || '%'
       OR f.answer ILIKE '%' || p_query || '%'
       OR similarity(f.question, p_query) > 0.1
     )
   ORDER BY similarity DESC, f.display_order ASC
   LIMIT GREATEST(p_limit, 1);
END $$;

REVOKE EXECUTE ON FUNCTION public.search_admission_faqs(UUID, TEXT, INT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.search_admission_faqs(UUID, TEXT, INT) TO service_role;

-- ============================================================================
-- 7. RPC: check_chat_rate_limit  (per IP per tenant per hour)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_chat_rate_limit(
  p_tenant_id UUID,
  p_ip_hash   TEXT,
  p_max_per_hr INT DEFAULT 20
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_count INT;
BEGIN
  IF p_ip_hash IS NULL THEN
    RETURN TRUE; -- skip if IP not available; edge function should always pass one
  END IF;
  SELECT COALESCE(SUM(s.message_count), 0)
    INTO v_count
    FROM admission_chat_sessions s
   WHERE s.tenant_id = p_tenant_id
     AND s.ip_hash   = p_ip_hash
     AND s.last_message_at >= NOW() - INTERVAL '1 hour';
  RETURN v_count < p_max_per_hr;
END $$;

REVOKE EXECUTE ON FUNCTION public.check_chat_rate_limit(UUID, TEXT, INT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.check_chat_rate_limit(UUID, TEXT, INT) TO service_role;

-- ============================================================================
-- Done.
-- ============================================================================
