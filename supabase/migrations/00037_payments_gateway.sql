-- Payment gateways configuration
CREATE TABLE IF NOT EXISTS payment_gateways (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  gateway_name text NOT NULL CHECK (gateway_name IN ('stripe','razorpay','paystack','flutterwave','mpesa','manual')),
  is_active boolean DEFAULT false,
  is_test_mode boolean DEFAULT true,
  display_name text NOT NULL,
  currency_code text DEFAULT 'USD',
  config jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(tenant_id, gateway_name)
);

CREATE TABLE IF NOT EXISTS payment_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  invoice_id uuid REFERENCES invoices(id),
  student_id uuid REFERENCES students(id),
  gateway_name text NOT NULL,
  gateway_transaction_id text,
  amount numeric(12,2) NOT NULL,
  currency_code text DEFAULT 'USD',
  status text DEFAULT 'pending' CHECK (status IN ('pending','processing','success','failed','refunded','cancelled')),
  payment_method text,
  metadata jsonb DEFAULT '{}',
  failure_reason text,
  paid_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_gateways ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_isolation_gateways" ON payment_gateways
  USING ((auth.jwt()->'app_metadata'->>'tenant_id')::uuid = tenant_id);
CREATE POLICY "tenant_isolation_transactions" ON payment_transactions
  USING ((auth.jwt()->'app_metadata'->>'tenant_id')::uuid = tenant_id);
