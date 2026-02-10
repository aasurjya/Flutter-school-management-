-- =============================================
-- Integration Readiness
-- Phase 8: Payment Gateway & Communication Logs
-- =============================================

-- =============================================
-- PAYMENT GATEWAY TRANSACTIONS
-- =============================================

CREATE TABLE payment_gateway_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    gateway_name VARCHAR(50) NOT NULL, -- 'razorpay', 'stripe', 'paypal', 'paytm'
    gateway_transaction_id VARCHAR(255),
    gateway_order_id VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(3) DEFAULT 'INR',
    status VARCHAR(50) DEFAULT 'created', -- 'created', 'authorized', 'captured', 'failed', 'refunded'
    payment_method VARCHAR(50), -- 'card', 'upi', 'netbanking', 'wallet'
    card_last4 VARCHAR(4),
    card_brand VARCHAR(20),
    upi_id VARCHAR(255),
    gateway_request JSONB,
    gateway_response JSONB,
    error_code VARCHAR(100),
    error_message TEXT,
    refund_id VARCHAR(255),
    refund_amount DECIMAL(10,2),
    refund_reason TEXT,
    webhook_received BOOLEAN DEFAULT false,
    webhook_payload JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    captured_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ
);

COMMENT ON TABLE payment_gateway_transactions IS 'Payment gateway transaction logs for reconciliation';

-- =============================================
-- SMS LOGS
-- =============================================

CREATE TABLE sms_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    recipient_phone VARCHAR(20) NOT NULL,
    recipient_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    recipient_type VARCHAR(50), -- 'student', 'parent', 'staff'
    message_content TEXT NOT NULL,
    message_type VARCHAR(50), -- 'transactional', 'promotional', 'otp', 'alert'
    template_id VARCHAR(100),
    gateway_name VARCHAR(50) NOT NULL, -- 'twilio', 'msg91', 'aws_sns'
    gateway_message_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'sent', 'delivered', 'failed', 'rejected'
    failure_reason TEXT,
    credits_used INT DEFAULT 1,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE sms_logs IS 'SMS message delivery logs';

-- =============================================
-- EMAIL LOGS
-- =============================================

CREATE TABLE email_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    recipient_email VARCHAR(255) NOT NULL,
    recipient_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    recipient_type VARCHAR(50), -- 'student', 'parent', 'staff'
    cc_emails TEXT[] DEFAULT '{}',
    bcc_emails TEXT[] DEFAULT '{}',
    subject VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    html_body TEXT,
    message_type VARCHAR(50), -- 'transactional', 'promotional', 'notification', 'report'
    template_id VARCHAR(100),
    attachments JSONB DEFAULT '[]', -- [{"name": "report.pdf", "url": "..."}]
    gateway_name VARCHAR(50) NOT NULL, -- 'sendgrid', 'aws_ses', 'mailgun'
    gateway_message_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'sent', 'delivered', 'opened', 'clicked', 'bounced', 'failed'
    failure_reason TEXT,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    bounced_at TIMESTAMPTZ,
    bounce_type VARCHAR(50), -- 'hard', 'soft'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE email_logs IS 'Email message delivery and engagement logs';

-- =============================================
-- PUSH NOTIFICATION LOGS
-- =============================================

CREATE TABLE push_notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    recipient_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    notification_type VARCHAR(50), -- 'announcement', 'alert', 'reminder', 'message'
    data JSONB DEFAULT '{}',
    image_url TEXT,
    click_action VARCHAR(255),
    gateway_name VARCHAR(50) DEFAULT 'fcm', -- 'fcm', 'apns'
    gateway_message_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'sent', 'delivered', 'failed', 'clicked'
    failure_reason TEXT,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE push_notification_logs IS 'Push notification delivery logs';

-- =============================================
-- WEBHOOK LOGS
-- =============================================

CREATE TABLE webhook_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    webhook_source VARCHAR(100) NOT NULL, -- 'razorpay', 'stripe', 'twilio', etc.
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    headers JSONB,
    ip_address VARCHAR(45),
    signature_valid BOOLEAN,
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMPTZ,
    processing_error TEXT,
    retry_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE webhook_logs IS 'Incoming webhook logs from third-party services';

-- =============================================
-- API USAGE LOGS
-- =============================================

CREATE TABLE api_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    api_key_id UUID,
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL, -- 'GET', 'POST', 'PUT', 'DELETE'
    status_code INT NOT NULL,
    response_time_ms INT,
    request_size_bytes INT,
    response_size_bytes INT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE api_usage_logs IS 'API endpoint usage logs for monitoring and billing';

-- =============================================
-- INDEXES
-- =============================================

-- Payment Gateway Transactions
CREATE INDEX idx_payment_gateway_tenant ON payment_gateway_transactions(tenant_id, created_at DESC);
CREATE INDEX idx_payment_gateway_payment ON payment_gateway_transactions(payment_id);
CREATE INDEX idx_payment_gateway_status ON payment_gateway_transactions(status, created_at DESC);
CREATE INDEX idx_payment_gateway_gateway_id ON payment_gateway_transactions(gateway_name, gateway_transaction_id);

-- SMS Logs
CREATE INDEX idx_sms_logs_tenant ON sms_logs(tenant_id, created_at DESC);
CREATE INDEX idx_sms_logs_recipient ON sms_logs(recipient_phone, created_at DESC);
CREATE INDEX idx_sms_logs_status ON sms_logs(status, created_at DESC);
CREATE INDEX idx_sms_logs_user ON sms_logs(recipient_user_id, created_at DESC);

-- Email Logs
CREATE INDEX idx_email_logs_tenant ON email_logs(tenant_id, created_at DESC);
CREATE INDEX idx_email_logs_recipient ON email_logs(recipient_email, created_at DESC);
CREATE INDEX idx_email_logs_status ON email_logs(status, created_at DESC);
CREATE INDEX idx_email_logs_user ON email_logs(recipient_user_id, created_at DESC);

-- Push Notification Logs
CREATE INDEX idx_push_logs_tenant ON push_notification_logs(tenant_id, created_at DESC);
CREATE INDEX idx_push_logs_user ON push_notification_logs(recipient_user_id, created_at DESC);
CREATE INDEX idx_push_logs_status ON push_notification_logs(status, created_at DESC);

-- Webhook Logs
CREATE INDEX idx_webhook_logs_tenant ON webhook_logs(tenant_id, created_at DESC);
CREATE INDEX idx_webhook_logs_source ON webhook_logs(webhook_source, event_type);
CREATE INDEX idx_webhook_logs_processed ON webhook_logs(processed, created_at)
    WHERE processed = false;

-- API Usage Logs
CREATE INDEX idx_api_usage_tenant ON api_usage_logs(tenant_id, created_at DESC);
CREATE INDEX idx_api_usage_user ON api_usage_logs(user_id, created_at DESC);
CREATE INDEX idx_api_usage_endpoint ON api_usage_logs(endpoint, created_at DESC);

-- =============================================
-- STORED PROCEDURES
-- =============================================

-- Log SMS send
CREATE OR REPLACE FUNCTION log_sms_send(
    p_tenant_id UUID,
    p_recipient_phone VARCHAR(20),
    p_message_content TEXT,
    p_gateway_name VARCHAR(50)
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO sms_logs (
        tenant_id,
        recipient_phone,
        message_content,
        gateway_name,
        status
    ) VALUES (
        p_tenant_id,
        p_recipient_phone,
        p_message_content,
        p_gateway_name,
        'pending'
    ) RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION log_sms_send IS 'Creates a log entry for SMS sending';

-- Log email send
CREATE OR REPLACE FUNCTION log_email_send(
    p_tenant_id UUID,
    p_recipient_email VARCHAR(255),
    p_subject VARCHAR(255),
    p_body TEXT,
    p_gateway_name VARCHAR(50)
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO email_logs (
        tenant_id,
        recipient_email,
        subject,
        body,
        gateway_name,
        status
    ) VALUES (
        p_tenant_id,
        p_recipient_email,
        p_subject,
        p_body,
        p_gateway_name,
        'pending'
    ) RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION log_email_send IS 'Creates a log entry for email sending';

-- Update gateway transaction status
CREATE OR REPLACE FUNCTION update_gateway_transaction_status(
    p_gateway_transaction_id VARCHAR(255),
    p_status VARCHAR(50),
    p_gateway_response JSONB
)
RETURNS VOID AS $$
BEGIN
    UPDATE payment_gateway_transactions
    SET
        status = p_status,
        gateway_response = p_gateway_response,
        updated_at = NOW(),
        captured_at = CASE WHEN p_status = 'captured' THEN NOW() ELSE captured_at END,
        refunded_at = CASE WHEN p_status = 'refunded' THEN NOW() ELSE refunded_at END
    WHERE gateway_transaction_id = p_gateway_transaction_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_gateway_transaction_status IS 'Updates payment gateway transaction status from webhooks';

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE payment_gateway_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_usage_logs ENABLE ROW LEVEL SECURITY;
