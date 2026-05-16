-- 2026-05-16: scope has_role() to current tenant; extract is_super_admin()
-- Audit finding HIGH-7: has_role() was SECURITY DEFINER but not tenant-scoped,
-- allowing cross-tenant privilege if a user had the same role in two tenants.
--
-- Compatibility notes:
--   * Existing 1-arg signature is has_role(required_role user_role) — preserved.
--     Callers across migrations 00010, 00042, 00043, 00044, 00050, etc. use
--     literals like has_role('super_admin') / has_role('teacher') / has_role('super_admin'::user_role)
--     which all resolve to this enum overload. Keeping the user_role parameter
--     type means none of those callers need to change.
--   * 2-arg has_role(uuid, text) and 3-arg has_role(uuid, uuid, text) overloads
--     defined in 00012 / 00029 remain untouched (they accept explicit tenant_id
--     or are scoped by RLS in other ways).
--   * super_admin is intentionally global by design (a single super_admin manages
--     all tenants — see 00042_fix_super_admin_cross_tenant_rls.sql), so it
--     bypasses the tenant scope check via is_super_admin().

-- ============================================================
-- 1. is_super_admin(): extracted, unscoped check for the global role
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = 'super_admin'::user_role
  );
$$;

-- ============================================================
-- 2. has_role(required_role user_role): now tenant-scoped
--    super_admin bypasses scope via is_super_admin()
-- ============================================================
CREATE OR REPLACE FUNCTION public.has_role(required_role user_role)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  current_tenant uuid;
BEGIN
  -- super_admin role bypasses tenant scope by design
  IF required_role = 'super_admin'::user_role THEN
    RETURN public.is_super_admin();
  END IF;

  current_tenant := public.tenant_id();

  -- No tenant context (tenant_id() returns NULL per 00031) → deny
  IF current_tenant IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = required_role
      AND tenant_id = current_tenant
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$;

-- ============================================================
-- 3. Grants (mirror prior migrations' implicit grants for authenticated)
-- ============================================================
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_role(user_role) TO authenticated;

COMMENT ON FUNCTION public.has_role(user_role) IS
  'Tenant-scoped role check. super_admin bypasses scope. Audit: 2026-05-16 SPRINT 1 task 1.B3 (HIGH-7).';
COMMENT ON FUNCTION public.is_super_admin() IS
  'Global, unscoped super_admin check. Extracted from has_role() so RLS policies can opt in to bypass tenant scope explicitly.';
