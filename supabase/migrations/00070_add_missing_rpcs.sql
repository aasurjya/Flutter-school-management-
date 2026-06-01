-- ============================================================================
-- 00070_add_missing_rpcs.sql
--
-- Adds/repairs RPCs the Flutter app calls but that did not exist in the
-- database, causing PostgREST 404s on the flows that use them:
--
--   * get_my_tenant_ai_usage()   — defined in 00060, but its install was
--     guarded on tenant_ai_usage/tenant_ai_credits, which are only created
--     later in 00065. On a clean migrate the guard fired and the function was
--     never installed. Re-install unconditionally now that the tables exist.
--   * get_fee_collection_stats(p_tenant_id) — backs the admin dashboard
--     "School Health" fee-collection rate. Was never defined anywhere.
--   * increment_resource_view(resource_id) / increment_resource_download(...)
--     — bump the view/download counters on study_resources (LMS). Never
--     defined anywhere. SECURITY DEFINER so a student who can only *read* a
--     resource can still bump the counter without UPDATE rights.
--
-- create_tenant_admin(...) is intentionally NOT added here: it must create a
-- GoTrue auth user, which belongs in the create-user edge function / admin
-- API, not a SQL migration.
-- ============================================================================

-- ── get_my_tenant_ai_usage() ────────────────────────────────────────────────
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
SET search_path = public AS $body$
DECLARE
  v_tenant_id UUID;
BEGIN
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
END
$body$;

REVOKE EXECUTE ON FUNCTION public.get_my_tenant_ai_usage() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_my_tenant_ai_usage() TO authenticated;

-- ── get_fee_collection_stats(p_tenant_id) ───────────────────────────────────
-- A tenant_admin can only ever read their own tenant (p_tenant_id is ignored
-- for them and replaced by the JWT tenant); a super_admin may query any tenant.
CREATE OR REPLACE FUNCTION public.get_fee_collection_stats(p_tenant_id UUID)
RETURNS TABLE (
  total_billed    NUMERIC,
  total_collected NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_tenant UUID;
BEGIN
  v_tenant := CASE
    WHEN public.is_super_admin() THEN p_tenant_id
    ELSE public.tenant_id()
  END;

  IF v_tenant IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(SUM(i.total_amount), 0)::NUMERIC,
    COALESCE(SUM(i.paid_amount), 0)::NUMERIC
  FROM invoices i
  WHERE i.tenant_id = v_tenant;
END
$$;

REVOKE EXECUTE ON FUNCTION public.get_fee_collection_stats(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_fee_collection_stats(UUID) TO authenticated;

-- ── increment_resource_view / increment_resource_download ───────────────────
CREATE OR REPLACE FUNCTION public.increment_resource_view(resource_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  UPDATE study_resources
     SET view_count = COALESCE(view_count, 0) + 1
   WHERE id = resource_id
     AND (tenant_id = public.tenant_id() OR public.is_super_admin());
END
$$;

REVOKE EXECUTE ON FUNCTION public.increment_resource_view(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.increment_resource_view(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.increment_resource_download(resource_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  UPDATE study_resources
     SET download_count = COALESCE(download_count, 0) + 1
   WHERE id = resource_id
     AND (tenant_id = public.tenant_id() OR public.is_super_admin());
END
$$;

REVOKE EXECUTE ON FUNCTION public.increment_resource_download(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.increment_resource_download(UUID) TO authenticated;
