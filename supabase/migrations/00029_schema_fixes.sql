-- =============================================
-- Schema Fixes Migration
-- Fixes: has_role overloads, missing indexes,
--   wallet race condition, invoice duplicate check,
--   incident_severity enum conflict, library_books constraint
-- =============================================

-- =============================================
-- 1. Fix has_role() function signature mismatch
--    The original (00006) takes 1 arg: has_role(required_role user_role)
--    But 00012 calls has_role(uuid, text) and 00019/00021 call has_role(uuid, uuid, text)
-- =============================================

-- 2-arg version: has_role(user_id uuid, role text)
CREATE OR REPLACE FUNCTION public.has_role(p_user_id uuid, p_role text)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_user_id AND role = p_role::user_role
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 3-arg version: has_role(user_id uuid, tenant_id uuid, role text)
CREATE OR REPLACE FUNCTION public.has_role(p_user_id uuid, p_tenant_id uuid, p_role text)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_user_id AND tenant_id = p_tenant_id AND role = p_role::user_role
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- =============================================
-- 2. Add missing indexes for performance
-- =============================================

CREATE INDEX IF NOT EXISTS idx_students_name ON students(tenant_id, first_name, last_name);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(tenant_id, due_date);
CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance(tenant_id, student_id, date);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_book_issues_status ON book_issues(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_student_parents_student ON student_parents(student_id);

-- =============================================
-- 3. Fix wallet balance race condition
--    Add CHECK constraint + rewrite trigger with proper credit/debit handling
-- =============================================

-- Prevent negative wallet balances at the database level
ALTER TABLE wallets ADD CONSTRAINT wallets_balance_non_negative CHECK (balance >= 0);

-- Replace the trigger function with one that uses row-level locking
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.txn_type = 'credit' THEN
    UPDATE wallets
    SET balance = balance + NEW.amount,
        last_transaction_at = NOW(),
        updated_at = NOW()
    WHERE id = NEW.wallet_id;
  ELSIF NEW.txn_type = 'debit' THEN
    UPDATE wallets
    SET balance = balance - NEW.amount,
        last_transaction_at = NOW(),
        updated_at = NOW()
    WHERE id = NEW.wallet_id;
    -- The CHECK constraint will prevent negative balances and raise an error
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 4. Fix generate_class_invoices duplicate check
--    Adds guard to prevent duplicate invoice generation for same class/term
-- =============================================

CREATE OR REPLACE FUNCTION generate_class_invoices(
  p_tenant_id UUID,
  p_class_id UUID,
  p_academic_year_id UUID,
  p_term_id UUID DEFAULT NULL,
  p_due_date DATE DEFAULT (CURRENT_DATE + INTERVAL '30 days')::DATE
) RETURNS INT AS $$
DECLARE
  v_count INT := 0;
  v_existing INT;
  v_student RECORD;
  v_fee RECORD;
  v_invoice_id UUID;
  v_invoice_number VARCHAR(50);
  v_total DECIMAL(10,2);
BEGIN
  -- Check for existing invoices for this class/term to prevent duplicates
  SELECT COUNT(*) INTO v_existing
  FROM invoices i
  JOIN student_enrollments se ON se.student_id = i.student_id
  JOIN sections sec ON sec.id = se.section_id
  WHERE i.tenant_id = p_tenant_id
    AND sec.class_id = p_class_id
    AND i.academic_year_id = p_academic_year_id
    AND se.academic_year_id = p_academic_year_id
    AND se.status = 'active'
    AND (
      (p_term_id IS NULL AND i.term_id IS NULL)
      OR i.term_id = p_term_id
    );

  IF v_existing > 0 THEN
    RAISE EXCEPTION 'Invoices already exist for this class/term combination. Found % existing invoices.', v_existing;
  END IF;

  -- Loop through all active students in the class
  FOR v_student IN
    SELECT se.student_id, se.section_id
    FROM student_enrollments se
    JOIN sections sec ON se.section_id = sec.id
    WHERE sec.class_id = p_class_id
      AND se.academic_year_id = p_academic_year_id
      AND se.status = 'active'
      AND se.tenant_id = p_tenant_id
  LOOP
    -- Calculate total fees
    SELECT COALESCE(SUM(fs.amount), 0) INTO v_total
    FROM fee_structures fs
    WHERE fs.class_id = p_class_id
      AND fs.academic_year_id = p_academic_year_id
      AND (p_term_id IS NULL OR fs.term_id = p_term_id OR fs.term_id IS NULL)
      AND fs.tenant_id = p_tenant_id;

    IF v_total > 0 THEN
      -- Generate invoice number
      v_invoice_number := 'INV-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' ||
                          LPAD((v_count + 1)::TEXT, 4, '0');

      -- Create invoice
      INSERT INTO invoices (
        tenant_id, invoice_number, student_id, academic_year_id, term_id,
        total_amount, due_date, status
      ) VALUES (
        p_tenant_id, v_invoice_number, v_student.student_id, p_academic_year_id,
        p_term_id, v_total, p_due_date, 'pending'
      ) RETURNING id INTO v_invoice_id;

      -- Add invoice items
      INSERT INTO invoice_items (invoice_id, fee_head_id, description, amount)
      SELECT v_invoice_id, fs.fee_head_id, fh.name, fs.amount
      FROM fee_structures fs
      JOIN fee_heads fh ON fs.fee_head_id = fh.id
      WHERE fs.class_id = p_class_id
        AND fs.academic_year_id = p_academic_year_id
        AND (p_term_id IS NULL OR fs.term_id = p_term_id OR fs.term_id IS NULL)
        AND fs.tenant_id = p_tenant_id;

      v_count := v_count + 1;
    END IF;
  END LOOP;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 5. Fix incident_severity enum conflict
--    00008 defines: ('minor', 'moderate', 'serious', 'critical')
--    00016 tries to redefine: ('minor', 'moderate', 'major', 'critical')
--    Add 'major' value to the existing enum if not already present
-- =============================================

DO $$ BEGIN
  ALTER TYPE incident_severity ADD VALUE IF NOT EXISTS 'major';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =============================================
-- 6. Add library_books available_copies floor check
--    Prevents available_copies from going negative (e.g., double-issue bug)
-- =============================================

ALTER TABLE library_books ADD CONSTRAINT library_books_available_non_negative
  CHECK (available_copies >= 0);
