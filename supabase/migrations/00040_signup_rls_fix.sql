-- Migration: Fix RLS policies to allow signup and super_admin tenant creation
-- Users need INSERT on their own profile during signup
CREATE POLICY "Users insert own profile"
  ON users FOR INSERT
  WITH CHECK (id = auth.uid());

-- Users need INSERT their own role (for super_admin self-assignment during signup)
CREATE POLICY "Users insert own role"
  ON user_roles FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Authenticated users need SELECT on tenants (to verify system tenant exists during signup)
CREATE POLICY "Authenticated users read tenants"
  ON tenants FOR SELECT
  USING (auth.role() = 'authenticated');

-- Allow super_admin signup to create the system tenant (fixed UUID)
CREATE POLICY "Users insert system tenant"
  ON tenants FOR INSERT
  WITH CHECK (id = '00000000-0000-0000-0000-000000000001' AND auth.role() = 'authenticated');
