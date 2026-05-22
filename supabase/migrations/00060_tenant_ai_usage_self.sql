-- ============================================================================
-- 00060_tenant_ai_usage_self.sql
--
-- Tenant-self AI usage RPC: lets tenant_admin / principal see *their own*
-- school's MTD AI cost without being super_admin.
--
-- Backs the admin-dashboard AI usage card (Sprint P0.3 — Tenant Quota
-- Visibility). Schools that can't see their own AI bill can't manage it,
-- which makes any budget cap feel arbitrary to them.
--
-- Returns one row: cost MTD, calls MTD, budget USD, % used, last call.
-- All values respect the caller's tenant_id from JWT claims — RLS-style.
-- Super_admins call get_ai_usage_by_tenant(...) for the cross-tenant view.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_my_tenant_ai_usage()
RETURNS TABLE (
  tenant_id          UUID,
  tier               TEXT,
  budget_usd         NUMERIC,
  used_usd_mtd       NUMERIC,
  calls_mtd          INT,
  blocked_mtd        INT,
  cache_hits_mtd     INT,
  used_pct_of_budget NUMERIC,
  last_call_at       TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_tenant_id UUID;
BEGIN
  -- Caller's tenant from JWT app_metadata. NULL means super_admin / no tenant
  -- context — they should use the super_admin endpoints instead.
  v_tenant_id := NULLIF(
    current_setting('request.jwt.claims', true)::jsonb
      -> 'app_metadata' ->> 'tenant_id',
    ''
  )::UUID;

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'no_tenant_in_jwt';
  END IF;

  RETURN QUERY
  WITH usage AS (
    SELECT
      SUM(u.cost_usd)
        FILTER (WHERE u.status IN ('success','fallback')) AS used,
      COUNT(*)
        FILTER (WHERE u.status IN ('success','fallback','cache_hit')) AS calls,
      COUNT(*) FILTER (WHERE u.status LIKE 'blocked_%')   AS blocked,
      COUNT(*) FILTER (WHERE u.status = 'cache_hit')      AS hits,
      MAX(u.created_at)                                   AS last_at
    FROM tenant_ai_usage u
    WHERE u.tenant_id  = v_tenant_id
      AND u.created_at >= DATE_TRUNC('month', NOW())
  )
  SELECT
    v_tenant_id,
    c.tier,
    c.budget_usd,
    COALESCE(usage.used, 0),
    COALESCE(usage.calls, 0)::INT,
    COALESCE(usage.blocked, 0)::INT,
    COALESCE(usage.hits, 0)::INT,
    CASE
      WHEN c.budget_usd > 0
        THEN ROUND(COALESCE(usage.used, 0) / c.budget_usd * 100, 1)
      ELSE 0::NUMERIC
    END,
    usage.last_at
  FROM tenant_ai_credits c, usage
  WHERE c.tenant_id = v_tenant_id;
END $$;

REVOKE EXECUTE ON FUNCTION public.get_my_tenant_ai_usage() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_my_tenant_ai_usage() TO authenticated;

COMMENT ON FUNCTION public.get_my_tenant_ai_usage() IS
  'Returns MTD AI usage for the caller''s tenant (from JWT app_metadata).'
  ' Used by the tenant_admin/principal AI usage card on the admin dashboard.';
