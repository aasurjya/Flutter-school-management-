-- Migration: 00059_ai_usage_aggregates
-- Purpose: Sprint 2.4 — aggregation RPCs feeding the super-admin AI cost
-- dashboard. Reads from tenant_ai_usage (created in 00055).
--
-- All RPCs are SECURITY DEFINER + restricted to super_admin role server-side
-- so a leaked client key can't enumerate tenant-level spend.

-- ============================================================================
-- 1. get_ai_usage_overview — platform-wide MTD + projected monthly spend
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_ai_usage_overview()
RETURNS TABLE (
  tenants_with_activity  INT,
  calls_mtd              INT,
  cost_mtd_usd           NUMERIC,
  projected_month_usd    NUMERIC,
  cost_last_month_usd    NUMERIC,
  blocked_calls_mtd      INT,
  cache_hits_mtd         INT,
  most_expensive_feature TEXT,
  most_expensive_provider TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_month_start DATE := DATE_TRUNC('month', NOW())::DATE;
  v_prev_month_start DATE := (DATE_TRUNC('month', NOW()) - INTERVAL '1 month')::DATE;
  v_days_elapsed INT;
  v_days_in_month INT;
BEGIN
  IF NOT (SELECT has_role('super_admin')) THEN
    RAISE EXCEPTION 'super_admin_only';
  END IF;

  v_days_elapsed  := EXTRACT(DAY FROM NOW())::INT;
  v_days_in_month := EXTRACT(DAY FROM (DATE_TRUNC('month', NOW()) + INTERVAL '1 month - 1 day'))::INT;

  RETURN QUERY
  WITH mtd AS (
    SELECT * FROM tenant_ai_usage
     WHERE created_at >= v_month_start
  ),
  last_month AS (
    SELECT COALESCE(SUM(cost_usd), 0) AS cost FROM tenant_ai_usage
     WHERE created_at >= v_prev_month_start
       AND created_at <  v_month_start
       AND status IN ('success', 'fallback')
  ),
  feature_top AS (
    SELECT feature_type FROM mtd
     WHERE status IN ('success', 'fallback')
     GROUP BY feature_type
     ORDER BY SUM(cost_usd) DESC NULLS LAST
     LIMIT 1
  ),
  provider_top AS (
    SELECT provider FROM mtd
     WHERE status IN ('success', 'fallback')
     GROUP BY provider
     ORDER BY SUM(cost_usd) DESC NULLS LAST
     LIMIT 1
  )
  SELECT
    (SELECT COUNT(DISTINCT tenant_id) FROM mtd)::INT,
    (SELECT COUNT(*)::INT FROM mtd WHERE status IN ('success','fallback','cache_hit')),
    (SELECT COALESCE(SUM(cost_usd), 0) FROM mtd WHERE status IN ('success','fallback')),
    CASE
      WHEN v_days_elapsed = 0 THEN 0::NUMERIC
      ELSE (SELECT COALESCE(SUM(cost_usd), 0) FROM mtd WHERE status IN ('success','fallback'))
           / v_days_elapsed * v_days_in_month
    END,
    (SELECT cost FROM last_month),
    (SELECT COUNT(*)::INT FROM mtd WHERE status LIKE 'blocked_%'),
    (SELECT COUNT(*)::INT FROM mtd WHERE status = 'cache_hit'),
    (SELECT feature_type FROM feature_top),
    (SELECT provider FROM provider_top);
END $$;

REVOKE EXECUTE ON FUNCTION public.get_ai_usage_overview() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_ai_usage_overview() TO authenticated;

-- ============================================================================
-- 2. get_ai_usage_by_tenant  — table view: spend MTD per tenant + tier
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_ai_usage_by_tenant(
  p_days INT DEFAULT 30
) RETURNS TABLE (
  tenant_id      UUID,
  tenant_name    TEXT,
  tier           TEXT,
  budget_usd     NUMERIC,
  used_usd_period NUMERIC,
  calls_period   INT,
  blocked_period INT,
  used_pct_of_budget NUMERIC,
  last_call_at   TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  IF NOT (SELECT has_role('super_admin')) THEN
    RAISE EXCEPTION 'super_admin_only';
  END IF;

  RETURN QUERY
  WITH usage AS (
    SELECT u.tenant_id,
           SUM(u.cost_usd) FILTER (WHERE u.status IN ('success','fallback')) AS used,
           COUNT(*)        FILTER (WHERE u.status IN ('success','fallback','cache_hit')) AS calls,
           COUNT(*)        FILTER (WHERE u.status LIKE 'blocked_%') AS blocked,
           MAX(u.created_at) AS last_at
      FROM tenant_ai_usage u
     WHERE u.created_at >= NOW() - (p_days || ' days')::INTERVAL
     GROUP BY u.tenant_id
  )
  SELECT
    t.id,
    t.name,
    c.tier,
    c.budget_usd,
    COALESCE(usage.used, 0),
    COALESCE(usage.calls, 0)::INT,
    COALESCE(usage.blocked, 0)::INT,
    CASE
      WHEN c.budget_usd > 0 THEN ROUND(COALESCE(usage.used, 0) / c.budget_usd * 100, 1)
      ELSE 0::NUMERIC
    END,
    usage.last_at
  FROM tenants t
  LEFT JOIN tenant_ai_credits c ON c.tenant_id = t.id
  LEFT JOIN usage             ON usage.tenant_id = t.id
  ORDER BY COALESCE(usage.used, 0) DESC NULLS LAST,
           t.name ASC;
END $$;

REVOKE EXECUTE ON FUNCTION public.get_ai_usage_by_tenant(INT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_ai_usage_by_tenant(INT) TO authenticated;

-- ============================================================================
-- 3. get_ai_usage_by_feature — feature-level breakdown across all tenants
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_ai_usage_by_feature(
  p_days INT DEFAULT 30
) RETURNS TABLE (
  feature_type TEXT,
  calls        INT,
  tokens_in    BIGINT,
  tokens_out   BIGINT,
  cost_usd     NUMERIC,
  avg_cost_per_call NUMERIC,
  cache_hits   INT,
  errors       INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  IF NOT (SELECT has_role('super_admin')) THEN
    RAISE EXCEPTION 'super_admin_only';
  END IF;

  RETURN QUERY
  SELECT
    u.feature_type,
    COUNT(*)::INT FILTER (WHERE u.status IN ('success','fallback','cache_hit')),
    COALESCE(SUM(u.tokens_in), 0)::BIGINT,
    COALESCE(SUM(u.tokens_out), 0)::BIGINT,
    COALESCE(SUM(u.cost_usd) FILTER (WHERE u.status IN ('success','fallback')), 0),
    CASE
      WHEN COUNT(*) FILTER (WHERE u.status IN ('success','fallback')) > 0 THEN
        COALESCE(SUM(u.cost_usd) FILTER (WHERE u.status IN ('success','fallback')), 0)
        / COUNT(*) FILTER (WHERE u.status IN ('success','fallback'))
      ELSE 0::NUMERIC
    END,
    COUNT(*)::INT FILTER (WHERE u.status = 'cache_hit'),
    COUNT(*)::INT FILTER (WHERE u.status = 'error')
  FROM tenant_ai_usage u
  WHERE u.created_at >= NOW() - (p_days || ' days')::INTERVAL
  GROUP BY u.feature_type
  ORDER BY SUM(u.cost_usd) DESC NULLS LAST;
END $$;

REVOKE EXECUTE ON FUNCTION public.get_ai_usage_by_feature(INT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_ai_usage_by_feature(INT) TO authenticated;

-- ============================================================================
-- Done.
-- ============================================================================
