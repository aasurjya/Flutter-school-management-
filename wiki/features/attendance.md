---
feature: attendance
last_tested: 2026-05-16
tester: product-tester
verdict: IMPROVE
persona: Mr. Rajan, Class 8-B teacher and class-teacher at a 600-student school
---

# Attendance

## At a Glance
- **Verdict:** IMPROVE — daily mark flow works end-to-end, but Reports tab is partially fake.
- **Entry screen:** [[../../lib/features/attendance/presentation/screens/attendance_screen.dart]]
- **Roles with access:** teacher (own sections), admin (all sections), student (own history)

## Axis 1 — Works?

**Pass:**
- Real sections from `classTeacherSectionsProvider` for teachers, `allSectionsProvider` for admins — `attendance_screen.dart:80-83`.
- Daily attendance percentage from `sectionDailyAttendanceProvider` RPC — `:158-185`.
- Per-section card with Marked/Pending status and live %, routing to `/attendance/mark/:sectionId?date=...` — `:191-200`.
- Student view shows real monthly stats from `attendanceStatsProvider` — `:213, 232-303`.
- Student recent history from `studentAttendanceProvider` with 30-day window — `:217-226`.

**Fail:**
- `_buildWeeklyCalendar` is **hardcoded mock data**: `final statuses = ['P', 'P', 'P', 'A', 'P', '-'];` — `attendance_screen.dart:366-367`. Every student sees the same fake week with a fake Thursday absence. This is the single most-viewed widget for parents using a child's account; it actively misinforms them.
- Reports tab dropdowns are **decorative**: `onChanged: (value) {}` on Period — `:456`, and on Class — `:474`. Pick a class, nothing happens. Pick "This Week", nothing happens.
- `_ReportCard "Avg Attendance %"` second card is a confused `(100 - avgPercentage)` computation labeled the same as the first card — `:524-531`. Both cards now show contradictory values for the same metric.

## Axis 2 — Good?

- **Taps to mark attendance:** 3 (open → pick class → mark). Within budget.
- **Labels:** "Mark Attendance / Reports" tabs read fine. The status pill ("Marked"/"Pending") is great — visible at a glance.
- **Empty state:** "No classes assigned" — `:148-153`. Functional but rough; doesn't tell a teacher *why* (RLS? section missing? class_teacher assignment not configured?).
- **Date picker** opens cleanly via the calendar icon action — `:53-56, 627-637`. Good.

## Axis 3 — Necessary?

YES — daily attendance is table-stakes for any school SaaS in India and is one of the few features tracked by the Government RTE compliance reports. The teacher's mark-attendance flow is the single most-used screen in the app. Keep, harden.

## Axis 4 — Improvable?

- [ ] Replace `_buildWeeklyCalendar` mock with real `studentAttendanceProvider` data for the current ISO week. **This is the highest-leverage fix in the screen — it lies to parents today.**
- [ ] Wire Period/Class dropdowns to actually filter `sectionDailyAttendanceProvider` — currently inert.
- [ ] Fix the duplicate "Avg Attendance %" `_ReportCard` to show "Absent Today" count derived from RPC, not `100 - avg`.
- [ ] Add "Mark all present" bulk action to the per-section card (the dominant case for an Indian class is "all present, mark 2 absent").
- [ ] Add a "yesterday's attendance" prefill for teachers who forgot to mark on the day (very common in Indian schools).

## Notes for the panel

- **Architect:** decide whether weekly-calendar should be a separate widget consuming a `currentWeekAttendanceProvider`, or stay inline. Test isolation matters here — the mock data has survived because there's no widget test.
- **Critic:** the fake weekly calendar is a trust-killer. Should it be removed entirely (ship-blocker level) or fixed in Sprint 2?
- **Mobile-UX:** on low-bandwidth (Indian Tier-3 city), the per-section card fires N watchers for N sections — could be 30+ RPC calls on a school admin's view. Pagination or aggregate single RPC needed.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
