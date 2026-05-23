# Killswitch — Take the app offline without a release

> Last drilled: **never** (drill before launch)

## When

- A critical bug is in production and Shorebird isn't wired yet, OR
- You're doing a database migration that will take >30 s, OR
- Supabase is having an incident and the app's degraded behaviour is worse
  than the maintenance screen.

## Pre-flight

The killswitch is a single Supabase row read by every client on app boot.
A failed/slow read falls through to "off" — so a network split between the
client and Supabase will **not** trigger the maintenance screen. This is by
design: a server-side cause for the outage means clients couldn't have
phoned home anyway.

## Engage (the "oh no" step)

```sql
-- One row, one flag. Pick a message that's specific:
UPDATE app_killswitch
SET enabled = true,
    message = 'Brief maintenance — back in ~10 minutes. Apologies.'
WHERE key = 'maintenance';
```

Already-running app sessions will NOT see the killswitch until they relaunch.
This is fine for our use case (you flip the switch before pushing the broken
release; users who haven't updated yet keep working).

## Disengage

```sql
UPDATE app_killswitch
SET enabled = false,
    message = ''
WHERE key = 'maintenance';
```

## Verify

After engaging, do a hard-restart on a test device (kill the app from
recents, reopen). Expect:
- White flash for ~1 s (Supabase init).
- Maintenance screen with your message.
- No further network calls (charles/proxy will confirm).

## Drill — quarterly

1. On staging, engage the killswitch with message `DRILL — ignore`.
2. Verify the maintenance screen renders on a staging build.
3. Disengage.
4. Update `Last drilled:` at top of this file.

## Common pitfalls

- **Anonymous read must succeed.** RLS policy is `USING (true)` — don't
  tighten it.
- **Don't add a `tenant_id` column.** Killswitch is global; per-tenant
  outages belong in `feature_flags`.
- **Maintenance screen renders before Sentry init.** Errors in maintenance
  screen rendering are uncaught — keep it minimal.
