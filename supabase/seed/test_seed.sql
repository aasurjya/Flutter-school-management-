-- =============================================================
-- test_seed.sql — minimal fixture data for integration tests
--
-- Creates:
--   • One test tenant
--   • One auth user + users row + user_roles (tenant_admin)
--   • One academic year, one class, one section
--
-- Apply manually:
--   psql $DATABASE_URL -f supabase/seed/test_seed.sql
--
-- Or via Supabase CLI:
--   supabase db execute --file supabase/seed/test_seed.sql
-- =============================================================

-- Idempotent: wrap in a transaction so partial runs can be re-applied.
BEGIN;

-- ---------------------------------------------------------------
-- 1. Tenant
-- ---------------------------------------------------------------
INSERT INTO public.tenants (
    id, name, slug, subscription_plan, is_active, created_at, updated_at
)
VALUES (
    'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
    'Test School',
    'test-school',
    'premium',
    true,
    now(),
    now()
)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------
-- 2. Auth user (Supabase managed table)
--    Password hash below is for: TestAdmin@123!
--    NOTE: In CI, the user is created via the Supabase auth API
--    (supabase.auth.admin.createUser) rather than direct SQL.
--    This seed entry is a fallback for local psql runs.
-- ---------------------------------------------------------------
INSERT INTO auth.users (
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin
)
VALUES (
    'bbbbbbbb-0000-0000-0000-000000000001'::uuid,
    'authenticated',
    'authenticated',
    'test-admin@school.test',
    crypt('TestAdmin@123!', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider": "email", "providers": ["email"], "tenant_id": "aaaaaaaa-0000-0000-0000-000000000001"}'::jsonb,
    '{"full_name": "Test Admin"}'::jsonb,
    false
)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------
-- 3. Application users row
-- ---------------------------------------------------------------
INSERT INTO public.users (
    id, tenant_id, email, full_name, is_active, created_at, updated_at
)
VALUES (
    'bbbbbbbb-0000-0000-0000-000000000001'::uuid,
    'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
    'test-admin@school.test',
    'Test Admin',
    true,
    now(),
    now()
)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------
-- 4. User role
-- ---------------------------------------------------------------
INSERT INTO public.user_roles (
    user_id, tenant_id, role, is_primary, created_at
)
VALUES (
    'bbbbbbbb-0000-0000-0000-000000000001'::uuid,
    'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
    'tenant_admin',
    true,
    now()
)
ON CONFLICT (user_id, tenant_id, role) DO NOTHING;

-- ---------------------------------------------------------------
-- 5. Academic year
-- ---------------------------------------------------------------
INSERT INTO public.academic_years (
    id, tenant_id, name, start_date, end_date, is_current, created_at, updated_at
)
VALUES (
    'cccccccc-0000-0000-0000-000000000001'::uuid,
    'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
    '2025-26',
    '2025-04-01',
    '2026-03-31',
    true,
    now(),
    now()
)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------
-- 6. Class
-- ---------------------------------------------------------------
INSERT INTO public.classes (
    id, tenant_id, name, numeric_name, sequence_order, created_at, updated_at
)
VALUES (
    'dddddddd-0000-0000-0000-000000000001'::uuid,
    'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
    'Class 10',
    10,
    10,
    now(),
    now()
)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------
-- 7. Section
-- ---------------------------------------------------------------
INSERT INTO public.sections (
    id, tenant_id, class_id, name, capacity, created_at, updated_at
)
VALUES (
    'eeeeeeee-0000-0000-0000-000000000001'::uuid,
    'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
    'dddddddd-0000-0000-0000-000000000001'::uuid,
    'A',
    40,
    now(),
    now()
)
ON CONFLICT (id) DO NOTHING;

COMMIT;
