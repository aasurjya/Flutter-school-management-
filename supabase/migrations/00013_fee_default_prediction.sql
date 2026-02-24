-- ============================================================
-- Migration: 00013_fee_default_prediction
-- Feature: Predictive Fee Collection Intelligence
-- ============================================================

-- ============================================================
-- fee_reminder_log — tracks reminders sent per invoice
-- ============================================================
CREATE TABLE IF NOT EXISTS fee_reminder_log (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  invoice_id   UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  student_id   UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  sent_by      UUID REFERENCES users(id),
  channel      VARCHAR(20) NOT NULL DEFAULT 'app',  -- app, whatsapp, sms, email
  message_text TEXT,
  risk_score   INTEGER,
  sent_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fee_reminder_log_tenant
  ON fee_reminder_log(tenant_id);
CREATE INDEX IF NOT EXISTS idx_fee_reminder_log_invoice
  ON fee_reminder_log(invoice_id);
CREATE INDEX IF NOT EXISTS idx_fee_reminder_log_student
  ON fee_reminder_log(student_id);

ALTER TABLE fee_reminder_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fee_reminder_log_tenant" ON fee_reminder_log
  FOR ALL USING (tenant_id = (
    SELECT tenant_id FROM users WHERE id = auth.uid()
  ));

-- ============================================================
-- predict_fee_defaults — rule-based risk scoring function
-- ============================================================
CREATE OR REPLACE FUNCTION predict_fee_defaults(p_tenant_id UUID)
RETURNS TABLE(
  student_id       UUID,
  student_name     TEXT,
  class_name       TEXT,
  invoice_id       UUID,
  invoice_number   VARCHAR,
  amount_due       DECIMAL,
  due_date         DATE,
  risk_score       INT,
  risk_factors     TEXT[],
  recommended_action TEXT,
  last_reminder_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  WITH payment_history AS (
    -- Historical payment pattern per student
    SELECT
      i.student_id,
      COALESCE(
        AVG(EXTRACT(DAY FROM p.paid_at::date - i.due_date))
        FILTER (WHERE p.paid_at IS NOT NULL),
        0
      )                          AS avg_days_late,
      COUNT(*) FILTER (WHERE i.status = 'overdue') AS overdue_count,
      COUNT(*)                   AS total_invoices
    FROM invoices i
    LEFT JOIN payments p
      ON p.invoice_id = i.id AND p.status = 'completed'
    WHERE i.tenant_id = p_tenant_id
      AND i.status IN ('paid', 'overdue', 'partial')
    GROUP BY i.student_id
  ),
  current_enrollment AS (
    -- Most recent class enrollment per student
    SELECT DISTINCT ON (se.student_id)
      se.student_id,
      c.name AS class_name
    FROM student_enrollments se
    JOIN sections sec ON se.section_id = sec.id
    JOIN classes  c   ON sec.class_id  = c.id
    WHERE sec.tenant_id = p_tenant_id
    ORDER BY se.student_id, se.id DESC
  ),
  pending_invoices AS (
    SELECT
      i.id,
      i.student_id,
      i.invoice_number,
      i.due_date,
      (i.total_amount - COALESCE(i.paid_amount, 0)) AS amount_due,
      s.first_name || ' ' || s.last_name             AS student_name
    FROM invoices i
    JOIN students s ON i.student_id = s.id
    WHERE i.tenant_id = p_tenant_id
      AND i.status IN ('pending', 'partial', 'overdue')
      AND (i.due_date <= CURRENT_DATE + INTERVAL '30 days'
           OR i.status = 'overdue')
      AND (i.total_amount - COALESCE(i.paid_amount, 0)) > 0
  ),
  reminder_recency AS (
    SELECT invoice_id, MAX(sent_at) AS last_sent_at
    FROM fee_reminder_log
    WHERE tenant_id = p_tenant_id
    GROUP BY invoice_id
  )
  SELECT
    pi.student_id,
    pi.student_name,
    COALESCE(ce.class_name, 'Unknown') AS class_name,
    pi.id                               AS invoice_id,
    pi.invoice_number,
    pi.amount_due,
    pi.due_date,
    -- Risk score 0-100
    LEAST(100, GREATEST(0,
      -- Late-payment history (max 40 pts)
      CASE
        WHEN COALESCE(ph.avg_days_late, 0) > 30 THEN 40
        ELSE (COALESCE(ph.avg_days_late, 0) / 30.0 * 40)::INT
      END
      -- Repeat overdue history (max 30 pts)
      + CASE
          WHEN COALESCE(ph.overdue_count, 0) > 2 THEN 30
          ELSE (COALESCE(ph.overdue_count, 0) / 2.0 * 30)::INT
        END
      -- Currently overdue (30 pts)
      + CASE WHEN pi.due_date < CURRENT_DATE THEN 30 ELSE 0 END
    ))::INT AS risk_score,
    -- Risk factors (human-readable)
    ARRAY_REMOVE(ARRAY[
      CASE
        WHEN COALESCE(ph.avg_days_late, 0) > 15
        THEN 'History of late payments (avg ' || ROUND(COALESCE(ph.avg_days_late, 0)) || ' days late)'
      END,
      CASE
        WHEN COALESCE(ph.overdue_count, 0) > 0
        THEN ph.overdue_count || ' previously overdue invoice(s)'
      END,
      CASE
        WHEN pi.due_date < CURRENT_DATE
        THEN 'Already overdue by ' || (CURRENT_DATE - pi.due_date) || ' day(s)'
      END,
      CASE
        WHEN pi.amount_due > 10000
        THEN 'High balance pending: ₹' || TO_CHAR(pi.amount_due, 'FM99,99,999')
      END
    ], NULL) AS risk_factors,
    -- Recommended action
    CASE
      WHEN pi.due_date < CURRENT_DATE
        AND COALESCE(ph.avg_days_late, 0) > 20
        THEN 'Offer installment payment plan immediately'
      WHEN pi.due_date < CURRENT_DATE
        THEN 'Send urgent payment reminder'
      WHEN pi.due_date <= CURRENT_DATE + INTERVAL '7 days'
        THEN 'Send proactive reminder with payment link'
      WHEN COALESCE(ph.overdue_count, 0) > 1
        THEN 'Proactively reach out — repeat defaulter'
      ELSE 'Monitor — low risk currently'
    END AS recommended_action,
    rr.last_sent_at AS last_reminder_at
  FROM pending_invoices pi
  LEFT JOIN payment_history  ph ON ph.student_id = pi.student_id
  LEFT JOIN current_enrollment ce ON ce.student_id = pi.student_id
  LEFT JOIN reminder_recency  rr ON rr.invoice_id = pi.id
  ORDER BY risk_score DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant to authenticated role
GRANT EXECUTE ON FUNCTION predict_fee_defaults(UUID) TO authenticated;
