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
