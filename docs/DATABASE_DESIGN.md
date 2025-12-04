# School Management SaaS - Multi-Tenant Database Design

## Table of Contents
1. [Tenancy Model Selection](#1-tenancy-model-selection)
2. [Core Schema Design](#2-core-schema-design)
3. [Multi-Tenant Access & RLS Strategy](#3-multi-tenant-access--rls-strategy)
4. [Scaling & Performance Best Practices](#4-scaling--performance-best-practices)
5. [Auditing, Soft Delete & Safety](#5-auditing-soft-delete--safety)
6. [End-to-End Example](#6-end-to-end-example)

---

## 1. Tenancy Model Selection

### Comparison of Tenancy Models

| Model | Isolation | Cost | Migrations | Scaling | Use Case |
|-------|-----------|------|------------|---------|----------|
| **Database-per-tenant** | Highest | High (separate DB per school) | Complex (run on each DB) | Limited by DB count | Highly regulated, enterprise |
| **Schema-per-tenant** | High | Medium | Medium (per-schema) | ~10K tenants max | Mid-market, some customization |
| **Shared DB + tenant_id** | Logical | Lowest | Simple (single migration) | Millions of rows | SaaS, uniform features |

### Chosen Model: **Shared Database, Shared Schema, Row-Level Tenancy**

For a School Management SaaS targeting hundreds to thousands of schools with identical features, we use:

- **Single PostgreSQL database**
- **Single `public` schema** (all tenants share tables)
- **`tenant_id` column** on every tenant-scoped table
- **Row-Level Security (RLS)** for isolation

### Justification

| Factor | Why Shared Schema Wins |
|--------|------------------------|
| **Cost** | One database = one connection pool, one backup, one monitoring stack |
| **Migrations** | Single migration applies to all tenants instantly |
| **Onboarding** | New school = INSERT into `tenants`, no infrastructure provisioning |
| **Query Simplicity** | All data in one place; cross-tenant analytics possible for super_admin |
| **Horizontal Scaling** | Read replicas, connection pooling, partitioning all work naturally |

### Trade-offs & Mitigations

| Concern | Mitigation |
|---------|------------|
| **Noisy neighbor** | Rate limiting, query timeouts, resource quotas per tenant |
| **Data leak risk** | RLS + tenant_id in every query + automated tests |
| **Customization** | JSONB `settings` column on `tenants` for per-school config |
| **Compliance** | Audit logs, soft-delete, data export capabilities |

---

## 2. Core Schema Design

### 2.1 Table Categories

| Category | Tables | Has tenant_id? |
|----------|--------|----------------|
| **Global** | (none currently; could add `global_config`, `feature_flags`) | No |
| **Platform** | `tenants` | No (IS the tenant) |
| **Tenant-Scoped** | All others | Yes |

### 2.2 Naming Conventions

- **Tables**: lowercase, plural, snake_case (`students`, `exam_subjects`)
- **Columns**: lowercase, snake_case (`tenant_id`, `created_at`)
- **Primary Keys**: `id UUID DEFAULT gen_random_uuid()`
- **Foreign Keys**: `<table_singular>_id` (e.g., `student_id`, `section_id`)
- **Timestamps**: `created_at`, `updated_at` (TIMESTAMPTZ)
- **Soft Delete**: `is_deleted BOOLEAN DEFAULT false` or `deleted_at TIMESTAMPTZ`

### 2.3 Core Tables Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         CORE LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  tenants ──┬── users ──── user_roles                            │
│            │                                                    │
│            ├── academic_years ── terms                          │
│            │                                                    │
│            ├── classes ── sections ── class_subjects            │
│            │                                                    │
│            ├── subjects ── teacher_assignments                  │
│            │                                                    │
│            ├── students ── student_enrollments                  │
│            │           └── student_parents ── parents           │
│            │                                                    │
│            └── staff                                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      ACADEMIC LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│  timetable_slots ── timetables                                  │
│  attendance ── period_attendance                                │
│  exams ── exam_subjects ── marks ── exam_statistics             │
│  assignments ── submissions                                     │
│  grade_scales ── grade_scale_items                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      OPERATIONS LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│  fee_heads ── fee_structures ── invoices ── invoice_items       │
│                                         └── payments            │
│  canteen_menu ── canteen_orders ── canteen_order_items          │
│  wallets ── wallet_transactions                                 │
│  library_books ── book_issues                                   │
│  transport_routes ── transport_stops ── student_transport       │
│  hostels ── hostel_rooms ── room_allocations                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    COMMUNICATION LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│  threads ── thread_participants ── messages                     │
│  announcements                                                  │
│  calendar_events                                                │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4 Key Table Definitions

#### Tenants (Schools)
```sql
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,        -- URL-safe identifier
    logo_url TEXT,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'India',
    timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
    currency VARCHAR(3) DEFAULT 'INR',
    settings JSONB DEFAULT '{}',              -- Per-school config
    subscription_plan VARCHAR(50) DEFAULT 'free',
    subscription_expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- No tenant_id here - this IS the tenant
```

#### Users (Platform Profiles)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id),    -- Can be NULL for super_admin
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    phone VARCHAR(20),
    avatar_url TEXT,
    date_of_birth DATE,
    gender VARCHAR(20),
    address TEXT,
    fcm_token TEXT,                           -- Push notifications
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email);
```

#### User Roles (Multi-Tenant Role Assignment)
```sql
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    role user_role NOT NULL,                  -- ENUM type
    permissions JSONB DEFAULT '[]',           -- Fine-grained overrides
    is_primary BOOLEAN DEFAULT false,         -- Default role for this user
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, tenant_id, role)          -- One role per user per tenant
);

CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_tenant ON user_roles(tenant_id);
CREATE INDEX idx_user_roles_lookup ON user_roles(user_id, tenant_id);
```

#### Students
```sql
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),        -- Links to auth (optional for young kids)
    admission_number VARCHAR(50) NOT NULL,
    roll_number VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20),
    blood_group VARCHAR(5),
    photo_url TEXT,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    medical_conditions TEXT,
    admission_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_students_tenant ON students(tenant_id);
CREATE UNIQUE INDEX idx_students_admission ON students(tenant_id, admission_number);
CREATE INDEX idx_students_user ON students(user_id) WHERE user_id IS NOT NULL;
```

#### Marks (High-Volume Table)
```sql
CREATE TABLE marks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    exam_subject_id UUID NOT NULL REFERENCES exam_subjects(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    marks_obtained DECIMAL(5,2),
    grade VARCHAR(5),
    remarks TEXT,
    is_absent BOOLEAN DEFAULT false,
    marked_by UUID REFERENCES users(id),
    marked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(exam_subject_id, student_id)
);

-- Critical indexes for marks queries
CREATE INDEX idx_marks_tenant ON marks(tenant_id);
CREATE INDEX idx_marks_student ON marks(tenant_id, student_id);
CREATE INDEX idx_marks_exam_subject ON marks(tenant_id, exam_subject_id);
CREATE INDEX idx_marks_lookup ON marks(tenant_id, exam_subject_id, student_id);
```

#### Attendance (High-Volume Table)
```sql
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status attendance_status NOT NULL,
    remarks TEXT,
    marked_by UUID REFERENCES users(id),
    marked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, date)                  -- One attendance per student per day
);

-- Critical indexes for attendance queries
CREATE INDEX idx_attendance_tenant ON attendance(tenant_id);
CREATE INDEX idx_attendance_student_date ON attendance(tenant_id, student_id, date);
CREATE INDEX idx_attendance_section_date ON attendance(tenant_id, section_id, date);
CREATE INDEX idx_attendance_date ON attendance(tenant_id, date);
```

### 2.5 Recommended Composite Indexes

```sql
-- For dashboard queries
CREATE INDEX idx_attendance_section_date_status 
    ON attendance(tenant_id, section_id, date, status);

-- For report cards
CREATE INDEX idx_marks_student_exam 
    ON marks(tenant_id, student_id, exam_subject_id);

-- For fee collection reports
CREATE INDEX idx_invoices_tenant_status_due 
    ON invoices(tenant_id, status, due_date);

-- For parent lookups
CREATE INDEX idx_student_parents_parent 
    ON student_parents(parent_id);
```

---

## 3. Multi-Tenant Access & RLS Strategy

### 3.1 JWT Claims Structure

The Supabase JWT should contain:
```json
{
  "sub": "user-uuid",
  "email": "teacher@school.app",
  "app_metadata": {
    "tenant_id": "school-uuid",
    "roles": ["teacher"]
  }
}
```

### 3.2 Helper Functions

```sql
-- Get current tenant from JWT
CREATE OR REPLACE FUNCTION auth.tenant_id()
RETURNS UUID AS $$
BEGIN
  RETURN COALESCE(
    (current_setting('request.jwt.claims', true)::json
      ->'app_metadata'->>'tenant_id')::UUID,
    '00000000-0000-0000-0000-000000000000'::UUID
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN '00000000-0000-0000-0000-000000000000'::UUID;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user has a specific role
CREATE OR REPLACE FUNCTION auth.has_role(required_role user_role)
RETURNS BOOLEAN AS $$
DECLARE
  roles JSONB;
BEGIN
  roles := (current_setting('request.jwt.claims', true)::json
    ->'app_metadata'->'roles')::JSONB;
  RETURN roles ? required_role::TEXT;
EXCEPTION
  WHEN OTHERS THEN
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is admin
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN auth.has_role('tenant_admin') 
      OR auth.has_role('principal') 
      OR auth.has_role('super_admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get current user's student IDs (for parent access)
CREATE OR REPLACE FUNCTION auth.my_student_ids()
RETURNS SETOF UUID AS $$
BEGIN
  -- If user is a student, return their student record
  RETURN QUERY 
    SELECT id FROM students WHERE user_id = auth.uid();
  
  -- If user is a parent, return their children
  RETURN QUERY
    SELECT sp.student_id 
    FROM student_parents sp
    JOIN parents p ON sp.parent_id = p.id
    WHERE p.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3.3 RLS Policy Patterns

#### Pattern 1: Basic Tenant Isolation
```sql
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

-- All authenticated users in tenant can read
CREATE POLICY "tenant_isolation_select" ON classes
FOR SELECT USING (tenant_id = auth.tenant_id());

-- Only admins can modify
CREATE POLICY "admin_manage" ON classes
FOR ALL USING (tenant_id = auth.tenant_id() AND auth.is_admin());
```

#### Pattern 2: Role-Based Access (Teachers)
```sql
-- Teachers see only classes they're assigned to
CREATE POLICY "teacher_view_assigned_sections" ON sections
FOR SELECT USING (
  tenant_id = auth.tenant_id() AND (
    auth.is_admin() OR
    id IN (
      SELECT section_id FROM teacher_assignments
      WHERE teacher_id = (SELECT id FROM staff WHERE user_id = auth.uid())
    )
  )
);
```

#### Pattern 3: Hierarchical Access (Students/Parents)
```sql
-- Students see only their own marks
-- Parents see only their children's marks
CREATE POLICY "view_marks" ON marks
FOR SELECT USING (
  tenant_id = auth.tenant_id() AND (
    auth.is_admin() OR
    auth.has_role('teacher') OR
    student_id IN (SELECT auth.my_student_ids())
  )
);
```

#### Pattern 4: Ownership-Based Access (Messaging)
```sql
CREATE POLICY "view_own_threads" ON threads
FOR SELECT USING (
  tenant_id = auth.tenant_id() AND (
    created_by = auth.uid() OR
    id IN (SELECT thread_id FROM thread_participants WHERE user_id = auth.uid())
  )
);
```

### 3.4 Role-Based Access Matrix

| Resource | super_admin | tenant_admin | teacher | parent | student |
|----------|-------------|--------------|---------|--------|---------|
| tenants | CRUD | R (own) | - | - | - |
| users | CRUD | CRUD (own tenant) | R | R (limited) | R (self) |
| classes | CRUD | CRUD | R | R | R |
| students | CRUD | CRUD | R (assigned) | R (children) | R (self) |
| marks | CRUD | CRUD | CRUD (assigned) | R (children) | R (self) |
| attendance | CRUD | CRUD | CRUD (assigned) | R (children) | R (self) |
| invoices | CRUD | CRUD | - | R (children) | R (self) |

### 3.5 Setting Tenant Context

**Option A: Via Supabase JWT (Recommended)**
```dart
// Flutter: Set tenant_id in user metadata during login
await supabase.auth.updateUser(
  UserAttributes(data: {'tenant_id': selectedTenantId}),
);
```

**Option B: Via Database Session Variable**
```sql
-- Set at connection start (e.g., from Edge Function)
SET app.tenant_id = 'school-uuid';

-- Use in RLS
USING (tenant_id = current_setting('app.tenant_id')::uuid)
```

### 3.6 Avoiding Tenant Leaks

1. **Always include tenant_id in WHERE clauses** (even with RLS as defense-in-depth)
2. **Use parameterized queries** – never concatenate tenant_id
3. **Automated tests**: Query each table with wrong tenant JWT, expect 0 rows
4. **Code review checklist**: Every new query must filter by tenant_id
5. **Database triggers**: Reject INSERTs where tenant_id doesn't match JWT

```sql
-- Trigger to enforce tenant_id on insert
CREATE OR REPLACE FUNCTION enforce_tenant_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.tenant_id != auth.tenant_id() THEN
    RAISE EXCEPTION 'tenant_id mismatch';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_tenant_id_students
  BEFORE INSERT ON students
  FOR EACH ROW EXECUTE FUNCTION enforce_tenant_id();
```

---

## 4. Scaling & Performance Best Practices

### 4.1 Indexing Strategy

```sql
-- Rule 1: Always index tenant_id
CREATE INDEX idx_<table>_tenant ON <table>(tenant_id);

-- Rule 2: Composite indexes for common queries
CREATE INDEX idx_attendance_tenant_date ON attendance(tenant_id, date);
CREATE INDEX idx_marks_tenant_student ON marks(tenant_id, student_id);
CREATE INDEX idx_invoices_tenant_status ON invoices(tenant_id, status);

-- Rule 3: Partial indexes for hot paths
CREATE INDEX idx_active_students ON students(tenant_id) 
  WHERE is_active = true;

CREATE INDEX idx_unpaid_invoices ON invoices(tenant_id, due_date) 
  WHERE status IN ('pending', 'overdue');
```

### 4.2 Partitioning High-Volume Tables

For tables that grow unbounded (attendance, marks, wallet_transactions):

```sql
-- Partition attendance by month
CREATE TABLE attendance (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    student_id UUID NOT NULL,
    date DATE NOT NULL,
    status attendance_status NOT NULL,
    -- ... other columns
    PRIMARY KEY (id, date)
) PARTITION BY RANGE (date);

-- Create monthly partitions
CREATE TABLE attendance_2024_01 PARTITION OF attendance
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE attendance_2024_02 PARTITION OF attendance
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
-- ... etc

-- Automate partition creation with pg_partman extension
```

**When to partition:**
- Table exceeds 10M rows
- Queries mostly filter by date range
- Old data can be archived/dropped by partition

### 4.3 Query Patterns

```sql
-- GOOD: tenant_id first, indexed columns, limited results
SELECT id, first_name, last_name, admission_number
FROM students
WHERE tenant_id = $1 
  AND is_active = true
  AND class_id = $2
ORDER BY last_name
LIMIT 50 OFFSET 0;

-- BAD: No tenant_id, SELECT *, no pagination
SELECT * FROM students WHERE class_id = $1;
```

**Rules:**
1. Always filter by `tenant_id` first
2. Avoid `SELECT *` – list only needed columns
3. Use pagination (`LIMIT`/`OFFSET` or cursor-based)
4. Use `EXPLAIN ANALYZE` to verify index usage

### 4.4 Connection Pooling

With Supabase, use **PgBouncer** (built-in):
- Transaction mode for short-lived queries
- Session mode only if using prepared statements
- Monitor active connections per tenant

```
# supabase/config.toml
[db.pooler]
enabled = true
port = 6543
pool_mode = "transaction"
default_pool_size = 20
max_client_conn = 200
```

### 4.5 Caching Strategy

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│   Supabase      │────▶│   PostgreSQL    │
│                 │     │   + PostgREST   │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │
        ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│  Local Cache    │     │  Redis/KV       │
│  (Hive/Isar)    │     │  (Edge Cache)   │
└─────────────────┘     └─────────────────┘
```

- **App-level**: Cache static data (classes, subjects) locally
- **Edge-level**: Cache frequently-read, rarely-changed data
- **Invalidation**: Use Supabase Realtime to push changes

---

## 5. Auditing, Soft Delete & Safety

### 5.1 Common Audit Columns

Add to all tenant-scoped tables:
```sql
-- Timestamps
created_at TIMESTAMPTZ DEFAULT NOW(),
updated_at TIMESTAMPTZ DEFAULT NOW(),

-- User tracking
created_by UUID REFERENCES users(id),
updated_by UUID REFERENCES users(id),

-- Soft delete (choose one)
is_deleted BOOLEAN DEFAULT false,
-- OR
deleted_at TIMESTAMPTZ,
deleted_by UUID REFERENCES users(id)
```

### 5.2 Auto-Update Trigger

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON students
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### 5.3 Audit Log Table

```sql
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    user_id UUID REFERENCES users(id),
    entity VARCHAR(100) NOT NULL,           -- 'students', 'marks', etc.
    entity_id UUID NOT NULL,
    action VARCHAR(20) NOT NULL,            -- 'INSERT', 'UPDATE', 'DELETE'
    old_data JSONB,
    new_data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_tenant ON audit_log(tenant_id);
CREATE INDEX idx_audit_entity ON audit_log(tenant_id, entity, entity_id);
CREATE INDEX idx_audit_user ON audit_log(tenant_id, user_id);
CREATE INDEX idx_audit_date ON audit_log(tenant_id, created_at);
```

### 5.4 Audit Trigger

```sql
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log (tenant_id, user_id, entity, entity_id, action, new_data)
    VALUES (NEW.tenant_id, auth.uid(), TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW));
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log (tenant_id, user_id, entity, entity_id, action, old_data, new_data)
    VALUES (NEW.tenant_id, auth.uid(), TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log (tenant_id, user_id, entity, entity_id, action, old_data)
    VALUES (OLD.tenant_id, auth.uid(), TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD));
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply to sensitive tables
CREATE TRIGGER audit_students
  AFTER INSERT OR UPDATE OR DELETE ON students
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();

CREATE TRIGGER audit_marks
  AFTER INSERT OR UPDATE OR DELETE ON marks
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

### 5.5 Soft Delete Strategy

| Entity | Strategy | Reason |
|--------|----------|--------|
| **Tenants** | Soft delete + archive after 90 days | Legal/billing records |
| **Students** | Soft delete | Alumni records, transcripts |
| **Marks/Attendance** | Never delete | Academic integrity |
| **Messages** | Soft delete | Legal compliance |
| **Canteen orders** | Hard delete after 1 year | No long-term value |

```sql
-- Soft delete query pattern
UPDATE students 
SET is_deleted = true, deleted_at = NOW(), deleted_by = auth.uid()
WHERE id = $1 AND tenant_id = auth.tenant_id();

-- Exclude deleted in queries
CREATE POLICY "hide_deleted" ON students
FOR SELECT USING (
  tenant_id = auth.tenant_id() AND 
  (is_deleted = false OR auth.is_admin())  -- Admins can see deleted
);
```

---

## 6. End-to-End Example

### Scenario: New School Onboarding & First Exam Entry

#### Step 1: School Signs Up

```sql
-- 1. Create tenant
INSERT INTO tenants (name, slug, email, phone)
VALUES ('Delhi Public School', 'dps-delhi', 'admin@dps.edu', '9876543210')
RETURNING id;
-- Returns: tenant_id = 'a1b2c3d4-...'
```

#### Step 2: Admin Invited

```sql
-- 2a. Create auth user (via Supabase Auth API)
-- Returns: auth_user_id = 'e5f6g7h8-...'

-- 2b. Create user profile
INSERT INTO users (id, tenant_id, email, full_name)
VALUES ('e5f6g7h8-...', 'a1b2c3d4-...', 'admin@dps.edu', 'Rajesh Kumar');

-- 2c. Assign admin role
INSERT INTO user_roles (user_id, tenant_id, role, is_primary)
VALUES ('e5f6g7h8-...', 'a1b2c3d4-...', 'tenant_admin', true);

-- 2d. Update JWT metadata (via Supabase Admin API)
-- Set app_metadata: { tenant_id: 'a1b2c3d4-...', roles: ['tenant_admin'] }
```

#### Step 3: Admin Creates Academic Structure

```sql
-- JWT now contains tenant_id, RLS enforces isolation

-- 3a. Academic year
INSERT INTO academic_years (tenant_id, name, start_date, end_date, is_current)
VALUES (auth.tenant_id(), '2024-25', '2024-04-01', '2025-03-31', true);

-- 3b. Class
INSERT INTO classes (tenant_id, name, numeric_name, sequence_order)
VALUES (auth.tenant_id(), 'Class 10', 10, 10);

-- 3c. Section
INSERT INTO sections (tenant_id, class_id, academic_year_id, name, capacity)
VALUES (auth.tenant_id(), $class_id, $academic_year_id, 'A', 40);

-- 3d. Subject
INSERT INTO subjects (tenant_id, name, code)
VALUES (auth.tenant_id(), 'Mathematics', 'MATH');
```

#### Step 4: Admin Adds Students

```sql
INSERT INTO students (tenant_id, admission_number, first_name, last_name, date_of_birth, admission_date)
VALUES 
  (auth.tenant_id(), 'DPS2024001', 'Aarav', 'Sharma', '2009-05-15', '2024-04-01'),
  (auth.tenant_id(), 'DPS2024002', 'Priya', 'Singh', '2009-08-22', '2024-04-01');

INSERT INTO student_enrollments (tenant_id, student_id, section_id, academic_year_id, roll_number)
VALUES 
  (auth.tenant_id(), $student1_id, $section_id, $ay_id, '1'),
  (auth.tenant_id(), $student2_id, $section_id, $ay_id, '2');
```

#### Step 5: Teacher Records Exam Marks

```sql
-- Teacher logs in, JWT contains: { tenant_id: 'a1b2c3d4-...', roles: ['teacher'] }

-- 5a. Create exam (admin)
INSERT INTO exams (tenant_id, academic_year_id, term_id, name, exam_type, start_date, end_date)
VALUES (auth.tenant_id(), $ay_id, $term_id, 'Mid-Term 2024', 'mid_term', '2024-09-15', '2024-09-25');

-- 5b. Create exam subject
INSERT INTO exam_subjects (tenant_id, exam_id, subject_id, section_id, max_marks, passing_marks, exam_date)
VALUES (auth.tenant_id(), $exam_id, $math_id, $section_id, 100, 35, '2024-09-16');

-- 5c. Teacher enters marks
INSERT INTO marks (tenant_id, exam_subject_id, student_id, marks_obtained, marked_by)
VALUES 
  (auth.tenant_id(), $exam_subject_id, $student1_id, 85, auth.uid()),
  (auth.tenant_id(), $exam_subject_id, $student2_id, 92, auth.uid());
```

#### Step 6: RLS Verification Queries

```sql
-- Parent logs in (linked to Aarav only)
-- JWT: { tenant_id: 'a1b2c3d4-...', roles: ['parent'] }

-- Query 1: Parent sees only their child's marks
SELECT s.first_name, m.marks_obtained, es.max_marks
FROM marks m
JOIN students s ON m.student_id = s.id
JOIN exam_subjects es ON m.exam_subject_id = es.id
WHERE m.tenant_id = auth.tenant_id();
-- Returns: Aarav, 85, 100 (only their child)

-- Query 2: Parent can see class topper for comparison (anonymized)
SELECT 
  MAX(marks_obtained) as class_topper,
  AVG(marks_obtained) as class_average,
  (SELECT marks_obtained FROM marks WHERE student_id IN (SELECT auth.my_student_ids())) as my_child
FROM marks m
WHERE exam_subject_id = $exam_subject_id;
-- Returns: 92, 88.5, 85 (topper/avg without revealing identity)
```

#### Step 7: Cross-Tenant Isolation Test

```sql
-- Different school tries to access DPS data
-- JWT: { tenant_id: 'other-school-id', roles: ['tenant_admin'] }

SELECT * FROM students WHERE tenant_id = 'a1b2c3d4-...';
-- Returns: 0 rows (RLS blocks access)

SELECT * FROM students;  -- Without explicit tenant_id filter
-- Returns: only students from 'other-school-id' (RLS auto-filters)
```

---

## Summary

This design provides:
- **Cost efficiency**: Single database for all schools
- **Strong isolation**: RLS + tenant_id on every query
- **Role-based access**: Fine-grained policies for admin/teacher/parent/student
- **Scalability**: Composite indexes, optional partitioning, connection pooling
- **Auditability**: Timestamps, user tracking, audit log
- **Safety**: Soft delete, trigger enforcement, automated tests

The existing migrations in `supabase/migrations/` implement this architecture. Run `supabase db push` to deploy them to your project.
