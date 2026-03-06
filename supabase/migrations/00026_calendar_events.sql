-- ============================================
-- School Calendar & Events Module
-- ============================================

-- Event type enum - add missing values to existing enum from 00001
DO $$ BEGIN
  CREATE TYPE event_type AS ENUM (
    'academic', 'cultural', 'sports', 'holiday', 'exam',
    'pta_meeting', 'workshop', 'field_trip', 'competition', 'celebration'
  );
EXCEPTION WHEN duplicate_object THEN
  -- Enum exists from 00001 with fewer values; add missing ones
  BEGIN ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'academic'; EXCEPTION WHEN others THEN NULL; END;
  BEGIN ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'cultural'; EXCEPTION WHEN others THEN NULL; END;
  BEGIN ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'sports'; EXCEPTION WHEN others THEN NULL; END;
  BEGIN ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'pta_meeting'; EXCEPTION WHEN others THEN NULL; END;
  BEGIN ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'workshop'; EXCEPTION WHEN others THEN NULL; END;
  BEGIN ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'field_trip'; EXCEPTION WHEN others THEN NULL; END;
  BEGIN ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'competition'; EXCEPTION WHEN others THEN NULL; END;
  BEGIN ALTER TYPE event_type ADD VALUE IF NOT EXISTS 'celebration'; EXCEPTION WHEN others THEN NULL; END;
END $$;

-- Event visibility enum
DO $$ BEGIN
  CREATE TYPE event_visibility AS ENUM (
    'all', 'teachers', 'students', 'parents', 'staff'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Event status enum
DO $$ BEGIN
  CREATE TYPE event_status AS ENUM (
    'scheduled', 'ongoing', 'completed', 'cancelled', 'postponed'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- RSVP status enum
DO $$ BEGIN
  CREATE TYPE rsvp_status AS ENUM (
    'pending', 'attending', 'not_attending', 'maybe'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Reminder type enum
DO $$ BEGIN
  CREATE TYPE reminder_type AS ENUM (
    'push', 'email', 'sms'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Academic calendar item type enum
DO $$ BEGIN
  CREATE TYPE academic_item_type AS ENUM (
    'term_start', 'term_end', 'exam_start', 'exam_end', 'holiday',
    'result_date', 'admission_start', 'admission_end', 'fee_deadline'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Holiday type enum
DO $$ BEGIN
  CREATE TYPE holiday_type AS ENUM (
    'national', 'state', 'religious', 'school_declared', 'vacation'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Recurrence frequency enum
DO $$ BEGIN
  CREATE TYPE recurrence_frequency AS ENUM (
    'daily', 'weekly', 'monthly', 'yearly'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================
-- school_events
-- ============================================
CREATE TABLE IF NOT EXISTS school_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  description   TEXT,
  event_type    TEXT NOT NULL DEFAULT 'academic',
  start_date    DATE NOT NULL,
  end_date      DATE NOT NULL,
  start_time    TIME,
  end_time      TIME,
  is_all_day    BOOLEAN NOT NULL DEFAULT TRUE,
  location      TEXT,
  is_recurring  BOOLEAN NOT NULL DEFAULT FALSE,
  recurrence_rule JSONB,  -- {frequency, interval, end_date, days_of_week[]}
  color_hex     TEXT,
  icon          TEXT,
  created_by    UUID REFERENCES users(id),
  visibility    event_visibility NOT NULL DEFAULT 'all',
  target_classes JSONB,  -- array of class IDs
  is_mandatory  BOOLEAN NOT NULL DEFAULT FALSE,
  status        event_status NOT NULL DEFAULT 'scheduled',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_event_dates CHECK (end_date >= start_date)
);

CREATE INDEX idx_school_events_tenant ON school_events(tenant_id);
CREATE INDEX idx_school_events_dates ON school_events(start_date, end_date);
CREATE INDEX idx_school_events_type ON school_events(tenant_id, event_type);
CREATE INDEX idx_school_events_status ON school_events(tenant_id, status);
CREATE INDEX idx_school_events_created_by ON school_events(created_by);

-- ============================================
-- event_attendees
-- ============================================
CREATE TABLE IF NOT EXISTS event_attendees (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id      UUID NOT NULL REFERENCES school_events(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rsvp_status   rsvp_status NOT NULL DEFAULT 'pending',
  attended      BOOLEAN NOT NULL DEFAULT FALSE,
  check_in_time TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_event_attendee UNIQUE (event_id, user_id)
);

CREATE INDEX idx_event_attendees_event ON event_attendees(event_id);
CREATE INDEX idx_event_attendees_user ON event_attendees(user_id);
CREATE INDEX idx_event_attendees_rsvp ON event_attendees(event_id, rsvp_status);

-- ============================================
-- event_reminders
-- ============================================
CREATE TABLE IF NOT EXISTS event_reminders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id        UUID NOT NULL REFERENCES school_events(id) ON DELETE CASCADE,
  reminder_type   reminder_type NOT NULL DEFAULT 'push',
  minutes_before  INT NOT NULL DEFAULT 30,
  sent            BOOLEAN NOT NULL DEFAULT FALSE,
  sent_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_event_reminders_event ON event_reminders(event_id);
CREATE INDEX idx_event_reminders_pending ON event_reminders(sent, event_id) WHERE sent = FALSE;

-- ============================================
-- academic_calendar_items
-- ============================================
CREATE TABLE IF NOT EXISTS academic_calendar_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  date            DATE NOT NULL,
  end_date        DATE,
  item_type       academic_item_type NOT NULL,
  is_holiday      BOOLEAN NOT NULL DEFAULT FALSE,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_academic_cal_tenant ON academic_calendar_items(tenant_id);
CREATE INDEX idx_academic_cal_year ON academic_calendar_items(academic_year_id);
CREATE INDEX idx_academic_cal_date ON academic_calendar_items(tenant_id, date);
CREATE INDEX idx_academic_cal_type ON academic_calendar_items(tenant_id, item_type);

-- ============================================
-- holiday_calendar
-- ============================================
CREATE TABLE IF NOT EXISTS holiday_calendar (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  date            DATE NOT NULL,
  end_date        DATE,
  type            holiday_type NOT NULL DEFAULT 'school_declared',
  is_optional     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_holiday_tenant ON holiday_calendar(tenant_id);
CREATE INDEX idx_holiday_year ON holiday_calendar(academic_year_id);
CREATE INDEX idx_holiday_date ON holiday_calendar(tenant_id, date);
CREATE INDEX idx_holiday_type ON holiday_calendar(tenant_id, type);

-- ============================================
-- Row Level Security
-- ============================================
ALTER TABLE school_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_calendar_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE holiday_calendar ENABLE ROW LEVEL SECURITY;

-- school_events policies
CREATE POLICY "school_events_select" ON school_events
  FOR SELECT USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );
CREATE POLICY "school_events_insert" ON school_events
  FOR INSERT WITH CHECK (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );
CREATE POLICY "school_events_update" ON school_events
  FOR UPDATE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );
CREATE POLICY "school_events_delete" ON school_events
  FOR DELETE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );

-- event_attendees policies
CREATE POLICY "event_attendees_select" ON event_attendees
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM school_events
      WHERE school_events.id = event_attendees.event_id
      AND school_events.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    )
  );
CREATE POLICY "event_attendees_insert" ON event_attendees
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM school_events
      WHERE school_events.id = event_attendees.event_id
      AND school_events.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    )
  );
CREATE POLICY "event_attendees_update" ON event_attendees
  FOR UPDATE USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM school_events
      WHERE school_events.id = event_attendees.event_id
      AND school_events.created_by = auth.uid()
    )
  );
CREATE POLICY "event_attendees_delete" ON event_attendees
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM school_events
      WHERE school_events.id = event_attendees.event_id
      AND school_events.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    )
  );

-- event_reminders policies
CREATE POLICY "event_reminders_select" ON event_reminders
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM school_events
      WHERE school_events.id = event_reminders.event_id
      AND school_events.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    )
  );
CREATE POLICY "event_reminders_insert" ON event_reminders
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM school_events
      WHERE school_events.id = event_reminders.event_id
      AND school_events.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    )
  );
CREATE POLICY "event_reminders_update" ON event_reminders
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM school_events
      WHERE school_events.id = event_reminders.event_id
      AND school_events.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    )
  );
CREATE POLICY "event_reminders_delete" ON event_reminders
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM school_events
      WHERE school_events.id = event_reminders.event_id
      AND school_events.tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
    )
  );

-- academic_calendar_items policies
CREATE POLICY "academic_cal_select" ON academic_calendar_items
  FOR SELECT USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );
CREATE POLICY "academic_cal_insert" ON academic_calendar_items
  FOR INSERT WITH CHECK (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );
CREATE POLICY "academic_cal_update" ON academic_calendar_items
  FOR UPDATE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );
CREATE POLICY "academic_cal_delete" ON academic_calendar_items
  FOR DELETE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );

-- holiday_calendar policies
CREATE POLICY "holiday_cal_select" ON holiday_calendar
  FOR SELECT USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );
CREATE POLICY "holiday_cal_insert" ON holiday_calendar
  FOR INSERT WITH CHECK (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );
CREATE POLICY "holiday_cal_update" ON holiday_calendar
  FOR UPDATE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );
CREATE POLICY "holiday_cal_delete" ON holiday_calendar
  FOR DELETE USING (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::UUID
  );

-- ============================================
-- Triggers: updated_at auto-update
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_school_events_updated_at
  BEFORE UPDATE ON school_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_event_attendees_updated_at
  BEFORE UPDATE ON event_attendees
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_academic_cal_updated_at
  BEFORE UPDATE ON academic_calendar_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_holiday_cal_updated_at
  BEFORE UPDATE ON holiday_calendar
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
