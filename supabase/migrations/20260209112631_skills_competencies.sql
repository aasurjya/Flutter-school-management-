-- =============================================
-- Skills & Competencies Framework
-- Phase 4: Competency-Based Learning
-- =============================================

-- =============================================
-- ENUMS
-- =============================================

CREATE TYPE competency_category AS ENUM ('cognitive', 'social', 'emotional', 'physical', 'technical');

CREATE TYPE bloom_level AS ENUM ('remember', 'understand', 'apply', 'analyze', 'evaluate', 'create');

-- =============================================
-- COMPETENCY FRAMEWORKS
-- =============================================

CREATE TABLE competency_frameworks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    framework_name VARCHAR(100) NOT NULL,
    description TEXT,
    version VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    applicable_grades TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, framework_name, version)
);

COMMENT ON TABLE competency_frameworks IS 'Competency frameworks for skills-based assessment';

-- =============================================
-- COMPETENCIES
-- =============================================

CREATE TABLE competencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    framework_id UUID NOT NULL REFERENCES competency_frameworks(id) ON DELETE CASCADE,
    competency_code VARCHAR(20) NOT NULL,
    competency_name VARCHAR(255) NOT NULL,
    description TEXT,
    category competency_category NOT NULL,
    parent_competency_id UUID REFERENCES competencies(id) ON DELETE SET NULL,
    proficiency_levels JSONB DEFAULT '[]', -- [{"level": 1, "name": "Beginner", "description": "..."}]
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(framework_id, competency_code)
);

COMMENT ON TABLE competencies IS 'Individual competencies within frameworks';
COMMENT ON COLUMN competencies.proficiency_levels IS 'JSON array defining proficiency scale';

-- =============================================
-- STUDENT COMPETENCY ASSESSMENTS
-- =============================================

CREATE TABLE student_competency_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    competency_id UUID NOT NULL REFERENCES competencies(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    term_id UUID REFERENCES terms(id) ON DELETE SET NULL,
    assessed_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    proficiency_level INT NOT NULL CHECK (proficiency_level BETWEEN 1 AND 5),
    assessment_date DATE NOT NULL,
    assessment_method VARCHAR(100), -- 'observation', 'project', 'test', 'portfolio'
    evidence TEXT,
    assessor_notes TEXT,
    score DECIMAL(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE student_competency_assessments IS 'Individual competency assessments for students';

-- =============================================
-- LEARNING OBJECTIVES
-- =============================================

CREATE TABLE learning_objectives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    objective_code VARCHAR(20) NOT NULL,
    description TEXT NOT NULL,
    linked_competencies UUID[] DEFAULT '{}', -- competency IDs
    bloom_taxonomy_level bloom_level,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(subject_id, class_id, objective_code)
);

COMMENT ON TABLE learning_objectives IS 'Learning objectives mapped to competencies';
COMMENT ON COLUMN learning_objectives.linked_competencies IS 'Array of competency IDs this objective develops';

-- =============================================
-- STUDENT SKILLS PORTFOLIO
-- =============================================

CREATE TABLE student_skills_portfolio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    skill_name VARCHAR(255) NOT NULL,
    skill_category VARCHAR(100),
    proficiency_level VARCHAR(50),
    evidence_urls TEXT[] DEFAULT '{}',
    certifications JSONB DEFAULT '[]',
    endorsed_by UUID[] DEFAULT '{}',
    acquired_date DATE,
    verified BOOLEAN DEFAULT false,
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE student_skills_portfolio IS 'Portfolio of skills and certifications for students';

-- =============================================
-- INDEXES
-- =============================================

CREATE INDEX idx_competency_frameworks_tenant ON competency_frameworks(tenant_id) WHERE is_active = true;
CREATE INDEX idx_competencies_framework ON competencies(framework_id, category);
CREATE INDEX idx_competencies_parent ON competencies(parent_competency_id);
CREATE INDEX idx_student_competency_assessments_student ON student_competency_assessments(student_id, academic_year_id);
CREATE INDEX idx_student_competency_assessments_competency ON student_competency_assessments(competency_id, assessment_date DESC);
CREATE INDEX idx_learning_objectives_subject ON learning_objectives(subject_id, class_id);
CREATE INDEX idx_skills_portfolio_student ON student_skills_portfolio(student_id, skill_category);

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE competency_frameworks ENABLE ROW LEVEL SECURITY;
ALTER TABLE competencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_competency_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_objectives ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_skills_portfolio ENABLE ROW LEVEL SECURITY;
