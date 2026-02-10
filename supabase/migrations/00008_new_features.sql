-- =============================================
-- New Features Schema - Phase 1-3
-- =============================================

-- =============================================
-- NOTIFICATIONS
-- =============================================

CREATE TYPE notification_type AS ENUM (
    'attendance', 'fee_reminder', 'grade_update', 'assignment',
    'announcement', 'emergency', 'ptm', 'general', 'achievement'
);

CREATE TYPE notification_priority AS ENUM ('low', 'normal', 'high', 'urgent');

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type notification_type NOT NULL DEFAULT 'general',
    priority notification_priority NOT NULL DEFAULT 'normal',
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    action_type VARCHAR(50),
    action_data JSONB,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_tenant ON notifications(tenant_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- =============================================
-- HEALTH RECORDS
-- =============================================

CREATE TYPE blood_group_type AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-');
CREATE TYPE incident_severity AS ENUM ('minor', 'moderate', 'serious', 'critical');

CREATE TABLE student_health_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    blood_group blood_group_type,
    height_cm DECIMAL(5,2),
    weight_kg DECIMAL(5,2),
    allergies TEXT[] DEFAULT '{}',
    chronic_conditions TEXT[] DEFAULT '{}',
    current_medications JSONB DEFAULT '[]',
    vaccinations JSONB DEFAULT '[]',
    dietary_restrictions TEXT[] DEFAULT '{}',
    vision_left VARCHAR(20),
    vision_right VARCHAR(20),
    hearing_status VARCHAR(50),
    physical_disabilities TEXT,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relation VARCHAR(50),
    family_doctor_name VARCHAR(100),
    family_doctor_phone VARCHAR(20),
    insurance_provider VARCHAR(100),
    insurance_policy_number VARCHAR(50),
    notes TEXT,
    last_checkup_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id)
);

CREATE TABLE health_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    incident_date DATE NOT NULL DEFAULT CURRENT_DATE,
    incident_time TIME,
    severity incident_severity NOT NULL DEFAULT 'minor',
    description TEXT NOT NULL,
    symptoms TEXT[],
    treatment_given TEXT,
    medication_administered TEXT,
    referred_to_hospital BOOLEAN DEFAULT false,
    hospital_name VARCHAR(100),
    parent_notified BOOLEAN DEFAULT false,
    parent_notified_at TIMESTAMPTZ,
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    follow_up_notes TEXT,
    reported_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_health_records_student ON student_health_records(student_id);
CREATE INDEX idx_health_records_tenant ON student_health_records(tenant_id);
CREATE INDEX idx_health_incidents_student ON health_incidents(student_id);
CREATE INDEX idx_health_incidents_date ON health_incidents(incident_date DESC);

-- =============================================
-- GAMIFICATION & ACHIEVEMENTS
-- =============================================

CREATE TYPE achievement_category AS ENUM (
    'academic', 'attendance', 'sports', 'arts', 'behavior',
    'leadership', 'community', 'special'
);

CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category achievement_category NOT NULL,
    icon_name VARCHAR(50),
    icon_url TEXT,
    points INT NOT NULL DEFAULT 10,
    criteria JSONB,
    is_automatic BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE student_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    awarded_by UUID REFERENCES users(id),
    notes TEXT,
    UNIQUE(student_id, achievement_id)
);

CREATE TABLE student_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    category achievement_category NOT NULL,
    points INT NOT NULL DEFAULT 0,
    academic_year_id UUID REFERENCES academic_years(id) ON DELETE CASCADE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, category, academic_year_id)
);

CREATE TABLE point_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    points INT NOT NULL,
    category achievement_category NOT NULL,
    reason VARCHAR(255) NOT NULL,
    reference_type VARCHAR(50),
    reference_id UUID,
    awarded_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_achievements_tenant ON achievements(tenant_id);
CREATE INDEX idx_student_achievements_student ON student_achievements(student_id);
CREATE INDEX idx_student_points_student ON student_points(student_id);
CREATE INDEX idx_point_transactions_student ON point_transactions(student_id);

-- =============================================
-- ONLINE ASSESSMENTS / QUIZZES
-- =============================================

CREATE TYPE quiz_status AS ENUM ('draft', 'published', 'active', 'closed', 'archived');
CREATE TYPE question_type AS ENUM ('multiple_choice', 'true_false', 'short_answer', 'essay', 'fill_blank', 'matching');

CREATE TABLE quizzes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    subject_id UUID REFERENCES subjects(id),
    section_id UUID REFERENCES sections(id),
    created_by UUID NOT NULL REFERENCES users(id),
    status quiz_status DEFAULT 'draft',
    total_marks INT NOT NULL DEFAULT 0,
    passing_marks INT,
    duration_minutes INT,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    shuffle_questions BOOLEAN DEFAULT false,
    shuffle_options BOOLEAN DEFAULT false,
    show_results_immediately BOOLEAN DEFAULT true,
    allow_review BOOLEAN DEFAULT true,
    max_attempts INT DEFAULT 1,
    instructions TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE question_bank (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id),
    chapter VARCHAR(100),
    topic VARCHAR(100),
    question_type question_type NOT NULL,
    difficulty_level INT DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
    question_text TEXT NOT NULL,
    question_image_url TEXT,
    options JSONB,
    correct_answer JSONB NOT NULL,
    explanation TEXT,
    marks INT NOT NULL DEFAULT 1,
    tags TEXT[] DEFAULT '{}',
    created_by UUID REFERENCES users(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE quiz_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
    question_bank_id UUID REFERENCES question_bank(id),
    question_type question_type NOT NULL,
    question_text TEXT NOT NULL,
    question_image_url TEXT,
    options JSONB,
    correct_answer JSONB NOT NULL,
    explanation TEXT,
    marks INT NOT NULL DEFAULT 1,
    sequence_order INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE quiz_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    attempt_number INT NOT NULL DEFAULT 1,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    submitted_at TIMESTAMPTZ,
    time_taken_seconds INT,
    total_marks_obtained DECIMAL(5,2) DEFAULT 0,
    percentage DECIMAL(5,2),
    is_passed BOOLEAN,
    answers JSONB DEFAULT '{}',
    is_graded BOOLEAN DEFAULT false,
    graded_by UUID REFERENCES users(id),
    graded_at TIMESTAMPTZ,
    feedback TEXT
);

CREATE INDEX idx_quizzes_tenant ON quizzes(tenant_id);
CREATE INDEX idx_quizzes_section ON quizzes(section_id);
CREATE INDEX idx_question_bank_tenant ON question_bank(tenant_id);
CREATE INDEX idx_question_bank_subject ON question_bank(subject_id);
CREATE INDEX idx_quiz_attempts_quiz ON quiz_attempts(quiz_id);
CREATE INDEX idx_quiz_attempts_student ON quiz_attempts(student_id);

-- =============================================
-- PTM (PARENT-TEACHER MEETING) SCHEDULER
-- =============================================

CREATE TYPE ptm_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');
CREATE TYPE appointment_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled', 'no_show');

CREATE TABLE ptm_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    ptm_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration_minutes INT NOT NULL DEFAULT 15,
    break_duration_minutes INT DEFAULT 5,
    location VARCHAR(255),
    is_virtual BOOLEAN DEFAULT false,
    meeting_link TEXT,
    target_sections UUID[] DEFAULT '{}',
    status ptm_status DEFAULT 'scheduled',
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ptm_teacher_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    ptm_id UUID NOT NULL REFERENCES ptm_schedules(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_available BOOLEAN DEFAULT true,
    room_number VARCHAR(20),
    custom_start_time TIME,
    custom_end_time TIME,
    notes TEXT,
    UNIQUE(ptm_id, teacher_id)
);

CREATE TABLE ptm_appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    ptm_id UUID NOT NULL REFERENCES ptm_schedules(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES users(id),
    parent_id UUID NOT NULL REFERENCES users(id),
    student_id UUID NOT NULL REFERENCES students(id),
    slot_time TIME NOT NULL,
    status appointment_status DEFAULT 'pending',
    parent_notes TEXT,
    teacher_notes TEXT,
    feedback TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ptm_schedules_tenant ON ptm_schedules(tenant_id);
CREATE INDEX idx_ptm_schedules_date ON ptm_schedules(ptm_date);
CREATE INDEX idx_ptm_appointments_ptm ON ptm_appointments(ptm_id);
CREATE INDEX idx_ptm_appointments_teacher ON ptm_appointments(teacher_id);
CREATE INDEX idx_ptm_appointments_parent ON ptm_appointments(parent_id);

-- =============================================
-- EMERGENCY ALERT SYSTEM
-- =============================================

CREATE TYPE emergency_type AS ENUM ('fire', 'earthquake', 'lockdown', 'medical', 'weather', 'evacuation', 'drill', 'other');
CREATE TYPE emergency_status AS ENUM ('active', 'resolved', 'false_alarm', 'drill_complete');
CREATE TYPE response_status AS ENUM ('safe', 'needs_help', 'missing', 'evacuated');

CREATE TABLE emergency_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    emergency_type emergency_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    instructions TEXT,
    severity INT NOT NULL DEFAULT 3 CHECK (severity BETWEEN 1 AND 5),
    status emergency_status DEFAULT 'active',
    is_drill BOOLEAN DEFAULT false,
    affected_areas TEXT[] DEFAULT '{}',
    target_roles user_role[] DEFAULT '{}',
    initiated_by UUID NOT NULL REFERENCES users(id),
    resolved_by UUID REFERENCES users(id),
    initiated_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT
);

CREATE TABLE emergency_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    alert_id UUID NOT NULL REFERENCES emergency_alerts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    student_id UUID REFERENCES students(id),
    response_status response_status NOT NULL,
    location VARCHAR(255),
    notes TEXT,
    responded_at TIMESTAMPTZ DEFAULT NOW(),
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMPTZ,
    CONSTRAINT response_user_check CHECK (user_id IS NOT NULL OR student_id IS NOT NULL)
);

CREATE TABLE emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    is_primary BOOLEAN DEFAULT false,
    emergency_types emergency_type[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_emergency_alerts_tenant ON emergency_alerts(tenant_id);
CREATE INDEX idx_emergency_alerts_status ON emergency_alerts(status) WHERE status = 'active';
CREATE INDEX idx_emergency_responses_alert ON emergency_responses(alert_id);

-- =============================================
-- LEAVE MANAGEMENT
-- =============================================

CREATE TYPE leave_type AS ENUM ('sick', 'casual', 'earned', 'maternity', 'paternity', 'study', 'other');
CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
CREATE TYPE applicant_type AS ENUM ('student', 'teacher', 'staff');

CREATE TABLE leave_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    applicant_type applicant_type NOT NULL,
    student_id UUID REFERENCES students(id),
    staff_id UUID REFERENCES staff(id),
    user_id UUID REFERENCES users(id),
    leave_type leave_type NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT NOT NULL,
    supporting_document_url TEXT,
    status leave_status DEFAULT 'pending',
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    substitute_teacher_id UUID REFERENCES users(id),
    notes TEXT,
    CONSTRAINT applicant_check CHECK (student_id IS NOT NULL OR staff_id IS NOT NULL OR user_id IS NOT NULL)
);

CREATE TABLE leave_balance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    staff_id UUID REFERENCES staff(id),
    leave_type leave_type NOT NULL,
    academic_year_id UUID REFERENCES academic_years(id),
    total_days INT NOT NULL DEFAULT 0,
    used_days INT NOT NULL DEFAULT 0,
    remaining_days INT GENERATED ALWAYS AS (total_days - used_days) STORED,
    CONSTRAINT balance_user_check CHECK (user_id IS NOT NULL OR staff_id IS NOT NULL),
    UNIQUE(user_id, leave_type, academic_year_id),
    UNIQUE(staff_id, leave_type, academic_year_id)
);

CREATE INDEX idx_leave_applications_tenant ON leave_applications(tenant_id);
CREATE INDEX idx_leave_applications_status ON leave_applications(status);
CREATE INDEX idx_leave_applications_dates ON leave_applications(start_date, end_date);

-- =============================================
-- RESOURCE LIBRARY
-- =============================================

CREATE TYPE resource_type AS ENUM ('document', 'video', 'audio', 'image', 'link', 'presentation', 'spreadsheet', 'other');

CREATE TABLE study_resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    resource_type resource_type NOT NULL,
    file_url TEXT,
    external_url TEXT,
    thumbnail_url TEXT,
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    subject_id UUID REFERENCES subjects(id),
    class_id UUID REFERENCES classes(id),
    chapter VARCHAR(100),
    topic VARCHAR(100),
    tags TEXT[] DEFAULT '{}',
    is_downloadable BOOLEAN DEFAULT true,
    view_count INT DEFAULT 0,
    download_count INT DEFAULT 0,
    uploaded_by UUID REFERENCES users(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE resource_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES study_resources(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    section_id UUID REFERENCES sections(id),
    accessed_at TIMESTAMPTZ DEFAULT NOW(),
    action VARCHAR(20) NOT NULL DEFAULT 'view'
);

CREATE INDEX idx_study_resources_tenant ON study_resources(tenant_id);
CREATE INDEX idx_study_resources_subject ON study_resources(subject_id);
CREATE INDEX idx_study_resources_class ON study_resources(class_id);
CREATE INDEX idx_resource_access_resource ON resource_access(resource_id);

-- =============================================
-- PREDICTIVE ANALYTICS (Views for dashboards)
-- =============================================

-- Student Risk Score View
CREATE OR REPLACE VIEW v_student_risk_scores AS
SELECT
    s.id as student_id,
    s.tenant_id,
    s.first_name,
    s.last_name,
    se.section_id,
    -- Attendance risk (weight: 30%)
    COALESCE(
        (SELECT
            CASE
                WHEN COUNT(*) = 0 THEN 0
                ELSE (COUNT(*) FILTER (WHERE a.status IN ('absent', 'late')) * 100.0 / COUNT(*))
            END
         FROM attendance a
         WHERE a.student_id = s.id
         AND a.date >= CURRENT_DATE - INTERVAL '30 days'
        ), 0
    ) * 0.3 as attendance_risk,
    -- Academic risk (weight: 40%)
    COALESCE(
        (SELECT
            CASE
                WHEN AVG(m.marks_obtained * 100.0 / es.max_marks) < 40 THEN 100
                WHEN AVG(m.marks_obtained * 100.0 / es.max_marks) < 60 THEN 50
                ELSE 0
            END
         FROM marks m
         JOIN exam_subjects es ON es.id = m.exam_subject_id
         JOIN exams e ON e.id = es.exam_id
         WHERE m.student_id = s.id
         AND e.created_at >= CURRENT_DATE - INTERVAL '90 days'
        ), 50
    ) * 0.4 as academic_risk,
    -- Assignment risk (weight: 30%)
    COALESCE(
        (SELECT
            CASE
                WHEN COUNT(*) = 0 THEN 0
                ELSE (COUNT(*) FILTER (WHERE sub.status IN ('pending', 'late')) * 100.0 / COUNT(*))
            END
         FROM assignments a
         LEFT JOIN submissions sub ON sub.assignment_id = a.id AND sub.student_id = s.id
         WHERE a.section_id = se.section_id
         AND a.due_date >= CURRENT_DATE - INTERVAL '30 days'
        ), 0
    ) * 0.3 as assignment_risk
FROM students s
JOIN student_enrollments se ON se.student_id = s.id
JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = true
WHERE s.is_active = true;

-- Leaderboard View
CREATE OR REPLACE VIEW v_student_leaderboard AS
SELECT
    sp.student_id,
    sp.tenant_id,
    s.first_name,
    s.last_name,
    s.photo_url,
    se.section_id,
    sec.name as section_name,
    c.name as class_name,
    COALESCE(SUM(sp.points), 0) as total_points,
    COUNT(DISTINCT sa.achievement_id) as achievement_count,
    RANK() OVER (PARTITION BY sp.tenant_id ORDER BY COALESCE(SUM(sp.points), 0) DESC) as tenant_rank,
    RANK() OVER (PARTITION BY se.section_id ORDER BY COALESCE(SUM(sp.points), 0) DESC) as section_rank
FROM student_points sp
JOIN students s ON s.id = sp.student_id
JOIN student_enrollments se ON se.student_id = s.id
JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = true
JOIN sections sec ON sec.id = se.section_id
JOIN classes c ON c.id = sec.class_id
LEFT JOIN student_achievements sa ON sa.student_id = s.id
WHERE s.is_active = true
GROUP BY sp.student_id, sp.tenant_id, s.first_name, s.last_name, s.photo_url,
         se.section_id, sec.name, c.name;

-- =============================================
-- FUNCTIONS
-- =============================================

-- Function to award points
CREATE OR REPLACE FUNCTION award_points(
    p_tenant_id UUID,
    p_student_id UUID,
    p_category achievement_category,
    p_points INT,
    p_reason VARCHAR(255),
    p_awarded_by UUID DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    v_academic_year_id UUID;
BEGIN
    -- Get current academic year
    SELECT id INTO v_academic_year_id
    FROM academic_years
    WHERE tenant_id = p_tenant_id AND is_current = true
    LIMIT 1;

    -- Insert or update points
    INSERT INTO student_points (tenant_id, student_id, category, points, academic_year_id)
    VALUES (p_tenant_id, p_student_id, p_category, p_points, v_academic_year_id)
    ON CONFLICT (student_id, category, academic_year_id)
    DO UPDATE SET points = student_points.points + p_points, updated_at = NOW();

    -- Log transaction
    INSERT INTO point_transactions (tenant_id, student_id, points, category, reason, awarded_by)
    VALUES (p_tenant_id, p_student_id, p_points, p_category, p_reason, p_awarded_by);
END;
$$ LANGUAGE plpgsql;

-- Function to check and award automatic achievements
CREATE OR REPLACE FUNCTION check_automatic_achievements(
    p_tenant_id UUID,
    p_student_id UUID
)
RETURNS void AS $$
DECLARE
    v_achievement RECORD;
BEGIN
    FOR v_achievement IN
        SELECT * FROM achievements
        WHERE tenant_id = p_tenant_id
        AND is_automatic = true
        AND is_active = true
    LOOP
        -- Check if already earned
        IF NOT EXISTS (
            SELECT 1 FROM student_achievements
            WHERE student_id = p_student_id
            AND achievement_id = v_achievement.id
        ) THEN
            -- Check criteria (simplified - you'd implement actual criteria checking)
            -- For now, this is a placeholder that would need custom logic
            NULL;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update notification read status
CREATE OR REPLACE FUNCTION mark_notification_read()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_read = true AND OLD.is_read = false THEN
        NEW.read_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notification_read_trigger
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION mark_notification_read();

-- Function to send notification
CREATE OR REPLACE FUNCTION send_notification(
    p_tenant_id UUID,
    p_user_id UUID,
    p_type notification_type,
    p_title VARCHAR(255),
    p_body TEXT,
    p_priority notification_priority DEFAULT 'normal',
    p_action_type VARCHAR(50) DEFAULT NULL,
    p_action_data JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO notifications (
        tenant_id, user_id, type, title, body,
        priority, action_type, action_data
    )
    VALUES (
        p_tenant_id, p_user_id, p_type, p_title, p_body,
        p_priority, p_action_type, p_action_data
    )
    RETURNING id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;
