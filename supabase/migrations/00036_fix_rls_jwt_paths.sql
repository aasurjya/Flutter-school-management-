-- Fix RLS policies that used the wrong JWT claims path.
-- The broken policies looked for tenant_id at the ROOT of JWT claims:
--   current_setting('request.jwt.claims')::json ->> 'tenant_id'
-- But Supabase puts tenant_id inside app_metadata:
--   auth.jwt()->'app_metadata'->>'tenant_id'

-- ============================================================
-- homework table
-- ============================================================
DROP POLICY IF EXISTS homework_tenant_policy ON homework;
DROP POLICY IF EXISTS homework_student_view ON homework;

CREATE POLICY homework_tenant_policy ON homework FOR ALL
  USING (tenant_id = ((auth.jwt()->'app_metadata'->>'tenant_id'))::uuid);

CREATE POLICY homework_student_view ON homework FOR SELECT
  USING (
    status = 'published' AND
    tenant_id = ((auth.jwt()->'app_metadata'->>'tenant_id'))::uuid
  );

-- ============================================================
-- homework_submissions table
-- ============================================================
DROP POLICY IF EXISTS submissions_tenant_policy ON homework_submissions;

CREATE POLICY submissions_tenant_policy ON homework_submissions FOR ALL
  USING (
    homework_id IN (
      SELECT id FROM homework
      WHERE tenant_id = ((auth.jwt()->'app_metadata'->>'tenant_id'))::uuid
    )
  );

-- ============================================================
-- student_checkins table
-- ============================================================
DROP POLICY IF EXISTS "Tenant isolation for student_checkins" ON student_checkins;

CREATE POLICY "Tenant isolation for student_checkins" ON student_checkins FOR ALL
  USING (tenant_id = ((auth.jwt()->'app_metadata'->>'tenant_id'))::uuid);
