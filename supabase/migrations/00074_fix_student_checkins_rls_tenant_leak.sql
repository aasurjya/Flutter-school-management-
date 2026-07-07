-- ============================================================================
-- 00074_fix_student_checkins_rls_tenant_leak.sql
--
-- student_checkins had a "Tenant isolation" FOR ALL policy, but two extra
-- permissive policies were OR'd with it by Postgres RLS semantics:
--   - "Teachers can view checkins" FOR SELECT USING (true)
--       -> any authenticated user, from any tenant, could read every
--          student's check-in/check-out records (location/time PII for minors).
--   - "Teachers can insert checkins" FOR INSERT WITH CHECK (checked_by = auth.uid())
--       -> had no tenant_id check of its own, so a user could insert a
--          checkin row for an arbitrary tenant_id/student_id as long as
--          checked_by was their own uid, bypassing tenant isolation on write.
--
-- Fix: drop both permissive policies (SELECT/UPDATE/DELETE/INSERT now rely
-- solely on the existing tenant-scoped "Tenant isolation" FOR ALL policy),
-- then re-add the checked_by requirement as a RESTRICTIVE policy so it is
-- ANDed with tenant isolation instead of OR'd around it.
-- ============================================================================

DROP POLICY IF EXISTS "Teachers can view checkins" ON student_checkins;
DROP POLICY IF EXISTS "Teachers can insert checkins" ON student_checkins;

CREATE POLICY "Checked-in-by matches auth user"
  ON student_checkins
  AS RESTRICTIVE
  FOR INSERT
  WITH CHECK (checked_by = auth.uid());
