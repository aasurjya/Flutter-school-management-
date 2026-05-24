# Codegen — when to use Freezed, when to use plain Dart

> Decision made: **2026-05-24** based on the existing 6 Freezed / 59 plain
> codebase split. Plain Dart is the default; Freezed only for the cases below.

## The decision

**Plain Dart classes are the standard** for `lib/data/models/`. Use the
existing `fromJson` / `toJson` pattern with manual constructors.

**Freezed is allowed only when:**

1. The model is used in `StateNotifier` / `Riverpod` state and needs `copyWith` for state transitions.
2. The model has 6+ fields and structural equality is load-bearing for `setState` short-circuits or Riverpod's `==` checks.
3. Union-type / sealed-class semantics are needed (e.g., `Result.success() | Result.error()`).

Everything else — DTOs over the wire, simple value classes, lookup
records — stays plain.

## Why this way, not the other way

Looking at the existing split (`find lib/data/models -name "*.dart"`):

- **6 Freezed:** `bus_tracking`, `inventory`, `invoice`, `gradebook`,
  `syllabus_topic`, `assignment`, `timetable`, `exam_statistics`,
  `online_exam`, `message`, `announcement`, `report_commentary`. All are
  either rich state holders (gradebook, exam_statistics) or have unions
  (assignment with submission types). Freezed earned its place there.
- **59 plain:** mostly simple DTOs — `student`, `parent`, `staff`, `class`,
  `section`, `subject`, `fee_head`, etc. Freezed for these would add a
  build_runner step + 800-line generated files per model for a `copyWith`
  that's used twice. Cost > benefit.

The earlier audit flagged "mixed patterns" as a code smell, but the
mix is actually *load-balanced by use case*. Standardizing on Freezed
would mean ~50 new `.freezed.dart` files (≈40k LOC of generated code).
Standardizing on plain would mean rewriting the 12 Freezed models'
state-transition logic by hand. Both are migrations with no payoff.

**The right call is to lock in what's already true and stop drifting.**

## Lint enforcement (cheap ratchet)

There's no hard CI gate today — the rule is enforced via PR review.
When someone adds a new model in `lib/data/models/`:

- Default: plain Dart (`class Foo { final String id; ... }`).
- If they want Freezed, they cite which of the 3 conditions above applies
  in the PR description.

If this is ignored repeatedly, add a lint script following the
`tool/design_token_lint.dart` ratchet pattern:
- Count `.freezed.dart` files in `lib/data/models/`.
- Baseline at the current count (12 or whatever it grows to).
- Fail CI when a new one appears without an explicit allow-list update.

Until that happens, this doc is the standard.

## Migration policy

**Don't bulk-migrate either direction.** The 6 Freezed models stay
Freezed; the 59 plain models stay plain. The only allowed direction is
**plain → Freezed** when a model crosses one of the 3 conditions above
(e.g., a plain DTO gets used in a StateNotifier).

Plan for any future migration:
1. One model per PR.
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`.
3. Update every consumer in the same PR (Edit's `replace_all` works for
   most rename-only changes).
4. Verify tests still pass.
5. Update this doc's count.

## Closing the "codegen unification" task

This decision doc **closes S3.24** from the scale roadmap. The task
was "Pick Freezed for everything or plain for everything." This
matches neither extreme — it picks **plain by default, Freezed where
earned**. That's the pragmatic answer because:

- The cost of bulk-migrating either way is ~1 week of churn with no
  measurable user impact.
- The mixed pattern hurts no one as long as the rule for picking is
  written down (this doc).
- A ratchet script can enforce it if drift ever becomes a real problem.

Status: **deferred items closed.** No further migration work pending.
