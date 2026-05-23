# Idempotency keys — preventing double-writes on flaky networks

## The problem

Indian school networks are flaky. A teacher taps "Mark Present" — the
request goes out, the server processes it, the response is lost on a
weak Wi-Fi → cellular handoff. The Flutter retry layer sends the same
request again. Without idempotency: two attendance rows, one for each
attempt. Multiplied across 12 roles × 30 students × 60 schools, this
shows up in customer support tickets as "the app is broken."

## The fix (per-write)

Every user-initiated write that could be retried carries a
`client_request_id UUID`. The database has a partial UNIQUE index on
`(tenant_id, client_request_id) WHERE client_request_id IS NOT NULL`.
A duplicate write hits the index and is rejected with `23505 duplicate
key value` — the Flutter retry layer treats that error as success
(the row already exists).

## Tables covered (migration `00063`)

| Table             | Unique on                              |
|-------------------|----------------------------------------|
| `attendance`      | `(tenant_id, client_request_id)`       |
| `messages`        | `(tenant_id, client_request_id)`       |
| `invoices`        | `(tenant_id, client_request_id)`       |
| `payments`        | `(tenant_id, client_request_id)`       |
| `submissions`     | `(student_id, client_request_id)`      |

`submissions` is keyed on `student_id` not `tenant_id` because submissions
don't carry tenant_id directly (joined via assignment).

## How to use it from Flutter

```dart
import 'package:school_management/core/net/idempotency.dart';
import 'package:school_management/core/net/retry.dart';

Future<void> markPresent({...}) async {
  final key = IdempotencyKey.generate(); // one key per user action

  await retryNetwork(
    () => client.from('attendance').insert({
      ...,
      'client_request_id': key,
    }),
    label: 'mark-attendance',
  );
}
```

`retryNetwork` retries transient transport errors with jitter (250 ms,
750 ms, 2 s ±30 %). On 4xx (constraint violation, RLS) it doesn't retry —
the operation already either succeeded (via the UNIQUE index dedup) or
failed for a real reason.

Important detail: `IdempotencyKey.generate()` is called **once per user
action**, not per retry. The retry loop reuses the same key.

## Adding it to a new write path

When you add a new write path that users can retry (any insert from a UI
button), follow this checklist:

- [ ] Decide the dedup scope. Usually `(tenant_id, client_request_id)`. For
      child tables, use the parent's natural scope (e.g. submissions →
      `student_id`).
- [ ] Migration: add `client_request_id UUID` column (nullable) +
      partial UNIQUE index.
- [ ] Flutter repo method: accept `clientRequestId` parameter, pass it in
      the insert payload, set it on the `client_request_id` column.
- [ ] Wrap the call site in `retryNetwork(() => ...)`.
- [ ] If the UI shows a success snackbar, do it on Future complete — not
      optimistically — so the user knows whether the dedup-as-success
      path fired.

## What it does NOT solve

- **Optimistic concurrency.** If two users mark the same attendance
  cell with different values, idempotency keys don't help — last write
  wins. Add an `updated_at` check or row version for genuine merge
  conflicts.
- **Cross-table transactions.** A "send invoice + log audit" pair isn't
  atomic via idempotency keys. Use a stored procedure or a Supabase edge
  function with a transaction.
- **Replays after long delays.** Keys aren't time-bounded. A retried-after-
  3-days request still dedupes; if you actually want a fresh write, the
  user should be prompted to "try again" with a new key.

## Drill

Once before launch, manually:

1. Set the device to airplane mode mid-tap.
2. Re-enable network.
3. Watch the retry fire. Confirm only **one** row landed in the DB.
4. Repeat for each table in the table above.
