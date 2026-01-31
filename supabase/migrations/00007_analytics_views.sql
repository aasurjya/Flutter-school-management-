-- =============================================
-- Analytics Views, Functions & Improvements
-- Migration 00007
-- =============================================

-- =============================================
-- 1. ADD MISSING RLS POLICIES
-- =============================================

-- Users can view their own roles
CREATE POLICY "Users view own roles"
ON user_roles FOR SELECT
USING (user_id = auth.uid() OR tenant_id = public.tenant_id());

-- Admins manage roles in their tenant
CREATE POLICY "Admins manage user roles"
ON user_roles FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- View teacher assignments
CREATE POLICY "View teacher assignments"
ON teacher_assignments FOR SELECT
USING (tenant_id = public.tenant_id());

-- Admins manage teacher assignments
CREATE POLICY "Admins manage teacher assignments"
ON teacher_assignments FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- View class subjects
CREATE POLICY "View class subjects"
ON class_subjects FOR SELECT
USING (tenant_id = public.tenant_id());

-- Admins manage class subjects
CREATE POLICY "Admins manage class subjects"
ON class_subjects FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- View student enrollments
CREATE POLICY "View student enrollments"
ON student_enrollments FOR SELECT
USING (tenant_id = public.tenant_id());

-- Admins manage student enrollments
CREATE POLICY "Admins manage student enrollments"
ON student_enrollments FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- View exams
CREATE POLICY "View exams"
ON exams FOR SELECT
USING (tenant_id = public.tenant_id());

-- Admins manage exams
CREATE POLICY "Admins manage exams"
ON exams FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- View exam subjects
CREATE POLICY "View exam subjects"
ON exam_subjects FOR SELECT
USING (tenant_id = public.tenant_id());

-- Teachers can manage exam subjects for their assignments
CREATE POLICY "Teachers manage exam subjects"
ON exam_subjects FOR ALL
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR public.has_role('teacher')
  )
);

-- View assignments
CREATE POLICY "View assignments"
ON assignments FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('teacher') OR
    -- Students see published assignments for their section
    (status = 'published' AND section_id IN (
      SELECT se.section_id FROM student_enrollments se
      JOIN students s ON se.student_id = s.id
      WHERE s.user_id = auth.uid()
    )) OR
    -- Parents see children's assignments
    (status = 'published' AND section_id IN (
      SELECT se.section_id FROM student_enrollments se
      JOIN student_parents sp ON se.student_id = sp.student_id
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    ))
  )
);

-- Teachers manage their assignments
CREATE POLICY "Teachers manage assignments"
ON assignments FOR ALL
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    (public.has_role('teacher') AND teacher_id = auth.uid())
  )
);

-- View submissions
CREATE POLICY "View submissions"
ON submissions FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    -- Teachers see submissions for their assignments
    assignment_id IN (SELECT id FROM assignments WHERE teacher_id = auth.uid()) OR
    -- Students see own submissions
    student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) OR
    -- Parents see children's submissions
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

-- Students create/update their submissions
CREATE POLICY "Students manage submissions"
ON submissions FOR INSERT
WITH CHECK (
  tenant_id = public.tenant_id() AND
  student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
);

CREATE POLICY "Students update submissions"
ON submissions FOR UPDATE
USING (
  tenant_id = public.tenant_id() AND
  student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) AND
  status IN ('pending', 'submitted')
);

-- Teachers grade submissions
CREATE POLICY "Teachers grade submissions"
ON submissions FOR UPDATE
USING (
  tenant_id = public.tenant_id() AND
  assignment_id IN (SELECT id FROM assignments WHERE teacher_id = auth.uid())
);

-- View timetables
CREATE POLICY "View timetables"
ON timetables FOR SELECT
USING (tenant_id = public.tenant_id());

-- Admins manage timetables
CREATE POLICY "Admins manage timetables"
ON timetables FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- View timetable slots
CREATE POLICY "View timetable slots"
ON timetable_slots FOR SELECT
USING (tenant_id = public.tenant_id());

-- Admins manage timetable slots
CREATE POLICY "Admins manage timetable slots"
ON timetable_slots FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- View parents
CREATE POLICY "View parents"
ON parents FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('teacher') OR
    user_id = auth.uid()
  )
);

-- Admins manage parents
CREATE POLICY "Admins manage parents"
ON parents FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- View student_parents
CREATE POLICY "View student parents"
ON student_parents FOR SELECT
USING (
  student_id IN (SELECT id FROM students WHERE tenant_id = public.tenant_id()) AND (
    public.is_admin() OR
    public.has_role('teacher') OR
    parent_id IN (SELECT id FROM parents WHERE user_id = auth.uid())
  )
);

-- Admins manage student_parents
CREATE POLICY "Admins manage student parents"
ON student_parents FOR ALL
USING (
  student_id IN (SELECT id FROM students WHERE tenant_id = public.tenant_id()) AND
  public.is_admin()
);

-- View staff
CREATE POLICY "View staff"
ON staff FOR SELECT
USING (tenant_id = public.tenant_id());

-- Admins manage staff
CREATE POLICY "Admins manage staff"
ON staff FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- View grade scales
CREATE POLICY "View grade scales"
ON grade_scales FOR SELECT
USING (tenant_id = public.tenant_id());

-- Admins manage grade scales
CREATE POLICY "Admins manage grade scales"
ON grade_scales FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- View grade scale items
CREATE POLICY "View grade scale items"
ON grade_scale_items FOR SELECT
USING (
  grade_scale_id IN (SELECT id FROM grade_scales WHERE tenant_id = public.tenant_id())
);

-- Admins manage grade scale items
CREATE POLICY "Admins manage grade scale items"
ON grade_scale_items FOR ALL
USING (
  grade_scale_id IN (SELECT id FROM grade_scales WHERE tenant_id = public.tenant_id()) AND
  public.is_admin()
);

-- View exam statistics
CREATE POLICY "View exam statistics"
ON exam_statistics FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('teacher') OR
    student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

-- Admins/teachers manage exam statistics
CREATE POLICY "Staff manage exam statistics"
ON exam_statistics FOR ALL
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR public.has_role('teacher')
  )
);

-- View period attendance
CREATE POLICY "View period attendance"
ON period_attendance FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('teacher') OR
    student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

-- Teachers manage period attendance
CREATE POLICY "Teachers manage period attendance"
ON period_attendance FOR ALL
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR public.has_role('teacher')
  )
);

-- Fee heads policies
CREATE POLICY "View fee heads"
ON fee_heads FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage fee heads"
ON fee_heads FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('accountant')));

-- Fee structures policies
CREATE POLICY "View fee structures"
ON fee_structures FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage fee structures"
ON fee_structures FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('accountant')));

-- Invoice items policies
CREATE POLICY "View invoice items"
ON invoice_items FOR SELECT
USING (
  invoice_id IN (SELECT id FROM invoices WHERE tenant_id = public.tenant_id())
);

CREATE POLICY "Admins manage invoice items"
ON invoice_items FOR ALL
USING (
  invoice_id IN (SELECT id FROM invoices WHERE tenant_id = public.tenant_id()) AND
  (public.is_admin() OR public.has_role('accountant'))
);

-- Payments policies
CREATE POLICY "View payments"
ON payments FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('accountant') OR
    invoice_id IN (
      SELECT id FROM invoices WHERE student_id IN (
        SELECT id FROM students WHERE user_id = auth.uid()
      )
    ) OR
    invoice_id IN (
      SELECT id FROM invoices WHERE student_id IN (
        SELECT sp.student_id FROM student_parents sp
        JOIN parents p ON sp.parent_id = p.id
        WHERE p.user_id = auth.uid()
      )
    )
  )
);

CREATE POLICY "Process payments"
ON payments FOR INSERT
WITH CHECK (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('accountant') OR
    -- Parents can make payments for their children
    invoice_id IN (
      SELECT id FROM invoices WHERE student_id IN (
        SELECT sp.student_id FROM student_parents sp
        JOIN parents p ON sp.parent_id = p.id
        WHERE p.user_id = auth.uid()
      )
    )
  )
);

-- Thread participants policy
CREATE POLICY "View thread participants"
ON thread_participants FOR SELECT
USING (
  thread_id IN (SELECT id FROM threads WHERE tenant_id = public.tenant_id()) AND (
    user_id = auth.uid() OR
    thread_id IN (SELECT thread_id FROM thread_participants WHERE user_id = auth.uid())
  )
);

CREATE POLICY "Manage thread participants"
ON thread_participants FOR ALL
USING (
  thread_id IN (
    SELECT id FROM threads WHERE tenant_id = public.tenant_id() AND created_by = auth.uid()
  )
);

-- Calendar events policies
CREATE POLICY "View calendar events"
ON calendar_events FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage calendar events"
ON calendar_events FOR ALL
USING (tenant_id = public.tenant_id() AND public.is_admin());

-- Library books policies
CREATE POLICY "View library books"
ON library_books FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Librarians manage books"
ON library_books FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('librarian')));

-- Book issues policies
CREATE POLICY "View book issues"
ON book_issues FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('librarian') OR
    student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    ) OR
    staff_id IN (SELECT id FROM staff WHERE user_id = auth.uid())
  )
);

CREATE POLICY "Librarians manage book issues"
ON book_issues FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('librarian')));

-- Wallet transactions policies
CREATE POLICY "View wallet transactions"
ON wallet_transactions FOR SELECT
USING (
  wallet_id IN (SELECT id FROM wallets WHERE tenant_id = public.tenant_id()) AND (
    public.is_admin() OR
    wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid()) OR
    wallet_id IN (
      SELECT id FROM wallets WHERE student_id IN (
        SELECT id FROM students WHERE user_id = auth.uid()
      )
    ) OR
    wallet_id IN (
      SELECT id FROM wallets WHERE student_id IN (
        SELECT sp.student_id FROM student_parents sp
        JOIN parents p ON sp.parent_id = p.id
        WHERE p.user_id = auth.uid()
      )
    )
  )
);

-- Canteen orders policies
CREATE POLICY "View canteen orders"
ON canteen_orders FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('canteen_staff') OR
    wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid()) OR
    wallet_id IN (
      SELECT id FROM wallets WHERE student_id IN (
        SELECT id FROM students WHERE user_id = auth.uid()
      )
    ) OR
    wallet_id IN (
      SELECT id FROM wallets WHERE student_id IN (
        SELECT sp.student_id FROM student_parents sp
        JOIN parents p ON sp.parent_id = p.id
        WHERE p.user_id = auth.uid()
      )
    )
  )
);

CREATE POLICY "Create canteen orders"
ON canteen_orders FOR INSERT
WITH CHECK (
  tenant_id = public.tenant_id() AND (
    wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid()) OR
    wallet_id IN (
      SELECT id FROM wallets WHERE student_id IN (
        SELECT id FROM students WHERE user_id = auth.uid()
      )
    )
  )
);

CREATE POLICY "Staff manage canteen orders"
ON canteen_orders FOR UPDATE
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR public.has_role('canteen_staff')
  )
);

-- Canteen order items policies
CREATE POLICY "View canteen order items"
ON canteen_order_items FOR SELECT
USING (
  order_id IN (SELECT id FROM canteen_orders WHERE tenant_id = public.tenant_id())
);

CREATE POLICY "Create canteen order items"
ON canteen_order_items FOR INSERT
WITH CHECK (
  order_id IN (
    SELECT id FROM canteen_orders WHERE tenant_id = public.tenant_id() AND (
      wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid()) OR
      wallet_id IN (
        SELECT id FROM wallets WHERE student_id IN (
          SELECT id FROM students WHERE user_id = auth.uid()
        )
      )
    )
  )
);

-- Transport policies
CREATE POLICY "View transport routes"
ON transport_routes FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage transport routes"
ON transport_routes FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('transport_manager')));

CREATE POLICY "View transport stops"
ON transport_stops FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage transport stops"
ON transport_stops FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('transport_manager')));

CREATE POLICY "View student transport"
ON student_transport FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('transport_manager') OR
    student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

CREATE POLICY "Admins manage student transport"
ON student_transport FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('transport_manager')));

-- Hostel policies
CREATE POLICY "View hostels"
ON hostels FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage hostels"
ON hostels FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('hostel_warden')));

CREATE POLICY "View hostel rooms"
ON hostel_rooms FOR SELECT
USING (tenant_id = public.tenant_id());

CREATE POLICY "Admins manage hostel rooms"
ON hostel_rooms FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('hostel_warden')));

CREATE POLICY "View room allocations"
ON room_allocations FOR SELECT
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    public.has_role('hostel_warden') OR
    student_id IN (SELECT id FROM students WHERE user_id = auth.uid()) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

CREATE POLICY "Admins manage room allocations"
ON room_allocations FOR ALL
USING (tenant_id = public.tenant_id() AND (public.is_admin() OR public.has_role('hostel_warden')));

-- Wallet management
CREATE POLICY "Manage own wallet"
ON wallets FOR UPDATE
USING (
  tenant_id = public.tenant_id() AND (
    public.is_admin() OR
    user_id = auth.uid() OR
    -- Parents can manage children's wallets
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = auth.uid()
    )
  )
);

-- =============================================
-- 2. PARENT IMPROVEMENTS
-- =============================================

-- Add daily spending limit and notification preferences
ALTER TABLE student_parents 
ADD COLUMN IF NOT EXISTS daily_spending_limit DECIMAL(8,2) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS notify_attendance BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS notify_fees BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS notify_results BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS notify_assignments BOOLEAN DEFAULT true;

-- =============================================
-- 3. ANALYTICS VIEWS
-- =============================================

-- Materialized view for student exam performance
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_student_performance AS
SELECT 
  m.tenant_id,
  m.student_id,
  s.first_name || ' ' || COALESCE(s.last_name, '') AS student_name,
  s.admission_number,
  se.section_id,
  sec.name AS section_name,
  c.id AS class_id,
  c.name AS class_name,
  e.id AS exam_id,
  e.name AS exam_name,
  e.exam_type,
  es.subject_id,
  sub.name AS subject_name,
  sub.code AS subject_code,
  m.marks_obtained,
  es.max_marks,
  es.passing_marks,
  CASE WHEN es.max_marks > 0 THEN ROUND((m.marks_obtained / es.max_marks) * 100, 2) ELSE 0 END AS percentage,
  CASE WHEN m.marks_obtained >= es.passing_marks THEN true ELSE false END AS is_passed,
  m.is_absent,
  e.academic_year_id,
  e.term_id
FROM marks m
JOIN exam_subjects es ON m.exam_subject_id = es.id
JOIN exams e ON es.exam_id = e.id
JOIN students s ON m.student_id = s.id
JOIN student_enrollments se ON s.id = se.student_id 
  AND se.academic_year_id = e.academic_year_id
JOIN sections sec ON se.section_id = sec.id
JOIN classes c ON sec.class_id = c.id
JOIN subjects sub ON es.subject_id = sub.id;

-- Create indexes for the materialized view
CREATE INDEX IF NOT EXISTS idx_mv_student_perf_tenant ON mv_student_performance(tenant_id);
CREATE INDEX IF NOT EXISTS idx_mv_student_perf_student ON mv_student_performance(student_id);
CREATE INDEX IF NOT EXISTS idx_mv_student_perf_exam ON mv_student_performance(exam_id);
CREATE INDEX IF NOT EXISTS idx_mv_student_perf_section ON mv_student_performance(section_id);
CREATE INDEX IF NOT EXISTS idx_mv_student_perf_subject ON mv_student_performance(subject_id);

-- View for class statistics per exam/subject
CREATE OR REPLACE VIEW v_class_exam_stats AS
SELECT 
  tenant_id,
  exam_id,
  exam_name,
  exam_type,
  section_id,
  section_name,
  class_id,
  class_name,
  subject_id,
  subject_name,
  academic_year_id,
  COUNT(*) AS total_students,
  COUNT(*) FILTER (WHERE NOT is_absent) AS students_appeared,
  ROUND(AVG(percentage) FILTER (WHERE NOT is_absent), 2) AS class_average,
  MAX(percentage) FILTER (WHERE NOT is_absent) AS highest_percentage,
  MIN(percentage) FILTER (WHERE NOT is_absent) AS lowest_percentage,
  COUNT(*) FILTER (WHERE is_passed AND NOT is_absent) AS passed_count,
  COUNT(*) FILTER (WHERE NOT is_passed AND NOT is_absent) AS failed_count,
  COUNT(*) FILTER (WHERE is_absent) AS absent_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE NOT is_absent) > 0 
    THEN ROUND((COUNT(*) FILTER (WHERE is_passed AND NOT is_absent)::NUMERIC / 
         COUNT(*) FILTER (WHERE NOT is_absent)) * 100, 2)
    ELSE 0 
  END AS pass_percentage
FROM mv_student_performance
GROUP BY tenant_id, exam_id, exam_name, exam_type, section_id, section_name, 
         class_id, class_name, subject_id, subject_name, academic_year_id;

-- View for student rank in class
CREATE OR REPLACE VIEW v_student_ranks AS
SELECT 
  sp.*,
  RANK() OVER (
    PARTITION BY sp.tenant_id, sp.exam_id, sp.section_id, sp.subject_id 
    ORDER BY sp.percentage DESC
  ) AS subject_rank,
  (
    SELECT COUNT(*) FROM mv_student_performance mp2 
    WHERE mp2.exam_id = sp.exam_id 
      AND mp2.section_id = sp.section_id 
      AND mp2.subject_id = sp.subject_id
      AND NOT mp2.is_absent
  ) AS total_in_subject
FROM mv_student_performance sp
WHERE NOT sp.is_absent;

-- View for overall student rank (across all subjects in an exam)
CREATE OR REPLACE VIEW v_student_overall_ranks AS
SELECT 
  tenant_id,
  student_id,
  student_name,
  admission_number,
  section_id,
  section_name,
  class_id,
  class_name,
  exam_id,
  exam_name,
  exam_type,
  academic_year_id,
  SUM(marks_obtained) AS total_obtained,
  SUM(max_marks) AS total_max_marks,
  ROUND((SUM(marks_obtained) / NULLIF(SUM(max_marks), 0)) * 100, 2) AS overall_percentage,
  COUNT(*) AS subjects_count,
  COUNT(*) FILTER (WHERE is_passed) AS subjects_passed,
  RANK() OVER (
    PARTITION BY tenant_id, exam_id, section_id 
    ORDER BY SUM(marks_obtained) DESC
  ) AS class_rank
FROM mv_student_performance
WHERE NOT is_absent
GROUP BY tenant_id, student_id, student_name, admission_number, section_id, section_name,
         class_id, class_name, exam_id, exam_name, exam_type, academic_year_id;

-- Attendance summary view
CREATE OR REPLACE VIEW v_attendance_summary AS
SELECT 
  a.tenant_id,
  a.student_id,
  s.first_name || ' ' || COALESCE(s.last_name, '') AS student_name,
  s.admission_number,
  a.section_id,
  sec.name AS section_name,
  c.name AS class_name,
  DATE_TRUNC('month', a.date)::DATE AS month,
  EXTRACT(YEAR FROM a.date) AS year,
  COUNT(*) AS total_days,
  COUNT(*) FILTER (WHERE a.status = 'present') AS present_days,
  COUNT(*) FILTER (WHERE a.status = 'absent') AS absent_days,
  COUNT(*) FILTER (WHERE a.status = 'late') AS late_days,
  COUNT(*) FILTER (WHERE a.status = 'half_day') AS half_days,
  COUNT(*) FILTER (WHERE a.status = 'excused') AS excused_days,
  ROUND(
    COUNT(*) FILTER (WHERE a.status IN ('present', 'late', 'excused'))::NUMERIC 
    / NULLIF(COUNT(*), 0) * 100, 2
  ) AS attendance_percentage
FROM attendance a
JOIN students s ON a.student_id = s.id
JOIN student_enrollments se ON s.id = se.student_id
JOIN sections sec ON se.section_id = sec.id
JOIN classes c ON sec.class_id = c.id
GROUP BY a.tenant_id, a.student_id, s.first_name, s.last_name, s.admission_number,
         a.section_id, sec.name, c.name, DATE_TRUNC('month', a.date), EXTRACT(YEAR FROM a.date);

-- Daily attendance summary for a section
CREATE OR REPLACE VIEW v_section_daily_attendance AS
SELECT 
  a.tenant_id,
  a.section_id,
  sec.name AS section_name,
  c.name AS class_name,
  a.date,
  COUNT(*) AS total_students,
  COUNT(*) FILTER (WHERE a.status = 'present') AS present_count,
  COUNT(*) FILTER (WHERE a.status = 'absent') AS absent_count,
  COUNT(*) FILTER (WHERE a.status = 'late') AS late_count,
  COUNT(*) FILTER (WHERE a.status = 'excused') AS excused_count,
  ROUND(
    COUNT(*) FILTER (WHERE a.status IN ('present', 'late', 'excused'))::NUMERIC 
    / NULLIF(COUNT(*), 0) * 100, 2
  ) AS attendance_percentage
FROM attendance a
JOIN sections sec ON a.section_id = sec.id
JOIN classes c ON sec.class_id = c.id
GROUP BY a.tenant_id, a.section_id, sec.name, c.name, a.date;

-- Fee summary view
CREATE OR REPLACE VIEW v_fee_summary AS
SELECT 
  i.tenant_id,
  i.student_id,
  s.first_name || ' ' || COALESCE(s.last_name, '') AS student_name,
  s.admission_number,
  se.section_id,
  sec.name AS section_name,
  c.name AS class_name,
  i.academic_year_id,
  ay.name AS academic_year_name,
  SUM(i.total_amount) AS total_fee,
  SUM(i.discount_amount) AS total_discount,
  SUM(i.paid_amount) AS total_paid,
  SUM(i.total_amount - i.discount_amount - i.paid_amount) AS total_pending,
  COUNT(*) AS total_invoices,
  COUNT(*) FILTER (WHERE i.status = 'paid') AS paid_invoices,
  COUNT(*) FILTER (WHERE i.status = 'pending') AS pending_invoices,
  COUNT(*) FILTER (WHERE i.status = 'overdue') AS overdue_invoices
FROM invoices i
JOIN students s ON i.student_id = s.id
JOIN student_enrollments se ON s.id = se.student_id AND se.academic_year_id = i.academic_year_id
JOIN sections sec ON se.section_id = sec.id
JOIN classes c ON sec.class_id = c.id
JOIN academic_years ay ON i.academic_year_id = ay.id
GROUP BY i.tenant_id, i.student_id, s.first_name, s.last_name, s.admission_number,
         se.section_id, sec.name, c.name, i.academic_year_id, ay.name;

-- Assignment summary view
CREATE OR REPLACE VIEW v_assignment_summary AS
SELECT 
  a.tenant_id,
  a.id AS assignment_id,
  a.title,
  a.section_id,
  sec.name AS section_name,
  c.name AS class_name,
  a.subject_id,
  sub.name AS subject_name,
  a.teacher_id,
  u.full_name AS teacher_name,
  a.due_date,
  a.max_marks,
  a.status,
  COUNT(DISTINCT se.student_id) AS total_students,
  COUNT(DISTINCT s.id) AS submitted_count,
  COUNT(DISTINCT s.id) FILTER (WHERE s.status = 'graded') AS graded_count,
  COUNT(DISTINCT s.id) FILTER (WHERE s.status = 'late') AS late_count,
  CASE WHEN a.due_date < NOW() THEN true ELSE false END AS is_past_due
FROM assignments a
JOIN sections sec ON a.section_id = sec.id
JOIN classes c ON sec.class_id = c.id
JOIN subjects sub ON a.subject_id = sub.id
JOIN users u ON a.teacher_id = u.id
LEFT JOIN student_enrollments se ON se.section_id = a.section_id
LEFT JOIN submissions s ON s.assignment_id = a.id
GROUP BY a.tenant_id, a.id, a.title, a.section_id, sec.name, c.name,
         a.subject_id, sub.name, a.teacher_id, u.full_name, a.due_date, a.max_marks, a.status;

-- =============================================
-- 4. HELPER FUNCTIONS
-- =============================================

-- Function to promote students to next academic year
CREATE OR REPLACE FUNCTION promote_students(
  p_tenant_id UUID,
  p_from_year_id UUID,
  p_to_year_id UUID,
  p_section_mapping JSONB
) RETURNS TABLE(promoted INT, failed INT, skipped INT) AS $$
DECLARE
  v_promoted INT := 0;
  v_failed INT := 0;
  v_skipped INT := 0;
  v_enrollment RECORD;
  v_new_section_id UUID;
BEGIN
  FOR v_enrollment IN
    SELECT se.* FROM student_enrollments se
    WHERE se.tenant_id = p_tenant_id
      AND se.academic_year_id = p_from_year_id
      AND se.status = 'active'
  LOOP
    -- Get new section ID from mapping
    v_new_section_id := (p_section_mapping->>v_enrollment.section_id::text)::UUID;
    
    IF v_new_section_id IS NULL THEN
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;
    
    BEGIN
      -- Create new enrollment in new year
      INSERT INTO student_enrollments (
        tenant_id, student_id, section_id, academic_year_id, 
        roll_number, status
      ) VALUES (
        p_tenant_id,
        v_enrollment.student_id,
        v_new_section_id,
        p_to_year_id,
        v_enrollment.roll_number,
        'active'
      );
      
      -- Mark old enrollment as promoted
      UPDATE student_enrollments 
      SET status = 'promoted'
      WHERE id = v_enrollment.id;
      
      v_promoted := v_promoted + 1;
    EXCEPTION WHEN unique_violation THEN
      v_failed := v_failed + 1;
    END;
  END LOOP;
  
  RETURN QUERY SELECT v_promoted, v_failed, v_skipped;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to refresh analytics materialized views
CREATE OR REPLACE FUNCTION refresh_analytics()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_student_performance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate invoices for a class
CREATE OR REPLACE FUNCTION generate_class_invoices(
  p_tenant_id UUID,
  p_class_id UUID,
  p_academic_year_id UUID,
  p_term_id UUID DEFAULT NULL,
  p_due_date DATE DEFAULT (CURRENT_DATE + INTERVAL '30 days')::DATE
) RETURNS INT AS $$
DECLARE
  v_count INT := 0;
  v_student RECORD;
  v_fee RECORD;
  v_invoice_id UUID;
  v_invoice_number VARCHAR(50);
  v_total DECIMAL(10,2);
BEGIN
  -- Loop through all active students in the class
  FOR v_student IN
    SELECT se.student_id, se.section_id
    FROM student_enrollments se
    JOIN sections sec ON se.section_id = sec.id
    WHERE sec.class_id = p_class_id
      AND se.academic_year_id = p_academic_year_id
      AND se.status = 'active'
      AND se.tenant_id = p_tenant_id
  LOOP
    -- Calculate total fees
    SELECT COALESCE(SUM(fs.amount), 0) INTO v_total
    FROM fee_structures fs
    WHERE fs.class_id = p_class_id
      AND fs.academic_year_id = p_academic_year_id
      AND (p_term_id IS NULL OR fs.term_id = p_term_id OR fs.term_id IS NULL)
      AND fs.tenant_id = p_tenant_id;
    
    IF v_total > 0 THEN
      -- Generate invoice number
      v_invoice_number := 'INV-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || 
                          LPAD((v_count + 1)::TEXT, 4, '0');
      
      -- Create invoice
      INSERT INTO invoices (
        tenant_id, invoice_number, student_id, academic_year_id, term_id,
        total_amount, due_date, status
      ) VALUES (
        p_tenant_id, v_invoice_number, v_student.student_id, p_academic_year_id,
        p_term_id, v_total, p_due_date, 'pending'
      ) RETURNING id INTO v_invoice_id;
      
      -- Add invoice items
      INSERT INTO invoice_items (invoice_id, fee_head_id, description, amount)
      SELECT v_invoice_id, fs.fee_head_id, fh.name, fs.amount
      FROM fee_structures fs
      JOIN fee_heads fh ON fs.fee_head_id = fh.id
      WHERE fs.class_id = p_class_id
        AND fs.academic_year_id = p_academic_year_id
        AND (p_term_id IS NULL OR fs.term_id = p_term_id OR fs.term_id IS NULL)
        AND fs.tenant_id = p_tenant_id;
      
      v_count := v_count + 1;
    END IF;
  END LOOP;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get student's current enrollment
CREATE OR REPLACE FUNCTION get_student_current_enrollment(p_student_id UUID)
RETURNS TABLE(
  enrollment_id UUID,
  section_id UUID,
  section_name VARCHAR,
  class_id UUID,
  class_name VARCHAR,
  academic_year_id UUID,
  academic_year_name VARCHAR,
  roll_number VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    se.id AS enrollment_id,
    se.section_id,
    sec.name AS section_name,
    c.id AS class_id,
    c.name AS class_name,
    se.academic_year_id,
    ay.name AS academic_year_name,
    se.roll_number
  FROM student_enrollments se
  JOIN sections sec ON se.section_id = sec.id
  JOIN classes c ON sec.class_id = c.id
  JOIN academic_years ay ON se.academic_year_id = ay.id
  WHERE se.student_id = p_student_id
    AND ay.is_current = true
    AND se.status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get parent's children
CREATE OR REPLACE FUNCTION get_parent_children(p_user_id UUID)
RETURNS TABLE(
  student_id UUID,
  student_name VARCHAR,
  admission_number VARCHAR,
  section_id UUID,
  section_name VARCHAR,
  class_name VARCHAR,
  photo_url TEXT,
  relation VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id AS student_id,
    (s.first_name || ' ' || COALESCE(s.last_name, ''))::VARCHAR AS student_name,
    s.admission_number,
    sec.id AS section_id,
    sec.name AS section_name,
    c.name AS class_name,
    s.photo_url,
    p.relation
  FROM students s
  JOIN student_parents sp ON s.id = sp.student_id
  JOIN parents p ON sp.parent_id = p.id
  JOIN student_enrollments se ON s.id = se.student_id
  JOIN sections sec ON se.section_id = sec.id
  JOIN classes c ON sec.class_id = c.id
  JOIN academic_years ay ON se.academic_year_id = ay.id
  WHERE p.user_id = p_user_id
    AND ay.is_current = true
    AND se.status = 'active'
    AND s.is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get teacher's assigned classes
CREATE OR REPLACE FUNCTION get_teacher_classes(p_user_id UUID)
RETURNS TABLE(
  assignment_id UUID,
  section_id UUID,
  section_name VARCHAR,
  class_id UUID,
  class_name VARCHAR,
  subject_id UUID,
  subject_name VARCHAR,
  student_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ta.id AS assignment_id,
    ta.section_id,
    sec.name AS section_name,
    c.id AS class_id,
    c.name AS class_name,
    ta.subject_id,
    sub.name AS subject_name,
    COUNT(DISTINCT se.student_id) AS student_count
  FROM teacher_assignments ta
  JOIN sections sec ON ta.section_id = sec.id
  JOIN classes c ON sec.class_id = c.id
  JOIN subjects sub ON ta.subject_id = sub.id
  JOIN academic_years ay ON ta.academic_year_id = ay.id
  LEFT JOIN student_enrollments se ON se.section_id = ta.section_id 
    AND se.academic_year_id = ta.academic_year_id
    AND se.status = 'active'
  WHERE ta.teacher_id = p_user_id
    AND ay.is_current = true
  GROUP BY ta.id, ta.section_id, sec.name, c.id, c.name, ta.subject_id, sub.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 5. TRIGGERS FOR REAL-TIME UPDATES
-- =============================================

-- Trigger to update exam statistics after marks are inserted/updated
CREATE OR REPLACE FUNCTION update_exam_statistics()
RETURNS TRIGGER AS $$
DECLARE
  v_exam_id UUID;
  v_section_id UUID;
  v_subject_id UUID;
  v_tenant_id UUID;
BEGIN
  -- Get exam and subject info
  SELECT es.exam_id, es.subject_id, es.tenant_id, 
         (SELECT section_id FROM student_enrollments WHERE student_id = NEW.student_id LIMIT 1)
  INTO v_exam_id, v_subject_id, v_tenant_id, v_section_id
  FROM exam_subjects es
  WHERE es.id = NEW.exam_subject_id;
  
  -- Update or insert exam statistics for this student
  INSERT INTO exam_statistics (
    tenant_id, exam_id, section_id, subject_id, student_id,
    total_marks, obtained_marks, percentage, computed_at
  )
  SELECT 
    v_tenant_id,
    v_exam_id,
    v_section_id,
    v_subject_id,
    NEW.student_id,
    es.max_marks,
    NEW.marks_obtained,
    CASE WHEN es.max_marks > 0 THEN ROUND((NEW.marks_obtained / es.max_marks) * 100, 2) ELSE 0 END,
    NOW()
  FROM exam_subjects es
  WHERE es.id = NEW.exam_subject_id
  ON CONFLICT (exam_id, section_id, 
    COALESCE(subject_id, '00000000-0000-0000-0000-000000000000'::UUID),
    COALESCE(student_id, '00000000-0000-0000-0000-000000000000'::UUID))
  DO UPDATE SET
    obtained_marks = EXCLUDED.obtained_marks,
    percentage = EXCLUDED.percentage,
    computed_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_exam_statistics
AFTER INSERT OR UPDATE ON marks
FOR EACH ROW EXECUTE FUNCTION update_exam_statistics();

-- Trigger to update invoice status after payment
CREATE OR REPLACE FUNCTION update_invoice_on_payment()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' THEN
    UPDATE invoices
    SET 
      paid_amount = paid_amount + NEW.amount,
      status = CASE 
        WHEN paid_amount + NEW.amount >= total_amount - discount_amount THEN 'paid'
        WHEN paid_amount + NEW.amount > 0 THEN 'partial'
        ELSE status
      END,
      updated_at = NOW()
    WHERE id = NEW.invoice_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_invoice_on_payment
AFTER INSERT OR UPDATE ON payments
FOR EACH ROW EXECUTE FUNCTION update_invoice_on_payment();

-- Trigger to update wallet balance on transaction
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.txn_type = 'credit' THEN
    UPDATE wallets
    SET balance = balance + NEW.amount,
        last_transaction_at = NOW(),
        updated_at = NOW()
    WHERE id = NEW.wallet_id;
  ELSIF NEW.txn_type = 'debit' THEN
    UPDATE wallets
    SET balance = balance - NEW.amount,
        last_transaction_at = NOW(),
        updated_at = NOW()
    WHERE id = NEW.wallet_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_wallet_balance
AFTER INSERT ON wallet_transactions
FOR EACH ROW EXECUTE FUNCTION update_wallet_balance();

-- Trigger to update book availability on issue/return
CREATE OR REPLACE FUNCTION update_book_availability()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE library_books
    SET available_copies = available_copies - 1,
        updated_at = NOW()
    WHERE id = NEW.book_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.status = 'issued' AND NEW.status = 'returned' THEN
    UPDATE library_books
    SET available_copies = available_copies + 1,
        updated_at = NOW()
    WHERE id = NEW.book_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_book_availability
AFTER INSERT OR UPDATE ON book_issues
FOR EACH ROW EXECUTE FUNCTION update_book_availability();

-- =============================================
-- 6. INDEXES FOR PERFORMANCE
-- =============================================

CREATE INDEX IF NOT EXISTS idx_attendance_student_date ON attendance(student_id, date);
CREATE INDEX IF NOT EXISTS idx_marks_student_exam ON marks(student_id, exam_subject_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student ON submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_invoices_student_year ON invoices(student_id, academic_year_id);
CREATE INDEX IF NOT EXISTS idx_student_enrollments_year ON student_enrollments(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_year ON teacher_assignments(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_timetables_section_day ON timetables(section_id, day_of_week);

-- =============================================
-- 7. GRANT PERMISSIONS FOR ANALYTICS VIEWS
-- =============================================

GRANT SELECT ON mv_student_performance TO authenticated;
GRANT SELECT ON v_class_exam_stats TO authenticated;
GRANT SELECT ON v_student_ranks TO authenticated;
GRANT SELECT ON v_student_overall_ranks TO authenticated;
GRANT SELECT ON v_attendance_summary TO authenticated;
GRANT SELECT ON v_section_daily_attendance TO authenticated;
GRANT SELECT ON v_fee_summary TO authenticated;
GRANT SELECT ON v_assignment_summary TO authenticated;
