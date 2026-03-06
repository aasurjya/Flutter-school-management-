-- ============================================================================
-- HR & Payroll Module
-- ============================================================================

-- Enums
DO $$ BEGIN
  CREATE TYPE contract_type AS ENUM ('permanent', 'temporary', 'contract', 'probation');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE contract_status AS ENUM ('active', 'expired', 'terminated');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE salary_component_type AS ENUM ('earning', 'deduction');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE salary_calculation_type AS ENUM ('fixed', 'percentage');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE payroll_run_status AS ENUM ('draft', 'processing', 'completed', 'approved');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE payroll_payment_status AS ENUM ('pending', 'paid', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE staff_attendance_status AS ENUM ('present', 'absent', 'half_day', 'on_leave', 'holiday');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE tax_declaration_status AS ENUM ('draft', 'submitted', 'verified');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE staff_document_type AS ENUM (
    'resume', 'id_proof', 'address_proof', 'qualification',
    'experience_letter', 'offer_letter', 'contract'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- 1. departments
-- ============================================================================
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  head_of_department_id UUID REFERENCES users(id) ON DELETE SET NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_departments_tenant ON departments(tenant_id);
CREATE UNIQUE INDEX idx_departments_tenant_name ON departments(tenant_id, name);

-- ============================================================================
-- 2. designations
-- ============================================================================
CREATE TABLE IF NOT EXISTS designations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  level INTEGER NOT NULL DEFAULT 1,
  pay_grade TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_designations_tenant ON designations(tenant_id);
CREATE INDEX idx_designations_department ON designations(department_id);
CREATE UNIQUE INDEX idx_designations_tenant_name ON designations(tenant_id, name);

-- ============================================================================
-- 3. staff_contracts
-- ============================================================================
CREATE TABLE IF NOT EXISTS staff_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  contract_type contract_type NOT NULL DEFAULT 'permanent',
  start_date DATE NOT NULL,
  end_date DATE,
  basic_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
  hra NUMERIC(12,2) NOT NULL DEFAULT 0,
  da NUMERIC(12,2) NOT NULL DEFAULT 0,
  ta NUMERIC(12,2) NOT NULL DEFAULT 0,
  other_allowances JSONB DEFAULT '{}',
  deductions JSONB DEFAULT '{}',
  gross_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
  net_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
  status contract_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_staff_contracts_tenant ON staff_contracts(tenant_id);
CREATE INDEX idx_staff_contracts_staff ON staff_contracts(staff_id);
CREATE INDEX idx_staff_contracts_status ON staff_contracts(status);
CREATE INDEX idx_staff_contracts_end_date ON staff_contracts(end_date);

-- ============================================================================
-- 4. salary_structures
-- ============================================================================
CREATE TABLE IF NOT EXISTS salary_structures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  components JSONB NOT NULL DEFAULT '[]',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_salary_structures_tenant ON salary_structures(tenant_id);

-- ============================================================================
-- 5. payroll_runs
-- ============================================================================
CREATE TABLE IF NOT EXISTS payroll_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
  year INTEGER NOT NULL CHECK (year BETWEEN 2000 AND 2100),
  run_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status payroll_run_status NOT NULL DEFAULT 'draft',
  total_gross NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_deductions NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_net NUMERIC(14,2) NOT NULL DEFAULT 0,
  approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payroll_runs_tenant ON payroll_runs(tenant_id);
CREATE INDEX idx_payroll_runs_month_year ON payroll_runs(tenant_id, year, month);
CREATE UNIQUE INDEX idx_payroll_runs_unique ON payroll_runs(tenant_id, month, year);

-- ============================================================================
-- 6. payroll_items
-- ============================================================================
CREATE TABLE IF NOT EXISTS payroll_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payroll_run_id UUID NOT NULL REFERENCES payroll_runs(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  basic_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
  earnings JSONB NOT NULL DEFAULT '{}',
  deductions JSONB NOT NULL DEFAULT '{}',
  gross_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
  tax_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  net_salary NUMERIC(12,2) NOT NULL DEFAULT 0,
  payment_status payroll_payment_status NOT NULL DEFAULT 'pending',
  payment_method TEXT,
  payment_ref TEXT,
  days_worked INTEGER NOT NULL DEFAULT 0,
  days_absent INTEGER NOT NULL DEFAULT 0,
  overtime_hours NUMERIC(6,2) NOT NULL DEFAULT 0,
  overtime_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payroll_items_run ON payroll_items(payroll_run_id);
CREATE INDEX idx_payroll_items_staff ON payroll_items(staff_id);
CREATE UNIQUE INDEX idx_payroll_items_unique ON payroll_items(payroll_run_id, staff_id);

-- ============================================================================
-- 7. salary_slips
-- ============================================================================
CREATE TABLE IF NOT EXISTS salary_slips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payroll_item_id UUID NOT NULL REFERENCES payroll_items(id) ON DELETE CASCADE,
  slip_number TEXT NOT NULL,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  pdf_url TEXT,
  sent_to_staff BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_salary_slips_slip_number ON salary_slips(slip_number);
CREATE INDEX idx_salary_slips_payroll_item ON salary_slips(payroll_item_id);

-- ============================================================================
-- 8. staff_attendance_daily
-- ============================================================================
CREATE TABLE IF NOT EXISTS staff_attendance_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  check_in TIME,
  check_out TIME,
  status staff_attendance_status NOT NULL DEFAULT 'present',
  overtime_hours NUMERIC(6,2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_staff_attendance_tenant ON staff_attendance_daily(tenant_id);
CREATE INDEX idx_staff_attendance_staff ON staff_attendance_daily(staff_id);
CREATE INDEX idx_staff_attendance_date ON staff_attendance_daily(date);
CREATE UNIQUE INDEX idx_staff_attendance_unique ON staff_attendance_daily(staff_id, date);

-- ============================================================================
-- 9. tax_declarations
-- ============================================================================
CREATE TABLE IF NOT EXISTS tax_declarations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  financial_year TEXT NOT NULL,
  section_80c JSONB DEFAULT '{}',
  section_80d JSONB DEFAULT '{}',
  hra_exemption NUMERIC(12,2) NOT NULL DEFAULT 0,
  other_declarations JSONB DEFAULT '{}',
  status tax_declaration_status NOT NULL DEFAULT 'draft',
  verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tax_declarations_tenant ON tax_declarations(tenant_id);
CREATE INDEX idx_tax_declarations_staff ON tax_declarations(staff_id);
CREATE UNIQUE INDEX idx_tax_declarations_unique ON tax_declarations(staff_id, financial_year);

-- ============================================================================
-- 10. staff_documents
-- ============================================================================
CREATE TABLE IF NOT EXISTS staff_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  document_type staff_document_type NOT NULL,
  file_url TEXT NOT NULL,
  file_name TEXT,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_staff_documents_tenant ON staff_documents(tenant_id);
CREATE INDEX idx_staff_documents_staff ON staff_documents(staff_id);

-- ============================================================================
-- RLS Policies
-- ============================================================================
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE designations ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE salary_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE salary_slips ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_attendance_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_declarations ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_documents ENABLE ROW LEVEL SECURITY;

-- Departments: tenant-scoped read for all authenticated, write for admins
CREATE POLICY departments_select ON departments
  FOR SELECT TO authenticated
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY departments_insert ON departments
  FOR INSERT TO authenticated
  WITH CHECK (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND has_role(auth.uid(), tenant_id, 'tenant_admin')
  );

CREATE POLICY departments_update ON departments
  FOR UPDATE TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND has_role(auth.uid(), tenant_id, 'tenant_admin')
  );

CREATE POLICY departments_delete ON departments
  FOR DELETE TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND has_role(auth.uid(), tenant_id, 'tenant_admin')
  );

-- Designations
CREATE POLICY designations_select ON designations
  FOR SELECT TO authenticated
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY designations_modify ON designations
  FOR ALL TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND has_role(auth.uid(), tenant_id, 'tenant_admin')
  );

-- Staff contracts: admin read/write, staff can read own
CREATE POLICY staff_contracts_admin ON staff_contracts
  FOR ALL TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND (
      has_role(auth.uid(), tenant_id, 'tenant_admin')
      OR has_role(auth.uid(), tenant_id, 'accountant')
    )
  );

CREATE POLICY staff_contracts_own ON staff_contracts
  FOR SELECT TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND staff_id IN (SELECT id FROM staff WHERE user_id = auth.uid())
  );

-- Salary structures
CREATE POLICY salary_structures_select ON salary_structures
  FOR SELECT TO authenticated
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY salary_structures_modify ON salary_structures
  FOR ALL TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND has_role(auth.uid(), tenant_id, 'tenant_admin')
  );

-- Payroll runs
CREATE POLICY payroll_runs_admin ON payroll_runs
  FOR ALL TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND (
      has_role(auth.uid(), tenant_id, 'tenant_admin')
      OR has_role(auth.uid(), tenant_id, 'accountant')
    )
  );

-- Payroll items: admin/accountant read all, staff read own
CREATE POLICY payroll_items_admin ON payroll_items
  FOR ALL TO authenticated
  USING (
    payroll_run_id IN (
      SELECT id FROM payroll_runs
      WHERE tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    )
    AND (
      has_role(auth.uid(), (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID, 'tenant_admin')
      OR has_role(auth.uid(), (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID, 'accountant')
    )
  );

CREATE POLICY payroll_items_own ON payroll_items
  FOR SELECT TO authenticated
  USING (
    staff_id IN (SELECT id FROM staff WHERE user_id = auth.uid())
  );

-- Salary slips: admin read all, staff read own
CREATE POLICY salary_slips_admin ON salary_slips
  FOR ALL TO authenticated
  USING (
    payroll_item_id IN (
      SELECT pi.id FROM payroll_items pi
      JOIN payroll_runs pr ON pi.payroll_run_id = pr.id
      WHERE pr.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    )
    AND (
      has_role(auth.uid(), (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID, 'tenant_admin')
      OR has_role(auth.uid(), (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID, 'accountant')
    )
  );

CREATE POLICY salary_slips_own ON salary_slips
  FOR SELECT TO authenticated
  USING (
    payroll_item_id IN (
      SELECT pi.id FROM payroll_items pi
      JOIN staff s ON pi.staff_id = s.id
      WHERE s.user_id = auth.uid()
    )
  );

-- Staff attendance daily
CREATE POLICY staff_attendance_admin ON staff_attendance_daily
  FOR ALL TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND (
      has_role(auth.uid(), tenant_id, 'tenant_admin')
      OR has_role(auth.uid(), tenant_id, 'accountant')
    )
  );

CREATE POLICY staff_attendance_own ON staff_attendance_daily
  FOR SELECT TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND staff_id IN (SELECT id FROM staff WHERE user_id = auth.uid())
  );

-- Tax declarations: admin verify, staff manage own
CREATE POLICY tax_declarations_admin ON tax_declarations
  FOR ALL TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND (
      has_role(auth.uid(), tenant_id, 'tenant_admin')
      OR has_role(auth.uid(), tenant_id, 'accountant')
    )
  );

CREATE POLICY tax_declarations_own ON tax_declarations
  FOR ALL TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND staff_id IN (SELECT id FROM staff WHERE user_id = auth.uid())
  );

-- Staff documents
CREATE POLICY staff_documents_admin ON staff_documents
  FOR ALL TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND has_role(auth.uid(), tenant_id, 'tenant_admin')
  );

CREATE POLICY staff_documents_own ON staff_documents
  FOR SELECT TO authenticated
  USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND staff_id IN (SELECT id FROM staff WHERE user_id = auth.uid())
  );

-- ============================================================================
-- Triggers: auto-update updated_at
-- ============================================================================
CREATE OR REPLACE FUNCTION update_hr_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_departments_updated_at BEFORE UPDATE ON departments
  FOR EACH ROW EXECUTE FUNCTION update_hr_updated_at();

CREATE TRIGGER trg_designations_updated_at BEFORE UPDATE ON designations
  FOR EACH ROW EXECUTE FUNCTION update_hr_updated_at();

CREATE TRIGGER trg_staff_contracts_updated_at BEFORE UPDATE ON staff_contracts
  FOR EACH ROW EXECUTE FUNCTION update_hr_updated_at();

CREATE TRIGGER trg_salary_structures_updated_at BEFORE UPDATE ON salary_structures
  FOR EACH ROW EXECUTE FUNCTION update_hr_updated_at();

CREATE TRIGGER trg_payroll_runs_updated_at BEFORE UPDATE ON payroll_runs
  FOR EACH ROW EXECUTE FUNCTION update_hr_updated_at();

CREATE TRIGGER trg_payroll_items_updated_at BEFORE UPDATE ON payroll_items
  FOR EACH ROW EXECUTE FUNCTION update_hr_updated_at();

CREATE TRIGGER trg_staff_attendance_updated_at BEFORE UPDATE ON staff_attendance_daily
  FOR EACH ROW EXECUTE FUNCTION update_hr_updated_at();

CREATE TRIGGER trg_tax_declarations_updated_at BEFORE UPDATE ON tax_declarations
  FOR EACH ROW EXECUTE FUNCTION update_hr_updated_at();

-- ============================================================================
-- RPC: Generate payroll for a given month/year
-- ============================================================================
CREATE OR REPLACE FUNCTION generate_payroll(
  p_tenant_id UUID,
  p_month INTEGER,
  p_year INTEGER,
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_run_id UUID;
  v_staff RECORD;
  v_days_in_month INTEGER;
  v_days_absent INTEGER;
  v_days_worked INTEGER;
  v_overtime NUMERIC(6,2);
  v_total_gross NUMERIC(14,2) := 0;
  v_total_deductions NUMERIC(14,2) := 0;
  v_total_net NUMERIC(14,2) := 0;
  v_earnings JSONB;
  v_deductions JSONB;
  v_gross NUMERIC(12,2);
  v_ded_total NUMERIC(12,2);
  v_net NUMERIC(12,2);
  v_tax NUMERIC(12,2);
BEGIN
  -- Calculate days in month
  v_days_in_month := EXTRACT(DAY FROM (make_date(p_year, p_month, 1) + INTERVAL '1 month - 1 day'));

  -- Create payroll run
  INSERT INTO payroll_runs (tenant_id, month, year, notes, status)
  VALUES (p_tenant_id, p_month, p_year, p_notes, 'processing')
  RETURNING id INTO v_run_id;

  -- Process each active staff member with an active contract
  FOR v_staff IN
    SELECT
      sc.staff_id,
      sc.basic_salary,
      sc.hra,
      sc.da,
      sc.ta,
      sc.other_allowances,
      sc.deductions AS contract_deductions,
      sc.gross_salary,
      sc.net_salary
    FROM staff_contracts sc
    JOIN staff s ON sc.staff_id = s.id
    WHERE sc.tenant_id = p_tenant_id
      AND sc.status = 'active'
      AND s.is_active = TRUE
  LOOP
    -- Count absent days in this month
    SELECT COALESCE(COUNT(*), 0) INTO v_days_absent
    FROM staff_attendance_daily
    WHERE staff_id = v_staff.staff_id
      AND date >= make_date(p_year, p_month, 1)
      AND date < make_date(p_year, p_month, 1) + INTERVAL '1 month'
      AND status IN ('absent');

    -- Sum overtime hours
    SELECT COALESCE(SUM(overtime_hours), 0) INTO v_overtime
    FROM staff_attendance_daily
    WHERE staff_id = v_staff.staff_id
      AND date >= make_date(p_year, p_month, 1)
      AND date < make_date(p_year, p_month, 1) + INTERVAL '1 month';

    v_days_worked := v_days_in_month - v_days_absent;

    -- Build earnings JSONB
    v_earnings := jsonb_build_object(
      'basic', v_staff.basic_salary,
      'hra', v_staff.hra,
      'da', v_staff.da,
      'ta', v_staff.ta
    );

    -- Calculate gross (pro-rata for absent days)
    v_gross := (v_staff.basic_salary + v_staff.hra + v_staff.da + v_staff.ta)
               * v_days_worked / v_days_in_month;

    -- Calculate deductions
    v_deductions := COALESCE(v_staff.contract_deductions, '{}'::JSONB);
    v_ded_total := 0;

    -- Sum all deduction values from JSONB
    SELECT COALESCE(SUM((value)::NUMERIC), 0) INTO v_ded_total
    FROM jsonb_each_text(v_deductions);

    -- Simple tax estimation (10% of gross above 25000)
    v_tax := GREATEST(0, (v_gross - 25000) * 0.10);

    v_net := v_gross - v_ded_total - v_tax;

    -- Insert payroll item
    INSERT INTO payroll_items (
      payroll_run_id, staff_id, basic_salary, earnings, deductions,
      gross_salary, tax_amount, net_salary, days_worked, days_absent,
      overtime_hours, overtime_amount
    ) VALUES (
      v_run_id, v_staff.staff_id, v_staff.basic_salary, v_earnings, v_deductions,
      v_gross, v_tax, v_net, v_days_worked, v_days_absent,
      v_overtime, v_overtime * (v_staff.basic_salary / v_days_in_month / 8) -- OT rate = daily/8
    );

    v_total_gross := v_total_gross + v_gross;
    v_total_deductions := v_total_deductions + v_ded_total + v_tax;
    v_total_net := v_total_net + v_net;
  END LOOP;

  -- Update payroll run totals
  UPDATE payroll_runs SET
    total_gross = v_total_gross,
    total_deductions = v_total_deductions,
    total_net = v_total_net,
    status = 'completed'
  WHERE id = v_run_id;

  RETURN v_run_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- View: HR dashboard stats
-- ============================================================================
CREATE OR REPLACE VIEW v_hr_dashboard_stats AS
SELECT
  s.tenant_id,
  COUNT(DISTINCT s.id) AS total_staff,
  COUNT(DISTINCT CASE WHEN s.is_active THEN s.id END) AS active_staff,
  COUNT(DISTINCT d.id) AS total_departments,
  COUNT(DISTINCT sc.id) FILTER (WHERE sc.status = 'active') AS active_contracts,
  COUNT(DISTINCT sc.id) FILTER (
    WHERE sc.status = 'active'
      AND sc.end_date IS NOT NULL
      AND sc.end_date <= CURRENT_DATE + INTERVAL '30 days'
  ) AS expiring_contracts,
  COALESCE(SUM(sc.net_salary) FILTER (WHERE sc.status = 'active'), 0) AS monthly_payroll_estimate
FROM staff s
LEFT JOIN staff_contracts sc ON s.id = sc.staff_id
LEFT JOIN departments d ON d.tenant_id = s.tenant_id AND d.is_active = TRUE
WHERE s.tenant_id = s.tenant_id
GROUP BY s.tenant_id;
