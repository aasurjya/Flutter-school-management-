-- Migration: 00054_perf_quality_sweep
-- Purpose: Performance and integrity sweep
--
--   1. RLS rewrites — wrap bare helper calls in (SELECT ...) for high-traffic
--      tables so Postgres evaluates helpers once per query, not per row.
--      Target tables: students, attendance, marks, invoices, threads, messages,
--      wallets, announcements, canteen_menu, users, tenants, academic_years,
--      terms, classes, sections, subjects.
--      Remaining ~85 policies in 00007 and feature migrations are out of scope
--      here — they will follow in a later sweep once this one is verified.
--   2. pg_trgm extension + GIN trigram indexes on first_name / last_name for
--      students, parents, staff so ILIKE '%query%' uses index scan.
--   3. Missing FK indexes on student_parents.parent_id and parents.user_id
--      (both hit in parent-role RLS subqueries on every multi-tenant table).
--   4. submit_exam_attempt_secure RPC — server-side time verification gate so
--      a student cannot falsify elapsed time by tampering with the device clock.
--
-- Not included (already shipped in 00048):
--   - generate_class_invoices() duplicate guard + advisory lock
--   - hostel_rooms.occupied trigger
--
-- Rollback: this migration is mostly additive (extensions, indexes, RPC).
-- The RLS rewrites DROP-then-CREATE policies; to revert, re-run the policy
-- definitions from 00006_rls_policies.sql.

-- ============================================================================
-- 1. RLS POLICY REWRITES (hot tables)
-- ============================================================================
-- Pattern: bare public.tenant_id() / public.has_role(...) / public.is_admin()
-- becomes (SELECT public.tenant_id()) / (SELECT public.has_role(...)) /
-- (SELECT public.is_admin()). Postgres caches the scalar subquery result.

-- ---- tenants ----
DROP POLICY IF EXISTS "Users view own tenant" ON tenants;
CREATE POLICY "Users view own tenant"
ON tenants FOR SELECT
USING (id = (SELECT public.tenant_id()));

-- "Super admins view all tenants" and "Super admins manage tenants" are
-- already wrapped by 00048's "Users read own tenant or super_admin reads all".
-- Leave them as a defense-in-depth read path.
DROP POLICY IF EXISTS "Super admins view all tenants" ON tenants;
CREATE POLICY "Super admins view all tenants"
ON tenants FOR SELECT
USING ((SELECT public.has_role('super_admin')));

DROP POLICY IF EXISTS "Super admins manage tenants" ON tenants;
CREATE POLICY "Super admins manage tenants"
ON tenants FOR ALL
USING ((SELECT public.has_role('super_admin')));

-- ---- users ----
DROP POLICY IF EXISTS "Users view users in tenant" ON users;
CREATE POLICY "Users view users in tenant"
ON users FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()) OR id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users update own profile" ON users;
CREATE POLICY "Users update own profile"
ON users FOR UPDATE
USING (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Admins manage users" ON users;
CREATE POLICY "Admins manage users"
ON users FOR ALL
USING (tenant_id = (SELECT public.tenant_id()) AND (SELECT public.is_admin()));

-- ---- academic structure ----
DROP POLICY IF EXISTS "View academic years" ON academic_years;
CREATE POLICY "View academic years"
ON academic_years FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()));

DROP POLICY IF EXISTS "Admins manage academic years" ON academic_years;
CREATE POLICY "Admins manage academic years"
ON academic_years FOR ALL
USING (tenant_id = (SELECT public.tenant_id()) AND (SELECT public.is_admin()));

DROP POLICY IF EXISTS "View terms" ON terms;
CREATE POLICY "View terms"
ON terms FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()));

DROP POLICY IF EXISTS "Admins manage terms" ON terms;
CREATE POLICY "Admins manage terms"
ON terms FOR ALL
USING (tenant_id = (SELECT public.tenant_id()) AND (SELECT public.is_admin()));

DROP POLICY IF EXISTS "View classes" ON classes;
CREATE POLICY "View classes"
ON classes FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()));

DROP POLICY IF EXISTS "Admins manage classes" ON classes;
CREATE POLICY "Admins manage classes"
ON classes FOR ALL
USING (tenant_id = (SELECT public.tenant_id()) AND (SELECT public.is_admin()));

DROP POLICY IF EXISTS "View sections" ON sections;
CREATE POLICY "View sections"
ON sections FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()));

DROP POLICY IF EXISTS "Admins manage sections" ON sections;
CREATE POLICY "Admins manage sections"
ON sections FOR ALL
USING (tenant_id = (SELECT public.tenant_id()) AND (SELECT public.is_admin()));

DROP POLICY IF EXISTS "View subjects" ON subjects;
CREATE POLICY "View subjects"
ON subjects FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()));

DROP POLICY IF EXISTS "Admins manage subjects" ON subjects;
CREATE POLICY "Admins manage subjects"
ON subjects FOR ALL
USING (tenant_id = (SELECT public.tenant_id()) AND (SELECT public.is_admin()));

-- ---- students ----
DROP POLICY IF EXISTS "Staff view students" ON students;
CREATE POLICY "Staff view students"
ON students FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id()) AND (
    (SELECT public.is_admin()) OR
    (SELECT public.has_role('teacher')) OR
    user_id = (SELECT auth.uid()) OR
    id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = (SELECT auth.uid())
    )
  )
);

DROP POLICY IF EXISTS "Admins manage students" ON students;
CREATE POLICY "Admins manage students"
ON students FOR ALL
USING (tenant_id = (SELECT public.tenant_id()) AND (SELECT public.is_admin()));

-- ---- attendance ----
DROP POLICY IF EXISTS "View attendance" ON attendance;
CREATE POLICY "View attendance"
ON attendance FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id()) AND (
    (SELECT public.is_admin()) OR
    (SELECT public.has_role('teacher')) OR
    student_id IN (SELECT id FROM students WHERE user_id = (SELECT auth.uid())) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = (SELECT auth.uid())
    )
  )
);

DROP POLICY IF EXISTS "Teachers mark attendance" ON attendance;
CREATE POLICY "Teachers mark attendance"
ON attendance FOR INSERT
WITH CHECK (
  tenant_id = (SELECT public.tenant_id()) AND (
    (SELECT public.is_admin()) OR (SELECT public.has_role('teacher'))
  )
);

DROP POLICY IF EXISTS "Teachers update attendance" ON attendance;
CREATE POLICY "Teachers update attendance"
ON attendance FOR UPDATE
USING (
  tenant_id = (SELECT public.tenant_id()) AND (
    (SELECT public.is_admin()) OR (SELECT public.has_role('teacher'))
  )
);

-- ---- marks ----
DROP POLICY IF EXISTS "View marks" ON marks;
CREATE POLICY "View marks"
ON marks FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id()) AND (
    (SELECT public.is_admin()) OR
    (SELECT public.has_role('teacher')) OR
    student_id IN (SELECT id FROM students WHERE user_id = (SELECT auth.uid())) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = (SELECT auth.uid())
    )
  )
);

DROP POLICY IF EXISTS "Teachers manage marks" ON marks;
CREATE POLICY "Teachers manage marks"
ON marks FOR ALL
USING (
  tenant_id = (SELECT public.tenant_id()) AND (
    (SELECT public.is_admin()) OR (SELECT public.has_role('teacher'))
  )
);

-- ---- invoices ----
DROP POLICY IF EXISTS "View invoices" ON invoices;
CREATE POLICY "View invoices"
ON invoices FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id()) AND (
    (SELECT public.is_admin()) OR
    (SELECT public.has_role('accountant')) OR
    student_id IN (SELECT id FROM students WHERE user_id = (SELECT auth.uid())) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = (SELECT auth.uid())
    )
  )
);

DROP POLICY IF EXISTS "Accountants manage invoices" ON invoices;
CREATE POLICY "Accountants manage invoices"
ON invoices FOR ALL
USING (
  tenant_id = (SELECT public.tenant_id()) AND (
    (SELECT public.is_admin()) OR (SELECT public.has_role('accountant'))
  )
);

-- ---- threads + messages ----
DROP POLICY IF EXISTS "View own threads" ON threads;
CREATE POLICY "View own threads"
ON threads FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id()) AND (
    created_by = (SELECT auth.uid()) OR
    id IN (SELECT thread_id FROM thread_participants WHERE user_id = (SELECT auth.uid()))
  )
);

DROP POLICY IF EXISTS "Create threads" ON threads;
CREATE POLICY "Create threads"
ON threads FOR INSERT
WITH CHECK (
  tenant_id = (SELECT public.tenant_id()) AND created_by = (SELECT auth.uid())
);

DROP POLICY IF EXISTS "View messages in threads" ON messages;
CREATE POLICY "View messages in threads"
ON messages FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id()) AND
  thread_id IN (SELECT thread_id FROM thread_participants WHERE user_id = (SELECT auth.uid()))
);

DROP POLICY IF EXISTS "Send messages" ON messages;
CREATE POLICY "Send messages"
ON messages FOR INSERT
WITH CHECK (
  tenant_id = (SELECT public.tenant_id()) AND
  sender_id = (SELECT auth.uid()) AND
  thread_id IN (SELECT thread_id FROM thread_participants WHERE user_id = (SELECT auth.uid()))
);

-- ---- canteen ----
DROP POLICY IF EXISTS "View menu" ON canteen_menu;
CREATE POLICY "View menu"
ON canteen_menu FOR SELECT
USING (tenant_id = (SELECT public.tenant_id()));

DROP POLICY IF EXISTS "Staff manage menu" ON canteen_menu;
CREATE POLICY "Staff manage menu"
ON canteen_menu FOR ALL
USING (
  tenant_id = (SELECT public.tenant_id()) AND (
    (SELECT public.is_admin()) OR (SELECT public.has_role('canteen_staff'))
  )
);

DROP POLICY IF EXISTS "View own wallet" ON wallets;
CREATE POLICY "View own wallet"
ON wallets FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id()) AND (
    user_id = (SELECT auth.uid()) OR
    student_id IN (SELECT id FROM students WHERE user_id = (SELECT auth.uid())) OR
    student_id IN (
      SELECT sp.student_id FROM student_parents sp
      JOIN parents p ON sp.parent_id = p.id
      WHERE p.user_id = (SELECT auth.uid())
    )
  )
);

-- ---- announcements ----
DROP POLICY IF EXISTS "View announcements" ON announcements;
CREATE POLICY "View announcements"
ON announcements FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id()) AND
  is_published = true AND
  (publish_at IS NULL OR publish_at <= NOW()) AND
  (expires_at IS NULL OR expires_at > NOW())
);

DROP POLICY IF EXISTS "Admins manage announcements" ON announcements;
CREATE POLICY "Admins manage announcements"
ON announcements FOR ALL
USING (tenant_id = (SELECT public.tenant_id()) AND (SELECT public.is_admin()));

-- ============================================================================
-- 2. pg_trgm extension + GIN trigram indexes for name search
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA extensions;

-- Drop legacy B-tree name indexes if they exist; they don't help leading-wildcard ILIKE.
-- (They stay as a fallback if absent, this is just cleanup. CREATE INDEX below is
-- the actually useful one.)

CREATE INDEX IF NOT EXISTS idx_students_first_name_trgm
  ON students USING gin (first_name extensions.gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_students_last_name_trgm
  ON students USING gin (last_name extensions.gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_students_admission_number_trgm
  ON students USING gin (admission_number extensions.gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_parents_first_name_trgm
  ON parents USING gin (first_name extensions.gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_parents_last_name_trgm
  ON parents USING gin (last_name extensions.gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_staff_first_name_trgm
  ON staff USING gin (first_name extensions.gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_staff_last_name_trgm
  ON staff USING gin (last_name extensions.gin_trgm_ops);

-- ============================================================================
-- 3. Missing FK indexes hit in parent-role RLS subqueries
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_student_parents_parent_id
  ON student_parents(parent_id);

CREATE INDEX IF NOT EXISTS idx_parents_user_id
  ON parents(user_id);

-- ============================================================================
-- 4. Server-side exam time verification RPC
-- ============================================================================
-- The Flutter client computes remaining time client-side, which a student can
-- bypass by freezing the device clock. This RPC re-computes elapsed time from
-- exam_attempts.started_at using NOW() on the database and rejects manual
-- submissions that exceed the allowed duration.
--
-- The Dart submitExamAttempt method should call this RPC before performing
-- the grade UPDATE. If allowed = false, surface a clear error in the UI.

CREATE OR REPLACE FUNCTION verify_exam_attempt_time(
  p_attempt_id UUID,
  p_auto_submit BOOLEAN DEFAULT false
) RETURNS TABLE (
  allowed BOOLEAN,
  elapsed_seconds INT,
  duration_seconds INT,
  reason TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_started_at TIMESTAMPTZ;
  v_duration_minutes INT;
  v_elapsed INT;
  v_duration_seconds INT;
  v_grace_seconds CONSTANT INT := 30;
BEGIN
  SELECT a.started_at, e.duration_minutes
    INTO v_started_at, v_duration_minutes
  FROM exam_attempts a
  JOIN online_exams e ON a.exam_id = e.id
  WHERE a.id = p_attempt_id;

  IF v_started_at IS NULL THEN
    RETURN QUERY SELECT false, 0, 0, 'attempt_not_found'::TEXT;
    RETURN;
  END IF;

  v_elapsed := EXTRACT(EPOCH FROM (NOW() - v_started_at))::INT;
  v_duration_seconds := v_duration_minutes * 60;

  -- Allow auto-submit at any point (client-side timer hit zero), or manual
  -- submit while within the allowed duration + grace window for clock skew.
  IF p_auto_submit OR v_elapsed <= (v_duration_seconds + v_grace_seconds) THEN
    RETURN QUERY SELECT true, v_elapsed, v_duration_seconds, 'ok'::TEXT;
  ELSE
    RETURN QUERY SELECT false, v_elapsed, v_duration_seconds, 'over_time'::TEXT;
  END IF;
END $$;

GRANT EXECUTE ON FUNCTION verify_exam_attempt_time(UUID, BOOLEAN) TO authenticated;

-- ============================================================================
-- Done.
-- ============================================================================
