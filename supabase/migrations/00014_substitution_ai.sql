-- ============================================================
-- Migration: 00014_substitution_ai
-- Feature: AI Substitution Teacher Assignment
-- ============================================================

-- ============================================================
-- teacher_absences — absence records per day
-- ============================================================
CREATE TABLE IF NOT EXISTS teacher_absences (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  teacher_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  absence_date   DATE NOT NULL,
  reason         TEXT,
  leave_type     VARCHAR(30) NOT NULL DEFAULT 'sick', -- sick, casual, personal, emergency, other
  status         VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, confirmed, cancelled
  reported_by    UUID REFERENCES users(id),
  approved_by    UUID REFERENCES users(id),
  notes          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, teacher_id, absence_date)
);

CREATE INDEX IF NOT EXISTS idx_teacher_absences_tenant      ON teacher_absences(tenant_id);
CREATE INDEX IF NOT EXISTS idx_teacher_absences_date        ON teacher_absences(tenant_id, absence_date);
CREATE INDEX IF NOT EXISTS idx_teacher_absences_teacher     ON teacher_absences(teacher_id);

-- ============================================================
-- substitution_assignments — per-period substitute assignments
-- ============================================================
CREATE TABLE IF NOT EXISTS substitution_assignments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  absence_id            UUID REFERENCES teacher_absences(id) ON DELETE CASCADE,
  timetable_id          UUID REFERENCES timetables(id),
  absent_teacher_id     UUID NOT NULL REFERENCES users(id),
  substitute_teacher_id UUID NOT NULL REFERENCES users(id),
  slot_id               UUID REFERENCES timetable_slots(id),
  section_id            UUID REFERENCES sections(id),
  subject_id            UUID REFERENCES subjects(id),
  substitution_date     DATE NOT NULL,
  status                VARCHAR(20) NOT NULL DEFAULT 'confirmed', -- confirmed, cancelled
  match_score           INTEGER DEFAULT 0,
  notes                 TEXT,
  assigned_by           UUID REFERENCES users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, timetable_id, substitution_date)
);

CREATE INDEX IF NOT EXISTS idx_sub_assignments_tenant   ON substitution_assignments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sub_assignments_date     ON substitution_assignments(tenant_id, substitution_date);
CREATE INDEX IF NOT EXISTS idx_sub_assignments_sub      ON substitution_assignments(substitute_teacher_id);
CREATE INDEX IF NOT EXISTS idx_sub_assignments_absent   ON substitution_assignments(absent_teacher_id);

-- ============================================================
-- RLS
-- ============================================================
ALTER TABLE teacher_absences ENABLE ROW LEVEL SECURITY;
ALTER TABLE substitution_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "teacher_absences_tenant" ON teacher_absences
  FOR ALL USING (tenant_id = (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "substitution_assignments_tenant" ON substitution_assignments
  FOR ALL USING (tenant_id = (SELECT tenant_id FROM users WHERE id = auth.uid()));

-- ============================================================
-- Updated-at trigger
-- ============================================================
CREATE OR REPLACE FUNCTION update_teacher_absences_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_teacher_absences_updated_at ON teacher_absences;
CREATE TRIGGER trg_teacher_absences_updated_at
  BEFORE UPDATE ON teacher_absences
  FOR EACH ROW EXECUTE FUNCTION update_teacher_absences_updated_at();

-- ============================================================
-- suggest_substitutes — rule-based ranking function
-- Returns ranked candidate substitutes for each period of an absent teacher
-- Scoring: Subject qualification (60 pts) + low substitution load (40 pts)
-- ============================================================
CREATE OR REPLACE FUNCTION suggest_substitutes(
  p_tenant_id           UUID,
  p_absent_teacher_id   UUID,
  p_date                DATE
)
RETURNS TABLE(
  timetable_id                  UUID,
  slot_id                       UUID,
  slot_name                     TEXT,
  start_time                    TEXT,
  end_time                      TEXT,
  section_id                    UUID,
  section_name                  TEXT,
  class_name                    TEXT,
  subject_id                    UUID,
  subject_name                  TEXT,
  candidate_teacher_id          UUID,
  candidate_name                TEXT,
  match_score                   INT,
  match_reason                  TEXT,
  substitution_count_this_month INT,
  rank                          INT
) AS $$
DECLARE
  v_day_of_week INT;
BEGIN
  v_day_of_week := EXTRACT(ISODOW FROM p_date)::INT;

  RETURN QUERY
  WITH
  -- The absent teacher's periods today
  absent_periods AS (
    SELECT
      t.id            AS timetable_id,
      t.slot_id,
      ts.name         AS slot_name,
      ts.start_time,
      ts.end_time,
      t.section_id,
      sec.name        AS section_name,
      c.name          AS class_name,
      t.subject_id,
      s.name          AS subject_name
    FROM   timetables     t
    JOIN   timetable_slots ts  ON ts.id = t.slot_id
    JOIN   sections        sec ON sec.id = t.section_id
    JOIN   classes         c   ON c.id  = sec.class_id
    LEFT JOIN subjects     s   ON s.id  = t.subject_id
    WHERE  t.tenant_id  = p_tenant_id
      AND  t.teacher_id = p_absent_teacher_id
      AND  t.day_of_week = v_day_of_week
  ),
  -- All teachers in this tenant except the absent one
  all_teachers AS (
    SELECT DISTINCT u.id AS teacher_id, u.full_name
    FROM users u
    JOIN user_roles ur ON ur.user_id = u.id AND ur.tenant_id = p_tenant_id
    WHERE u.tenant_id   = p_tenant_id
      AND ur.role       = 'teacher'
      AND u.id         != p_absent_teacher_id
      -- Exclude teachers absent today
      AND u.id NOT IN (
        SELECT ta.teacher_id
        FROM   teacher_absences ta
        WHERE  ta.tenant_id    = p_tenant_id
          AND  ta.absence_date = p_date
          AND  ta.status IN ('pending', 'confirmed')
      )
  ),
  -- Teachers occupied in each slot today
  busy_in_slot AS (
    SELECT t.slot_id, t.teacher_id
    FROM   timetables t
    WHERE  t.tenant_id   = p_tenant_id
      AND  t.day_of_week = v_day_of_week
      AND  t.teacher_id IS NOT NULL
  ),
  -- Already assigned as substitute today per slot
  already_assigned AS (
    SELECT sa.slot_id, sa.substitute_teacher_id
    FROM   substitution_assignments sa
    WHERE  sa.tenant_id        = p_tenant_id
      AND  sa.substitution_date = p_date
      AND  sa.status           = 'confirmed'
  ),
  -- Subject qualifications (from both teacher_assignments and existing timetables)
  teacher_qualifications AS (
    SELECT DISTINCT teacher_id, subject_id
    FROM   teacher_assignments
    WHERE  tenant_id = p_tenant_id
    UNION
    SELECT DISTINCT teacher_id, subject_id
    FROM   timetables
    WHERE  tenant_id   = p_tenant_id
      AND  subject_id IS NOT NULL
      AND  teacher_id IS NOT NULL
  ),
  -- Substitution load this calendar month
  sub_load AS (
    SELECT substitute_teacher_id, COUNT(*) AS sub_count
    FROM   substitution_assignments
    WHERE  tenant_id          = p_tenant_id
      AND  substitution_date >= DATE_TRUNC('month', p_date)
      AND  status             = 'confirmed'
    GROUP BY substitute_teacher_id
  )

  SELECT
    ap.timetable_id,
    ap.slot_id,
    ap.slot_name::TEXT,
    ap.start_time::TEXT,
    ap.end_time::TEXT,
    ap.section_id,
    ap.section_name::TEXT,
    ap.class_name::TEXT,
    ap.subject_id,
    ap.subject_name::TEXT,
    at.teacher_id           AS candidate_teacher_id,
    at.full_name::TEXT      AS candidate_name,

    -- Match score 0–100
    LEAST(100,
      CASE WHEN tq.teacher_id IS NOT NULL THEN 60 ELSE 30 END
      + CASE
          WHEN COALESCE(sl.sub_count, 0) = 0  THEN 40
          WHEN COALESCE(sl.sub_count, 0) <= 2  THEN 25
          WHEN COALESCE(sl.sub_count, 0) <= 5  THEN 10
          ELSE 0
        END
    )::INT AS match_score,

    CASE
      WHEN tq.teacher_id IS NOT NULL
        THEN 'Qualified for ' || COALESCE(ap.subject_name, 'subject') || ' • ' ||
             CASE COALESCE(sl.sub_count, 0)
               WHEN 0 THEN 'No sub duties this month'
               ELSE COALESCE(sl.sub_count, 0) || ' sub(s) this month'
             END
      ELSE 'Free period • Available for cover'
    END::TEXT AS match_reason,

    COALESCE(sl.sub_count, 0)::INT AS substitution_count_this_month,

    ROW_NUMBER() OVER (
      PARTITION BY ap.timetable_id
      ORDER BY
        (tq.teacher_id IS NOT NULL) DESC,
        COALESCE(sl.sub_count, 0) ASC,
        at.full_name ASC
    )::INT AS rank

  FROM   absent_periods ap
  CROSS JOIN all_teachers at
  -- Only free teachers
  LEFT JOIN busy_in_slot     bis ON bis.slot_id    = ap.slot_id AND bis.teacher_id = at.teacher_id
  LEFT JOIN already_assigned aa  ON aa.slot_id     = ap.slot_id AND aa.substitute_teacher_id = at.teacher_id
  LEFT JOIN teacher_qualifications tq ON tq.teacher_id = at.teacher_id AND tq.subject_id = ap.subject_id
  LEFT JOIN sub_load         sl  ON sl.substitute_teacher_id = at.teacher_id

  WHERE  bis.teacher_id            IS NULL
    AND  aa.substitute_teacher_id  IS NULL

  ORDER BY ap.slot_id, rank;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION suggest_substitutes(UUID, UUID, DATE) TO authenticated;
