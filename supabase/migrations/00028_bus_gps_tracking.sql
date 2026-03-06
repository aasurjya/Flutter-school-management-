-- =============================================
-- Bus GPS Tracking & Geofencing
-- =============================================

-- Bus vehicles table (extends transport_routes with GPS-capable vehicles)
CREATE TABLE IF NOT EXISTS bus_vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  route_id UUID REFERENCES transport_routes(id) ON DELETE SET NULL,
  vehicle_number TEXT NOT NULL,
  vehicle_type TEXT NOT NULL DEFAULT 'bus', -- bus, van, minibus
  driver_name TEXT,
  driver_phone TEXT,
  driver_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  helper_name TEXT,
  helper_phone TEXT,
  capacity INTEGER DEFAULT 40,
  is_active BOOLEAN DEFAULT true,
  gps_device_id TEXT, -- hardware tracker ID if any
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Real-time GPS location pings
CREATE TABLE IF NOT EXISTS bus_location_pings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES bus_vehicles(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  speed_kmh DOUBLE PRECISION DEFAULT 0,
  heading DOUBLE PRECISION DEFAULT 0, -- compass bearing 0-360
  accuracy_meters DOUBLE PRECISION,
  is_ignition_on BOOLEAN DEFAULT true,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Latest location per vehicle (materialized for fast reads)
CREATE TABLE IF NOT EXISTS bus_latest_locations (
  vehicle_id UUID PRIMARY KEY REFERENCES bus_vehicles(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  speed_kmh DOUBLE PRECISION DEFAULT 0,
  heading DOUBLE PRECISION DEFAULT 0,
  is_ignition_on BOOLEAN DEFAULT true,
  recorded_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Geofence zones (school, stops, restricted areas)
CREATE TABLE IF NOT EXISTS bus_geofences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  zone_type TEXT NOT NULL DEFAULT 'school', -- school, stop, restricted, custom
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius_meters DOUBLE PRECISION NOT NULL DEFAULT 200,
  is_active BOOLEAN DEFAULT true,
  notify_on_enter BOOLEAN DEFAULT true,
  notify_on_exit BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Geofence events (bus entered/exited a zone)
CREATE TABLE IF NOT EXISTS bus_geofence_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES bus_vehicles(id) ON DELETE CASCADE,
  geofence_id UUID NOT NULL REFERENCES bus_geofences(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL, -- entered, exited
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  notified BOOLEAN DEFAULT false
);

-- Trip logs (start/end of each trip)
CREATE TABLE IF NOT EXISTS bus_trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES bus_vehicles(id) ON DELETE CASCADE,
  route_id UUID REFERENCES transport_routes(id) ON DELETE SET NULL,
  trip_type TEXT NOT NULL DEFAULT 'pickup', -- pickup, drop
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ,
  start_latitude DOUBLE PRECISION,
  start_longitude DOUBLE PRECISION,
  end_latitude DOUBLE PRECISION,
  end_longitude DOUBLE PRECISION,
  distance_km DOUBLE PRECISION,
  status TEXT NOT NULL DEFAULT 'in_progress', -- in_progress, completed, cancelled
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Driver check-in/check-out for each stop
CREATE TABLE IF NOT EXISTS bus_stop_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  trip_id UUID NOT NULL REFERENCES bus_trips(id) ON DELETE CASCADE,
  stop_id UUID NOT NULL REFERENCES transport_stops(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES bus_vehicles(id) ON DELETE CASCADE,
  arrived_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  departed_at TIMESTAMPTZ,
  students_boarded INTEGER DEFAULT 0,
  students_alighted INTEGER DEFAULT 0,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Parent tracking subscriptions (which parents track which vehicles)
CREATE TABLE IF NOT EXISTS bus_tracking_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  parent_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES bus_vehicles(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  notify_arrival BOOLEAN DEFAULT true,
  notify_departure BOOLEAN DEFAULT true,
  notify_delay BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(parent_user_id, vehicle_id, student_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_bus_pings_vehicle_time ON bus_location_pings(vehicle_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_bus_pings_tenant ON bus_location_pings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_bus_latest_tenant ON bus_latest_locations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_bus_geofence_events_vehicle ON bus_geofence_events(vehicle_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_bus_trips_vehicle ON bus_trips(vehicle_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_bus_trips_status ON bus_trips(status) WHERE status = 'in_progress';
CREATE INDEX IF NOT EXISTS idx_bus_stop_checkins_trip ON bus_stop_checkins(trip_id);
CREATE INDEX IF NOT EXISTS idx_bus_tracking_subs_parent ON bus_tracking_subscriptions(parent_user_id);

-- RLS policies
ALTER TABLE bus_vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_location_pings ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_latest_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_geofences ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_geofence_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_stop_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_tracking_subscriptions ENABLE ROW LEVEL SECURITY;

-- Tenant-based RLS for all tables
CREATE POLICY bus_vehicles_tenant ON bus_vehicles
  FOR ALL USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::UUID);

CREATE POLICY bus_pings_tenant ON bus_location_pings
  FOR ALL USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::UUID);

CREATE POLICY bus_latest_tenant ON bus_latest_locations
  FOR ALL USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::UUID);

CREATE POLICY bus_geofences_tenant ON bus_geofences
  FOR ALL USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::UUID);

CREATE POLICY bus_geofence_events_tenant ON bus_geofence_events
  FOR ALL USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::UUID);

CREATE POLICY bus_trips_tenant ON bus_trips
  FOR ALL USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::UUID);

CREATE POLICY bus_stop_checkins_tenant ON bus_stop_checkins
  FOR ALL USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::UUID);

CREATE POLICY bus_tracking_subs_tenant ON bus_tracking_subscriptions
  FOR ALL USING (tenant_id = (auth.jwt()->'app_metadata'->>'tenant_id')::UUID);

-- Function to upsert latest location on each ping
CREATE OR REPLACE FUNCTION update_bus_latest_location()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO bus_latest_locations (vehicle_id, tenant_id, latitude, longitude, speed_kmh, heading, is_ignition_on, recorded_at, updated_at)
  VALUES (NEW.vehicle_id, NEW.tenant_id, NEW.latitude, NEW.longitude, NEW.speed_kmh, NEW.heading, NEW.is_ignition_on, NEW.recorded_at, now())
  ON CONFLICT (vehicle_id) DO UPDATE SET
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    speed_kmh = EXCLUDED.speed_kmh,
    heading = EXCLUDED.heading,
    is_ignition_on = EXCLUDED.is_ignition_on,
    recorded_at = EXCLUDED.recorded_at,
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bus_latest_location
  AFTER INSERT ON bus_location_pings
  FOR EACH ROW EXECUTE FUNCTION update_bus_latest_location();
