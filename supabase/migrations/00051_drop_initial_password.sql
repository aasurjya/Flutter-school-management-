-- 2026-05-16: drop plaintext password column (security audit finding CRITICAL-1)
--
-- Self-contained migration: first recreate create_user_profile() without the
-- initial_password INSERT, THEN drop the column. Atomic deploy — no caller
-- breaks because CREATE OR REPLACE supersedes the 00050 definition before
-- the column disappears.

CREATE OR REPLACE FUNCTION public.create_user_profile(
  p_user_id UUID,
  p_tenant_id UUID,
  p_email TEXT,
  p_full_name TEXT,
  p_role user_role,
  p_password TEXT,
  p_phone TEXT DEFAULT NULL,
  p_created_by UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_caller_is_super BOOLEAN;
  v_caller_is_admin BOOLEAN;
  v_caller_is_principal BOOLEAN;
  v_tenant_slug TEXT;
  v_created_by UUID;
BEGIN
  -- ---- Resolve created_by (C3 fix) ----
  v_created_by := COALESCE(p_created_by, auth.uid());
  IF v_created_by IS NULL THEN
    RAISE EXCEPTION 'created_by could not be resolved: no JWT or explicit value';
  END IF;

  -- ---- Permission check ----
  v_caller_is_super := public.has_role('super_admin'::user_role);
  v_caller_is_admin := public.is_admin();

  IF NOT (v_caller_is_super OR v_caller_is_admin) THEN
    RAISE EXCEPTION 'Permission denied: only super_admin, tenant_admin, or principal can create users';
  END IF;

  -- ---- Tenant scope guard (M2 fix) ----
  IF NOT v_caller_is_super THEN
    IF p_tenant_id != public.tenant_id() THEN
      RAISE EXCEPTION 'Permission denied: cannot create users in a different tenant';
    END IF;
  END IF;

  -- ---- Role hierarchy (H1 fix: full hierarchy) ----
  v_caller_is_principal := public.has_role('principal'::user_role);

  IF NOT v_caller_is_super THEN
    -- No non-super can create super_admin
    IF p_role = 'super_admin' THEN
      RAISE EXCEPTION 'Permission denied: only super_admin can create super_admin role';
    END IF;

    -- Only super_admin can create principal
    IF p_role = 'principal' THEN
      RAISE EXCEPTION 'Permission denied: only super_admin can create principal role';
    END IF;

    -- Only super_admin or principal can create tenant_admin
    IF p_role = 'tenant_admin' AND NOT v_caller_is_principal THEN
      -- tenant_admin trying to create another tenant_admin is blocked
      -- (principal can create tenant_admin, tenant_admin cannot)
      RAISE EXCEPTION 'Permission denied: only super_admin or principal can create tenant_admin role';
    END IF;
  END IF;

  -- ---- Email format validation (M4 fix) ----
  IF p_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' THEN
    RAISE EXCEPTION 'Invalid email format: %', p_email;
  END IF;

  -- ---- Look up tenant slug ----
  SELECT slug INTO v_tenant_slug
  FROM public.tenants
  WHERE id = p_tenant_id;

  IF v_tenant_slug IS NULL THEN
    RAISE EXCEPTION 'Tenant not found: %', p_tenant_id;
  END IF;

  -- ---- Insert user profile (M1 fix: ON CONFLICT for retry safety) ----
  INSERT INTO public.users (id, tenant_id, email, full_name, phone, is_active)
  VALUES (p_user_id, p_tenant_id, p_email, p_full_name, p_phone, true)
  ON CONFLICT (id) DO NOTHING;

  -- ---- Assign role ----
  -- (This triggers sync_user_role_to_app_metadata which sets roles + tenant_id + tenant_slug)
  INSERT INTO public.user_roles (user_id, tenant_id, role, is_primary)
  VALUES (p_user_id, p_tenant_id, p_role, true)
  ON CONFLICT (user_id, tenant_id, role) DO NOTHING;

  -- Audit log only: who created this user. Password is returned once in response, never persisted.
  INSERT INTO public.user_credentials (user_id, tenant_id, email, created_by)
  VALUES (p_user_id, p_tenant_id, p_email, v_created_by)
  ON CONFLICT (user_id) DO NOTHING;

  -- ---- Confirm email so user can log in immediately ----
  -- The sync trigger already set roles/tenant_id/tenant_slug on app_metadata,
  -- so we only need to confirm the email here.
  UPDATE auth.users
  SET email_confirmed_at = COALESCE(email_confirmed_at, now())
  WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'user_id', p_user_id,
    'email', p_email,
    'role', p_role::text,
    'tenant_id', p_tenant_id,
    'success', true
  );

EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'User profile already exists for this user ID or email';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

ALTER TABLE public.user_credentials DROP COLUMN IF EXISTS initial_password;

COMMENT ON FUNCTION public.create_user_profile IS 'Tenant-scoped user-profile creation. Password is bcrypted by Supabase auth; no plaintext is ever stored. Audit: 2026-05-16 SPRINT 1 task A1.';
