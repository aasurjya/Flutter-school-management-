-- Consolidated demo-login seeder
-- 13 accounts as documented in LOGIN_CREDENTIALS.md
-- Password (all): Demo@2026
-- Tenant: Demo School (a1b2c3d4-e5f6-7890-abcd-ef1234567890) — the one seed.sql created
-- Idempotent: ON CONFLICT DO UPDATE on every insert.

BEGIN;

-- 1. auth.users
INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
)
SELECT
    v.id::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    v.email,
    crypt('Demo@2026', gen_salt('bf')),
    NOW(),
    jsonb_build_object(
        'provider', 'email',
        'providers', ARRAY['email'],
        'tenant_id', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'roles',      ARRAY[v.role_name]
    ),
    jsonb_build_object('full_name', v.full_name),
    NOW(), NOW(),
    '', '', '', ''
FROM (VALUES
    ('20000000-0000-0000-0000-000000000001', 'superadmin@demoschool.edu',  'Super Admin',          'super_admin'),
    ('20000000-0000-0000-0000-000000000002', 'admin@demoschool.edu',       'Tenant Admin',         'tenant_admin'),
    ('20000000-0000-0000-0000-000000000003', 'principal@demoschool.edu',   'Dr. Principal Smith',  'principal'),
    ('20000000-0000-0000-0000-000000000010', 'teacher1@demoschool.edu',    'John Teacher',         'teacher'),
    ('20000000-0000-0000-0000-000000000011', 'teacher2@demoschool.edu',    'Mary Teacher',         'teacher'),
    ('20000000-0000-0000-0000-000000000012', 'teacher3@demoschool.edu',    'Bob Teacher',          'teacher'),
    ('20000000-0000-0000-0000-000000000020', 'accountant@demoschool.edu',  'Alice Accountant',     'accountant'),
    ('20000000-0000-0000-0000-000000000100', 'student1@demoschool.edu',    'Emma Student',         'student'),
    ('20000000-0000-0000-0000-000000000101', 'student2@demoschool.edu',    'Liam Student',         'student'),
    ('20000000-0000-0000-0000-000000000102', 'student3@demoschool.edu',    'Olivia Student',       'student'),
    ('20000000-0000-0000-0000-000000000103', 'student4@demoschool.edu',    'Noah Student',         'student'),
    ('20000000-0000-0000-0000-000000000104', 'student5@demoschool.edu',    'Ava Student',          'student'),
    ('20000000-0000-0000-0000-000000000200', 'parent1@demoschool.edu',     'Robert Parent',        'parent'),
    ('20000000-0000-0000-0000-000000000201', 'parent2@demoschool.edu',     'Sarah Parent',         'parent'),
    ('20000000-0000-0000-0000-000000000202', 'parent3@demoschool.edu',     'Michael Parent',       'parent')
) AS v(id, email, full_name, role_name)
ON CONFLICT (id) DO UPDATE
SET email             = EXCLUDED.email,
    encrypted_password= EXCLUDED.encrypted_password,
    email_confirmed_at= EXCLUDED.email_confirmed_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data= EXCLUDED.raw_user_meta_data,
    updated_at        = NOW();

-- 2. auth.identities (email provider)
INSERT INTO auth.identities (
    provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
)
SELECT
    v.id::uuid::text,
    v.id::uuid,
    jsonb_build_object(
        'sub',            v.id,
        'email',          v.email,
        'email_verified', true,
        'phone_verified', false
    ),
    'email',
    NOW(), NOW(), NOW()
FROM (VALUES
    ('20000000-0000-0000-0000-000000000001', 'superadmin@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000002', 'admin@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000003', 'principal@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000010', 'teacher1@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000011', 'teacher2@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000012', 'teacher3@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000020', 'accountant@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000100', 'student1@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000101', 'student2@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000102', 'student3@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000103', 'student4@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000104', 'student5@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000200', 'parent1@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000201', 'parent2@demoschool.edu'),
    ('20000000-0000-0000-0000-000000000202', 'parent3@demoschool.edu')
) AS v(id, email)
ON CONFLICT (provider_id, provider) DO UPDATE
SET identity_data = EXCLUDED.identity_data,
    updated_at    = NOW();

-- 3. public.users (mirrors auth.users; users_id_fkey -> auth.users)
INSERT INTO public.users (id, tenant_id, email, full_name, is_active, profile_complete)
SELECT
    v.id::uuid,
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid,
    v.email,
    v.full_name,
    true,
    true
FROM (VALUES
    ('20000000-0000-0000-0000-000000000001', 'superadmin@demoschool.edu', 'Super Admin'),
    ('20000000-0000-0000-0000-000000000002', 'admin@demoschool.edu',      'Tenant Admin'),
    ('20000000-0000-0000-0000-000000000003', 'principal@demoschool.edu',  'Dr. Principal Smith'),
    ('20000000-0000-0000-0000-000000000010', 'teacher1@demoschool.edu',   'John Teacher'),
    ('20000000-0000-0000-0000-000000000011', 'teacher2@demoschool.edu',   'Mary Teacher'),
    ('20000000-0000-0000-0000-000000000012', 'teacher3@demoschool.edu',   'Bob Teacher'),
    ('20000000-0000-0000-0000-000000000020', 'accountant@demoschool.edu', 'Alice Accountant'),
    ('20000000-0000-0000-0000-000000000100', 'student1@demoschool.edu',   'Emma Student'),
    ('20000000-0000-0000-0000-000000000101', 'student2@demoschool.edu',   'Liam Student'),
    ('20000000-0000-0000-0000-000000000102', 'student3@demoschool.edu',   'Olivia Student'),
    ('20000000-0000-0000-0000-000000000103', 'student4@demoschool.edu',   'Noah Student'),
    ('20000000-0000-0000-0000-000000000104', 'student5@demoschool.edu',   'Ava Student'),
    ('20000000-0000-0000-0000-000000000200', 'parent1@demoschool.edu',    'Robert Parent'),
    ('20000000-0000-0000-0000-000000000201', 'parent2@demoschool.edu',    'Sarah Parent'),
    ('20000000-0000-0000-0000-000000000202', 'parent3@demoschool.edu',    'Michael Parent')
) AS v(id, email, full_name)
ON CONFLICT (id) DO UPDATE
SET email     = EXCLUDED.email,
    tenant_id = EXCLUDED.tenant_id,
    full_name = EXCLUDED.full_name,
    is_active = true,
    updated_at = NOW();

-- 4. public.user_roles
INSERT INTO public.user_roles (user_id, tenant_id, role, is_primary)
SELECT
    v.id::uuid,
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid,
    v.role_name::user_role,
    true
FROM (VALUES
    ('20000000-0000-0000-0000-000000000001', 'super_admin'),
    ('20000000-0000-0000-0000-000000000002', 'tenant_admin'),
    ('20000000-0000-0000-0000-000000000003', 'principal'),
    ('20000000-0000-0000-0000-000000000010', 'teacher'),
    ('20000000-0000-0000-0000-000000000011', 'teacher'),
    ('20000000-0000-0000-0000-000000000012', 'teacher'),
    ('20000000-0000-0000-0000-000000000020', 'accountant'),
    ('20000000-0000-0000-0000-000000000100', 'student'),
    ('20000000-0000-0000-0000-000000000101', 'student'),
    ('20000000-0000-0000-0000-000000000102', 'student'),
    ('20000000-0000-0000-0000-000000000103', 'student'),
    ('20000000-0000-0000-0000-000000000104', 'student'),
    ('20000000-0000-0000-0000-000000000200', 'parent'),
    ('20000000-0000-0000-0000-000000000201', 'parent'),
    ('20000000-0000-0000-0000-000000000202', 'parent')
) AS v(id, role_name)
ON CONFLICT (user_id, tenant_id, role) DO NOTHING;

-- 6. Domain rows for the two student accounts the login panel actually
--    advertises (student4=Noah, student5=Ava) plus the parent (parent3=
--    Michael) who is supposed to see both as a multi-child view.
--    Without these, the accounts can authenticate but the app shows
--    "Student profile not found." — auth.users/public.users/user_roles
--    alone aren't enough to render a student or parent dashboard.
INSERT INTO students (
    id, tenant_id, user_id, admission_number, first_name, last_name,
    date_of_birth, gender, nationality, admission_date, is_active
) VALUES
    ('55555555-5555-5555-5555-555555555560', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
     '20000000-0000-0000-0000-000000000103', 'DEMO2024006', 'Noah', 'Student',
     '2009-08-20', 'Male', 'Indian', '2024-04-01', true),
    ('55555555-5555-5555-5555-555555555561', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
     '20000000-0000-0000-0000-000000000104', 'DEMO2024007', 'Ava', 'Student',
     '2011-02-11', 'Female', 'Indian', '2024-04-01', true)
ON CONFLICT (id) DO UPDATE SET user_id = EXCLUDED.user_id;

INSERT INTO student_enrollments (
    tenant_id, student_id, section_id, academic_year_id, roll_number, status
) VALUES
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555560',
     'dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '6', 'active'),
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555561',
     'dddddddd-dddd-dddd-dddd-dddddddddd02', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '7', 'active')
ON CONFLICT (student_id, academic_year_id) DO NOTHING;

INSERT INTO parents (
    id, tenant_id, user_id, first_name, last_name, relation, email, phone
) VALUES
    ('66666666-6666-6666-6666-666666666670', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
     '20000000-0000-0000-0000-000000000202', 'Michael', 'Parent', 'father',
     'parent3@demoschool.edu', '9800000202')
ON CONFLICT (id) DO UPDATE SET user_id = EXCLUDED.user_id;

INSERT INTO student_parents (student_id, parent_id, is_primary, can_pickup)
VALUES
    ('55555555-5555-5555-5555-555555555560', '66666666-6666-6666-6666-666666666670', true, true),
    ('55555555-5555-5555-5555-555555555561', '66666666-6666-6666-6666-666666666670', true, true)
ON CONFLICT DO NOTHING;

COMMIT;

DO $$
DECLARE auth_cnt int; pub_cnt int; role_cnt int;
BEGIN
    SELECT COUNT(*) INTO auth_cnt FROM auth.users      WHERE email LIKE '%@demoschool.edu';
    SELECT COUNT(*) INTO pub_cnt  FROM public.users    WHERE email LIKE '%@demoschool.edu';
    SELECT COUNT(*) INTO role_cnt FROM public.user_roles ur
        JOIN public.users u ON u.id = ur.user_id WHERE u.email LIKE '%@demoschool.edu';
    RAISE NOTICE '✅ Demo logins seeded: auth.users=%, public.users=%, user_roles=%',
        auth_cnt, pub_cnt, role_cnt;
END $$;
