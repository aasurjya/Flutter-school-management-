-- Stores the initial generated password for admin-created users.
-- Only the creator (or super_admin) can read. Only service_role can insert.
CREATE TABLE IF NOT EXISTS user_credentials (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tenant_id   uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email       text NOT NULL,
  initial_password text NOT NULL,
  created_by  uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id)
);

ALTER TABLE user_credentials ENABLE ROW LEVEL SECURITY;

-- Super admins can view all credentials
CREATE POLICY "Super admins view all credentials"
  ON user_credentials FOR SELECT
  USING (has_role('super_admin'::user_role));

-- Admins/principals can view credentials they created
CREATE POLICY "Creators view credentials"
  ON user_credentials FOR SELECT
  USING (created_by = auth.uid());

-- Only service_role (edge function) may insert — no direct client insert
CREATE POLICY "Service role inserts credentials"
  ON user_credentials FOR INSERT
  WITH CHECK (false);
