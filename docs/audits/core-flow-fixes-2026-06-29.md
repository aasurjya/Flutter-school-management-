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

## Second pass — shipped (wire the real data layer)

Analyze-clean; UI wiring is best verified in-app (no runtime test run here).

- **Admin dashboard KPIs** — replaced the fabricated `_InstitutionPulseGrid`
  (hardcoded 94.2% / "2 on leave") with `MvBackedKpiStrip`, which reads the real
  `adminKpisProvider` (`v_my_admin_kpis`) and auto-hides pre-migration. Deleted
  the dead grid classes; `onRefresh` now invalidates `adminKpisProvider`.
- **Admin approval queue** — `_PrincipalApprovalQueue` rewired from invented
  "Mrs. Barua" rows to real pending leave requests
  (`leaveApplicationsProvider(LeaveFilter(pendingOnly: true))`) with
  loading / empty ("All caught up") / error states and a "View all N" overflow.
- **Student weekly attendance calendar** — replaced hardcoded
  `['P','P','P','A','P','-']` with the real current-week strip derived from
  `studentAttendanceProvider`; "today" is computed from the date, future days
  and no-record days show an em-dash; late/half-day/excused now render distinctly.
- **Messaging chat detail** — `_ChatDetailScreen` rebuilt as a stateful consumer
  bound to the real thread: loads `messagesNotifierProvider` messages
  (newest-first, rendered reversed), renders real bubbles with loading/empty/error,
  and Send actually calls `sendMessage(...)` with in-flight + failure handling.
  Removed the canned bubbles and the "coming soon" call/profile/mute/block stubs.

## Third pass — shipped (finish faked surfaces)

Analyze-clean; UI wiring best verified in-app.

- **Chat-list unread badges** — `_threadFromRow` now derives `unreadCount` from
  the current user's `last_read_at` vs `last_message_at` (data already fetched —
  no query change). The existing bold-row/badge UI lights up.
- **Notifications tab** — `_NotificationsTab` rebuilt as a consumer of the real
  `notificationNotifierProvider` with loading/empty/error, `NotificationCard`
  rows, tap-to-read and swipe-to-delete.
- **Parent "action required" ledger** — `_NeedsAttentionLedger` rewired from the
  invented "$450 due / unread note" to real data: outstanding fees from
  `parentChildOverviewProvider` + unread count from messaging `unreadCountProvider`,
  with an "All caught up" empty state. Removed the fabricated child-card
  "homework due" / "Active period: Chemistry lab" lines.
- **Teacher dashboard** — removed the fabricated "Grading Ledger: 32/40 graded"
  and the index-derived "Topic: Chapter N" per-slot line (kept the real
  "N Active Courses").

## Deferred — genuinely blocked / next pass
- **Messaging compose (new conversations)** — blocked on missing infrastructure:
  there is no users-search provider, and the student↔parent↔user_id linkage is
  incomplete (`ai_message_composer_screen.dart:195` TODO needs a DB migration).
  Interim: the compose Send no longer *silently pretends to send* — it now states
  new conversations aren't available yet and points to existing chats. Real fix
  needs a recipient search provider + the linkage migration.
- **Chat-list last-message preview text** — needs a latest-message-per-thread
  embed/view/RPC; deferred to avoid an unverifiable blind query (unread badge,
  the primary triage signal, is done).
- **Teacher graded-count / per-slot topic** — no provider exists; needs a
  submissions-graded aggregate + lesson_plans/topic_coverage wiring.

## Deferred — larger infrastructure
- Real payment gateway SDK (razorpay) + server order-create + `recordPayment`
  reconciliation (removes the demo banner).
- FCM push notifications + automatic parent absence/tardy alerts.
- Biometric unlock / "keep me signed in".
- Move gateway secret/webhook keys server-side (stop `select('*')` to client).
- Self-service signup route decision (screen exists but is unreachable) + invite flow.
- Skeleton/shimmer loaders across lists; tenant-driven currency formatting.
