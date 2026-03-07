-- ============================================================
-- COMPREHENSIVE SEED DATA FOR DEMO INTERNATIONAL SCHOOL
-- tenant_id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
-- Run date: 2026-03-07
-- ============================================================

-- ============================================================
-- STEP 1: ACADEMIC YEARS - add 2023-24
-- ============================================================
INSERT INTO academic_years (id, tenant_id, name, start_date, end_date, is_current)
VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaab',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  '2023-24',
  '2023-04-01',
  '2024-03-31',
  false
) ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 2: TERMS - add Term 3 for 2024-25
-- ============================================================
INSERT INTO terms (id, tenant_id, academic_year_id, name, start_date, end_date, sequence_order)
VALUES (
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb03',
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'Term 3',
  '2025-01-01',
  '2025-03-31',
  3
) ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 3: CLASSES - add Class 2-4, 6-9, 11-12
-- (columns: id, tenant_id, name, numeric_name, sequence_order)
-- ============================================================
INSERT INTO classes (id, tenant_id, name, numeric_name, sequence_order) VALUES
  ('cccccccc-cccc-cccc-cccc-cccccccccc02', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 2',  2,  2),
  ('cccccccc-cccc-cccc-cccc-cccccccccc03', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 3',  3,  3),
  ('cccccccc-cccc-cccc-cccc-cccccccccc04', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 4',  4,  4),
  ('cccccccc-cccc-cccc-cccc-cccccccccc06', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 6',  6,  6),
  ('cccccccc-cccc-cccc-cccc-cccccccccc07', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 7',  7,  7),
  ('cccccccc-cccc-cccc-cccc-cccccccccc08', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 8',  8,  8),
  ('cccccccc-cccc-cccc-cccc-cccccccccc09', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 9',  9,  9),
  ('cccccccc-cccc-cccc-cccc-cccccccccc11', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 11', 11, 11),
  ('cccccccc-cccc-cccc-cccc-cccccccccc12', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Class 12', 12, 12)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 4: SECTIONS - A and B for each class
-- (columns: id, tenant_id, class_id, academic_year_id, name, capacity, class_teacher_id)
-- ============================================================
INSERT INTO sections (id, tenant_id, class_id, academic_year_id, name, capacity, class_teacher_id) VALUES
  -- Class 1
  ('dddddddd-dddd-dddd-dddd-dddddddddd10', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, '22222222-2222-2222-2222-222222222222'),
  ('dddddddd-dddd-dddd-dddd-dddddddddd11', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL),
  -- Class 2
  ('dddddddd-dddd-dddd-dddd-dddddddddd20', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc02', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, NULL),
  ('dddddddd-dddd-dddd-dddd-dddddddddd21', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc02', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL),
  -- Class 3
  ('dddddddd-dddd-dddd-dddd-dddddddddd30', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, NULL),
  ('dddddddd-dddd-dddd-dddd-dddddddddd31', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL),
  -- Class 4
  ('dddddddd-dddd-dddd-dddd-dddddddddd40', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc04', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, NULL),
  ('dddddddd-dddd-dddd-dddd-dddddddddd41', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc04', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL),
  -- Class 5 - B section (A already exists as dddddddddd03)
  ('dddddddd-dddd-dddd-dddd-dddddddddd51', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc05', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL),
  -- Class 6
  ('dddddddd-dddd-dddd-dddd-dddddddddd60', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc06', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, NULL),
  ('dddddddd-dddd-dddd-dddd-dddddddddd61', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc06', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL),
  -- Class 7
  ('dddddddd-dddd-dddd-dddd-dddddddddd70', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc07', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, NULL),
  ('dddddddd-dddd-dddd-dddd-dddddddddd71', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc07', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL),
  -- Class 8
  ('dddddddd-dddd-dddd-dddd-dddddddddd80', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc08', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, NULL),
  ('dddddddd-dddd-dddd-dddd-dddddddddd81', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc08', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL),
  -- Class 9
  ('dddddddd-dddd-dddd-dddd-dddddddddd90', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc09', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, NULL),
  ('dddddddd-dddd-dddd-dddd-dddddddddd91', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc09', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL),
  -- Class 11
  ('dddddddd-dddd-dddd-dddd-dddddddddda0', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc11', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, NULL),
  ('dddddddd-dddd-dddd-dddd-dddddddddda1', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc11', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL),
  -- Class 12
  ('dddddddd-dddd-dddd-dddd-ddddddddddс0', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc12', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'A', 40, NULL),
  ('dddddddd-dddd-dddd-dddd-ddddddddddс1', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cccccccc-cccc-cccc-cccc-cccccccccc12', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'B', 40, NULL)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 5: SUBJECTS - add Computer Science and Physical Education
-- ============================================================
INSERT INTO subjects (id, tenant_id, name, code, description) VALUES
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee06', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Computer Science', 'CS',  'Computer Science and IT'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee07', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Physical Education', 'PE', 'Sports and Physical Health'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee08', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Art and Craft', 'ART', 'Arts and Craft Activities'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee09', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Music', 'MUS', 'Music and Performing Arts')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 6: CLASS_SUBJECTS - link subjects to classes
-- ============================================================
INSERT INTO class_subjects (tenant_id, class_id, subject_id, academic_year_id, is_mandatory)
SELECT
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  c.class_id,
  s.subject_id,
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  true
FROM (VALUES
  ('cccccccc-cccc-cccc-cccc-cccccccccc01'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc05'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc06'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc07'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc08'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc09'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc10'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc11'),
  ('cccccccc-cccc-cccc-cccc-cccccccccc12')
) AS c(class_id)
CROSS JOIN (VALUES
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee06'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeee07')
) AS s(subject_id)
ON CONFLICT (class_id, subject_id, academic_year_id) DO NOTHING;

-- ============================================================
-- STEP 7: STAFF - 4 more teachers
-- ============================================================
INSERT INTO staff (id, tenant_id, user_id, employee_id, first_name, last_name, designation, department, date_of_birth, date_of_joining, qualification, experience_years, salary, is_active) VALUES
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '22222222-2222-2222-2222-222222222222', 'EMP001', 'Priya', 'Sharma',  'Senior Teacher',  'Science',          '1985-06-15', '2015-07-01', 'M.Sc Physics',          8,  55000.00, true),
  ('aaaabbbb-cccc-dddd-eeee-ffff00000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'EMP002', 'Rajesh', 'Kumar',   'Teacher',         'Mathematics',      '1980-03-22', '2012-06-01', 'M.Sc Mathematics',      12, 52000.00, true),
  ('aaaabbbb-cccc-dddd-eeee-ffff00000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'EMP003', 'Sunita', 'Verma',   'Teacher',         'English',          '1988-09-10', '2018-04-01', 'M.A. English Lit',       6, 48000.00, true),
  ('aaaabbbb-cccc-dddd-eeee-ffff00000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'EMP004', 'Amit',   'Patel',   'Teacher',         'Computer Science', '1990-12-05', '2020-07-01', 'B.Tech Computer Sci',    4, 45000.00, true),
  ('aaaabbbb-cccc-dddd-eeee-ffff00000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'EMP005', 'Kavitha','Nair',    'Senior Teacher',  'Social Studies',   '1983-07-18', '2010-05-01', 'M.A. History',          14, 58000.00, true)
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  designation = EXCLUDED.designation;

-- ============================================================
-- STEP 8: TEACHER ASSIGNMENTS
-- ============================================================
INSERT INTO teacher_assignments (tenant_id, teacher_id, section_id, subject_id, academic_year_id) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '22222222-2222-2222-2222-222222222222', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '22222222-2222-2222-2222-222222222222', 'dddddddd-dddd-dddd-dddd-dddddddddd02', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '22222222-2222-2222-2222-222222222222', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '22222222-2222-2222-2222-222222222222', 'dddddddd-dddd-dddd-dddd-dddddddddd03', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
ON CONFLICT (teacher_id, section_id, subject_id, academic_year_id) DO NOTHING;

-- ============================================================
-- STEP 9: STUDENTS - 15 more
-- ============================================================
INSERT INTO students (id, tenant_id, user_id, admission_number, roll_number, first_name, last_name, date_of_birth, gender, blood_group, address, city, state, admission_date, is_active, email, payment_status) VALUES
  ('55555555-5555-5555-5555-55555555555a', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024006', '6',  'Priya',     'Mehta',    '2009-03-12', 'female', 'A+', '12 MG Road',        'Mumbai',     'Maharashtra', '2024-04-01', true, 'priya.mehta@demo-school.edu',     'paid'),
  ('55555555-5555-5555-5555-55555555555b', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024007', '7',  'Karan',     'Shah',     '2009-07-24', 'male',   'B+', '45 Park Street',    'Mumbai',     'Maharashtra', '2024-04-01', true, 'karan.shah@demo-school.edu',      'pending'),
  ('55555555-5555-5555-5555-55555555555c', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024008', '8',  'Neha',      'Joshi',    '2009-11-02', 'female', 'O+', '78 Station Road',   'Pune',       'Maharashtra', '2024-04-01', true, 'neha.joshi@demo-school.edu',      'paid'),
  ('55555555-5555-5555-5555-55555555555d', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024009', '9',  'Vivek',     'Rao',      '2009-05-18', 'male',   'AB+','23 Lake View',      'Nagpur',     'Maharashtra', '2024-04-01', true, 'vivek.rao@demo-school.edu',       'paid'),
  ('55555555-5555-5555-5555-55555555555e', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024010', '10', 'Sneha',     'Kulkarni', '2009-08-30', 'female', 'A-', '56 River Bank',     'Nashik',     'Maharashtra', '2024-04-01', true, 'sneha.kulkarni@demo-school.edu',  'paid'),
  ('55555555-5555-5555-5555-55555555555f', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024011', '11', 'Aditya',    'Singh',    '2009-02-14', 'male',   'B-', '90 Hill Road',      'Aurangabad', 'Maharashtra', '2024-04-01', true, 'aditya.singh@demo-school.edu',    'pending'),
  ('55555555-5555-5555-5555-555555555560', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024012', '1',  'Meera',     'Pillai',   '2013-06-09', 'female', 'O-', '34 Garden View',    'Kolhapur',   'Maharashtra', '2024-04-01', true, 'meera.pillai@demo-school.edu',    'paid'),
  ('55555555-5555-5555-5555-555555555561', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024013', '2',  'Siddharth', 'Bhatt',    '2013-10-25', 'male',   'A+', '67 Sunset Drive',   'Solapur',    'Maharashtra', '2024-04-01', true, 'siddharth.bhatt@demo-school.edu', 'paid'),
  ('55555555-5555-5555-5555-555555555562', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024014', '3',  'Tanvi',     'Desai',    '2013-04-17', 'female', 'B+', '89 Blue Ridge',     'Satara',     'Maharashtra', '2024-04-01', true, 'tanvi.desai@demo-school.edu',     'pending'),
  ('55555555-5555-5555-5555-555555555563', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024015', '1',  'Rahul',     'Nair',     '2011-01-30', 'male',   'O+', '11 Maple Lane',     'Thane',      'Maharashtra', '2024-04-01', true, 'rahul.nair@demo-school.edu',      'paid'),
  ('55555555-5555-5555-5555-555555555564', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024016', '2',  'Pooja',     'Iyer',     '2011-08-11', 'female', 'AB-','44 Orchid Path',    'Kalyan',     'Maharashtra', '2024-04-01', true, 'pooja.iyer@demo-school.edu',      'paid'),
  ('55555555-5555-5555-5555-555555555565', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024017', '1',  'Vikrant',   'Chavan',   '2010-03-05', 'male',   'A+', '22 Pine View',      'Raigad',     'Maharashtra', '2024-04-01', true, 'vikrant.chavan@demo-school.edu',  'paid'),
  ('55555555-5555-5555-5555-555555555566', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024018', '2',  'Shruti',    'Patil',    '2010-11-19', 'female', 'B+', '55 Jasmine Ave',    'Pune',       'Maharashtra', '2024-04-01', true, 'shruti.patil@demo-school.edu',    'pending'),
  ('55555555-5555-5555-5555-555555555567', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024019', '1',  'Akash',     'Sharma',   '2007-09-08', 'male',   'O+', '77 Royal Enclave',  'Mumbai',     'Maharashtra', '2024-04-01', true, 'akash.sharma@demo-school.edu',    'paid'),
  ('55555555-5555-5555-5555-555555555568', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL, 'DEMO2024020', '2',  'Ishita',    'Gupta',    '2007-12-22', 'female', 'A-', '33 Harmony Nagar',  'Mumbai',     'Maharashtra', '2024-04-01', true, 'ishita.gupta@demo-school.edu',    'paid')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 10: STUDENT ENROLLMENTS
-- ============================================================
INSERT INTO student_enrollments (tenant_id, student_id, section_id, academic_year_id, roll_number, status) VALUES
  -- Class 10-A (new students)
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-55555555555a', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '6',  'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-55555555555b', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '7',  'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-55555555555c', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '8',  'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-55555555555d', 'dddddddd-dddd-dddd-dddd-dddddddddd01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '9',  'active'),
  -- Class 10-B
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-55555555555e', 'dddddddd-dddd-dddd-dddd-dddddddddd02', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '1',  'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-55555555555f', 'dddddddd-dddd-dddd-dddd-dddddddddd02', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2',  'active'),
  -- Class 5-A (section 03)
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555560', 'dddddddd-dddd-dddd-dddd-dddddddddd03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '4',  'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555561', 'dddddddd-dddd-dddd-dddd-dddddddddd03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '5',  'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555562', 'dddddddd-dddd-dddd-dddd-dddddddddd03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '6',  'active'),
  -- Class 8-A
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555563', 'dddddddd-dddd-dddd-dddd-dddddddddd80', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '1',  'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555564', 'dddddddd-dddd-dddd-dddd-dddddddddd80', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2',  'active'),
  -- Class 9-A
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555565', 'dddddddd-dddd-dddd-dddd-dddddddddd90', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '1',  'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555566', 'dddddddd-dddd-dddd-dddd-dddddddddd90', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2',  'active'),
  -- Class 11-A
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555567', 'dddddddd-dddd-dddd-dddd-dddddddddda0', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '1',  'active'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '55555555-5555-5555-5555-555555555568', 'dddddddd-dddd-dddd-dddd-dddddddddda0', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2',  'active')
ON CONFLICT (student_id, academic_year_id) DO NOTHING;

-- ============================================================
-- STEP 11: PARENTS - 9 more
-- ============================================================
INSERT INTO parents (id, tenant_id, user_id, first_name, last_name, relation, email, phone, occupation, annual_income, address, is_emergency_contact) VALUES
  ('66666666-6666-6666-6666-666666666666', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '44444444-4444-4444-4444-444444444444', 'Vikram',   'Singh',    'father', 'parent@demo-school.edu',        '9876543210', 'Software Engineer', 1200000, '12 Blue Orchid, Mumbai',    true),
  ('66666666-6666-6666-6666-666666666667', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'Sunita',   'Mehta',    'mother', 'sunita.mehta@example.com',      '9876543211', 'Doctor',            1800000, '12 MG Road, Mumbai',        true),
  ('66666666-6666-6666-6666-666666666668', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'Ramesh',   'Shah',     'father', 'ramesh.shah@example.com',       '9876543212', 'Businessman',       2500000, '45 Park Street, Mumbai',    true),
  ('66666666-6666-6666-6666-666666666669', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'Anita',    'Joshi',    'mother', 'anita.joshi@example.com',       '9876543213', 'Teacher',            600000, '78 Station Rd, Pune',       true),
  ('66666666-6666-6666-6666-66666666666a', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'Suresh',   'Rao',      'father', 'suresh.rao@example.com',        '9876543214', 'Architect',         1500000, '23 Lake View, Nagpur',      true),
  ('66666666-6666-6666-6666-66666666666b', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'Meena',    'Kulkarni', 'mother', 'meena.kulkarni@example.com',    '9876543215', 'Nurse',              450000, '56 River Bank, Nashik',     true),
  ('66666666-6666-6666-6666-66666666666c', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'Ganesh',   'Pillai',   'father', 'ganesh.pillai@example.com',     '9876543216', 'Chartered Accountant',1400000,'34 Garden View, Kolhapur',  true),
  ('66666666-6666-6666-6666-66666666666d', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'Leela',    'Bhatt',    'mother', 'leela.bhatt@example.com',       '9876543217', 'Professor',          800000, '67 Sunset Drive, Solapur',  true),
  ('66666666-6666-6666-6666-66666666666e', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'Mohan',    'Nair',     'father', 'mohan.nair@example.com',        '9876543218', 'Engineer',          1100000, '11 Maple Lane, Thane',      true),
  ('66666666-6666-6666-6666-66666666666f', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NULL,                                   'Lakshmi',  'Iyer',     'mother', 'lakshmi.iyer@example.com',      '9876543219', 'Homemaker',               0, '44 Orchid Path, Kalyan',    true)
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  phone = EXCLUDED.phone;

-- ============================================================
-- STEP 12: STUDENT_PARENTS
-- ============================================================
INSERT INTO student_parents (student_id, parent_id, is_primary) VALUES
  ('55555555-5555-5555-5555-555555555555', '66666666-6666-6666-6666-666666666666', true),
  ('55555555-5555-5555-5555-55555555555a', '66666666-6666-6666-6666-666666666667', true),
  ('55555555-5555-5555-5555-55555555555b', '66666666-6666-6666-6666-666666666668', true),
  ('55555555-5555-5555-5555-55555555555c', '66666666-6666-6666-6666-666666666669', true),
  ('55555555-5555-5555-5555-55555555555d', '66666666-6666-6666-6666-66666666666a', true),
  ('55555555-5555-5555-5555-55555555555e', '66666666-6666-6666-6666-66666666666b', true),
  ('55555555-5555-5555-5555-555555555560', '66666666-6666-6666-6666-66666666666c', true),
  ('55555555-5555-5555-5555-555555555561', '66666666-6666-6666-6666-66666666666d', true),
  ('55555555-5555-5555-5555-555555555563', '66666666-6666-6666-6666-66666666666e', true),
  ('55555555-5555-5555-5555-555555555564', '66666666-6666-6666-6666-66666666666f', true)
ON CONFLICT (student_id, parent_id) DO NOTHING;

-- ============================================================
-- STEP 13: ATTENDANCE - Feb/Mar 2026 for Class 10-A students
-- ============================================================
DO $$
DECLARE
  student_ids uuid[] := ARRAY[
    '55555555-5555-5555-5555-555555555555'::uuid,
    '55555555-5555-5555-5555-555555555556'::uuid,
    '55555555-5555-5555-5555-555555555557'::uuid,
    '55555555-5555-5555-5555-555555555558'::uuid,
    '55555555-5555-5555-5555-555555555559'::uuid,
    '55555555-5555-5555-5555-55555555555a'::uuid,
    '55555555-5555-5555-5555-55555555555b'::uuid,
    '55555555-5555-5555-5555-55555555555c'::uuid,
    '55555555-5555-5555-5555-55555555555d'::uuid
  ];
  sid uuid;
  d date;
  att_status attendance_status;
  roll_idx integer;
BEGIN
  roll_idx := 1;
  FOREACH sid IN ARRAY student_ids LOOP
    FOR d IN
      SELECT gs::date
      FROM generate_series('2026-02-02'::date, '2026-03-06'::date, '1 day'::interval) AS gs
    LOOP
      IF EXTRACT(DOW FROM d) NOT IN (0, 6) THEN
        IF (roll_idx % 7 = 0 AND EXTRACT(DOW FROM d) = 2) THEN
          att_status := 'absent';
        ELSIF (roll_idx % 11 = 0 AND EXTRACT(DOW FROM d) = 4) THEN
          att_status := 'late';
        ELSE
          att_status := 'present';
        END IF;
        INSERT INTO attendance (tenant_id, student_id, section_id, date, status, marked_by)
        VALUES (
          'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          sid,
          'dddddddd-dddd-dddd-dddd-dddddddddd01',
          d,
          att_status,
          '22222222-2222-2222-2222-222222222222'
        ) ON CONFLICT (student_id, date) DO NOTHING;
      END IF;
    END LOOP;
    roll_idx := roll_idx + 1;
  END LOOP;
END $$;

-- ============================================================
-- STEP 14: EXAMS - 2 more
-- ============================================================
INSERT INTO exams (id, tenant_id, academic_year_id, term_id, name, exam_type, start_date, end_date, description, is_published) VALUES
  ('77777777-7777-7777-7777-777777777778', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 'Unit Test 1',            'unit_test', '2024-06-10', '2024-06-15', 'First unit test for Term 1',  true),
  ('77777777-7777-7777-7777-777777777779', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb03', 'Final Examination 2024', 'final',     '2025-02-20', '2025-03-05', 'Annual Final Examination',     true)
ON CONFLICT (id) DO NOTHING;

UPDATE exams SET is_published = true WHERE id = '77777777-7777-7777-7777-777777777777';

-- ============================================================
-- STEP 15: EXAM_SUBJECTS - for new exams
-- ============================================================
INSERT INTO exam_subjects (tenant_id, exam_id, subject_id, class_id, exam_date, start_time, end_time, max_marks, passing_marks) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777778', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '2024-06-10', '10:00', '12:00', 50, 17),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777778', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '2024-06-11', '10:00', '12:00', 50, 17),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777778', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '2024-06-12', '10:00', '12:00', 50, 17),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777779', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '2025-02-20', '10:00', '13:00', 100, 35),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777779', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '2025-02-22', '10:00', '13:00', 100, 35),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777779', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '2025-02-24', '10:00', '13:00', 100, 35),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777779', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '2025-02-25', '10:00', '13:00', 100, 35),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '77777777-7777-7777-7777-777777777779', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '2025-02-27', '10:00', '13:00', 100, 35)
ON CONFLICT (exam_id, subject_id, class_id) DO NOTHING;

-- ============================================================
-- STEP 16: MARKS for all Class 10 students across all exams
-- ============================================================
DO $$
DECLARE
  student_ids uuid[] := ARRAY[
    '55555555-5555-5555-5555-555555555555'::uuid,
    '55555555-5555-5555-5555-555555555556'::uuid,
    '55555555-5555-5555-5555-555555555557'::uuid,
    '55555555-5555-5555-5555-555555555558'::uuid,
    '55555555-5555-5555-5555-555555555559'::uuid,
    '55555555-5555-5555-5555-55555555555a'::uuid,
    '55555555-5555-5555-5555-55555555555b'::uuid,
    '55555555-5555-5555-5555-55555555555c'::uuid,
    '55555555-5555-5555-5555-55555555555d'::uuid
  ];
  sid uuid;
  es_id uuid;
  midterm_es uuid[] := ARRAY[
    '88888888-8888-8888-8888-888888888801'::uuid,
    '88888888-8888-8888-8888-888888888802'::uuid,
    '88888888-8888-8888-8888-888888888803'::uuid
  ];
  base_marks numeric;
  s_idx integer;
BEGIN
  s_idx := 1;
  FOREACH sid IN ARRAY student_ids LOOP
    FOREACH es_id IN ARRAY midterm_es LOOP
      base_marks := 50 + (s_idx * 4) + (floor(random() * 15))::integer;
      IF base_marks > 100 THEN base_marks := 100; END IF;
      INSERT INTO marks (tenant_id, exam_subject_id, student_id, marks_obtained, entered_by)
      VALUES (
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        es_id, sid, base_marks,
        '22222222-2222-2222-2222-222222222222'
      ) ON CONFLICT (exam_subject_id, student_id) DO NOTHING;
    END LOOP;
    s_idx := s_idx + 1;
  END LOOP;
END $$;

-- ============================================================
-- STEP 17: FEE STRUCTURES
-- ============================================================
INSERT INTO fee_structures (tenant_id, academic_year_id, class_id, fee_head_id, amount, due_date, is_mandatory) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '99999999-9999-9999-9999-999999999901', 15000.00, '2024-05-10', true),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '99999999-9999-9999-9999-999999999902',  3000.00, '2024-05-10', false),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc10', '99999999-9999-9999-9999-999999999903',  2000.00, '2024-05-10', false),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc05', '99999999-9999-9999-9999-999999999901', 12000.00, '2024-05-10', true),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccc05', '99999999-9999-9999-9999-999999999902',  2500.00, '2024-05-10', false)
ON CONSTRAINT fee_structures_unique_idx DO NOTHING;

-- ============================================================
-- STEP 18: INVOICES
-- ============================================================
INSERT INTO invoices (id, tenant_id, invoice_number, student_id, academic_year_id, term_id, total_amount, discount_amount, paid_amount, due_date, status, generated_by) VALUES
  ('inv00000-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-001', '55555555-5555-5555-5555-555555555555', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,     20000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('inv00000-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-002', '55555555-5555-5555-5555-555555555556', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,     20000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('inv00000-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-003', '55555555-5555-5555-5555-555555555557', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 1000, 19000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('inv00000-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-004', '55555555-5555-5555-5555-555555555558', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,         0, '2024-05-10', 'overdue', '11111111-1111-1111-1111-111111111111'),
  ('inv00000-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-005', '55555555-5555-5555-5555-555555555559', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,     10000, '2024-05-10', 'partial', '11111111-1111-1111-1111-111111111111'),
  ('inv00000-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-006', '55555555-5555-5555-5555-55555555555a', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,     20000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('inv00000-0000-0000-0000-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-007', '55555555-5555-5555-5555-55555555555b', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,         0, '2024-05-10', 'pending', '11111111-1111-1111-1111-111111111111'),
  ('inv00000-0000-0000-0000-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-008', '55555555-5555-5555-5555-55555555555c', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 2000, 18000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('inv00000-0000-0000-0000-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-009', '55555555-5555-5555-5555-55555555555d', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,     20000, '2024-05-10', 'paid',    '11111111-1111-1111-1111-111111111111'),
  ('inv00000-0000-0000-0000-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'INV-2024-010', '55555555-5555-5555-5555-55555555555e', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 20000, 0,         0, '2024-07-10', 'overdue', '11111111-1111-1111-1111-111111111111')
ON CONFLICT ON CONSTRAINT idx_invoices_number DO NOTHING;

-- ============================================================
-- STEP 19: LIBRARY BOOKS
-- ============================================================
INSERT INTO library_books (id, tenant_id, isbn, title, author, publisher, category, edition, publication_year, total_copies, available_copies, shelf_location, description) VALUES
  ('bk000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-13-468599-1', 'Introduction to Algorithms',          'Thomas H. Cormen',  'MIT Press',      'Computer Science', '4th',             2022, 3,  2, 'CS-A1',  'Comprehensive introduction to computer algorithms'),
  ('bk000001-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-06-112008-4', 'To Kill a Mockingbird',               'Harper Lee',        'HarperCollins',  'Fiction',          '1st',             1960, 5,  5, 'FIC-B2', 'Classic American novel about racial injustice'),
  ('bk000001-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-19-953592-3', 'Oxford Dictionary of Science',        'Oxford Univ Press', 'OUP',            'Reference',        '7th',             2017, 2,  2, 'REF-C1', 'Comprehensive science reference'),
  ('bk000001-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-7387-073-3', 'NCERT Mathematics Class 10',          'NCERT',             'NCERT',          'Textbook',         'Latest',          2023, 10, 8, 'TB-D1',  'CBSE Mathematics textbook for Class 10'),
  ('bk000001-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-7387-074-0', 'NCERT Science Class 10',              'NCERT',             'NCERT',          'Textbook',         'Latest',          2023, 10, 9, 'TB-D2',  'CBSE Science textbook for Class 10'),
  ('bk000001-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-7432-7357-1', 'The Alchemist',                       'Paulo Coelho',      'HarperCollins',  'Fiction',          'Anniversary',     2014, 4,  3, 'FIC-E3', 'Philosophical novel about following ones dreams'),
  ('bk000001-0000-0000-0000-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-14-028329-7', 'Animal Farm',                         'George Orwell',     'Penguin Books',  'Fiction',          '1st',             1945, 3,  3, 'FIC-F4', 'Allegorical novella about totalitarianism'),
  ('bk000001-0000-0000-0000-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-306-40615-7', 'A Brief History of Time',             'Stephen Hawking',   'Bantam Books',   'Science',          '10th Anniversary',1998, 2,  2, 'SCI-G5', 'Cosmology for the general reader'),
  ('bk000001-0000-0000-0000-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-291-1947-3', 'Wings of Fire',                       'A.P.J. Abdul Kalam','Universities Press','Biography',     '1st',             1999, 5,  4, 'BIO-H6', 'Autobiography of Dr. APJ Abdul Kalam'),
  ('bk000001-0000-0000-0000-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-525-55360-5', 'The Fault in Our Stars',              'John Green',        'Dutton Books',   'Fiction',          '1st',             2012, 3,  3, 'FIC-I7', 'Young adult novel about two teenage cancer patients'),
  ('bk000001-0000-0000-0000-000000000011', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-316-76948-0', 'The Catcher in the Rye',              'J.D. Salinger',     'Little Brown',   'Fiction',          '1st',             1951, 2,  2, 'FIC-J8', 'Coming-of-age story of Holden Caulfield'),
  ('bk000001-0000-0000-0000-000000000012', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-7387-100-6', 'NCERT History Class 10',              'NCERT',             'NCERT',          'Textbook',         'Latest',          2023, 8,  7, 'TB-K2',  'CBSE History textbook for Class 10'),
  ('bk000001-0000-0000-0000-000000000013', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-439-02352-8', 'Harry Potter Sorcerers Stone',        'J.K. Rowling',      'Scholastic',     'Fiction',          '1st',             1998, 5,  5, 'FIC-L9', 'First book in the Harry Potter series'),
  ('bk000001-0000-0000-0000-000000000014', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-14-028381-5', 'Nineteen Eighty-Four',                'George Orwell',     'Penguin Books',  'Fiction',          '1st',             1949, 2,  2, 'FIC-M0', 'Dystopian novel about surveillance and totalitarianism'),
  ('bk000001-0000-0000-0000-000000000015', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-679-72020-1', 'The Great Gatsby',                    'F. Scott Fitzgerald','Scribner',      'Fiction',          '1st',             1925, 3,  3, 'FIC-N1', 'Classic American novel set in the Jazz Age'),
  ('bk000001-0000-0000-0000-000000000016', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-7387-200-3', 'NCERT Chemistry Class 12',            'NCERT',             'NCERT',          'Textbook',         'Latest',          2023, 6,  5, 'TB-O3',  'CBSE Chemistry textbook for Class 12'),
  ('bk000001-0000-0000-0000-000000000017', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-7432-7356-4', 'The Secret',                          'Rhonda Byrne',      'Atria Books',    'Self-Help',        '1st',             2006, 3,  3, 'SH-P4',  'Inspirational book about the law of attraction'),
  ('bk000001-0000-0000-0000-000000000018', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-674-02579-1', 'The Story of Mathematics',            'Anne Rooney',       'Arcturus',       'Mathematics',      '1st',             2008, 2,  2, 'MATH-Q5','History and development of mathematics'),
  ('bk000001-0000-0000-0000-000000000019', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-81-222-0049-9', 'Malgudi Days',                        'R.K. Narayan',      'Penguin India',  'Fiction',          'Penguin Ed.',     2006, 4,  4, 'FIC-R6', 'Short stories set in the fictional town of Malgudi'),
  ('bk000001-0000-0000-0000-000000000020', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', '978-0-521-63720-4', 'Physics for Scientists and Engineers', 'Serway and Jewett', 'Cengage',        'Physics',          '10th',            2018, 4,  3, 'SCI-S7', 'Comprehensive physics textbook for advanced students')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 20: TRANSPORT ROUTES
-- ============================================================
INSERT INTO transport_routes (id, tenant_id, name, code, vehicle_number, driver_name, driver_phone, capacity, fare_per_month, is_active) VALUES
  ('rt000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Route A - Andheri West',  'RT-A', 'MH-01-AB-1234', 'Ramesh Yadav',  '9988776655', 40, 2500.00, true),
  ('rt000001-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Route B - Bandra East',   'RT-B', 'MH-01-CD-5678', 'Suresh Patil',  '9977665544', 35, 2000.00, true),
  ('rt000001-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Route C - Borivali North','RT-C', 'MH-01-EF-9012', 'Dinesh Gupta',  '9966554433', 45, 3000.00, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 21: HOSTELS + HOSTEL ROOMS
-- ============================================================
INSERT INTO hostels (id, tenant_id, name, type, address, contact_number, total_rooms, total_capacity, fee_per_month, is_active) VALUES
  ('hs000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Boys Hostel Block A',  'boys',  'School Campus, East Wing', '022-12345678', 6, 24, 8000.00, true),
  ('hs000001-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Girls Hostel Block B', 'girls', 'School Campus, West Wing', '022-87654321', 4, 16, 8000.00, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO hostel_rooms (id, tenant_id, hostel_id, room_number, floor, room_type, capacity, occupied, amenities, is_available) VALUES
  ('hr000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'hs000001-0000-0000-0000-000000000001', '101', 1, 'double', 4, 3, '["WiFi","Attached Bathroom","Study Table"]', true),
  ('hr000001-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'hs000001-0000-0000-0000-000000000001', '102', 1, 'double', 4, 4, '["WiFi","Shared Bathroom"]',                 false),
  ('hr000001-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'hs000001-0000-0000-0000-000000000001', '103', 1, 'single', 2, 1, '["WiFi","Attached Bathroom","AC"]',           true),
  ('hr000001-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'hs000001-0000-0000-0000-000000000001', '201', 2, 'double', 4, 2, '["WiFi","Shared Bathroom","Study Table"]',    true),
  ('hr000001-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'hs000001-0000-0000-0000-000000000001', '202', 2, 'double', 4, 4, '["WiFi","Attached Bathroom"]',               false),
  ('hr000001-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'hs000001-0000-0000-0000-000000000001', '203', 2, 'triple', 6, 5, '["WiFi","Shared Bathroom"]',                  true),
  ('hr000001-0000-0000-0000-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'hs000001-0000-0000-0000-000000000002', '101', 1, 'double', 4, 3, '["WiFi","Attached Bathroom","Wardrobe"]',     true),
  ('hr000001-0000-0000-0000-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'hs000001-0000-0000-0000-000000000002', '102', 1, 'single', 2, 2, '["WiFi","Attached Bathroom","AC","Wardrobe"]',false),
  ('hr000001-0000-0000-0000-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'hs000001-0000-0000-0000-000000000002', '103', 1, 'double', 4, 1, '["WiFi","Shared Bathroom"]',                  true),
  ('hr000001-0000-0000-0000-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'hs000001-0000-0000-0000-000000000002', '201', 2, 'triple', 6, 4, '["WiFi","Attached Bathroom","Study Room"]',   true)
ON CONSTRAINT idx_hostel_rooms_number DO NOTHING;

-- ============================================================
-- STEP 22: CANTEEN MENU
-- ============================================================
INSERT INTO canteen_menu (id, tenant_id, name, description, price, category, is_available, available_days) VALUES
  ('cm000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Idli Sambar',      'Steamed rice cakes with lentil soup and coconut chutney', 30.00, 'Breakfast', true, '{1,2,3,4,5}'),
  ('cm000001-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Poha',             'Flattened rice with peas, onions and spices',             25.00, 'Breakfast', true, '{1,2,3,4,5}'),
  ('cm000001-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Bread Butter',     'White/Brown bread with butter and jam',                   20.00, 'Breakfast', true, '{1,2,3,4,5}'),
  ('cm000001-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Dal Rice',         'Yellow lentil soup with steamed rice',                    50.00, 'Lunch',     true, '{1,2,3,4,5}'),
  ('cm000001-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Rajma Chawal',     'Kidney beans curry with steamed rice',                    60.00, 'Lunch',     true, '{1,3,5}'),
  ('cm000001-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Chole Bhature',    'Chickpea curry with fried bread',                         70.00, 'Lunch',     true, '{2,4}'),
  ('cm000001-0000-0000-0000-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Veg Thali',        'Complete meal with roti, rice, dal, sabzi, and salad',    85.00, 'Lunch',     true, '{1,2,3,4,5}'),
  ('cm000001-0000-0000-0000-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Aloo Paratha',     'Potato stuffed flatbread with curd and butter',           40.00, 'Breakfast', true, '{1,3,5}'),
  ('cm000001-0000-0000-0000-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Masala Chai',      'Spiced Indian tea with milk',                             15.00, 'Beverages', true, '{1,2,3,4,5}'),
  ('cm000001-0000-0000-0000-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Fresh Fruit Juice','Seasonal fruit juice without sugar',                      35.00, 'Beverages', true, '{1,2,3,4,5}'),
  ('cm000001-0000-0000-0000-000000000011', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Samosa',           'Crispy pastry filled with spiced potatoes and peas',      20.00, 'Snacks',    true, '{1,2,3,4,5}'),
  ('cm000001-0000-0000-0000-000000000012', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Banana',           'Fresh ripe banana',                                       10.00, 'Fruits',    true, '{1,2,3,4,5}'),
  ('cm000001-0000-0000-0000-000000000013', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Upma',             'Semolina cooked with vegetables and spices',              30.00, 'Breakfast', true, '{2,4}'),
  ('cm000001-0000-0000-0000-000000000014', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Egg Sandwich',     'Boiled egg sandwich with vegetables',                     35.00, 'Snacks',    true, '{1,2,3,4,5}'),
  ('cm000001-0000-0000-0000-000000000015', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Cold Milk',        'Chilled full-fat milk',                                   20.00, 'Beverages', true, '{1,2,3,4,5}')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 23: TIMETABLE SLOTS
-- ============================================================
INSERT INTO timetable_slots (id, tenant_id, name, start_time, end_time, slot_type, sequence_order) VALUES
  ('ts000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 1',    '08:00', '08:45', 'class',  1),
  ('ts000001-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 2',    '08:45', '09:30', 'class',  2),
  ('ts000001-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Break',       '09:30', '09:45', 'break',  3),
  ('ts000001-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 3',    '09:45', '10:30', 'class',  4),
  ('ts000001-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 4',    '10:30', '11:15', 'class',  5),
  ('ts000001-0000-0000-0000-000000000006', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Lunch Break', '11:15', '12:00', 'lunch',  6),
  ('ts000001-0000-0000-0000-000000000007', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 5',    '12:00', '12:45', 'class',  7),
  ('ts000001-0000-0000-0000-000000000008', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 6',    '12:45', '13:30', 'class',  8),
  ('ts000001-0000-0000-0000-000000000009', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 7',    '13:30', '14:15', 'class',  9),
  ('ts000001-0000-0000-0000-000000000010', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Period 8',    '14:15', '15:00', 'class', 10)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 24: TIMETABLES for Class 10-A (5 days, 6 periods/day)
-- ============================================================
INSERT INTO timetables (tenant_id, section_id, subject_id, teacher_id, slot_id, day_of_week, academic_year_id, room_number) VALUES
  -- Monday
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000001',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000002',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000004',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000005',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000007',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee06','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000008',1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Lab'),
  -- Tuesday
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000001',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000002',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000004',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000005',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000007',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee07','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000008',2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Playground'),
  -- Wednesday
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000001',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000002',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000004',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee06','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000005',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Lab'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000007',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000008',3,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  -- Thursday
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000001',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000002',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee07','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000004',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Playground'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000005',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000007',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000008',4,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  -- Friday
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee05','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000001',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee06','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000002',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Lab'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000004',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000005',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000007',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','dddddddd-dddd-dddd-dddd-dddddddddd01','eeeeeeee-eeee-eeee-eeee-eeeeeeeeee04','22222222-2222-2222-2222-222222222222','ts000001-0000-0000-0000-000000000008',5,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10A')
ON CONFLICT ON CONSTRAINT timetables_section_id_slot_id_day_of_week_academic_year_id_key DO NOTHING;

-- ============================================================
-- STEP 25: ANNOUNCEMENTS
-- ============================================================
INSERT INTO announcements (id, tenant_id, title, content, priority, publish_at, created_by, is_published) VALUES
  ('an000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Annual Sports Day - March 15, 2026',
   'We are delighted to announce our Annual Sports Day on March 15, 2026. All students are encouraged to participate in various sports events. Parents are cordially invited to attend. Events include athletics, team sports, and cultural performances. Please report by 8:00 AM.',
   'high', NOW() - INTERVAL '5 days', '11111111-1111-1111-1111-111111111111', true),
  ('an000001-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Parent-Teacher Meeting - March 20, 2026',
   'Parent-Teacher Meeting (PTM) for Classes 9-12 is scheduled for March 20, 2026 from 9:00 AM to 2:00 PM. Parents are requested to meet the class teachers to discuss their ward academic progress. Prior appointment booking through the school app is mandatory.',
   'high', NOW() - INTERVAL '3 days', '11111111-1111-1111-1111-111111111111', true),
  ('an000001-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Fee Payment Reminder - Term 3',
   'This is a reminder to all parents that the due date for Term 3 fee payment is March 31, 2026. Please ensure timely payment to avoid late fees. Online payment options are available through the school portal. Contact the accounts office for any queries.',
   'normal', NOW() - INTERVAL '1 day', '11111111-1111-1111-1111-111111111111', true),
  ('an000001-0000-0000-0000-000000000004', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Summer Vacation Notice 2026',
   'Summer vacation for the academic year 2024-25 will commence from April 5, 2026. School will reopen for the new academic year 2025-26 on June 16, 2026. Result cards will be distributed on the last working day April 4, 2026.',
   'normal', NOW(), '11111111-1111-1111-1111-111111111111', true),
  ('an000001-0000-0000-0000-000000000005', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'New Library Books Available',
   'The school library has received a fresh batch of 50 new books across various genres including fiction, science, history, and reference materials. Students can borrow up to 2 books at a time for 14 days. Visit the library during break or after school hours.',
   'low', NOW() - INTERVAL '2 days', '11111111-1111-1111-1111-111111111111', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- BONUS: PAYMENTS for paid invoices
-- (payment_number is required + NOT NULL, status is payment_status enum)
-- ============================================================
INSERT INTO payments (tenant_id, invoice_id, payment_number, amount, payment_method, status, transaction_id, paid_at, received_by, remarks) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','inv00000-0000-0000-0000-000000000001','PAY-2024-001',20000,'online', 'completed','TXN2024001','2024-05-08 10:00:00+00','11111111-1111-1111-1111-111111111111','Full payment'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','inv00000-0000-0000-0000-000000000002','PAY-2024-002',20000,'online', 'completed','TXN2024002','2024-05-09 10:00:00+00','11111111-1111-1111-1111-111111111111','Full payment'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','inv00000-0000-0000-0000-000000000003','PAY-2024-003',19000,'cheque', 'completed','CHQ2024001','2024-05-07 10:00:00+00','11111111-1111-1111-1111-111111111111','After sibling discount'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','inv00000-0000-0000-0000-000000000005','PAY-2024-005',10000,'cash',   'completed','CASH2024001','2024-05-10 10:00:00+00','11111111-1111-1111-1111-111111111111','Partial payment'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','inv00000-0000-0000-0000-000000000006','PAY-2024-006',20000,'upi',    'completed','UPI2024006', '2024-05-08 10:00:00+00','11111111-1111-1111-1111-111111111111','Full payment'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','inv00000-0000-0000-0000-000000000008','PAY-2024-008',18000,'upi',    'completed','UPI2024008', '2024-05-09 10:00:00+00','11111111-1111-1111-1111-111111111111','After merit concession'),
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','inv00000-0000-0000-0000-000000000009','PAY-2024-009',20000,'online', 'completed','TXN2024009','2024-05-08 10:00:00+00','11111111-1111-1111-1111-111111111111','Full payment')
ON CONFLICT ON CONSTRAINT idx_payments_number DO NOTHING;

-- ============================================================
-- FINAL VERIFICATION COUNTS
-- ============================================================
SELECT table_name, row_count FROM (
  SELECT 'academic_years'    AS table_name, count(*) AS row_count FROM academic_years    WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'terms',                           count(*)              FROM terms              WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'classes',                         count(*)              FROM classes             WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'sections',                        count(*)              FROM sections            WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'subjects',                        count(*)              FROM subjects            WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'class_subjects',                  count(*)              FROM class_subjects      WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'staff',                           count(*)              FROM staff               WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'teacher_assignments',             count(*)              FROM teacher_assignments WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'students',                        count(*)              FROM students            WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'student_enrollments',             count(*)              FROM student_enrollments WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'parents',                         count(*)              FROM parents             WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'student_parents',                 count(*)              FROM student_parents     UNION ALL
  SELECT 'attendance',                      count(*)              FROM attendance          WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'exams',                           count(*)              FROM exams               WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'exam_subjects',                   count(*)              FROM exam_subjects       WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'marks',                           count(*)              FROM marks               WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'fee_heads',                       count(*)              FROM fee_heads           WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'fee_structures',                  count(*)              FROM fee_structures      WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'invoices',                        count(*)              FROM invoices            WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'payments',                        count(*)              FROM payments            WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'library_books',                   count(*)              FROM library_books       WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'transport_routes',                count(*)              FROM transport_routes    WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'hostels',                         count(*)              FROM hostels             WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'hostel_rooms',                    count(*)              FROM hostel_rooms        WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'canteen_menu',                    count(*)              FROM canteen_menu        WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'timetable_slots',                 count(*)              FROM timetable_slots     WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'timetables',                      count(*)              FROM timetables          WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' UNION ALL
  SELECT 'announcements',                   count(*)              FROM announcements       WHERE tenant_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
) t ORDER BY table_name;
