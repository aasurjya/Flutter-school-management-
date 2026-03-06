-- ============================================
-- VISITOR MANAGEMENT MODULE
-- Migration: 00024_visitor_management.sql
-- ============================================

CREATE EXTENSION IF NOT EXISTS moddatetime SCHEMA extensions;

-- Enums
DO $$ BEGIN CREATE TYPE visitor_id_type AS ENUM ('national_id', 'passport', 'drivers_license'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE visitor_log_purpose AS ENUM ('parent_visit', 'delivery', 'maintenance', 'meeting', 'interview', 'vendor', 'other'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE visitor_log_status AS ENUM ('pre_registered', 'checked_in', 'checked_out', 'denied'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE visitor_pre_reg_status AS ENUM ('pending', 'approved', 'denied', 'completed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================
-- visitors: recurring visitor profiles
-- ============================================
CREATE TABLE visitors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  photo_url TEXT,
  id_type visitor_id_type,
  id_number TEXT,
  company TEXT,
  is_blacklisted BOOLEAN NOT NULL DEFAULT FALSE,
  visit_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_visitors_tenant ON visitors(tenant_id);
CREATE INDEX idx_visitors_phone ON visitors(tenant_id, phone);
CREATE INDEX idx_visitors_name ON visitors(tenant_id, full_name);
CREATE INDEX idx_visitors_blacklisted ON visitors(tenant_id, is_blacklisted) WHERE is_blacklisted = TRUE;

ALTER TABLE visitors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant isolation for visitors"
  ON visitors FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM user_roles WHERE user_id = auth.uid()));

-- ============================================
-- visitor_logs: check-in / check-out records
-- ============================================
CREATE TABLE visitor_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  visitor_id UUID NOT NULL REFERENCES visitors(id) ON DELETE CASCADE,
  purpose visitor_log_purpose NOT NULL DEFAULT 'other',
  person_to_meet UUID REFERENCES users(id),
  department TEXT,
  check_in_time TIMESTAMPTZ NOT NULL DEFAULT now(),
  check_out_time TIMESTAMPTZ,
  badge_number TEXT,
  vehicle_number TEXT,
  items_carried TEXT,
  status visitor_log_status NOT NULL DEFAULT 'checked_in',
  notes TEXT,
  approved_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_visitor_logs_tenant ON visitor_logs(tenant_id);
CREATE INDEX idx_visitor_logs_visitor ON visitor_logs(visitor_id);
CREATE INDEX idx_visitor_logs_checkin ON visitor_logs(tenant_id, check_in_time DESC);
CREATE INDEX idx_visitor_logs_status ON visitor_logs(tenant_id, status);
CREATE INDEX idx_visitor_logs_badge ON visitor_logs(tenant_id, badge_number) WHERE badge_number IS NOT NULL;
CREATE INDEX idx_visitor_logs_date ON visitor_logs(tenant_id, check_in_time);

ALTER TABLE visitor_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant isolation for visitor_logs"
  ON visitor_logs FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM user_roles WHERE user_id = auth.uid()));

-- ============================================
-- visitor_pre_registrations: advance bookings
-- ============================================
CREATE TABLE visitor_pre_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  expected_date DATE NOT NULL,
  visitor_name TEXT NOT NULL,
  visitor_phone TEXT,
  visitor_email TEXT,
  purpose visitor_log_purpose NOT NULL DEFAULT 'other',
  host_id UUID REFERENCES users(id),
  status visitor_pre_reg_status NOT NULL DEFAULT 'pending',
  qr_code_data TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_visitor_prereg_tenant ON visitor_pre_registrations(tenant_id);
CREATE INDEX idx_visitor_prereg_date ON visitor_pre_registrations(tenant_id, expected_date);
CREATE INDEX idx_visitor_prereg_status ON visitor_pre_registrations(tenant_id, status);
CREATE INDEX idx_visitor_prereg_host ON visitor_pre_registrations(host_id);
CREATE UNIQUE INDEX idx_visitor_prereg_qr ON visitor_pre_registrations(qr_code_data) WHERE qr_code_data IS NOT NULL;

ALTER TABLE visitor_pre_registrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant isolation for visitor_pre_registrations"
  ON visitor_pre_registrations FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM user_roles WHERE user_id = auth.uid()));

-- ============================================
-- Trigger: increment visit_count on check-in
-- ============================================
CREATE OR REPLACE FUNCTION update_visitor_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'checked_in' THEN
    UPDATE visitors SET visit_count = visit_count + 1, updated_at = now()
    WHERE id = NEW.visitor_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_visitor_count
  AFTER INSERT ON visitor_logs
  FOR EACH ROW EXECUTE FUNCTION update_visitor_count();

-- ============================================
-- Trigger: auto-update updated_at
-- ============================================
CREATE TRIGGER trg_visitors_updated_at
  BEFORE UPDATE ON visitors
  FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(updated_at);

CREATE TRIGGER trg_visitor_logs_updated_at
  BEFORE UPDATE ON visitor_logs
  FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(updated_at);

CREATE TRIGGER trg_visitor_prereg_updated_at
  BEFORE UPDATE ON visitor_pre_registrations
  FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime(updated_at);
