-- Migration 00046: Profile completion flow
-- Adds profile_complete flag and extra contact fields to staff

-- 1. Add profile_complete to users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS profile_complete BOOLEAN NOT NULL DEFAULT false;

-- Existing users who already have phone or date_of_birth filled in are
-- considered complete so they are not forced through the setup flow.
UPDATE users
SET profile_complete = true
WHERE phone IS NOT NULL
   OR date_of_birth IS NOT NULL;

-- 2. Add missing contact columns to staff
ALTER TABLE staff
  ADD COLUMN IF NOT EXISTS phone        VARCHAR(20),
  ADD COLUMN IF NOT EXISTS address      TEXT,
  ADD COLUMN IF NOT EXISTS city         VARCHAR(100),
  ADD COLUMN IF NOT EXISTS state        VARCHAR(100);
