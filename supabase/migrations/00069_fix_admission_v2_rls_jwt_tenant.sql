-- =============================================
-- Fix admission v2 RLS: use JWT-based tenant_id() instead of app.tenant_id GUC
-- =============================================
--
-- Problem
-- -------
-- The five admission v2 tables were created in 00015_admissions.sql with
-- tenant-isolation policies of the form:
--
--     FOR ALL USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
--
-- That depends on a session GUC (`app.tenant_id`) that the app would have to
-- `SET` on every connection. The rest of this codebase derives the tenant from
-- the Supabase JWT via the public.tenant_id() helper, and PostgREST never sets
-- `app.tenant_id`. As a result current_setting('app.tenant_id', true) is always
-- NULL for the app's connections, so:
--   * every SELECT on these tables returns zero rows, and
--   * every INSERT/UPDATE is rejected with
--     "new row violates row-level security policy".
--
-- This is why submitting a new admission application failed with the generic
-- "Couldn't load that. Pull to try again." error, and why the inquiry /
-- application / interview lists were always empty.
--
-- Fix
-- ---
-- Replace the GUC-based policies with the same JWT-based pattern used by the
-- core tables (e.g. students): scope by public.tenant_id(), with a super_admin
-- escape hatch, and add an explicit WITH CHECK so writes are validated too.
--
-- Affected tables:
--   admission_inquiries_v2, admission_applications_v2, admission_interviews_v2,
--   admission_documents_v2, admission_settings_v2

-- admission_inquiries_v2
DROP POLICY IF EXISTS tenant_isolation_inquiries_v2 ON admission_inquiries_v2;
CREATE POLICY tenant_isolation_inquiries_v2 ON admission_inquiries_v2
    FOR ALL
    USING (tenant_id = public.tenant_id() OR public.has_role('super_admin'::user_role))
    WITH CHECK (tenant_id = public.tenant_id() OR public.has_role('super_admin'::user_role));

-- admission_applications_v2
DROP POLICY IF EXISTS tenant_isolation_applications_v2 ON admission_applications_v2;
CREATE POLICY tenant_isolation_applications_v2 ON admission_applications_v2
    FOR ALL
    USING (tenant_id = public.tenant_id() OR public.has_role('super_admin'::user_role))
    WITH CHECK (tenant_id = public.tenant_id() OR public.has_role('super_admin'::user_role));

-- admission_interviews_v2
DROP POLICY IF EXISTS tenant_isolation_interviews_v2 ON admission_interviews_v2;
CREATE POLICY tenant_isolation_interviews_v2 ON admission_interviews_v2
    FOR ALL
    USING (tenant_id = public.tenant_id() OR public.has_role('super_admin'::user_role))
    WITH CHECK (tenant_id = public.tenant_id() OR public.has_role('super_admin'::user_role));

-- admission_documents_v2
DROP POLICY IF EXISTS tenant_isolation_documents_v2 ON admission_documents_v2;
CREATE POLICY tenant_isolation_documents_v2 ON admission_documents_v2
    FOR ALL
    USING (tenant_id = public.tenant_id() OR public.has_role('super_admin'::user_role))
    WITH CHECK (tenant_id = public.tenant_id() OR public.has_role('super_admin'::user_role));

-- admission_settings_v2
DROP POLICY IF EXISTS tenant_isolation_settings_v2 ON admission_settings_v2;
CREATE POLICY tenant_isolation_settings_v2 ON admission_settings_v2
    FOR ALL
    USING (tenant_id = public.tenant_id() OR public.has_role('super_admin'::user_role))
    WITH CHECK (tenant_id = public.tenant_id() OR public.has_role('super_admin'::user_role));
