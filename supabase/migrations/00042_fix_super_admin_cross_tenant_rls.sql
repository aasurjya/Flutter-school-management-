-- Migration: Fix RLS for super_admin cross-tenant access + break student/student_parents cycle
--
-- Problems:
-- 1. INFINITE RECURSION: students policy queries student_parents; student_parents
--    policy queries students back. Cycle: students → student_parents → students.
-- 2. MISSING POLICIES: super_admin has no SELECT on users/user_roles/students
--    across tenants, so getTenantStats/getTenantUsers always fail with 403.
--
-- Fix strategy:
-- a) Break the cycle by fixing student_parents to query parents instead of students
-- b) Add super_admin bypass policies (simple has_role() check, no subqueries)

-- ============================================================
-- 1. BREAK INFINITE RECURSION IN student_parents ↔ students
-- ============================================================
-- The old policy queried students to verify tenant, creating a cycle.
-- New policy verifies tenant via parents table (no cycle).

DROP POLICY IF EXISTS "View student parents" ON public.student_parents;
CREATE POLICY "View student parents"
ON public.student_parents FOR SELECT
USING (
  public.has_role('super_admin') OR
  (
    parent_id IN (SELECT id FROM public.parents WHERE tenant_id = public.tenant_id()) AND (
      public.is_admin() OR
      public.has_role('teacher') OR
      parent_id IN (SELECT id FROM public.parents WHERE user_id = auth.uid())
    )
  )
);

DROP POLICY IF EXISTS "Admins manage student parents" ON public.student_parents;
CREATE POLICY "Admins manage student parents"
ON public.student_parents FOR ALL
USING (
  public.has_role('super_admin') OR
  (
    parent_id IN (SELECT id FROM public.parents WHERE tenant_id = public.tenant_id()) AND
    public.is_admin()
  )
);

-- ============================================================
-- 2. SUPER ADMIN: full SELECT on students (cross-tenant stats)
-- ============================================================
DROP POLICY IF EXISTS "Super admins view all students" ON public.students;
CREATE POLICY "Super admins view all students"
ON public.students FOR SELECT
USING (public.has_role('super_admin'));

-- Super admins can also manage students in any tenant
DROP POLICY IF EXISTS "Super admins manage all students" ON public.students;
CREATE POLICY "Super admins manage all students"
ON public.students FOR ALL
USING (public.has_role('super_admin'));

-- ============================================================
-- 3. SUPER ADMIN: SELECT on user_roles (cross-tenant stats)
-- ============================================================
DROP POLICY IF EXISTS "Super admins view all user_roles" ON public.user_roles;
CREATE POLICY "Super admins view all user_roles"
ON public.user_roles FOR SELECT
USING (public.has_role('super_admin'));

-- Allow users to view their own roles
DROP POLICY IF EXISTS "Users view own user_roles" ON public.user_roles;
CREATE POLICY "Users view own user_roles"
ON public.user_roles FOR SELECT
USING (user_id = auth.uid());

-- Allow tenant admins to view roles in their tenant
DROP POLICY IF EXISTS "Tenant admins view user_roles" ON public.user_roles;
CREATE POLICY "Tenant admins view user_roles"
ON public.user_roles FOR SELECT
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- ============================================================
-- 4. SUPER ADMIN: SELECT on users (platform stats + tenant user list)
-- ============================================================
DROP POLICY IF EXISTS "Super admins view all users" ON public.users;
CREATE POLICY "Super admins view all users"
ON public.users FOR SELECT
USING (public.has_role('super_admin'));

-- ============================================================
-- 5. SUPER ADMIN: SELECT on parents / staff (cross-tenant stats)
-- ============================================================
DROP POLICY IF EXISTS "Super admins view all parents" ON public.parents;
CREATE POLICY "Super admins view all parents"
ON public.parents FOR SELECT
USING (public.has_role('super_admin'));

DROP POLICY IF EXISTS "Super admins view all staff" ON public.staff;
CREATE POLICY "Super admins view all staff"
ON public.staff FOR SELECT
USING (public.has_role('super_admin'));
