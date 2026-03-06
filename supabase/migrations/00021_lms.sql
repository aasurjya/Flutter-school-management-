-- ============================================================
-- LMS (Learning Management System) Module
-- Migration: 00021_lms.sql
-- ============================================================

-- ============================================
-- ENUMS
-- ============================================

CREATE TYPE lms_course_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE lms_content_type AS ENUM ('video', 'document', 'presentation', 'link', 'text', 'quiz', 'assignment');
CREATE TYPE lms_enrollment_status AS ENUM ('enrolled', 'in_progress', 'completed', 'dropped');
CREATE TYPE lms_content_progress_status AS ENUM ('not_started', 'in_progress', 'completed');

-- ============================================
-- TABLES
-- ============================================

-- Courses
CREATE TABLE IF NOT EXISTS courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
  class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
  teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  thumbnail_url TEXT,
  status lms_course_status NOT NULL DEFAULT 'draft',
  is_self_paced BOOLEAN NOT NULL DEFAULT false,
  start_date DATE,
  end_date DATE,
  enrollment_limit INT,
  tags JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Course Modules
CREATE TABLE IF NOT EXISTS course_modules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  sequence_order INT NOT NULL DEFAULT 0,
  duration_minutes INT DEFAULT 0,
  is_locked BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Module Content
CREATE TABLE IF NOT EXISTS module_content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  module_id UUID NOT NULL REFERENCES course_modules(id) ON DELETE CASCADE,
  content_type lms_content_type NOT NULL DEFAULT 'text',
  title TEXT NOT NULL,
  content_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  sequence_order INT NOT NULL DEFAULT 0,
  is_mandatory BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Course Enrollments
CREATE TABLE IF NOT EXISTS course_enrollments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  progress_percentage NUMERIC(5,2) NOT NULL DEFAULT 0,
  status lms_enrollment_status NOT NULL DEFAULT 'enrolled',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(course_id, student_id)
);

-- Content Progress
CREATE TABLE IF NOT EXISTS content_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  enrollment_id UUID NOT NULL REFERENCES course_enrollments(id) ON DELETE CASCADE,
  content_id UUID NOT NULL REFERENCES module_content(id) ON DELETE CASCADE,
  status lms_content_progress_status NOT NULL DEFAULT 'not_started',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  time_spent_seconds INT NOT NULL DEFAULT 0,
  score NUMERIC(5,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(enrollment_id, content_id)
);

-- Discussion Forums
CREATE TABLE IF NOT EXISTS discussion_forums (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_pinned BOOLEAN NOT NULL DEFAULT false,
  is_locked BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Forum Posts
CREATE TABLE IF NOT EXISTS forum_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  forum_id UUID NOT NULL REFERENCES discussion_forums(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_answer BOOLEAN NOT NULL DEFAULT false,
  upvotes INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Course Certificates
CREATE TABLE IF NOT EXISTS course_certificates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  enrollment_id UUID NOT NULL REFERENCES course_enrollments(id) ON DELETE CASCADE,
  certificate_number TEXT NOT NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  template_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(enrollment_id),
  UNIQUE(tenant_id, certificate_number)
);

-- ============================================
-- INDEXES
-- ============================================

-- Courses
CREATE INDEX idx_courses_tenant ON courses(tenant_id);
CREATE INDEX idx_courses_teacher ON courses(teacher_id);
CREATE INDEX idx_courses_status ON courses(tenant_id, status);
CREATE INDEX idx_courses_subject ON courses(subject_id);
CREATE INDEX idx_courses_class ON courses(class_id);

-- Modules
CREATE INDEX idx_course_modules_tenant ON course_modules(tenant_id);
CREATE INDEX idx_course_modules_course ON course_modules(course_id);
CREATE INDEX idx_course_modules_order ON course_modules(course_id, sequence_order);

-- Content
CREATE INDEX idx_module_content_tenant ON module_content(tenant_id);
CREATE INDEX idx_module_content_module ON module_content(module_id);
CREATE INDEX idx_module_content_order ON module_content(module_id, sequence_order);

-- Enrollments
CREATE INDEX idx_course_enrollments_tenant ON course_enrollments(tenant_id);
CREATE INDEX idx_course_enrollments_course ON course_enrollments(course_id);
CREATE INDEX idx_course_enrollments_student ON course_enrollments(student_id);
CREATE INDEX idx_course_enrollments_status ON course_enrollments(tenant_id, status);

-- Progress
CREATE INDEX idx_content_progress_tenant ON content_progress(tenant_id);
CREATE INDEX idx_content_progress_enrollment ON content_progress(enrollment_id);
CREATE INDEX idx_content_progress_content ON content_progress(content_id);

-- Forums
CREATE INDEX idx_discussion_forums_tenant ON discussion_forums(tenant_id);
CREATE INDEX idx_discussion_forums_course ON discussion_forums(course_id);

-- Posts
CREATE INDEX idx_forum_posts_tenant ON forum_posts(tenant_id);
CREATE INDEX idx_forum_posts_forum ON forum_posts(forum_id);
CREATE INDEX idx_forum_posts_author ON forum_posts(author_id);
CREATE INDEX idx_forum_posts_parent ON forum_posts(parent_post_id);
CREATE INDEX idx_forum_posts_created ON forum_posts(forum_id, created_at DESC);

-- Certificates
CREATE INDEX idx_course_certificates_tenant ON course_certificates(tenant_id);
CREATE INDEX idx_course_certificates_enrollment ON course_certificates(enrollment_id);

-- ============================================
-- TRIGGERS: auto-update updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_lms_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_courses_updated_at
  BEFORE UPDATE ON courses
  FOR EACH ROW EXECUTE FUNCTION update_lms_updated_at();

CREATE TRIGGER trg_course_modules_updated_at
  BEFORE UPDATE ON course_modules
  FOR EACH ROW EXECUTE FUNCTION update_lms_updated_at();

CREATE TRIGGER trg_module_content_updated_at
  BEFORE UPDATE ON module_content
  FOR EACH ROW EXECUTE FUNCTION update_lms_updated_at();

CREATE TRIGGER trg_course_enrollments_updated_at
  BEFORE UPDATE ON course_enrollments
  FOR EACH ROW EXECUTE FUNCTION update_lms_updated_at();

CREATE TRIGGER trg_content_progress_updated_at
  BEFORE UPDATE ON content_progress
  FOR EACH ROW EXECUTE FUNCTION update_lms_updated_at();

CREATE TRIGGER trg_discussion_forums_updated_at
  BEFORE UPDATE ON discussion_forums
  FOR EACH ROW EXECUTE FUNCTION update_lms_updated_at();

CREATE TRIGGER trg_forum_posts_updated_at
  BEFORE UPDATE ON forum_posts
  FOR EACH ROW EXECUTE FUNCTION update_lms_updated_at();

CREATE TRIGGER trg_course_certificates_updated_at
  BEFORE UPDATE ON course_certificates
  FOR EACH ROW EXECUTE FUNCTION update_lms_updated_at();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_forums ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_certificates ENABLE ROW LEVEL SECURITY;

-- Courses: tenant members can view published; teachers/admins can manage
CREATE POLICY courses_select ON courses FOR SELECT
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

CREATE POLICY courses_insert ON courses FOR INSERT
  WITH CHECK (
    tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid
    AND has_role(auth.uid(), tenant_id, 'teacher')
  );

CREATE POLICY courses_update ON courses FOR UPDATE
  USING (
    tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid
    AND (teacher_id = auth.uid() OR has_role(auth.uid(), tenant_id, 'tenant_admin'))
  );

CREATE POLICY courses_delete ON courses FOR DELETE
  USING (
    tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid
    AND (teacher_id = auth.uid() OR has_role(auth.uid(), tenant_id, 'tenant_admin'))
  );

-- Course Modules: same tenant access
CREATE POLICY course_modules_select ON course_modules FOR SELECT
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

CREATE POLICY course_modules_manage ON course_modules FOR ALL
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

-- Module Content: same tenant access
CREATE POLICY module_content_select ON module_content FOR SELECT
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

CREATE POLICY module_content_manage ON module_content FOR ALL
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

-- Course Enrollments: same tenant access
CREATE POLICY course_enrollments_select ON course_enrollments FOR SELECT
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

CREATE POLICY course_enrollments_manage ON course_enrollments FOR ALL
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

-- Content Progress: same tenant access
CREATE POLICY content_progress_select ON content_progress FOR SELECT
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

CREATE POLICY content_progress_manage ON content_progress FOR ALL
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

-- Discussion Forums: same tenant access
CREATE POLICY discussion_forums_select ON discussion_forums FOR SELECT
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

CREATE POLICY discussion_forums_manage ON discussion_forums FOR ALL
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

-- Forum Posts: same tenant access
CREATE POLICY forum_posts_select ON forum_posts FOR SELECT
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

CREATE POLICY forum_posts_manage ON forum_posts FOR ALL
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

-- Certificates: same tenant access
CREATE POLICY course_certificates_select ON course_certificates FOR SELECT
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

CREATE POLICY course_certificates_manage ON course_certificates FOR ALL
  USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::uuid);

-- ============================================
-- VIEWS
-- ============================================

CREATE OR REPLACE VIEW v_course_enrollment_stats AS
SELECT
  c.id AS course_id,
  c.tenant_id,
  c.title,
  c.status,
  COUNT(ce.id) AS total_enrolled,
  COUNT(ce.id) FILTER (WHERE ce.status = 'completed') AS total_completed,
  COUNT(ce.id) FILTER (WHERE ce.status = 'in_progress') AS total_in_progress,
  COUNT(ce.id) FILTER (WHERE ce.status = 'dropped') AS total_dropped,
  COALESCE(AVG(ce.progress_percentage), 0) AS avg_progress
FROM courses c
LEFT JOIN course_enrollments ce ON c.id = ce.course_id
GROUP BY c.id, c.tenant_id, c.title, c.status;
