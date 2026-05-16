---
feature: exams
last_tested: 2026-05-16
tester: product-tester
verdict: SHIP
persona: Priya (10th-grader at a CBSE school) checking her mid-term marks
---

# Exams & Results

## At a Glance
- **Verdict:** SHIP — clean implementation top to bottom; rare in this codebase.
- **Entry screen:** [[../../lib/features/exams/presentation/screens/exams_screen.dart]]
- **Roles with access:** student, parent, teacher, admin

## Axis 1 — Works?

**Pass — every single widget is wired:**
- Upcoming/Ongoing/Completed bucketing computed from real `examsProvider` data with date math — `exams_screen.dart:82-98`.
- Results tab uses real `studentPerformanceProvider` keyed on `(studentId, examId)` — `:182-187`.
- Class rank from real `studentOverallRankProvider` — `:188-193`.
- Analytics tab pulls subject-vs-class-average from `classExamStatsProvider` — `:425-427`.
- Exam history list iterates last 5 exams with real per-exam rank — `:550-613`.
- Empty states present and informative ("No exams scheduled", "No exam results available") — `:69-79, 159-169`.
- Error states with no leak of stack traces — `:53-66`.

No `coming soon` snackbars. No hardcoded IDs. No `onPressed: () {}`.

## Axis 2 — Good?

- **Taps to see latest result:** 2 (open Exams → Results tab). The dropdown defaults to most recent. Good.
- **Labels:** "Upcoming / Results / Analytics" — student-friendly. Rank card with trophy icon is delightful and works for the Indian parental obsession with ranks.
- **Empty states:** good. "No exams scheduled" with assignment-outlined icon — `:69-79`. "No analytics available yet" — `:397-406`. These are the gold standard for the rest of the app.
- **Visual hierarchy:** Subject performance shows score vs class-average with trending-up / trending-down icons — `:730-738`. Concrete, immediately readable.

Nitpicks:
- The Analytics tab opens to "latest exam" by default, with no selector — `:418`. Once a student has more than ~3 exams, they'll want to compare to specific ones, not just the latest.
- The Results dropdown shows raw `exam.name` — fine, but on a 2026 academic-year sprint with many exams it'll get long. Group by term?

## Axis 3 — Necessary?

CRITICAL — exam results are the **#1 reason** Indian parents open a school-management app. The trophy/rank card is exactly the dopamine hit the persona wants. This and Attendance are the two features that drive daily active usage from the parent persona.

No overlap with `report_card` module — report_card is for end-of-term PDF generation; this module is the in-app live view. Keep separate.

## Axis 4 — Improvable?

- [ ] Add exam selector to Analytics tab (currently locked to `exams.first`).
- [ ] Group exams in dropdown by term (Term 1, Term 2, Final).
- [ ] Add a "compare with classmate" mode — the rank card already shows class rank, but a parent will want to see "who's #1 and how far ahead are they?" (sociological reality of Indian K-12).
- [ ] Add a teacher's variant of this screen (`marks_entry_screen.dart` exists but isn't linked from here for the teacher persona).

## Notes for the panel

- **Critic:** is this screen too good for the rest of the app? What pattern made this work — was it written by a different agent / different sprint? Worth extracting as the template for fees, attendance, fees re-implementation.
- **Mobile-UX:** the trophy gradient card (`:225-285`) is the only "celebratory" surface in the app. Pattern should be reused for awards, attendance milestones, fee-paid-on-time states.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
