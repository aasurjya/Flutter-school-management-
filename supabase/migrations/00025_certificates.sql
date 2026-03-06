-- ============================================
-- CERTIFICATE GENERATOR MODULE
-- Migration: 00025_certificates.sql
-- ============================================

-- Enums
CREATE TYPE certificate_type AS ENUM (
  'transfer', 'bonafide', 'character', 'migration',
  'achievement', 'participation', 'merit', 'custom'
);
CREATE TYPE certificate_status AS ENUM ('draft', 'issued', 'revoked');

-- ============================================
-- certificate_templates: reusable templates
-- ============================================
CREATE TABLE certificate_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type certificate_type NOT NULL DEFAULT 'custom',
  layout_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  variables JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cert_templates_tenant ON certificate_templates(tenant_id);
CREATE INDEX idx_cert_templates_type ON certificate_templates(tenant_id, type);
CREATE INDEX idx_cert_templates_active ON certificate_templates(tenant_id, is_active) WHERE is_active = TRUE;

ALTER TABLE certificate_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant isolation for certificate_templates"
  ON certificate_templates FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM user_roles WHERE user_id = auth.uid()));

-- ============================================
-- issued_certificates: actual issued certs
-- ============================================
CREATE TABLE issued_certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  template_id UUID NOT NULL REFERENCES certificate_templates(id) ON DELETE RESTRICT,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  certificate_number TEXT NOT NULL,
  issued_date DATE NOT NULL DEFAULT CURRENT_DATE,
  issued_by UUID REFERENCES users(id),
  purpose TEXT,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  pdf_url TEXT,
  status certificate_status NOT NULL DEFAULT 'draft',
  revoked_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_issued_certs_number ON issued_certificates(tenant_id, certificate_number);
CREATE INDEX idx_issued_certs_tenant ON issued_certificates(tenant_id);
CREATE INDEX idx_issued_certs_student ON issued_certificates(student_id);
CREATE INDEX idx_issued_certs_template ON issued_certificates(template_id);
CREATE INDEX idx_issued_certs_status ON issued_certificates(tenant_id, status);
CREATE INDEX idx_issued_certs_date ON issued_certificates(tenant_id, issued_date DESC);
CREATE INDEX idx_issued_certs_type ON issued_certificates(tenant_id, (data->>'type'));

ALTER TABLE issued_certificates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant isolation for issued_certificates"
  ON issued_certificates FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM user_roles WHERE user_id = auth.uid()));

-- ============================================
-- certificate_number_sequences: auto-numbering
-- ============================================
CREATE TABLE certificate_number_sequences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  template_type certificate_type NOT NULL,
  prefix TEXT NOT NULL DEFAULT 'CERT',
  current_number INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, template_type)
);

CREATE INDEX idx_cert_seq_tenant ON certificate_number_sequences(tenant_id);

ALTER TABLE certificate_number_sequences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant isolation for certificate_number_sequences"
  ON certificate_number_sequences FOR ALL
  USING (tenant_id IN (SELECT tenant_id FROM user_roles WHERE user_id = auth.uid()));

-- ============================================
-- Function: generate next certificate number
-- ============================================
CREATE OR REPLACE FUNCTION generate_certificate_number(
  p_tenant_id UUID,
  p_type certificate_type
) RETURNS TEXT AS $$
DECLARE
  v_prefix TEXT;
  v_number INTEGER;
  v_year TEXT;
BEGIN
  v_year := TO_CHAR(CURRENT_DATE, 'YYYY');

  -- Upsert and increment
  INSERT INTO certificate_number_sequences (tenant_id, template_type, prefix, current_number)
  VALUES (p_tenant_id, p_type, UPPER(p_type::text), 1)
  ON CONFLICT (tenant_id, template_type)
  DO UPDATE SET current_number = certificate_number_sequences.current_number + 1,
                updated_at = now()
  RETURNING prefix, current_number INTO v_prefix, v_number;

  RETURN v_prefix || '-' || v_year || '-' || LPAD(v_number::text, 5, '0');
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Triggers: auto-update updated_at
-- ============================================
CREATE TRIGGER trg_cert_templates_updated_at
  BEFORE UPDATE ON certificate_templates
  FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);

CREATE TRIGGER trg_issued_certs_updated_at
  BEFORE UPDATE ON issued_certificates
  FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);

CREATE TRIGGER trg_cert_seq_updated_at
  BEFORE UPDATE ON certificate_number_sequences
  FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);
