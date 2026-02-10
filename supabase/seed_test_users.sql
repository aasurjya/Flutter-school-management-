-- =============================================
-- SEED TEST USERS FOR SCHOOL MANAGEMENT SYSTEM
-- =============================================
--
-- IMPORTANT: This script creates test users for development/testing.
-- Run this in Supabase SQL Editor after running migrations.
--
-- HOW TO CREATE USERS:
-- 1. Go to Supabase Dashboard > Authentication > Users
-- 2. Click "Add user" and create each user with the credentials below
-- 3. After creating ALL users in the Auth dashboard, run this SQL script
--
-- TEST CREDENTIALS:
-- ┌──────────────────┬──────────────────────────────┬─────────────────┐
-- │ Role             │ Email                        │ Password        │
-- ├──────────────────┼──────────────────────────────┼─────────────────┤
-- │ Super Admin      │ superadmin@edusaas.com       │ SuperAdmin@2024 │
-- │ Tenant Admin     │ admin@greenvalley.edu        │ Admin@2024      │
-- │ Principal        │ principal@greenvalley.edu    │ Principal@2024  │
-- │ Teacher          │ teacher@greenvalley.edu      │ Teacher@2024    │
-- │ Student          │ student@greenvalley.edu      │ Student@2024    │
-- │ Parent           │ parent@greenvalley.edu       │ Parent@2024     │
-- └──────────────────┴──────────────────────────────┴─────────────────┘

-- =============================================
-- STEP 1: Create a demo tenant (school)
-- =============================================
INSERT INTO public.tenants (id, name, slug, logo_url, address, phone, email, is_active, settings)
VALUES (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'Green Valley International School',
    'greenvalley',
    NULL,
    '123 Education Street, Knowledge City',
    '+91 98765 43210',
    'info@greenvalley.edu',
    true,
    '{"currency": "INR", "timezone": "Asia/Kolkata", "academic_year_start_month": 4}'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    is_active = true;

-- =============================================
-- STEP 2: Create users in public.users table
-- This links auth.users to our application data
-- =============================================

DO $$
DECLARE
    v_super_admin_id UUID;
    v_tenant_admin_id UUID;
    v_principal_id UUID;
    v_teacher_id UUID;
    v_student_user_id UUID;
    v_parent_id UUID;
    v_tenant_id UUID := 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
BEGIN
    -- Get user IDs from auth.users (these users must exist in Supabase Auth first)
    SELECT id INTO v_super_admin_id FROM auth.users WHERE email = 'superadmin@edusaas.com';
    SELECT id INTO v_tenant_admin_id FROM auth.users WHERE email = 'admin@greenvalley.edu';
    SELECT id INTO v_principal_id FROM auth.users WHERE email = 'principal@greenvalley.edu';
    SELECT id INTO v_teacher_id FROM auth.users WHERE email = 'teacher@greenvalley.edu';
    SELECT id INTO v_student_user_id FROM auth.users WHERE email = 'student@greenvalley.edu';
    SELECT id INTO v_parent_id FROM auth.users WHERE email = 'parent@greenvalley.edu';

    -- Check which users exist
    RAISE NOTICE 'Super Admin ID: %', v_super_admin_id;
    RAISE NOTICE 'Tenant Admin ID: %', v_tenant_admin_id;
    RAISE NOTICE 'Principal ID: %', v_principal_id;
    RAISE NOTICE 'Teacher ID: %', v_teacher_id;
    RAISE NOTICE 'Student User ID: %', v_student_user_id;
    RAISE NOTICE 'Parent ID: %', v_parent_id;

    -- Create Super Admin (no tenant - platform level)
    IF v_super_admin_id IS NOT NULL THEN
        INSERT INTO public.users (id, email, full_name, phone, is_active, created_at, updated_at)
        VALUES (v_super_admin_id, 'superadmin@edusaas.com', 'Platform Super Admin', '+91 9999900001', true, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, is_active = true, updated_at = NOW();

        INSERT INTO public.user_roles (user_id, role, is_primary, created_at)
        VALUES (v_super_admin_id, 'super_admin', true, NOW())
        ON CONFLICT (user_id, role) DO UPDATE SET is_primary = true;

        RAISE NOTICE 'Super Admin created successfully!';
    ELSE
        RAISE NOTICE 'WARNING: Super Admin user not found in auth.users. Please create user first.';
    END IF;

    -- Create Tenant Admin
    IF v_tenant_admin_id IS NOT NULL THEN
        INSERT INTO public.users (id, tenant_id, email, full_name, phone, is_active, created_at, updated_at)
        VALUES (v_tenant_admin_id, v_tenant_id, 'admin@greenvalley.edu', 'Rajesh Kumar', '+91 9999900002', true, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, tenant_id = v_tenant_id, is_active = true, updated_at = NOW();

        INSERT INTO public.user_roles (user_id, tenant_id, role, is_primary, created_at)
        VALUES (v_tenant_admin_id, v_tenant_id, 'tenant_admin', true, NOW())
        ON CONFLICT (user_id, role) DO UPDATE SET is_primary = true, tenant_id = v_tenant_id;

        RAISE NOTICE 'Tenant Admin created successfully!';
    ELSE
        RAISE NOTICE 'WARNING: Tenant Admin user not found in auth.users. Please create user first.';
    END IF;

    -- Create Principal
    IF v_principal_id IS NOT NULL THEN
        INSERT INTO public.users (id, tenant_id, email, full_name, phone, is_active, created_at, updated_at)
        VALUES (v_principal_id, v_tenant_id, 'principal@greenvalley.edu', 'Dr. Sharma', '+91 9999900003', true, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, tenant_id = v_tenant_id, is_active = true, updated_at = NOW();

        INSERT INTO public.user_roles (user_id, tenant_id, role, is_primary, created_at)
        VALUES (v_principal_id, v_tenant_id, 'principal', true, NOW())
        ON CONFLICT (user_id, role) DO UPDATE SET is_primary = true, tenant_id = v_tenant_id;

        RAISE NOTICE 'Principal created successfully!';
    ELSE
        RAISE NOTICE 'WARNING: Principal user not found in auth.users. Please create user first.';
    END IF;

    -- Create Teacher
    IF v_teacher_id IS NOT NULL THEN
        INSERT INTO public.users (id, tenant_id, email, full_name, phone, is_active, created_at, updated_at)
        VALUES (v_teacher_id, v_tenant_id, 'teacher@greenvalley.edu', 'Priya Singh', '+91 9999900004', true, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, tenant_id = v_tenant_id, is_active = true, updated_at = NOW();

        INSERT INTO public.user_roles (user_id, tenant_id, role, is_primary, created_at)
        VALUES (v_teacher_id, v_tenant_id, 'teacher', true, NOW())
        ON CONFLICT (user_id, role) DO UPDATE SET is_primary = true, tenant_id = v_tenant_id;

        RAISE NOTICE 'Teacher created successfully!';
    ELSE
        RAISE NOTICE 'WARNING: Teacher user not found in auth.users. Please create user first.';
    END IF;

    -- Create Student User
    IF v_student_user_id IS NOT NULL THEN
        INSERT INTO public.users (id, tenant_id, email, full_name, phone, is_active, created_at, updated_at)
        VALUES (v_student_user_id, v_tenant_id, 'student@greenvalley.edu', 'Arjun Patel', '+91 9999900005', true, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, tenant_id = v_tenant_id, is_active = true, updated_at = NOW();

        INSERT INTO public.user_roles (user_id, tenant_id, role, is_primary, created_at)
        VALUES (v_student_user_id, v_tenant_id, 'student', true, NOW())
        ON CONFLICT (user_id, role) DO UPDATE SET is_primary = true, tenant_id = v_tenant_id;

        RAISE NOTICE 'Student created successfully!';
    ELSE
        RAISE NOTICE 'WARNING: Student user not found in auth.users. Please create user first.';
    END IF;

    -- Create Parent
    IF v_parent_id IS NOT NULL THEN
        INSERT INTO public.users (id, tenant_id, email, full_name, phone, is_active, created_at, updated_at)
        VALUES (v_parent_id, v_tenant_id, 'parent@greenvalley.edu', 'Vikram Patel', '+91 9999900006', true, NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, tenant_id = v_tenant_id, is_active = true, updated_at = NOW();

        INSERT INTO public.user_roles (user_id, tenant_id, role, is_primary, created_at)
        VALUES (v_parent_id, v_tenant_id, 'parent', true, NOW())
        ON CONFLICT (user_id, role) DO UPDATE SET is_primary = true, tenant_id = v_tenant_id;

        RAISE NOTICE 'Parent created successfully!';
    ELSE
        RAISE NOTICE 'WARNING: Parent user not found in auth.users. Please create user first.';
    END IF;

    RAISE NOTICE '========================================';
    RAISE NOTICE 'User creation complete!';
    RAISE NOTICE 'Remember to create users in Supabase Auth first if any are missing.';
    RAISE NOTICE '========================================';
END $$;

-- =============================================
-- STEP 3: Verify created users
-- =============================================
SELECT
    u.id,
    u.email,
    u.full_name,
    u.tenant_id,
    t.name as tenant_name,
    ur.role,
    ur.is_primary
FROM public.users u
LEFT JOIN public.tenants t ON u.tenant_id = t.id
LEFT JOIN public.user_roles ur ON u.id = ur.user_id
ORDER BY ur.role;
