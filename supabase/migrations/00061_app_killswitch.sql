-- ============================================================================
-- 00061_app_killswitch.sql
--
-- Pre-launch "oh no" button. A single Supabase row the app reads at boot —
-- if `maintenance.enabled = true`, the app shows a static maintenance screen
-- and refuses to proceed past splash. Lets us take traffic offline cleanly
-- when something is on fire and Shorebird OTA isn't wired yet.
--
-- Reads are public (anon can read) so the app can check before login.
-- Writes are super_admin only.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.app_killswitch (
  key         TEXT PRIMARY KEY,
  enabled     BOOLEAN     NOT NULL DEFAULT false,
  message     TEXT        NOT NULL DEFAULT '',
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by  UUID
);

COMMENT ON TABLE  public.app_killswitch IS
  'Global app-wide killswitch flags read at boot. See docs/runbooks/killswitch.md.';
COMMENT ON COLUMN public.app_killswitch.key     IS 'Logical key, e.g. ''maintenance''.';
COMMENT ON COLUMN public.app_killswitch.enabled IS 'When true, app halts boot and shows the message.';
COMMENT ON COLUMN public.app_killswitch.message IS 'User-facing copy (1-2 sentences).';

-- Seed the canonical row in disabled state.
INSERT INTO public.app_killswitch (key, enabled, message)
VALUES ('maintenance', false, '')
ON CONFLICT (key) DO NOTHING;

-- updated_at trigger so we can audit when the killswitch was flipped.
CREATE OR REPLACE FUNCTION public.tg_app_killswitch_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_app_killswitch_updated_at ON public.app_killswitch;
CREATE TRIGGER trg_app_killswitch_updated_at
BEFORE UPDATE ON public.app_killswitch
FOR EACH ROW EXECUTE FUNCTION public.tg_app_killswitch_set_updated_at();

-- RLS: public read (so anon clients can check before login), super_admin write.
ALTER TABLE public.app_killswitch ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS app_killswitch_read   ON public.app_killswitch;
CREATE POLICY app_killswitch_read
  ON public.app_killswitch FOR SELECT
  USING (true);

DROP POLICY IF EXISTS app_killswitch_write  ON public.app_killswitch;
CREATE POLICY app_killswitch_write
  ON public.app_killswitch FOR ALL
  USING      (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true')
  WITH CHECK (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true');

GRANT SELECT ON public.app_killswitch TO anon, authenticated;
GRANT INSERT, UPDATE ON public.app_killswitch TO authenticated;
