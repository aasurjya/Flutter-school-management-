-- ============================================================
-- Communication Hub Module
-- ============================================================

-- Enums
DO $$ BEGIN
  CREATE TYPE template_category AS ENUM (
    'fee_reminder', 'attendance_alert', 'exam_notice',
    'event_invite', 'general', 'emergency'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE communication_channel AS ENUM (
    'sms', 'email', 'push', 'in_app', 'whatsapp'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE campaign_status AS ENUM (
    'draft', 'scheduled', 'sending', 'sent', 'failed', 'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE recipient_status AS ENUM (
    'pending', 'sent', 'delivered', 'read', 'failed'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE campaign_target_type AS ENUM (
    'all', 'class', 'section', 'individual', 'parents', 'teachers', 'staff', 'custom'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE sms_provider AS ENUM (
    'twilio', 'africastalking', 'msg91', 'textlocal'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE email_provider AS ENUM (
    'sendgrid', 'ses', 'smtp', 'mailgun'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE communication_direction AS ENUM (
    'inbound', 'outbound'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE trigger_event AS ENUM (
    'absent_marked', 'fee_overdue', 'exam_published',
    'assignment_due', 'low_grade', 'birthday',
    'fee_payment_received', 'report_card_published',
    'ptm_scheduled', 'emergency_alert'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- communication_templates
-- ============================================================
CREATE TABLE IF NOT EXISTS communication_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  category template_category NOT NULL DEFAULT 'general',
  subject VARCHAR(500),
  body_template TEXT NOT NULL,
  variables JSONB NOT NULL DEFAULT '[]'::jsonb,
  channel communication_channel NOT NULL DEFAULT 'in_app',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_comm_templates_tenant ON communication_templates(tenant_id);
CREATE INDEX idx_comm_templates_category ON communication_templates(tenant_id, category);
CREATE INDEX idx_comm_templates_active ON communication_templates(tenant_id, is_active) WHERE is_active = true;

-- ============================================================
-- communication_campaigns
-- ============================================================
CREATE TABLE IF NOT EXISTS communication_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  template_id UUID REFERENCES communication_templates(id) ON DELETE SET NULL,
  subject VARCHAR(500),
  body TEXT NOT NULL,
  target_type campaign_target_type NOT NULL DEFAULT 'all',
  target_filter JSONB NOT NULL DEFAULT '{}'::jsonb,
  channels JSONB NOT NULL DEFAULT '["in_app"]'::jsonb,
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  status campaign_status NOT NULL DEFAULT 'draft',
  stats JSONB NOT NULL DEFAULT '{"total": 0, "sent": 0, "delivered": 0, "read": 0, "failed": 0}'::jsonb,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_campaigns_tenant ON communication_campaigns(tenant_id);
CREATE INDEX idx_campaigns_status ON communication_campaigns(tenant_id, status);
CREATE INDEX idx_campaigns_scheduled ON communication_campaigns(scheduled_at) WHERE status = 'scheduled';
CREATE INDEX idx_campaigns_created_by ON communication_campaigns(created_by);
CREATE INDEX idx_campaigns_created_at ON communication_campaigns(tenant_id, created_at DESC);

-- ============================================================
-- campaign_recipients
-- ============================================================
CREATE TABLE IF NOT EXISTS campaign_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES communication_campaigns(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  channel communication_channel NOT NULL DEFAULT 'in_app',
  status recipient_status NOT NULL DEFAULT 'pending',
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_recipients_campaign ON campaign_recipients(campaign_id);
CREATE INDEX idx_recipients_user ON campaign_recipients(user_id);
CREATE INDEX idx_recipients_status ON campaign_recipients(campaign_id, status);
CREATE UNIQUE INDEX idx_recipients_unique ON campaign_recipients(campaign_id, user_id, channel);

-- ============================================================
-- sms_gateway_config
-- ============================================================
CREATE TABLE IF NOT EXISTS sms_gateway_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  provider sms_provider NOT NULL DEFAULT 'twilio',
  api_key_encrypted TEXT,
  api_secret_encrypted TEXT,
  sender_id VARCHAR(20),
  is_active BOOLEAN NOT NULL DEFAULT false,
  balance_credits NUMERIC(12, 2) DEFAULT 0,
  config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_sms_config_tenant ON sms_gateway_config(tenant_id) WHERE is_active = true;
CREATE INDEX idx_sms_config_tenant_all ON sms_gateway_config(tenant_id);

-- ============================================================
-- email_config
-- ============================================================
CREATE TABLE IF NOT EXISTS email_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  provider email_provider NOT NULL DEFAULT 'smtp',
  config JSONB NOT NULL DEFAULT '{}'::jsonb,
  from_email VARCHAR(255),
  from_name VARCHAR(255),
  is_active BOOLEAN NOT NULL DEFAULT false,
  daily_limit INT DEFAULT 500,
  sent_today INT DEFAULT 0,
  last_reset_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_email_config_tenant ON email_config(tenant_id) WHERE is_active = true;
CREATE INDEX idx_email_config_tenant_all ON email_config(tenant_id);

-- ============================================================
-- communication_log
-- ============================================================
CREATE TABLE IF NOT EXISTS communication_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  campaign_id UUID REFERENCES communication_campaigns(id) ON DELETE SET NULL,
  channel communication_channel NOT NULL,
  direction communication_direction NOT NULL DEFAULT 'outbound',
  recipient_info VARCHAR(255),
  content_preview TEXT,
  status recipient_status NOT NULL DEFAULT 'pending',
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_comm_log_tenant ON communication_log(tenant_id);
CREATE INDEX idx_comm_log_tenant_created ON communication_log(tenant_id, created_at DESC);
CREATE INDEX idx_comm_log_user ON communication_log(user_id);
CREATE INDEX idx_comm_log_campaign ON communication_log(campaign_id);
CREATE INDEX idx_comm_log_channel ON communication_log(tenant_id, channel);
CREATE INDEX idx_comm_log_status ON communication_log(tenant_id, status);

-- ============================================================
-- auto_notification_rules
-- ============================================================
CREATE TABLE IF NOT EXISTS auto_notification_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  trigger_event trigger_event NOT NULL,
  template_id UUID REFERENCES communication_templates(id) ON DELETE SET NULL,
  channels JSONB NOT NULL DEFAULT '["push", "in_app"]'::jsonb,
  target_roles JSONB DEFAULT '["parent"]'::jsonb,
  conditions JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT true,
  delay_minutes INT DEFAULT 0,
  last_triggered_at TIMESTAMPTZ,
  trigger_count INT DEFAULT 0,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_auto_rules_tenant ON auto_notification_rules(tenant_id);
CREATE INDEX idx_auto_rules_active ON auto_notification_rules(tenant_id, is_active) WHERE is_active = true;
CREATE INDEX idx_auto_rules_trigger ON auto_notification_rules(tenant_id, trigger_event);
CREATE UNIQUE INDEX idx_auto_rules_unique ON auto_notification_rules(tenant_id, trigger_event, name);

-- ============================================================
-- Aggregation view: daily communication stats
-- ============================================================
CREATE OR REPLACE VIEW v_communication_daily_stats AS
SELECT
  cl.tenant_id,
  DATE(cl.created_at) AS log_date,
  cl.channel,
  cl.direction,
  COUNT(*) AS total_count,
  COUNT(*) FILTER (WHERE cl.status = 'sent') AS sent_count,
  COUNT(*) FILTER (WHERE cl.status = 'delivered') AS delivered_count,
  COUNT(*) FILTER (WHERE cl.status = 'read') AS read_count,
  COUNT(*) FILTER (WHERE cl.status = 'failed') AS failed_count
FROM communication_log cl
GROUP BY cl.tenant_id, DATE(cl.created_at), cl.channel, cl.direction;

-- ============================================================
-- Function: update campaign stats from recipients
-- ============================================================
CREATE OR REPLACE FUNCTION update_campaign_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE communication_campaigns
  SET stats = (
    SELECT jsonb_build_object(
      'total', COUNT(*),
      'sent', COUNT(*) FILTER (WHERE status IN ('sent', 'delivered', 'read')),
      'delivered', COUNT(*) FILTER (WHERE status IN ('delivered', 'read')),
      'read', COUNT(*) FILTER (WHERE status = 'read'),
      'failed', COUNT(*) FILTER (WHERE status = 'failed')
    )
    FROM campaign_recipients
    WHERE campaign_id = COALESCE(NEW.campaign_id, OLD.campaign_id)
  ),
  updated_at = now()
  WHERE id = COALESCE(NEW.campaign_id, OLD.campaign_id);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_campaign_stats ON campaign_recipients;
CREATE TRIGGER trg_update_campaign_stats
  AFTER INSERT OR UPDATE OF status ON campaign_recipients
  FOR EACH ROW
  EXECUTE FUNCTION update_campaign_stats();

-- ============================================================
-- RLS Policies
-- ============================================================
ALTER TABLE communication_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_gateway_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_notification_rules ENABLE ROW LEVEL SECURITY;

-- Templates: admins and teachers can manage
CREATE POLICY templates_select ON communication_templates
  FOR SELECT USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

CREATE POLICY templates_insert ON communication_templates
  FOR INSERT WITH CHECK (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND tenant_id = communication_templates.tenant_id
      AND role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY templates_update ON communication_templates
  FOR UPDATE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND tenant_id = communication_templates.tenant_id
      AND role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY templates_delete ON communication_templates
  FOR DELETE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND tenant_id = communication_templates.tenant_id
      AND role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

-- Campaigns: admins and teachers can manage
CREATE POLICY campaigns_select ON communication_campaigns
  FOR SELECT USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

CREATE POLICY campaigns_insert ON communication_campaigns
  FOR INSERT WITH CHECK (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND tenant_id = communication_campaigns.tenant_id
      AND role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY campaigns_update ON communication_campaigns
  FOR UPDATE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND tenant_id = communication_campaigns.tenant_id
      AND role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY campaigns_delete ON communication_campaigns
  FOR DELETE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    AND created_by = auth.uid()
  );

-- Recipients: users can see their own; admins see all for tenant
CREATE POLICY recipients_select ON campaign_recipients
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM communication_campaigns cc
      JOIN user_roles ur ON ur.tenant_id = cc.tenant_id
      WHERE cc.id = campaign_recipients.campaign_id
      AND ur.user_id = auth.uid()
      AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

CREATE POLICY recipients_insert ON campaign_recipients
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM communication_campaigns cc
      JOIN user_roles ur ON ur.tenant_id = cc.tenant_id
      WHERE cc.id = campaign_recipients.campaign_id
      AND ur.user_id = auth.uid()
      AND ur.role IN ('super_admin', 'tenant_admin', 'principal', 'teacher')
    )
  );

CREATE POLICY recipients_update ON campaign_recipients
  FOR UPDATE USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM communication_campaigns cc
      JOIN user_roles ur ON ur.tenant_id = cc.tenant_id
      WHERE cc.id = campaign_recipients.campaign_id
      AND ur.user_id = auth.uid()
      AND ur.role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

-- SMS/Email config: only admins
CREATE POLICY sms_config_select ON sms_gateway_config
  FOR SELECT USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

CREATE POLICY sms_config_manage ON sms_gateway_config
  FOR ALL USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND tenant_id = sms_gateway_config.tenant_id
      AND role IN ('super_admin', 'tenant_admin')
    )
  );

CREATE POLICY email_config_select ON email_config
  FOR SELECT USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

CREATE POLICY email_config_manage ON email_config
  FOR ALL USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND tenant_id = email_config.tenant_id
      AND role IN ('super_admin', 'tenant_admin')
    )
  );

-- Communication log: admins see all; users see their own
CREATE POLICY comm_log_select ON communication_log
  FOR SELECT USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    AND (
      user_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid()
        AND tenant_id = communication_log.tenant_id
        AND role IN ('super_admin', 'tenant_admin', 'principal')
      )
    )
  );

CREATE POLICY comm_log_insert ON communication_log
  FOR INSERT WITH CHECK (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
  );

-- Auto rules: admins and teachers
CREATE POLICY auto_rules_select ON auto_notification_rules
  FOR SELECT USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

CREATE POLICY auto_rules_manage ON auto_notification_rules
  FOR ALL USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    AND EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND tenant_id = auto_notification_rules.tenant_id
      AND role IN ('super_admin', 'tenant_admin', 'principal')
    )
  );

-- ============================================================
-- Updated_at triggers
-- ============================================================
CREATE OR REPLACE FUNCTION update_comm_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_templates_updated_at BEFORE UPDATE ON communication_templates
  FOR EACH ROW EXECUTE FUNCTION update_comm_updated_at();

CREATE TRIGGER trg_campaigns_updated_at BEFORE UPDATE ON communication_campaigns
  FOR EACH ROW EXECUTE FUNCTION update_comm_updated_at();

CREATE TRIGGER trg_sms_config_updated_at BEFORE UPDATE ON sms_gateway_config
  FOR EACH ROW EXECUTE FUNCTION update_comm_updated_at();

CREATE TRIGGER trg_email_config_updated_at BEFORE UPDATE ON email_config
  FOR EACH ROW EXECUTE FUNCTION update_comm_updated_at();

CREATE TRIGGER trg_auto_rules_updated_at BEFORE UPDATE ON auto_notification_rules
  FOR EACH ROW EXECUTE FUNCTION update_comm_updated_at();
