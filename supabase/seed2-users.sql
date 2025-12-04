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
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'admin@demo-school.edu',
  'Rajesh Kumar (Admin)',
  '9876543211'
);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'tenant_admin',
  true
);
