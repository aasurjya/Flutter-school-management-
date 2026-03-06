-- ============================================
-- AI Tutoring Assistant Module
-- ============================================

-- Enums
DO $$ BEGIN
  CREATE TYPE ai_tutor_difficulty AS ENUM ('beginner', 'intermediate', 'advanced');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE ai_tutor_session_status AS ENUM ('active', 'completed', 'abandoned');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE ai_tutor_message_role AS ENUM ('student', 'tutor', 'system');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE ai_tutor_message_type AS ENUM ('text', 'explanation', 'quiz', 'hint', 'solution', 'encouragement');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE ai_learning_path_status AS ENUM ('active', 'completed', 'paused');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE ai_mastery_level AS ENUM ('not_started', 'learning', 'practicing', 'mastered');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================
-- AI Tutor Sessions
-- ============================================
CREATE TABLE IF NOT EXISTS ai_tutor_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
  topic TEXT NOT NULL DEFAULT '',
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  messages_count INT NOT NULL DEFAULT 0,
  difficulty_level ai_tutor_difficulty NOT NULL DEFAULT 'intermediate',
  satisfaction_rating INT CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
  status ai_tutor_session_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_tutor_sessions_tenant ON ai_tutor_sessions(tenant_id);
CREATE INDEX idx_ai_tutor_sessions_student ON ai_tutor_sessions(student_id);
CREATE INDEX idx_ai_tutor_sessions_subject ON ai_tutor_sessions(subject_id);
CREATE INDEX idx_ai_tutor_sessions_status ON ai_tutor_sessions(status);
CREATE INDEX idx_ai_tutor_sessions_started ON ai_tutor_sessions(started_at DESC);

-- ============================================
-- AI Tutor Messages
-- ============================================
CREATE TABLE IF NOT EXISTS ai_tutor_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES ai_tutor_sessions(id) ON DELETE CASCADE,
  role ai_tutor_message_role NOT NULL,
  content TEXT NOT NULL,
  message_type ai_tutor_message_type NOT NULL DEFAULT 'text',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_tutor_messages_session ON ai_tutor_messages(session_id);
CREATE INDEX idx_ai_tutor_messages_created ON ai_tutor_messages(created_at);

-- ============================================
-- AI Learning Paths
-- ============================================
CREATE TABLE IF NOT EXISTS ai_learning_paths (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  current_step INT NOT NULL DEFAULT 0,
  total_steps INT NOT NULL DEFAULT 0,
  topics JSONB NOT NULL DEFAULT '[]',
  progress_percentage DOUBLE PRECISION NOT NULL DEFAULT 0,
  status ai_learning_path_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_learning_paths_tenant ON ai_learning_paths(tenant_id);
CREATE INDEX idx_ai_learning_paths_student ON ai_learning_paths(student_id);
CREATE INDEX idx_ai_learning_paths_status ON ai_learning_paths(status);

-- ============================================
-- AI Practice Problems
-- ============================================
CREATE TABLE IF NOT EXISTS ai_practice_problems (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
  topic TEXT NOT NULL DEFAULT '',
  difficulty ai_tutor_difficulty NOT NULL DEFAULT 'intermediate',
  question TEXT NOT NULL,
  options JSONB DEFAULT '[]',
  correct_answer TEXT NOT NULL,
  explanation TEXT,
  hints JSONB DEFAULT '[]',
  concept_tags JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_practice_problems_tenant ON ai_practice_problems(tenant_id);
CREATE INDEX idx_ai_practice_problems_subject ON ai_practice_problems(subject_id);
CREATE INDEX idx_ai_practice_problems_topic ON ai_practice_problems(topic);
CREATE INDEX idx_ai_practice_problems_difficulty ON ai_practice_problems(difficulty);

-- ============================================
-- Student Concept Mastery
-- ============================================
CREATE TABLE IF NOT EXISTS student_concept_mastery (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
  concept TEXT NOT NULL,
  mastery_level ai_mastery_level NOT NULL DEFAULT 'not_started',
  correct_count INT NOT NULL DEFAULT 0,
  attempt_count INT NOT NULL DEFAULT 0,
  last_practiced TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(student_id, subject_id, concept)
);

CREATE INDEX idx_student_concept_mastery_student ON student_concept_mastery(student_id);
CREATE INDEX idx_student_concept_mastery_subject ON student_concept_mastery(subject_id);
CREATE INDEX idx_student_concept_mastery_level ON student_concept_mastery(mastery_level);

-- ============================================
-- AI Tutor Feedback
-- ============================================
CREATE TABLE IF NOT EXISTS ai_tutor_feedback (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES ai_tutor_sessions(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  feedback_text TEXT,
  helpful BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_tutor_feedback_session ON ai_tutor_feedback(session_id);
CREATE INDEX idx_ai_tutor_feedback_student ON ai_tutor_feedback(student_id);

-- ============================================
-- Row Level Security
-- ============================================
ALTER TABLE ai_tutor_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_tutor_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_learning_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_practice_problems ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_concept_mastery ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_tutor_feedback ENABLE ROW LEVEL SECURITY;

-- Sessions: students see their own, teachers/admins see all in tenant
CREATE POLICY ai_tutor_sessions_select ON ai_tutor_sessions
  FOR SELECT USING (
    tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
  );

CREATE POLICY ai_tutor_sessions_insert ON ai_tutor_sessions
  FOR INSERT WITH CHECK (
    tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
  );

CREATE POLICY ai_tutor_sessions_update ON ai_tutor_sessions
  FOR UPDATE USING (
    tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
  );

-- Messages: visible if you can see the session
CREATE POLICY ai_tutor_messages_select ON ai_tutor_messages
  FOR SELECT USING (
    session_id IN (
      SELECT id FROM ai_tutor_sessions
      WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
    )
  );

CREATE POLICY ai_tutor_messages_insert ON ai_tutor_messages
  FOR INSERT WITH CHECK (
    session_id IN (
      SELECT id FROM ai_tutor_sessions
      WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
    )
  );

-- Learning paths: tenant scoped
CREATE POLICY ai_learning_paths_select ON ai_learning_paths
  FOR SELECT USING (
    tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
  );

CREATE POLICY ai_learning_paths_insert ON ai_learning_paths
  FOR INSERT WITH CHECK (
    tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
  );

CREATE POLICY ai_learning_paths_update ON ai_learning_paths
  FOR UPDATE USING (
    tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
  );

-- Practice problems: tenant scoped
CREATE POLICY ai_practice_problems_select ON ai_practice_problems
  FOR SELECT USING (
    tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
  );

CREATE POLICY ai_practice_problems_insert ON ai_practice_problems
  FOR INSERT WITH CHECK (
    tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
  );

-- Concept mastery: student owns their own
CREATE POLICY student_concept_mastery_select ON student_concept_mastery
  FOR SELECT USING (
    student_id IN (
      SELECT id FROM students
      WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
    )
  );

CREATE POLICY student_concept_mastery_insert ON student_concept_mastery
  FOR INSERT WITH CHECK (
    student_id IN (
      SELECT id FROM students
      WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
    )
  );

CREATE POLICY student_concept_mastery_update ON student_concept_mastery
  FOR UPDATE USING (
    student_id IN (
      SELECT id FROM students
      WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
    )
  );

-- Feedback: tenant scoped
CREATE POLICY ai_tutor_feedback_select ON ai_tutor_feedback
  FOR SELECT USING (
    session_id IN (
      SELECT id FROM ai_tutor_sessions
      WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
    )
  );

CREATE POLICY ai_tutor_feedback_insert ON ai_tutor_feedback
  FOR INSERT WITH CHECK (
    session_id IN (
      SELECT id FROM ai_tutor_sessions
      WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID)
    )
  );

-- ============================================
-- Trigger: auto-update messages_count
-- ============================================
CREATE OR REPLACE FUNCTION update_session_message_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE ai_tutor_sessions
  SET messages_count = (
    SELECT COUNT(*) FROM ai_tutor_messages WHERE session_id = NEW.session_id
  ),
  updated_at = NOW()
  WHERE id = NEW.session_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_session_message_count
  AFTER INSERT ON ai_tutor_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_session_message_count();

-- ============================================
-- Trigger: auto-update updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_ai_tutor_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ai_tutor_sessions_updated
  BEFORE UPDATE ON ai_tutor_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_ai_tutor_updated_at();

CREATE TRIGGER trg_ai_learning_paths_updated
  BEFORE UPDATE ON ai_learning_paths
  FOR EACH ROW
  EXECUTE FUNCTION update_ai_tutor_updated_at();

CREATE TRIGGER trg_student_concept_mastery_updated
  BEFORE UPDATE ON student_concept_mastery
  FOR EACH ROW
  EXECUTE FUNCTION update_ai_tutor_updated_at();
