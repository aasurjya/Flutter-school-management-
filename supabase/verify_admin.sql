-- Check if admin@demo.edu data exists
SELECT 'Auth users check:' as check_type, COUNT(*) as count 
FROM auth.users 
WHERE email = 'admin@demo.edu';

SELECT 'Public users check:' as check_type, COUNT(*) as count 
FROM users 
WHERE email = 'admin@demo.edu';

SELECT 'User roles check:' as check_type, COUNT(*) as count 
FROM user_roles 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'admin@demo.edu')
  AND role = 'tenant_admin';

-- Show actual user data
SELECT u.id, u.email, u.tenant_id, 
       json_agg(ur.role) as roles,
       json_agg(ur.is_primary) as primary_flags
FROM users u
LEFT JOIN user_roles ur ON ur.user_id = u.id
WHERE u.email = 'admin@demo.edu'
GROUP BY u.id, u.email, u.tenant_id;
