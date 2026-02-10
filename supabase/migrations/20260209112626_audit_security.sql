-- =============================================
-- Audit & Security
-- Phase 7: Audit Logging & Data Retention
-- =============================================

-- =============================================
-- AUDIT LOGS
-- =============================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'view', 'export'
    table_name VARCHAR(100) NOT NULL,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[] DEFAULT '{}',
    ip_address VARCHAR(45),
    user_agent TEXT,
    request_id VARCHAR(100),
    session_id VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE audit_logs IS 'Comprehensive audit trail of all data changes';
COMMENT ON COLUMN audit_logs.changed_fields IS 'Array of field names that were modified';

-- =============================================
-- DATA ACCESS LOGS
-- =============================================

CREATE TABLE data_access_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    accessed_table VARCHAR(100) NOT NULL,
    accessed_record_id UUID,
    access_type VARCHAR(20) NOT NULL, -- 'read', 'export', 'print'
    access_reason TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    accessed_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE data_access_logs IS 'Log of access to sensitive data for compliance';

-- =============================================
-- LOGIN AUDIT
-- =============================================

CREATE TABLE login_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    email VARCHAR(255) NOT NULL,
    login_status VARCHAR(20) NOT NULL, -- 'success', 'failed', 'blocked'
    failure_reason VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_info JSONB,
    location_info JSONB,
    two_factor_used BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE login_audit IS 'Audit trail of login attempts';

-- =============================================
-- DATA RETENTION POLICIES
-- =============================================

CREATE TABLE data_retention_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    table_name VARCHAR(100) NOT NULL,
    policy_name VARCHAR(255) NOT NULL,
    retention_period_days INT NOT NULL CHECK (retention_period_days > 0),
    archive_after_days INT CHECK (archive_after_days > 0),
    delete_after_days INT CHECK (delete_after_days > 0),
    is_active BOOLEAN DEFAULT true,
    last_run_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, table_name),
    CONSTRAINT valid_retention_period CHECK (
        delete_after_days IS NULL OR
        archive_after_days IS NULL OR
        delete_after_days > archive_after_days
    )
);

COMMENT ON TABLE data_retention_policies IS 'Data retention and archival policies for compliance';

-- =============================================
-- SENSITIVE DATA ENCRYPTION KEYS
-- =============================================

CREATE TABLE encryption_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    key_name VARCHAR(100) NOT NULL,
    key_purpose VARCHAR(255),
    algorithm VARCHAR(50) NOT NULL,
    key_data TEXT NOT NULL, -- Encrypted key
    is_active BOOLEAN DEFAULT true,
    rotation_required_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    rotated_at TIMESTAMPTZ,
    UNIQUE(tenant_id, key_name)
);

COMMENT ON TABLE encryption_keys IS 'Encryption keys for sensitive data protection';

-- =============================================
-- GDPR/FERPA COMPLIANCE
-- =============================================

CREATE TABLE data_subject_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    request_type VARCHAR(50) NOT NULL, -- 'access', 'rectification', 'erasure', 'portability', 'restriction'
    subject_type VARCHAR(50) NOT NULL, -- 'student', 'parent', 'staff', 'other'
    subject_id UUID,
    subject_email VARCHAR(255) NOT NULL,
    subject_name VARCHAR(255),
    request_details TEXT,
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'rejected'
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    due_date DATE,
    completed_at TIMESTAMPTZ,
    response_details TEXT,
    data_exported JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE data_subject_requests IS 'GDPR/FERPA data subject access requests';

-- =============================================
-- INDEXES
-- =============================================

-- Audit Logs (Partitioned table - indexes on partitions)
CREATE INDEX idx_audit_logs_tenant ON audit_logs(tenant_id, created_at DESC);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_table ON audit_logs(table_name, action, created_at DESC);
CREATE INDEX idx_audit_logs_record ON audit_logs(table_name, record_id);

-- Data Access Logs
CREATE INDEX idx_data_access_tenant ON data_access_logs(tenant_id, accessed_at DESC);
CREATE INDEX idx_data_access_user ON data_access_logs(user_id, accessed_at DESC);
CREATE INDEX idx_data_access_table ON data_access_logs(accessed_table, accessed_at DESC);

-- Login Audit
CREATE INDEX idx_login_audit_user ON login_audit(user_id, created_at DESC);
CREATE INDEX idx_login_audit_email ON login_audit(email, created_at DESC);
CREATE INDEX idx_login_audit_status ON login_audit(login_status, created_at DESC);
CREATE INDEX idx_login_audit_ip ON login_audit(ip_address, created_at DESC);

-- Data Retention Policies
CREATE INDEX idx_retention_policies_tenant ON data_retention_policies(tenant_id)
    WHERE is_active = true;

-- Encryption Keys
CREATE INDEX idx_encryption_keys_tenant ON encryption_keys(tenant_id)
    WHERE is_active = true;

-- Data Subject Requests
CREATE INDEX idx_data_subject_requests_tenant ON data_subject_requests(tenant_id, status);
CREATE INDEX idx_data_subject_requests_status ON data_subject_requests(status, due_date);
CREATE INDEX idx_data_subject_requests_assigned ON data_subject_requests(assigned_to, status);

-- =============================================
-- AUDIT TRIGGER FUNCTION
-- =============================================

CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
    v_changed_fields TEXT[];
    v_tenant_id UUID;
    v_user_id UUID;
BEGIN
    -- Extract tenant_id and user_id from the record
    IF TG_OP = 'DELETE' THEN
        v_old_data := to_jsonb(OLD);
        v_tenant_id := (v_old_data->>'tenant_id')::UUID;
    ELSE
        v_new_data := to_jsonb(NEW);
        v_tenant_id := (v_new_data->>'tenant_id')::UUID;
    END IF;

    -- Get current user ID from JWT
    BEGIN
        v_user_id := (current_setting('request.jwt.claims', true)::json->>'sub')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_user_id := NULL;
    END;

    -- Build audit record
    IF TG_OP = 'UPDATE' THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);

        -- Find changed fields
        SELECT array_agg(key)
        INTO v_changed_fields
        FROM jsonb_each(v_new_data)
        WHERE v_new_data->key IS DISTINCT FROM v_old_data->key;
    END IF;

    -- Insert audit log
    INSERT INTO audit_logs (
        tenant_id,
        user_id,
        action,
        table_name,
        record_id,
        old_values,
        new_values,
        changed_fields
    ) VALUES (
        v_tenant_id,
        v_user_id,
        LOWER(TG_OP),
        TG_TABLE_NAME,
        CASE
            WHEN TG_OP = 'DELETE' THEN (v_old_data->>'id')::UUID
            ELSE (v_new_data->>'id')::UUID
        END,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN v_old_data ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN v_new_data ELSE NULL END,
        v_changed_fields
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit_trigger_function IS 'Generic trigger function for audit logging';

-- =============================================
-- ENABLE AUDIT ON SENSITIVE TABLES
-- =============================================

-- Students
CREATE TRIGGER audit_students
    AFTER INSERT OR UPDATE OR DELETE ON students
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Marks
CREATE TRIGGER audit_marks
    AFTER INSERT OR UPDATE OR DELETE ON marks
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Invoices
CREATE TRIGGER audit_invoices
    AFTER INSERT OR UPDATE OR DELETE ON invoices
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Payments
CREATE TRIGGER audit_payments
    AFTER INSERT OR UPDATE OR DELETE ON payments
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Staff
CREATE TRIGGER audit_staff
    AFTER INSERT OR UPDATE OR DELETE ON staff
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Payroll
CREATE TRIGGER audit_payroll
    AFTER INSERT OR UPDATE OR DELETE ON payroll
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- User Roles
CREATE TRIGGER audit_user_roles
    AFTER INSERT OR UPDATE OR DELETE ON user_roles
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- =============================================
-- STORED PROCEDURES
-- =============================================

-- Archive old audit logs
CREATE OR REPLACE FUNCTION archive_old_audit_logs(p_days_old INT DEFAULT 365)
RETURNS INT AS $$
DECLARE
    v_archived_count INT;
BEGIN
    -- TODO: Move to archive table
    -- For now, just delete very old logs
    DELETE FROM audit_logs
    WHERE created_at < NOW() - (p_days_old || ' days')::INTERVAL;

    GET DIAGNOSTICS v_archived_count = ROW_COUNT;
    RETURN v_archived_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION archive_old_audit_logs IS 'Archives or deletes audit logs older than specified days';

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_access_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_retention_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE encryption_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_subject_requests ENABLE ROW LEVEL SECURITY;
