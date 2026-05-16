---
feature: timetable
last_tested: 2026-05-16
tester: product-tester
verdict: IMPROVE
persona: Mr. Rajan (Class 8-B teacher) checking his Monday schedule
---

# Timetable

## At a Glance
- **Verdict:** IMPROVE — folder is **provider-only**, no presentation screens. Routes reference it from the admin dashboard ("Timetable" quick action), but there's nothing to render. This is a major missing feature given how prominently it's surfaced.
- **Entry screen:** **MISSING** — only `lib/features/timetable/providers/timetable_provider.dart` exists.
- **Roles with access:** N/A — routes point to a non-existent screen.

## Axis 1 — Works?

**Fail at the structural level:**
- `lib/features/timetable/` contains only `providers/timetable_provider.dart`.
- `AppRoutes.timetable` is referenced from `admin_dashboard_screen.dart:724` (Quick Actions grid) and `:1005` (Academic Setup grid).
- Two surface-level entry points route to a feature that doesn't exist as a screen. This will either crash or hit a fallback.

The provider chain exists (data flow is plausibly ready), but the UI hasn't been built — OR it lives elsewhere under a different feature folder. Probable location: maybe inside `features/teacher/teacher_timetable_screen.dart` (which exists) and `features/student/student_timetable_screen.dart` (which is in routes). If so, the `features/timetable/` folder is a misnomer and the real screens are role-specific.

## Axis 2 — Good?

N/A — no screen to evaluate. The fact that route names point to a missing feature is itself a UX failure.

## Axis 3 — Necessary?

CRITICAL — timetable is a top-3 daily-use feature in Indian K-12. A student/teacher checks today's schedule every morning. Cannot ship without this.

Confirmed via routing references:
- `teacher_timetable_screen.dart` exists (line 53 of app_router imports)
- `student_timetable_screen.dart` exists (line 39 of app_router imports)

So the screens DO exist, just not under `features/timetable/`. The folder layout is wrong.

## Axis 4 — Improvable?

- [ ] **Move the existing role-specific timetable screens into `features/timetable/presentation/screens/` and route them through the same module.** Right now they're scattered under `features/teacher/` and `features/student/` and the canonical "timetable" folder is empty — anyone reading the codebase will be confused.
- [ ] Build an admin variant (`admin_timetable_screen.dart`) — the principal needs to see all classes' schedules.
- [ ] Add a "today" / "week" / "term" tab.
- [ ] Add conflict detection for substitutions (overlaps with `features/substitution/`).

## Notes for the panel

- **Architect:** the `features/timetable/` directory layout is a documentation lie. Either move the screens in, or delete the folder and rename the providers feature-internal. The mismatch is one of those small things that breaks new-contributor onboarding.
- **Critic:** flagged as MERGE candidate — pull the teacher/student timetable screens into one canonical module.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
