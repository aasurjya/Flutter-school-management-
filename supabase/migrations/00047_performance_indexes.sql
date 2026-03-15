-- Migration: 00047_performance_indexes
-- Purpose: Add missing composite and partial indexes identified as performance gaps
--          in CLAUDE.md Known Issues (student name search, message sender, invoice
--          due_date, attendance date, visitor logs today).
--
-- Skipped — already covered by earlier migrations:
--   idx_students_name       → 00029 already creates (tenant_id, first_name, last_name)
--   idx_messages_sender     → 00029 already creates (sender_id)
--   idx_user_roles_user     → 00001 already creates (user_id)
--   idx_visitor_logs_tenant → 00024 already creates (tenant_id) and
--                             idx_visitor_logs_checkin covers (tenant_id, check_in_time DESC)
--
-- Renamed — earlier migrations used the same index name with different columns,
-- so IF NOT EXISTS on the old name would silently skip the better index:
--   idx_messages_thread          → idx_messages_thread_ordered   (adds created_at DESC)
--   idx_invoices_due_date        → idx_invoices_due_date_partial  (partial WHERE + drops tenant_id prefix)
--   idx_invoices_student         → idx_invoices_student_status   (adds status column)
--   idx_attendance_date          → idx_attendance_date_section   (adds section_id column)
--   idx_attendance_student       → idx_attendance_student_date2  (00029 already has a 3-col variant;
--                                                                  this two-col form is lighter for
--                                                                  student-scoped date range queries)
--   idx_user_roles_tenant        → idx_user_roles_tenant_role    (adds role column)
--   idx_enrollments_section      → idx_enrollments_section_year  (adds academic_year_id)

-- ----------------------------------------------------------------------------
-- students
-- ----------------------------------------------------------------------------

-- Composite filter used in admin lists: "show active students for this school"
CREATE INDEX IF NOT EXISTS idx_students_tenant_active
    ON students (tenant_id, is_active);

-- ----------------------------------------------------------------------------
-- messages
-- ----------------------------------------------------------------------------

-- Fetch the latest N messages in a thread (ORDER BY created_at DESC) without a
-- separate sort step.  The existing idx_messages_thread covers (thread_id) alone.
CREATE INDEX IF NOT EXISTS idx_messages_thread_ordered
    ON messages (thread_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- invoices
-- ----------------------------------------------------------------------------

-- Overdue-invoice queries filter by status != 'paid' and sort/filter by due_date.
-- Partial index keeps it small (only unpaid rows) and avoids reading paid invoices.
-- The existing idx_invoices_due_date covers (tenant_id, due_date) without the
-- partial predicate, so this is additive, not duplicate.
CREATE INDEX IF NOT EXISTS idx_invoices_due_date_partial
    ON invoices (due_date)
    WHERE status != 'paid';

-- (student_id, status) composite lets the fees screen load a student's unpaid
-- invoices in a single index scan.  The existing idx_invoices_student covers
-- (student_id) alone.
CREATE INDEX IF NOT EXISTS idx_invoices_student_status
    ON invoices (student_id, status);

-- Tenant-level status aggregation (e.g. count overdue, count pending) used in
-- the admin finance dashboard.
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_status
    ON invoices (tenant_id, status);

-- ----------------------------------------------------------------------------
-- attendance
-- ----------------------------------------------------------------------------

-- Mark-attendance screen queries by (date, section_id) to load the full class
-- roster for a day.  The existing idx_attendance_date covers date alone;
-- idx_attendance_section_date covers (section_id, date) — this composite puts
-- date first, matching the WHERE date = $1 AND section_id = $2 query shape.
CREATE INDEX IF NOT EXISTS idx_attendance_date_section
    ON attendance (date, section_id);

-- Student attendance history: WHERE student_id = $1 ORDER BY date DESC.
-- The existing idx_attendance_student covers (student_id) alone; 00029's variant
-- is a 3-col index (tenant_id, student_id, date).  This two-column form is
-- cheaper for student-portal queries that already know the student but not the tenant.
CREATE INDEX IF NOT EXISTS idx_attendance_student_date2
    ON attendance (student_id, date DESC);

-- ----------------------------------------------------------------------------
-- visitor_logs
-- ----------------------------------------------------------------------------

-- Today's visitor list: WHERE check_in_time >= today.  The existing
-- idx_visitor_logs_date covers (tenant_id, check_in_time) without the
-- tenant_id prefix being optional; this single-column index serves queries
-- from the receptionist portal where RLS already filters by tenant.
CREATE INDEX IF NOT EXISTS idx_visitor_logs_check_in
    ON visitor_logs (check_in_time);

-- ----------------------------------------------------------------------------
-- user_roles
-- ----------------------------------------------------------------------------

-- Role-lookup queries: "does this user have role X in tenant Y?"
-- The existing idx_user_roles_tenant covers (tenant_id) alone.  Adding role
-- turns it into a covering lookup for the has_role() helper function used in
-- every RLS policy.
CREATE INDEX IF NOT EXISTS idx_user_roles_tenant_role
    ON user_roles (tenant_id, role);

-- ----------------------------------------------------------------------------
-- student_enrollments
-- ----------------------------------------------------------------------------

-- Load a student's current enrollment: WHERE student_id = $1 AND status = 'active'
CREATE INDEX IF NOT EXISTS idx_enrollments_student
    ON student_enrollments (student_id, status);

-- Load a section's roster for a given academic year (timetable, mark-attendance)
-- The existing idx_student_enrollments_section covers (section_id) alone.
CREATE INDEX IF NOT EXISTS idx_enrollments_section_year
    ON student_enrollments (section_id, academic_year_id);
