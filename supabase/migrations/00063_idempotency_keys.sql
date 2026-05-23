-- ============================================================================
-- 00063_idempotency_keys.sql
--
-- Pre-launch retrofit of `client_request_id` on the 5 user-write tables.
-- The pattern:
--   1. Flutter generates a UUID per user action (tap "Pay", "Mark present",
--      "Send message").
--   2. The Flutter retry layer reuses the same UUID across retries.
--   3. Supabase upserts on (tenant_id, client_request_id) — duplicate writes
--      from flaky-network retries become no-ops instead of double-charges.
--
-- Tables touched (per existing schema on main):
--   • attendance     — double-mark on flaky network
--   • messages       — double-send on tap-and-spinner anxiety
--   • invoices       — double invoice from a click-twice
--   • payments       — DOUBLE-CHARGE (the worst one)
--   • submissions    — double-submit assignment from refresh
--
-- `client_request_id` is nullable so old / legacy paths keep working without
-- a key. The UNIQUE index is partial (`WHERE NOT NULL`) so absence stays free.
--
-- Pre-launch friendly: tables have zero rows in prod today, so no
-- CONCURRENTLY needed; the index build is instant. When we ship this exact
-- pattern to a new post-launch table, the matching Stage-3 migration must
-- use CREATE INDEX CONCURRENTLY in its own statement (which Squawk enforces).
-- ============================================================================

-- Helper macro: add the column + partial unique index in one go. Postgres
-- doesn't have macros, so we just repeat the pattern. Each block is idempotent.

-- --- attendance -------------------------------------------------------------
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS client_request_id UUID;
CREATE UNIQUE INDEX IF NOT EXISTS uq_attendance_client_request_id
  ON public.attendance (tenant_id, client_request_id)
  WHERE client_request_id IS NOT NULL;

-- --- messages ---------------------------------------------------------------
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS client_request_id UUID;
CREATE UNIQUE INDEX IF NOT EXISTS uq_messages_client_request_id
  ON public.messages (tenant_id, client_request_id)
  WHERE client_request_id IS NOT NULL;

-- --- invoices ---------------------------------------------------------------
ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS client_request_id UUID;
CREATE UNIQUE INDEX IF NOT EXISTS uq_invoices_client_request_id
  ON public.invoices (tenant_id, client_request_id)
  WHERE client_request_id IS NOT NULL;

-- --- payments ---------------------------------------------------------------
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS client_request_id UUID;
CREATE UNIQUE INDEX IF NOT EXISTS uq_payments_client_request_id
  ON public.payments (tenant_id, client_request_id)
  WHERE client_request_id IS NOT NULL;

-- --- submissions ------------------------------------------------------------
-- Note: submissions doesn't currently have tenant_id at the table level
-- (joined via assignments). Use student_id + client_request_id as the unique
-- pair, which is the natural per-student dedup key for an in-flight submit.
ALTER TABLE public.submissions
  ADD COLUMN IF NOT EXISTS client_request_id UUID;
CREATE UNIQUE INDEX IF NOT EXISTS uq_submissions_client_request_id
  ON public.submissions (student_id, client_request_id)
  WHERE client_request_id IS NOT NULL;

COMMENT ON COLUMN public.attendance.client_request_id  IS 'Client-supplied UUID for idempotent retries (see docs/runbooks/idempotency.md).';
COMMENT ON COLUMN public.messages.client_request_id    IS 'Client-supplied UUID for idempotent retries.';
COMMENT ON COLUMN public.invoices.client_request_id    IS 'Client-supplied UUID for idempotent retries.';
COMMENT ON COLUMN public.payments.client_request_id    IS 'Client-supplied UUID for idempotent retries — prevents double-charge.';
COMMENT ON COLUMN public.submissions.client_request_id IS 'Client-supplied UUID for idempotent retries.';
