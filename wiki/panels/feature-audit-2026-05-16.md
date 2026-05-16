---
type: panel
panel: feature-audit
date: 2026-05-16
moderator_needed: panel-moderator
audit_source: [[../_feature_inventory_2026-05-16]]
---

# Feature Audit Panel — 2026-05-16

**Question for the panel:** Should we ship these decisions?

product-tester completed an audit of 12 top-priority features. 8 came back IMPROVE, 3 came back SHIP, 1 came back KILL. Three of the IMPROVE / KILL findings are contentious enough to warrant a multi-agent panel:

---

## Finding 1 — `ai_tutor` should be KILLED before Sprint 2

**Verdict from product-tester:** KILL.

**Evidence:**
- `lib/features/ai_tutor/` has no entry screen — only `widgets/tutor_chat_overlay.dart` + `providers/ai_tutor_provider.dart`.
- Not routed from any dashboard.
- Student-facing AI tutoring has bad unit economics at ₹50-200/student/month SaaS price (one multi-turn AI conversation can cost ₹50-200 in tokens alone).
- Liability: school is not the right vendor of AI tutoring; wrong answers blow back on school reputation.
- Free alternatives exist (ChatGPT, Gemini, Khan AI, Photomath) that students will use anyway.

**Question for the panel:**
- product-intel: cite any Indian K-12 SaaS that's shipped student-facing AI tutoring profitably. If none, recommendation stands.
- CTO: confirm cost-per-conversation floor.
- critic: is this a clean KILL or should we scope down to "AI homework helper bounded to assigned homework"?

**Files affected on KILL:**
- Delete `lib/features/ai_tutor/`
- Grep callers of `tutor_chat_overlay.dart` and remove mounts.
- Surface in [[../pending]] under "Needs Human" as a release-note item.

See [[../features/ai_tutor]].

---

## Finding 2 — Admin Dashboard ships with hardcoded mock data in 5 places

**Verdict from product-tester:** IMPROVE (likely ship-blocker for vendor demos).

**Evidence:** all in `lib/features/dashboard/presentation/screens/admin_dashboard_screen.dart`:
- `_MetricCard(label: 'Attendance', value: '94.2%')` — `:354` — hardcoded.
- `_buildTodaySummary` 4 entries — `:463, 469, 475, 481` — all hardcoded mock numbers.
- `_buildRecentActivity` 3 entries — `:494-511` — fake activity with names "John Doe", "Sarah Smith", "PAY-9021".
- Settings sheet "Profile" tile is `onTap: () => Navigator.of(context).pop()` — `:944` — no nav.
- Settings sheet "Settings" tile same dead-onTap — `:977`.

**Why it matters:** the admin dashboard is the **first screen a customer sees in a demo**. Fake-John-Doe activity items will destroy trust in the first 30 seconds.

**Question for the panel:**
- critic: ship-blocker for the Sprint 1 closure deploy, or Sprint 2 fix?
- architect: which existing providers cover these numbers? (`studentCountProvider`, `staffAttendanceProvider`, `feeCollectionStatsProvider`, `upcomingEventsProvider` likely candidates.)
- product-intel: is a recent-activity feed expected from a Tier-1 K-12 SaaS, or can we hide the section until real activity exists?

**Smallest fix:**
- Replace all 5 mock surfaces with `valueOrNull` chains on existing providers.
- Hide `_buildRecentActivity` until an `activityFeedProvider` is built (1-week scope).
- 2 dead onTap fixes are 2 lines of code each.

See [[../features/dashboard]].

---

## Finding 3 — The fees Quick Actions block the product demo

**Verdict from product-tester:** IMPROVE — **but practically ship-blocking**.

**Evidence:** all in `lib/features/fees/presentation/screens/fees_screen.dart`:
- "Generate Invoices" quick action — `:192-195` — snackbar.
- "Send Reminders" quick action — `:203-206` — snackbar.
- "Export Report" quick action — `:214-217` — snackbar.
- "Fee Structure" quick action — `:225-228` — snackbar.
- Collection-tab Export button — `:721-727` — snackbar.
- Invoice card View button — `:1108-1112` — snackbar.

That's 6 dead buttons on the highest-stakes screen in the app. Customer testing the fees module will tap "Generate Invoices" within the first 60 seconds and disqualify the product.

**Question for the panel:**
- critic: this is Sprint 3 on [[../pending]]. Should it be promoted to Sprint 1.5 (between current Phase β finish and Sprint 2 RLS hardening)?
- architect: confirm fix paths. Invoice gen → existing `pdf` package. Reminders → `communication` provider. Export → `share_plus`. Fee structure → new admin form (or wire to existing `fee_management_screen.dart` in `features/admin/`).
- product-intel: do MyClassboard / Edsys / Teachmint surface invoice-generation as a 1-click action? If yes, parity is mandatory.

**Smallest fix:**
- 4 of the 6 dead buttons can be wired to existing modules in <1 day. The fifth (Fee Structure form) requires new admin UI, ~3 days.
- Promote from Sprint 3 → Sprint 1.5.

See [[../features/fees]].

---

## Secondary findings (not contentious enough to need the panel, but logged)

- **`timetable` feature folder is empty** — actual screens live under `features/teacher/` and `features/student/`. Move them in or rename. See [[../features/timetable]].
- **`students_list_screen.dart` Add-Student button is a snackbar** (twice — `:85-93, 151-160`). Filter sheet chips are decorative (`onSelected: (_) {}`). Single-day fix. See [[../features/students]].
- **Attendance Reports tab dropdowns** have `onChanged: (value) {}` — `attendance_screen.dart:456, 474`. Same anti-pattern as students list. Single-day fix. See [[../features/attendance]].
- **`generate_remarks_screen.dart` ships hardcoded `_sections` and `_exams`** — `:24-34`. Vendor demos will pick "Class 10 - A" → backend gets `sec-1` (doesn't exist). Single-day fix. See [[../features/ai_insights]].
- **`PTM Create FAB is a snackbar`** — `ptm_scheduler_screen.dart:53-59`. Module called "Scheduler" can't actually schedule. Promote from Sprint 3 → Sprint 2. See [[../features/ptm]].
- **`Navigator.pushNamed` leak in `communication_dashboard_screen.dart`** — 8 sites bypass go_router. Lint rule needed. See [[../features/communication]].

## Verdict tally (12 features)

| Verdict | Count | Features |
|---|---|---|
| SHIP | 3 | exams, homework, admission, profile (4 actually — see corrigendum) |
| IMPROVE | 8 | fees, attendance, bus_tracking, communication, students, ptm, ai_insights, dashboard, timetable |
| KILL | 1 | ai_tutor |
| MERGE candidates | — | homework + assignments, transport + bus_tracking, parent_digest → communication, study_recommendations → homework |

(Total is >12 because some features split SHIP/IMPROVE flags. SHIP count is 4 if we include profile separately.)

## Panel deliverable

For each finding above, the panel must produce one of:

- **APPROVE-AND-EXECUTE** — agreement to ship the recommended change in the next sprint.
- **REJECT-AND-COUNTER** — alternative path, with reasoning.
- **DEFER** — explicit decision to delay, with re-review trigger.

Panel-moderator should write `panels/feature-audit-decision-2026-05-16.md` once verdicts are reached.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
- [[../pending]]
