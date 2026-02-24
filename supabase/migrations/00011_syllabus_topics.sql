-- ============================================================
-- Migration: Syllabus Topics Feature Ecosystem
-- Description: Hierarchical topic tree, coverage tracking,
--              lesson plans, and topic-resource linking.
-- ============================================================

-- -----------------------------------------------------------
-- ENUMS
-- -----------------------------------------------------------

CREATE TYPE topic_level AS ENUM ('unit', 'chapter', 'topic', 'subtopic');
CREATE TYPE topic_status AS ENUM ('not_started', 'in_progress', 'completed', 'skipped');
CREATE TYPE lesson_plan_status AS ENUM ('draft', 'ready', 'delivered', 'archived');
CREATE TYPE topic_entity_type AS ENUM ('assignment', 'quiz', 'question_bank', 'study_resource', 'exam_subject');

-- -----------------------------------------------------------
-- TABLE: syllabus_topics
-- -----------------------------------------------------------

CREATE TABLE syllabus_topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    parent_topic_id UUID REFERENCES syllabus_topics(id) ON DELETE CASCADE,
    level topic_level NOT NULL DEFAULT 'topic',
    sequence_order INT NOT NULL DEFAULT 0,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    learning_objectives TEXT[] DEFAULT '{}',
    estimated_periods INT DEFAULT 1,
    term_id UUID REFERENCES terms(id) ON DELETE SET NULL,
    tags TEXT[] DEFAULT '{}',
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(tenant_id, subject_id, class_id, academic_year_id, parent_topic_id, sequence_order)
);

-- -----------------------------------------------------------
-- TABLE: topic_coverage
-- -----------------------------------------------------------

CREATE TABLE topic_coverage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES syllabus_topics(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status topic_status NOT NULL DEFAULT 'not_started',
    started_date DATE,
    completed_date DATE,
    periods_spent INT DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(topic_id, section_id)
);

-- -----------------------------------------------------------
-- TABLE: lesson_plans
-- -----------------------------------------------------------

CREATE TABLE lesson_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES syllabus_topics(id) ON DELETE CASCADE,
    section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    objective TEXT,
    warm_up TEXT,
    main_activity TEXT,
    assessment_activity TEXT,
    homework TEXT,
    materials_needed TEXT,
    differentiation_notes TEXT,
    duration_minutes INT DEFAULT 40,
    status lesson_plan_status NOT NULL DEFAULT 'draft',
    is_ai_generated BOOLEAN DEFAULT FALSE,
    ai_prompt_context JSONB,
    delivered_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------
-- TABLE: topic_resource_links (polymorphic M:N)
-- -----------------------------------------------------------

CREATE TABLE topic_resource_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES syllabus_topics(id) ON DELETE CASCADE,
    entity_type topic_entity_type NOT NULL,
    entity_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(topic_id, entity_type, entity_id)
);

-- -----------------------------------------------------------
-- ALTER existing tables: add nullable topic_id FK
-- -----------------------------------------------------------

ALTER TABLE assignments ADD COLUMN IF NOT EXISTS topic_id UUID REFERENCES syllabus_topics(id) ON DELETE SET NULL;
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS topic_id UUID REFERENCES syllabus_topics(id) ON DELETE SET NULL;
ALTER TABLE question_bank ADD COLUMN IF NOT EXISTS topic_id UUID REFERENCES syllabus_topics(id) ON DELETE SET NULL;
ALTER TABLE study_resources ADD COLUMN IF NOT EXISTS topic_id UUID REFERENCES syllabus_topics(id) ON DELETE SET NULL;

-- -----------------------------------------------------------
-- INDEXES
-- -----------------------------------------------------------

CREATE INDEX idx_syllabus_topics_tenant ON syllabus_topics(tenant_id);
CREATE INDEX idx_syllabus_topics_subject_class ON syllabus_topics(subject_id, class_id, academic_year_id);
CREATE INDEX idx_syllabus_topics_parent ON syllabus_topics(parent_topic_id);

CREATE INDEX idx_topic_coverage_tenant ON topic_coverage(tenant_id);
CREATE INDEX idx_topic_coverage_section ON topic_coverage(section_id, topic_id);
CREATE INDEX idx_topic_coverage_status ON topic_coverage(status) WHERE status != 'completed';

CREATE INDEX idx_lesson_plans_tenant ON lesson_plans(tenant_id);
CREATE INDEX idx_lesson_plans_topic ON lesson_plans(topic_id);
CREATE INDEX idx_lesson_plans_teacher ON lesson_plans(teacher_id);

CREATE INDEX idx_topic_resource_links_topic ON topic_resource_links(topic_id, entity_type);
CREATE INDEX idx_topic_resource_links_entity ON topic_resource_links(entity_type, entity_id);

CREATE INDEX idx_assignments_topic ON assignments(topic_id) WHERE topic_id IS NOT NULL;
CREATE INDEX idx_quizzes_topic ON quizzes(topic_id) WHERE topic_id IS NOT NULL;
CREATE INDEX idx_question_bank_topic ON question_bank(topic_id) WHERE topic_id IS NOT NULL;
CREATE INDEX idx_study_resources_topic ON study_resources(topic_id) WHERE topic_id IS NOT NULL;

-- -----------------------------------------------------------
-- VIEW: v_syllabus_coverage_summary
-- -----------------------------------------------------------

CREATE OR REPLACE VIEW v_syllabus_coverage_summary AS
SELECT
    st.tenant_id,
    st.subject_id,
    st.class_id,
    st.academic_year_id,
    tc.section_id,
    COUNT(st.id) AS total_topics,
    COUNT(tc.id) FILTER (WHERE tc.status = 'completed') AS completed_topics,
    COUNT(tc.id) FILTER (WHERE tc.status = 'in_progress') AS in_progress_topics,
    COUNT(tc.id) FILTER (WHERE tc.status = 'skipped') AS skipped_topics,
    CASE
        WHEN COUNT(st.id) > 0
        THEN ROUND(COUNT(tc.id) FILTER (WHERE tc.status = 'completed') * 100.0 / COUNT(st.id), 1)
        ELSE 0
    END AS coverage_percentage,
    COALESCE(SUM(st.estimated_periods), 0) AS total_estimated_periods,
    COALESCE(SUM(tc.periods_spent), 0) AS total_periods_spent
FROM syllabus_topics st
LEFT JOIN topic_coverage tc ON tc.topic_id = st.id
WHERE st.parent_topic_id IS NOT NULL  -- only leaf-ish topics (not root units)
GROUP BY st.tenant_id, st.subject_id, st.class_id, st.academic_year_id, tc.section_id;

-- -----------------------------------------------------------
-- RLS POLICIES
-- -----------------------------------------------------------

ALTER TABLE syllabus_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_coverage ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_resource_links ENABLE ROW LEVEL SECURITY;

-- syllabus_topics: read for all tenant users, write for teacher/admin
CREATE POLICY "syllabus_topics_select" ON syllabus_topics
    FOR SELECT USING (
        tenant_id IN (SELECT tenant_id FROM user_roles WHERE user_id = auth.uid())
    );

CREATE POLICY "syllabus_topics_insert" ON syllabus_topics
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
              AND tenant_id = syllabus_topics.tenant_id
              AND role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
        )
    );

CREATE POLICY "syllabus_topics_update" ON syllabus_topics
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
              AND tenant_id = syllabus_topics.tenant_id
              AND role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
        )
    );

CREATE POLICY "syllabus_topics_delete" ON syllabus_topics
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
              AND tenant_id = syllabus_topics.tenant_id
              AND role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
        )
    );

-- topic_coverage: same pattern
CREATE POLICY "topic_coverage_select" ON topic_coverage
    FOR SELECT USING (
        tenant_id IN (SELECT tenant_id FROM user_roles WHERE user_id = auth.uid())
    );

CREATE POLICY "topic_coverage_modify" ON topic_coverage
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
              AND tenant_id = topic_coverage.tenant_id
              AND role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
        )
    );

-- lesson_plans
CREATE POLICY "lesson_plans_select" ON lesson_plans
    FOR SELECT USING (
        tenant_id IN (SELECT tenant_id FROM user_roles WHERE user_id = auth.uid())
    );

CREATE POLICY "lesson_plans_modify" ON lesson_plans
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
              AND tenant_id = lesson_plans.tenant_id
              AND role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
        )
    );

-- topic_resource_links
CREATE POLICY "topic_resource_links_select" ON topic_resource_links
    FOR SELECT USING (
        tenant_id IN (SELECT tenant_id FROM user_roles WHERE user_id = auth.uid())
    );

CREATE POLICY "topic_resource_links_modify" ON topic_resource_links
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
              AND tenant_id = topic_resource_links.tenant_id
              AND role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
        )
    );

-- -----------------------------------------------------------
-- TRIGGER: auto-update updated_at
-- -----------------------------------------------------------

CREATE OR REPLACE FUNCTION update_syllabus_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_syllabus_topics_updated_at
    BEFORE UPDATE ON syllabus_topics
    FOR EACH ROW EXECUTE FUNCTION update_syllabus_updated_at();

CREATE TRIGGER trg_topic_coverage_updated_at
    BEFORE UPDATE ON topic_coverage
    FOR EACH ROW EXECUTE FUNCTION update_syllabus_updated_at();

CREATE TRIGGER trg_lesson_plans_updated_at
    BEFORE UPDATE ON lesson_plans
    FOR EACH ROW EXECUTE FUNCTION update_syllabus_updated_at();
