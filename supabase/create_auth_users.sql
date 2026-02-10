-- =============================================
-- Create Auth Users for Testing
-- Password: Demo@2026 for all users
-- =============================================

-- Super Admin
INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'superadmin@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(),
    '{"tenant_id":"00000000-0000-0000-0000-000000000001","roles":["super_admin"]}'::jsonb,
    '{"full_name":"Super Admin User"}'::jsonb,
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
);

-- Tenant Admin
INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '20000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'admin@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(),
    '{"tenant_id":"00000000-0000-0000-0000-000000000001","roles":["tenant_admin"]}'::jsonb,
    '{"full_name":"Admin User"}'::jsonb,
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
);

-- Teacher
INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '20000000-0000-0000-0000-000000000010',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'teacher1@demoschool.edu',
    crypt('Demo@2026', gen_salt('bf')),
    NOW(),
    '{"tenant_id":"00000000-0000-0000-0000-000000000001","roles":["teacher"]}'::jsonb,
    '{"full_name":"John Teacher"}'::jsonb,
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
);

-- Insert identities for each user
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES
    (gen_random_uuid(), '20000000-0000-0000-0000-000000000001', '{"sub":"20000000-0000-0000-0000-000000000001","email":"superadmin@demoschool.edu"}'::jsonb, 'email', '20000000-0000-0000-0000-000000000001', NOW(), NOW(), NOW()),
    (gen_random_uuid(), '20000000-0000-0000-0000-000000000002', '{"sub":"20000000-0000-0000-0000-000000000002","email":"admin@demoschool.edu"}'::jsonb, 'email', '20000000-0000-0000-0000-000000000002', NOW(), NOW(), NOW()),
    (gen_random_uuid(), '20000000-0000-0000-0000-000000000010', '{"sub":"20000000-0000-0000-0000-000000000010","email":"teacher1@demoschool.edu"}'::jsonb, 'email', '20000000-0000-0000-0000-000000000010', NOW(), NOW(), NOW());

-- Now create the user profiles and roles
-- Tenant first
INSERT INTO tenants (id, name, slug, email, phone, city, country, subscription_plan, is_active)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Demo School',
    'demo-school',
    'admin@demoschool.edu',
    '+1-555-0100',
    'New York',
    'USA',
    'enterprise',
    true
) ON CONFLICT (slug) DO NOTHING;

-- Super Admin User Profile
INSERT INTO users (id, email, tenant_id, is_active, created_at, updated_at)
VALUES (
    '20000000-0000-0000-0000-000000000001',
    'superadmin@demoschool.edu',
    '00000000-0000-0000-0000-000000000001',
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (user_id, tenant_id, role, is_primary, created_at)
VALUES (
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'super_admin',
    true,
    NOW()
) ON CONFLICT (user_id, tenant_id, role) DO NOTHING;

-- Admin User Profile
INSERT INTO users (id, email, tenant_id, is_active, created_at, updated_at)
VALUES (
    '20000000-0000-0000-0000-000000000002',
    'admin@demoschool.edu',
    '00000000-0000-0000-0000-000000000001',
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (user_id, tenant_id, role, is_primary, created_at)
VALUES (
    '20000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'tenant_admin',
    true,
    NOW()
) ON CONFLICT (user_id, tenant_id, role) DO NOTHING;

-- Teacher User Profile
INSERT INTO users (id, email, tenant_id, is_active, created_at, updated_at)
VALUES (
    '20000000-0000-0000-0000-000000000010',
    'teacher1@demoschool.edu',
    '00000000-0000-0000-0000-000000000001',
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (user_id, tenant_id, role, is_primary, created_at)
VALUES (
    '20000000-0000-0000-0000-000000000010',
    '00000000-0000-0000-0000-000000000001',
    'teacher',
    true,
    NOW()
) ON CONFLICT (user_id, tenant_id, role) DO NOTHING;
