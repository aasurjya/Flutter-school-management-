---
feature: students
last_tested: 2026-05-16
tester: product-tester
verdict: IMPROVE
persona: Ms. Reddy, receptionist trying to add a walk-in student during peak admissions
---

# Students (List)

## At a Glance
- **Verdict:** IMPROVE — the read path is excellent (paginated, debounced search). The write path is **two dead "Add Student" buttons**.
- **Entry screen:** [[../../lib/features/students/presentation/screens/students_list_screen.dart]]
- **Roles with access:** admin, teacher, principal

## Axis 1 — Works?

**Pass:**
- `paginatedStudentsProvider` with scroll-pagination (300px before end) — `students_list_screen.dart:30-50, 211-230`.
- 300ms debounced search — `:52-60`.
- Clear search button — `:107-113`.
- Class/section filter state held locally; passed to provider — `:24-25, 54-69`.
- Real student card with phone, class-section, roll number, initials avatar — `:298-383`.
- Empty / error / loading states all handled with retry CTAs — `:165-209`.
- "x students" count shown at top — `:127-143`.

**Fail (the punchline):**
- AppBar `+` icon — `students_list_screen.dart:85-93` — is a snackbar: `'Add student coming soon'`.
- FAB `Add Student` — `students_list_screen.dart:151-160` — is the **same snackbar**.
- The filter sheet's "Apply Filters" button — `:280-289` — closes the sheet but the chips have `onSelected: (_) {}` — `:257, 259, 260, 271, 273, 274`. The whole sheet is decorative.

That's three dead user-actions on one screen.

## Axis 2 — Good?

- **Taps to view a student:** 1-2 (open → tap card). Excellent.
- **Taps to add a student:** ∞ (dead button). Critical fail for the receptionist persona.
- **Search/filter:** debounced + clear button + filter sheet UI is well thought through — but the chips don't fire. The "Apply Filters" button doesn't push state up.
- **Labels:** clean, no jargon.
- **Card density:** good — name + class-section + roll + phone in a single tappable row.

## Axis 3 — Necessary?

CRITICAL — this is the canonical list screen of the entire app. Used by every admin role. Cannot ship a school SaaS without an "Add Student" CTA that works.

The Add-Student path likely exists elsewhere (in `features/admin/student_management_screen.dart` or via admission acceptance flow). But this is where the receptionist will look first.

## Axis 4 — Improvable?

- [ ] **Wire both Add Student buttons** to push to the real add-student form. This is a 30-min fix and unblocks the receptionist persona.
- [ ] Wire the filter chips in `_showFilterSheet` to mutate `paginatedStudentsProvider` filter state.
- [ ] Add status filter (Active / Inactive / Alumni) actually firing.
- [ ] Highlight matched search substring in name (cheap, high signal).

## Notes for the panel

- **Architect:** decide where Add-Student lives. If it's in `features/admin/`, this screen should route to it; if it should live here, the form needs to move.
- **Critic:** the filter-sheet-of-lies is exactly the same pattern as Attendance Reports tab — chips/dropdowns rendered without state. Look for this pattern elsewhere with a grep for `onSelected: (_) {}` and `onChanged: (value) {}`.
- **Product-intel:** what does a receptionist's "Add student in 30 seconds" flow look like in Teachmint? Time-box benchmark needed.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
