-- Create demo users via SQL (simpler method)
-- Note: This creates users but they won't have the app_metadata set correctly
-- Better to use the Supabase Auth UI for setting metadata

-- Just insert into the public tables (users will be created via UI)
-- This SQL is for reference - use the UI method instead

-- Teacher profile
INSERT INTO users (id, tenant_id, email, full_name, phone)
SELECT id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'teacher@demo.edu', 'John Teacher', NULL
FROM auth.users WHERE email = 'teacher@demo.edu'
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
SELECT id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'teacher', true
FROM auth.users WHERE email = 'teacher@demo.edu'
ON CONFLICT (user_id, tenant_id, role) DO NOTHING;

-- Student profile
INSERT INTO users (id, tenant_id, email, full_name, phone)
SELECT id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'student@demo.edu', 'Alice Student', NULL
FROM auth.users WHERE email = 'student@demo.edu'
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
SELECT id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'student', true
FROM auth.users WHERE email = 'student@demo.edu'
ON CONFLICT (user_id, tenant_id, role) DO NOTHING;

-- Parent profile
INSERT INTO users (id, tenant_id, email, full_name, phone)
SELECT id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'parent@demo.edu', 'Bob Parent', NULL
FROM auth.users WHERE email = 'parent@demo.edu'
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
SELECT id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'parent', true
FROM auth.users WHERE email = 'parent@demo.edu'
ON CONFLICT (user_id, tenant_id, role) DO NOTHING;
