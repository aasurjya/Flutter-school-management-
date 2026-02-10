-- =============================================
-- Test Users Seed Data
-- Creates test users for all stakeholder roles
-- =============================================

-- Note: Supabase auth requires users to be created via API or Dashboard
-- This file creates the users table entries and role assignments
-- For auth.users, we'll need to use Supabase Dashboard or signUp function

-- =============================================
-- 1. CREATE TENANT
-- =============================================

INSERT INTO tenants (id, name, slug, email, phone, city, country, subscription_plan, is_active)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Demo International School',
    'demo-school',
    'admin@demoschool.edu',
    '+1-555-0100',
    'New York',
    'USA',
    'enterprise',
    true
);

-- =============================================
-- 2. CREATE ACADEMIC STRUCTURE
-- =============================================

-- Academic Year
INSERT INTO academic_years (id, tenant_id, name, start_date, end_date, is_current)
VALUES (
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '2025-2026',
    '2025-08-01',
    '2026-06-30',
    true
);

-- Terms
INSERT INTO terms (id, tenant_id, academic_year_id, name, start_date, end_date, is_current)
VALUES
    ('11000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Fall 2025', '2025-08-01', '2025-12-20', true),
    ('11000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Spring 2026', '2026-01-05', '2026-06-30', false);

-- Classes
INSERT INTO classes (id, tenant_id, name, description, sort_order)
VALUES
    ('12000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Grade 1', 'First Grade', 1),
    ('12000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Grade 2', 'Second Grade', 2),
    ('12000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Grade 3', 'Third Grade', 3),
    ('12000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Grade 10', 'Tenth Grade', 10);

-- Sections
INSERT INTO sections (id, tenant_id, class_id, name, max_students)
VALUES
    ('13000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '12000000-0000-0000-0000-000000000001', 'Section A', 30),
    ('13000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '12000000-0000-0000-0000-000000000002', 'Section A', 30),
    ('13000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '12000000-0000-0000-0000-000000000004', 'Section A', 40);

-- Subjects
INSERT INTO subjects (id, tenant_id, name, code, subject_type)
VALUES
    ('14000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Mathematics', 'MATH', 'mandatory'),
    ('14000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'English', 'ENG', 'mandatory'),
    ('14000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Science', 'SCI', 'mandatory'),
    ('14000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Art', 'ART', 'elective');

-- =============================================
-- 3. CREATE USERS & ROLES
-- =============================================

-- IMPORTANT: These UUIDs must match auth.users created in Supabase Auth
-- We'll use predictable UUIDs for testing

-- Super Admin
INSERT INTO users (id, tenant_id, email, full_name, phone, is_active)
VALUES (
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'superadmin@demoschool.edu',
    'Super Admin User',
    '+1-555-0101',
    true
);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES (
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'super_admin',
    true
);

-- Tenant Admin
INSERT INTO users (id, tenant_id, email, full_name, phone, is_active)
VALUES (
    '20000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'admin@demoschool.edu',
    'Admin User',
    '+1-555-0102',
    true
);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES (
    '20000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'tenant_admin',
    true
);

-- Principal
INSERT INTO users (id, tenant_id, email, full_name, phone, is_active)
VALUES (
    '20000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000001',
    'principal@demoschool.edu',
    'Dr. Principal Smith',
    '+1-555-0103',
    true
);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES (
    '20000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000001',
    'principal',
    true
);

-- Teachers
INSERT INTO users (id, tenant_id, email, full_name, phone, is_active)
VALUES
    ('20000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', 'teacher1@demoschool.edu', 'John Teacher', '+1-555-0110', true),
    ('20000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000001', 'teacher2@demoschool.edu', 'Mary Teacher', '+1-555-0111', true),
    ('20000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000001', 'teacher3@demoschool.edu', 'Bob Teacher', '+1-555-0112', true);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES
    ('20000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', 'teacher', true),
    ('20000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000001', 'teacher', true),
    ('20000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000001', 'teacher', true);

-- Staff
INSERT INTO staff (id, tenant_id, user_id, employee_id, full_name, email, phone, designation, department, hire_date, is_active)
VALUES
    ('15000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000010', 'EMP001', 'John Teacher', 'teacher1@demoschool.edu', '+1-555-0110', 'Math Teacher', 'Academics', '2020-08-01', true),
    ('15000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000011', 'EMP002', 'Mary Teacher', 'teacher2@demoschool.edu', '+1-555-0111', 'English Teacher', 'Academics', '2021-08-01', true),
    ('15000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000012', 'EMP003', 'Bob Teacher', 'teacher3@demoschool.edu', '+1-555-0112', 'Science Teacher', 'Academics', '2019-08-01', true);

-- Accountant
INSERT INTO users (id, tenant_id, email, full_name, phone, is_active)
VALUES (
    '20000000-0000-0000-0000-000000000020',
    '00000000-0000-0000-0000-000000000001',
    'accountant@demoschool.edu',
    'Alice Accountant',
    '+1-555-0120',
    true
);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES (
    '20000000-0000-0000-0000-000000000020',
    '00000000-0000-0000-0000-000000000001',
    'accountant',
    true
);

INSERT INTO staff (id, tenant_id, user_id, employee_id, full_name, email, phone, designation, department, hire_date, is_active)
VALUES (
    '15000000-0000-0000-0000-000000000010',
    '00000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000020',
    'EMP010',
    'Alice Accountant',
    'accountant@demoschool.edu',
    '+1-555-0120',
    'Senior Accountant',
    'Finance',
    '2018-01-01',
    true
);

-- Students
INSERT INTO users (id, tenant_id, email, full_name, phone, is_active)
VALUES
    ('20000000-0000-0000-0000-000000000100', '00000000-0000-0000-0000-000000000001', 'student1@demoschool.edu', 'Emma Student', '+1-555-0200', true),
    ('20000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 'student2@demoschool.edu', 'Liam Student', '+1-555-0201', true),
    ('20000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000001', 'student3@demoschool.edu', 'Olivia Student', '+1-555-0202', true),
    ('20000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000001', 'student4@demoschool.edu', 'Noah Student', '+1-555-0203', true),
    ('20000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000001', 'student5@demoschool.edu', 'Ava Student', '+1-555-0204', true);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES
    ('20000000-0000-0000-0000-000000000100', '00000000-0000-0000-0000-000000000001', 'student', true),
    ('20000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 'student', true),
    ('20000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000001', 'student', true),
    ('20000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000001', 'student', true),
    ('20000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000001', 'student', true);

INSERT INTO students (id, tenant_id, user_id, admission_number, roll_number, full_name, email, date_of_birth, gender, blood_group, is_active)
VALUES
    ('16000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000100', 'ADM2025001', '001', 'Emma Student', 'student1@demoschool.edu', '2015-05-15', 'Female', 'A+', true),
    ('16000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000101', 'ADM2025002', '002', 'Liam Student', 'student2@demoschool.edu', '2015-03-20', 'Male', 'B+', true),
    ('16000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000102', 'ADM2025003', '003', 'Olivia Student', 'student3@demoschool.edu', '2015-07-10', 'Female', 'O+', true),
    ('16000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000103', 'ADM2025004', '004', 'Noah Student', 'student4@demoschool.edu', '2011-08-25', 'Male', 'AB+', true),
    ('16000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000104', 'ADM2025005', '005', 'Ava Student', 'student5@demoschool.edu', '2011-12-05', 'Female', 'A+', true);

-- Student Enrollments
INSERT INTO student_enrollments (id, tenant_id, student_id, academic_year_id, class_id, section_id, roll_number, enrollment_date, status)
VALUES
    ('17000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '12000000-0000-0000-0000-000000000001', '13000000-0000-0000-0000-000000000001', '001', '2025-08-01', 'active'),
    ('17000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '12000000-0000-0000-0000-000000000001', '13000000-0000-0000-0000-000000000001', '002', '2025-08-01', 'active'),
    ('17000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', '12000000-0000-0000-0000-000000000002', '13000000-0000-0000-0000-000000000002', '003', '2025-08-01', 'active'),
    ('17000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', '12000000-0000-0000-0000-000000000004', '13000000-0000-0000-0000-000000000003', '004', '2025-08-01', 'active'),
    ('17000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000001', '12000000-0000-0000-0000-000000000004', '13000000-0000-0000-0000-000000000003', '005', '2025-08-01', 'active');

-- Parents
INSERT INTO users (id, tenant_id, email, full_name, phone, is_active)
VALUES
    ('20000000-0000-0000-0000-000000000200', '00000000-0000-0000-0000-000000000001', 'parent1@demoschool.edu', 'Robert Parent', '+1-555-0300', true),
    ('20000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000001', 'parent2@demoschool.edu', 'Sarah Parent', '+1-555-0301', true),
    ('20000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000001', 'parent3@demoschool.edu', 'Michael Parent', '+1-555-0302', true);

INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES
    ('20000000-0000-0000-0000-000000000200', '00000000-0000-0000-0000-000000000001', 'parent', true),
    ('20000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000001', 'parent', true),
    ('20000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000001', 'parent', true);

INSERT INTO parents (id, tenant_id, user_id, full_name, email, phone, occupation, is_primary_contact)
VALUES
    ('18000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000200', 'Robert Parent', 'parent1@demoschool.edu', '+1-555-0300', 'Engineer', true),
    ('18000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000201', 'Sarah Parent', 'parent2@demoschool.edu', '+1-555-0301', 'Doctor', true),
    ('18000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000202', 'Michael Parent', 'parent3@demoschool.edu', '+1-555-0302', 'Lawyer', true);

-- Student-Parent relationships
INSERT INTO student_parents (id, tenant_id, student_id, parent_id, relationship)
VALUES
    ('19000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-000000000001', '18000000-0000-0000-0000-000000000001', 'father'),
    ('19000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-000000000002', '18000000-0000-0000-0000-000000000001', 'father'),
    ('19000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-000000000003', '18000000-0000-0000-0000-000000000002', 'mother'),
    ('19000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-000000000004', '18000000-0000-0000-0000-000000000003', 'father'),
    ('19000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-000000000005', '18000000-0000-0000-0000-000000000003', 'father');

-- =============================================
-- 4. CREATE SAMPLE DATA FOR NEW FEATURES
-- =============================================

-- Sample ML Model
INSERT INTO ml_models (id, tenant_id, model_type, model_name, model_version, algorithm, status, is_active)
VALUES (
    '30000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'performance_prediction',
    'Student Performance Predictor v1',
    '1.0.0',
    'random_forest',
    'active',
    true
);

-- Sample Performance Predictions for at-risk student
INSERT INTO student_performance_predictions (
    id, student_id, academic_year_id, model_id,
    predicted_gpa, risk_level, dropout_probability, confidence,
    intervention_required, recommended_actions, early_warning_flags
)
VALUES (
    '31000000-0000-0000-0000-000000000001',
    '16000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    2.5,
    'high',
    0.65,
    'high',
    true,
    '[{"action": "academic_support", "priority": "high", "estimated_impact": "30%"}, {"action": "counseling", "priority": "medium", "estimated_impact": "20%"}]'::jsonb,
    ARRAY['low_attendance', 'declining_grades', 'behavioral_issues']
);

-- Sample Fee Payment Plan
INSERT INTO invoices (id, tenant_id, student_id, invoice_number, invoice_date, due_date, total_amount, status)
VALUES (
    '40000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '16000000-0000-0000-0000-000000000001',
    'INV-2025-001',
    '2025-08-01',
    '2025-09-01',
    10000.00,
    'pending'
);

INSERT INTO fee_payment_plans (
    id, invoice_id, student_id, plan_name,
    total_amount, down_payment, installment_amount,
    number_of_installments, frequency, start_date, end_date,
    status
)
VALUES (
    '41000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    '16000000-0000-0000-0000-000000000001',
    'Monthly Payment Plan',
    10000.00,
    1000.00,
    1000.00,
    9,
    'monthly',
    '2025-09-01',
    '2026-05-01',
    'active'
);

-- Auto-generate installments
SELECT auto_generate_installments('41000000-0000-0000-0000-000000000001');

-- Sample Behavior Incident
INSERT INTO behavior_incidents (
    id, student_id, incident_date, behavior_type,
    behavior_category, severity, title, description,
    reported_by, conduct_points_deducted
)
VALUES (
    '50000000-0000-0000-0000-000000000001',
    '16000000-0000-0000-0000-000000000004',
    '2025-09-15',
    'negative',
    'classroom_disruption',
    'moderate',
    'Classroom Disruption',
    'Student was talking during class despite warnings',
    '20000000-0000-0000-0000-000000000010',
    10
);

-- =============================================
-- SUCCESS MESSAGE
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Test users created successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Total users created: 13';
    RAISE NOTICE '- 1 Super Admin';
    RAISE NOTICE '- 1 Tenant Admin';
    RAISE NOTICE '- 1 Principal';
    RAISE NOTICE '- 3 Teachers';
    RAISE NOTICE '- 1 Accountant';
    RAISE NOTICE '- 5 Students';
    RAISE NOTICE '- 3 Parents';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANT: Auth users must be created separately in Supabase Dashboard';
    RAISE NOTICE 'See LOGIN_CREDENTIALS.md for login details';
END $$;
