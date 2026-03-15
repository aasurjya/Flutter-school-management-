# Plan Review Rubric — Flutter/School Management

**Used By**: CTO Agent, Review Design Command
**Purpose**: Evaluate implementation plans before any code is written
**Version**: 1.0

---

## Overview

Plans that don't meet REQUIRED criteria must be sent back for revision. A plan review prevents wasted implementation effort.

---

## Evaluation Categories

### 1. Requirements Alignment (REQUIRED)

| Criterion | Pass | Fail |
| --- | --- | --- |
| Plan addresses ALL stated requirements | All items covered | Missing requirements |
| Success criteria are measurable | Clear metrics defined | Vague or unmeasurable |
| Scope is right-sized | No over/under engineering | Too complex or too simple |
| Edge cases identified | Listed with handling | Not considered |

**Questions to Ask:**
- Does this solve the actual stated problem?
- Is anything being built that wasn't asked for?
- Are implied requirements captured?

---

### 2. Flutter Architecture Fit (REQUIRED)

| Criterion | Pass | Fail |
| --- | --- | --- |
| Correct layer placement | Screen/Provider/Repository | Business logic in wrong layer |
| Follows existing feature structure | `presentation/screens/`, `providers/`, `data/` | Ad-hoc file placement |
| Uses BaseRepository | Extends base class | Direct Supabase calls |
| Riverpod patterns correct | autoDispose, family, watch/read rules | Wrong provider type or lifecycle |

**Reference**: See `CLAUDE.md` architecture section and `.claude/guides/coding-standards.md`

---

### 3. Multi-Tenant Safety (REQUIRED)

| Criterion | Pass | Fail |
| --- | --- | --- |
| All new queries scoped | tenant_id planned on every query | No mention of tenant scoping |
| tenantId null handled | super_admin case explicitly handled | tenantId! assumed |
| New tables have tenant_id | Schema includes tenant_id column | Missing from table design |
| Migration is idempotent | `IF NOT EXISTS` on all creates | Destructive migrations |
| RLS policies planned | Row-level security for new tables | No mention of RLS |

---

### 4. Technical Correctness (REQUIRED)

| Criterion | Pass | Fail |
| --- | --- | --- |
| Pagination on list screens | `.range()` in plan | Unbounded queries planned |
| Null safety respected | Nullable types used correctly | Force-unwrap `!` on uncertain values |
| Error handling complete | All error paths covered | Happy path only |
| Freezed rebuild noted | Plan mentions `build_runner` if models change | Silently skipping codegen step |
| Real-time cleanup planned | `dispose()` + `cancel()` mentioned | Memory leak risk |

---

### 5. Testing Strategy (REQUIRED)

| Criterion | Pass | Fail |
| --- | --- | --- |
| Test approach defined | Clear what will be tested | No testing mentioned |
| TDD workflow specified | Tests before implementation | Implementation first |
| mocktail mock strategy | Uses Mock classes + ProviderContainer | Manual mocks or real Supabase |
| Coverage targets identified | 80% target on changed files | Vague "will add tests" |
| Critical cases planned | tenant_id filter test, no demo creds test | Missing known-critical tests |

---

### 6. Security Considerations (REQUIRED)

| Criterion | Pass | Fail |
| --- | --- | --- |
| No demo credentials | Plan removes or avoids hardcoded creds | Keeps known credentials |
| Auth/authz addressed | Role checks, GoRouter guards | Missing access controls |
| Payment operations safe | Server-side atomicity for multi-step ops | Client-side multi-step |
| Input validation present | Form validation before DB writes | Direct user input to Supabase |

---

### 7. Operational Readiness (RECOMMENDED)

| Criterion | Pass | Needs Work |
| --- | --- | --- |
| Error messages helpful | User-facing error copy defined | Generic "Something went wrong" |
| Loading/error/empty states | All UI states specified | Only success state designed |
| Offline behavior defined | Isar usage or "online only" stated | Unspecified |

---

## Scoring

**REQUIRED Categories (1–6)**: All criteria must PASS. Any FAIL = revision needed.
**RECOMMENDED (7)**: Should be addressed but doesn't block approval.

---

## Review Output Format

```markdown
## Plan Review: <feature name>

### Verdict: APPROVED | NEEDS REVISION

### Requirements Alignment
- [x] All requirements addressed
- [x] Success criteria measurable
- [ ] Scope appropriate — **ISSUE**: Caching layer not required

### Architecture Fit
- [x] Correct layer placement
- [x] Follows existing feature structure
- [x] BaseRepository used

### Multi-Tenant Safety
- [ ] All queries scoped — **ISSUE**: tenant_id missing from plan for notifications table
- [x] tenantId null handled

### Technical Correctness
- [x] Pagination planned
- [ ] Freezed rebuild noted — **NOTE**: Add build_runner step when adding new model

### Testing Strategy
- [x] TDD workflow specified
- [x] 80% coverage target
- [ ] Critical cases planned — **MISSING**: No test planned for tenant_id filter

### Security
- [x] No demo credentials
- [x] Auth enforced

---

### Required Changes (Must Fix Before Coding)

1. Add tenant_id to notifications table plan
2. Plan a test verifying tenant_id filter on notification queries

### Recommendations

1. Consider adding empty state UI spec for no-notifications case
```

---

## Common Rejection Reasons

1. **Over-engineering**: Abstractions for single use cases — e.g., generic caching layer for one query
2. **Missing tenant_id**: Plan doesn't address multi-tenant scoping on new tables
3. **No pagination**: List screen planned without `.range()` — will crash with large schools
4. **Missing Freezed step**: Model changes don't mention `build_runner`
5. **No testing strategy**: "Will add tests later" is not acceptable
6. **tenantId! assumed**: Plan doesn't handle super_admin case
7. **Scope creep**: Plan touches files not in scope
