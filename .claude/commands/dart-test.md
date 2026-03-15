---
description: Flutter TDD — scaffold testWidgets/test files, run flutter test --coverage, interpret lcov output
---

# Dart Test (TDD)

Flutter-specific Test-Driven Development. Scaffold test files FIRST, verify they fail, implement, verify they pass.

## Usage

```text
/dart-test <file-to-test>
/dart-test lib/features/fees/providers/fees_provider.dart
/dart-test lib/features/auth/presentation/screens/login_screen.dart
```

## TDD Workflow

### 1. RED — Write Failing Test

Scaffold the test file before writing any implementation:

```bash
# Determine test file path
SOURCE=lib/features/fees/providers/fees_provider.dart
TEST=test/features/fees/providers/fees_provider_test.dart

# Create test directory
mkdir -p $(dirname $TEST)
```

**Provider test scaffold:**

```dart
// test/features/fees/providers/fees_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_management/features/fees/providers/fees_provider.dart';

// Mock repository
class MockFeesRepository extends Mock implements FeesRepository {}

void main() {
  late MockFeesRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockFeesRepository();
    container = ProviderContainer(
      overrides: [
        feesRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('FeesProvider', () {
    test('initial state is loading', () {
      final state = container.read(feesProvider);
      expect(state, isA<AsyncLoading>());
    });

    test('loads fees for tenant', () async {
      // Arrange
      final mockFees = [/* mock Fee objects */];
      when(() => mockRepo.getFees(any())).thenAnswer((_) async => mockFees);

      // Act
      await container.read(feesProvider.future);

      // Assert
      final state = container.read(feesProvider);
      expect(state.value, equals(mockFees));
      verify(() => mockRepo.getFees(any())).called(1);
    });

    test('handles error from repository', () async {
      // Arrange
      when(() => mockRepo.getFees(any())).thenThrow(Exception('Network error'));

      // Act & Assert
      final state = await container.read(feesProvider.future).catchError((_) => []);
      expect(container.read(feesProvider).hasError, isTrue);
    });
  });
}
```

**Widget test scaffold:**

```dart
// test/features/auth/presentation/screens/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_management/features/auth/presentation/screens/login_screen.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {}

void main() {
  Widget buildWidget({AuthNotifier? authNotifier}) {
    return ProviderScope(
      overrides: [
        if (authNotifier != null)
          authProvider.notifier.overrideWith(() => authNotifier),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  group('LoginScreen', () {
    testWidgets('shows email and password fields', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows error for empty submission', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('does NOT show hardcoded demo credentials', (tester) async {
      await tester.pumpWidget(buildWidget());

      // CRITICAL: No demo credentials should be visible
      expect(find.text('admin@school.com'), findsNothing);
      expect(find.text('admin123'), findsNothing);
    });
  });
}
```

### 2. Run Tests — Verify FAIL

```bash
flutter test $TEST
# Expected: FAILING (red) — "No tests passed"
```

### 3. Implement Minimal Code

Write just enough to make tests pass. Reference the test expectations.

### 4. Run Tests — Verify PASS

```bash
flutter test $TEST
# Expected: All tests passing (green)
```

### 5. Check Coverage

```bash
flutter test --coverage
# Generates coverage/lcov.info

# View summary
lcov --summary coverage/lcov.info

# For just the file under test:
lcov --extract coverage/lcov.info "*/features/fees/*" --output-file /tmp/fees_coverage.info
lcov --summary /tmp/fees_coverage.info
```

Coverage target: **80%** for new code.

### 6. Refactor

Improve code while keeping tests green. Re-run tests after each change.

## Required Edge Cases for Every Test Suite

1. **Empty/null state** — Empty list, null tenantId
2. **Error state** — Network failure, Supabase error
3. **Loading state** — Async data fetching
4. **Tenant isolation** — Operations are scoped to correct tenant
5. **Role-based access** — Correct data for the user's role
6. **Pagination** — List screens don't load unlimited records

## Test Structure: Arrange-Act-Assert

```dart
test('description of expected behavior', () async {
  // Arrange — set up mocks and test data
  when(() => mockRepo.method(any())).thenAnswer((_) async => result);

  // Act — call the code under test
  final actual = await provider.doSomething();

  // Assert — verify the outcome
  expect(actual.status, equals(Status.success));
  verify(() => mockRepo.method(capturedArg)).called(1);
});
```

## Common mocktail Patterns

```dart
// Mock async method returning data
when(() => mockRepo.getStudents(any())).thenAnswer((_) async => [student1, student2]);

// Mock void method
when(() => mockRepo.updateStudent(any())).thenAnswer((_) async {});

// Mock error
when(() => mockRepo.getStudents(any())).thenThrow(PostgrestException(message: 'Error'));

// Capture arguments
final captured = verify(() => mockRepo.save(captureAny())).captured;
expect(captured.first, equals(expectedStudent));
```

## Anti-Patterns to Avoid

- Testing that a function was called without asserting the result
- Using `tester.pumpWidget` without `await tester.pumpAndSettle()`
- Mocking Supabase client directly (mock repositories instead)
- Tests that depend on execution order (shared mutable state)
- Asserting with `isNotNull` when you can assert the actual value
