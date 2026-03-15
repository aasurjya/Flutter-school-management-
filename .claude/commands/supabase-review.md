---
description: Review Supabase migrations and queries for tenant_id, RLS policies, idempotency, and missing indexes
---

# Supabase Review

Invoke the `database-reviewer` agent to check Supabase migrations and queries for school-management-specific issues.

## Usage

```text
/supabase-review
/supabase-review <migration-file>
/supabase-review supabase/migrations/20260313_add_hostel.sql
```

## What This Checks

### 1. Migration Safety

```bash
# List all migrations
supabase migration list

# Check migration file exists and is idempotent
cat <migration-file>
```

**Migration checklist:**
- [ ] Uses `IF NOT EXISTS` for table creation
- [ ] Uses `IF NOT EXISTS` for index creation
- [ ] Has both `UP` logic (idempotent)
- [ ] No `DROP TABLE` without backup strategy
- [ ] No `ALTER TABLE` that removes required columns

### 2. Tenant Isolation (CRITICAL)

Every table accessed by tenants MUST have:

```sql
-- REQUIRED on every tenant-scoped table
ALTER TABLE public.my_table ENABLE ROW LEVEL SECURITY;

-- REQUIRED RLS policy
CREATE POLICY "tenant_isolation" ON public.my_table
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- REQUIRED: tenant_id column
ALTER TABLE public.my_table ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
```

**Check:** Does the migration add `tenant_id` to all new tables? Does it enable RLS?

### 3. Missing Indexes

Common missing indexes in this codebase (from CLAUDE.md):

```sql
-- Student name search (missing)
CREATE INDEX IF NOT EXISTS idx_students_name ON students(tenant_id, first_name, last_name);

-- Message sender (missing)
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(thread_id, sender_id);

-- Invoice due date (missing)
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(tenant_id, due_date);
```

**Check every new query:** Is there an index supporting the WHERE clause?

### 4. Super Admin JWT Safety

```sql
-- super_admin has no tenant_id in JWT — RLS policies must handle NULL
-- BAD policy (crashes for super_admin):
USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)

-- GOOD policy (handles super_admin):
USING (
  tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
  OR auth.jwt() -> 'app_metadata' ->> 'role' = 'super_admin'
)
```

### 5. Known Race Conditions

```sql
-- wallet.balance race condition — use atomic update
-- BAD (race condition):
UPDATE wallets SET balance = balance + amount WHERE id = wallet_id;

-- GOOD (check trigger or use atomic RPC):
-- Use a stored procedure/RPC for wallet operations
```

### 6. Duplicate Invoice Protection

```sql
-- generate_class_invoices() has no duplicate check
-- Add unique constraint or check:
CREATE UNIQUE INDEX IF NOT EXISTS idx_invoices_unique
  ON invoices(tenant_id, student_id, fee_period, academic_year_id);
```

## Steps

### Step 1: Identify Changed Migrations

```bash
git diff --name-only HEAD~1 HEAD | grep "supabase/migrations"
# Or for staged changes:
git diff --cached --name-only | grep "supabase/migrations"
```

### Step 2: Run Database Reviewer

Invoke the `database-reviewer` agent with this context:

**Schema context:**
- Multi-tenant SaaS: every table needs `tenant_id` + RLS
- super_admin has no `tenant_id` in JWT `app_metadata`
- Known issues: wallet race conditions, hostel room counter desync, invoice duplicate generation

**Review each migration for:**
1. `tenant_id` column on all new tables
2. `ENABLE ROW LEVEL SECURITY` on all new tables
3. RLS policies that handle super_admin (null tenant_id)
4. Indexes for all new query patterns
5. Idempotency (`IF NOT EXISTS` everywhere)
6. Reversibility (is there a way back?)

### Step 3: Check Flutter Repository Code

For each new migration, check the corresponding repository:

```bash
# Find repository files that query the new table
grep -rn "from('<table_name>')" lib/ --include="*.dart"
```

Verify:
- `.eq('tenant_id', tenantId)` on every query
- Pagination: `.range(offset, limit)` on list queries
- No N+1: use joins, not loops

## Output Format

```markdown
## Supabase Review: <migration-name>

### Verdict: APPROVED | NEEDS_REVISION

### Tenant Isolation
- [x] tenant_id column present
- [x] RLS enabled
- [x] RLS policy handles super_admin
- [ ] **MISSING**: Policy doesn't handle null tenant_id for super_admin

### Indexes
- [x] Primary key index
- [ ] **MISSING**: Index on (tenant_id, student_id) for frequent query pattern

### Idempotency
- [x] IF NOT EXISTS on table creation
- [x] IF NOT EXISTS on indexes

### Known Issues
- [ ] **CHECK**: wallet balance update — is this atomic?

### Flutter Repository Check
- [x] .eq('tenant_id', tenantId) present in all queries
- [x] Pagination with .range() on list endpoints
- [ ] **MISSING**: N+1 pattern in student list — loads parents in a loop

### Recommendations
1. Add RLS policy for super_admin
2. Add index on (tenant_id, created_at) for common sort pattern
3. Use JOIN instead of loop for parent loading
```
