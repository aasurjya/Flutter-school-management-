# Adversarial Review Rubric — Flutter

**Used By**: Code Review Agent (adversarial mode)
**Purpose**: Binary spec compliance verification against Definition of Done contract
**Version**: 1.0

---

## Overview

This rubric is for **adversarial review** — a fundamentally different mode from collaborative code review. Your job is to **find failures**, not help improve the code. You are checking whether the implementation meets its written contract (spec and DoD items), not whether the code is "good."

**Key distinction:**
- **Collaborative review** (`code-review-rubric.md`): "How can this code be better?"
- **Adversarial review** (this rubric): "Does this code meet its contract? Prove it."

---

## Verdict

Every adversarial review produces exactly one verdict:

| Verdict | Meaning | Criteria |
| --- | --- | --- |
| **PASS** | Implementation meets its contract | Zero BLOCKING issues |
| **FAIL** | Implementation violates its contract | One or more BLOCKING issues |

There is no "APPROVED WITH COMMENTS." PASS or FAIL.

---

## Issue Classification

| Classification | Meaning | Impact on Verdict |
| --- | --- | --- |
| **BLOCKING** | Contract violation — spec says X, code does not do X | Causes FAIL |
| **WARNING** | Quality concern — not a spec violation | Does NOT cause FAIL |

**When in doubt, it's BLOCKING.** The threshold for PASS should be high.

---

## Evidence Requirements

Every finding requires **cited evidence**. Assertions without evidence are invalid.

### For PASS (per DoD item)

```markdown
**DoD #1**: "All student queries include tenant_id filter"
**Verdict**: PASS
**Evidence**:
- Implementation: `lib/features/students/data/repositories/student_repository.dart:34` — `.eq('tenant_id', tenantId)`
- Test: `test/features/students/data/repositories/student_repository_test.dart:67` — test "getStudents includes tenant_id filter"
```

### For FAIL (per DoD item)

```markdown
**DoD #3**: "Loading state shown while students are fetched"
**Verdict**: FAIL (BLOCKING)
**Expected**: CircularProgressIndicator shown while AsyncLoading
**Found**: Screen returns empty Container() on AsyncLoading at `lib/features/students/presentation/screens/student_list_screen.dart:45` — no loading widget
**Evidence**: `lib/features/students/presentation/screens/student_list_screen.dart:45`
```

---

## Review Categories

### 1. Spec Compliance (BLOCKING threshold)

For each DoD item:

| Check | Classification | Criteria |
| --- | --- | --- |
| DoD item fully implemented | BLOCKING if missing | Implementation exists AND handles all specified cases |
| DoD item tested | BLOCKING if untested | At least one test directly verifies the DoD item |
| DoD item matches spec | BLOCKING if divergent | Does what spec SAYS, not what reviewer assumes |

**Process:**
1. Read each DoD item verbatim
2. Search the diff for the implementation
3. Search the diff for tests that verify the behavior
4. Cite file:line for both
5. If either is missing → BLOCKING FAIL

### 2. Flutter-Critical Safety (BLOCKING threshold)

| Check | Classification | Criteria |
| --- | --- | --- |
| tenant_id on all new queries | BLOCKING | Missing = multi-tenant data leak |
| mounted check after await | BLOCKING | Missing = crash on widget unmount |
| dispose() implemented | BLOCKING | Missing controllers/subscriptions = memory leak |
| No hardcoded demo credentials | BLOCKING | admin@school.com or admin123 in new code |

### 3. Test Quality (BLOCKING / WARNING)

| Check | Classification | Criteria |
| --- | --- | --- |
| Tests verify behavior, not presence | BLOCKING | No `expect(result, isNotNull)` as sole assertion for DoD-critical behavior |
| Tests cover error paths | WARNING | Happy path alone insufficient for DoD items mentioning errors |
| No real Supabase calls in tests | BLOCKING | Real HTTP calls make tests environment-dependent |
| `pumpAndSettle()` in widget tests | WARNING | Missing can cause false passes |

### 4. File Scope (BLOCKING threshold)

| Check | Classification | Criteria |
| --- | --- | --- |
| Changes within declared scope | BLOCKING if violated | Work unit may only modify declared files |
| No unrelated changes | BLOCKING | No "while I was here" modifications |

```bash
# Get actual changed files
git diff main..HEAD --name-only
# Every changed file must be in declared file scope
```

### 5. Dart/Flutter Type Safety (BLOCKING / WARNING)

| Check | Classification | Criteria |
| --- | --- | --- |
| No `dynamic` types where typed expected | BLOCKING | dynamic in new code on DoD-critical paths |
| No unsafe `!` without null guard | BLOCKING | Force-unwrap on nullable without proof of non-null |
| No `as` cast without type guard | WARNING | Unchecked casts noted but not blocking |

---

## Output Format

```markdown
## Adversarial Review: <work unit or feature>

### Verdict: PASS | FAIL

### DoD Verification

| # | DoD Item | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | <item text> | PASS | impl: `file:line`, test: `file:line` |
| 2 | <item text> | FAIL (BLOCKING) | Expected: <X>, Found: <Y> at `file:line` |
| 3 | <item text> | PASS | impl: `file:line`, test: `file:line` |

### BLOCKING Issues

1. **DoD #2 not met**: <description with evidence>
2. **Missing tenant_id filter**: `lib/features/x/data/repositories/x_repository.dart:45`

### WARNINGS

1. <warning with evidence>

### Files Reviewed

- `lib/features/x/presentation/screens/x_screen.dart` (modified, in scope)
- `test/features/x/presentation/screens/x_screen_test.dart` (added, in scope)
```

---

## Reviewer Conduct Rules

1. **Judge against the spec, not preferences.** If spec says "show CircularProgressIndicator" and code does that, it's PASS — even if you'd prefer a shimmer.
2. **No suggestions.** Report PASS or FAIL. Nothing else.
3. **No leniency.** "Close enough" is FAIL. The spec is the contract.
4. **No anchoring.** If re-reviewing after a FAIL, you must have ZERO knowledge of the previous review.
5. **Evidence or silence.** If you can't cite a file:line reference, you can't make the claim.
