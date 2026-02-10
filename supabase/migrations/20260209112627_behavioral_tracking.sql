-- =============================================
-- Behavioral Tracking & Discipline System
-- Phase 3: Behavior Incidents, Discipline, Counseling
-- =============================================

-- =============================================
-- ENUMS
-- =============================================

CREATE TYPE behavior_type AS ENUM ('positive', 'negative', 'neutral');

CREATE TYPE behavior_category AS ENUM (
    'attendance',
    'punctuality',
    'academic_honesty',
    'respect',
    'bullying',
    'violence',
    'vandalism',
    'technology_misuse',
    'uniform_violation',
    'classroom_disruption',
    'language',
    'participation',
    'leadership',
    'helpfulness'
);

CREATE TYPE behavior_severity AS ENUM ('minor', 'moderate', 'major', 'severe');

CREATE TYPE disciplinary_action_type AS ENUM (
    'verbal_warning',
    'written_warning',
    'detention',
    'suspension_in_school',
    'suspension_out_of_school',
    'community_service',
    'parent_conference',
    'behavior_contract',
    'expulsion'
);

CREATE TYPE disciplinary_status AS ENUM ('pending', 'active', 'completed', 'appealed', 'overturned');

CREATE TYPE counseling_type AS ENUM (
    'behavioral',
    'academic',
    'personal',
    'career',
    'mental_health',
    'family',
    'peer_relationship',
    'substance_abuse'
);

CREATE TYPE session_status AS ENUM ('scheduled', 'completed', 'cancelled', 'no_show', 'rescheduled');

-- =============================================
-- BEHAVIOR INCIDENTS
-- =============================================

CREATE TABLE behavior_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    incident_date DATE NOT NULL,
    incident_time TIME,
    location VARCHAR(255),
    behavior_type behavior_type NOT NULL,
    behavior_category behavior_category NOT NULL,
    severity behavior_severity NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    reported_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    witnesses UUID[] DEFAULT '{}',
    other_students_involved UUID[] DEFAULT '{}',
    evidence_urls TEXT[] DEFAULT '{}',
    immediate_action_taken TEXT,
    parent_notified BOOLEAN DEFAULT false,
    parent_notified_at TIMESTAMPTZ,
    requires_counseling BOOLEAN DEFAULT false,
    affects_conduct_grade BOOLEAN DEFAULT true,
    conduct_points_deducted INT DEFAULT 0 CHECK (conduct_points_deducted >= 0),
    conduct_points_awarded INT DEFAULT 0 CHECK (conduct_points_awarded >= 0),
    resolution_notes TEXT,
    resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE behavior_incidents IS 'Records of student behavioral incidents both positive and negative';
COMMENT ON COLUMN behavior_incidents.conduct_points_deducted IS 'Negative points deducted for negative behaviors';
COMMENT ON COLUMN behavior_incidents.conduct_points_awarded IS 'Positive points awarded for positive behaviors';

-- =============================================
-- DISCIPLINARY ACTIONS
-- =============================================

CREATE TABLE disciplinary_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    incident_id UUID REFERENCES behavior_incidents(id) ON DELETE SET NULL,
    action_type disciplinary_action_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    duration_days INT GENERATED ALWAYS AS (
        CASE
            WHEN end_date IS NOT NULL THEN (end_date - start_date) + 1
            ELSE 1
        END
    ) STORED,
    status disciplinary_status DEFAULT 'pending',
    issued_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    appeal_filed BOOLEAN DEFAULT false,
    appeal_filed_at TIMESTAMPTZ,
    appeal_reason TEXT,
    appeal_decision TEXT,
    appeal_decided_by UUID REFERENCES users(id) ON DELETE SET NULL,
    appeal_decided_at TIMESTAMPTZ,
    conditions TEXT,
    completion_requirements TEXT,
    completion_verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    completion_verified_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE disciplinary_actions IS 'Formal disciplinary actions taken against students';
COMMENT ON COLUMN disciplinary_actions.conditions IS 'Conditions that must be met during or after the disciplinary action';

-- =============================================
-- COUNSELING SESSIONS
-- =============================================

CREATE TABLE counseling_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    counselor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    counseling_type counseling_type NOT NULL,
    session_date DATE NOT NULL,
    session_time TIME,
    duration_minutes INT CHECK (duration_minutes > 0),
    is_mandatory BOOLEAN DEFAULT false,
    referred_by UUID REFERENCES users(id) ON DELETE SET NULL,
    incident_id UUID REFERENCES behavior_incidents(id) ON DELETE SET NULL,
    status session_status DEFAULT 'scheduled',
    session_notes TEXT, -- Should be encrypted in production
    goals_set TEXT[] DEFAULT '{}',
    progress_notes TEXT,
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    is_confidential BOOLEAN DEFAULT true,
    shared_with UUID[] DEFAULT '{}',
    parent_consent_required BOOLEAN DEFAULT false,
    parent_consent_obtained BOOLEAN DEFAULT false,
    parent_consent_date DATE,
    attachments JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

COMMENT ON TABLE counseling_sessions IS 'Student counseling session records';
COMMENT ON COLUMN counseling_sessions.session_notes IS 'Confidential notes from counseling session - should be encrypted';
COMMENT ON COLUMN counseling_sessions.shared_with IS 'Array of user IDs who have access to this confidential session';

-- =============================================
-- STUDENT CONDUCT GRADES
-- =============================================

CREATE TABLE student_conduct_grades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    term_id UUID REFERENCES terms(id) ON DELETE SET NULL,
    conduct_grade VARCHAR(2), -- A+, A, B, C, D, F
    conduct_points INT DEFAULT 100 CHECK (conduct_points >= 0 AND conduct_points <= 200),
    positive_behaviors_count INT DEFAULT 0,
    negative_behaviors_count INT DEFAULT 0,
    punctuality_score DECIMAL(5,2),
    respect_score DECIMAL(5,2),
    responsibility_score DECIMAL(5,2),
    cooperation_score DECIMAL(5,2),
    overall_score DECIMAL(5,2),
    teacher_comments TEXT,
    counselor_comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, academic_year_id, term_id)
);

COMMENT ON TABLE student_conduct_grades IS 'Conduct and behavior grades for students by term';
COMMENT ON COLUMN student_conduct_grades.conduct_points IS 'Points-based system: start at 100, add for positive, deduct for negative';

-- =============================================
-- BEHAVIOR INTERVENTION PLANS
-- =============================================

CREATE TABLE behavior_intervention_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    plan_name VARCHAR(255) NOT NULL,
    target_behaviors TEXT[] NOT NULL,
    replacement_behaviors TEXT[] NOT NULL,
    interventions JSONB DEFAULT '[]', -- Array of intervention strategies
    support_staff UUID[] DEFAULT '{}',
    start_date DATE NOT NULL,
    review_date DATE,
    end_date DATE,
    status VARCHAR(50) DEFAULT 'active',
    baseline_data JSONB,
    progress_monitoring JSONB DEFAULT '[]',
    parent_involved BOOLEAN DEFAULT false,
    parent_signature_date DATE,
    effectiveness_rating INT CHECK (effectiveness_rating BETWEEN 1 AND 5),
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE behavior_intervention_plans IS 'Formal behavior intervention plans (BIP) for students with chronic behavioral issues';
COMMENT ON COLUMN behavior_intervention_plans.progress_monitoring IS 'Array of progress check records with dates and metrics';

-- =============================================
-- INDEXES
-- =============================================

-- Behavior Incidents
CREATE INDEX idx_behavior_incidents_student ON behavior_incidents(student_id, incident_date DESC);
CREATE INDEX idx_behavior_incidents_date ON behavior_incidents(incident_date DESC);
CREATE INDEX idx_behavior_incidents_reporter ON behavior_incidents(reported_by, created_at DESC);
CREATE INDEX idx_behavior_incidents_category ON behavior_incidents(behavior_category, severity);
CREATE INDEX idx_behavior_incidents_unresolved ON behavior_incidents(resolved, incident_date DESC)
    WHERE resolved = false;
CREATE INDEX idx_behavior_incidents_type ON behavior_incidents(behavior_type, incident_date DESC);

-- Disciplinary Actions
CREATE INDEX idx_disciplinary_actions_student ON disciplinary_actions(student_id, start_date DESC);
CREATE INDEX idx_disciplinary_actions_incident ON disciplinary_actions(incident_id);
CREATE INDEX idx_disciplinary_actions_status ON disciplinary_actions(status, start_date DESC)
    WHERE status IN ('pending', 'active');
CREATE INDEX idx_disciplinary_actions_type ON disciplinary_actions(action_type, start_date DESC);
CREATE INDEX idx_disciplinary_actions_appeal ON disciplinary_actions(appeal_filed, appeal_filed_at)
    WHERE appeal_filed = true;

-- Counseling Sessions
CREATE INDEX idx_counseling_sessions_student ON counseling_sessions(student_id, session_date DESC);
CREATE INDEX idx_counseling_sessions_counselor ON counseling_sessions(counselor_id, session_date DESC);
CREATE INDEX idx_counseling_sessions_status ON counseling_sessions(status, session_date)
    WHERE status IN ('scheduled', 'rescheduled');
CREATE INDEX idx_counseling_sessions_type ON counseling_sessions(counseling_type, session_date DESC);
CREATE INDEX idx_counseling_sessions_incident ON counseling_sessions(incident_id);
CREATE INDEX idx_counseling_sessions_followup ON counseling_sessions(follow_up_required, follow_up_date)
    WHERE follow_up_required = true;

-- Student Conduct Grades
CREATE INDEX idx_conduct_grades_student ON student_conduct_grades(student_id, academic_year_id);
CREATE INDEX idx_conduct_grades_term ON student_conduct_grades(term_id);
CREATE INDEX idx_conduct_grades_year ON student_conduct_grades(academic_year_id);

-- Behavior Intervention Plans
CREATE INDEX idx_behavior_plans_student ON behavior_intervention_plans(student_id, academic_year_id);
CREATE INDEX idx_behavior_plans_status ON behavior_intervention_plans(status, review_date)
    WHERE status = 'active';

-- =============================================
-- STORED PROCEDURES
-- =============================================

-- Calculate conduct grade for student
CREATE OR REPLACE FUNCTION calculate_conduct_grade(
    p_student_id UUID,
    p_term_id UUID
)
RETURNS VARCHAR(2) AS $$
DECLARE
    v_academic_year_id UUID;
    v_positive_count INT;
    v_negative_count INT;
    v_conduct_points INT;
    v_grade VARCHAR(2);
BEGIN
    -- Get academic year from term
    SELECT academic_year_id INTO v_academic_year_id
    FROM terms WHERE id = p_term_id;

    -- Count behaviors
    SELECT
        COUNT(*) FILTER (WHERE behavior_type = 'positive'),
        COUNT(*) FILTER (WHERE behavior_type = 'negative'),
        100 +
        COALESCE(SUM(conduct_points_awarded), 0) -
        COALESCE(SUM(conduct_points_deducted), 0)
    INTO v_positive_count, v_negative_count, v_conduct_points
    FROM behavior_incidents
    WHERE student_id = p_student_id
        AND incident_date BETWEEN (SELECT start_date FROM terms WHERE id = p_term_id)
                             AND (SELECT end_date FROM terms WHERE id = p_term_id);

    -- Ensure points stay within 0-200 range
    v_conduct_points := GREATEST(0, LEAST(200, COALESCE(v_conduct_points, 100)));

    -- Calculate grade based on points
    v_grade := CASE
        WHEN v_conduct_points >= 95 THEN 'A+'
        WHEN v_conduct_points >= 90 THEN 'A'
        WHEN v_conduct_points >= 85 THEN 'B+'
        WHEN v_conduct_points >= 80 THEN 'B'
        WHEN v_conduct_points >= 75 THEN 'C+'
        WHEN v_conduct_points >= 70 THEN 'C'
        WHEN v_conduct_points >= 65 THEN 'D+'
        WHEN v_conduct_points >= 60 THEN 'D'
        ELSE 'F'
    END;

    -- Insert or update conduct grade
    INSERT INTO student_conduct_grades (
        student_id,
        academic_year_id,
        term_id,
        conduct_grade,
        conduct_points,
        positive_behaviors_count,
        negative_behaviors_count
    ) VALUES (
        p_student_id,
        v_academic_year_id,
        p_term_id,
        v_grade,
        v_conduct_points,
        v_positive_count,
        v_negative_count
    )
    ON CONFLICT (student_id, academic_year_id, term_id)
    DO UPDATE SET
        conduct_grade = v_grade,
        conduct_points = v_conduct_points,
        positive_behaviors_count = v_positive_count,
        negative_behaviors_count = v_negative_count,
        updated_at = NOW();

    RETURN v_grade;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_conduct_grade IS 'Calculates and updates conduct grade for a student in a term';

-- Auto-notify parents when serious incident occurs
CREATE OR REPLACE FUNCTION notify_parent_on_serious_incident()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.severity IN ('major', 'severe') AND NOT NEW.parent_notified THEN
        -- TODO: Trigger notification to parents
        -- This would integrate with notification system
        NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notify_parent_incident
    AFTER INSERT ON behavior_incidents
    FOR EACH ROW
    EXECUTE FUNCTION notify_parent_on_serious_incident();

COMMENT ON FUNCTION notify_parent_on_serious_incident IS 'Automatically notifies parents for major/severe incidents';

-- Update conduct grade after behavior incident
CREATE OR REPLACE FUNCTION update_conduct_grade_on_incident()
RETURNS TRIGGER AS $$
DECLARE
    v_term_id UUID;
BEGIN
    -- Find current term for the incident date
    SELECT id INTO v_term_id
    FROM terms t
    JOIN student_enrollments se ON t.academic_year_id = se.academic_year_id
    WHERE se.student_id = NEW.student_id
        AND NEW.incident_date BETWEEN t.start_date AND t.end_date
    LIMIT 1;

    IF v_term_id IS NOT NULL THEN
        PERFORM calculate_conduct_grade(NEW.student_id, v_term_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_conduct_grade
    AFTER INSERT OR UPDATE ON behavior_incidents
    FOR EACH ROW
    EXECUTE FUNCTION update_conduct_grade_on_incident();

COMMENT ON FUNCTION update_conduct_grade_on_incident IS 'Automatically recalculates conduct grade when incident is recorded';

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE behavior_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE disciplinary_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE counseling_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_conduct_grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_intervention_plans ENABLE ROW LEVEL SECURITY;
