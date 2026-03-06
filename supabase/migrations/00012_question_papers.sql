-- ============================================================
-- Migration: 00012_question_papers
-- Feature: AI Question Paper Generator
-- ============================================================

-- Enums
DO $$ BEGIN
  CREATE TYPE question_type AS ENUM (
    'mcq', 'short_answer', 'long_answer', 'true_false',
    'fill_blank', 'match_following', 'diagram'
  );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE difficulty_level AS ENUM ('easy', 'medium', 'hard');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE paper_status AS ENUM ('draft', 'published', 'archived');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ============================================================
-- question_papers — master record
-- ============================================================
CREATE TABLE IF NOT EXISTS question_papers (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title             TEXT NOT NULL,
  subject_id        UUID REFERENCES subjects(id),
  class_id          UUID REFERENCES classes(id),
  academic_year_id  UUID REFERENCES academic_years(id),
  exam_type         TEXT NOT NULL DEFAULT 'unit_test',  -- unit_test, mid_term, final, practice
  difficulty        difficulty_level NOT NULL DEFAULT 'medium',
  total_marks       INTEGER NOT NULL DEFAULT 100,
  duration_minutes  INTEGER NOT NULL DEFAULT 180,
  instructions      TEXT,
  is_ai_generated   BOOLEAN NOT NULL DEFAULT FALSE,
  ai_prompt_context JSONB,
  status            paper_status NOT NULL DEFAULT 'draft',
  created_by        UUID REFERENCES users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- question_paper_sections — e.g. Section A, Section B
-- ============================================================
CREATE TABLE IF NOT EXISTS question_paper_sections (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id     UUID NOT NULL REFERENCES question_papers(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  instructions TEXT,
  total_marks  INTEGER NOT NULL DEFAULT 0,
  sequence_order INTEGER NOT NULL DEFAULT 1,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- question_paper_items — individual questions
-- ============================================================
CREATE TABLE IF NOT EXISTS question_paper_items (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id         UUID NOT NULL REFERENCES question_papers(id) ON DELETE CASCADE,
  section_id       UUID REFERENCES question_paper_sections(id) ON DELETE CASCADE,
  question_bank_id UUID REFERENCES question_bank(id),  -- optional link
  question_text    TEXT NOT NULL,
  question_type    question_type NOT NULL DEFAULT 'multiple_choice',
  marks            NUMERIC(5,2) NOT NULL DEFAULT 1,
  difficulty       difficulty_level NOT NULL DEFAULT 'medium',
  options          JSONB,   -- array of strings for MCQ/true-false
  correct_answer   TEXT,    -- kept server-side (not sent to students)
  explanation      TEXT,
  image_url        TEXT,
  sequence_order   INTEGER NOT NULL DEFAULT 1,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_question_papers_tenant
  ON question_papers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_question_papers_subject_class
  ON question_papers(subject_id, class_id);
CREATE INDEX IF NOT EXISTS idx_question_papers_status
  ON question_papers(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_qp_sections_paper
  ON question_paper_sections(paper_id);
CREATE INDEX IF NOT EXISTS idx_qp_items_paper
  ON question_paper_items(paper_id);
CREATE INDEX IF NOT EXISTS idx_qp_items_section
  ON question_paper_items(section_id);

-- ============================================================
-- updated_at trigger
-- ============================================================
CREATE OR REPLACE FUNCTION update_question_papers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_question_papers_updated_at ON question_papers;
CREATE TRIGGER trg_question_papers_updated_at
  BEFORE UPDATE ON question_papers
  FOR EACH ROW EXECUTE FUNCTION update_question_papers_updated_at();

-- ============================================================
-- has_role 2-arg overload (needed for policies below)
-- ============================================================
CREATE OR REPLACE FUNCTION public.has_role(p_user_id uuid, p_role text)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = p_user_id AND role = p_role::user_role
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.has_role(p_user_id uuid, p_tenant_id uuid, p_role text)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = p_user_id AND role = p_role::user_role
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ============================================================
-- RLS
-- ============================================================
ALTER TABLE question_papers ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_paper_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_paper_items ENABLE ROW LEVEL SECURITY;

-- Teachers and admins can read papers in their tenant
CREATE POLICY "question_papers_select" ON question_papers
  FOR SELECT USING (tenant_id = (
    SELECT tenant_id FROM users WHERE id = auth.uid()
  ));

CREATE POLICY "question_papers_insert" ON question_papers
  FOR INSERT WITH CHECK (tenant_id = (
    SELECT tenant_id FROM users WHERE id = auth.uid()
  ));

CREATE POLICY "question_papers_update" ON question_papers
  FOR UPDATE USING (
    created_by = auth.uid()
    OR has_role(auth.uid(), 'tenant_admin')
    OR has_role(auth.uid(), 'principal')
  );

CREATE POLICY "question_papers_delete" ON question_papers
  FOR DELETE USING (
    created_by = auth.uid()
    OR has_role(auth.uid(), 'tenant_admin')
    OR has_role(auth.uid(), 'principal')
  );

-- Sections follow parent paper's RLS
CREATE POLICY "qp_sections_select" ON question_paper_sections
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM question_papers qp
    WHERE qp.id = paper_id
    AND qp.tenant_id = (SELECT tenant_id FROM users WHERE id = auth.uid())
  ));

CREATE POLICY "qp_sections_all" ON question_paper_sections
  FOR ALL USING (EXISTS (
    SELECT 1 FROM question_papers qp
    WHERE qp.id = paper_id
    AND qp.tenant_id = (SELECT tenant_id FROM users WHERE id = auth.uid())
  ));

-- Items follow parent paper's RLS
CREATE POLICY "qp_items_select" ON question_paper_items
  FOR SELECT USING (EXISTS (
    SELECT 1 FROM question_papers qp
    WHERE qp.id = paper_id
    AND qp.tenant_id = (SELECT tenant_id FROM users WHERE id = auth.uid())
  ));

CREATE POLICY "qp_items_all" ON question_paper_items
  FOR ALL USING (EXISTS (
    SELECT 1 FROM question_papers qp
    WHERE qp.id = paper_id
    AND qp.tenant_id = (SELECT tenant_id FROM users WHERE id = auth.uid())
  ));
