-- Migration: Fix has_role() to query user_roles table instead of JWT app_metadata
--
-- Problem: has_role() read app_metadata.roles from JWT, but app only sets
-- user_metadata.role (singular string) during signup. app_metadata can only be
-- set by service-role key, so it was never populated → all super_admin RLS checks
-- returned false → 403 on tenant insert.
--
-- Fix: has_role() now queries user_roles table directly (SECURITY DEFINER bypasses RLS).
-- This is reliable and never goes stale regardless of JWT state.

CREATE OR REPLACE FUNCTION public.has_role(required_role user_role)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = auth.uid()
      AND role = required_role
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Update is_admin() to stay consistent
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.has_role('tenant_admin')
      OR public.has_role('principal')
      OR public.has_role('super_admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Also add a trigger to keep auth app_metadata in sync for Edge Functions
-- (Edge Functions use service role, but may still read JWT claims)
CREATE OR REPLACE FUNCTION public.sync_user_role_to_app_metadata()
RETURNS TRIGGER AS $$
DECLARE
  roles_array JSONB;
BEGIN
  -- Collect all roles for this user
  SELECT jsonb_agg(role::text)
  INTO roles_array
  FROM public.user_roles
  WHERE user_id = COALESCE(NEW.user_id, OLD.user_id);

  -- Update auth.users app_metadata
  UPDATE auth.users
  SET raw_app_meta_data = jsonb_set(
    COALESCE(raw_app_meta_data, '{}'::jsonb),
    '{roles}',
    COALESCE(roles_array, '[]'::jsonb)
  )
  WHERE id = COALESCE(NEW.user_id, OLD.user_id);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_user_role_change ON public.user_roles;
CREATE TRIGGER on_user_role_change
  AFTER INSERT OR UPDATE OR DELETE ON public.user_roles
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_role_to_app_metadata();

-- Backfill app_metadata for any existing users
DO $$
DECLARE
  rec RECORD;
  roles_array JSONB;
BEGIN
  FOR rec IN SELECT DISTINCT user_id FROM public.user_roles LOOP
    SELECT jsonb_agg(role::text)
    INTO roles_array
    FROM public.user_roles
    WHERE user_id = rec.user_id;

    UPDATE auth.users
    SET raw_app_meta_data = jsonb_set(
      COALESCE(raw_app_meta_data, '{}'::jsonb),
      '{roles}',
      COALESCE(roles_array, '[]'::jsonb)
    )
    WHERE id = rec.user_id;
  END LOOP;
END $$;
