-- Check if admin@demo.edu data exists in database
-- Run this in Supabase SQL Editor

-- 1. Check auth.users
SELECT 'Auth users:' as check, COUNT(*) as count
FROM auth.users
WHERE email = 'admin@demo.edu';

-- 2. Check public.users
SELECT 'Public users:' as check, COUNT(*) as count
FROM users
WHERE email = 'admin@demo.edu';

-- 3. Check user_roles
SELECT 'User roles:' as check, COUNT(*) as count
FROM user_roles
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'admin@demo.edu')
  AND role = 'tenant_admin';

-- 4. Show detailed user data
SELECT
  u.id,
  u.email,
  u.full_name,
  u.tenant_id,
  json_agg(json_build_object(
    'role', ur.role,
    'is_primary', ur.is_primary,
    'tenant_id', ur.tenant_id
  )) as user_roles
FROM users u
LEFT JOIN user_roles ur ON ur.user_id = u.id
WHERE u.email = 'admin@demo.edu'
GROUP BY u.id, u.email, u.full_name, u.tenant_id;

-- 5. Check app_metadata in auth.users
SELECT
  email,
  raw_app_meta_data->>'tenant_id' as tenant_id,
  raw_app_meta_data->>'roles' as roles
FROM auth.users
WHERE email = 'admin@demo.edu';
