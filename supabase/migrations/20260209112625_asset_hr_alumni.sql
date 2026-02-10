-- =============================================
-- Asset Management, HR & Alumni
-- Phase 5: Operations Management
-- =============================================

-- =============================================
-- ENUMS
-- =============================================

CREATE TYPE asset_condition AS ENUM ('excellent', 'good', 'fair', 'poor', 'damaged', 'unusable');

CREATE TYPE asset_status AS ENUM ('active', 'in_maintenance', 'retired', 'disposed', 'lost', 'stolen');

CREATE TYPE maintenance_type AS ENUM ('routine', 'preventive', 'repair', 'upgrade', 'inspection');

CREATE TYPE maintenance_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled', 'overdue');

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'leave_type') THEN
        CREATE TYPE leave_type AS ENUM ('sick', 'casual', 'earned', 'maternity', 'paternity', 'unpaid', 'compensatory');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'leave_status') THEN
        CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
    END IF;
END $$;

CREATE TYPE payroll_status AS ENUM ('draft', 'approved', 'paid', 'on_hold');

-- =============================================
-- ASSET MANAGEMENT
-- =============================================

CREATE TABLE asset_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    depreciation_rate DECIMAL(5,2) DEFAULT 0 CHECK (depreciation_rate >= 0 AND depreciation_rate <= 100),
    useful_life_years INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, category_name)
);

COMMENT ON TABLE asset_categories IS 'Categories for school assets';

CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    asset_category_id UUID NOT NULL REFERENCES asset_categories(id) ON DELETE CASCADE,
    asset_code VARCHAR(50) NOT NULL,
    asset_name VARCHAR(255) NOT NULL,
    description TEXT,
    purchase_date DATE,
    purchase_cost DECIMAL(12,2) CHECK (purchase_cost >= 0),
    current_value DECIMAL(12,2) CHECK (current_value >= 0),
    location VARCHAR(255),
    condition asset_condition DEFAULT 'good',
    status asset_status DEFAULT 'active',
    warranty_expiry DATE,
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    vendor_name VARCHAR(255),
    vendor_contact VARCHAR(255),
    serial_number VARCHAR(100),
    qr_code TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, asset_code)
);

COMMENT ON TABLE assets IS 'School assets and equipment inventory';

CREATE TABLE asset_maintenance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    maintenance_type maintenance_type NOT NULL,
    scheduled_date DATE NOT NULL,
    completed_date DATE,
    cost DECIMAL(10,2) DEFAULT 0 CHECK (cost >= 0),
    performed_by VARCHAR(255),
    vendor_name VARCHAR(255),
    notes TEXT,
    status maintenance_status DEFAULT 'scheduled',
    next_maintenance_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE asset_maintenance IS 'Asset maintenance records and schedules';

-- =============================================
-- STAFF HR MANAGEMENT
-- =============================================

CREATE TABLE staff_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    attendance_date DATE NOT NULL,
    check_in_time TIME,
    check_out_time TIME,
    status attendance_status DEFAULT 'present',
    working_hours DECIMAL(4,2) GENERATED ALWAYS AS (
        CASE
            WHEN check_in_time IS NOT NULL AND check_out_time IS NOT NULL
            THEN EXTRACT(EPOCH FROM (check_out_time - check_in_time)) / 3600
            ELSE 0
        END
    ) STORED,
    location VARCHAR(255),
    notes TEXT,
    marked_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(staff_id, attendance_date)
);

COMMENT ON TABLE staff_attendance IS 'Daily attendance records for staff members';

CREATE TABLE staff_leave_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    leave_type leave_type NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days_count INT GENERATED ALWAYS AS (
        (end_date - start_date) + 1
    ) STORED,
    reason TEXT NOT NULL,
    status leave_status DEFAULT 'pending',
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    supporting_documents JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_leave_dates CHECK (end_date >= start_date)
);

COMMENT ON TABLE staff_leave_applications IS 'Staff leave applications and approvals';

CREATE TABLE payroll (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    month DATE NOT NULL, -- First day of the month
    basic_salary DECIMAL(10,2) NOT NULL CHECK (basic_salary >= 0),
    allowances JSONB DEFAULT '{}', -- {"hra": 5000, "ta": 2000}
    deductions JSONB DEFAULT '{}', -- {"pf": 1800, "tax": 3000}
    gross_salary DECIMAL(10,2) NOT NULL CHECK (gross_salary >= 0),
    net_salary DECIMAL(10,2) NOT NULL CHECK (net_salary >= 0),
    payment_date DATE,
    payment_method payment_method,
    transaction_reference VARCHAR(100),
    status payroll_status DEFAULT 'draft',
    processed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(staff_id, month)
);

COMMENT ON TABLE payroll IS 'Monthly payroll records for staff';

CREATE TABLE performance_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    review_period_start DATE NOT NULL,
    review_period_end DATE NOT NULL,
    reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    overall_rating INT CHECK (overall_rating BETWEEN 1 AND 5),
    strengths TEXT,
    areas_for_improvement TEXT,
    goals_for_next_period TEXT[] DEFAULT '{}',
    achievements TEXT[] DEFAULT '{}',
    training_recommendations TEXT[] DEFAULT '{}',
    review_date DATE NOT NULL,
    review_status VARCHAR(50) DEFAULT 'draft',
    staff_acknowledgment BOOLEAN DEFAULT false,
    staff_acknowledgment_date DATE,
    staff_comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_review_period CHECK (review_period_end >= review_period_start)
);

COMMENT ON TABLE performance_reviews IS 'Staff performance review records';

-- =============================================
-- ALUMNI MANAGEMENT
-- =============================================

CREATE TABLE alumni (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE SET NULL,
    graduation_year INT NOT NULL,
    graduation_class VARCHAR(50),
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    current_occupation VARCHAR(255),
    current_employer VARCHAR(255),
    current_designation VARCHAR(255),
    current_city VARCHAR(100),
    current_country VARCHAR(100),
    linkedin_url TEXT,
    achievements TEXT[] DEFAULT '{}',
    willing_to_mentor BOOLEAN DEFAULT false,
    mentorship_areas TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    profile_visibility VARCHAR(20) DEFAULT 'public', -- 'public', 'alumni_only', 'private'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE alumni IS 'Alumni database for graduated students';

CREATE TABLE alumni_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    event_name VARCHAR(255) NOT NULL,
    event_date DATE NOT NULL,
    event_time TIME,
    location VARCHAR(255),
    description TEXT,
    target_graduation_years INT[] DEFAULT '{}',
    registration_required BOOLEAN DEFAULT true,
    registration_deadline DATE,
    max_attendees INT,
    current_attendees INT DEFAULT 0,
    event_fee DECIMAL(10,2) DEFAULT 0,
    organizer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE alumni_events IS 'Alumni reunion and networking events';

CREATE TABLE alumni_event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES alumni_events(id) ON DELETE CASCADE,
    alumni_id UUID NOT NULL REFERENCES alumni(id) ON DELETE CASCADE,
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    attended BOOLEAN DEFAULT false,
    attendance_marked_at TIMESTAMPTZ,
    payment_status VARCHAR(20) DEFAULT 'pending',
    payment_amount DECIMAL(10,2),
    companions INT DEFAULT 0,
    dietary_requirements TEXT,
    notes TEXT,
    UNIQUE(event_id, alumni_id)
);

COMMENT ON TABLE alumni_event_registrations IS 'Event registration records for alumni';

CREATE TABLE alumni_donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    alumni_id UUID NOT NULL REFERENCES alumni(id) ON DELETE CASCADE,
    donation_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    purpose TEXT,
    campaign_name VARCHAR(255),
    payment_method payment_method,
    transaction_reference VARCHAR(100),
    receipt_number VARCHAR(50),
    is_anonymous BOOLEAN DEFAULT false,
    is_recurring BOOLEAN DEFAULT false,
    tax_deductible BOOLEAN DEFAULT true,
    acknowledgment_sent BOOLEAN DEFAULT false,
    acknowledgment_sent_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE alumni_donations IS 'Alumni donation records';

-- =============================================
-- INDEXES
-- =============================================

-- Assets
CREATE INDEX idx_assets_tenant ON assets(tenant_id, status);
CREATE INDEX idx_assets_category ON assets(asset_category_id);
CREATE INDEX idx_assets_assigned ON assets(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_assets_status ON assets(status, condition);
CREATE INDEX idx_asset_maintenance_asset ON asset_maintenance(asset_id, scheduled_date DESC);
CREATE INDEX idx_asset_maintenance_status ON asset_maintenance(status, scheduled_date);

-- Staff HR
CREATE INDEX idx_staff_attendance_staff ON staff_attendance(staff_id, attendance_date DESC);
CREATE INDEX idx_staff_attendance_date ON staff_attendance(attendance_date);
CREATE INDEX idx_staff_leave_staff ON staff_leave_applications(staff_id, status);
CREATE INDEX idx_staff_leave_status ON staff_leave_applications(status, start_date);
CREATE INDEX idx_payroll_staff ON payroll(staff_id, month DESC);
CREATE INDEX idx_payroll_month ON payroll(month, status);
CREATE INDEX idx_performance_reviews_staff ON performance_reviews(staff_id, review_date DESC);

-- Alumni
CREATE INDEX idx_alumni_tenant ON alumni(tenant_id, is_active);
CREATE INDEX idx_alumni_graduation_year ON alumni(graduation_year DESC);
CREATE INDEX idx_alumni_willing_mentor ON alumni(willing_to_mentor) WHERE willing_to_mentor = true;
CREATE INDEX idx_alumni_events_tenant ON alumni_events(tenant_id, event_date DESC);
CREATE INDEX idx_alumni_events_published ON alumni_events(is_published, event_date) WHERE is_published = true;
CREATE INDEX idx_alumni_registrations_event ON alumni_event_registrations(event_id);
CREATE INDEX idx_alumni_donations_alumni ON alumni_donations(alumni_id, donation_date DESC);
CREATE INDEX idx_alumni_donations_date ON alumni_donations(donation_date DESC);

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE asset_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_leave_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumni ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumni_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumni_event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumni_donations ENABLE ROW LEVEL SECURITY;
