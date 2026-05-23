# Runbooks

Concrete, step-by-step procedures for things that go wrong (or need a careful
human in the loop) in production. Read these BEFORE you need them — at 2 AM
during an incident is not the time to figure out the restore process.

| Runbook                             | When to read it                                      |
|-------------------------------------|------------------------------------------------------|
| [restore.md](./restore.md)          | Database is corrupted / a bad migration shipped.     |
| [killswitch.md](./killswitch.md)    | Need to take the app offline without a release.      |
| [migrations.md](./migrations.md)    | About to merge a schema change. Always.              |
| [feature-flags.md](./feature-flags.md) | Need to dark-launch / staged-rollout / disable a feature. |
| [idempotency.md](./idempotency.md)  | Adding a new write path that users can retry.        |

## Conventions

- Every runbook starts with a **"When"** section (the trigger).
- Every step is a literal command you can copy-paste.
- Every runbook ends with a **"Drill"** section — instructions for periodically
  practicing the procedure on staging so it works at 2 AM.
- Updates to a runbook should bump a `Last drilled: YYYY-MM-DD` line in the
  doc. If that date is more than 90 days old, the procedure is **assumed
  broken** until re-drilled.
