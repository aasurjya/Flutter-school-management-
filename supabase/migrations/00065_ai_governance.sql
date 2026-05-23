-- ============================================================================
-- 00065_ai_governance.sql
--
-- AI governance tables for the OpenRouter multi-model gateway.
--
-- Stage: demo / first-pilot. One shared platform OpenRouter free key.
-- 50 req/day no-credit (1000 with $10 top-up) hard ceiling. Per-tenant
-- soft caps in tenant_ai_credits prevent one greedy tenant from blowing
-- the whole platform budget during demos.
--
-- Future-flagged: tenant_ai_credits.byok_key_encrypted column is present
-- but unused today; reserved for the BYOK upgrade when per-tenant keys
-- become necessary (~10 active schools).
--
-- The previously-shipped 00060_tenant_ai_usage_self.sql function
-- `get_my_tenant_ai_usage()` was conditional on these tables existing
-- (see the DO block in 00060). It auto-installs on this migration's
-- next replay since both dependency tables are now present.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- tenant_ai_credits — per-tenant budget + tier + optional BYOK key
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tenant_ai_credits (
  tenant_id          UUID PRIMARY KEY
                       REFERENCES public.tenants(id) ON DELETE CASCADE,
  tier               TEXT NOT NULL DEFAULT 'free'
                       CHECK (tier IN ('free', 'paid', 'enterprise')),
  -- Demo-time budget is a daily call count, not a $-amount. NUMERIC kept
  -- for future paid-tier dollar tracking without a schema change.
  budget_usd         NUMERIC NOT NULL DEFAULT 20
                       CHECK (budget_usd >= 0),
  -- BYOK reserved for future use (Phase 2). Today: null = use platform key.
  byok_provider      TEXT,
  byok_key_encrypted TEXT,
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by         UUID
);

COMMENT ON TABLE  public.tenant_ai_credits IS
  'Per-tenant AI budget + tier. budget_usd is a daily call count today; '
  'becomes dollars when tier=paid. byok_* reserved for BYOK upgrade.';
COMMENT ON COLUMN public.tenant_ai_credits.budget_usd IS
  'Daily soft cap. Default 20 calls/tenant prevents one greedy tenant '
  'from blowing the platform free-tier (50/day) during demos.';

-- updated_at trigger
CREATE OR REPLACE FUNCTION public.tg_tenant_ai_credits_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_tenant_ai_credits_updated_at ON public.tenant_ai_credits;
CREATE TRIGGER trg_tenant_ai_credits_updated_at
BEFORE UPDATE ON public.tenant_ai_credits
FOR EACH ROW EXECUTE FUNCTION public.tg_tenant_ai_credits_updated_at();

-- Seed every existing tenant with the default free tier so the gateway's
-- quota gate finds a row on first call.
INSERT INTO public.tenant_ai_credits (tenant_id, tier, budget_usd)
SELECT id, 'free', 20 FROM public.tenants
ON CONFLICT (tenant_id) DO NOTHING;

-- RLS: tenant_admin can read their own row; super_admin writes any.
ALTER TABLE public.tenant_ai_credits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_ai_credits_read ON public.tenant_ai_credits;
CREATE POLICY tenant_ai_credits_read
  ON public.tenant_ai_credits FOR SELECT
  USING (
    tenant_id::TEXT = COALESCE(
      auth.jwt() -> 'app_metadata' ->> 'tenant_id', ''
    )
    OR COALESCE(
      auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false'
    ) = 'true'
  );

DROP POLICY IF EXISTS tenant_ai_credits_write ON public.tenant_ai_credits;
CREATE POLICY tenant_ai_credits_write
  ON public.tenant_ai_credits FOR ALL
  USING      (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true')
  WITH CHECK (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true');

GRANT SELECT ON public.tenant_ai_credits TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.tenant_ai_credits TO authenticated;

-- ----------------------------------------------------------------------------
-- tenant_ai_usage — one row per AI call. Idempotency-dedupes on retry.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tenant_ai_usage (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        UUID NOT NULL
                     REFERENCES public.tenants(id) ON DELETE CASCADE,
  feature_type     TEXT NOT NULL,
  model            TEXT NOT NULL,
  -- Status taxonomy:
  --   success            — model returned ok
  --   fallback           — primary failed, a later model in chain returned ok
  --   cache_hit          — idempotency dedupe; returned the prior row's content
  --   blocked_quota      — tenant hit daily cap
  --   blocked_all_exhausted — every model in chain failed; returned fallback string
  status           TEXT NOT NULL,
  cost_usd         NUMERIC NOT NULL DEFAULT 0,
  tokens_in        INT,
  tokens_out       INT,
  -- Optional latency in ms; useful for circuit-breaker tuning later.
  latency_ms       INT,
  -- Idempotency key — reuses the Stage 1 pattern (client_request_id).
  -- A retried-after-success call with the same key returns the original
  -- row instead of double-billing.
  idempotency_key  UUID,
  -- Error message when status starts with 'blocked_' or 'error_'.
  error_message    TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Partial unique index for idempotency dedupe.
CREATE UNIQUE INDEX IF NOT EXISTS uq_tenant_ai_usage_idem
  ON public.tenant_ai_usage (tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- Time-windowed indexes for fast daily-cap counts and recent-call dashboards.
CREATE INDEX IF NOT EXISTS idx_tenant_ai_usage_tenant_day
  ON public.tenant_ai_usage (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tenant_ai_usage_model_status
  ON public.tenant_ai_usage (model, status, created_at DESC);

COMMENT ON TABLE  public.tenant_ai_usage IS
  'Audit + billing log for every AI call. Idempotency-deduped on '
  '(tenant_id, idempotency_key).';
COMMENT ON COLUMN public.tenant_ai_usage.status IS
  'success | fallback | cache_hit | blocked_quota | blocked_all_exhausted | error_*';

-- RLS: tenant sees their own usage; super_admin sees all.
ALTER TABLE public.tenant_ai_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_ai_usage_read ON public.tenant_ai_usage;
CREATE POLICY tenant_ai_usage_read
  ON public.tenant_ai_usage FOR SELECT
  USING (
    tenant_id::TEXT = COALESCE(
      auth.jwt() -> 'app_metadata' ->> 'tenant_id', ''
    )
    OR COALESCE(
      auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false'
    ) = 'true'
  );

-- Writes are gateway-only (service_role). Authenticated users cannot insert
-- directly to prevent log forgery / billing fraud.
DROP POLICY IF EXISTS tenant_ai_usage_write ON public.tenant_ai_usage;
CREATE POLICY tenant_ai_usage_write
  ON public.tenant_ai_usage FOR ALL
  USING      (false)
  WITH CHECK (false);

GRANT SELECT ON public.tenant_ai_usage TO authenticated;
-- Note: gateway writes via service_role which bypasses RLS by design.
