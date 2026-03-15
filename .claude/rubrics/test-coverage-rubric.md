# Test Coverage Rubric — Flutter

**Used By**: TDD Guide Agent, Code Reviewer Agent
**Purpose**: Ensure adequate test coverage and test quality
**Version**: 1.0

---

## Coverage Targets

| Area | Required |
| --- | --- |
| New/changed code | **80%** (statements, branches, functions, lines) |
| Existing unchanged code | No regression — must not decrease |

**Why 80%, not 100%?** This project currently has 0% tests. 80% is the achievable, high-value target. Below 80% guarantees untested code paths; above 80% is encouraged but not blocking.

---

## Reference Standards

| Document | Purpose |
| --- | --- |
| `.claude/guides/testing-patterns.md` | Canonical Flutter test writing guide |
| `CLAUDE.md` | Known issues (tenantId!, attendance overwrite, demo creds) |

---

## Test Quality Criteria

### 1. Test Independence

| Criterion | Pass | Fail |
| --- | --- | --- |
| No shared state | Each test isolated | Tests affect each other |
| Order independent | Can run in any order | Must run in sequence |
| No real Supabase calls | All external calls mocked | Real HTTP/DB calls |

### 2. Meaningful Assertions

| Criterion | Pass | Fail |
| --- | --- | --- |
| Tests behavior | Validates outcomes | Only checks calls were made |
| Specific assertions | Checks exact values | `expect(result, isNotNull)` alone |
| Error cases tested | Tests failure paths | Happy path only |

### 3. Mock Appropriateness (mocktail)

| Criterion | Pass | Fail |
| --- | --- | --- |
| Uses `Mock` classes | `class MockRepo extends Mock implements Repo {}` | Manual stub objects |
| `ProviderContainer` overrides | Tests use Riverpod container overrides | Tests import live providers |
| Realistic fallback values | `registerFallbackValue` for custom types | Missing fallback registration |

### 4. Flutter-Specific Quality

| Criterion | Pass | Fail |
| --- | --- | --- |
| `pumpAndSettle()` used | Async widget tests settle properly | Assertions before async completes |
| Widget test wraps in `ProviderScope` | Full Riverpod context available | Direct widget without providers |
| No hardcoded demo credentials visible | `expect(find.text('admin123'), findsNothing)` | Demo creds visible in UI |

---

## Required Test Cases

### For Every Provider/StateNotifier

1. **Happy path** — Returns expected data for valid tenant
2. **Error propagation** — Network/Supabase exception propagated
3. **Tenant isolation** — Query scoped to correct `tenantId`
4. **Pagination** — List does not load unbounded records
5. **Null tenantId** — Handled for super_admin case

### For Every Screen Widget

1. **Loading state** — `CircularProgressIndicator` or shimmer shown
2. **Success state** — Data renders correctly
3. **Error state** — Error message shown with retry
4. **Empty state** — `EmptyState` widget shown when no data
5. **Navigation** — Back button works, taps navigate correctly
6. **CRITICAL: No demo creds** — `admin@school.com`, `admin123` not visible

### For Every Repository

1. **tenant_id filter** — Query always includes `.eq('tenant_id', tenantId)`
2. **Pagination** — `.range()` present on list queries
3. **Error mapping** — `PostgrestException` handled correctly

---

## Test Patterns

### Good: Provider Test

```dart
group('StudentsProvider', () {
  test('returns students for tenant', () async {
    when(() => mockRepo.getStudents('tenant_123'))
        .thenAnswer((_) async => [Student(id: 's1', name: 'Alice', tenantId: 'tenant_123')]);

    final result = await container.read(studentsProvider('tenant_123').future);

    expect(result.first.name, equals('Alice'));
    verify(() => mockRepo.getStudents('tenant_123')).called(1);
  });
});
```

### Anti-Patterns to Flag

```dart
// BAD — tests presence, not correctness
expect(result, isNotNull);

// BAD — tests mock behavior only, not results
verify(() => mockRepo.save(any())).called(1);
// Missing: what was the state after save?

// BAD — real Supabase call
test('loads students', () async {
  final students = await SupabaseClient().from('students').select();
  // Real HTTP!
});

// BAD — missing pumpAndSettle in widget test
await tester.tap(find.text('Login'));
await tester.pump(); // should be pumpAndSettle()
expect(find.byType(CircularProgressIndicator), findsNothing);
```

---

## Coverage Commands

```bash
# Run with coverage
flutter test --coverage

# Summary (requires lcov)
lcov --summary coverage/lcov.info

# Extract coverage for specific feature
lcov --extract coverage/lcov.info "*/features/auth/*" \
  --output-file /tmp/auth.info
lcov --summary /tmp/auth.info

# HTML report
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

---

## Review Output Format

```markdown
## Test Review: <files>

### Coverage Summary

| File | Statements | Branches | Functions | Lines |
| --- | --- | --- | --- | --- |
| student_provider.dart | 85% | 72% | 90% | 84% |

### Verdict: ADEQUATE | NEEDS IMPROVEMENT

---

### Missing Test Cases

#### 1. tenant_id filter not tested

**File**: `student_repository_test.dart`
**Method**: `getStudents()`
**Missing**: Test verifying `.eq('tenant_id', tenantId)` called

### Quality Issues

#### 1. Weak assertion

**File**: `login_screen_test.dart:45`
**Issue**: `expect(result, isNotNull)` — doesn't verify login success
**Fix**: `expect(find.text('Welcome'), findsOneWidget)`
```

---

## Approval Criteria

**ADEQUATE** when:
- Coverage ≥ 80% on new/changed code
- All required test cases present (loading/error/empty/success states)
- No anti-patterns (real network calls, missing pumpAndSettle)

**NEEDS IMPROVEMENT** when:
- Coverage < 80%
- Missing error path tests
- Missing tenant_id filter test
