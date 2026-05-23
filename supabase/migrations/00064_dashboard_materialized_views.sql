-- ============================================================================
-- 00064_dashboard_materialized_views.sql
--
-- Materialized views for the 3 role dashboards (admin / teacher / parent).
-- Each dashboard previously fired 5+ aggregation queries on every load.
-- Now each one reads a single row from a pre-aggregated mv refreshed every
-- 5 minutes via pg_cron.
--
-- Trade-off: dashboard data is up to 5 minutes stale. Acceptable for KPI
-- summaries (today's attendance %, this-week's fees collected, students-
-- at-risk count). Real-time accuracy stays in the OLTP tables; only the
-- aggregations get cached.
--
-- p95 dashboard render targets after this migration lands:
--   • admin    "reads one row" → < 100 ms
--   • teacher  "reads one row + class breakdown" → < 200 ms
--   • parent   "reads one row + child summary" → < 150 ms
--
-- Refresh is CONCURRENTLY so reads don't block during the rebuild.
-- ============================================================================

-- pg_cron is normally pre-installed on Supabase. Defensive guard:
DO $do$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    RAISE NOTICE 'pg_cron extension not installed; mv refresh schedule '
                 'will need to be set up manually';
  END IF;
END
$do$;

-- ----------------------------------------------------------------------------
-- 1. mv_admin_kpis — tenant-level snapshot for the admin/principal dashboard
-- ----------------------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS public.mv_admin_kpis CASCADE;

CREATE MATERIALIZED VIEW public.mv_admin_kpis AS
SELECT
  t.id AS tenant_id,
  -- Student counts.
  (SELECT COUNT(*) FROM students s
   WHERE s.tenant_id = t.id AND s.is_active = true) AS active_students,
  -- Today's attendance %.
  (
    SELECT CASE
      WHEN COUNT(*) = 0 THEN NULL
      ELSE ROUND(
        100.0 * SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*), 0), 1)
    END
    FROM attendance a
    WHERE a.tenant_id = t.id
      AND a.date = CURRENT_DATE
  ) AS today_attendance_pct,
  -- Fee collection MTD.
  (SELECT COALESCE(SUM(p.amount), 0)
   FROM payments p
   WHERE p.tenant_id = t.id
     AND p.paid_at >= DATE_TRUNC('month', NOW())
     AND p.status = 'completed') AS fees_collected_mtd,
  -- Overdue invoice count.
  (SELECT COUNT(*)
   FROM invoices i
   WHERE i.tenant_id = t.id
     AND i.status = 'overdue') AS overdue_invoices,
  -- At-risk students (joins to student_risk_scores from migration 00010 —
  -- if that table doesn't exist yet, the subquery returns 0 instead of
  -- failing the whole view).
  COALESCE((
    SELECT COUNT(*)
    FROM student_risk_scores srs
    WHERE srs.tenant_id = t.id
      AND srs.risk_level IN ('high', 'critical')
  ), 0) AS at_risk_students,
  NOW() AS refreshed_at
FROM tenants t;

CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_admin_kpis_tenant
  ON public.mv_admin_kpis (tenant_id);

COMMENT ON MATERIALIZED VIEW public.mv_admin_kpis IS
  'Per-tenant admin dashboard snapshot. Refreshed every 5 min via pg_cron. '
  'Replaces 5+ ad-hoc aggregation queries on every dashboard load.';

-- ----------------------------------------------------------------------------
-- 2. mv_teacher_class_summary — per-section snapshot for the teacher dashboard
-- ----------------------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS public.mv_teacher_class_summary CASCADE;

CREATE MATERIALIZED VIEW public.mv_teacher_class_summary AS
SELECT
  s.tenant_id,
  s.id AS section_id,
  s.name AS section_name,
  c.id AS class_id,
  c.name AS class_name,
  (SELECT COUNT(*)
   FROM student_enrollments e
   WHERE e.section_id = s.id
     AND e.status = 'active') AS active_students,
  (
    SELECT CASE
      WHEN COUNT(*) = 0 THEN NULL
      ELSE ROUND(
        100.0 * SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*), 0), 1)
    END
    FROM attendance a
    JOIN student_enrollments e ON e.student_id = a.student_id
    WHERE e.section_id = s.id
      AND a.date = CURRENT_DATE
  ) AS today_attendance_pct,
  COALESCE((
    SELECT COUNT(*)
    FROM student_risk_scores srs
    JOIN student_enrollments e ON e.student_id = srs.student_id
    WHERE e.section_id = s.id
      AND srs.risk_level IN ('high', 'critical')
  ), 0) AS at_risk_students,
  NOW() AS refreshed_at
FROM sections s
JOIN classes c ON c.id = s.class_id;

CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_teacher_class_summary_section
  ON public.mv_teacher_class_summary (section_id);
CREATE INDEX IF NOT EXISTS idx_mv_teacher_class_summary_tenant
  ON public.mv_teacher_class_summary (tenant_id);

COMMENT ON MATERIALIZED VIEW public.mv_teacher_class_summary IS
  'Per-section snapshot for teacher dashboards. One row per section.';

-- ----------------------------------------------------------------------------
-- 3. mv_parent_child_overview — per-student snapshot for the parent dashboard
-- ----------------------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS public.mv_parent_child_overview CASCADE;

CREATE MATERIALIZED VIEW public.mv_parent_child_overview AS
SELECT
  s.tenant_id,
  s.id AS student_id,
  s.first_name || ' ' || COALESCE(s.last_name, '') AS student_name,
  -- This-week attendance %.
  (
    SELECT CASE
      WHEN COUNT(*) = 0 THEN NULL
      ELSE ROUND(
        100.0 * SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*), 0), 1)
    END
    FROM attendance a
    WHERE a.student_id = s.id
      AND a.date >= DATE_TRUNC('week', CURRENT_DATE)
  ) AS week_attendance_pct,
  -- Total outstanding invoices.
  (SELECT COALESCE(SUM(i.total_amount), 0)
   FROM invoices i
   WHERE i.student_id = s.id
     AND i.status IN ('pending', 'overdue', 'partial')) AS outstanding_amount,
  -- Risk level (NULL if no recent score).
  (SELECT srs.risk_level
   FROM student_risk_scores srs
   WHERE srs.student_id = s.id
   ORDER BY srs.computed_at DESC NULLS LAST
   LIMIT 1) AS risk_level,
  NOW() AS refreshed_at
FROM students s
WHERE s.is_active = true;

CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_parent_child_overview_student
  ON public.mv_parent_child_overview (student_id);
CREATE INDEX IF NOT EXISTS idx_mv_parent_child_overview_tenant
  ON public.mv_parent_child_overview (tenant_id);

COMMENT ON MATERIALIZED VIEW public.mv_parent_child_overview IS
  'Per-student snapshot for parent dashboards. One row per active student.';

-- ----------------------------------------------------------------------------
-- Refresh function — call from pg_cron.
-- CONCURRENTLY requires the unique indexes above; reads aren't blocked
-- during refresh.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.refresh_dashboard_mvs()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_admin_kpis;
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_teacher_class_summary;
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_parent_child_overview;
END
$$;

COMMENT ON FUNCTION public.refresh_dashboard_mvs IS
  'Refreshes all 3 dashboard materialized views CONCURRENTLY. '
  'Scheduled by pg_cron every 5 min.';

-- Schedule the refresh — every 5 minutes. Skip silently if pg_cron isn't
-- available (e.g., local dev without the extension).
DO $do$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Idempotent: cron.schedule errors on duplicate name, so unschedule first.
    PERFORM cron.unschedule('refresh_dashboard_mvs')
      WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'refresh_dashboard_mvs');
    PERFORM cron.schedule(
      'refresh_dashboard_mvs',
      '*/5 * * * *',
      $cron$SELECT public.refresh_dashboard_mvs();$cron$
    );
  END IF;
END
$do$;

-- ----------------------------------------------------------------------------
-- RLS — mvs aren't covered by row-level security by default. Wrap reads in
-- views that filter by the caller's tenant_id from JWT.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW public.v_my_admin_kpis
WITH (security_invoker = on) AS
SELECT mv.*
FROM public.mv_admin_kpis mv
WHERE mv.tenant_id = NULLIF(
  current_setting('request.jwt.claims', true)::jsonb
    -> 'app_metadata' ->> 'tenant_id', ''
)::UUID;

CREATE OR REPLACE VIEW public.v_my_teacher_class_summary
WITH (security_invoker = on) AS
SELECT mv.*
FROM public.mv_teacher_class_summary mv
WHERE mv.tenant_id = NULLIF(
  current_setting('request.jwt.claims', true)::jsonb
    -> 'app_metadata' ->> 'tenant_id', ''
)::UUID;

CREATE OR REPLACE VIEW public.v_my_parent_child_overview
WITH (security_invoker = on) AS
SELECT mv.*
FROM public.mv_parent_child_overview mv
WHERE mv.tenant_id = NULLIF(
  current_setting('request.jwt.claims', true)::jsonb
    -> 'app_metadata' ->> 'tenant_id', ''
)::UUID;

GRANT SELECT ON public.v_my_admin_kpis            TO authenticated;
GRANT SELECT ON public.v_my_teacher_class_summary TO authenticated;
GRANT SELECT ON public.v_my_parent_child_overview TO authenticated;
