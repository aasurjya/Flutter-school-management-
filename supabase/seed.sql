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
INSERT INTO auth.users (
  id, instance_id, aud, email, encrypted_password, email_confirmed_at, role,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change, email_change_token_new,
  email_change_token_current, phone, phone_change, phone_change_token, is_sso_user
)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'admin@demo-school.edu',
  crypt('Demo123!', gen_salt('bf')),
  NOW(),
  'authenticated',
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"full_name": "Rajesh Kumar (Admin)"}'::jsonb,
  NOW(),
  NOW(),
  '', '', '', '', '',
  NULL, '', '',
  false
);

-- Admin identity (required for auth to work)
INSERT INTO auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111',
  'admin@demo-school.edu',
  'email',
  '{"sub": "11111111-1111-1111-1111-111111111111", "email": "admin@demo-school.edu", "email_verified": true, "phone_verified": false}'::jsonb,
  NOW(),
  NOW(),
  NOW()
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

-- Teacher user
INSERT INTO auth.users (
  id, instance_id, aud, email, encrypted_password, email_confirmed_at, role,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change, email_change_token_new,
  email_change_token_current, phone, phone_change, phone_change_token, is_sso_user
)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'teacher@demo-school.edu',
  crypt('Demo123!', gen_salt('bf')),
  NOW(),
  'authenticated',
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"full_name": "Priya Sharma (Teacher)"}'::jsonb,
  NOW(),
  NOW(),
  '', '', '', '', '',
  NULL, '', '',
  false
);

-- Teacher identity
INSERT INTO auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  '22222222-2222-2222-2222-222222222222',
  'teacher@demo-school.edu',
  'email',
  '{"sub": "22222222-2222-2222-2222-222222222222", "email": "teacher@demo-school.edu", "email_verified": true, "phone_verified": false}'::jsonb,
  NOW(),
  NOW(),
  NOW()
);

INSERT INTO users (id, tenant_id, email, full_name, phone)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'teacher@demo-school.edu',
  'Priya Sharma (Teacher)',
  '9876543212'
);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'teacher',
  true
);

-- Student user
INSERT INTO auth.users (
  id, instance_id, aud, email, encrypted_password, email_confirmed_at, role,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change, email_change_token_new,
  email_change_token_current, phone, phone_change, phone_change_token, is_sso_user
)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'student@demo-school.edu',
  crypt('Demo123!', gen_salt('bf')),
  NOW(),
  'authenticated',
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"full_name": "Aarav Singh (Student)"}'::jsonb,
  NOW(),
  NOW(),
  '', '', '', '', '',
  NULL, '', '',
  false
);

-- Student identity
INSERT INTO auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  '33333333-3333-3333-3333-333333333333',
  'student@demo-school.edu',
  'email',
  '{"sub": "33333333-3333-3333-3333-333333333333", "email": "student@demo-school.edu", "email_verified": true, "phone_verified": false}'::jsonb,
  NOW(),
  NOW(),
  NOW()
);

INSERT INTO users (id, tenant_id, email, full_name, phone)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'student@demo-school.edu',
  'Aarav Singh (Student)',
  '9876543213'
);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'student',
  true
);

-- Parent user
INSERT INTO auth.users (
  id, instance_id, aud, email, encrypted_password, email_confirmed_at, role,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change, email_change_token_new,
  email_change_token_current, phone, phone_change, phone_change_token, is_sso_user
)
VALUES (
  '44444444-4444-4444-4444-444444444444',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'parent@demo-school.edu',
  crypt('Demo123!', gen_salt('bf')),
  NOW(),
  'authenticated',
  '{"provider": "email", "providers": ["email"]}'::jsonb,
  '{"full_name": "Vikram Singh (Parent)"}'::jsonb,
  NOW(),
  NOW(),
  '', '', '', '', '',
  NULL, '', '',
  false
);

-- Parent identity
INSERT INTO auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
VALUES (
  '44444444-4444-4444-4444-444444444444',
  '44444444-4444-4444-4444-444444444444',
  'parent@demo-school.edu',
  'email',
  '{"sub": "44444444-4444-4444-4444-444444444444", "email": "parent@demo-school.edu", "email_verified": true, "phone_verified": false}'::jsonb,
  NOW(),
  NOW(),
  NOW()
);

INSERT INTO users (id, tenant_id, email, full_name, phone)
VALUES (
  '44444444-4444-4444-4444-444444444444',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'parent@demo-school.edu',
  'Vikram Singh (Parent)',
  '9876543214'
);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES (
  '44444444-4444-4444-4444-444444444444',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'parent',
  true
);

-- =============================================
-- 3. ACADEMIC STRUCTURE
-- =============================================

-- Academic Year
INSERT INTO academic_years (id, tenant_id, name, start_date, end_date, is_current)
VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  '2024-25',
  '2024-04-01',
  '2025-03-31',
  true
);

-- Terms
INSERT INTO terms (id, tenant_id, academic_year_id, name, start_date, end_date, sequence_order)
VALUES 
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Term 1', '2024-04-01', '2024-09-30', 1),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb02', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Term 2', '2024-10-01', '2025-03-31', 2);

-- Classes
INSERT INTO classes (id, tenant_id, name, numeric_name, sequence_order)
VALUES 
  ('cccccccc-cccc-cccc-cccc-cccccccccc01', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 1', 1, 1),
  ('cccccccc-cccc-cccc-cccc-cccccccccc05', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 5', 5, 5),
  ('cccccccc-cccc-cccc-cccc-cccccccccc10', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 10', 10, 10);

-- Sections
INSERT INTO sections (id, tenant_id, class_id, academic_year_id, name, capacity, room_number)
VALUES 
  ('dddddddd-dddd-dddd-dddd-dddddddddd01', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc10', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, '101'),
  ('dddddddd-dddd-dddd-dddd-dddddddddd02', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc10', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, '102'),
  ('dddddddd-dddd-dddd-dddd-dddddddddd03', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc05', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 35, '201');

-- Subjects
INSERT INTO subjects (id, tenant_id, name, code, subject_type)
VALUES 
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Mathematics', 'MATH', 'mandatory'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'English', 'ENG', 'mandatory'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Science', 'SCI', 'mandatory'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Hindi', 'HIN', 'mandatory'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Social Studies', 'SST', 'mandatory');

-- Class-Subject mappings
INSERT INTO class_subjects (tenant_id, class_id, subject_id, academic_year_id, is_mandatory)
SELECT 
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  c.id,
  s.id,
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  true
FROM classes c, subjects s
WHERE c.tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
  AND s.tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- =============================================
-- 4. STAFF
-- =============================================

INSERT INTO staff (id, tenant_id, user_id, employee_id, first_name, last_name, designation, department, date_of_joining)
VALUES (
  'ffffffff-ffff-ffff-ffff-ffffffffffff',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  '22222222-2222-2222-2222-222222222222',
  'EMP001',
  'Priya',
  'Sharma',
  'Senior Teacher',
  'Mathematics',
  '2020-06-01'
);

-- Teacher assignment (teacher_id references users.id)
INSERT INTO teacher_assignments (tenant_id, teacher_id, section_id, subject_id, academic_year_id)
VALUES (
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  '22222222-2222-2222-2222-222222222222',
  'dddddddd-dddd-dddd-dddd-dddddddddd01',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
);

-- =============================================
-- 5. STUDENTS
-- =============================================

INSERT INTO students (id, tenant_id, user_id, admission_number, roll_number, first_name, last_name, date_of_birth, gender, admission_date)
VALUES 
  ('55555555-5555-5555-5555-555555555555', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '33333333-3333-3333-3333-333333333333', 'DEMO2024001', '1', 'Aarav', 'Singh', '2009-05-15', 'Male', '2024-04-01'),
  ('55555555-5555-5555-5555-555555555556', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024002', '2', 'Ananya', 'Patel', '2009-08-22', 'Female', '2024-04-01'),
  ('55555555-5555-5555-5555-555555555557', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024003', '3', 'Arjun', 'Kumar', '2009-03-10', 'Male', '2024-04-01'),
  ('55555555-5555-5555-5555-555555555558', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024004', '4', 'Diya', 'Sharma', '2009-11-28', 'Female', '2024-04-01'),
  ('55555555-5555-5555-5555-555555555559', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024005', '5', 'Rohan', 'Gupta', '2009-07-04', 'Male', '2024-04-01');

-- Student enrollments
INSERT INTO student_enrollments (tenant_id, student_id, section_id, academic_year_id, roll_number, status)
VALUES 
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555555', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '1', 'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555556', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2', 'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555557', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '3', 'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555558', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '4', 'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555559', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '5', 'active');

-- =============================================
-- 6. PARENTS
-- =============================================

INSERT INTO parents (id, tenant_id, user_id, first_name, last_name, relation, email, phone)
VALUES (
  '66666666-6666-6666-6666-666666666666',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  '44444444-4444-4444-4444-444444444444',
  'Vikram',
  'Singh',
  'Father',
  'parent@demo-school.edu',
  '9876543214'
);

-- Link parent to student
INSERT INTO student_parents (student_id, parent_id, is_primary, can_pickup)
VALUES (
  '55555555-5555-5555-5555-555555555555',
  '66666666-6666-6666-6666-666666666666',
  true,
  true
);

-- =============================================
-- 7. SAMPLE ATTENDANCE (Last 7 days)
-- =============================================

INSERT INTO attendance (tenant_id, student_id, section_id, date, status, marked_by)
SELECT 
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  s.id,
  'dddddddd-dddd-dddd-dddd-dddddddddd01',
  d.date,
  CASE 
    WHEN random() < 0.85 THEN 'present'::attendance_status
    WHEN random() < 0.95 THEN 'late'::attendance_status
    ELSE 'absent'::attendance_status
  END,
  '22222222-2222-2222-2222-222222222222'
FROM students s
CROSS JOIN (
  SELECT generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, INTERVAL '1 day')::DATE as date
) d
WHERE s.tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- =============================================
-- 8. SAMPLE EXAM & MARKS
-- =============================================

-- Create exam
INSERT INTO exams (id, tenant_id, academic_year_id, term_id, name, exam_type, start_date, end_date)
VALUES (
  '77777777-7777-7777-7777-777777777777',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01',
  'Mid-Term Examination 2024',
  'mid_term',
  '2024-09-15',
  '2024-09-25'
);

 -- Create exam subjects
 INSERT INTO exam_subjects (id, tenant_id, exam_id, subject_id, class_id, max_marks, passing_marks, exam_date)
 VALUES 
   ('88888888-8888-8888-8888-888888888801', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777777', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01', 'cccccccc-cccc-cccc-cccc-cccccccccc10', 100, 35, '2024-09-16'),
   ('88888888-8888-8888-8888-888888888802', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777777', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02', 'cccccccc-cccc-cccc-cccc-cccccccccc10', 100, 35, '2024-09-17'),
   ('88888888-8888-8888-8888-888888888803', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777777', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03', 'cccccccc-cccc-cccc-cccc-cccccccccc10', 100, 35, '2024-09-18');

 -- Insert marks for Math
 INSERT INTO marks (tenant_id, exam_subject_id, student_id, marks_obtained, entered_by)
 VALUES 
   ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '88888888-8888-8888-8888-888888888801', '55555555-5555-5555-5555-555555555555', 85, '22222222-2222-2222-2222-222222222222'),
   ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '88888888-8888-8888-8888-888888888801', '55555555-5555-5555-5555-555555555556', 92, '22222222-2222-2222-2222-222222222222'),
   ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '88888888-8888-8888-8888-888888888801', '55555555-5555-5555-5555-555555555557', 78, '22222222-2222-2222-2222-222222222222'),
   ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '88888888-8888-8888-8888-888888888801', '55555555-5555-5555-5555-555555555558', 88, '22222222-2222-2222-2222-222222222222'),
   ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '88888888-8888-8888-8888-888888888801', '55555555-5555-5555-5555-555555555559', 65, '22222222-2222-2222-2222-222222222222');
 
 -- Insert marks for English
 INSERT INTO marks (tenant_id, exam_subject_id, student_id, marks_obtained, entered_by)
 VALUES 
   ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '88888888-8888-8888-8888-888888888802', '55555555-5555-5555-5555-555555555555', 90, '22222222-2222-2222-2222-222222222222'),
   ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '88888888-8888-8888-8888-888888888802', '55555555-5555-5555-5555-555555555556', 85, '22222222-2222-2222-2222-222222222222'),
   ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '88888888-8888-8888-8888-888888888802', '55555555-5555-5555-5555-555555555557', 72, '22222222-2222-2222-2222-222222222222'),
   ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '88888888-8888-8888-8888-888888888802', '55555555-5555-5555-5555-555555555558', 95, '22222222-2222-2222-2222-222222222222'),
   ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '88888888-8888-8888-8888-888888888802', '55555555-5555-5555-5555-555555555559', 68, '22222222-2222-2222-2222-222222222222');

-- =============================================
-- 9. FEE STRUCTURE
-- =============================================

INSERT INTO fee_heads (id, tenant_id, name, description, is_recurring)
VALUES 
  ('99999999-9999-9999-9999-999999999901', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Tuition Fee', 'Monthly tuition fee', true),
  ('99999999-9999-9999-9999-999999999902', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Transport Fee', 'Monthly transport fee', true),
  ('99999999-9999-9999-9999-999999999903', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Lab Fee', 'Annual laboratory fee', false);

-- fee_structures schema:
-- id, tenant_id, academic_year_id, class_id, fee_head_id, amount, due_date, term_id, is_mandatory
-- We only seed required columns and leave others NULL/default.
INSERT INTO fee_structures (id, tenant_id, academic_year_id, class_id, fee_head_id, amount)
VALUES 
  ('aaaa0001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '99999999-9999-9999-9999-999999999901', 5000.00),
  ('aaaa0001-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '99999999-9999-9999-9999-999999999902', 1500.00);

-- =============================================
-- 10. ANNOUNCEMENTS
-- =============================================

INSERT INTO announcements (tenant_id, title, content, is_published, publish_at, created_by)
VALUES 
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Welcome to the New Academic Year!', 'Dear Students and Parents, Welcome to the academic year 2024-25. We wish you a great year ahead!', true, NOW(), '11111111-1111-1111-1111-111111111111'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Mid-Term Examination Schedule', 'Mid-term examinations will be held from September 15-25, 2024. Please check the detailed schedule.', true, NOW(), '11111111-1111-1111-1111-111111111111');

-- =============================================
-- DEMO CREDENTIALS SUMMARY
-- =============================================
-- 
-- Admin:   admin@demo-school.edu   / Demo123!
-- Teacher: teacher@demo-school.edu / Demo123!
-- Student: student@demo-school.edu / Demo123!
-- Parent:  parent@demo-school.edu  / Demo123!
--
-- =============================================
