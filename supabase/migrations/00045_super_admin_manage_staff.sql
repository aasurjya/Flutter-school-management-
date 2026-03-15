-- Migration: Allow super_admin to INSERT/UPDATE/DELETE staff across all tenants
--
-- Problem: super_admin creates users (auth + users + user_roles) but the
-- "Admins manage staff" policy checks `tenant_id = public.tenant_id()`.
-- For super_admin, tenant_id() returns NULL (no tenant in JWT), so all
-- staff writes from super_admin context were silently blocked by RLS.
--
-- Migration 00042 added a SELECT bypass but no write bypass.
-- This migration adds the missing ALL (INSERT/UPDATE/DELETE) bypass.

DROP POLICY IF EXISTS "Super admins manage all staff" ON public.staff;
CREATE POLICY "Super admins manage all staff"
  ON public.staff FOR ALL
  USING     (public.has_role('super_admin'))
  WITH CHECK (public.has_role('super_admin'));
