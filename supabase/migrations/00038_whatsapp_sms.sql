-- WhatsApp & SMS Integration
-- Migration: 00038_whatsapp_sms.sql

CREATE TABLE IF NOT EXISTS sms_whatsapp_configs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE UNIQUE,
  whatsapp_enabled boolean DEFAULT false,
  whatsapp_api_key text,
  whatsapp_phone_number_id text,
  whatsapp_business_account_id text,
  sms_enabled boolean DEFAULT false,
  sms_provider text CHECK (sms_provider IN ('twilio','africas_talking','vonage','aws_sns')),
  sms_api_key text,
  sms_sender_id text,
  auto_attendance_notify boolean DEFAULT true,
  auto_fee_notify boolean DEFAULT true,
  auto_result_notify boolean DEFAULT true,
  auto_absence_notify boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notification_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  channel text NOT NULL CHECK (channel IN ('whatsapp','sms','email','push')),
  recipient_phone text,
  recipient_name text,
  message_template text,
  message_body text,
  status text DEFAULT 'sent' CHECK (status IN ('sent','delivered','failed','pending')),
  error_message text,
  triggered_by text,
  sent_at timestamptz DEFAULT now()
);

ALTER TABLE sms_whatsapp_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_isolation" ON sms_whatsapp_configs
  USING ((auth.jwt()->'app_metadata'->>'tenant_id')::uuid = tenant_id);
CREATE POLICY "tenant_isolation" ON notification_logs
  USING ((auth.jwt()->'app_metadata'->>'tenant_id')::uuid = tenant_id);
