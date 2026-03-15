-- Seed data for all empty feature module tables
-- Tenant:       a1b2c3d4-e5f6-7890-abcd-ef1234567890
-- Admin user:   11111111-1111-1111-1111-111111111111
-- Teacher user: 22222222-2222-2222-2222-222222222222
-- Staff (teacher): ffffffff-ffff-ffff-ffff-ffffffffffff
-- Student:      55555555-5555-5555-5555-555555555555
-- Section A:    dddddddd-dddd-dddd-dddd-dddddddddd01
-- Class 1:      cccccccc-cccc-cccc-cccc-cccccccccc01
-- Subject Math: eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01
-- Subject Eng:  eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02
-- Subject Sci:  eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03
-- Acad Year:    aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
-- Term 1:       bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01

SET search_path = public;

-- ============================================================
-- NOTICES
-- ============================================================
INSERT INTO notices (id, tenant_id, title, body, category, audience, is_published, created_by)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'School Annual Day Celebration',
   'Dear Students and Parents, We are pleased to announce our Annual Day celebration on 25th March 2026. All students are requested to participate.',
   'events'::notice_category, 'all'::notice_audience, true, '11111111-1111-1111-1111-111111111111'),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Exam Schedule Released',
   'The mid-term examination schedule has been released. Students are advised to check the timetable and prepare accordingly.',
   'examination'::notice_category, 'all'::notice_audience, true, '11111111-1111-1111-1111-111111111111'),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Holiday Notice - Holi',
   'School will remain closed on 14th March 2026 on account of Holi. Classes will resume on 16th March 2026.',
   'holiday'::notice_category, 'all'::notice_audience, true, '11111111-1111-1111-1111-111111111111')
ON CONFLICT DO NOTHING;

-- ============================================================
-- HOMEWORK
-- ============================================================
INSERT INTO homework (id, tenant_id, section_id, subject_id, assigned_by, title, description, due_date, status)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'dddddddd-dddd-dddd-dddd-dddddddddd01',
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01',
   '22222222-2222-2222-2222-222222222222',
   'Chapter 5 Exercise Problems',
   'Complete exercises 5.1 to 5.4 from your mathematics textbook. Show all steps.',
   CURRENT_DATE + 7, 'published'),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'dddddddd-dddd-dddd-dddd-dddddddddd01',
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02',
   '22222222-2222-2222-2222-222222222222',
   'Essay Writing - My Favourite Festival',
   'Write a 300-word essay on your favourite festival. Submit in your English notebook.',
   CURRENT_DATE + 5, 'published'),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'dddddddd-dddd-dddd-dddd-dddddddddd01',
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03',
   '22222222-2222-2222-2222-222222222222',
   'Science Lab Report',
   'Write a detailed lab report on the photosynthesis experiment conducted in class.',
   CURRENT_DATE + 10, 'published')
ON CONFLICT DO NOTHING;

-- ============================================================
-- ASSIGNMENTS
-- ============================================================
INSERT INTO assignments (id, tenant_id, section_id, subject_id, teacher_id, title, description, due_date, max_marks, status)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'dddddddd-dddd-dddd-dddd-dddddddddd01',
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01',
   '22222222-2222-2222-2222-222222222222',
   'Algebra Quiz - Linear Equations',
   'Solve the given set of linear equations. This assignment contributes 10 marks to your internal assessment.',
   NOW() + INTERVAL '14 days', 10, 'published'::assignment_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'dddddddd-dddd-dddd-dddd-dddddddddd01',
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02',
   '22222222-2222-2222-2222-222222222222',
   'Reading Comprehension Test',
   'Read the passage and answer all comprehension questions.',
   NOW() + INTERVAL '7 days', 20, 'published'::assignment_status)
ON CONFLICT DO NOTHING;

-- ============================================================
-- SCHOOL EVENTS
-- ============================================================
INSERT INTO school_events (id, tenant_id, title, description, event_type, start_date, end_date, location, created_by, visibility, status)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Annual Sports Day',
   'Inter-house sports competition with track events, field events and team sports.',
   'sports', (CURRENT_DATE + 30), (CURRENT_DATE + 31), 'School Sports Ground',
   '11111111-1111-1111-1111-111111111111', 'all'::event_visibility, 'scheduled'::event_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Science Exhibition 2026',
   'Students showcase their science projects. Parents are invited to attend.',
   'academic', (CURRENT_DATE + 45), (CURRENT_DATE + 46), 'School Auditorium',
   '11111111-1111-1111-1111-111111111111', 'all'::event_visibility, 'scheduled'::event_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Parent-Teacher Meeting - Term 1',
   'PTM to discuss student progress and academic performance.',
   'meeting', (CURRENT_DATE + 15), (CURRENT_DATE + 15), 'School Classrooms',
   '11111111-1111-1111-1111-111111111111', 'parents'::event_visibility, 'scheduled'::event_status)
ON CONFLICT DO NOTHING;

-- ============================================================
-- CALENDAR EVENTS
-- ============================================================
INSERT INTO calendar_events (id, tenant_id, title, description, event_type, start_date, end_date, is_all_day, created_by, target_roles)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Mid-Term Exams Begin',
   'Mid-term examination period starts. Regular classes suspended.',
   'exam'::event_type, (CURRENT_DATE + 20), (CURRENT_DATE + 25), true,
   '11111111-1111-1111-1111-111111111111', '{student,teacher,parent}'::user_role[]),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Summer Vacation',
   'School summer vacation from 1st May to 30th June 2026.',
   'holiday'::event_type, '2026-05-01'::date, '2026-06-30'::date, true,
   '11111111-1111-1111-1111-111111111111', '{student,teacher,parent}'::user_role[]),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Staff Development Day',
   'Professional development program for teaching staff.',
   'meeting'::event_type, (CURRENT_DATE + 10), (CURRENT_DATE + 10), true,
   '11111111-1111-1111-1111-111111111111', '{teacher}'::user_role[])
ON CONFLICT DO NOTHING;

-- ============================================================
-- ADMISSION APPLICATIONS
-- ============================================================
INSERT INTO admission_applications (
  id, tenant_id, application_number, application_date, target_class_id, academic_year_id,
  student_name, date_of_birth, gender, father_name, father_phone, father_email, status
) VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'APP-2026-001', CURRENT_DATE - 5,
   'cccccccc-cccc-cccc-cccc-cccccccccc01',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   'Arjun Mehta', '2016-03-15', 'male', 'Suresh Mehta', '+91-9876543210', 'suresh.mehta@email.com',
   'under_review'::application_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'APP-2026-002', CURRENT_DATE - 10,
   'cccccccc-cccc-cccc-cccc-cccccccccc05',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   'Priyanka Singh', '2015-07-22', 'female', 'Ramesh Singh', '+91-9876543211', 'ramesh.singh@email.com',
   'under_review'::application_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'APP-2026-003', CURRENT_DATE - 2,
   'cccccccc-cccc-cccc-cccc-cccccccccc10',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   'Kiran Patel', '2017-01-10', 'female', 'Harish Patel', '+91-9876543212', 'harish.patel@email.com',
   'submitted'::application_status)
ON CONFLICT (application_number) DO NOTHING;

-- ============================================================
-- ALUMNI PROFILES
-- ============================================================
INSERT INTO alumni_profiles (id, tenant_id, first_name, last_name, graduation_year, email, phone, current_company, current_designation, linkedin_url, is_verified, visibility)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Vikram', 'Sharma', 2020, 'vikram.sharma@gmail.com', '+91-9876500001',
   'TCS Limited', 'Software Engineer', 'https://linkedin.com/in/vikram-sharma', true, 'alumni_only'::alumni_visibility),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Deepa', 'Nair', 2018, 'deepa.nair@gmail.com', '+91-9876500002',
   'Infosys', 'Senior Analyst', 'https://linkedin.com/in/deepa-nair', true, 'alumni_only'::alumni_visibility),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Arun', 'Kumar', 2022, 'arun.kumar@gmail.com', '+91-9876500003',
   'Wipro Technologies', 'Junior Developer', NULL, false, 'alumni_only'::alumni_visibility)
ON CONFLICT DO NOTHING;

-- ============================================================
-- VISITORS (required for visitor_logs FK)
-- ============================================================
INSERT INTO visitors (id, tenant_id, full_name, phone, id_type, id_number)
VALUES
  ('aa000001-0000-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Ramesh Kumar', '+91-9876501001', 'national_id', 'NID-1234567890'),
  ('aa000001-0000-0000-0000-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Sunita Devi', '+91-9876501002', 'drivers_license', 'DL-MH-001234'),
  ('aa000001-0000-0000-0000-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Amazon Delivery Agent', '+91-9876501003', NULL, NULL)
ON CONFLICT DO NOTHING;

-- ============================================================
-- VISITOR LOGS
-- ============================================================
INSERT INTO visitor_logs (id, tenant_id, visitor_id, purpose, person_to_meet, check_in_time, check_out_time, badge_number, status)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'aa000001-0000-0000-0000-000000000001',
   'parent_visit'::visitor_log_purpose, '22222222-2222-2222-2222-222222222222',
   NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour', 'B-001', 'checked_out'::visitor_log_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'aa000001-0000-0000-0000-000000000002',
   'meeting'::visitor_log_purpose, '11111111-1111-1111-1111-111111111111',
   NOW() - INTERVAL '30 minutes', NULL, 'B-002', 'checked_in'::visitor_log_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'aa000001-0000-0000-0000-000000000003',
   'delivery'::visitor_log_purpose, '11111111-1111-1111-1111-111111111111',
   NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '30 minutes', 'B-003', 'checked_out'::visitor_log_status)
ON CONFLICT DO NOTHING;

-- ============================================================
-- VISITOR PRE-REGISTRATIONS
-- ============================================================
INSERT INTO visitor_pre_registrations (id, tenant_id, visitor_name, visitor_email, visitor_phone, purpose, host_id, expected_date, status)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Mr. Anand Krishnan', 'anand.k@email.com', '+91-9876502001',
   'meeting'::visitor_log_purpose, '11111111-1111-1111-1111-111111111111',
   CURRENT_DATE + 2, 'approved'::visitor_pre_reg_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Mrs. Lakshmi Rao', 'lakshmi.rao@email.com', '+91-9876502002',
   'other'::visitor_log_purpose, '11111111-1111-1111-1111-111111111111',
   CURRENT_DATE + 1, 'pending'::visitor_pre_reg_status)
ON CONFLICT DO NOTHING;

-- ============================================================
-- ONLINE EXAMS
-- ============================================================
INSERT INTO online_exams (id, tenant_id, title, description, exam_type, subject_id, class_id, section_ids, created_by, total_marks, passing_marks, duration_minutes, start_time, end_time, status)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Math Unit Test - Chapter 5', 'Online unit test covering linear equations.',
   'unit_test'::online_exam_type,
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01',
   'cccccccc-cccc-cccc-cccc-cccccccccc01',
   '["dddddddd-dddd-dddd-dddd-dddddddddd01"]'::jsonb,
   '22222222-2222-2222-2222-222222222222',
   50, 20, 60,
   NOW() + INTERVAL '3 days', NOW() + INTERVAL '3 days' + INTERVAL '2 hours',
   'scheduled'::online_exam_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'English Grammar Quiz', 'Quick quiz on tenses and sentence structure.',
   'class_test'::online_exam_type,
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02',
   'cccccccc-cccc-cccc-cccc-cccccccccc01',
   '["dddddddd-dddd-dddd-dddd-dddddddddd01"]'::jsonb,
   '22222222-2222-2222-2222-222222222222',
   25, 10, 30,
   NOW() + INTERVAL '7 days', NOW() + INTERVAL '7 days' + INTERVAL '1 hour',
   'scheduled'::online_exam_status)
ON CONFLICT DO NOTHING;

-- ============================================================
-- COMMUNICATION CAMPAIGNS
-- ============================================================
INSERT INTO communication_campaigns (id, tenant_id, name, body, target_type, channels, status, created_by, scheduled_at)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Fee Reminder - March 2026',
   'Dear Parent, this is a reminder that school fees are due by 15th March 2026. Please pay at the school office or via online portal.',
   'parents'::campaign_target_type, '["sms","in_app"]'::jsonb,
   'draft'::campaign_status, '11111111-1111-1111-1111-111111111111',
   NOW() + INTERVAL '2 days'),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Annual Day Invitation',
   'You are cordially invited to our Annual Day celebration on 25th March 2026 at 5 PM. Venue: School Auditorium. Please RSVP by 20th March.',
   'all'::campaign_target_type, '["email","in_app"]'::jsonb,
   'sent'::campaign_status, '11111111-1111-1111-1111-111111111111',
   NOW() - INTERVAL '2 days')
ON CONFLICT DO NOTHING;

-- ============================================================
-- BEHAVIOR INCIDENTS
-- ============================================================
INSERT INTO behavior_incidents (id, tenant_id, student_id, reported_by, incident_date, description, severity, status)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   '55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222222',
   CURRENT_DATE - 5,
   'Student arrived 30 minutes late to school without a valid reason. Third occurrence this month.',
   'minor'::incident_severity, 'resolved'::incident_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   '55555555-5555-5555-5555-555555555556', '22222222-2222-2222-2222-222222222222',
   CURRENT_DATE - 3,
   'Student was disruptive during science class, disturbing other students.',
   'moderate'::incident_severity, 'investigating'::incident_status)
ON CONFLICT DO NOTHING;

-- ============================================================
-- REPORT CARD TEMPLATES (required FK for report_cards)
-- ============================================================
INSERT INTO report_card_templates (id, tenant_id, name, layout, header_config, sections, is_default)
VALUES
  ('00000000-0000-0000-0001-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Standard Term Report', 'standard'::report_card_layout,
   '{"school_name":true,"logo":true,"student_info":true}'::jsonb,
   '[]'::jsonb, true)
ON CONFLICT DO NOTHING;

-- ============================================================
-- REPORT CARDS
-- ============================================================
INSERT INTO report_cards (id, tenant_id, student_id, academic_year_id, term_id, template_id, exam_ids, data, status)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   '55555555-5555-5555-5555-555555555555',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01',
   '00000000-0000-0000-0001-000000000001',
   '[]'::jsonb,
   '{"overall_grade":"B+","overall_percentage":78.5,"remarks":"Good performance."}'::jsonb,
   'draft'::report_card_status),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   '55555555-5555-5555-5555-555555555556',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01',
   '00000000-0000-0000-0001-000000000001',
   '[]'::jsonb,
   '{"overall_grade":"A","overall_percentage":85.0,"remarks":"Outstanding performance."}'::jsonb,
   'draft'::report_card_status)
ON CONFLICT DO NOTHING;

-- ============================================================
-- PAYROLL RUNS
-- ============================================================
INSERT INTO payroll_runs (id, tenant_id, month, year, status, total_gross, total_deductions, total_net)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   2, 2026, 'completed'::payroll_run_status, 375000, 45000, 330000),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   3, 2026, 'draft'::payroll_run_status, 0, 0, 0)
ON CONFLICT (tenant_id, month, year) DO NOTHING;

-- ============================================================
-- INVENTORY ASSET CATEGORIES
-- ============================================================
INSERT INTO inv_asset_categories (id, tenant_id, name, description, depreciation_rate)
VALUES
  ('00000000-0000-0000-0002-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Electronics', 'Computers, projectors, printers and other electronic equipment', 20),
  ('00000000-0000-0000-0002-000000000002', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Furniture', 'Desks, chairs, almirahs and other furniture items', 10),
  ('00000000-0000-0000-0002-000000000003', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Sports Equipment', 'Cricket kits, footballs, badminton sets and other sports items', 15)
ON CONFLICT DO NOTHING;

-- ============================================================
-- INVENTORY ASSETS
-- ============================================================
INSERT INTO inv_assets (id, tenant_id, asset_code, name, category_id, purchase_date, purchase_price, current_value, location, condition, status)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'ELEC-001', 'Desktop Computer - Computer Lab',
   '00000000-0000-0000-0002-000000000001', CURRENT_DATE - 365, 45000, 38000,
   'Block A - Computer Lab', 'good'::asset_condition_v2, 'in_use'::asset_status_v2),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'ELEC-002', 'Projector - Classroom 101',
   '00000000-0000-0000-0002-000000000001', CURRENT_DATE - 180, 35000, 30000,
   'Block B - Room 101', 'good'::asset_condition_v2, 'in_use'::asset_status_v2),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'FURN-001', 'Teacher Desk Set - Staff Room',
   '00000000-0000-0000-0002-000000000002', CURRENT_DATE - 730, 12000, 9000,
   'Block C - Staff Room', 'good'::asset_condition_v2, 'in_use'::asset_status_v2),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'SPRT-001', 'Cricket Kit - Full Set',
   '00000000-0000-0000-0002-000000000003', CURRENT_DATE - 90, 8000, 7000,
   'Sports Room', 'excellent'::asset_condition_v2, 'available'::asset_status_v2),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'ELEC-003', 'Laser Printer - Office',
   '00000000-0000-0000-0002-000000000001', CURRENT_DATE - 240, 15000, 12000,
   'Admin Office', 'good'::asset_condition_v2, 'in_use'::asset_status_v2)
ON CONFLICT (tenant_id, asset_code) DO NOTHING;

-- ============================================================
-- LMS COURSES
-- ============================================================
INSERT INTO courses (id, tenant_id, title, description, subject_id, class_id, teacher_id, status, is_self_paced)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Mathematics Fundamentals', 'Comprehensive course covering algebra, geometry and arithmetic.',
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01',
   'cccccccc-cccc-cccc-cccc-cccccccccc01',
   '22222222-2222-2222-2222-222222222222',
   'published'::lms_course_status, false),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'English Language Skills', 'Develop reading, writing and communication skills in English.',
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee02',
   'cccccccc-cccc-cccc-cccc-cccccccccc01',
   '22222222-2222-2222-2222-222222222222',
   'published'::lms_course_status, false),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Science Explorer', 'Interactive science lessons covering physics, chemistry and biology.',
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee03',
   'cccccccc-cccc-cccc-cccc-cccccccccc01',
   '22222222-2222-2222-2222-222222222222',
   'draft'::lms_course_status, true)
ON CONFLICT DO NOTHING;

-- ============================================================
-- CERTIFICATE TEMPLATES
-- ============================================================
INSERT INTO certificate_templates (id, tenant_id, name, type, layout_data, variables, is_active)
VALUES
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Academic Excellence Certificate', 'achievement'::certificate_type,
   '{"orientation":"landscape","size":"A4","background":"#FFFFFF"}'::jsonb,
   '[{"key":"student_name","label":"Student Name"},{"key":"grade","label":"Grade"},{"key":"percentage","label":"Percentage"}]'::jsonb,
   true),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Participation Certificate', 'participation'::certificate_type,
   '{"orientation":"landscape","size":"A4","background":"#F0F8FF"}'::jsonb,
   '[{"key":"student_name","label":"Student Name"},{"key":"event_name","label":"Event Name"},{"key":"event_date","label":"Event Date"}]'::jsonb,
   true),
  (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
   'Bonafide Certificate', 'bonafide'::certificate_type,
   '{"orientation":"portrait","size":"A4","background":"#FFFFFF"}'::jsonb,
   '[{"key":"student_name","label":"Student Name"},{"key":"class","label":"Class"},{"key":"issue_date","label":"Issue Date"}]'::jsonb,
   true)
ON CONFLICT DO NOTHING;
