-- Fix: Super admin tenant INSERT was getting 403 because the ALL policy
-- had USING but no explicit WITH CHECK. PostgreSQL requires WITH CHECK
-- for INSERT; without it, the policy silently blocks writes.

DROP POLICY IF EXISTS "Super admins manage tenants" ON public.tenants;

CREATE POLICY "Super admins manage tenants"
  ON public.tenants FOR ALL
  USING  (public.has_role('super_admin'::user_role))
  WITH CHECK (public.has_role('super_admin'::user_role));

-- Also fix user_credentials: service_role bypasses RLS entirely,
-- so we only need a permissive INSERT policy for completeness.
-- The WITH CHECK (false) blocks direct client inserts (correct),
-- but we need to ensure service_role can still insert (it always can).
-- No change needed there — service_role bypasses RLS.

-- Fix any other ALL policies missing explicit WITH CHECK that could
-- affect the admin workflow (staff, students, parents).

DROP POLICY IF EXISTS "Admins manage users" ON public.users;
CREATE POLICY "Admins manage users"
  ON public.users FOR ALL
  USING  (public.tenant_id() = tenant_id AND public.is_admin())
  WITH CHECK (public.tenant_id() = tenant_id AND public.is_admin());

DROP POLICY IF EXISTS "Admins manage user roles" ON public.user_roles;
CREATE POLICY "Admins manage user roles"
  ON public.user_roles FOR ALL
  USING  (tenant_id = public.tenant_id() AND public.is_admin())
  WITH CHECK (tenant_id = public.tenant_id() AND public.is_admin());

DROP POLICY IF EXISTS "Admins manage student parents" ON public.student_parents;
CREATE POLICY "Admins manage student parents"
  ON public.student_parents FOR ALL
  USING (
    public.has_role('super_admin') OR
    (
      parent_id IN (SELECT id FROM public.parents WHERE tenant_id = public.tenant_id())
      AND public.is_admin()
    )
  )
  WITH CHECK (
    public.has_role('super_admin') OR
    (
      parent_id IN (SELECT id FROM public.parents WHERE tenant_id = public.tenant_id())
      AND public.is_admin()
    )
  );
