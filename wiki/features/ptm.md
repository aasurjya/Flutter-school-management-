---
feature: ptm
last_tested: 2026-05-16
tester: product-tester
verdict: IMPROVE
persona: Mrs. Banerjee (principal) trying to schedule a PTM for Class 10 mid-term
---

# PTM Scheduler

## At a Glance
- **Verdict:** IMPROVE — read path is wired, but the only write action is a snackbar. PTM is a tier-1 use case in Indian K-12; this can't ship as-is.
- **Entry screen:** [[../../lib/features/ptm/presentation/screens/ptm_scheduler_screen.dart]]
- **Roles with access:** admin, principal, teacher, parent

## Axis 1 — Works?

**Pass:**
- 3 tabs (Upcoming / My Appointments / All PTMs) hooked to real `ptmSchedulesProvider` + `ptmAppointmentsProvider` — `ptm_scheduler_screen.dart:69-75, 113-118, 158-160`.
- Filter parameter `upcomingOnly: true` actually filters — `:73`.
- Each PTM card routes to `/ptm/{id}` detail — `:193`.
- Empty states with icons + helpful copy — `:79-94, 121-138`.
- Loading + error fallbacks present — `:103-105, 146-148, 174-176`.

**Fail:**
- **Create PTM FAB is a snackbar** — `ptm_scheduler_screen.dart:53-59`: `'PTM creation coming soon'`. The whole module is named "Scheduler" yet you can't schedule.

## Axis 2 — Good?

- **Taps to book an appointment (parent):** likely 3 (PTM → upcoming → book). Reasonable, assuming `book_appointment_screen.dart` actually fires.
- **Taps to create a PTM (principal):** ∞ (FAB dead).
- **Labels:** "Upcoming / My Appointments / All PTMs" — clean.
- **Empty states:** "No upcoming PTMs / Check back later for scheduled meetings" — informative and warm. Best-in-class.

Nitpicks:
- "All PTMs" tab is a redundancy of "Upcoming" + completed ones. Could be replaced with a date range filter on Upcoming.
- No indicator of how many parents have RSVP'd. Critical for the persona — they want to see "Class 10-A: 22/30 RSVP'd, 8 missing".

## Axis 3 — Necessary?

YES — PTMs are mandatory in Indian K-12, typically 3-4 per year. Coordinating teacher availability + parent slots is the actual pain point. A working scheduler is a real wedge against MyClassboard (which makes you do it in Excel).

But: today, the principal can't actually use the scheduler. The "Create PTM" snackbar is the blocker.

## Axis 4 — Improvable?

- [ ] **Implement Create PTM form** — at minimum: date, time-range, section(s), max-slots-per-teacher. This is Sprint 3 on [[pending]]; promote to Sprint 1.5.
- [ ] Add RSVP count to PTM cards ("22/30 parents RSVP'd").
- [ ] Add "Send PTM invite to parents" CTA that opens the `communication` campaign creator pre-filled.
- [ ] Replace "All PTMs" tab with date-range filter on Upcoming.

## Notes for the panel

- **Architect:** PTM creation will touch `ptm_schedules` and `teacher_assignments` together — must be a server-side RPC (per Known Issues in `claude.md`: "No transaction guarantees for multi-step ops (PTM deletion, invoice generation, canteen orders) — use server-side RPCs"). Confirm RPC design before UI build.
- **Critic:** the "All PTMs" tab is exactly the kind of filler the 48-feature sprawl produces. Cut it; one list with a filter does the same job.
- **Product-intel:** does Edsys / Teachmint offer PTM scheduling? If yes, what's the differentiator we want here?

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
