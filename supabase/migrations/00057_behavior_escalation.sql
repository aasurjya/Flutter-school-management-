-- Migration: 00057_behavior_escalation
-- Purpose: Sprint 1.4 — flag students whose discipline incident rate has
--          ACCELERATED in the last 14 days versus the prior 14 days.
--
-- Pure SQL heuristic. No LLM. No external API call. ~0 cost per query.
-- Targeted at the discipline dashboard tile + counselor workflow:
-- "Which 5 students do I need to look at THIS week?"
--
-- Severity weights mirror the standard pyramidal escalation cost in school
-- discipline literature (a critical incident is ~8× the operational cost of a
-- minor one — detention vs principal meeting vs parent escalation).
--
-- Escalation score = (sum of severity-weighted incidents in last 14 days)
--                  − (sum of severity-weighted incidents in the prior 14 days)
--
-- A student is "escalating" when:
--   escalation_score >= 3   (e.g. one new moderate incident, no prior)
--   OR recent_incident_count >= 5   (frequency floor, regardless of trend)
--
-- Returns flagged students ordered by escalation_score desc, then recent_count
-- desc. Caller paginates via LIMIT.
--
-- Pattern follows compute_student_risk_score() in 00010_ai_phase1.sql.
-- RLS: SECURITY DEFINER so the function executes with elevated rights; the
-- function itself filters by p_tenant_id, and EXECUTE is granted only to
-- authenticated (clients can only ask about their own tenant via the RPC).
--
-- Rollback: DROP FUNCTION compute_behavior_escalation; DROP VIEW v_behavior_escalation_current.

-- ============================================================================
-- 1. RPC: compute_behavior_escalation
-- ============================================================================

CREATE OR REPLACE FUNCTION public.compute_behavior_escalation(
  p_tenant_id   UUID,
  p_section_id  UUID DEFAULT NULL,
  p_limit       INT  DEFAULT 20
) RETURNS TABLE (
  student_id          UUID,
  first_name          TEXT,
  last_name           TEXT,
  admission_number    TEXT,
  recent_incident_count INT,
  prior_incident_count  INT,
  recent_weighted_score INT,
  prior_weighted_score  INT,
  escalation_score      INT,
  most_severe_recent    TEXT,
  last_incident_date    DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  RETURN QUERY
  WITH severity_weights AS (
    SELECT 'minor'::TEXT    AS s, 1 AS w UNION ALL
    SELECT 'moderate'::TEXT,       2 UNION ALL
    SELECT 'major'::TEXT,           4 UNION ALL
    SELECT 'critical'::TEXT,        8
  ),
  windowed AS (
    SELECT
      bi.student_id,
      bi.severity::TEXT AS severity,
      bi.incident_date,
      CASE
        WHEN bi.incident_date >= (CURRENT_DATE - INTERVAL '14 days') THEN 'recent'
        WHEN bi.incident_date >= (CURRENT_DATE - INTERVAL '28 days') THEN 'prior'
        ELSE 'older'
      END AS bucket
    FROM behavior_incidents bi
    WHERE bi.tenant_id = p_tenant_id
      AND bi.incident_date >= (CURRENT_DATE - INTERVAL '28 days')
  ),
  agg AS (
    SELECT
      w.student_id,
      COUNT(*) FILTER (WHERE w.bucket = 'recent')::INT AS recent_n,
      COUNT(*) FILTER (WHERE w.bucket = 'prior')::INT  AS prior_n,
      COALESCE(SUM(sw.w) FILTER (WHERE w.bucket = 'recent'), 0)::INT AS recent_wt,
      COALESCE(SUM(sw.w) FILTER (WHERE w.bucket = 'prior'),  0)::INT AS prior_wt,
      (SELECT w2.severity FROM windowed w2
         WHERE w2.student_id = w.student_id AND w2.bucket = 'recent'
         ORDER BY (CASE w2.severity
                     WHEN 'critical' THEN 4
                     WHEN 'major'    THEN 3
                     WHEN 'moderate' THEN 2
                     ELSE 1 END) DESC,
                  w2.incident_date DESC
         LIMIT 1) AS most_severe,
      MAX(w.incident_date) FILTER (WHERE w.bucket = 'recent') AS last_dt
    FROM windowed w
    LEFT JOIN severity_weights sw ON sw.s = w.severity
    GROUP BY w.student_id
  )
  SELECT
    s.id            AS student_id,
    s.first_name    AS first_name,
    s.last_name     AS last_name,
    s.admission_number AS admission_number,
    agg.recent_n,
    agg.prior_n,
    agg.recent_wt,
    agg.prior_wt,
    (agg.recent_wt - agg.prior_wt)::INT AS escalation_score,
    agg.most_severe,
    agg.last_dt
  FROM agg
  JOIN students s ON s.id = agg.student_id
  LEFT JOIN student_enrollments e
    ON e.student_id = s.id AND e.is_active = TRUE
  WHERE
    s.tenant_id = p_tenant_id
    AND (p_section_id IS NULL OR e.section_id = p_section_id)
    AND (
      (agg.recent_wt - agg.prior_wt) >= 3
      OR agg.recent_n >= 5
    )
  ORDER BY escalation_score DESC, agg.recent_n DESC, agg.last_dt DESC NULLS LAST
  LIMIT GREATEST(p_limit, 1);
END $$;

REVOKE EXECUTE ON FUNCTION public.compute_behavior_escalation(UUID, UUID, INT)
  FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.compute_behavior_escalation(UUID, UUID, INT)
  TO authenticated;

COMMENT ON FUNCTION public.compute_behavior_escalation IS
  'Sprint 1.4: returns students whose 14-day weighted incident score has accelerated. Pure SQL, no LLM cost.';

-- ============================================================================
-- 2. VIEW: v_behavior_escalation_current  (convenience tile-level view)
-- ============================================================================
-- View applies RLS via the underlying behavior_incidents + students tables.
-- Limited to last 28 days for index-friendly scans.

CREATE OR REPLACE VIEW public.v_behavior_escalation_summary AS
SELECT
  bi.tenant_id,
  COUNT(DISTINCT bi.student_id) FILTER (
    WHERE bi.incident_date >= (CURRENT_DATE - INTERVAL '14 days')
  ) AS students_with_recent_incidents,
  COUNT(*) FILTER (
    WHERE bi.incident_date >= (CURRENT_DATE - INTERVAL '14 days')
  ) AS total_recent_incidents,
  COUNT(*) FILTER (
    WHERE bi.incident_date >= (CURRENT_DATE - INTERVAL '14 days')
      AND bi.severity IN ('major', 'critical')
  ) AS recent_major_or_critical,
  COUNT(*) FILTER (
    WHERE bi.incident_date >= (CURRENT_DATE - INTERVAL '28 days')
      AND bi.incident_date < (CURRENT_DATE - INTERVAL '14 days')
  ) AS prior_total_incidents
FROM behavior_incidents bi
WHERE bi.incident_date >= (CURRENT_DATE - INTERVAL '28 days')
GROUP BY bi.tenant_id;

COMMENT ON VIEW public.v_behavior_escalation_summary IS
  'Sprint 1.4: tenant-level rollup for the discipline dashboard tile header.';

-- ============================================================================
-- Done.
-- ============================================================================
