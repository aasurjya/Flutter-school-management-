# Testing Patterns Guide — Flutter

Canonical guide for writing tests in this Flutter school management project. Every agent and developer writing tests should read this document.

---

## Philosophy

### Why 80% Coverage?

We enforce 80% statement, branch, function, and line coverage on new/changed code. This project currently has 0% tests — 80% is the achievable, valuable target. Anything below 80% means significant untested code paths.

Coverage is a floor, not a ceiling. 80% coverage doesn't mean the code is correct — but less means guaranteed untested paths.

### Why TDD?

Test-Driven Development enforces writing tests before implementation:

1. **RED**: Write a failing test that describes expected behavior
2. **GREEN**: Write the minimum code to make it pass
3. **REFACTOR**: Improve code while keeping tests green

TDD is a design tool. Writing the test first forces you to think about the interface before the implementation.

### Tests Must Test Results, Not Presence

```dart
// BAD — tests presence, not correctness
expect(result, isNotNull);
expect(mockRepo.called, true);

// GOOD — tests actual results
expect(result.status, equals(AttendanceStatus.present));
expect(result.studentId, equals('student_123'));
verify(() => mockRepo.save(expectedAttendance)).called(1);
```

---

## Test File Organization

```text
test/
  features/
    attendance/
      presentation/
        screens/
          mark_attendance_screen_test.dart
      providers/
        attendance_provider_test.dart
      data/
        repositories/
          attendance_repository_test.dart
    fees/
      ...
  core/
    widgets/
      ...
```

Mirror the `lib/` structure. One test file per source file.

---

## Provider Testing Pattern (Riverpod)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentRepository extends Mock implements StudentRepository {}

void main() {
  late MockStudentRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockStudentRepository();
    container = ProviderContainer(
      overrides: [
        studentRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    registerFallbackValue(const Student(id: '', name: '', tenantId: ''));
  });

  tearDown(() {
    container.dispose();
  });

  group('StudentsProvider', () {
    test('returns students for tenant', () async {
      // Arrange
      const tenantId = 'tenant_123';
      final students = [Student(id: 's1', name: 'Alice', tenantId: tenantId)];
      when(() => mockRepo.getStudents(tenantId)).thenAnswer((_) async => students);

      // Act
      final result = await container.read(studentsProvider(tenantId).future);

      // Assert
      expect(result, equals(students));
      verify(() => mockRepo.getStudents(tenantId)).called(1);
    });

    test('propagates error from repository', () async {
      when(() => mockRepo.getStudents(any()))
          .thenThrow(Exception('Network error'));

      expect(
        container.read(studentsProvider('tenant_123').future),
        throwsException,
      );
    });
  });
}
```

---

## Widget Testing Pattern

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {}

Widget buildTestWidget({
  List<Override> overrides = const [],
  Widget? child,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child ?? const LoginScreen(),
    ),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('CRITICAL: no hardcoded demo credentials visible', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('admin@school.com'), findsNothing);
      expect(find.text('admin123'), findsNothing);
      expect(find.text('password123'), findsNothing);
    });

    testWidgets('shows error for empty email submission', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows loading state during auth', (tester) async {
      final mockNotifier = MockAuthNotifier();
      when(() => mockNotifier.login(any(), any()))
          .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1)));

      await tester.pumpWidget(buildTestWidget(
        overrides: [authProvider.notifier.overrideWith(() => mockNotifier)],
      ));

      await tester.enterText(find.byKey(const Key('email_field')), 'test@school.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

---

## Repository Testing Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockQueryBuilder extends Mock implements PostgrestQueryBuilder {}

void main() {
  late MockSupabaseClient mockSupabase;
  late StudentRepository repository;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    repository = StudentRepository(supabase: mockSupabase);
  });

  group('StudentRepository', () {
    test('getStudents includes tenant_id filter', () async {
      // This verifies the CRITICAL multi-tenant safety rule
      final mockQuery = MockQueryBuilder();
      when(() => mockSupabase.from('students')).thenReturn(mockQuery);
      when(() => mockQuery.select(any())).thenReturn(mockQuery);
      when(() => mockQuery.eq('tenant_id', 'tenant_123')).thenReturn(mockQuery);
      when(() => mockQuery.range(any(), any())).thenReturn(mockQuery);
      when(() => mockQuery).thenAnswer((_) async => []);

      await repository.getStudents('tenant_123');

      verify(() => mockQuery.eq('tenant_id', 'tenant_123')).called(1);
    });
  });
}
```

---

## Common mocktail Patterns

```dart
// Mock async method
when(() => mock.getStudents(any())).thenAnswer((_) async => []);

// Mock void method
when(() => mock.deleteStudent(any())).thenAnswer((_) async {});

// Mock error
when(() => mock.save(any()))
    .thenThrow(PostgrestException(message: 'Error', code: '23505'));

// Capture arguments
final call = verify(() => mock.save(captureAny())).captured;
expect(call.first as Student, predicate<Student>((s) => s.tenantId == 'tenant_123'));

// Match specific argument
when(() => mock.getStudent('student_123')).thenAnswer((_) async => student);
```

---

## Required Edge Cases

For every provider/repository, test:

1. **Empty result** — No records for valid tenant
2. **Error state** — Network failure, Supabase exception
3. **Tenant isolation** — Query is scoped to correct tenant
4. **Pagination** — List does not load unlimited records
5. **Null safety** — Null tenantId for super_admin case
6. **Invalid input** — Empty strings, malformed IDs

For every screen, test:

1. **Loading state** — Shows `CircularProgressIndicator` or shimmer
2. **Success state** — Data renders correctly
3. **Error state** — Error message shown with retry option
4. **Empty state** — Empty state widget shown when no data
5. **Navigation** — Back button works, taps navigate correctly

---

## Coverage Commands

```bash
# Run with coverage
flutter test --coverage

# Summary
lcov --summary coverage/lcov.info

# HTML report
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html

# Target: 80% on new/changed code
```

## Anti-Patterns to Avoid

1. **Testing mock behavior** — `verify(() => mock.method()).called(1)` without asserting the result
2. **Asserting too little** — `expect(result, isNotNull)` doesn't verify correctness
3. **Shared test state** — Using class-level variables that leak between tests
4. **Real Supabase calls** — Never make real network calls in unit tests
5. **Missing `pumpAndSettle()`** — Async widget tests need settlement
6. **Skipping error paths** — Test the `catch` branches, not just happy path

---

## See Also

- [Coding Standards](./coding-standards.md) — Dart null safety, Riverpod patterns
- [Build Validation](./build-validation.md) — `flutter test --coverage` workflow
