-- ============================================
-- ONLINE EXAMINATION SYSTEM
-- Migration: 00022_online_exams.sql
-- ============================================

-- ==================== ENUMS ====================

CREATE TYPE online_exam_type AS ENUM (
  'class_test', 'unit_test', 'mid_term', 'final', 'competitive', 'practice'
);

CREATE TYPE online_exam_status AS ENUM (
  'draft', 'scheduled', 'live', 'completed', 'cancelled'
);

CREATE TYPE exam_question_type AS ENUM (
  'mcq', 'multi_select', 'true_false', 'fill_blank',
  'short_answer', 'long_answer', 'match_pairs', 'ordering'
);

CREATE TYPE exam_difficulty AS ENUM ('easy', 'medium', 'hard');

CREATE TYPE exam_attempt_status AS ENUM (
  'in_progress', 'submitted', 'auto_submitted', 'under_review', 'graded'
);

-- ==================== TABLES ====================

-- Online Exams (main table)
CREATE TABLE IF NOT EXISTS online_exams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  exam_type online_exam_type NOT NULL DEFAULT 'class_test',
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  section_ids JSONB DEFAULT '[]'::jsonb,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_marks NUMERIC(8,2) NOT NULL DEFAULT 0,
  passing_marks NUMERIC(8,2) NOT NULL DEFAULT 0,
  duration_minutes INT NOT NULL DEFAULT 60,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  instructions TEXT,
  settings JSONB NOT NULL DEFAULT '{
    "shuffle_questions": true,
    "shuffle_options": true,
    "show_result_immediately": true,
    "allow_review": false,
    "negative_marking_value": 0,
    "max_attempts": 1,
    "proctoring_enabled": false,
    "fullscreen_required": false,
    "tab_switch_limit": 0
  }'::jsonb,
  status online_exam_status NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Exam Sections
CREATE TABLE IF NOT EXISTS exam_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id UUID NOT NULL REFERENCES online_exams(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  sequence_order INT NOT NULL DEFAULT 1,
  question_count INT NOT NULL DEFAULT 0,
  marks_per_question NUMERIC(6,2) NOT NULL DEFAULT 1,
  negative_marks NUMERIC(6,2) NOT NULL DEFAULT 0,
  section_duration_minutes INT,
  is_optional BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Exam Questions
CREATE TABLE IF NOT EXISTS exam_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id UUID NOT NULL REFERENCES exam_sections(id) ON DELETE CASCADE,
  question_bank_id UUID REFERENCES question_bank(id) ON DELETE SET NULL,
  question_type exam_question_type NOT NULL DEFAULT 'mcq',
  question_text TEXT NOT NULL,
  question_media JSONB,
  options JSONB DEFAULT '[]'::jsonb,
  correct_answer JSONB NOT NULL DEFAULT '{}'::jsonb,
  marks NUMERIC(6,2) NOT NULL DEFAULT 1,
  explanation TEXT,
  difficulty exam_difficulty NOT NULL DEFAULT 'medium',
  sequence_order INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Exam Attempts
CREATE TABLE IF NOT EXISTS exam_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  exam_id UUID NOT NULL REFERENCES online_exams(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  attempt_number INT NOT NULL DEFAULT 1,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  submitted_at TIMESTAMPTZ,
  time_taken_seconds INT,
  total_marks_obtained NUMERIC(8,2) DEFAULT 0,
  percentage NUMERIC(5,2) DEFAULT 0,
  status exam_attempt_status NOT NULL DEFAULT 'in_progress',
  proctoring_flags JSONB DEFAULT '[]'::jsonb,
  ip_address TEXT,
  browser_info TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Exam Responses (per question)
CREATE TABLE IF NOT EXISTS exam_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id UUID NOT NULL REFERENCES exam_attempts(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES exam_questions(id) ON DELETE CASCADE,
  response JSONB,
  is_correct BOOLEAN,
  marks_awarded NUMERIC(6,2) DEFAULT 0,
  time_spent_seconds INT DEFAULT 0,
  flagged_for_review BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(attempt_id, question_id)
);

-- ==================== INDEXES ====================

CREATE INDEX idx_online_exams_tenant ON online_exams(tenant_id);
CREATE INDEX idx_online_exams_subject ON online_exams(subject_id);
CREATE INDEX idx_online_exams_class ON online_exams(class_id);
CREATE INDEX idx_online_exams_created_by ON online_exams(created_by);
CREATE INDEX idx_online_exams_status ON online_exams(status);
CREATE INDEX idx_online_exams_start_time ON online_exams(start_time);
CREATE INDEX idx_online_exams_end_time ON online_exams(end_time);

CREATE INDEX idx_exam_sections_exam ON exam_sections(exam_id);
CREATE INDEX idx_exam_sections_order ON exam_sections(exam_id, sequence_order);

CREATE INDEX idx_exam_questions_section ON exam_questions(section_id);
CREATE INDEX idx_exam_questions_bank ON exam_questions(question_bank_id);
CREATE INDEX idx_exam_questions_order ON exam_questions(section_id, sequence_order);
CREATE INDEX idx_exam_questions_type ON exam_questions(question_type);
CREATE INDEX idx_exam_questions_difficulty ON exam_questions(difficulty);

CREATE INDEX idx_exam_attempts_tenant ON exam_attempts(tenant_id);
CREATE INDEX idx_exam_attempts_exam ON exam_attempts(exam_id);
CREATE INDEX idx_exam_attempts_student ON exam_attempts(student_id);
CREATE INDEX idx_exam_attempts_status ON exam_attempts(status);
CREATE INDEX idx_exam_attempts_exam_student ON exam_attempts(exam_id, student_id);

CREATE INDEX idx_exam_responses_attempt ON exam_responses(attempt_id);
CREATE INDEX idx_exam_responses_question ON exam_responses(question_id);
CREATE INDEX idx_exam_responses_flagged ON exam_responses(attempt_id) WHERE flagged_for_review = true;

-- ==================== TRIGGERS ====================

CREATE OR REPLACE FUNCTION update_online_exams_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_online_exams_updated_at
  BEFORE UPDATE ON online_exams
  FOR EACH ROW EXECUTE FUNCTION update_online_exams_updated_at();

CREATE TRIGGER trg_exam_sections_updated_at
  BEFORE UPDATE ON exam_sections
  FOR EACH ROW EXECUTE FUNCTION update_online_exams_updated_at();

CREATE TRIGGER trg_exam_questions_updated_at
  BEFORE UPDATE ON exam_questions
  FOR EACH ROW EXECUTE FUNCTION update_online_exams_updated_at();

CREATE TRIGGER trg_exam_attempts_updated_at
  BEFORE UPDATE ON exam_attempts
  FOR EACH ROW EXECUTE FUNCTION update_online_exams_updated_at();

CREATE TRIGGER trg_exam_responses_updated_at
  BEFORE UPDATE ON exam_responses
  FOR EACH ROW EXECUTE FUNCTION update_online_exams_updated_at();

-- ==================== AUTO-UPDATE SECTION QUESTION COUNT ====================

CREATE OR REPLACE FUNCTION update_section_question_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE exam_sections
    SET question_count = (
      SELECT COUNT(*) FROM exam_questions WHERE section_id = NEW.section_id
    )
    WHERE id = NEW.section_id;
  END IF;
  IF TG_OP = 'DELETE' THEN
    UPDATE exam_sections
    SET question_count = (
      SELECT COUNT(*) FROM exam_questions WHERE section_id = OLD.section_id
    )
    WHERE id = OLD.section_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_exam_questions_count
  AFTER INSERT OR DELETE ON exam_questions
  FOR EACH ROW EXECUTE FUNCTION update_section_question_count();

-- ==================== AUTO-UPDATE EXAM TOTAL MARKS ====================

CREATE OR REPLACE FUNCTION update_exam_total_marks()
RETURNS TRIGGER AS $$
DECLARE
  v_exam_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_exam_id := (SELECT exam_id FROM exam_sections WHERE id = OLD.section_id);
  ELSE
    v_exam_id := (SELECT exam_id FROM exam_sections WHERE id = NEW.section_id);
  END IF;

  UPDATE online_exams
  SET total_marks = COALESCE((
    SELECT SUM(eq.marks)
    FROM exam_questions eq
    JOIN exam_sections es ON es.id = eq.section_id
    WHERE es.exam_id = v_exam_id
  ), 0)
  WHERE id = v_exam_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_exam_total_marks
  AFTER INSERT OR UPDATE OR DELETE ON exam_questions
  FOR EACH ROW EXECUTE FUNCTION update_exam_total_marks();

-- ==================== RLS POLICIES ====================

ALTER TABLE online_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_responses ENABLE ROW LEVEL SECURITY;

-- Online Exams policies
CREATE POLICY "Tenant isolation for online_exams"
  ON online_exams FOR ALL
  USING (tenant_id IN (
    SELECT ur.tenant_id FROM user_roles ur WHERE ur.user_id = auth.uid()
  ));

-- Exam Sections policies
CREATE POLICY "Tenant isolation for exam_sections"
  ON exam_sections FOR ALL
  USING (exam_id IN (
    SELECT oe.id FROM online_exams oe
    WHERE oe.tenant_id IN (
      SELECT ur.tenant_id FROM user_roles ur WHERE ur.user_id = auth.uid()
    )
  ));

-- Exam Questions policies
CREATE POLICY "Tenant isolation for exam_questions"
  ON exam_questions FOR ALL
  USING (section_id IN (
    SELECT es.id FROM exam_sections es
    JOIN online_exams oe ON oe.id = es.exam_id
    WHERE oe.tenant_id IN (
      SELECT ur.tenant_id FROM user_roles ur WHERE ur.user_id = auth.uid()
    )
  ));

-- Exam Attempts policies
CREATE POLICY "Tenant isolation for exam_attempts"
  ON exam_attempts FOR ALL
  USING (tenant_id IN (
    SELECT ur.tenant_id FROM user_roles ur WHERE ur.user_id = auth.uid()
  ));

-- Exam Responses policies
CREATE POLICY "Tenant isolation for exam_responses"
  ON exam_responses FOR ALL
  USING (attempt_id IN (
    SELECT ea.id FROM exam_attempts ea
    WHERE ea.tenant_id IN (
      SELECT ur.tenant_id FROM user_roles ur WHERE ur.user_id = auth.uid()
    )
  ));

-- ==================== ANALYTICS VIEW ====================

CREATE OR REPLACE VIEW v_exam_analytics AS
SELECT
  oe.id AS exam_id,
  oe.tenant_id,
  oe.title AS exam_title,
  oe.subject_id,
  oe.class_id,
  oe.total_marks,
  oe.passing_marks,
  oe.status,
  COUNT(DISTINCT ea.id) AS total_attempts,
  COUNT(DISTINCT ea.student_id) AS unique_students,
  COUNT(DISTINCT ea.id) FILTER (WHERE ea.status = 'graded') AS graded_attempts,
  ROUND(AVG(ea.total_marks_obtained) FILTER (WHERE ea.status = 'graded'), 2) AS avg_score,
  ROUND(MAX(ea.total_marks_obtained) FILTER (WHERE ea.status = 'graded'), 2) AS highest_score,
  ROUND(MIN(ea.total_marks_obtained) FILTER (WHERE ea.status = 'graded'), 2) AS lowest_score,
  ROUND(AVG(ea.percentage) FILTER (WHERE ea.status = 'graded'), 2) AS avg_percentage,
  COUNT(*) FILTER (WHERE ea.status = 'graded' AND ea.percentage >= (oe.passing_marks / NULLIF(oe.total_marks, 0) * 100)) AS pass_count,
  COUNT(*) FILTER (WHERE ea.status = 'graded' AND ea.percentage < (oe.passing_marks / NULLIF(oe.total_marks, 0) * 100)) AS fail_count,
  ROUND(AVG(ea.time_taken_seconds) FILTER (WHERE ea.status IN ('submitted', 'auto_submitted', 'graded')), 0) AS avg_time_seconds,
  COUNT(*) FILTER (WHERE ea.status = 'in_progress') AS in_progress_count
FROM online_exams oe
LEFT JOIN exam_attempts ea ON ea.exam_id = oe.id
GROUP BY oe.id, oe.tenant_id, oe.title, oe.subject_id, oe.class_id, oe.total_marks, oe.passing_marks, oe.status;

-- Question-wise analytics view
CREATE OR REPLACE VIEW v_exam_question_analytics AS
SELECT
  eq.id AS question_id,
  es.exam_id,
  eq.question_text,
  eq.question_type,
  eq.marks,
  eq.difficulty,
  COUNT(er.id) AS total_responses,
  COUNT(*) FILTER (WHERE er.is_correct = true) AS correct_count,
  COUNT(*) FILTER (WHERE er.is_correct = false) AS incorrect_count,
  ROUND(AVG(er.marks_awarded), 2) AS avg_marks,
  ROUND(AVG(er.time_spent_seconds), 0) AS avg_time_seconds,
  CASE WHEN COUNT(er.id) > 0
    THEN ROUND((COUNT(*) FILTER (WHERE er.is_correct = true))::numeric / COUNT(er.id) * 100, 2)
    ELSE 0
  END AS accuracy_rate
FROM exam_questions eq
JOIN exam_sections es ON es.id = eq.section_id
LEFT JOIN exam_responses er ON er.question_id = eq.id
GROUP BY eq.id, es.exam_id, eq.question_text, eq.question_type, eq.marks, eq.difficulty;
