-- =============================================
-- Notice Board
-- =============================================

DO $$ BEGIN
  CREATE TYPE notice_category AS ENUM (
    'academic', 'sports', 'events', 'holiday',
    'examination', 'fee', 'general', 'emergency'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE notice_audience AS ENUM (
    'all', 'students', 'parents', 'teachers', 'staff'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS notices (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title          TEXT NOT NULL,
  body           TEXT NOT NULL,
  category       notice_category NOT NULL DEFAULT 'general',
  audience       notice_audience NOT NULL DEFAULT 'all',
  is_pinned      BOOLEAN NOT NULL DEFAULT FALSE,
  is_published   BOOLEAN NOT NULL DEFAULT TRUE,
  attachment_url TEXT,
  attachment_name TEXT,
  created_by     UUID NOT NULL REFERENCES users(id),
  expires_at     TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notices_tenant ON notices(tenant_id, is_published);
CREATE INDEX IF NOT EXISTS idx_notices_pinned ON notices(tenant_id, is_pinned) WHERE is_pinned = TRUE;
CREATE INDEX IF NOT EXISTS idx_notices_category ON notices(tenant_id, category);
CREATE INDEX IF NOT EXISTS idx_notices_audience ON notices(tenant_id, audience);
CREATE INDEX IF NOT EXISTS idx_notices_expires ON notices(expires_at) WHERE expires_at IS NOT NULL;

ALTER TABLE notices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notices_select" ON notices
  FOR SELECT USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );

CREATE POLICY "notices_insert" ON notices
  FOR INSERT WITH CHECK (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND created_by = auth.uid()
  );

CREATE POLICY "notices_update" ON notices
  FOR UPDATE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND (created_by = auth.uid()
      OR EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid()
          AND role IN ('super_admin', 'tenant_admin', 'principal')
      )
    )
  );

CREATE POLICY "notices_delete" ON notices
  FOR DELETE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    AND (created_by = auth.uid()
      OR EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid()
          AND role IN ('super_admin', 'tenant_admin', 'principal')
      )
    )
  );

CREATE OR REPLACE FUNCTION update_notices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notices_updated_at
  BEFORE UPDATE ON notices
  FOR EACH ROW EXECUTE FUNCTION update_notices_updated_at();
