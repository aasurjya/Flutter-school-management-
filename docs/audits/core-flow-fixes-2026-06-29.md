# Core-Flow Fixes — First Pass (2026-06-29)

Companion to [`core-flow-ux-audit-2026-06-29.md`](./core-flow-ux-audit-2026-06-29.md).
Scope of this pass: localized, low-risk, compile-verified fixes to the five core
flows. Higher-risk "wire the dead data layer" items are staged as a second pass
(they benefit from running the app).

## Shipped in this pass

### Auth
- **Shared email validator** — new `lib/core/utils/validators.dart`
  (`Validators.isValidEmail`, TLD `{2,}`). Replaced the stale `{2,4}` regex in
  the signup form and the forgot-password dialog (which wrongly rejected
  `.online` / `.education` addresses); routed the main login validator through
  it too. Covered by `test/core/validators_test.dart` (4 tests, incl. the
  TLD regression).
- **`mounted` guards** — forgot-password handler (`login_screen.dart`) now guards
  `setState` after every `await`; splash navigation branches made consistent.
  Forgot-password copy de-jargoned (no "Failed to…").

### Dashboards
- **Student dashboard** — raw `Error loading dashboard: $err` replaced with the
  shared session-aware `AppErrorWidget.fromError(... onRetry:)`, wrapped scrollable
  so pull-to-refresh still works; bare spinner → `LoadingState`.
- **Parent dashboard** — removed the fabricated **"Present at school · Safe arrival
  at 08:14 AM"** safety claim (was derived from the enrollment `is_active` flag +
  a hardcoded time). Now shows a neutral "Today's attendance hasn't synced yet"
  pending state. *(Wiring real per-child attendance = second pass.)*

### Attendance
- **Existing-records cap** — `getAttendanceBySection` `.limit(100)` → `1000` so a
  full roster's saved records always load (the low cap let records beyond 100 get
  silently overwritten to `present`).
- **Pre-submit confirmation** — submitting now shows a present/absent/late summary,
  makes the present-by-default rule explicit, and warns when it will replace
  records already saved for the date. (Undo banner retained as the secondary net.)
- **Unsaved-changes guard** — `PopScope` + discard dialog (uses `WarmCopy.discard*`).
- **Avatar crash** — guarded `studentName.substring(0,1)` against empty names.
- **Tap targets** — status buttons now `Material`+`InkWell`, `minHeight: 48`, with
  `Semantics(button/selected/label)`.

### Fees
- **Charge outstanding, not total** — checkout now uses `invoice.pendingAmount`
  (paying a partially-paid invoice previously over-charged the full original total).
- **Currency** — `$` → `₹` at checkout and on the success receipt (was mismatched
  against the ₹ shown everywhere else).
- **Stale state** — payment-success "Done" now invalidates invoice / summary /
  payments providers so the parent returns to fresh amounts, not a cached "pending".
- **Honesty banner** — the simulated gateway now carries a "Demo checkout — no real
  payment is processed yet…" notice so a fake success can't be mistaken for a charge.

## Verification
- `dart format` + `dart analyze` clean on all 9 touched files (0 errors/warnings).
- `flutter test test/core/validators_test.dart` → 4/4 pass.
- Full `flutter analyze` → 0 errors project-wide (pre-existing info-lints unchanged).

## Deferred — second pass (wire the real data layer; verify in-app)
- **Messaging** — chat detail shows canned messages & Send is "coming soon";
  compose creates nothing; chat list previews/unread always blank; notifications
  tab is a dead placeholder. The `MessageRepository` already works — wire it.
- **Admin dashboard** — mount `MvBackedKpiStrip`/`adminKpisProvider` (finished,
  unwired) over the fabricated metrics; add a real pending-approvals queue.
- **Student weekly attendance calendar** — hardcoded `['P','P','P','A','P','-']`;
  drive from `studentAttendanceProvider`.
- **Teacher/parent dashboard ledgers** — "32/40 graded", "$450 due", "unread note"
  are static; back with real providers.

## Deferred — larger infrastructure
- Real payment gateway SDK (razorpay) + server order-create + `recordPayment`
  reconciliation (removes the demo banner).
- FCM push notifications + automatic parent absence/tardy alerts.
- Biometric unlock / "keep me signed in".
- Move gateway secret/webhook keys server-side (stop `select('*')` to client).
- Self-service signup route decision (screen exists but is unreachable) + invite flow.
- Skeleton/shimmer loaders across lists; tenant-driven currency formatting.
