-- =============================================
-- Online Admissions / Enrollment Module
-- Migration 00015: Complete admission pipeline
-- =============================================

-- =============================================
-- ENUMS
-- =============================================

DO $$ BEGIN
  CREATE TYPE admission_inquiry_status AS ENUM (
    'new',
    'contacted',
    'visit_scheduled',
    'visit_completed',
    'application_sent',
    'converted',
    'lost'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE admission_inquiry_source AS ENUM (
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
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE admission_application_status AS ENUM (
    'draft',
    'submitted',
    'under_review',
    'interview_scheduled',
    'accepted',
    'rejected',
    'waitlisted',
    'enrolled',
    'withdrawn'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE admission_interview_status AS ENUM (
    'scheduled',
    'completed',
    'cancelled',
    'rescheduled',
    'no_show'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE admission_document_status AS ENUM (
    'pending',
    'uploaded',
    'verified',
    'rejected'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE admission_document_type AS ENUM (
    'birth_certificate',
    'transfer_certificate',
    'report_card',
    'address_proof',
    'photo',
    'parent_id',
    'medical_certificate',
    'caste_certificate',
    'income_certificate',
    'migration_certificate',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =============================================
-- ADMISSION INQUIRIES
-- =============================================

CREATE TABLE IF NOT EXISTS admission_inquiries_v2 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    -- Contact info
    student_name VARCHAR(255) NOT NULL,
    parent_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20) NOT NULL,
    -- Inquiry details
    source admission_inquiry_source NOT NULL DEFAULT 'walk_in',
    applying_for_class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    academic_year_id UUID REFERENCES academic_years(id) ON DELETE SET NULL,
    status admission_inquiry_status NOT NULL DEFAULT 'new',
    -- Assignment & follow-up
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    next_followup_date DATE,
    notes TEXT,
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admission_inquiries_v2_tenant
    ON admission_inquiries_v2(tenant_id);
CREATE INDEX IF NOT EXISTS idx_admission_inquiries_v2_status
    ON admission_inquiries_v2(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_admission_inquiries_v2_assigned
    ON admission_inquiries_v2(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_admission_inquiries_v2_followup
    ON admission_inquiries_v2(next_followup_date) WHERE next_followup_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_admission_inquiries_v2_created
    ON admission_inquiries_v2(tenant_id, created_at DESC);

-- =============================================
-- ADMISSION APPLICATIONS
-- =============================================

CREATE TABLE IF NOT EXISTS admission_applications_v2 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    inquiry_id UUID REFERENCES admission_inquiries_v2(id) ON DELETE SET NULL,
    application_number VARCHAR(50),
    -- Student info
    student_name VARCHAR(255) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    applying_for_class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    previous_school VARCHAR(255),
    previous_class VARCHAR(50),
    -- Parent info stored as JSONB for flexibility
    parent_info JSONB NOT NULL DEFAULT '{}',
    -- Documents stored as JSONB map of type -> url
    documents JSONB NOT NULL DEFAULT '{}',
    -- Address
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    -- Status
    status admission_application_status NOT NULL DEFAULT 'draft',
    status_notes TEXT,
    -- Decision
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    waitlist_position INT,
    -- Enrollment link
    enrolled_student_id UUID REFERENCES students(id) ON DELETE SET NULL,
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_admission_applications_v2_number
    ON admission_applications_v2(application_number) WHERE application_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_admission_applications_v2_tenant
    ON admission_applications_v2(tenant_id);
CREATE INDEX IF NOT EXISTS idx_admission_applications_v2_status
    ON admission_applications_v2(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_admission_applications_v2_class
    ON admission_applications_v2(applying_for_class_id, academic_year_id);
CREATE INDEX IF NOT EXISTS idx_admission_applications_v2_inquiry
    ON admission_applications_v2(inquiry_id) WHERE inquiry_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_admission_applications_v2_created
    ON admission_applications_v2(tenant_id, created_at DESC);

-- =============================================
-- ADMISSION INTERVIEWS
-- =============================================

CREATE TABLE IF NOT EXISTS admission_interviews_v2 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    application_id UUID NOT NULL REFERENCES admission_applications_v2(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMPTZ NOT NULL,
    interviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    location VARCHAR(255),
    -- Feedback
    feedback TEXT,
    score INT CHECK (score >= 0 AND score <= 100),
    recommendation VARCHAR(50),
    status admission_interview_status NOT NULL DEFAULT 'scheduled',
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admission_interviews_v2_application
    ON admission_interviews_v2(application_id);
CREATE INDEX IF NOT EXISTS idx_admission_interviews_v2_interviewer
    ON admission_interviews_v2(interviewer_id, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_admission_interviews_v2_date
    ON admission_interviews_v2(tenant_id, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_admission_interviews_v2_status
    ON admission_interviews_v2(status);

-- =============================================
-- ADMISSION DOCUMENTS
-- =============================================

CREATE TABLE IF NOT EXISTS admission_documents_v2 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    application_id UUID NOT NULL REFERENCES admission_applications_v2(id) ON DELETE CASCADE,
    document_type admission_document_type NOT NULL,
    file_url TEXT NOT NULL,
    file_name VARCHAR(255),
    -- Verification
    status admission_document_status NOT NULL DEFAULT 'uploaded',
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    rejection_reason TEXT,
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admission_documents_v2_application
    ON admission_documents_v2(application_id);
CREATE INDEX IF NOT EXISTS idx_admission_documents_v2_status
    ON admission_documents_v2(application_id, status);

-- =============================================
-- ADMISSION SETTINGS (per class per year)
-- =============================================

CREATE TABLE IF NOT EXISTS admission_settings_v2 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    -- Capacity
    total_seats INT NOT NULL DEFAULT 40,
    filled_seats INT NOT NULL DEFAULT 0,
    waitlist_limit INT NOT NULL DEFAULT 10,
    -- Fees
    application_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
    -- Required documents
    documents_required JSONB NOT NULL DEFAULT '["birth_certificate","report_card","address_proof","photo"]',
    -- Open/close dates
    admission_open BOOLEAN NOT NULL DEFAULT false,
    open_date DATE,
    close_date DATE,
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- One setting row per class per year per tenant
    CONSTRAINT uq_admission_settings_v2 UNIQUE(tenant_id, academic_year_id, class_id)
);

CREATE INDEX IF NOT EXISTS idx_admission_settings_v2_tenant
    ON admission_settings_v2(tenant_id, academic_year_id);

-- =============================================
-- AUTO-GENERATE APPLICATION NUMBER TRIGGER
-- =============================================

CREATE OR REPLACE FUNCTION generate_admission_app_number_v2()
RETURNS TRIGGER AS $$
DECLARE
    v_year VARCHAR(4);
    v_seq INT;
BEGIN
    IF NEW.application_number IS NULL OR NEW.application_number = '' THEN
        v_year := EXTRACT(YEAR FROM NOW())::VARCHAR;
        SELECT COALESCE(MAX(
            SUBSTRING(application_number FROM '\d+$')::INT
        ), 0) + 1
        INTO v_seq
        FROM admission_applications_v2
        WHERE tenant_id = NEW.tenant_id
          AND application_number LIKE 'ADM-' || v_year || '-%';

        NEW.application_number := 'ADM-' || v_year || '-' || LPAD(v_seq::VARCHAR, 5, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_admission_app_number_v2 ON admission_applications_v2;
CREATE TRIGGER trg_generate_admission_app_number_v2
    BEFORE INSERT ON admission_applications_v2
    FOR EACH ROW
    EXECUTE FUNCTION generate_admission_app_number_v2();

-- =============================================
-- UPDATED_AT TRIGGERS
-- =============================================

CREATE OR REPLACE FUNCTION update_admission_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_admission_inquiries_v2_updated ON admission_inquiries_v2;
CREATE TRIGGER trg_admission_inquiries_v2_updated
    BEFORE UPDATE ON admission_inquiries_v2
    FOR EACH ROW EXECUTE FUNCTION update_admission_updated_at();

DROP TRIGGER IF EXISTS trg_admission_applications_v2_updated ON admission_applications_v2;
CREATE TRIGGER trg_admission_applications_v2_updated
    BEFORE UPDATE ON admission_applications_v2
    FOR EACH ROW EXECUTE FUNCTION update_admission_updated_at();

DROP TRIGGER IF EXISTS trg_admission_interviews_v2_updated ON admission_interviews_v2;
CREATE TRIGGER trg_admission_interviews_v2_updated
    BEFORE UPDATE ON admission_interviews_v2
    FOR EACH ROW EXECUTE FUNCTION update_admission_updated_at();

DROP TRIGGER IF EXISTS trg_admission_documents_v2_updated ON admission_documents_v2;
CREATE TRIGGER trg_admission_documents_v2_updated
    BEFORE UPDATE ON admission_documents_v2
    FOR EACH ROW EXECUTE FUNCTION update_admission_updated_at();

DROP TRIGGER IF EXISTS trg_admission_settings_v2_updated ON admission_settings_v2;
CREATE TRIGGER trg_admission_settings_v2_updated
    BEFORE UPDATE ON admission_settings_v2
    FOR EACH ROW EXECUTE FUNCTION update_admission_updated_at();

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================

ALTER TABLE admission_inquiries_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE admission_applications_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE admission_interviews_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE admission_documents_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE admission_settings_v2 ENABLE ROW LEVEL SECURITY;

-- Policies: tenant isolation via has_role() helper (defined in 00006)
CREATE POLICY tenant_isolation_inquiries_v2 ON admission_inquiries_v2
    FOR ALL USING (tenant_id = (current_setting('app.tenant_id', true))::UUID);

CREATE POLICY tenant_isolation_applications_v2 ON admission_applications_v2
    FOR ALL USING (tenant_id = (current_setting('app.tenant_id', true))::UUID);

CREATE POLICY tenant_isolation_interviews_v2 ON admission_interviews_v2
    FOR ALL USING (tenant_id = (current_setting('app.tenant_id', true))::UUID);

CREATE POLICY tenant_isolation_documents_v2 ON admission_documents_v2
    FOR ALL USING (tenant_id = (current_setting('app.tenant_id', true))::UUID);

CREATE POLICY tenant_isolation_settings_v2 ON admission_settings_v2
    FOR ALL USING (tenant_id = (current_setting('app.tenant_id', true))::UUID);

-- =============================================
-- ADMISSION STATS VIEW
-- =============================================

CREATE OR REPLACE VIEW v_admission_stats AS
SELECT
    a.tenant_id,
    a.academic_year_id,
    a.applying_for_class_id,
    COUNT(*) AS total_applications,
    COUNT(*) FILTER (WHERE a.status = 'submitted') AS submitted_count,
    COUNT(*) FILTER (WHERE a.status = 'under_review') AS under_review_count,
    COUNT(*) FILTER (WHERE a.status = 'interview_scheduled') AS interview_scheduled_count,
    COUNT(*) FILTER (WHERE a.status = 'accepted') AS accepted_count,
    COUNT(*) FILTER (WHERE a.status = 'rejected') AS rejected_count,
    COUNT(*) FILTER (WHERE a.status = 'waitlisted') AS waitlisted_count,
    COUNT(*) FILTER (WHERE a.status = 'enrolled') AS enrolled_count,
    COUNT(*) FILTER (WHERE a.status = 'withdrawn') AS withdrawn_count,
    COUNT(*) FILTER (WHERE a.status = 'draft') AS draft_count
FROM admission_applications_v2 a
GROUP BY a.tenant_id, a.academic_year_id, a.applying_for_class_id;
