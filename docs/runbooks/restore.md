# Database restore — bring back data from a Supabase snapshot

> Last drilled: **never** (drill before launch — single highest-leverage
> pre-launch task)

## When

- A migration corrupted data and you need a clean copy of yesterday's state.
- An accidental `DELETE FROM …` ran without a WHERE.
- A schema change broke the app and reverting the migration alone isn't enough.
- A regional Supabase outage requires moving to a fresh project.

## Pre-flight — Supabase tier matters

| Plan         | Backups                       | Restore granularity     |
|--------------|-------------------------------|--------------------------|
| **Free**     | Daily snapshots, 7-day retention | Whole project, point-in-time NOT available |
| **Pro ($25)**| Daily snapshots + PITR        | Any second in last 7 days |
| **Team+**    | Same + longer retention       | Any second in last 14 days |

If we're still on Free at the moment of the incident, you get yesterday's
data — work that arrived today is **lost**. Document that clearly to the
affected customers.

## Drill procedure (the only way you'll trust the backup)

Do this once before launch and again after any major schema change.

### Step 1 — Take a snapshot

Supabase Dashboard → Project → Database → Backups → "Create backup now".

### Step 2 — Create a fresh project for the restore target

Dashboard → New project → name `school-management-restore-drill-YYYYMMDD`.
Use a different region from production so you don't accidentally point
the live app at it. Spin-up takes ~2 minutes.

### Step 3 — Download the snapshot

```bash
# Get the snapshot ID from the dashboard or via API:
supabase db dump --linked --db-url "$SOURCE_DB_URL" -f /tmp/snapshot.sql

# Inspect — verify it's not empty and contains tenants table:
grep -c "INSERT INTO public.tenants" /tmp/snapshot.sql
```

### Step 4 — Restore to the drill project

```bash
supabase link --project-ref "$DRILL_PROJECT_REF"
psql "$DRILL_DB_URL" -f /tmp/snapshot.sql
```

### Step 5 — Verify

```sql
-- Tenants count matches production:
SELECT COUNT(*) FROM public.tenants;
-- Newest student created_at matches expected snapshot time (±24h on Free):
SELECT MAX(created_at) FROM public.students;
-- RLS policies are present:
SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public';
```

### Step 6 — Tear down the drill project

Dashboard → Project Settings → General → Delete project.

### Step 7 — Update this doc

Change `Last drilled:` at top to today's date.

## Real incident procedure

Same as drill, but the target project is **the live one** — you point the app
at the restored project by rotating `SUPABASE_URL` in `.env.production` and
shipping a release.

**Critical:** During the restore window, engage the [killswitch](./killswitch.md)
so users see "We're updating" instead of intermittent 500s.

## Common pitfalls

- **You can't restore individual tables on Free tier.** Plan accordingly.
- **Storage objects are NOT in the SQL dump.** Use Supabase Storage's own
  restore for `avatars`, `documents`, etc.
- **Edge function secrets reset on a new project.** Re-set all `supabase
  secrets set` invocations after restore.
- **DNS / OAuth callbacks** point to the old project — update Auth provider
  configs.
