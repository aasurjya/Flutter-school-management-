-- ============================================================================
-- 00073_phase2_indexes_and_caps.sql
--
-- Phase 2.4 — Missing indexes on high-traffic tables + student-count cap RPC.
--
-- Closes the index gaps found during the Phase 2 audit:
--   • exam_subjects, marks, class_subjects, teacher_assignments had no
--     tenant_id index → every list query did a full scan within the tenant
--     partition. At exam season (every teacher loading marks) this burns
--     Supabase compute.
--   • marks(exam_subject_id) — the single hottest query during grade entry.
--   • teacher_assignments(teacher_id) — every teacher's homepage loads this.
--   • class_subjects(class_id) — class setup screen.
--
-- Also adds:
--   • get_student_count(tenant_id) SECURITY DEFINER RPC — used by the
--     enforce-subscription edge function's student_count check so it
--     doesn't need a separate round-trip.
--   • get_tenant_active_student_count() — RLS-safe version for tenant_admins.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Missing tenant_id indexes on high-traffic tables
--
-- CONCURRENTLY so index build doesn't hold a write-blocking lock on tables
-- this migration itself calls out as high-traffic (marks, teacher_assignments).
-- Must run outside a transaction block — this file has no BEGIN/COMMIT.
-- ----------------------------------------------------------------------------
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_exam_subjects_tenant
  ON public.exam_subjects(tenant_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_exam_subjects_exam
  ON public.exam_subjects(exam_id);

-- marks is the hottest table during exam season.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_marks_tenant
  ON public.marks(tenant_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_marks_exam_subject
  ON public.marks(exam_subject_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_marks_student
  ON public.marks(student_id);
-- Composite: tenant + exam_subject → the exact query grade entry runs.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_marks_tenant_exam_subject
  ON public.marks(tenant_id, exam_subject_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_class_subjects_tenant
  ON public.class_subjects(tenant_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_class_subjects_class
  ON public.class_subjects(class_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_class_subjects_subject
  ON public.class_subjects(subject_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teacher_assignments_tenant
  ON public.teacher_assignments(tenant_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teacher_assignments_teacher
  ON public.teacher_assignments(teacher_id);
-- Composite: tenant + teacher → every teacher's homepage query.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_teacher_assignments_tenant_teacher
  ON public.teacher_assignments(tenant_id, teacher_id);

-- ----------------------------------------------------------------------------
-- 2. get_student_count — service-role RPC for enforce-subscription
--    Returns the active student count for a tenant. Used by the edge
--    function's student_count check without a separate Supabase round-trip.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_student_count(p_tenant_id UUID)
RETURNS INT LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT COUNT(*)::int FROM public.students
  WHERE tenant_id = p_tenant_id AND is_active = true;
$$;

COMMENT ON FUNCTION public.get_student_count(UUID) IS
  'Service-role: active student count for a tenant. '
  'Used by enforce-subscription edge function.';

-- ----------------------------------------------------------------------------
-- 3. get_tenant_active_student_count — RLS-safe for tenant_admins
--    Reads the tenant_id from JWT so a tenant admin can check their own
--    capacity without super_admin rights.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_tenant_active_student_count()
RETURNS INT LANGUAGE sql STABLE AS $$
  SELECT COUNT(*)::int FROM public.students
  WHERE tenant_id::TEXT = COALESCE(
    auth.jwt() -> 'app_metadata' ->> 'tenant_id', ''
  )
  AND is_active = true;
$$;

COMMENT ON FUNCTION public.get_tenant_active_student_count() IS
  'RLS-safe: active student count for the calling tenant. '
  'Tenant admins use this to check plan capacity.';

GRANT EXECUTE ON FUNCTION public.get_student_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_tenant_active_student_count() TO authenticated;
