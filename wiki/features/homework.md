---
feature: homework
last_tested: 2026-05-16
tester: product-tester
verdict: SHIP
persona: Mrs. Sharma, Class 7 maths teacher assigning weekly homework
---

# Homework Tracker

## At a Glance
- **Verdict:** SHIP — clean, focused, no dead buttons. One of the better surfaces in the app.
- **Entry screen:** [[../../lib/features/homework/presentation/screens/homework_dashboard_screen.dart]]
- **Roles with access:** teacher, student, parent

## Axis 1 — Works?

**Pass:**
- Real `homeworkDashboardStatsProvider(null)` powers all four stat cards (Total/Active/Overdue/To-Grade) — `homework_dashboard_screen.dart:33, 173-218`.
- `homeworkNotifierProvider.load()` fires in `initState` microtask (correct pattern) — `:25-28`.
- FAB routes to real `homeworkCreate` — `:48-50`.
- Calendar action and Quick Actions both route to real screens (`homeworkCalendar`, `homeworkCreate`) — `:43, 89-99`.
- Each homework tile routes to `/homework/{id}` detail with correct status pill + overdue badge — `:292, 274-321`.
- Pull-to-refresh invalidates correct providers — `:53-56`.
- Empty state: useful + suggests next action ("Tap the + button to assign homework") — `:121-148`.

No `coming soon`. No mock data. No dropped `onChanged`.

## Axis 2 — Good?

- **Taps to assign:** 1 (FAB). Best-in-class.
- **Labels:** clean. "To Grade" stat is exactly the cognitive frame a teacher uses ("what's on my desk?").
- **Overdue treatment:** red status pill + "Overdue" label override — `:319, 282`. Strong visual.
- **Priority badge:** "HIGH" tag only shows for high priority — `:371-388`. Restrained, correct.
- Tile shows subject + class + section + due date with icons in one row — `:329-356`. Dense without being cluttered.

Nitpicks:
- Recent Homework caps at 10 — `:151`. No pagination, no "View All". Once a teacher has 30+ assignments live, they can't see them all from this screen.
- No filter chips (mine vs all, by subject, by class). Probably belongs on the calendar view but worth raising.

## Axis 3 — Necessary?

YES — homework tracking is genuinely useful AND it's the bridge into the parent persona. The parent-mode of this screen (under `parent/presentation/screens/homework_tracker_screen.dart`) gives parents visibility into what their child must submit. That visibility is the #1 reason parents in India install the app.

No overlap with `assignments` module — they should arguably merge (see Improve list). The dual existence of `features/homework` and `features/assignments` is a navigation tax on the user.

## Axis 4 — Improvable?

- [ ] Add "View All" + filter chips on Recent Homework (mine / all / by subject / by class).
- [ ] **Merge `features/assignments` into `features/homework`** or rename consistently. Today both exist and route from the admin dashboard (`AppRoutes.assignments`). Pick one taxonomy.
- [ ] Add bulk-action: "Close all overdue homework". Right now there's no way to mass-close stale items.

## Notes for the panel

- **Architect:** the homework/assignments duplication is a clear merge candidate. Confirm one canonical name, deprecate the other.
- **Critic:** parent-side homework view is separate code (`parent/presentation/screens/homework_tracker_screen.dart`) — is that a deliberate role-specific UI, or should it consume the same provider chain with a `roleVariantProvider`?

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
