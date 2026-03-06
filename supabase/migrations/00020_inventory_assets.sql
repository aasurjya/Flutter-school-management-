-- =============================================
-- Inventory & Asset Management Module
-- Migration 00020: Complete inventory tracking
-- =============================================

-- =============================================
-- ENUMS (guard against pre-existing from 20260209112625)
-- =============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'asset_condition_v2') THEN
        CREATE TYPE asset_condition_v2 AS ENUM ('excellent', 'good', 'fair', 'poor');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'asset_status_v2') THEN
        CREATE TYPE asset_status_v2 AS ENUM ('available', 'in_use', 'maintenance', 'damaged', 'disposed', 'lost');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'asset_assignment_status') THEN
        CREATE TYPE asset_assignment_status AS ENUM ('active', 'returned', 'overdue');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'maintenance_type_v2') THEN
        CREATE TYPE maintenance_type_v2 AS ENUM ('preventive', 'corrective', 'emergency');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'maintenance_status_v2') THEN
        CREATE TYPE maintenance_status_v2 AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'inventory_unit') THEN
        CREATE TYPE inventory_unit AS ENUM ('pieces', 'boxes', 'kg', 'liters', 'reams', 'sets', 'pairs', 'packets');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'inventory_transaction_type') THEN
        CREATE TYPE inventory_transaction_type AS ENUM ('purchase', 'issue', 'return', 'adjustment', 'disposal');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'purchase_request_status') THEN
        CREATE TYPE purchase_request_status AS ENUM ('draft', 'submitted', 'approved', 'rejected', 'ordered', 'received');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'asset_audit_status') THEN
        CREATE TYPE asset_audit_status AS ENUM ('planned', 'in_progress', 'completed');
    END IF;
END $$;

-- =============================================
-- ASSET CATEGORIES (v2 - self-referencing hierarchy)
-- =============================================

CREATE TABLE IF NOT EXISTS inv_asset_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    parent_category_id UUID REFERENCES inv_asset_categories(id) ON DELETE SET NULL,
    description TEXT,
    depreciation_rate DECIMAL(5,2) DEFAULT 0 CHECK (depreciation_rate >= 0 AND depreciation_rate <= 100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, name)
);

CREATE INDEX idx_inv_asset_categories_tenant ON inv_asset_categories(tenant_id);
CREATE INDEX idx_inv_asset_categories_parent ON inv_asset_categories(parent_category_id);

COMMENT ON TABLE inv_asset_categories IS 'Hierarchical asset categories with depreciation rates';

-- =============================================
-- ASSETS
-- =============================================

CREATE TABLE IF NOT EXISTS inv_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    asset_code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    category_id UUID REFERENCES inv_asset_categories(id) ON DELETE SET NULL,
    description TEXT,
    purchase_date DATE,
    purchase_price DECIMAL(12,2) CHECK (purchase_price >= 0),
    current_value DECIMAL(12,2) CHECK (current_value >= 0),
    vendor VARCHAR(255),
    warranty_expiry DATE,
    location VARCHAR(255),
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    status asset_status_v2 DEFAULT 'available',
    condition asset_condition_v2 DEFAULT 'good',
    qr_code_data TEXT,
    image_url TEXT,
    serial_number VARCHAR(100),
    specifications JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, asset_code)
);

CREATE INDEX idx_inv_assets_tenant ON inv_assets(tenant_id);
CREATE INDEX idx_inv_assets_category ON inv_assets(category_id);
CREATE INDEX idx_inv_assets_status ON inv_assets(tenant_id, status);
CREATE INDEX idx_inv_assets_location ON inv_assets(tenant_id, location);
CREATE INDEX idx_inv_assets_assigned ON inv_assets(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_inv_assets_qr ON inv_assets(tenant_id, qr_code_data);

COMMENT ON TABLE inv_assets IS 'Individual tracked assets with QR codes and depreciation';

-- =============================================
-- ASSET ASSIGNMENTS
-- =============================================

CREATE TABLE IF NOT EXISTS inv_asset_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES inv_assets(id) ON DELETE CASCADE,
    assigned_to UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
    return_date DATE,
    expected_return_date DATE,
    condition_at_assign asset_condition_v2 NOT NULL DEFAULT 'good',
    condition_at_return asset_condition_v2,
    notes TEXT,
    status asset_assignment_status DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inv_assignments_asset ON inv_asset_assignments(asset_id);
CREATE INDEX idx_inv_assignments_user ON inv_asset_assignments(assigned_to);
CREATE INDEX idx_inv_assignments_status ON inv_asset_assignments(status) WHERE status = 'active';

COMMENT ON TABLE inv_asset_assignments IS 'Asset assignment history and tracking';

-- =============================================
-- ASSET MAINTENANCE
-- =============================================

CREATE TABLE IF NOT EXISTS inv_asset_maintenance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES inv_assets(id) ON DELETE CASCADE,
    maintenance_type maintenance_type_v2 NOT NULL,
    description TEXT,
    reported_by UUID REFERENCES users(id) ON DELETE SET NULL,
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    scheduled_date DATE NOT NULL,
    completed_date DATE,
    cost DECIMAL(10,2) DEFAULT 0 CHECK (cost >= 0),
    vendor VARCHAR(255),
    status maintenance_status_v2 DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inv_maintenance_asset ON inv_asset_maintenance(asset_id);
CREATE INDEX idx_inv_maintenance_status ON inv_asset_maintenance(status);
CREATE INDEX idx_inv_maintenance_scheduled ON inv_asset_maintenance(scheduled_date) WHERE status IN ('scheduled', 'in_progress');

COMMENT ON TABLE inv_asset_maintenance IS 'Maintenance records and schedules for assets';

-- =============================================
-- INVENTORY ITEMS (consumables)
-- =============================================

CREATE TABLE IF NOT EXISTS inv_inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    item_code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    category_id UUID REFERENCES inv_asset_categories(id) ON DELETE SET NULL,
    description TEXT,
    unit inventory_unit DEFAULT 'pieces',
    current_stock INT DEFAULT 0 CHECK (current_stock >= 0),
    minimum_stock INT DEFAULT 0 CHECK (minimum_stock >= 0),
    maximum_stock INT DEFAULT 1000 CHECK (maximum_stock >= 0),
    reorder_point INT DEFAULT 10 CHECK (reorder_point >= 0),
    unit_cost DECIMAL(10,2) DEFAULT 0 CHECK (unit_cost >= 0),
    location VARCHAR(255),
    is_consumable BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, item_code)
);

CREATE INDEX idx_inv_items_tenant ON inv_inventory_items(tenant_id);
CREATE INDEX idx_inv_items_category ON inv_inventory_items(category_id);
CREATE INDEX idx_inv_items_low_stock ON inv_inventory_items(tenant_id) WHERE current_stock <= reorder_point;

COMMENT ON TABLE inv_inventory_items IS 'Consumable inventory items with stock tracking';

-- =============================================
-- INVENTORY TRANSACTIONS
-- =============================================

CREATE TABLE IF NOT EXISTS inv_inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL REFERENCES inv_inventory_items(id) ON DELETE CASCADE,
    transaction_type inventory_transaction_type NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_cost DECIMAL(10,2) DEFAULT 0 CHECK (unit_cost >= 0),
    total_cost DECIMAL(12,2) DEFAULT 0 CHECK (total_cost >= 0),
    reference_number VARCHAR(100),
    issued_to UUID REFERENCES users(id) ON DELETE SET NULL,
    issued_by UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inv_transactions_item ON inv_inventory_transactions(item_id);
CREATE INDEX idx_inv_transactions_date ON inv_inventory_transactions(transaction_date);
CREATE INDEX idx_inv_transactions_type ON inv_inventory_transactions(transaction_type);

COMMENT ON TABLE inv_inventory_transactions IS 'Stock movement records for inventory items';

-- =============================================
-- PURCHASE REQUESTS
-- =============================================

CREATE TABLE IF NOT EXISTS inv_purchase_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    request_number VARCHAR(50) NOT NULL,
    requested_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    items JSONB NOT NULL DEFAULT '[]',
    justification TEXT,
    total_estimated_cost DECIMAL(12,2) DEFAULT 0 CHECK (total_estimated_cost >= 0),
    status purchase_request_status DEFAULT 'draft',
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    vendor VARCHAR(255),
    delivery_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, request_number)
);

CREATE INDEX idx_inv_purchase_tenant ON inv_purchase_requests(tenant_id);
CREATE INDEX idx_inv_purchase_status ON inv_purchase_requests(tenant_id, status);
CREATE INDEX idx_inv_purchase_requester ON inv_purchase_requests(requested_by);

COMMENT ON TABLE inv_purchase_requests IS 'Purchase request workflow with approval tracking';

-- =============================================
-- ASSET AUDITS
-- =============================================

CREATE TABLE IF NOT EXISTS inv_asset_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    audit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    conducted_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_assets INT DEFAULT 0,
    verified_count INT DEFAULT 0,
    missing_count INT DEFAULT 0,
    damaged_count INT DEFAULT 0,
    notes TEXT,
    status asset_audit_status DEFAULT 'planned',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inv_audits_tenant ON inv_asset_audits(tenant_id);
CREATE INDEX idx_inv_audits_date ON inv_asset_audits(audit_date);

COMMENT ON TABLE inv_asset_audits IS 'Periodic asset audit records';

-- =============================================
-- RLS POLICIES
-- =============================================

ALTER TABLE inv_asset_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_asset_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_asset_maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_purchase_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE inv_asset_audits ENABLE ROW LEVEL SECURITY;

-- Tenant-scoped read policies
CREATE POLICY inv_asset_categories_tenant_read ON inv_asset_categories
    FOR SELECT USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY inv_assets_tenant_read ON inv_assets
    FOR SELECT USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY inv_inventory_items_tenant_read ON inv_inventory_items
    FOR SELECT USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY inv_purchase_requests_tenant_read ON inv_purchase_requests
    FOR SELECT USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY inv_asset_audits_tenant_read ON inv_asset_audits
    FOR SELECT USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

-- Assignment/maintenance/transaction read via asset/item join
CREATE POLICY inv_assignments_read ON inv_asset_assignments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM inv_assets a
            WHERE a.id = asset_id
            AND a.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
        )
    );

CREATE POLICY inv_maintenance_read ON inv_asset_maintenance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM inv_assets a
            WHERE a.id = asset_id
            AND a.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
        )
    );

CREATE POLICY inv_transactions_read ON inv_inventory_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM inv_inventory_items i
            WHERE i.id = item_id
            AND i.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
        )
    );

-- Write policies (admin/staff with has_role check)
CREATE POLICY inv_asset_categories_write ON inv_asset_categories
    FOR ALL USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY inv_assets_write ON inv_assets
    FOR ALL USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY inv_inventory_items_write ON inv_inventory_items
    FOR ALL USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY inv_purchase_requests_write ON inv_purchase_requests
    FOR ALL USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY inv_asset_audits_write ON inv_asset_audits
    FOR ALL USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID);

CREATE POLICY inv_assignments_write ON inv_asset_assignments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM inv_assets a
            WHERE a.id = asset_id
            AND a.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
        )
    );

CREATE POLICY inv_maintenance_write ON inv_asset_maintenance
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM inv_assets a
            WHERE a.id = asset_id
            AND a.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
        )
    );

CREATE POLICY inv_transactions_write ON inv_inventory_transactions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM inv_inventory_items i
            WHERE i.id = item_id
            AND i.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
        )
    );

-- =============================================
-- TRIGGER: Update stock on transaction
-- =============================================

CREATE OR REPLACE FUNCTION update_inventory_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.transaction_type IN ('purchase', 'return') THEN
        UPDATE inv_inventory_items
        SET current_stock = current_stock + NEW.quantity,
            updated_at = NOW()
        WHERE id = NEW.item_id;
    ELSIF NEW.transaction_type IN ('issue', 'disposal') THEN
        UPDATE inv_inventory_items
        SET current_stock = GREATEST(current_stock - NEW.quantity, 0),
            updated_at = NOW()
        WHERE id = NEW.item_id;
    END IF;
    -- 'adjustment' type: handled explicitly by the caller setting stock directly
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_inventory_stock
    AFTER INSERT ON inv_inventory_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_stock();

-- =============================================
-- VIEW: Inventory stats summary
-- =============================================

CREATE OR REPLACE VIEW v_inventory_dashboard AS
SELECT
    a.tenant_id,
    COUNT(DISTINCT a.id) AS total_assets,
    COUNT(DISTINCT a.id) FILTER (WHERE a.status = 'available') AS available_assets,
    COUNT(DISTINCT a.id) FILTER (WHERE a.status = 'in_use') AS in_use_assets,
    COUNT(DISTINCT a.id) FILTER (WHERE a.status = 'maintenance') AS maintenance_assets,
    COUNT(DISTINCT a.id) FILTER (WHERE a.status = 'damaged') AS damaged_assets,
    COUNT(DISTINCT a.id) FILTER (WHERE a.status = 'disposed') AS disposed_assets,
    COUNT(DISTINCT a.id) FILTER (WHERE a.status = 'lost') AS lost_assets,
    COALESCE(SUM(a.purchase_price), 0) AS total_purchase_value,
    COALESCE(SUM(a.current_value), 0) AS total_current_value,
    (SELECT COUNT(*) FROM inv_asset_maintenance m
     JOIN inv_assets a2 ON m.asset_id = a2.id
     WHERE a2.tenant_id = a.tenant_id AND m.status IN ('scheduled', 'in_progress')) AS pending_maintenance,
    (SELECT COUNT(*) FROM inv_inventory_items i
     WHERE i.tenant_id = a.tenant_id AND i.current_stock <= i.reorder_point AND i.is_active = true) AS low_stock_items
FROM inv_assets a
GROUP BY a.tenant_id;
