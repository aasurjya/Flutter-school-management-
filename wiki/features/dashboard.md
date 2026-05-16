---
feature: dashboard
last_tested: 2026-05-16
tester: product-tester
verdict: SHIP
persona: Principal Mrs. Banerjee opening the app first thing Monday morning
---

# Dashboards (admin / teacher / student / parent)

## At a Glance
- **Verdict:** IMPROVE — admin dashboard mixes real data with hardcoded mock stats. Layout is polished; data integrity isn't.
- **Entry screens:**
  - [[../../lib/features/dashboard/presentation/screens/admin_dashboard_screen.dart]] (primary)
  - [[../../lib/features/dashboard/presentation/screens/teacher_dashboard_screen.dart]]
  - [[../../lib/features/dashboard/presentation/screens/student_dashboard_screen.dart]]
  - [[../../lib/features/dashboard/presentation/screens/parent_dashboard_screen.dart]]
- **Roles with access:** admin → admin variant, teacher → teacher variant, etc. (Routing in `app_router.dart:233-261`)

## Axis 1 — Works?

**Pass:**
- Admin dashboard wires real `studentCountProvider`, `feeCollectionStatsProvider`, `currentAcademicYearProvider`, `currentTenantProvider`, `riskDistributionProvider`, `unresolvedAlertCountProvider` — `admin_dashboard_screen.dart:282-296, 384-436`.
- Refresh invalidates real providers — `:48-53`.
- Quick action grids route to real screens via `_ResponsiveActionGrid` — `:712-727`.
- Tenant name pulled live from `currentTenantProvider` — `:102`.
- Date is computed from `DateTime.now()` — `:43`.
- At-risk + early-warning banners only render when count > 0 — `:402-404, 425-426`. Good defensive UI.

**Fail (visible mock data on the primary surface):**
- `_MetricCard(label: 'Attendance', value: '94.2%')` — `admin_dashboard_screen.dart:354`. **Hardcoded.**
- `_buildTodaySummary` is **100% hardcoded mock**:
  - "Students present: 2,312 / 2,456" — `:463`
  - "Teachers present: 121 / 124" — `:469`
  - "Outstanding Invoices: ₹4.2L" — `:475`
  - "Scheduled Events: 03" — `:481`
- `_buildRecentActivity` returns **3 hardcoded fake activities**:
  - "Fee Payment Received • Reference #PAY-9021 • John Doe" — `:494-499`
  - "New Admission • Class 10-A • Sarah Smith" — `:500-505`
  - "Exam Results Published • Mid-term • Class 12 Science" — `:506-511`
- "Profile" tile in settings menu has `onTap: () => Navigator.of(context).pop()` — no navigation — `admin_dashboard_screen.dart:944`.
- "Settings" tile same dead-onTap — `:977`.

The dashboard *looks* like it has a live operational view; in production with a real tenant, it'll show ratios that have no relationship to actual data.

## Axis 2 — Good?

- **Visual hierarchy:** Hero metric (Enrollment Strength) → Attendance + Revenue → Alerts → AI Summary → 3 action grids (Management / Academic / Operations) → Today summary → Activity. Strong scrollable structure.
- **Mobile-friendly:** `_ResponsiveActionGrid` correctly scales 3-7 columns based on width — `:653-654`. Good.
- **All-caps section headers** ("Management Tools", "Academic Setup", "School Operations", "Operational Health") give clear nav anchors.
- **Logout flow** uses `confirmLogout(context, ref)` from shared utils — `:24`. Correct.

Nitpicks:
- 3 separate action grids (Management Tools, Academic Setup, School Operations) total ~21 quick actions on one scrollable page. Visual clutter — first-time admin will be paralysed.
- "AdminAINarrativeCard" lives in the AI insights module — good code reuse but it's the only narrative element on the page; the layout would be cleaner if it sat next to Operational Health.

## Axis 3 — Necessary?

CRITICAL — this is the most-viewed screen for the highest-value persona. The principal opens it daily.

But the **mock data is a credibility-killer in vendor demos**. The 3 fake activities ("John Doe", "Sarah Smith", "PAY-9021") are clearly placeholders that survived a polish pass. A real customer trial will see those names and lose trust.

## Axis 4 — Improvable?

- [ ] **Replace `_MetricCard(value: '94.2%')` with `todayAttendancePercentageProvider`** — already used elsewhere — `admin_dashboard_screen.dart:354`.
- [ ] Replace `_buildTodaySummary` numbers with providers (`studentCountProvider`, `staffAttendanceProvider`, `feeCollectionStatsProvider`, `upcomingEventsProvider`) — `:451-490`.
- [ ] Replace `_buildRecentActivity` with a real activity feed provider (or hide the section if no provider exists yet). Even an empty state ("No activity yet today") is better than fake John Doe.
- [ ] Wire "Profile" and "Settings" tiles in the settings sheet to push to `/account` and `/settings` — `:944, 977`.
- [ ] Consolidate the 3 action grids into 2 (Operations + Setup). 21 icons is too many; pareto says 8 cover 80% of taps.

## Notes for the panel

- **Critic:** the fake activity feed is the single highest "embarrassment risk" in a customer demo. Treat as ship-blocker?
- **Product-intel:** what's on the Teachmint/Edsys home dashboard? Likely fewer surfaces — they ship one hero metric + 3 actions + alerts.
- **Architect:** decide whether `parent_dashboard_screen.dart` and `student_dashboard_screen.dart` share enough with admin to factor out a `BaseDashboardScaffold` widget. (Not read in depth this pass — flagged for next iteration.)

## Fixed 2026-05-16

Ship-blocker surfaces wired on `admin_dashboard_screen.dart`:

- **Attendance % tile** — wired to `todayAttendancePercentageProvider` (reads `v_section_daily_attendance.attendance_percentage`, aggregated mean across all sections today).
- **Students present** — wired to `todayStudentAttendanceCountsProvider` (new provider, calls `AttendanceRepository.getTodayStudentCounts()` which sums `present_count / total_students` from the same view).
- **Teachers present** — wired to `staffAttendanceTodayProvider`; surfaces `'—'` pending a staff-role filter on the DB view (TODO sprint-1.6).
- **Outstanding Invoices** — wired to `feeCollectionStatsProvider(null)`; reads `stats['total_pending']` (field was `total_pending`, not `outstanding`).
- **Scheduled Events** — deferred; renders `'—'` with a TODO(sprint-1.6) comment.
- **Fake activity feed** — `_buildRecentActivity()` call hidden from `build()` with a comment; method body preserved for easy restore.
- **Profile drawer tile** — now navigates to `AppRoutes.account` via `GoRouter.of(context).go(...)`.
- **Settings drawer tile** — hidden (no `/settings` route this sprint).
- `_ViewAllBtn` dead widget removed (was only used by the now-hidden activity section).

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
