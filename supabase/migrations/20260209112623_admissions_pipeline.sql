-- =============================================
-- Admissions Pipeline
-- Phase 6: Inquiry to Enrollment Tracking
-- =============================================

-- =============================================
-- ENUMS
-- =============================================

CREATE TYPE inquiry_status AS ENUM (
    'new',
    'contacted',
    'visit_scheduled',
    'visit_completed',
    'application_submitted',
    'converted',
    'lost',
    'not_interested'
);

CREATE TYPE inquiry_source AS ENUM (
    'website',
    'referral',
    'walk_in',
    'advertisement',
    'social_media',
    'phone_call',
    'email',
    'event',
    'other'
);

CREATE TYPE application_status AS ENUM (
    'submitted',
    'under_review',
    'documents_pending',
    'entrance_test_scheduled',
    'interview_scheduled',
    'accepted',
    'rejected',
    'waitlisted',
    'withdrawn'
);

CREATE TYPE test_status AS ENUM ('scheduled', 'completed', 'absent', 'cancelled', 'rescheduled');

-- =============================================
-- ADMISSION INQUIRIES
-- =============================================

CREATE TABLE admission_inquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    inquiry_number VARCHAR(50) UNIQUE NOT NULL,
    inquiry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    -- Student Information
    student_name VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(20),
    previous_school VARCHAR(255),
    current_grade VARCHAR(50),
    -- Parent Information
    parent_name VARCHAR(255) NOT NULL,
    parent_email VARCHAR(255),
    parent_phone VARCHAR(20) NOT NULL,
    alternate_phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    -- Inquiry Details
    target_class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    academic_year_id UUID REFERENCES academic_years(id) ON DELETE SET NULL,
    inquiry_source inquiry_source NOT NULL,
    referral_details TEXT,
    status inquiry_status DEFAULT 'new',
    -- Follow-up
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    last_contacted_at TIMESTAMPTZ,
    next_followup_date DATE,
    visit_scheduled_date DATE,
    visit_completed BOOLEAN DEFAULT false,
    -- Conversion
    converted_to_application_id UUID,
    converted_at TIMESTAMPTZ,
    lost_reason TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE admission_inquiries IS 'Initial admission inquiries and lead tracking';

-- =============================================
-- ADMISSION APPLICATIONS
-- =============================================

CREATE TABLE admission_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    inquiry_id UUID REFERENCES admission_inquiries(id) ON DELETE SET NULL,
    application_number VARCHAR(50) UNIQUE NOT NULL,
    application_date DATE NOT NULL DEFAULT CURRENT_DATE,
    target_class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    -- Student Information
    student_name VARCHAR(255) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    blood_group VARCHAR(5),
    previous_school VARCHAR(255),
    previous_grade VARCHAR(50),
    transfer_certificate_number VARCHAR(100),
    -- Parent Information
    father_name VARCHAR(255),
    father_occupation VARCHAR(255),
    father_phone VARCHAR(20),
    father_email VARCHAR(255),
    mother_name VARCHAR(255),
    mother_occupation VARCHAR(255),
    mother_phone VARCHAR(20),
    mother_email VARCHAR(255),
    guardian_name VARCHAR(255),
    guardian_relation VARCHAR(100),
    guardian_phone VARCHAR(20),
    -- Address
    current_address TEXT,
    permanent_address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    -- Application Status
    status application_status DEFAULT 'submitted',
    documents_submitted JSONB DEFAULT '{}', -- {"birth_certificate": "url", "report_card": "url"}
    documents_verified BOOLEAN DEFAULT false,
    documents_verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    documents_verified_at TIMESTAMPTZ,
    -- Assessment
    entrance_test_required BOOLEAN DEFAULT false,
    entrance_test_score DECIMAL(5,2),
    interview_required BOOLEAN DEFAULT false,
    interview_notes TEXT,
    interview_rating INT CHECK (interview_rating BETWEEN 1 AND 5),
    -- Decision
    decision VARCHAR(20),
    decision_date DATE,
    decision_by UUID REFERENCES users(id) ON DELETE SET NULL,
    decision_notes TEXT,
    rejection_reason TEXT,
    waitlist_position INT,
    -- Fee
    application_fee DECIMAL(10,2) DEFAULT 0,
    application_fee_paid BOOLEAN DEFAULT false,
    application_fee_payment_date DATE,
    -- Enrollment
    enrolled BOOLEAN DEFAULT false,
    enrolled_student_id UUID REFERENCES students(id) ON DELETE SET NULL,
    enrolled_at TIMESTAMPTZ,
    -- Metadata
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE admission_applications IS 'Formal admission applications with complete student information';

-- =============================================
-- ENTRANCE TESTS
-- =============================================

CREATE TABLE admission_entrance_tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID NOT NULL REFERENCES admission_applications(id) ON DELETE CASCADE,
    test_name VARCHAR(255) NOT NULL,
    test_date DATE NOT NULL,
    test_time TIME,
    location VARCHAR(255),
    duration_minutes INT,
    subjects_tested TEXT[] DEFAULT '{}',
    total_marks INT NOT NULL,
    marks_obtained DECIMAL(5,2),
    percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE WHEN total_marks > 0 THEN (marks_obtained / total_marks * 100) ELSE 0 END
    ) STORED,
    status test_status DEFAULT 'scheduled',
    evaluator_id UUID REFERENCES users(id) ON DELETE SET NULL,
    evaluation_notes TEXT,
    result_declared BOOLEAN DEFAULT false,
    result_declared_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE admission_entrance_tests IS 'Entrance test records for admission applications';

-- =============================================
-- ADMISSION INTERVIEWS
-- =============================================

CREATE TABLE admission_interviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID NOT NULL REFERENCES admission_applications(id) ON DELETE CASCADE,
    interview_date DATE NOT NULL,
    interview_time TIME,
    location VARCHAR(255),
    interviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    panel_members UUID[] DEFAULT '{}',
    duration_minutes INT,
    status test_status DEFAULT 'scheduled',
    -- Assessment Criteria
    academic_preparedness INT CHECK (academic_preparedness BETWEEN 1 AND 5),
    communication_skills INT CHECK (communication_skills BETWEEN 1 AND 5),
    attitude_behavior INT CHECK (attitude_behavior BETWEEN 1 AND 5),
    overall_impression INT CHECK (overall_impression BETWEEN 1 AND 5),
    recommendation VARCHAR(20), -- 'strongly_recommend', 'recommend', 'neutral', 'not_recommend'
    notes TEXT,
    parent_interview_conducted BOOLEAN DEFAULT false,
    parent_interview_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE admission_interviews IS 'Interview records for admission candidates';

-- =============================================
-- ADMISSION CAMPAIGNS
-- =============================================

CREATE TABLE admission_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    campaign_name VARCHAR(255) NOT NULL,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    target_classes UUID[] DEFAULT '{}',
    budget DECIMAL(10,2),
    actual_spend DECIMAL(10,2) DEFAULT 0,
    channels JSONB DEFAULT '[]', -- ["social_media", "newspaper", "radio"]
    inquiries_generated INT DEFAULT 0,
    applications_received INT DEFAULT 0,
    enrollments INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_campaign_dates CHECK (end_date >= start_date)
);

COMMENT ON TABLE admission_campaigns IS 'Marketing campaigns for admission drives';

-- =============================================
-- INDEXES
-- =============================================

-- Inquiries
CREATE INDEX idx_inquiries_tenant ON admission_inquiries(tenant_id, inquiry_date DESC);
CREATE INDEX idx_inquiries_status ON admission_inquiries(status, inquiry_date DESC);
CREATE INDEX idx_inquiries_assigned ON admission_inquiries(assigned_to, status)
    WHERE status NOT IN ('converted', 'lost');
CREATE INDEX idx_inquiries_followup ON admission_inquiries(next_followup_date)
    WHERE next_followup_date IS NOT NULL;
CREATE INDEX idx_inquiries_source ON admission_inquiries(inquiry_source, inquiry_date DESC);

-- Applications
CREATE INDEX idx_applications_tenant ON admission_applications(tenant_id, application_date DESC);
CREATE INDEX idx_applications_status ON admission_applications(status, application_date DESC);
CREATE INDEX idx_applications_class ON admission_applications(target_class_id, academic_year_id);
CREATE INDEX idx_applications_inquiry ON admission_applications(inquiry_id);
CREATE INDEX idx_applications_assigned ON admission_applications(assigned_to, status);
CREATE INDEX idx_applications_decision ON admission_applications(decision, decision_date DESC);

-- Entrance Tests
CREATE INDEX idx_entrance_tests_application ON admission_entrance_tests(application_id);
CREATE INDEX idx_entrance_tests_date ON admission_entrance_tests(test_date, status);
CREATE INDEX idx_entrance_tests_status ON admission_entrance_tests(status, test_date);

-- Interviews
CREATE INDEX idx_interviews_application ON admission_interviews(application_id);
CREATE INDEX idx_interviews_date ON admission_interviews(interview_date, status);
CREATE INDEX idx_interviews_interviewer ON admission_interviews(interviewer_id, interview_date DESC);

-- Campaigns
CREATE INDEX idx_campaigns_tenant ON admission_campaigns(tenant_id, is_active);
CREATE INDEX idx_campaigns_year ON admission_campaigns(academic_year_id);

-- =============================================
-- STORED PROCEDURES
-- =============================================

-- Convert application to enrollment
CREATE OR REPLACE FUNCTION convert_application_to_enrollment(p_application_id UUID)
RETURNS UUID AS $$
DECLARE
    v_app admission_applications%ROWTYPE;
    v_student_id UUID;
    v_parent_id UUID;
BEGIN
    -- Get application details
    SELECT * INTO v_app FROM admission_applications WHERE id = p_application_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Application not found: %', p_application_id;
    END IF;

    IF v_app.status != 'accepted' THEN
        RAISE EXCEPTION 'Application must be accepted before enrollment';
    END IF;

    -- TODO: Create student record
    -- TODO: Create parent record
    -- TODO: Create student_enrollment record
    -- TODO: Update application

    RETURN v_student_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION convert_application_to_enrollment IS 'Converts an accepted application to enrolled student';

-- Auto-generate inquiry number
CREATE OR REPLACE FUNCTION generate_inquiry_number()
RETURNS TRIGGER AS $$
DECLARE
    v_year VARCHAR(4);
    v_sequence INT;
    v_inquiry_number VARCHAR(50);
BEGIN
    IF NEW.inquiry_number IS NULL OR NEW.inquiry_number = '' THEN
        v_year := EXTRACT(YEAR FROM NEW.inquiry_date)::VARCHAR;

        SELECT COALESCE(MAX(
            SUBSTRING(inquiry_number FROM '\d+$')::INT
        ), 0) + 1
        INTO v_sequence
        FROM admission_inquiries
        WHERE inquiry_number LIKE 'INQ-' || v_year || '-%';

        NEW.inquiry_number := 'INQ-' || v_year || '-' || LPAD(v_sequence::VARCHAR, 5, '0');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_inquiry_number
    BEFORE INSERT ON admission_inquiries
    FOR EACH ROW
    EXECUTE FUNCTION generate_inquiry_number();

-- Auto-generate application number
CREATE OR REPLACE FUNCTION generate_application_number()
RETURNS TRIGGER AS $$
DECLARE
    v_year VARCHAR(4);
    v_sequence INT;
BEGIN
    IF NEW.application_number IS NULL OR NEW.application_number = '' THEN
        v_year := EXTRACT(YEAR FROM NEW.application_date)::VARCHAR;

        SELECT COALESCE(MAX(
            SUBSTRING(application_number FROM '\d+$')::INT
        ), 0) + 1
        INTO v_sequence
        FROM admission_applications
        WHERE application_number LIKE 'APP-' || v_year || '-%';

        NEW.application_number := 'APP-' || v_year || '-' || LPAD(v_sequence::VARCHAR, 5, '0');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_application_number
    BEFORE INSERT ON admission_applications
    FOR EACH ROW
    EXECUTE FUNCTION generate_application_number();

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE admission_inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE admission_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE admission_entrance_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE admission_interviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE admission_campaigns ENABLE ROW LEVEL SECURITY;
