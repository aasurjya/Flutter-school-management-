-- =============================================
-- Seed Data for New Features
-- =============================================

-- Use the existing tenant and users
DO $$
DECLARE
    v_tenant_id UUID := 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
    v_admin_id UUID;
    v_teacher_id UUID;
    v_student_id UUID;
    v_parent_id UUID;
    v_academic_year_id UUID;
    v_section_id UUID;
    v_subject_id UUID;
BEGIN
    -- Get existing user IDs
    SELECT id INTO v_admin_id FROM users WHERE email = 'admin@demo-school.edu' LIMIT 1;
    SELECT id INTO v_teacher_id FROM users WHERE email = 'teacher@demo-school.edu' LIMIT 1;
    SELECT id INTO v_student_id FROM students WHERE tenant_id = v_tenant_id LIMIT 1;
    SELECT id INTO v_parent_id FROM users WHERE email = 'parent@demo-school.edu' LIMIT 1;

    -- Get academic year
    SELECT id INTO v_academic_year_id FROM academic_years WHERE tenant_id = v_tenant_id AND is_current = true LIMIT 1;

    -- Get section
    SELECT id INTO v_section_id FROM sections WHERE tenant_id = v_tenant_id LIMIT 1;

    -- Get subject
    SELECT id INTO v_subject_id FROM subjects WHERE tenant_id = v_tenant_id LIMIT 1;

    -- =============================================
    -- ACHIEVEMENTS
    -- =============================================
    INSERT INTO achievements (id, tenant_id, name, description, icon_name, points, category, criteria, is_active) VALUES
    ('ach-001', v_tenant_id, 'Perfect Attendance', 'Attended all classes for a month', 'stars', 100, 'attendance', '{"type": "attendance", "days": 30}', true),
    ('ach-002', v_tenant_id, 'Top Scorer', 'Achieved highest marks in an exam', 'emoji_events', 200, 'academic', '{"type": "exam", "rank": 1}', true),
    ('ach-003', v_tenant_id, 'Quick Learner', 'Completed 5 quizzes with 90%+ score', 'school', 150, 'academic', '{"type": "quiz", "count": 5, "min_score": 90}', true),
    ('ach-004', v_tenant_id, 'Bookworm', 'Read and returned 10 library books', 'menu_book', 75, 'library', '{"type": "library", "books": 10}', true),
    ('ach-005', v_tenant_id, 'Helper', 'Helped 5 classmates with assignments', 'volunteer_activism', 50, 'social', '{"type": "social", "helps": 5}', true)
    ON CONFLICT DO NOTHING;

    -- Student Points
    IF v_student_id IS NOT NULL THEN
        INSERT INTO student_points (tenant_id, student_id, category, points, earned_at) VALUES
        (v_tenant_id, v_student_id, 'attendance', 50, NOW() - INTERVAL '5 days'),
        (v_tenant_id, v_student_id, 'academic', 100, NOW() - INTERVAL '3 days'),
        (v_tenant_id, v_student_id, 'quiz', 75, NOW() - INTERVAL '1 day')
        ON CONFLICT DO NOTHING;

        -- Student Achievements
        INSERT INTO student_achievements (tenant_id, student_id, achievement_id, earned_at) VALUES
        (v_tenant_id, v_student_id, 'ach-001', NOW() - INTERVAL '7 days')
        ON CONFLICT DO NOTHING;

        -- =============================================
        -- HEALTH RECORDS
        -- =============================================
        INSERT INTO student_health_records (
            tenant_id, student_id, blood_group, height_cm, weight_kg,
            allergies, chronic_conditions, emergency_contact_name,
            emergency_contact_phone, emergency_contact_relation
        ) VALUES (
            v_tenant_id, v_student_id, 'O+', 150.5, 45.0,
            ARRAY['Peanuts', 'Dust'], ARRAY[]::TEXT[],
            'Emergency Contact', '+1234567890', 'Parent'
        ) ON CONFLICT (student_id) DO NOTHING;
    END IF;

    -- =============================================
    -- NOTIFICATIONS
    -- =============================================
    IF v_parent_id IS NOT NULL THEN
        INSERT INTO notifications (tenant_id, user_id, type, priority, title, body, action_type, is_read) VALUES
        (v_tenant_id, v_parent_id, 'attendance', 'normal', 'Attendance Alert', 'Your child was marked absent today.', 'view_attendance', false),
        (v_tenant_id, v_parent_id, 'fee_reminder', 'high', 'Fee Due Reminder', 'School fees for January are due. Please pay by Jan 15.', 'pay_fees', false),
        (v_tenant_id, v_parent_id, 'grade_update', 'normal', 'New Grades Posted', 'Math exam results have been published.', 'view_grades', true),
        (v_tenant_id, v_parent_id, 'announcement', 'low', 'School Holiday', 'School will be closed on Republic Day.', 'view_announcement', true)
        ON CONFLICT DO NOTHING;
    END IF;

    IF v_teacher_id IS NOT NULL THEN
        INSERT INTO notifications (tenant_id, user_id, type, priority, title, body, action_type, is_read) VALUES
        (v_tenant_id, v_teacher_id, 'assignment', 'normal', 'Assignment Submitted', '5 students have submitted Math homework.', 'view_submissions', false),
        (v_tenant_id, v_teacher_id, 'ptm', 'high', 'PTM Scheduled', 'Parent-Teacher meeting is scheduled for next week.', 'view_ptm', false)
        ON CONFLICT DO NOTHING;
    END IF;

    -- =============================================
    -- QUIZZES
    -- =============================================
    IF v_teacher_id IS NOT NULL AND v_section_id IS NOT NULL AND v_subject_id IS NOT NULL THEN
        INSERT INTO quizzes (id, tenant_id, title, description, section_id, subject_id, created_by, duration_minutes, total_marks, passing_marks, shuffle_questions, show_results, status) VALUES
        ('quiz-001', v_tenant_id, 'Math Quick Quiz', 'Test your basic math skills', v_section_id, v_subject_id, v_teacher_id, 15, 20, 10, true, true, 'published'),
        ('quiz-002', v_tenant_id, 'Science Chapter 1', 'Quiz on Introduction to Science', v_section_id, v_subject_id, v_teacher_id, 30, 50, 25, false, true, 'published'),
        ('quiz-003', v_tenant_id, 'Weekly Assessment', 'Weekly class assessment', v_section_id, v_subject_id, v_teacher_id, 20, 30, 15, true, false, 'draft')
        ON CONFLICT DO NOTHING;

        -- Quiz Questions
        INSERT INTO quiz_questions (quiz_id, question_text, question_type, options, correct_answer, marks, explanation, order_index) VALUES
        ('quiz-001', 'What is 5 + 7?', 'mcq', '["10", "11", "12", "13"]', '12', 2, 'Basic addition', 1),
        ('quiz-001', 'What is 8 x 6?', 'mcq', '["42", "46", "48", "52"]', '48', 2, 'Multiplication', 2),
        ('quiz-001', '15 - 9 = ?', 'mcq', '["4", "5", "6", "7"]', '6', 2, 'Subtraction', 3),
        ('quiz-001', 'True or False: 10 / 2 = 5', 'true_false', '["True", "False"]', 'True', 2, 'Division', 4),
        ('quiz-001', 'What is the square root of 16?', 'short_answer', NULL, '4', 2, 'Square root', 5)
        ON CONFLICT DO NOTHING;

        -- Question Bank
        INSERT INTO question_bank (tenant_id, subject_id, question_text, question_type, options, correct_answer, marks, difficulty, tags, created_by) VALUES
        (v_tenant_id, v_subject_id, 'Define photosynthesis', 'short_answer', NULL, 'Process by which plants make food using sunlight', 5, 'medium', ARRAY['biology', 'plants'], v_teacher_id),
        (v_tenant_id, v_subject_id, 'What is H2O?', 'mcq', '["Hydrogen", "Oxygen", "Water", "Helium"]', 'Water', 2, 'easy', ARRAY['chemistry', 'basics'], v_teacher_id)
        ON CONFLICT DO NOTHING;
    END IF;

    -- =============================================
    -- PTM SCHEDULES
    -- =============================================
    IF v_teacher_id IS NOT NULL AND v_academic_year_id IS NOT NULL THEN
        INSERT INTO ptm_schedules (id, tenant_id, title, description, academic_year_id, date, start_time, end_time, slot_duration_minutes, venue, is_active) VALUES
        ('ptm-001', v_tenant_id, 'Mid-Term PTM', 'Parent-Teacher meeting for mid-term review', v_academic_year_id, CURRENT_DATE + INTERVAL '7 days', '09:00', '17:00', 15, 'School Auditorium', true),
        ('ptm-002', v_tenant_id, 'Final Term PTM', 'End of year parent-teacher conference', v_academic_year_id, CURRENT_DATE + INTERVAL '30 days', '10:00', '16:00', 20, 'Classrooms', true)
        ON CONFLICT DO NOTHING;

        -- Teacher Availability
        INSERT INTO ptm_teacher_availability (ptm_schedule_id, teacher_id, is_available, room_number) VALUES
        ('ptm-001', v_teacher_id, true, 'Room 101'),
        ('ptm-002', v_teacher_id, true, 'Room 101')
        ON CONFLICT DO NOTHING;
    END IF;

    -- =============================================
    -- STUDY RESOURCES
    -- =============================================
    IF v_teacher_id IS NOT NULL AND v_subject_id IS NOT NULL THEN
        INSERT INTO study_resources (tenant_id, title, description, resource_type, subject_id, tags, uploaded_by, view_count, download_count) VALUES
        (v_tenant_id, 'Math Formulas Cheat Sheet', 'All important formulas for quick reference', 'document', v_subject_id, ARRAY['math', 'formulas', 'reference'], v_teacher_id, 150, 85),
        (v_tenant_id, 'Science Lab Video Tutorial', 'How to conduct basic science experiments', 'video', v_subject_id, ARRAY['science', 'lab', 'tutorial'], v_teacher_id, 200, 50),
        (v_tenant_id, 'English Grammar Guide', 'Complete guide to English grammar rules', 'document', v_subject_id, ARRAY['english', 'grammar'], v_teacher_id, 120, 70)
        ON CONFLICT DO NOTHING;
    END IF;

    -- =============================================
    -- EMERGENCY CONTACTS
    -- =============================================
    INSERT INTO emergency_contacts (tenant_id, name, phone, email, contact_type, is_primary, notes) VALUES
    (v_tenant_id, 'Local Police Station', '100', 'police@local.gov', 'police', true, '24/7 Emergency'),
    (v_tenant_id, 'City Hospital', '108', 'emergency@hospital.com', 'hospital', true, 'Nearest hospital'),
    (v_tenant_id, 'Fire Department', '101', 'fire@local.gov', 'fire', true, 'Fire emergency'),
    (v_tenant_id, 'School Security', '+1234567899', 'security@school.edu', 'security', true, 'On-campus security')
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Seed data for new features inserted successfully!';
END $$;

-- Verify the data
SELECT 'achievements' as table_name, COUNT(*) as count FROM achievements
UNION ALL SELECT 'student_points', COUNT(*) FROM student_points
UNION ALL SELECT 'notifications', COUNT(*) FROM notifications
UNION ALL SELECT 'quizzes', COUNT(*) FROM quizzes
UNION ALL SELECT 'quiz_questions', COUNT(*) FROM quiz_questions
UNION ALL SELECT 'ptm_schedules', COUNT(*) FROM ptm_schedules
UNION ALL SELECT 'study_resources', COUNT(*) FROM study_resources
UNION ALL SELECT 'emergency_contacts', COUNT(*) FROM emergency_contacts
UNION ALL SELECT 'student_health_records', COUNT(*) FROM student_health_records;
