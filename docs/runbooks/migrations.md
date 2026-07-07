# Migrations — how to ship a schema change without taking the app down

> Read before merging **any** PR that touches `supabase/migrations/`.

## The 90-second rule

If your migration acquires an `ACCESS EXCLUSIVE` lock on a table with more
than ~10 000 rows, every request that touches that table during the lock
fails. That's an outage.

The Squawk linter (`tool/squawk_lint.sh`, runs in CI) catches the most
common offenders. Here's what to do when it flags you.

## Rule cheat-sheet

| Rule                                | What to do instead                                 |
|-------------------------------------|----------------------------------------------------|
| `adding-required-field`             | Add nullable, backfill in a 2nd migration, set NOT NULL in a 3rd. |
| `adding-not-nullable-field`         | Same as above.                                     |
| `changing-column-type`              | Add new column, dual-write, backfill, drop old.    |
| `require-concurrent-index-creation` | `CREATE INDEX CONCURRENTLY …` outside a transaction. |
| `ban-drop-column`                   | Mark unused; drop in a 2nd PR ≥ 1 week later.      |
| `renaming-column` / `renaming-table`| Add new + view, dual-write, drop old later.        |
| `prefer-bigint-over-int`            | Use `BIGINT`/`BIGSERIAL` for new PKs.              |

## The 3-step pattern for "I really need to add NOT NULL"

```sql
-- Migration 00099_add_status_step1.sql — add nullable
ALTER TABLE public.foo ADD COLUMN IF NOT EXISTS status TEXT;

-- ... ship & deploy app to write the column ...

-- Migration 00100_add_status_step2_backfill.sql — fill historic rows
UPDATE public.foo SET status = 'legacy' WHERE status IS NULL;

-- Migration 00101_add_status_step3_notnull.sql — enforce
ALTER TABLE public.foo ALTER COLUMN status SET NOT NULL;
```

Each step is a separate PR. Step 3 happens **after** step 1 has been live
for at least one app release.

## Conditional install (when prerequisites might not exist)

When a migration depends on a table that's in a parked / disabled migration,
wrap it in a DO block that checks `information_schema`. Pattern:

```sql
DO $do$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema='public' AND table_name='dependency_table')
  THEN
    RAISE NOTICE 'dependency_table missing; skipping install';
    RETURN;
  END IF;

  EXECUTE $func$
    CREATE OR REPLACE FUNCTION ... AS $body$ ... $body$;
  $func$;
END
$do$;
```

Note: distinct dollar-quote tags (`$do$`, `$func$`, `$body$`) avoid parser
confusion when nesting CREATE FUNCTION inside DO.

## Pre-merge checklist

- [ ] `bash tool/squawk_lint.sh` clean (CI will run this too).
- [ ] Migration has a comment header describing **why**, not just **what**.
- [ ] Indexes use `CREATE INDEX IF NOT EXISTS` + `CONCURRENTLY` (unless
      table is empty pre-launch).
- [ ] RLS policies on new tables added in the same migration, not a follow-up.
- [ ] If the migration depends on extension functions, the extension
      `CREATE EXTENSION IF NOT EXISTS …` is in the migration too.
- [ ] Reversible: a brief comment explaining how to roll back (don't write a
      down-migration; just describe the rollback in prose).

## When Squawk blocks you and you're sure it's safe

**Correction (2026-07-08):** this doc previously suggested an inline
`-- squawk-ignore-next-statement: <rule>` comment. That syntax doesn't
exist. Squawk's real inline syntax is `-- squawk-ignore <rule>` (no colon,
no "-next-statement"), documented at squawkhq.com/docs/cli — but even that
did not suppress a warning in local testing against squawk-cli 1.5.4
(tested against `adding-field-with-default` on migrations 00068/00072).
Don't spend time re-trying inline-comment variants; use one of the two
options below instead.

**For a rule that's a genuine false positive for this codebase** (not just
this one migration): add it to the `EXCLUDE` list in `tool/squawk_lint.sh`,
with a comment explaining why, following the existing `prefer-big-int` /
`adding-field-with-default` entries as examples. This is a project-wide
policy change — get it reviewed, don't add it solo in a PR that also needs
the exclude to pass its own CI check.

**For a rule that's flagging a real risk you're accepting knowingly, just
this once:** there's no working per-statement ignore. Get explicit sign-off
in the PR description on why this specific instance is safe, and merge with
the risk documented — don't add it to squawk_lint.sh's EXCLUDE (that would
silence the rule for every future migration, not just this one).
