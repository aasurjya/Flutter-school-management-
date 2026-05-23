-- ============================================================================
-- 00062_feature_flags.sql
--
-- Trivial Supabase-backed feature flag system. Three behaviours per flag:
--   1. Disabled       — enabled=false, rollout_percent=0
--   2. Fully enabled  — enabled=true,  rollout_percent=100
--   3. Percent rollout — enabled=true, rollout_percent=N (0-100)
--      Flag is on for a tenant iff hash(tenant_id || key) % 100 < N.
--      Stable across sessions; doesn't flip mid-day.
--
-- payload is free-form JSON for variant data (e.g. "claude_model": "haiku-4-5").
-- audience is an optional allowlist — when non-empty, restricts the flag to
-- specific tenant ids regardless of percent (handy for pilot schools).
--
-- This is NOT a replacement for GrowthBook / LaunchDarkly. It's the 95%
-- solution that pays for itself in 4 hours and covers us to ~1000 schools.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.feature_flags (
  key             TEXT PRIMARY KEY,
  enabled         BOOLEAN     NOT NULL DEFAULT false,
  rollout_percent INT         NOT NULL DEFAULT 100
                  CHECK (rollout_percent BETWEEN 0 AND 100),
  payload         JSONB       NOT NULL DEFAULT '{}'::jsonb,
  audience        UUID[]      NOT NULL DEFAULT ARRAY[]::UUID[],
  description     TEXT        NOT NULL DEFAULT '',
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by      UUID
);

COMMENT ON TABLE  public.feature_flags IS
  'Server-controlled feature flags. Read by every client on app boot. See docs/runbooks/feature-flags.md.';
COMMENT ON COLUMN public.feature_flags.audience IS
  'When non-empty, restricts the flag to these tenant ids regardless of rollout_percent.';
COMMENT ON COLUMN public.feature_flags.rollout_percent IS
  'Percent of tenants to enable the flag for (stable hash on tenant_id || key).';

-- updated_at trigger.
CREATE OR REPLACE FUNCTION public.tg_feature_flags_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_feature_flags_updated_at ON public.feature_flags;
CREATE TRIGGER trg_feature_flags_updated_at
BEFORE UPDATE ON public.feature_flags
FOR EACH ROW EXECUTE FUNCTION public.tg_feature_flags_set_updated_at();

-- Public read so clients can fetch all flags on boot. Super-admin write.
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS feature_flags_read  ON public.feature_flags;
CREATE POLICY feature_flags_read
  ON public.feature_flags FOR SELECT
  USING (true);

DROP POLICY IF EXISTS feature_flags_write ON public.feature_flags;
CREATE POLICY feature_flags_write
  ON public.feature_flags FOR ALL
  USING      (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true')
  WITH CHECK (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true');

GRANT SELECT ON public.feature_flags TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.feature_flags TO authenticated;

-- ----------------------------------------------------------------------------
-- Helper: resolve_feature_flag(key, tenant_id) — returns the effective state.
-- The client can do the bucketing itself, but exposing this RPC lets the
-- server be the source of truth for audit logs / experiments later.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.resolve_feature_flag(
  p_key       TEXT,
  p_tenant_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_flag public.feature_flags;
  v_bucket INT;
BEGIN
  SELECT * INTO v_flag FROM public.feature_flags WHERE key = p_key;
  IF NOT FOUND OR NOT v_flag.enabled THEN
    RETURN false;
  END IF;

  IF array_length(v_flag.audience, 1) IS NOT NULL THEN
    RETURN p_tenant_id = ANY(v_flag.audience);
  END IF;

  IF v_flag.rollout_percent >= 100 THEN
    RETURN true;
  END IF;
  IF v_flag.rollout_percent <= 0 THEN
    RETURN false;
  END IF;

  -- Stable bucket — hashtext is signed; mod 100 normalises into [0,99].
  v_bucket := ABS(hashtext(p_tenant_id::text || ':' || p_key)) % 100;
  RETURN v_bucket < v_flag.rollout_percent;
END
$$;

GRANT EXECUTE ON FUNCTION public.resolve_feature_flag(TEXT, UUID) TO authenticated, anon;

COMMENT ON FUNCTION public.resolve_feature_flag IS
  'Resolves whether the given flag is on for the given tenant, applying'
  ' enabled / audience / rollout_percent in that order.';
