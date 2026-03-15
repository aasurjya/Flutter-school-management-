# Code Review Rubric — Flutter/Dart

**Used By**: Code Reviewer Agent
**Purpose**: Evaluate code changes before PR creation
**Version**: 1.0

---

## Severity Levels

| Level | Description | Action |
| --- | --- | --- |
| **CRITICAL** | Security vulnerability, data loss risk, crashes production | MUST fix before PR |
| **HIGH** | Bug, incorrect behavior, significant performance issue | MUST fix before PR |
| **MEDIUM** | Code smell, maintainability issue, minor bug | SHOULD fix |
| **LOW** | Style, nitpick, suggestion | OPTIONAL |

---

## Reference Standards

| Document | Purpose |
| --- | --- |
| `.claude/guides/coding-standards.md` | Dart null safety, Riverpod patterns, multi-tenant rules |
| `CLAUDE.md` | Architecture, known issues, key file paths |
| `.claude/guides/testing-patterns.md` | Flutter test philosophy, mocktail patterns |
| `.claude/guides/build-validation.md` | flutter analyze, flutter test workflows |

---

## Evaluation Categories

### 1. Correctness (CRITICAL/HIGH)

| Criterion | Severity | Check |
| --- | --- | --- |
| Code does what it's supposed to do | CRITICAL | Manual trace through logic |
| Edge cases handled | HIGH | Null, empty, boundary values |
| Error paths correct | HIGH | Exceptions caught and handled |
| No logic errors | CRITICAL | Conditions, loops, async flows |

---

### 2. Multi-Tenant Safety (CRITICAL)

| Criterion | Severity | Check |
| --- | --- | --- |
| `tenant_id` on all Supabase queries | CRITICAL | Every `.from()` call includes `.eq('tenant_id', tenantId)` |
| `tenantId!` not force-unwrapped | CRITICAL | Check for null before unwrapping; super_admin has no tenantId |
| No cross-tenant data leaks | CRITICAL | Queries scoped to correct tenant |
| RLS policies rely on tenant_id | HIGH | Don't trust client-side only |

**Code Patterns to Flag:**

```dart
// CRITICAL — fetches data from ALL tenants
final response = await supabase.from('students').select();

// CRITICAL — crashes for super_admin
final tenantId = authState.tenantId!;

// GOOD
final tenantId = authState.tenantId;
if (tenantId == null) return; // or handle super_admin case
final response = await supabase.from('students').select()
    .eq('tenant_id', tenantId);
```

---

### 3. Security (CRITICAL)

| Criterion | Severity | Check |
| --- | --- | --- |
| No hardcoded credentials | CRITICAL | No passwords/emails in source — KNOWN ISSUE in LoginScreen |
| Auth/authz enforced | CRITICAL | Role checks, GoRouter guards |
| No sensitive data in logs | HIGH | No PII, tokens in print/debugPrint |
| Input validation present | HIGH | User input validated before Supabase calls |

**CRITICAL PROJECT CHECK**: Grep for `admin@school.com`, `admin123`, `password123` — these demo credentials MUST be removed before production.

---

### 4. Flutter/Dart Quality (HIGH/MEDIUM)

| Criterion | Severity | Check |
| --- | --- | --- |
| `dispose()` implemented | HIGH | All controllers, animations, subscriptions disposed |
| `mounted` check after `await` | HIGH | `if (!mounted) return;` before any `BuildContext` use after async |
| `ref.watch` only in `build()` | HIGH | Never in `onPressed`, `initState`, async methods |
| `ref.read` in callbacks | HIGH | Not `ref.watch` in event handlers |
| Null safety correct | HIGH | No unsafe `!` without proof value is non-null |
| Immutability with `copyWith` | MEDIUM | Never mutate state directly |
| `const` constructors used | MEDIUM | const for all widgets/values not using runtime data |

**Code Patterns to Flag:**

```dart
// HIGH — crash risk
Navigator.of(context).pop(); // after await without mounted check

// HIGH — wrong ref usage
ElevatedButton(onPressed: () => ref.watch(someProvider))

// HIGH — real-time leak
StreamSubscription _sub = supabase.from('x').stream(...).listen(...);
// Without _sub.cancel() in dispose()
```

---

### 5. Database / Performance (HIGH/MEDIUM)

| Criterion | Severity | Check |
| --- | --- | --- |
| Pagination on list queries | HIGH | `.range(offset, offset + pageSize - 1)` present |
| No N+1 queries | HIGH | No loops that make individual Supabase calls |
| No transaction-less multi-step ops | HIGH | Fee + invoice + wallet should use RPC, not 3 calls |
| Indexes for new query patterns | MEDIUM | New `.eq()` patterns need indexes |
| No unbounded queries | HIGH | No `.select()` without `.range()` on large tables |

---

### 6. Testing (HIGH)

| Criterion | Severity | Check |
| --- | --- | --- |
| Tests exist for new code | HIGH | Widget tests for screens, unit tests for providers |
| Tests verify results, not presence | HIGH | Not just `expect(result, isNotNull)` |
| mocktail used for mocks | HIGH | Not manual mock objects |
| No real Supabase calls in tests | CRITICAL | All external calls mocked |
| 80% coverage on changed files | HIGH | `flutter test --coverage` target |

---

### 7. Maintainability (MEDIUM)

| Criterion | Severity | Check |
| --- | --- | --- |
| Files < 800 lines | MEDIUM | Extract widgets if larger |
| Functions focused | MEDIUM | Single responsibility |
| Names follow conventions | MEDIUM | snake_case files, PascalCase classes, camelCase vars |
| Error handling present | HIGH | No empty catch blocks |

---

## Review Output Format

```markdown
## Code Review: <files or PR description>

### Verdict: APPROVED | CHANGES REQUIRED

### Summary

<Brief description of what the code does and overall quality>

---

### Critical Issues (Must Fix)

#### 1. Missing tenant_id filter

**File**: `lib/features/students/data/repositories/student_repository.dart:45`
**Severity**: CRITICAL
**Issue**: Supabase query fetches students from all tenants
**Fix**: Add `.eq('tenant_id', tenantId)` to query

---

### High Priority Issues (Must Fix)

#### 2. Missing mounted check

**File**: `lib/features/auth/presentation/screens/login_screen.dart:78`
**Severity**: HIGH
**Issue**: `Navigator.pop(context)` called after `await` without `mounted` check

---

### Checklist

#### Multi-Tenant Safety
- [ ] All queries have tenant_id filter
- [ ] No `tenantId!` force-unwrap

#### Flutter Safety
- [ ] dispose() implemented
- [ ] mounted checks after async
- [ ] ref.watch only in build()

#### Security
- [ ] No hardcoded credentials
- [ ] Auth checks present

#### Performance
- [ ] Pagination on list screens
- [ ] No N+1 queries

#### Testing
- [ ] Tests exist
- [ ] 80%+ coverage
```

---

## Approval Criteria

**APPROVED** when:
- Zero CRITICAL issues
- Zero HIGH issues (or explicitly accepted with justification)
- MEDIUM issues documented

**CHANGES REQUIRED** when:
- Any CRITICAL issues exist
- Any HIGH issues without justification

---

## Maximum Iterations: 3

After 3 rounds, escalate to human if issues persist.
