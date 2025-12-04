-- Verify seed data is complete
-- Run this in Supabase SQL Editor to check all required rows exist

-- Check tenant
SELECT 'Tenant check:' as check_type, COUNT(*) as count 
FROM tenants 
WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- Check auth.users
SELECT 'Auth users check:' as check_type, COUNT(*) as count 
FROM auth.users 
WHERE email = 'admin@demo-school.edu';

-- Check public.users
SELECT 'Public users check:' as check_type, COUNT(*) as count 
FROM users 
WHERE email = 'admin@demo-school.edu';

-- Check user_roles
SELECT 'User roles check:' as check_type, COUNT(*) as count 
FROM user_roles 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'admin@demo-school.edu')
  AND role = 'tenant_admin'
  AND is_primary = true;

-- Show the actual user data with roles
SELECT 
  u.id,
  u.email,
  u.full_name,
  u.tenant_id,
  json_agg(
    json_build_object(
      'role', ur.role,
      'is_primary', ur.is_primary,
      'tenant_id', ur.tenant_id
    )
  ) as roles
FROM users u
LEFT JOIN user_roles ur ON ur.user_id = u.id
WHERE u.email = 'admin@demo-school.edu'
GROUP BY u.id, u.email, u.full_name, u.tenant_id;
