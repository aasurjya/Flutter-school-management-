-- 00068_fix_auth_users_null_tokens.sql
--
-- Fixes login HTTP 500 ("converting NULL to string is unsupported") from GoTrue.
--
-- Root cause
-- ----------
-- Some auth.users rows (created via manual SQL / seed data — e.g. the disabled
-- 00035_seed_data.sql — rather than the GoTrue admin API) have NULL in the
-- token/string columns that GoTrue scans into Go `string` values on sign-in.
-- The Go scanner cannot map NULL -> string, so the /token endpoint returns 500
-- for the WHOLE project and every login fails. Users created through the
-- create-user edge function (auth.admin.createUser) are unaffected because the
-- admin API writes '' for these columns.
--
-- Fix
-- ---
-- Backfill the known GoTrue string columns to '' (the same value the admin API
-- writes for new users). Idempotent: only NULL values are touched via the
-- WHERE clause, so this migration is safe to re-run.

UPDATE auth.users
SET
  confirmation_token         = COALESCE(confirmation_token, ''),
  recovery_token             = COALESCE(recovery_token, ''),
  email_change               = COALESCE(email_change, ''),
  email_change_token_new     = COALESCE(email_change_token_new, ''),
  email_change_token_current = COALESCE(email_change_token_current, ''),
  phone_change               = COALESCE(phone_change, ''),
  phone_change_token         = COALESCE(phone_change_token, ''),
  reauthentication_token     = COALESCE(reauthentication_token, '')
WHERE
  confirmation_token IS NULL
  OR recovery_token IS NULL
  OR email_change IS NULL
  OR email_change_token_new IS NULL
  OR email_change_token_current IS NULL
  OR phone_change IS NULL
  OR phone_change_token IS NULL
  OR reauthentication_token IS NULL;
