-- =============================================
-- Advanced Fee Management
-- Phase 2: Payment Plans, Dunning, Concessions
-- =============================================

-- =============================================
-- ENUMS
-- =============================================

CREATE TYPE payment_plan_status AS ENUM ('active', 'completed', 'defaulted', 'cancelled');

CREATE TYPE installment_frequency AS ENUM ('weekly', 'biweekly', 'monthly', 'quarterly');

CREATE TYPE installment_status AS ENUM ('pending', 'paid', 'overdue', 'waived', 'rescheduled');

CREATE TYPE dunning_stage AS ENUM (
    'reminder_1',
    'reminder_2',
    'reminder_3',
    'warning',
    'final_notice',
    'service_suspension'
);

CREATE TYPE dunning_action_type AS ENUM (
    'email',
    'sms',
    'phone_call',
    'letter',
    'in_person_meeting'
);

CREATE TYPE concession_type AS ENUM (
    'scholarship',
    'sibling_discount',
    'merit_based',
    'financial_hardship',
    'staff_child',
    'early_bird',
    'loyalty_discount',
    'need_based'
);

CREATE TYPE discount_type AS ENUM ('percentage', 'fixed_amount');

-- =============================================
-- FEE PAYMENT PLANS
-- =============================================

CREATE TABLE fee_payment_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    plan_name VARCHAR(100) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    down_payment DECIMAL(10,2) DEFAULT 0 CHECK (down_payment >= 0),
    installment_amount DECIMAL(10,2) NOT NULL CHECK (installment_amount >= 0),
    number_of_installments INT NOT NULL CHECK (number_of_installments > 0),
    frequency installment_frequency NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    interest_rate DECIMAL(5,2) DEFAULT 0 CHECK (interest_rate >= 0), -- annual percentage
    processing_fee DECIMAL(10,2) DEFAULT 0 CHECK (processing_fee >= 0),
    late_fee_per_day DECIMAL(8,2) DEFAULT 0 CHECK (late_fee_per_day >= 0),
    status payment_plan_status DEFAULT 'active',
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    CONSTRAINT valid_date_range CHECK (end_date > start_date),
    CONSTRAINT valid_down_payment CHECK (down_payment <= total_amount)
);

COMMENT ON TABLE fee_payment_plans IS 'Payment installment plans for student fees';
COMMENT ON COLUMN fee_payment_plans.interest_rate IS 'Annual interest rate percentage applied to installments';
COMMENT ON COLUMN fee_payment_plans.late_fee_per_day IS 'Daily late fee charged for overdue installments';

-- =============================================
-- PAYMENT INSTALLMENTS
-- =============================================

CREATE TABLE payment_installments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_plan_id UUID NOT NULL REFERENCES fee_payment_plans(id) ON DELETE CASCADE,
    installment_number INT NOT NULL CHECK (installment_number > 0),
    due_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    late_fee DECIMAL(8,2) DEFAULT 0 CHECK (late_fee >= 0),
    status installment_status DEFAULT 'pending',
    paid_amount DECIMAL(10,2) DEFAULT 0 CHECK (paid_amount >= 0),
    paid_date DATE,
    payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
    reminder_sent BOOLEAN DEFAULT false,
    reminder_sent_at TIMESTAMPTZ,
    days_overdue INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(payment_plan_id, installment_number)
);

COMMENT ON TABLE payment_installments IS 'Individual installments within payment plans';
COMMENT ON COLUMN payment_installments.days_overdue IS 'Auto-calculated number of days past due date';

-- =============================================
-- DUNNING WORKFLOWS
-- =============================================

CREATE TABLE fee_dunning_workflows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    workflow_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    stages JSONB NOT NULL DEFAULT '[]', -- [{"stage": "reminder_1", "days_overdue": 1, "actions": ["email", "sms"]}]
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, workflow_name)
);

COMMENT ON TABLE fee_dunning_workflows IS 'Configurable collection workflows for overdue payments';
COMMENT ON COLUMN fee_dunning_workflows.stages IS 'JSON array defining escalation stages and actions';

-- =============================================
-- DUNNING ACTIONS
-- =============================================

CREATE TABLE dunning_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    installment_id UUID REFERENCES payment_installments(id) ON DELETE SET NULL,
    dunning_stage dunning_stage NOT NULL,
    action_type dunning_action_type NOT NULL,
    recipient_email VARCHAR(255),
    recipient_phone VARCHAR(20),
    message_content TEXT,
    scheduled_at TIMESTAMPTZ NOT NULL,
    executed_at TIMESTAMPTZ,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'sent', 'delivered', 'failed'
    amount_overdue DECIMAL(10,2) NOT NULL CHECK (amount_overdue >= 0),
    days_overdue INT NOT NULL CHECK (days_overdue >= 0),
    payment_received BOOLEAN DEFAULT false,
    payment_received_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE dunning_actions IS 'Log of collection actions taken for overdue payments';
COMMENT ON COLUMN dunning_actions.message_content IS 'Template-rendered message sent to recipient';

-- =============================================
-- FEE CONCESSIONS & SCHOLARSHIPS
-- =============================================

CREATE TABLE fee_concessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    concession_type concession_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    discount_type discount_type NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value >= 0),
    applicable_fee_heads UUID[] DEFAULT '{}', -- specific fee head IDs or empty for all
    valid_from DATE NOT NULL,
    valid_until DATE NOT NULL,
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    reason TEXT,
    supporting_documents JSONB DEFAULT '[]', -- [{name, url}]
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_concession_dates CHECK (valid_until >= valid_from),
    CONSTRAINT valid_percentage CHECK (
        discount_type != 'percentage' OR (discount_value >= 0 AND discount_value <= 100)
    )
);

COMMENT ON TABLE fee_concessions IS 'Fee discounts, scholarships, and waivers for students';
COMMENT ON COLUMN fee_concessions.applicable_fee_heads IS 'Array of fee_head IDs; empty array means apply to all';
COMMENT ON COLUMN fee_concessions.discount_value IS 'Percentage (0-100) or fixed amount based on discount_type';

-- =============================================
-- CONCESSION APPLICATION HISTORY
-- =============================================

CREATE TABLE concession_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    concession_id UUID NOT NULL REFERENCES fee_concessions(id) ON DELETE CASCADE,
    original_amount DECIMAL(10,2) NOT NULL CHECK (original_amount >= 0),
    discount_amount DECIMAL(10,2) NOT NULL CHECK (discount_amount >= 0),
    final_amount DECIMAL(10,2) NOT NULL CHECK (final_amount >= 0),
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    applied_by UUID REFERENCES users(id) ON DELETE SET NULL
);

COMMENT ON TABLE concession_applications IS 'History of concessions applied to specific invoices';

-- =============================================
-- INDEXES
-- =============================================

-- Payment Plans
CREATE INDEX idx_payment_plans_student ON fee_payment_plans(student_id, status);
CREATE INDEX idx_payment_plans_invoice ON fee_payment_plans(invoice_id);
CREATE INDEX idx_payment_plans_status ON fee_payment_plans(status, end_date)
    WHERE status IN ('active', 'defaulted');

-- Payment Installments
CREATE INDEX idx_installments_plan ON payment_installments(payment_plan_id, installment_number);
CREATE INDEX idx_installments_overdue ON payment_installments(status, due_date)
    WHERE status IN ('pending', 'overdue');
CREATE INDEX idx_installments_due_date ON payment_installments(due_date)
    WHERE status = 'pending';

-- Dunning Workflows
CREATE INDEX idx_dunning_workflows_tenant ON fee_dunning_workflows(tenant_id)
    WHERE is_active = true;

-- Dunning Actions
CREATE INDEX idx_dunning_actions_student ON dunning_actions(student_id, created_at DESC);
CREATE INDEX idx_dunning_actions_installment ON dunning_actions(installment_id);
CREATE INDEX idx_dunning_actions_status ON dunning_actions(status, scheduled_at)
    WHERE status = 'pending';
CREATE INDEX idx_dunning_actions_overdue ON dunning_actions(days_overdue DESC, created_at DESC);

-- Fee Concessions
CREATE INDEX idx_concessions_student ON fee_concessions(student_id, academic_year_id)
    WHERE is_active = true;
CREATE INDEX idx_concessions_year ON fee_concessions(academic_year_id, valid_from);
CREATE INDEX idx_concessions_type ON fee_concessions(concession_type, is_active);
CREATE INDEX idx_concessions_validity ON fee_concessions(valid_from, valid_until)
    WHERE is_active = true;

-- Concession Applications
CREATE INDEX idx_concession_apps_invoice ON concession_applications(invoice_id);
CREATE INDEX idx_concession_apps_concession ON concession_applications(concession_id);

-- =============================================
-- STORED PROCEDURES
-- =============================================

-- Auto-generate installments for payment plan
CREATE OR REPLACE FUNCTION auto_generate_installments(p_plan_id UUID)
RETURNS VOID AS $$
DECLARE
    v_plan fee_payment_plans%ROWTYPE;
    v_installment_date DATE;
    v_i INT;
BEGIN
    -- Get payment plan details
    SELECT * INTO v_plan FROM fee_payment_plans WHERE id = p_plan_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment plan not found: %', p_plan_id;
    END IF;

    -- Calculate installment dates based on frequency
    v_installment_date := v_plan.start_date;

    FOR v_i IN 1..v_plan.number_of_installments LOOP
        -- Calculate next installment date
        CASE v_plan.frequency
            WHEN 'weekly' THEN
                v_installment_date := v_plan.start_date + (v_i - 1) * INTERVAL '7 days';
            WHEN 'biweekly' THEN
                v_installment_date := v_plan.start_date + (v_i - 1) * INTERVAL '14 days';
            WHEN 'monthly' THEN
                v_installment_date := v_plan.start_date + (v_i - 1) * INTERVAL '1 month';
            WHEN 'quarterly' THEN
                v_installment_date := v_plan.start_date + (v_i - 1) * INTERVAL '3 months';
        END CASE;

        -- Insert installment
        INSERT INTO payment_installments (
            payment_plan_id,
            installment_number,
            due_date,
            amount,
            status
        ) VALUES (
            p_plan_id,
            v_i,
            v_installment_date,
            v_plan.installment_amount,
            'pending'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION auto_generate_installments IS 'Automatically creates installment records for a payment plan';

-- Process dunning workflow (to be run daily)
CREATE OR REPLACE FUNCTION process_dunning_workflow()
RETURNS VOID AS $$
DECLARE
    v_installment RECORD;
    v_days_overdue INT;
BEGIN
    -- Update overdue status
    UPDATE payment_installments
    SET status = 'overdue'
    WHERE status = 'pending'
        AND due_date < CURRENT_DATE;

    -- Process overdue installments
    FOR v_installment IN
        SELECT pi.*, fpp.student_id
        FROM payment_installments pi
        JOIN fee_payment_plans fpp ON pi.payment_plan_id = fpp.id
        WHERE pi.status = 'overdue'
    LOOP
        v_days_overdue := EXTRACT(DAY FROM (CURRENT_DATE - v_installment.due_date))::INT;

        -- TODO: Implement dunning stage logic based on workflows
        -- Check dunning_workflows and create appropriate dunning_actions
        NULL;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION process_dunning_workflow IS 'Processes overdue installments and triggers dunning actions';

-- Apply concession to invoice
CREATE OR REPLACE FUNCTION apply_concession_to_invoice(
    p_invoice_id UUID,
    p_concession_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_invoice invoices%ROWTYPE;
    v_concession fee_concessions%ROWTYPE;
    v_discount_amount DECIMAL(10,2);
    v_final_amount DECIMAL(10,2);
BEGIN
    -- Get invoice and concession details
    SELECT * INTO v_invoice FROM invoices WHERE id = p_invoice_id;
    SELECT * INTO v_concession FROM fee_concessions WHERE id = p_concession_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invoice or concession not found';
    END IF;

    -- Calculate discount
    IF v_concession.discount_type = 'percentage' THEN
        v_discount_amount := v_invoice.total_amount * (v_concession.discount_value / 100);
    ELSE
        v_discount_amount := v_concession.discount_value;
    END IF;

    v_final_amount := GREATEST(0, v_invoice.total_amount - v_discount_amount);

    -- Record concession application
    INSERT INTO concession_applications (
        invoice_id,
        concession_id,
        original_amount,
        discount_amount,
        final_amount
    ) VALUES (
        p_invoice_id,
        p_concession_id,
        v_invoice.total_amount,
        v_discount_amount,
        v_final_amount
    );

    -- Update invoice
    UPDATE invoices
    SET
        total_amount = v_final_amount,
        updated_at = NOW()
    WHERE id = p_invoice_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION apply_concession_to_invoice IS 'Applies a fee concession to an invoice and updates amounts';

-- Update payment plan status on installment payment
CREATE OR REPLACE FUNCTION update_payment_plan_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    v_plan_id UUID;
    v_all_paid BOOLEAN;
BEGIN
    IF NEW.status = 'paid' AND OLD.status != 'paid' THEN
        v_plan_id := NEW.payment_plan_id;

        -- Check if all installments are paid
        SELECT NOT EXISTS (
            SELECT 1 FROM payment_installments
            WHERE payment_plan_id = v_plan_id
                AND status != 'paid'
        ) INTO v_all_paid;

        IF v_all_paid THEN
            UPDATE fee_payment_plans
            SET
                status = 'completed',
                completed_at = NOW(),
                updated_at = NOW()
            WHERE id = v_plan_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_payment_plan_status
    AFTER UPDATE OF status ON payment_installments
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_plan_on_payment();

COMMENT ON FUNCTION update_payment_plan_on_payment IS 'Automatically updates payment plan status when all installments are paid';

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE fee_payment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_dunning_workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE dunning_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_concessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE concession_applications ENABLE ROW LEVEL SECURITY;
