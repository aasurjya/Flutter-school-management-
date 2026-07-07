-- ============================================================================
-- 00075_fix_user_roles_self_insert_privilege_escalation.sql
--
-- "Users insert own role" ON user_roles FOR INSERT WITH CHECK (user_id = auth.uid())
-- placed NO restriction on which role or tenant_id a user could claim for
-- themselves. Any authenticated user could call the Supabase client SDK
-- directly (no app UI needed) and insert a `super_admin` row for any tenant,
-- fully bypassing the app-level email-match bootstrap in
-- lib/features/auth/providers/auth_provider.dart (createUserWithRole).
--
-- Fix: self-insert may no longer claim the top-level administrative roles.
-- Assigning super_admin/tenant_admin/principal must go through an admin-
-- authorized path (the "Admins manage user roles" / "Super admins manage
-- all user_roles" policies already in place) or a future SECURITY DEFINER
-- promotion function, not a raw self-insert.
-- ============================================================================

DROP POLICY IF EXISTS "Users insert own role" ON user_roles;

CREATE POLICY "Users insert own non-privileged role"
  ON user_roles
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND role NOT IN ('super_admin', 'tenant_admin', 'principal')
  );
