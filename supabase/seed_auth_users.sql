-- =============================================
-- Create auth.users for local Supabase
-- Password for all users: Demo@2026
-- =============================================

-- The password hash below is bcrypt for 'Demo@2026'
-- Generated via: SELECT crypt('Demo@2026', gen_salt('bf'));

INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token,
    raw_app_meta_data, raw_user_meta_data, is_super_admin
)
VALUES
-- Super Admin
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated',
    'superadmin@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["super_admin"]}'::jsonb,
    '{"full_name": "Super Admin User"}'::jsonb,
    false
),
-- Tenant Admin
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated',
    'admin@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["tenant_admin"]}'::jsonb,
    '{"full_name": "Admin User"}'::jsonb,
    false
),
-- Principal
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000003',
    'authenticated', 'authenticated',
    'principal@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["principal"]}'::jsonb,
    '{"full_name": "Dr. Principal Smith"}'::jsonb,
    false
),
-- Teacher 1
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000010',
    'authenticated', 'authenticated',
    'teacher1@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["teacher"]}'::jsonb,
    '{"full_name": "John Teacher"}'::jsonb,
    false
),
-- Teacher 2
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000011',
    'authenticated', 'authenticated',
    'teacher2@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["teacher"]}'::jsonb,
    '{"full_name": "Mary Teacher"}'::jsonb,
    false
),
-- Teacher 3
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000012',
    'authenticated', 'authenticated',
    'teacher3@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["teacher"]}'::jsonb,
    '{"full_name": "Bob Teacher"}'::jsonb,
    false
),
-- Accountant
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000020',
    'authenticated', 'authenticated',
    'accountant@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["accountant"]}'::jsonb,
    '{"full_name": "Alice Accountant"}'::jsonb,
    false
),
-- Student 1
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000100',
    'authenticated', 'authenticated',
    'student1@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["student"]}'::jsonb,
    '{"full_name": "Emma Student"}'::jsonb,
    false
),
-- Student 2
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000101',
    'authenticated', 'authenticated',
    'student2@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["student"]}'::jsonb,
    '{"full_name": "Liam Student"}'::jsonb,
    false
),
-- Student 3
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000102',
    'authenticated', 'authenticated',
    'student3@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["student"]}'::jsonb,
    '{"full_name": "Olivia Student"}'::jsonb,
    false
),
-- Student 4
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000103',
    'authenticated', 'authenticated',
    'student4@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["student"]}'::jsonb,
    '{"full_name": "Noah Student"}'::jsonb,
    false
),
-- Student 5
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000104',
    'authenticated', 'authenticated',
    'student5@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["student"]}'::jsonb,
    '{"full_name": "Ava Student"}'::jsonb,
    false
),
-- Parent 1
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000200',
    'authenticated', 'authenticated',
    'parent1@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["parent"]}'::jsonb,
    '{"full_name": "Robert Parent"}'::jsonb,
    false
),
-- Parent 2
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000201',
    'authenticated', 'authenticated',
    'parent2@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["parent"]}'::jsonb,
    '{"full_name": "Sarah Parent"}'::jsonb,
    false
),
-- Parent 3
(
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000202',
    'authenticated', 'authenticated',
    'parent3@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '',
    '{"provider": "email", "providers": ["email"], "tenant_id": "00000000-0000-0000-0000-000000000001", "roles": ["parent"]}'::jsonb,
    '{"full_name": "Michael Parent"}'::jsonb,
    false
)
ON CONFLICT (id) DO NOTHING;

-- Create identities for each auth user (required by Supabase auth)
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
SELECT
    u.id,
    u.id,
    jsonb_build_object('sub', u.id::text, 'email', u.email),
    'email',
    u.id::text,
    NOW(),
    NOW(),
    NOW()
FROM auth.users u
WHERE u.id IN (
    '20000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000010',
    '20000000-0000-0000-0000-000000000011',
    '20000000-0000-0000-0000-000000000012',
    '20000000-0000-0000-0000-000000000020',
    '20000000-0000-0000-0000-000000000100',
    '20000000-0000-0000-0000-000000000101',
    '20000000-0000-0000-0000-000000000102',
    '20000000-0000-0000-0000-000000000103',
    '20000000-0000-0000-0000-000000000104',
    '20000000-0000-0000-0000-000000000200',
    '20000000-0000-0000-0000-000000000201',
    '20000000-0000-0000-0000-000000000202'
)
ON CONFLICT DO NOTHING;

DO $$
BEGIN
    RAISE NOTICE '✅ Auth users created successfully!';
    RAISE NOTICE 'All users have password: Demo@2026';
END $$;
