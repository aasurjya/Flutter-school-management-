-- ============================================================
-- Migration: 00018_report_cards.sql
-- Report Card Generator: templates, grading scales, comments,
-- skills, activities, and generated report cards.
-- ============================================================

-- -------------------------------------------------------
-- ENUM TYPES
-- -------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE report_card_layout AS ENUM (
    'standard', 'detailed', 'competency_based', 'narrative'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE grading_scale_type AS ENUM (
    'percentage', 'letter', 'gpa', 'cgpa'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE report_card_status AS ENUM (
    'draft', 'generated', 'reviewed', 'published', 'sent'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE report_comment_type AS ENUM (
    'class_teacher', 'subject_teacher', 'principal', 'counselor'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE skill_category AS ENUM (
    'leadership', 'teamwork', 'communication', 'creativity',
    'critical_thinking', 'time_management'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE activity_type AS ENUM (
    'sports', 'arts', 'clubs', 'community_service'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE page_size AS ENUM ('A4', 'letter');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE template_section_type AS ENUM (
    'grades', 'attendance', 'behavior', 'teacher_comment',
    'principal_comment', 'skills', 'activities'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- -------------------------------------------------------
-- 1. grading_scales
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS grading_scales (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        grading_scale_type NOT NULL DEFAULT 'percentage',
  scale_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- scale_items: [{grade, min_marks, max_marks, gpa_value, description}]
  is_default  BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_grading_scales_tenant ON grading_scales(tenant_id);

-- -------------------------------------------------------
-- 2. report_card_templates
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS report_card_templates (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  layout          report_card_layout NOT NULL DEFAULT 'standard',
  header_config   JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- header_config: {school_logo, school_name, address, motto, affiliation_no}
  sections        JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- sections: [{type: template_section_type, enabled: bool, order: int, config: {}}]
  grading_scale_id UUID REFERENCES grading_scales(id) ON DELETE SET NULL,
  footer_text     TEXT,
  is_default      BOOLEAN NOT NULL DEFAULT false,
  page_size       page_size NOT NULL DEFAULT 'A4',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_report_card_templates_tenant ON report_card_templates(tenant_id);

-- -------------------------------------------------------
-- 3. report_cards (main generated records)
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS report_cards (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id      UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  term_id         UUID NOT NULL REFERENCES terms(id) ON DELETE CASCADE,
  template_id     UUID NOT NULL REFERENCES report_card_templates(id) ON DELETE RESTRICT,
  exam_ids        JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- exam_ids: [uuid, uuid, ...] -- which exams this report covers
  data            JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- data: full computed snapshot (grades, attendance, etc.)
  status          report_card_status NOT NULL DEFAULT 'draft',
  generated_at    TIMESTAMPTZ,
  reviewed_by     UUID REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at     TIMESTAMPTZ,
  published_at    TIMESTAMPTZ,
  sent_at         TIMESTAMPTZ,
  pdf_url         TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_report_card_student_term
    UNIQUE (tenant_id, student_id, academic_year_id, term_id)
);

CREATE INDEX idx_report_cards_tenant ON report_cards(tenant_id);
CREATE INDEX idx_report_cards_student ON report_cards(student_id);
CREATE INDEX idx_report_cards_status ON report_cards(tenant_id, status);
CREATE INDEX idx_report_cards_academic_year ON report_cards(academic_year_id);
CREATE INDEX idx_report_cards_term ON report_cards(term_id);

-- -------------------------------------------------------
-- 4. report_card_comments
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS report_card_comments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_card_id  UUID NOT NULL REFERENCES report_cards(id) ON DELETE CASCADE,
  comment_type    report_comment_type NOT NULL,
  commented_by    UUID REFERENCES users(id) ON DELETE SET NULL,
  comment_text    TEXT NOT NULL,
  is_ai_generated BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_report_comment_type
    UNIQUE (report_card_id, comment_type)
);

CREATE INDEX idx_report_card_comments_report ON report_card_comments(report_card_id);

-- -------------------------------------------------------
-- 5. report_card_skills
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS report_card_skills (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_card_id  UUID NOT NULL REFERENCES report_cards(id) ON DELETE CASCADE,
  skill_category  skill_category NOT NULL,
  rating          SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comments        TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_report_skill_category
    UNIQUE (report_card_id, skill_category)
);

CREATE INDEX idx_report_card_skills_report ON report_card_skills(report_card_id);

-- -------------------------------------------------------
-- 6. report_card_activities
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS report_card_activities (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_card_id  UUID NOT NULL REFERENCES report_cards(id) ON DELETE CASCADE,
  activity_type   activity_type NOT NULL,
  activity_name   TEXT NOT NULL,
  achievement     TEXT,
  grade           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_report_card_activities_report ON report_card_activities(report_card_id);

-- -------------------------------------------------------
-- TRIGGER: auto-update updated_at
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION update_report_card_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  CREATE TRIGGER trg_grading_scales_updated
    BEFORE UPDATE ON grading_scales
    FOR EACH ROW EXECUTE FUNCTION update_report_card_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TRIGGER trg_report_card_templates_updated
    BEFORE UPDATE ON report_card_templates
    FOR EACH ROW EXECUTE FUNCTION update_report_card_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TRIGGER trg_report_cards_updated
    BEFORE UPDATE ON report_cards
    FOR EACH ROW EXECUTE FUNCTION update_report_card_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TRIGGER trg_report_card_comments_updated
    BEFORE UPDATE ON report_card_comments
    FOR EACH ROW EXECUTE FUNCTION update_report_card_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TRIGGER trg_report_card_skills_updated
    BEFORE UPDATE ON report_card_skills
    FOR EACH ROW EXECUTE FUNCTION update_report_card_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TRIGGER trg_report_card_activities_updated
    BEFORE UPDATE ON report_card_activities
    FOR EACH ROW EXECUTE FUNCTION update_report_card_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- -------------------------------------------------------
-- RLS POLICIES
-- -------------------------------------------------------
ALTER TABLE grading_scales ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_card_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_card_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_card_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_card_activities ENABLE ROW LEVEL SECURITY;

-- Grading scales: read for authenticated, write for admin/teacher
CREATE POLICY grading_scales_select ON grading_scales
  FOR SELECT USING (
    tenant_id IN (
      SELECT ur.tenant_id FROM user_roles ur WHERE ur.user_id = auth.uid()
    )
  );

CREATE POLICY grading_scales_insert ON grading_scales
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = grading_scales.tenant_id
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

CREATE POLICY grading_scales_update ON grading_scales
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = grading_scales.tenant_id
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

CREATE POLICY grading_scales_delete ON grading_scales
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = grading_scales.tenant_id
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

-- Templates: same pattern
CREATE POLICY templates_select ON report_card_templates
  FOR SELECT USING (
    tenant_id IN (
      SELECT ur.tenant_id FROM user_roles ur WHERE ur.user_id = auth.uid()
    )
  );

CREATE POLICY templates_insert ON report_card_templates
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = report_card_templates.tenant_id
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

CREATE POLICY templates_update ON report_card_templates
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = report_card_templates.tenant_id
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

CREATE POLICY templates_delete ON report_card_templates
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = report_card_templates.tenant_id
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

-- Report cards: read for own student/parent/admin/teacher; write for admin/teacher
CREATE POLICY report_cards_select ON report_cards
  FOR SELECT USING (
    -- Admin/teacher in same tenant
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = report_cards.tenant_id
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
    OR
    -- Student viewing own report
    EXISTS (
      SELECT 1 FROM students s
      WHERE s.id = report_cards.student_id
        AND s.user_id = auth.uid()
        AND report_cards.status IN ('published', 'sent')
    )
    OR
    -- Parent viewing child's report
    EXISTS (
      SELECT 1 FROM student_parents sp
      JOIN parents p ON p.id = sp.parent_id
      WHERE sp.student_id = report_cards.student_id
        AND p.user_id = auth.uid()
        AND report_cards.status IN ('published', 'sent')
    )
  );

CREATE POLICY report_cards_insert ON report_cards
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = report_cards.tenant_id
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY report_cards_update ON report_cards
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = report_cards.tenant_id
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY report_cards_delete ON report_cards
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.tenant_id = report_cards.tenant_id
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

-- Comments: same tenant admin/teacher for write; read via report_card access
CREATE POLICY comments_select ON report_card_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM report_cards rc
      WHERE rc.id = report_card_comments.report_card_id
      -- Relies on report_cards RLS for visibility
    )
  );

CREATE POLICY comments_insert ON report_card_comments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM report_cards rc
      JOIN user_roles ur ON ur.tenant_id = rc.tenant_id
      WHERE rc.id = report_card_comments.report_card_id
        AND ur.user_id = auth.uid()
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY comments_update ON report_card_comments
  FOR UPDATE USING (
    report_card_comments.commented_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM report_cards rc
      JOIN user_roles ur ON ur.tenant_id = rc.tenant_id
      WHERE rc.id = report_card_comments.report_card_id
        AND ur.user_id = auth.uid()
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

CREATE POLICY comments_delete ON report_card_comments
  FOR DELETE USING (
    report_card_comments.commented_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM report_cards rc
      JOIN user_roles ur ON ur.tenant_id = rc.tenant_id
      WHERE rc.id = report_card_comments.report_card_id
        AND ur.user_id = auth.uid()
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

-- Skills: tied to report card access
CREATE POLICY skills_select ON report_card_skills
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM report_cards rc WHERE rc.id = report_card_skills.report_card_id)
  );

CREATE POLICY skills_insert ON report_card_skills
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM report_cards rc
      JOIN user_roles ur ON ur.tenant_id = rc.tenant_id
      WHERE rc.id = report_card_skills.report_card_id
        AND ur.user_id = auth.uid()
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY skills_update ON report_card_skills
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM report_cards rc
      JOIN user_roles ur ON ur.tenant_id = rc.tenant_id
      WHERE rc.id = report_card_skills.report_card_id
        AND ur.user_id = auth.uid()
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY skills_delete ON report_card_skills
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM report_cards rc
      JOIN user_roles ur ON ur.tenant_id = rc.tenant_id
      WHERE rc.id = report_card_skills.report_card_id
        AND ur.user_id = auth.uid()
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

-- Activities: same pattern as skills
CREATE POLICY activities_select ON report_card_activities
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM report_cards rc WHERE rc.id = report_card_activities.report_card_id)
  );

CREATE POLICY activities_insert ON report_card_activities
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM report_cards rc
      JOIN user_roles ur ON ur.tenant_id = rc.tenant_id
      WHERE rc.id = report_card_activities.report_card_id
        AND ur.user_id = auth.uid()
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY activities_update ON report_card_activities
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM report_cards rc
      JOIN user_roles ur ON ur.tenant_id = rc.tenant_id
      WHERE rc.id = report_card_activities.report_card_id
        AND ur.user_id = auth.uid()
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY activities_delete ON report_card_activities
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM report_cards rc
      JOIN user_roles ur ON ur.tenant_id = rc.tenant_id
      WHERE rc.id = report_card_activities.report_card_id
        AND ur.user_id = auth.uid()
        AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

-- -------------------------------------------------------
-- VIEW: Report card summary per class for dashboard
-- -------------------------------------------------------
CREATE OR REPLACE VIEW v_report_card_summary AS
SELECT
  rc.tenant_id,
  rc.academic_year_id,
  rc.term_id,
  se.section_id,
  s2.name AS section_name,
  c.id AS class_id,
  c.name AS class_name,
  COUNT(*) AS total_reports,
  COUNT(*) FILTER (WHERE rc.status = 'draft') AS draft_count,
  COUNT(*) FILTER (WHERE rc.status = 'generated') AS generated_count,
  COUNT(*) FILTER (WHERE rc.status = 'reviewed') AS reviewed_count,
  COUNT(*) FILTER (WHERE rc.status = 'published') AS published_count,
  COUNT(*) FILTER (WHERE rc.status = 'sent') AS sent_count
FROM report_cards rc
JOIN students s ON s.id = rc.student_id
JOIN student_enrollments se ON se.student_id = s.id AND se.academic_year_id = rc.academic_year_id
JOIN sections s2 ON s2.id = se.section_id
JOIN classes c ON c.id = s2.class_id
GROUP BY rc.tenant_id, rc.academic_year_id, rc.term_id,
         se.section_id, s2.name, c.id, c.name;
