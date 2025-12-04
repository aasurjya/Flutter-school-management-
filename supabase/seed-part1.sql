-- =============================================
-- School Management SaaS - Seed Data
-- Run this AFTER migrations to create demo data
-- =============================================

-- =============================================
-- 1. CREATE DEMO TENANT (SCHOOL)
-- =============================================
INSERT INTO tenants (id, name, slug, email, phone, address, city, state)
VALUES (
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'Demo International School',
  'demo-school',
  'admin@demo-school.edu',
  '9876543210',
  '123 Education Lane',
  'Mumbai',
  'Maharashtra'
);

-- =============================================
-- 2. CREATE DEMO USERS (via auth.users first)
-- Note: In production, create via Supabase Auth API
-- For seeding, we insert directly (requires service_role)
-- =============================================

-- Admin user
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, role, raw_app_meta_data)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'admin@demo-school.edu',
  crypt('Demo123!', gen_salt('bf')),
  NOW(),
  'authenticated',
  '{"tenant_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", "roles": ["tenant_admin"]}'::jsonb
);

INSERT INTO users (id, tenant_id, email, full_name, phone)
VALUES (
  '11111111-1111-1111-1111-111111111111',
