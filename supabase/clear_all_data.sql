-- ⚠️  DANGER: DESTRUCTIVE SCRIPT — DEVELOPMENT ONLY
-- This script deletes ALL data from ALL tables.
-- DO NOT RUN IN PRODUCTION.
--
-- CLEAR ALL DUMMY DATA AND RESET TO CLEAN STATE
-- This script deletes all demo/test users, students, parents, and related data
-- Keeping schema intact, only removing data

DO $$
BEGIN
  -- Safety guard: abort if this looks like a production environment
  IF current_setting('app.settings.app_env', true) = 'production' THEN
    RAISE EXCEPTION 'ABORTED: Cannot run clear_all_data.sql in production environment';
  END IF;
END $$;

BEGIN;

-- Disable foreign key checks temporarily
ALTER TABLE IF EXISTS student_parents DISABLE TRIGGER ALL;
ALTER TABLE IF EXISTS student_enrollments DISABLE TRIGGER ALL;
ALTER TABLE IF EXISTS students DISABLE TRIGGER ALL;
ALTER TABLE IF EXISTS parents DISABLE TRIGGER ALL;
ALTER TABLE IF EXISTS staff DISABLE TRIGGER ALL;
ALTER TABLE IF EXISTS user_roles DISABLE TRIGGER ALL;
ALTER TABLE IF EXISTS users DISABLE TRIGGER ALL;

-- Delete in dependency order
DELETE FROM student_parents;
DELETE FROM student_enrollments;
DELETE FROM submissions;
DELETE FROM assignments;
DELETE FROM marks;
DELETE FROM exam_subjects;
DELETE FROM exams;
DELETE FROM subject_allocations;
DELETE FROM class_subjects;
DELETE FROM topics_coverage;
DELETE FROM syllabus_topics;
DELETE FROM lesson_plans;
DELETE FROM section_timetables;
DELETE FROM sections;
DELETE FROM classes;
DELETE FROM invoices;
DELETE FROM fee_structures;
DELETE FROM fee_heads;
DELETE FROM messages;
DELETE FROM threads;
DELETE FROM notifications;
DELETE FROM library_issue_returns;
DELETE FROM book_requests;
DELETE FROM library_books;
DELETE FROM hostel_allocations;
DELETE FROM hostel_rooms;
DELETE FROM hostels;
DELETE FROM transport_routes;
DELETE FROM bus_routes;
DELETE FROM vehicles;
DELETE FROM trips;
DELETE FROM attendance_records;
DELETE FROM canteen_orders;
DELETE FROM canteen_menu_items;
DELETE FROM canteen_menu;
DELETE FROM wallet_transactions;
DELETE FROM wallets;
DELETE FROM documents;
DELETE FROM certificates;
DELETE FROM achievements;
DELETE FROM event_attendees;
DELETE FROM school_events;
DELETE FROM announcements;
DELETE FROM visitors_log;
DELETE FROM students CASCADE;
DELETE FROM parents CASCADE;
DELETE FROM staff CASCADE;
DELETE FROM teacher_assignments;
DELETE FROM subjects;
DELETE FROM terms;
DELETE FROM academic_years;
DELETE FROM user_roles;
DELETE FROM users;

-- Re-enable triggers
ALTER TABLE IF EXISTS student_parents ENABLE TRIGGER ALL;
ALTER TABLE IF EXISTS student_enrollments ENABLE TRIGGER ALL;
ALTER TABLE IF EXISTS students ENABLE TRIGGER ALL;
ALTER TABLE IF EXISTS parents ENABLE TRIGGER ALL;
ALTER TABLE IF EXISTS staff ENABLE TRIGGER ALL;
ALTER TABLE IF EXISTS user_roles ENABLE TRIGGER ALL;
ALTER TABLE IF EXISTS users ENABLE TRIGGER ALL;

-- Reset sequences to start from 1
ALTER SEQUENCE IF EXISTS users_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS students_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS parents_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS staff_id_seq RESTART WITH 1;

COMMIT;

-- Verify data is cleared
SELECT 'Users count:' as check_item, COUNT(*) FROM users
UNION ALL
SELECT 'Students count:', COUNT(*) FROM students
UNION ALL
SELECT 'Parents count:', COUNT(*) FROM parents
UNION ALL
SELECT 'Staff count:', COUNT(*) FROM staff;
