-- ============================================================
-- Migration 00016: Discipline / Behavior Management
-- ============================================================

-- ─── ENUMS ──────────────────────────────────────────────────
CREATE TYPE behavior_category_type AS ENUM ('positive', 'negative');

CREATE TYPE incident_severity AS ENUM ('minor', 'moderate', 'major', 'critical');

CREATE TYPE incident_status AS ENUM ('reported', 'investigating', 'resolved', 'escalated');

CREATE TYPE behavior_action_type AS ENUM (
  'verbal_warning',
  'written_warning',
  'detention',
  'suspension',
  'expulsion',
  'counseling',
  'parent_meeting',
  'community_service'
);

CREATE TYPE behavior_plan_status AS ENUM ('active', 'completed', 'discontinued');

-- ─── BEHAVIOR CATEGORIES ────────────────────────────────────
CREATE TABLE behavior_categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        behavior_category_type NOT NULL,
  points      INT NOT NULL DEFAULT 0,
  icon        TEXT,          -- icon name / codepoint
  color       TEXT,          -- hex color string
  description TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_behavior_categories_tenant ON behavior_categories(tenant_id);
CREATE INDEX idx_behavior_categories_type   ON behavior_categories(tenant_id, type);

-- ─── BEHAVIOR INCIDENTS ─────────────────────────────────────
CREATE TABLE behavior_incidents (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id     UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  reported_by    UUID NOT NULL REFERENCES users(id),
  category_id    UUID REFERENCES behavior_categories(id),
  incident_date  DATE NOT NULL DEFAULT CURRENT_DATE,
  incident_time  TIME,
  description    TEXT NOT NULL,
  severity       incident_severity NOT NULL DEFAULT 'minor',
  location       TEXT,
  witnesses      JSONB DEFAULT '[]'::jsonb,
  evidence_urls  JSONB DEFAULT '[]'::jsonb,
  status         incident_status NOT NULL DEFAULT 'reported',
  resolution_notes TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_behavior_incidents_tenant   ON behavior_incidents(tenant_id);
CREATE INDEX idx_behavior_incidents_student  ON behavior_incidents(student_id);
CREATE INDEX idx_behavior_incidents_date     ON behavior_incidents(tenant_id, incident_date DESC);
CREATE INDEX idx_behavior_incidents_severity ON behavior_incidents(tenant_id, severity);
CREATE INDEX idx_behavior_incidents_status   ON behavior_incidents(tenant_id, status);
CREATE INDEX idx_behavior_incidents_reporter ON behavior_incidents(reported_by);

-- ─── BEHAVIOR ACTIONS ───────────────────────────────────────
CREATE TABLE behavior_actions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id  UUID NOT NULL REFERENCES behavior_incidents(id) ON DELETE CASCADE,
  action_type  behavior_action_type NOT NULL,
  assigned_by  UUID NOT NULL REFERENCES users(id),
  assigned_to  UUID REFERENCES users(id),  -- e.g. counselor
  start_date   DATE,
  end_date     DATE,
  notes        TEXT,
  completed    BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_behavior_actions_incident ON behavior_actions(incident_id);
CREATE INDEX idx_behavior_actions_type     ON behavior_actions(action_type);

-- ─── BEHAVIOR PLANS (IMPROVEMENT PLANS) ─────────────────────
CREATE TABLE behavior_plans (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  created_by            UUID NOT NULL REFERENCES users(id),
  title                 TEXT NOT NULL,
  description           TEXT,
  goals                 JSONB NOT NULL DEFAULT '[]'::jsonb,
  strategies            JSONB NOT NULL DEFAULT '[]'::jsonb,
  start_date            DATE NOT NULL DEFAULT CURRENT_DATE,
  review_date           DATE,
  status                behavior_plan_status NOT NULL DEFAULT 'active',
  parent_acknowledged   BOOLEAN NOT NULL DEFAULT FALSE,
  parent_acknowledged_at TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_behavior_plans_tenant  ON behavior_plans(tenant_id);
CREATE INDEX idx_behavior_plans_student ON behavior_plans(student_id);
CREATE INDEX idx_behavior_plans_status  ON behavior_plans(tenant_id, status);

-- ─── BEHAVIOR PLAN REVIEWS ──────────────────────────────────
CREATE TABLE behavior_plan_reviews (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id          UUID NOT NULL REFERENCES behavior_plans(id) ON DELETE CASCADE,
  reviewed_by      UUID NOT NULL REFERENCES users(id),
  review_date      DATE NOT NULL DEFAULT CURRENT_DATE,
  progress_notes   TEXT,
  goal_progress    JSONB DEFAULT '{}'::jsonb,
  outcome          TEXT,  -- 'improving', 'no_change', 'worsening'
  next_review_date DATE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_plan_reviews_plan ON behavior_plan_reviews(plan_id);

-- ─── POSITIVE RECOGNITIONS ──────────────────────────────────
CREATE TABLE positive_recognitions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id      UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  recognized_by   UUID NOT NULL REFERENCES users(id),
  category_id     UUID REFERENCES behavior_categories(id),
  description     TEXT NOT NULL,
  points_awarded  INT NOT NULL DEFAULT 0,
  is_public       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_positive_recognitions_tenant  ON positive_recognitions(tenant_id);
CREATE INDEX idx_positive_recognitions_student ON positive_recognitions(student_id);
CREATE INDEX idx_positive_recognitions_date    ON positive_recognitions(tenant_id, created_at DESC);

-- ─── DETENTION SCHEDULES ────────────────────────────────────
CREATE TABLE detention_schedules (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  day_of_week   INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Mon … 6=Sun
  start_time    TIME NOT NULL,
  end_time      TIME NOT NULL,
  location      TEXT NOT NULL,
  supervisor_id UUID REFERENCES users(id),
  capacity      INT NOT NULL DEFAULT 30,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_detention_schedules_tenant ON detention_schedules(tenant_id);

-- ─── DETENTION ASSIGNMENTS ──────────────────────────────────
CREATE TABLE detention_assignments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id          UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  incident_id         UUID REFERENCES behavior_incidents(id),
  schedule_id         UUID REFERENCES detention_schedules(id),
  detention_date      DATE NOT NULL,
  assigned_by         UUID NOT NULL REFERENCES users(id),
  status              TEXT NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned', 'served', 'missed', 'excused')),
  notes               TEXT,
  check_in_time       TIMESTAMPTZ,
  check_out_time      TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_detention_assignments_tenant  ON detention_assignments(tenant_id);
CREATE INDEX idx_detention_assignments_student ON detention_assignments(student_id);
CREATE INDEX idx_detention_assignments_date    ON detention_assignments(tenant_id, detention_date);

-- ─── RLS POLICIES ───────────────────────────────────────────
ALTER TABLE behavior_categories    ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_incidents     ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_actions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_plans         ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_plan_reviews  ENABLE ROW LEVEL SECURITY;
ALTER TABLE positive_recognitions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE detention_schedules    ENABLE ROW LEVEL SECURITY;
ALTER TABLE detention_assignments  ENABLE ROW LEVEL SECURITY;

-- Tenant-scoped read for authenticated users
CREATE POLICY "Tenant isolation - behavior_categories"
  ON behavior_categories FOR ALL
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

CREATE POLICY "Tenant isolation - behavior_incidents"
  ON behavior_incidents FOR ALL
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

CREATE POLICY "Tenant isolation - behavior_actions"
  ON behavior_actions FOR ALL
  USING (incident_id IN (
    SELECT id FROM behavior_incidents
    WHERE tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
  ));

CREATE POLICY "Tenant isolation - behavior_plans"
  ON behavior_plans FOR ALL
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

CREATE POLICY "Tenant isolation - behavior_plan_reviews"
  ON behavior_plan_reviews FOR ALL
  USING (plan_id IN (
    SELECT id FROM behavior_plans
    WHERE tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
  ));

CREATE POLICY "Tenant isolation - positive_recognitions"
  ON positive_recognitions FOR ALL
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

CREATE POLICY "Tenant isolation - detention_schedules"
  ON detention_schedules FOR ALL
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

CREATE POLICY "Tenant isolation - detention_assignments"
  ON detention_assignments FOR ALL
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ─── ANALYTICS VIEW ─────────────────────────────────────────
CREATE OR REPLACE VIEW v_student_behavior_score AS
SELECT
  s.id AS student_id,
  s.tenant_id,
  COALESCE(pos.total_positive, 0) AS positive_points,
  COALESCE(neg.total_negative, 0) AS negative_points,
  COALESCE(pos.total_positive, 0) - COALESCE(neg.total_negative, 0) AS net_score,
  COALESCE(inc.incident_count, 0) AS incident_count,
  COALESCE(rec.recognition_count, 0) AS recognition_count
FROM students s
LEFT JOIN LATERAL (
  SELECT SUM(points_awarded) AS total_positive
  FROM positive_recognitions pr
  WHERE pr.student_id = s.id
) pos ON TRUE
LEFT JOIN LATERAL (
  SELECT SUM(bc.points) AS total_negative
  FROM behavior_incidents bi
  JOIN behavior_categories bc ON bc.id = bi.category_id
  WHERE bi.student_id = s.id
    AND bc.type = 'negative'
    AND bi.status IN ('reported', 'resolved')
) neg ON TRUE
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS incident_count
  FROM behavior_incidents bi2
  WHERE bi2.student_id = s.id
) inc ON TRUE
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS recognition_count
  FROM positive_recognitions pr2
  WHERE pr2.student_id = s.id
) rec ON TRUE;

-- ─── TRIGGERS: updated_at ───────────────────────────────────
CREATE OR REPLACE FUNCTION update_discipline_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_behavior_categories_updated
  BEFORE UPDATE ON behavior_categories
  FOR EACH ROW EXECUTE FUNCTION update_discipline_updated_at();

CREATE TRIGGER trg_behavior_incidents_updated
  BEFORE UPDATE ON behavior_incidents
  FOR EACH ROW EXECUTE FUNCTION update_discipline_updated_at();

CREATE TRIGGER trg_behavior_actions_updated
  BEFORE UPDATE ON behavior_actions
  FOR EACH ROW EXECUTE FUNCTION update_discipline_updated_at();

CREATE TRIGGER trg_behavior_plans_updated
  BEFORE UPDATE ON behavior_plans
  FOR EACH ROW EXECUTE FUNCTION update_discipline_updated_at();

CREATE TRIGGER trg_detention_schedules_updated
  BEFORE UPDATE ON detention_schedules
  FOR EACH ROW EXECUTE FUNCTION update_discipline_updated_at();

CREATE TRIGGER trg_detention_assignments_updated
  BEFORE UPDATE ON detention_assignments
  FOR EACH ROW EXECUTE FUNCTION update_discipline_updated_at();
