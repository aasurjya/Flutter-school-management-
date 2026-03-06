-- ============================================
-- Alumni Management Module
-- ============================================

-- Enums
DO $$ BEGIN CREATE TYPE alumni_visibility AS ENUM ('public', 'alumni_only', 'private'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE alumni_event_type AS ENUM ('reunion', 'networking', 'career_talk', 'fundraiser', 'meetup'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE alumni_event_status AS ENUM ('upcoming', 'ongoing', 'completed', 'cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE alumni_registration_status AS ENUM ('registered', 'attended', 'cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE alumni_donation_purpose AS ENUM ('general', 'scholarship', 'infrastructure', 'sports', 'library'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE alumni_donation_status AS ENUM ('pending', 'completed', 'failed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE mentorship_program_status AS ENUM ('open', 'in_progress', 'completed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE mentorship_request_status AS ENUM ('pending', 'accepted', 'rejected', 'completed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE alumni_story_status AS ENUM ('draft', 'published'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================
-- alumni_profiles
-- ============================================
CREATE TABLE alumni_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    student_id UUID REFERENCES students(id) ON DELETE SET NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    graduation_year INT NOT NULL,
    class_name TEXT,
    profile_photo_url TEXT,
    current_company TEXT,
    current_designation TEXT,
    industry TEXT,
    location_city TEXT,
    location_country TEXT,
    linkedin_url TEXT,
    bio TEXT,
    skills JSONB DEFAULT '[]'::jsonb,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    is_mentor BOOLEAN NOT NULL DEFAULT false,
    visibility alumni_visibility NOT NULL DEFAULT 'alumni_only',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_alumni_profiles_tenant ON alumni_profiles(tenant_id);
CREATE INDEX idx_alumni_profiles_user ON alumni_profiles(user_id);
CREATE INDEX idx_alumni_profiles_student ON alumni_profiles(student_id);
CREATE INDEX idx_alumni_profiles_graduation_year ON alumni_profiles(tenant_id, graduation_year);
CREATE INDEX idx_alumni_profiles_industry ON alumni_profiles(tenant_id, industry);
CREATE INDEX idx_alumni_profiles_location ON alumni_profiles(tenant_id, location_city, location_country);
CREATE INDEX idx_alumni_profiles_mentor ON alumni_profiles(tenant_id, is_mentor) WHERE is_mentor = true;

-- ============================================
-- alumni_events
-- ============================================
CREATE TABLE alumni_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_type alumni_event_type NOT NULL DEFAULT 'meetup',
    date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    location TEXT,
    is_virtual BOOLEAN NOT NULL DEFAULT false,
    virtual_link TEXT,
    max_attendees INT,
    image_url TEXT,
    organizer_id UUID REFERENCES alumni_profiles(id) ON DELETE SET NULL,
    status alumni_event_status NOT NULL DEFAULT 'upcoming',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_alumni_events_tenant ON alumni_events(tenant_id);
CREATE INDEX idx_alumni_events_date ON alumni_events(tenant_id, date);
CREATE INDEX idx_alumni_events_status ON alumni_events(tenant_id, status);
CREATE INDEX idx_alumni_events_organizer ON alumni_events(organizer_id);

-- ============================================
-- alumni_event_registrations
-- ============================================
CREATE TABLE alumni_event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES alumni_events(id) ON DELETE CASCADE,
    alumni_id UUID NOT NULL REFERENCES alumni_profiles(id) ON DELETE CASCADE,
    status alumni_registration_status NOT NULL DEFAULT 'registered',
    registered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(event_id, alumni_id)
);

CREATE INDEX idx_alumni_event_reg_event ON alumni_event_registrations(event_id);
CREATE INDEX idx_alumni_event_reg_alumni ON alumni_event_registrations(alumni_id);

-- ============================================
-- alumni_donations
-- ============================================
CREATE TABLE alumni_donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    alumni_id UUID NOT NULL REFERENCES alumni_profiles(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'INR',
    purpose alumni_donation_purpose NOT NULL DEFAULT 'general',
    payment_method TEXT,
    transaction_ref TEXT,
    message TEXT,
    is_anonymous BOOLEAN NOT NULL DEFAULT false,
    status alumni_donation_status NOT NULL DEFAULT 'pending',
    donated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_alumni_donations_tenant ON alumni_donations(tenant_id);
CREATE INDEX idx_alumni_donations_alumni ON alumni_donations(alumni_id);
CREATE INDEX idx_alumni_donations_purpose ON alumni_donations(tenant_id, purpose);
CREATE INDEX idx_alumni_donations_status ON alumni_donations(tenant_id, status);
CREATE INDEX idx_alumni_donations_date ON alumni_donations(tenant_id, donated_at);

-- ============================================
-- mentorship_programs
-- ============================================
CREATE TABLE mentorship_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    mentor_id UUID NOT NULL REFERENCES alumni_profiles(id) ON DELETE CASCADE,
    mentee_count_limit INT NOT NULL DEFAULT 5,
    skills_offered JSONB DEFAULT '[]'::jsonb,
    status mentorship_program_status NOT NULL DEFAULT 'open',
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_mentorship_programs_tenant ON mentorship_programs(tenant_id);
CREATE INDEX idx_mentorship_programs_mentor ON mentorship_programs(mentor_id);
CREATE INDEX idx_mentorship_programs_status ON mentorship_programs(tenant_id, status);

-- ============================================
-- mentorship_requests
-- ============================================
CREATE TABLE mentorship_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID NOT NULL REFERENCES mentorship_programs(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    message TEXT,
    status mentorship_request_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(program_id, student_id)
);

CREATE INDEX idx_mentorship_requests_program ON mentorship_requests(program_id);
CREATE INDEX idx_mentorship_requests_student ON mentorship_requests(student_id);
CREATE INDEX idx_mentorship_requests_status ON mentorship_requests(status);

-- ============================================
-- alumni_success_stories
-- ============================================
CREATE TABLE alumni_success_stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    alumni_id UUID NOT NULL REFERENCES alumni_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    story_text TEXT NOT NULL,
    image_url TEXT,
    is_featured BOOLEAN NOT NULL DEFAULT false,
    approved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status alumni_story_status NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_alumni_stories_tenant ON alumni_success_stories(tenant_id);
CREATE INDEX idx_alumni_stories_alumni ON alumni_success_stories(alumni_id);
CREATE INDEX idx_alumni_stories_featured ON alumni_success_stories(tenant_id, is_featured) WHERE is_featured = true;
CREATE INDEX idx_alumni_stories_status ON alumni_success_stories(tenant_id, status);

-- ============================================
-- alumni_directory_searches (analytics)
-- ============================================
CREATE TABLE alumni_directory_searches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    searched_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    search_query TEXT,
    filters JSONB,
    result_count INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_alumni_dir_searches_tenant ON alumni_directory_searches(tenant_id);
CREATE INDEX idx_alumni_dir_searches_date ON alumni_directory_searches(created_at);

-- ============================================
-- Views
-- ============================================
CREATE OR REPLACE VIEW v_alumni_donation_summary AS
SELECT
    d.tenant_id,
    d.purpose,
    COUNT(*) AS donation_count,
    SUM(d.amount) AS total_amount,
    AVG(d.amount) AS avg_amount
FROM alumni_donations d
WHERE d.status = 'completed'
GROUP BY d.tenant_id, d.purpose;

-- ============================================
-- RLS Policies
-- ============================================
ALTER TABLE alumni_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumni_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumni_event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumni_donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentorship_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentorship_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumni_success_stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumni_directory_searches ENABLE ROW LEVEL SECURITY;

-- Alumni profiles: visible to same tenant users
CREATE POLICY alumni_profiles_select ON alumni_profiles
    FOR SELECT USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_profiles_insert ON alumni_profiles
    FOR INSERT WITH CHECK (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_profiles_update ON alumni_profiles
    FOR UPDATE USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_profiles_delete ON alumni_profiles
    FOR DELETE USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );

-- Events: visible to same tenant
CREATE POLICY alumni_events_select ON alumni_events
    FOR SELECT USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_events_insert ON alumni_events
    FOR INSERT WITH CHECK (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_events_update ON alumni_events
    FOR UPDATE USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_events_delete ON alumni_events
    FOR DELETE USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );

-- Registrations: accessible through event's tenant
CREATE POLICY alumni_event_reg_select ON alumni_event_registrations
    FOR SELECT USING (
        event_id IN (
            SELECT id FROM alumni_events
            WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
        )
    );
CREATE POLICY alumni_event_reg_insert ON alumni_event_registrations
    FOR INSERT WITH CHECK (
        event_id IN (
            SELECT id FROM alumni_events
            WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
        )
    );
CREATE POLICY alumni_event_reg_update ON alumni_event_registrations
    FOR UPDATE USING (
        event_id IN (
            SELECT id FROM alumni_events
            WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
        )
    );
CREATE POLICY alumni_event_reg_delete ON alumni_event_registrations
    FOR DELETE USING (
        event_id IN (
            SELECT id FROM alumni_events
            WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
        )
    );

-- Donations: visible to same tenant
CREATE POLICY alumni_donations_select ON alumni_donations
    FOR SELECT USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_donations_insert ON alumni_donations
    FOR INSERT WITH CHECK (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_donations_update ON alumni_donations
    FOR UPDATE USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );

-- Mentorship programs: visible to same tenant
CREATE POLICY mentorship_programs_select ON mentorship_programs
    FOR SELECT USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY mentorship_programs_insert ON mentorship_programs
    FOR INSERT WITH CHECK (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY mentorship_programs_update ON mentorship_programs
    FOR UPDATE USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY mentorship_programs_delete ON mentorship_programs
    FOR DELETE USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );

-- Mentorship requests: accessible through program's tenant
CREATE POLICY mentorship_requests_select ON mentorship_requests
    FOR SELECT USING (
        program_id IN (
            SELECT id FROM mentorship_programs
            WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
        )
    );
CREATE POLICY mentorship_requests_insert ON mentorship_requests
    FOR INSERT WITH CHECK (
        program_id IN (
            SELECT id FROM mentorship_programs
            WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
        )
    );
CREATE POLICY mentorship_requests_update ON mentorship_requests
    FOR UPDATE USING (
        program_id IN (
            SELECT id FROM mentorship_programs
            WHERE tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
        )
    );

-- Success stories: visible to same tenant
CREATE POLICY alumni_stories_select ON alumni_success_stories
    FOR SELECT USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_stories_insert ON alumni_success_stories
    FOR INSERT WITH CHECK (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_stories_update ON alumni_success_stories
    FOR UPDATE USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_stories_delete ON alumni_success_stories
    FOR DELETE USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );

-- Directory searches: visible to same tenant
CREATE POLICY alumni_dir_searches_select ON alumni_directory_searches
    FOR SELECT USING (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );
CREATE POLICY alumni_dir_searches_insert ON alumni_directory_searches
    FOR INSERT WITH CHECK (
        tenant_id IN (SELECT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
    );

-- ============================================
-- Triggers: updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_alumni_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_alumni_profiles_updated_at
    BEFORE UPDATE ON alumni_profiles
    FOR EACH ROW EXECUTE FUNCTION update_alumni_updated_at();

CREATE TRIGGER trg_alumni_events_updated_at
    BEFORE UPDATE ON alumni_events
    FOR EACH ROW EXECUTE FUNCTION update_alumni_updated_at();

CREATE TRIGGER trg_alumni_event_reg_updated_at
    BEFORE UPDATE ON alumni_event_registrations
    FOR EACH ROW EXECUTE FUNCTION update_alumni_updated_at();

CREATE TRIGGER trg_alumni_donations_updated_at
    BEFORE UPDATE ON alumni_donations
    FOR EACH ROW EXECUTE FUNCTION update_alumni_updated_at();

CREATE TRIGGER trg_mentorship_programs_updated_at
    BEFORE UPDATE ON mentorship_programs
    FOR EACH ROW EXECUTE FUNCTION update_alumni_updated_at();

CREATE TRIGGER trg_mentorship_requests_updated_at
    BEFORE UPDATE ON mentorship_requests
    FOR EACH ROW EXECUTE FUNCTION update_alumni_updated_at();

CREATE TRIGGER trg_alumni_stories_updated_at
    BEFORE UPDATE ON alumni_success_stories
    FOR EACH ROW EXECUTE FUNCTION update_alumni_updated_at();
