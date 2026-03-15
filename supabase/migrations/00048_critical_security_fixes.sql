-- Migration: 00048_critical_security_fixes
-- Purpose: Fix critical security and data integrity issues found in security audit.
--
-- Fixes:
--   1. generate_class_invoices() — add advisory lock to prevent TOCTOU race
--   2. update_wallet_balance() — add FOR UPDATE row lock
--   3. update_invoice_on_payment() — add FOR UPDATE row lock
--   4. tenants RLS — restrict to own tenant + super_admin (was open to all authenticated)
--   5. hostel_rooms.occupied — add sync trigger from room_allocations
--   6. payment_gateways RLS — restrict to admin/accountant roles

-- ============================================================================
-- 1. generate_class_invoices() — add advisory lock for atomicity
-- ============================================================================

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
  -- Advisory lock prevents concurrent calls for the same class/term from racing
  PERFORM pg_advisory_xact_lock(
    hashtext(p_tenant_id::TEXT || p_class_id::TEXT || COALESCE(p_term_id::TEXT, 'NULL'))
  );

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
    RAISE NOTICE 'Invoices already exist for this class/term combination. Found % existing invoices.', v_existing;
    RETURN 0;
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
      v_invoice_number := 'INV-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD((v_count + 1)::TEXT, 4, '0');

      -- Create invoice
      INSERT INTO invoices (
        tenant_id, student_id, academic_year_id, term_id,
        invoice_number, total_amount, due_date, status
      ) VALUES (
        p_tenant_id, v_student.student_id, p_academic_year_id, p_term_id,
        v_invoice_number, v_total, p_due_date, 'pending'
      ) RETURNING id INTO v_invoice_id;

      -- Create invoice items
      FOR v_fee IN
        SELECT fs.fee_head_id, fs.amount
        FROM fee_structures fs
        WHERE fs.class_id = p_class_id
          AND fs.academic_year_id = p_academic_year_id
          AND (p_term_id IS NULL OR fs.term_id = p_term_id OR fs.term_id IS NULL)
          AND fs.tenant_id = p_tenant_id
      LOOP
        INSERT INTO invoice_items (
          tenant_id, invoice_id, fee_head_id, amount
        ) VALUES (
          p_tenant_id, v_invoice_id, v_fee.fee_head_id, v_fee.amount
        );
      END LOOP;

      v_count := v_count + 1;
    END IF;
  END LOOP;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- 2. update_wallet_balance() — add FOR UPDATE row lock
-- ============================================================================

CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
DECLARE
  v_wallet wallets;
BEGIN
  -- Lock the wallet row to prevent concurrent race conditions
  SELECT * INTO v_wallet
  FROM wallets
  WHERE id = NEW.wallet_id
  FOR UPDATE;

  IF NEW.txn_type = 'credit' THEN
    UPDATE wallets
    SET balance = v_wallet.balance + NEW.amount,
        updated_at = NOW()
    WHERE id = NEW.wallet_id;
  ELSIF NEW.txn_type = 'debit' THEN
    IF v_wallet.balance < NEW.amount THEN
      RAISE EXCEPTION 'Insufficient wallet balance. Available: %, Required: %',
        v_wallet.balance, NEW.amount;
    END IF;
    UPDATE wallets
    SET balance = v_wallet.balance - NEW.amount,
        updated_at = NOW()
    WHERE id = NEW.wallet_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- 3. update_invoice_on_payment() — add FOR UPDATE row lock
-- ============================================================================

CREATE OR REPLACE FUNCTION update_invoice_on_payment()
RETURNS TRIGGER AS $$
DECLARE
  v_invoice invoices;
BEGIN
  IF NEW.status = 'completed' THEN
    -- Lock the invoice row to prevent concurrent payment race
    SELECT * INTO v_invoice
    FROM invoices
    WHERE id = NEW.invoice_id
    FOR UPDATE;

    UPDATE invoices
    SET paid_amount = v_invoice.paid_amount + NEW.amount,
        status = CASE
          WHEN v_invoice.paid_amount + NEW.amount
               >= v_invoice.total_amount - COALESCE(v_invoice.discount_amount, 0) THEN 'paid'
          WHEN v_invoice.paid_amount + NEW.amount > 0 THEN 'partial'
          ELSE v_invoice.status
        END,
        updated_at = NOW()
    WHERE id = NEW.invoice_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- 4. tenants RLS — restrict to own tenant + super_admin
-- ============================================================================

-- Drop the overly permissive policy
DROP POLICY IF EXISTS "Authenticated users read tenants" ON tenants;

-- Replace with scoped policy
CREATE POLICY "Users read own tenant or super_admin reads all"
  ON tenants FOR SELECT
  USING (
    id = (SELECT (auth.jwt()->'app_metadata'->>'tenant_id')::uuid)
    OR (SELECT public.has_role('super_admin'))
  );


-- ============================================================================
-- 5. hostel_rooms.occupied — sync trigger from room_allocations
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_hostel_room_occupancy()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.is_active = true THEN
    UPDATE hostel_rooms
    SET occupied = occupied + 1,
        is_available = (capacity > occupied + 1)
    WHERE id = NEW.room_id;
  ELSIF TG_OP = 'UPDATE'
    AND OLD.is_active = true AND NEW.is_active = false THEN
    UPDATE hostel_rooms
    SET occupied = GREATEST(0, occupied - 1),
        is_available = (capacity > GREATEST(0, occupied - 1))
    WHERE id = NEW.room_id;
  ELSIF TG_OP = 'DELETE' AND OLD.is_active = true THEN
    UPDATE hostel_rooms
    SET occupied = GREATEST(0, occupied - 1),
        is_available = (capacity > GREATEST(0, occupied - 1))
    WHERE id = OLD.room_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_hostel_room_occupancy ON room_allocations;
CREATE TRIGGER trg_hostel_room_occupancy
AFTER INSERT OR UPDATE OF is_active OR DELETE ON room_allocations
FOR EACH ROW EXECUTE FUNCTION sync_hostel_room_occupancy();


-- ============================================================================
-- 6. payment_gateways RLS — restrict to admin/accountant
-- ============================================================================

DROP POLICY IF EXISTS "tenant_isolation_gateways" ON payment_gateways;

CREATE POLICY "admin_accountant_gateways" ON payment_gateways
  FOR ALL
  USING (
    (auth.jwt()->'app_metadata'->>'tenant_id')::uuid = tenant_id
    AND (
      (SELECT public.is_admin())
      OR (SELECT public.has_role('accountant'))
    )
  );
