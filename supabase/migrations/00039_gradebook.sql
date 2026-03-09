-- Gradebook: grading categories and grade entries
-- Supports weighted categories (Homework 20%, Quizzes 30%, Exams 50%)

CREATE TABLE IF NOT EXISTS grading_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  class_subject_id uuid REFERENCES class_subjects(id),
  name text NOT NULL,  -- 'Homework', 'Quiz', 'Midterm', 'Final'
  weight numeric(5,2) NOT NULL DEFAULT 100,  -- percentage weight
  drop_lowest integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Grade entries (individual assignments/assessments)
CREATE TABLE IF NOT EXISTS grade_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  category_id uuid REFERENCES grading_categories(id) ON DELETE CASCADE,
  student_id uuid REFERENCES students(id) ON DELETE CASCADE,
  title text NOT NULL,
  points_earned numeric(10,2),
  points_possible numeric(10,2) NOT NULL,
  graded_at date DEFAULT CURRENT_DATE,
  notes text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE grading_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_isolation" ON grading_categories
  USING ((auth.jwt()->'app_metadata'->>'tenant_id')::uuid = tenant_id);

CREATE POLICY "tenant_isolation" ON grade_entries
  USING ((auth.jwt()->'app_metadata'->>'tenant_id')::uuid = tenant_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_grading_categories_class_subject
  ON grading_categories(class_subject_id);

CREATE INDEX IF NOT EXISTS idx_grade_entries_category
  ON grade_entries(category_id);

CREATE INDEX IF NOT EXISTS idx_grade_entries_student
  ON grade_entries(student_id);

CREATE INDEX IF NOT EXISTS idx_grade_entries_category_student
  ON grade_entries(category_id, student_id);
