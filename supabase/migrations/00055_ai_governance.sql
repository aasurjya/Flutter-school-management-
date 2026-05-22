-- Migration: 00055_ai_governance
-- Purpose: AI cost/quota governance — pre-requisite for any new AI feature.
--
-- Adds three tables:
--   1. tenant_ai_usage     — append-only log of every LLM call
--   2. tenant_ai_credits   — monthly rolling budget per tenant (1 row/tenant)
--   3. tenant_ai_settings  — per-feature governance (n rows/tenant)
--
-- Adds two SECURITY DEFINER RPCs the ai-gateway edge function calls:
--   - check_ai_quota(p_feature_type)     — pre-flight: can this tenant make a
--                                          call right now? returns allowed/reason
--   - log_ai_usage(...)                  — post-call: atomically write usage row
--                                          + update credits.used_usd/calls_used
--
-- RLS pattern follows 00054_perf_quality_sweep.sql:
--   - all helper calls wrapped in (SELECT ...) for scalar-subquery caching
--   - tenant_id = (SELECT public.tenant_id()) for tenant scoping
--   - tenants SELECT their own rows; only service-role writes
--
-- Monthly reset: pg_cron job that, on day 1 at 00:30 UTC, archives the prior
-- cycle into a snapshot column and resets used_usd/calls_used. If pg_cron is
-- not available in the target env, the reset_ai_credits() function can be
-- triggered manually or from an external scheduler.
--
-- Default tier mapping seeded for existing tenants: 'free'. Super-admin can
-- upgrade per tenant via the tenant_ai_settings_screen.
--
-- Rollback: this migration is purely additive. To revert, drop tables in
-- reverse dependency order and DROP FUNCTION the two RPCs.

-- ============================================================================
-- 1. TABLE: tenant_ai_usage  (append-only log)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.tenant_ai_usage (
  id              BIGSERIAL PRIMARY KEY,
  tenant_id       UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  feature_type    TEXT NOT NULL,
  provider        TEXT NOT NULL,
  status          TEXT NOT NULL CHECK (status IN (
                    'success', 'error', 'cache_hit', 'blocked_quota',
                    'blocked_rate', 'blocked_feature_disabled', 'fallback'
                  )),
  tokens_in       INT NOT NULL DEFAULT 0,
  tokens_out      INT NOT NULL DEFAULT 0,
  cost_usd        NUMERIC(10, 6) NOT NULL DEFAULT 0,
  latency_ms      INT,
  request_hash    TEXT,
  error_code      TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tenant_ai_usage_tenant_created
  ON public.tenant_ai_usage (tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_tenant_ai_usage_tenant_feature_created
  ON public.tenant_ai_usage (tenant_id, feature_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_tenant_ai_usage_request_hash
  ON public.tenant_ai_usage (tenant_id, request_hash)
  WHERE request_hash IS NOT NULL;

COMMENT ON TABLE  public.tenant_ai_usage IS
  'Append-only log of every LLM call made through ai-gateway. Service-role writes only; tenants read their own rows.';
COMMENT ON COLUMN public.tenant_ai_usage.cost_usd IS
  'Computed cost in USD with 6-decimal precision. Derived from tokens_in/out and provider price-per-Mtok at call time.';
COMMENT ON COLUMN public.tenant_ai_usage.request_hash IS
  'SHA-256 (truncated) of (feature_type, normalized prompt, model). Used for cache-hit lookups.';

-- ============================================================================
-- 2. TABLE: tenant_ai_credits  (monthly rolling budget — 1 row per tenant)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.tenant_ai_credits (
  tenant_id        UUID PRIMARY KEY REFERENCES public.tenants(id) ON DELETE CASCADE,
  tier             TEXT NOT NULL DEFAULT 'free'
                     CHECK (tier IN ('free', 'standard', 'premium', 'tutor_addon')),
  cycle_start      DATE NOT NULL DEFAULT DATE_TRUNC('month', NOW())::DATE,
  budget_usd       NUMERIC(10, 2) NOT NULL DEFAULT 0,
  used_usd         NUMERIC(10, 2) NOT NULL DEFAULT 0,
  calls_used       INT NOT NULL DEFAULT 0,
  calls_limit      INT NOT NULL DEFAULT 150,
  soft_cap_pct     INT NOT NULL DEFAULT 80 CHECK (soft_cap_pct BETWEEN 1 AND 100),
  hard_cap_pct     INT NOT NULL DEFAULT 100 CHECK (hard_cap_pct BETWEEN 1 AND 200),
  burst_per_min    INT NOT NULL DEFAULT 30,
  warn_sent_at     TIMESTAMPTZ,
  blocked_at       TIMESTAMPTZ,
  last_cycle_used_usd NUMERIC(10, 2) NOT NULL DEFAULT 0,
  last_cycle_calls    INT NOT NULL DEFAULT 0,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  public.tenant_ai_credits IS
  'Monthly rolling AI budget per tenant. Reset on day 1 via reset_ai_credits() (pg_cron or external scheduler).';
COMMENT ON COLUMN public.tenant_ai_credits.tier IS
  'Pricing tier: free=150 calls/mo, standard=8000, premium=30000, tutor_addon=metered.';
COMMENT ON COLUMN public.tenant_ai_credits.hard_cap_pct IS
  'When used_usd >= budget_usd * hard_cap_pct / 100, all gateway calls return blocked_quota.';

-- ---- moddatetime trigger so updated_at stays current ----
DROP TRIGGER IF EXISTS trg_tenant_ai_credits_modtime ON public.tenant_ai_credits;
CREATE TRIGGER trg_tenant_ai_credits_modtime
  BEFORE UPDATE ON public.tenant_ai_credits
  FOR EACH ROW
  EXECUTE PROCEDURE moddatetime(updated_at);

-- ============================================================================
-- 3. TABLE: tenant_ai_settings  (per-feature governance — n rows per tenant)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.tenant_ai_settings (
  tenant_id              UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  feature_type           TEXT NOT NULL,
  enabled                BOOLEAN NOT NULL DEFAULT TRUE,
  preferred_provider     TEXT NOT NULL DEFAULT 'auto'
                           CHECK (preferred_provider IN ('auto', 'cheap', 'quality')),
  max_tokens_out         INT NOT NULL DEFAULT 1024 CHECK (max_tokens_out BETWEEN 1 AND 16000),
  max_cost_per_call_usd  NUMERIC(8, 4) NOT NULL DEFAULT 0.05
                           CHECK (max_cost_per_call_usd > 0),
  cache_ttl_seconds      INT NOT NULL DEFAULT 3600 CHECK (cache_ttl_seconds >= 0),
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (tenant_id, feature_type)
);

COMMENT ON TABLE  public.tenant_ai_settings IS
  'Per-feature AI governance per tenant. Absent row = use plan defaults (enabled, auto provider).';
COMMENT ON COLUMN public.tenant_ai_settings.preferred_provider IS
  'auto=routing matrix decides; cheap=force DeepSeek/Haiku; quality=force Claude Sonnet.';

DROP TRIGGER IF EXISTS trg_tenant_ai_settings_modtime ON public.tenant_ai_settings;
CREATE TRIGGER trg_tenant_ai_settings_modtime
  BEFORE UPDATE ON public.tenant_ai_settings
  FOR EACH ROW
  EXECUTE PROCEDURE moddatetime(updated_at);

-- ============================================================================
-- 4. RLS POLICIES
-- ============================================================================
-- Tenants SELECT their own rows; only service-role writes. Super-admin can
-- read/write all. Pattern matches 00054 (scalar-subquery wrapping).

ALTER TABLE public.tenant_ai_usage    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_ai_credits  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_ai_settings ENABLE ROW LEVEL SECURITY;

-- ---- tenant_ai_usage ----
DROP POLICY IF EXISTS "Tenant reads own ai usage" ON public.tenant_ai_usage;
CREATE POLICY "Tenant reads own ai usage"
ON public.tenant_ai_usage FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()));

DROP POLICY IF EXISTS "Super admin reads all ai usage" ON public.tenant_ai_usage;
CREATE POLICY "Super admin reads all ai usage"
ON public.tenant_ai_usage FOR SELECT
USING ((SELECT public.has_role('super_admin')));

-- INSERT/UPDATE/DELETE: service-role only (RLS does not apply to service role).
-- Explicitly revoke from authenticated/anon to prevent direct writes.
REVOKE INSERT, UPDATE, DELETE ON public.tenant_ai_usage FROM authenticated, anon;

-- ---- tenant_ai_credits ----
DROP POLICY IF EXISTS "Tenant reads own credits" ON public.tenant_ai_credits;
CREATE POLICY "Tenant reads own credits"
ON public.tenant_ai_credits FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()));

DROP POLICY IF EXISTS "Super admin manages all credits" ON public.tenant_ai_credits;
CREATE POLICY "Super admin manages all credits"
ON public.tenant_ai_credits FOR ALL
USING ((SELECT public.has_role('super_admin')));

REVOKE INSERT, UPDATE, DELETE ON public.tenant_ai_credits FROM authenticated, anon;

-- ---- tenant_ai_settings ----
DROP POLICY IF EXISTS "Tenant reads own ai settings" ON public.tenant_ai_settings;
CREATE POLICY "Tenant reads own ai settings"
ON public.tenant_ai_settings FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()));

DROP POLICY IF EXISTS "Super admin manages all ai settings" ON public.tenant_ai_settings;
CREATE POLICY "Super admin manages all ai settings"
ON public.tenant_ai_settings FOR ALL
USING ((SELECT public.has_role('super_admin')));

DROP POLICY IF EXISTS "Tenant admin updates own ai settings" ON public.tenant_ai_settings;
CREATE POLICY "Tenant admin updates own ai settings"
ON public.tenant_ai_settings FOR UPDATE
USING (
  tenant_id = (SELECT public.tenant_id())
  AND (SELECT public.is_admin())
);

REVOKE INSERT, DELETE ON public.tenant_ai_settings FROM authenticated, anon;

-- ============================================================================
-- 5. RPC: check_ai_quota  (pre-flight gate, called by ai-gateway)
-- ============================================================================
-- Returns whether a given tenant/feature can make an AI call right now.
-- Reasons surfaced to the gateway (and thence to the client banner):
--   ok | feature_disabled | hard_cap_reached | burst_limit_reached
-- SECURITY DEFINER so the edge function (service-role) can call without
-- depending on tenant JWT context for the lookup.

CREATE OR REPLACE FUNCTION public.check_ai_quota(
  p_tenant_id   UUID,
  p_feature_type TEXT
) RETURNS TABLE (
  allowed        BOOLEAN,
  reason         TEXT,
  used_usd       NUMERIC,
  budget_usd     NUMERIC,
  calls_used     INT,
  calls_limit    INT,
  preferred_provider TEXT,
  max_tokens_out INT,
  max_cost_per_call_usd NUMERIC,
  cache_ttl_seconds INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_credit RECORD;
  v_setting RECORD;
  v_recent_calls INT;
BEGIN
  -- Load credits (NULL = no row yet; treat as blocked until seeded)
  SELECT * INTO v_credit FROM tenant_ai_credits WHERE tenant_id = p_tenant_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'no_credit_row'::TEXT,
                        0::NUMERIC, 0::NUMERIC, 0, 0,
                        'auto'::TEXT, 1024, 0.05::NUMERIC, 3600;
    RETURN;
  END IF;

  -- Load per-feature setting (absent = enabled with defaults)
  SELECT * INTO v_setting
    FROM tenant_ai_settings
   WHERE tenant_id = p_tenant_id AND feature_type = p_feature_type;
  IF NOT FOUND THEN
    v_setting.enabled := TRUE;
    v_setting.preferred_provider := 'auto';
    v_setting.max_tokens_out := 1024;
    v_setting.max_cost_per_call_usd := 0.05;
    v_setting.cache_ttl_seconds := 3600;
  END IF;

  -- Feature disabled?
  IF NOT v_setting.enabled THEN
    RETURN QUERY SELECT FALSE, 'feature_disabled'::TEXT,
                        v_credit.used_usd, v_credit.budget_usd,
                        v_credit.calls_used, v_credit.calls_limit,
                        v_setting.preferred_provider, v_setting.max_tokens_out,
                        v_setting.max_cost_per_call_usd, v_setting.cache_ttl_seconds;
    RETURN;
  END IF;

  -- Hard cap reached (cost OR call count)?
  IF v_credit.used_usd >= v_credit.budget_usd * v_credit.hard_cap_pct / 100.0
     OR v_credit.calls_used >= v_credit.calls_limit THEN
    RETURN QUERY SELECT FALSE, 'hard_cap_reached'::TEXT,
                        v_credit.used_usd, v_credit.budget_usd,
                        v_credit.calls_used, v_credit.calls_limit,
                        v_setting.preferred_provider, v_setting.max_tokens_out,
                        v_setting.max_cost_per_call_usd, v_setting.cache_ttl_seconds;
    RETURN;
  END IF;

  -- Burst: calls in the last 60 seconds for this tenant
  SELECT COUNT(*)::INT INTO v_recent_calls
    FROM tenant_ai_usage
   WHERE tenant_id = p_tenant_id
     AND created_at >= NOW() - INTERVAL '60 seconds'
     AND status IN ('success', 'fallback');
  IF v_recent_calls >= v_credit.burst_per_min THEN
    RETURN QUERY SELECT FALSE, 'burst_limit_reached'::TEXT,
                        v_credit.used_usd, v_credit.budget_usd,
                        v_credit.calls_used, v_credit.calls_limit,
                        v_setting.preferred_provider, v_setting.max_tokens_out,
                        v_setting.max_cost_per_call_usd, v_setting.cache_ttl_seconds;
    RETURN;
  END IF;

  -- All clear
  RETURN QUERY SELECT TRUE, 'ok'::TEXT,
                      v_credit.used_usd, v_credit.budget_usd,
                      v_credit.calls_used, v_credit.calls_limit,
                      v_setting.preferred_provider, v_setting.max_tokens_out,
                      v_setting.max_cost_per_call_usd, v_setting.cache_ttl_seconds;
END $$;

REVOKE EXECUTE ON FUNCTION public.check_ai_quota(UUID, TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.check_ai_quota(UUID, TEXT) TO service_role;

COMMENT ON FUNCTION public.check_ai_quota(UUID, TEXT) IS
  'Pre-flight gate called by ai-gateway edge function. Returns (allowed, reason, current usage state, per-feature config).';

-- ============================================================================
-- 6. RPC: log_ai_usage  (post-call atomic write + credits update)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.log_ai_usage(
  p_tenant_id    UUID,
  p_user_id      UUID,
  p_feature_type TEXT,
  p_provider     TEXT,
  p_status       TEXT,
  p_tokens_in    INT,
  p_tokens_out   INT,
  p_cost_usd     NUMERIC,
  p_latency_ms   INT,
  p_request_hash TEXT,
  p_error_code   TEXT DEFAULT NULL
) RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_id BIGINT;
  v_soft_cap_crossed BOOLEAN := FALSE;
BEGIN
  INSERT INTO tenant_ai_usage (
    tenant_id, user_id, feature_type, provider, status,
    tokens_in, tokens_out, cost_usd, latency_ms, request_hash, error_code
  ) VALUES (
    p_tenant_id, p_user_id, p_feature_type, p_provider, p_status,
    COALESCE(p_tokens_in, 0), COALESCE(p_tokens_out, 0),
    COALESCE(p_cost_usd, 0), p_latency_ms, p_request_hash, p_error_code
  ) RETURNING id INTO v_id;

  -- Only success + fallback consume budget; cache_hit / blocked_* do not.
  IF p_status IN ('success', 'fallback') THEN
    UPDATE tenant_ai_credits
       SET used_usd  = used_usd + COALESCE(p_cost_usd, 0),
           calls_used = calls_used + 1
     WHERE tenant_id = p_tenant_id
    RETURNING (used_usd >= budget_usd * soft_cap_pct / 100.0
               AND warn_sent_at IS NULL)
        INTO v_soft_cap_crossed;

    -- Mark warn_sent_at so the gateway only enqueues one warning per cycle
    IF v_soft_cap_crossed THEN
      UPDATE tenant_ai_credits
         SET warn_sent_at = NOW()
       WHERE tenant_id = p_tenant_id;
    END IF;
  END IF;

  RETURN v_id;
END $$;

REVOKE EXECUTE ON FUNCTION public.log_ai_usage(
  UUID, UUID, TEXT, TEXT, TEXT, INT, INT, NUMERIC, INT, TEXT, TEXT
) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.log_ai_usage(
  UUID, UUID, TEXT, TEXT, TEXT, INT, INT, NUMERIC, INT, TEXT, TEXT
) TO service_role;

COMMENT ON FUNCTION public.log_ai_usage IS
  'Called by ai-gateway after every LLM call. Atomically logs usage row + updates credits.used_usd/calls_used. Fires soft-cap warning once per cycle.';

-- ============================================================================
-- 7. RPC: reset_ai_credits  (monthly cycle reset)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.reset_ai_credits()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_count INT;
BEGIN
  WITH updated AS (
    UPDATE tenant_ai_credits
       SET last_cycle_used_usd = used_usd,
           last_cycle_calls    = calls_used,
           used_usd            = 0,
           calls_used          = 0,
           cycle_start         = DATE_TRUNC('month', NOW())::DATE,
           warn_sent_at        = NULL,
           blocked_at          = NULL
     WHERE cycle_start < DATE_TRUNC('month', NOW())::DATE
     RETURNING tenant_id
  )
  SELECT COUNT(*)::INT INTO v_count FROM updated;
  RETURN v_count;
END $$;

REVOKE EXECUTE ON FUNCTION public.reset_ai_credits() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.reset_ai_credits() TO service_role;

COMMENT ON FUNCTION public.reset_ai_credits() IS
  'Monthly cycle reset. Archives prior cycle into last_cycle_* columns then zeroes used_usd/calls_used. Invoke via pg_cron or external scheduler on day 1.';

-- ============================================================================
-- 8. SEED: default credits row for every existing tenant
-- ============================================================================
-- Default tier = free. Super-admin upgrades through tenant_ai_settings_screen.
-- budget_usd = 0 means hard_cap_reached fires immediately — intentionally
-- forces super-admin to explicitly enable AI per tenant before first call.

INSERT INTO public.tenant_ai_credits (
  tenant_id, tier, budget_usd, calls_limit
)
SELECT id, 'free', 0, 150
  FROM public.tenants
 WHERE id NOT IN (SELECT tenant_id FROM public.tenant_ai_credits);

-- ============================================================================
-- 9. pg_cron monthly reset (best-effort — only schedules if extension available)
-- ============================================================================
-- Wrapped in DO block so the migration succeeds in environments without
-- pg_cron (e.g. local dev). Production Supabase has pg_cron enabled.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Unschedule any prior job with the same name to keep this idempotent
    PERFORM cron.unschedule(jobid)
      FROM cron.job
     WHERE jobname = 'ai_credits_monthly_reset';

    PERFORM cron.schedule(
      'ai_credits_monthly_reset',
      '30 0 1 * *',           -- 00:30 UTC, day 1 of every month
      $cmd$SELECT public.reset_ai_credits();$cmd$
    );
  END IF;
END $$;

-- ============================================================================
-- Done.
-- ============================================================================
