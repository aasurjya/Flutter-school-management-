-- =============================================
-- SEED SUPER ADMIN USER
-- Run this in Supabase SQL Editor
-- =============================================

-- Step 1: First create the user in Supabase Auth
-- Go to Supabase Dashboard > Authentication > Users > Add User
-- Email: superadmin@schoolsaas.com
-- Password: SuperAdmin@123
-- 
-- After creating, get the user's UUID from the dashboard

-- Step 2: Then run this SQL with the actual UUID
-- Replace 'YOUR_USER_UUID_HERE' with the actual UUID from step 1

DO $$
DECLARE
    v_user_id UUID;
    v_super_admin_email TEXT := 'superadmin@schoolsaas.com';
BEGIN
    -- Get the user ID from auth.users (if user was created via dashboard)
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_super_admin_email;
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE 'User not found. Please create the user in Supabase Auth first.';
        RAISE NOTICE 'Email: %', v_super_admin_email;
        RAISE NOTICE 'Password: SuperAdmin@123';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Found user with ID: %', v_user_id;
    
    -- Insert into users table (no tenant_id for super admin)
    INSERT INTO public.users (id, email, full_name, phone, is_active, created_at, updated_at)
    VALUES (
        v_user_id,
        v_super_admin_email,
        'Super Administrator',
        '+91 9999999999',
        true,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = 'Super Administrator',
        is_active = true,
        updated_at = NOW();
    
    RAISE NOTICE 'User record created/updated in users table';
    
    -- Assign super_admin role (no tenant_id needed for super admin)
    INSERT INTO public.user_roles (user_id, role, is_primary, created_at)
    VALUES (
        v_user_id,
        'super_admin',
        true,
        NOW()
    )
    ON CONFLICT (user_id, role) DO UPDATE SET
        is_primary = true;
    
    RAISE NOTICE 'Super admin role assigned successfully!';
    RAISE NOTICE 'You can now login with:';
    RAISE NOTICE 'Email: %', v_super_admin_email;
    RAISE NOTICE 'Password: SuperAdmin@123';
    
END $$;

-- Verify the super admin was created
SELECT 
    u.id,
    u.email,
    u.full_name,
    ur.role,
    ur.is_primary
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'super_admin';
