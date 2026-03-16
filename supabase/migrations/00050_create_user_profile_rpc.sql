-- Migration: Client-side fallback for user creation when Edge Function is unavailable
--
-- Problem: The create-user Edge Function may not be deployed, causing
--   ClientException: Failed to fetch. This blocks all admin user creation.
--
-- Solution: SECURITY DEFINER RPCs that handle profile+role+credentials+metadata,
--   so the Flutter client can use auth.signUp() + RPC as a fallback path.
--
-- Also fixes: missing super_admin INSERT/UPDATE policies on users/user_roles,
--   credential INSERT policy (was WITH CHECK(false) blocking RPC inserts),
--   and search_path on all SECURITY DEFINER functions (including 00041 originals).

-- ============================================================
-- 0. Fix search_path on existing SECURITY DEFINER functions from 00041
--    (prevents schema-shadowing attacks on SECURITY DEFINER context)
-- ============================================================

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
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public, auth;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.has_role('tenant_admin')
      OR public.has_role('principal')
      OR public.has_role('super_admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public, auth;

-- ============================================================
-- 1. Enhanced sync trigger: also sync tenant_id to app_metadata
--    Single query for roles + tenant_id (avoids N+1 per row event)
-- ============================================================

CREATE OR REPLACE FUNCTION public.sync_user_role_to_app_metadata()
RETURNS TRIGGER AS $$
DECLARE
  roles_array JSONB;
  v_tenant_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := COALESCE(NEW.user_id, OLD.user_id);

  -- Single query: collect roles + most recent tenant_id
  SELECT
    jsonb_agg(role::text),
    (array_agg(tenant_id ORDER BY created_at DESC))[1]
  INTO roles_array, v_tenant_id
  FROM public.user_roles
  WHERE user_id = v_user_id;

  -- Update auth.users with roles, tenant_id, and tenant_slug
  UPDATE auth.users
  SET raw_app_meta_data = jsonb_set(
    jsonb_set(
      jsonb_set(
        COALESCE(raw_app_meta_data, '{}'::jsonb),
        '{roles}',
        COALESCE(roles_array, '[]'::jsonb)
      ),
      '{tenant_id}',
      CASE WHEN v_tenant_id IS NOT NULL
        THEN to_jsonb(v_tenant_id::text)
        ELSE 'null'::jsonb
      END
    ),
    '{tenant_slug}',
    COALESCE(
      (SELECT to_jsonb(t.slug) FROM public.tenants t WHERE t.id = v_tenant_id),
      'null'::jsonb
    )
  )
  WHERE id = v_user_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

-- Trigger already exists from 00041, re-create to be safe:
DROP TRIGGER IF EXISTS on_user_role_change ON public.user_roles;
CREATE TRIGGER on_user_role_change
  AFTER INSERT OR UPDATE OR DELETE ON public.user_roles
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_role_to_app_metadata();

-- ============================================================
-- 2. Super admin ALL policies on users and user_roles (INSERT/UPDATE/DELETE)
--    Drop the old SELECT-only policies to avoid redundant duplicates.
-- ============================================================

-- Clean up old SELECT-only policies (superseded by FOR ALL)
DROP POLICY IF EXISTS "Super admins view all users" ON public.users;
DROP POLICY IF EXISTS "Super admins view all user_roles" ON public.user_roles;

DROP POLICY IF EXISTS "Super admins manage all users" ON public.users;
CREATE POLICY "Super admins manage all users"
  ON public.users FOR ALL
  USING  (public.has_role('super_admin'::user_role))
  WITH CHECK (public.has_role('super_admin'::user_role));

DROP POLICY IF EXISTS "Super admins manage all user_roles" ON public.user_roles;
CREATE POLICY "Super admins manage all user_roles"
  ON public.user_roles FOR ALL
  USING  (public.has_role('super_admin'::user_role))
  WITH CHECK (public.has_role('super_admin'::user_role));

-- ============================================================
-- 3. Allow RPC (SECURITY DEFINER) to insert into user_credentials
--    The old policy had WITH CHECK(false) which blocks even SECURITY DEFINER
--    when called from an RPC that does INSERT via the table directly.
--    Replace with a policy that allows admins who created the record.
-- ============================================================

DROP POLICY IF EXISTS "Service role inserts credentials" ON public.user_credentials;

CREATE POLICY "Admins insert credentials"
  ON public.user_credentials FOR INSERT
  WITH CHECK (
    public.has_role('super_admin'::user_role)
    OR public.is_admin()
  );

-- ============================================================
-- 4. delete_auth_user RPC — for rollback cleanup
--    Includes tenant scope check: non-super-admins can only delete
--    users belonging to their own tenant.
-- ============================================================

CREATE OR REPLACE FUNCTION public.delete_auth_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Permission check: only admins
  IF NOT (
    public.has_role('super_admin'::user_role)
    OR public.has_role('tenant_admin'::user_role)
    OR public.has_role('principal'::user_role)
  ) THEN
    RAISE EXCEPTION 'Permission denied: only admins can delete auth users';
  END IF;

  -- Tenant scope check: non-super-admins can only delete users in their own tenant
  IF NOT public.has_role('super_admin'::user_role) THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.users
      WHERE id = p_user_id
        AND tenant_id = public.tenant_id()
    ) THEN
      RAISE EXCEPTION 'Permission denied: user does not belong to your tenant';
    END IF;
  END IF;

  -- Delete from auth.users (cascades to public.users via FK)
  DELETE FROM auth.users WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth;

-- ============================================================
-- 5. create_user_profile RPC — handles everything except auth.signUp()
--
-- Fixes applied per review:
--   C3: Resolve p_created_by inside body, fail if NULL
--   H1: Full role hierarchy (principal can't create tenant_admin)
--   M1: Use ON CONFLICT DO NOTHING for retry safety
--   M2: Tenant scope guard for non-super-admins
--   M4: Basic email format validation
--   L1: Remove useless WHEN OTHERS THEN RAISE
--   L2: Remove redundant belt-and-suspenders auth.users UPDATE
-- ============================================================

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

  -- ---- Store initial credentials (plaintext) ----
  -- Stored as plaintext intentionally: admins use CredentialService.getCredentials()
  -- to display initial passwords to staff/teachers. RLS restricts reads to creator
  -- + super_admin only. Same pattern as the Edge Function in create-user/index.ts.
  INSERT INTO public.user_credentials (user_id, tenant_id, email, initial_password, created_by)
  VALUES (p_user_id, p_tenant_id, p_email, p_password, v_created_by)
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
