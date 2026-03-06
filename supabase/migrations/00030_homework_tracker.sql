-- ============================================================
-- Homework Tracker
-- ============================================================

-- Homework assignments table
CREATE TABLE IF NOT EXISTS homework (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  instructions TEXT,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
  assigned_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'closed')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  max_marks INTEGER,
  allow_late_submission BOOLEAN DEFAULT FALSE,
  attachment_urls JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Homework submissions table
CREATE TABLE IF NOT EXISTS homework_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  homework_id UUID NOT NULL REFERENCES homework(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  content TEXT,
  attachment_urls JSONB DEFAULT '[]'::jsonb,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'late', 'graded', 'returned')),
  submitted_at TIMESTAMPTZ,
  marks INTEGER,
  feedback TEXT,
  graded_by UUID REFERENCES users(id),
  graded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(homework_id, student_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_homework_tenant ON homework(tenant_id);
CREATE INDEX IF NOT EXISTS idx_homework_section ON homework(section_id);
CREATE INDEX IF NOT EXISTS idx_homework_subject ON homework(subject_id);
CREATE INDEX IF NOT EXISTS idx_homework_assigned_by ON homework(assigned_by);
CREATE INDEX IF NOT EXISTS idx_homework_due_date ON homework(due_date);
CREATE INDEX IF NOT EXISTS idx_homework_status ON homework(status);
CREATE INDEX IF NOT EXISTS idx_homework_submissions_homework ON homework_submissions(homework_id);
CREATE INDEX IF NOT EXISTS idx_homework_submissions_student ON homework_submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_homework_submissions_status ON homework_submissions(status);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_homework_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER homework_updated_at
  BEFORE UPDATE ON homework
  FOR EACH ROW EXECUTE FUNCTION update_homework_updated_at();

CREATE TRIGGER homework_submissions_updated_at
  BEFORE UPDATE ON homework_submissions
  FOR EACH ROW EXECUTE FUNCTION update_homework_updated_at();

-- RLS Policies
ALTER TABLE homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE homework_submissions ENABLE ROW LEVEL SECURITY;

-- Teachers and admins can manage homework for their tenant
CREATE POLICY homework_tenant_policy ON homework
  FOR ALL USING (
    tenant_id = (current_setting('request.jwt.claims', true)::json->>'tenant_id')::uuid
  );

-- Students can view published homework for their sections
CREATE POLICY homework_student_view ON homework
  FOR SELECT USING (
    status = 'published' AND
    tenant_id = (current_setting('request.jwt.claims', true)::json->>'tenant_id')::uuid
  );

-- Submissions: students can manage their own, teachers can view all for their homework
CREATE POLICY submissions_student_policy ON homework_submissions
  FOR ALL USING (
    student_id = auth.uid() OR
    homework_id IN (
      SELECT id FROM homework WHERE assigned_by = auth.uid()
    )
  );

CREATE POLICY submissions_tenant_policy ON homework_submissions
  FOR SELECT USING (
    homework_id IN (
      SELECT id FROM homework
      WHERE tenant_id = (current_setting('request.jwt.claims', true)::json->>'tenant_id')::uuid
    )
  );
