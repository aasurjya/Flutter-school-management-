-- =============================================
-- Student Check-in / Check-out tracking
-- =============================================

CREATE TABLE IF NOT EXISTS student_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
  check_type TEXT NOT NULL CHECK (check_type IN ('check_in', 'check_out')),
  checked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  checked_by UUID REFERENCES users(id),
  method TEXT NOT NULL DEFAULT 'qr_scan' CHECK (method IN ('qr_scan', 'manual')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_student_checkins_tenant ON student_checkins(tenant_id);
CREATE INDEX idx_student_checkins_student ON student_checkins(student_id);
CREATE INDEX idx_student_checkins_section ON student_checkins(section_id);
CREATE INDEX idx_student_checkins_date ON student_checkins(checked_at);

-- RLS
ALTER TABLE student_checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant isolation for student_checkins"
  ON student_checkins
  FOR ALL
  USING (tenant_id = (current_setting('request.jwt.claims', true)::json->>'tenant_id')::uuid);

CREATE POLICY "Teachers can insert checkins"
  ON student_checkins
  FOR INSERT
  WITH CHECK (
    checked_by = auth.uid()
  );

CREATE POLICY "Teachers can view checkins"
  ON student_checkins
  FOR SELECT
  USING (true);
