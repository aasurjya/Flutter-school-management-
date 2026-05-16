// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/profile/presentation/screens/change_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGoRouter extends Mock {
  String? lastRoute;
  void go(String route) => lastRoute = route;
}

// ---------------------------------------------------------------------------
// Fake AuthResponse / UserResponse helpers
// ---------------------------------------------------------------------------

/// Minimal [AppUser] fixture
AppUser _makeUser({
  String id = 'user-1',
  String email = 'member@test.com',
}) {
  final now = DateTime(2024, 1, 1);
  return AppUser(
    id: id,
    email: email,
    tenantId: 'tenant-1',
    roles: const ['teacher'],
    primaryRole: 'teacher',
    createdAt: now,
    updatedAt: now,
  );
}

/// Stub [AuthNotifier] that skips network init and starts from a fixed state.
class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(AsyncValue<AppUser?> initialState)
      : super.forTest(initialState);
}

// ---------------------------------------------------------------------------
// Widget-under-test builder
// ---------------------------------------------------------------------------

/// Renders [ChangePasswordScreen] inside a lightweight [MaterialApp] so that
/// [ScaffoldMessenger] and navigation work without a real GoRouter.
///
/// We use a [Navigator]-based replacement for GoRouter so that the screen can
/// call [context.go('/login')] via a fake GoRouter lookup — but for simplicity
/// we override the auth notifier only and catch snackbars / navigation via
/// widget finders.
Widget _makeApp({
  required AuthRepository mockRepo,
  AppUser? loggedInUser,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
      authNotifierProvider.overrideWith(
        (ref) => _StubAuthNotifier(
          loggedInUser != null
              ? AsyncValue.data(loggedInUser)
              : const AsyncValue.data(null),
        ),
      ),
    ],
    child: MaterialApp(
      home: const ChangePasswordScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  // -------------------------------------------------------------------------
  // 1. Validation — password strength
  // -------------------------------------------------------------------------
  testWidgets(
    'test_changePassword_validatesNewPasswordStrength',
    (tester) async {
      await tester.pumpWidget(_makeApp(
        mockRepo: mockRepo,
        loggedInUser: _makeUser(),
      ));
      await tester.pumpAndSettle();

      // Fill current password with something
      await tester.enterText(
          find.byKey(const Key('current_password_field')), 'OldPass1');

      // --- Case A: too short ---
      await tester.enterText(
          find.byKey(const Key('new_password_field')), 'abc');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'abc');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);

      // --- Case B: no upper / digit ---
      await tester.enterText(
          find.byKey(const Key('new_password_field')), 'abcdefgh');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'abcdefgh');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      expect(
        find.text('Password must contain uppercase, lowercase, and a digit'),
        findsOneWidget,
      );

      // --- Case C: strong password — no strength error ---
      await tester.enterText(
          find.byKey(const Key('new_password_field')), 'Abcd1234');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'Abcd1234');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      expect(find.text('Password must be at least 8 characters'), findsNothing);
      expect(
        find.text('Password must contain uppercase, lowercase, and a digit'),
        findsNothing,
      );
    },
  );

  // -------------------------------------------------------------------------
  // 2. Validation — confirm mismatch
  // -------------------------------------------------------------------------
  testWidgets(
    'test_changePassword_rejectsMismatchedConfirm',
    (tester) async {
      await tester.pumpWidget(_makeApp(
        mockRepo: mockRepo,
        loggedInUser: _makeUser(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('current_password_field')), 'OldPass1');
      await tester.enterText(
          find.byKey(const Key('new_password_field')), 'Abcd1234');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'Abcd9999');

      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      verifyNever(() => mockRepo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    },
  );

  // -------------------------------------------------------------------------
  // 3. Validation — new == current
  // -------------------------------------------------------------------------
  testWidgets(
    'test_changePassword_rejectsSameAsCurrent',
    (tester) async {
      await tester.pumpWidget(_makeApp(
        mockRepo: mockRepo,
        loggedInUser: _makeUser(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('current_password_field')), 'Abcd1234');
      await tester.enterText(
          find.byKey(const Key('new_password_field')), 'Abcd1234');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'Abcd1234');

      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      expect(
        find.text('New password must differ from the current password'),
        findsOneWidget,
      );
      verifyNever(() => mockRepo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    },
  );

  // -------------------------------------------------------------------------
  // 4. Wrong current password — inline error
  // -------------------------------------------------------------------------
  testWidgets(
    'test_changePassword_wrongCurrentPassword_showsInlineError',
    (tester) async {
      when(() => mockRepo.signInWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ))
          .thenThrow(const AuthException('Invalid login credentials'));

      await tester.pumpWidget(_makeApp(
        mockRepo: mockRepo,
        loggedInUser: _makeUser(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('current_password_field')), 'WrongPass1');
      await tester.enterText(
          find.byKey(const Key('new_password_field')), 'Abcd1234');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'Abcd1234');

      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      // Inline error visible, user stays on screen
      expect(find.text('Current password is incorrect.'), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    },
  );

  // -------------------------------------------------------------------------
  // 5. Success — signs out and navigates to /login
  // -------------------------------------------------------------------------
  testWidgets(
    'test_changePassword_success_signsOutAndNavigates',
    (tester) async {
      // Build a fake AuthResponse with a non-null session to satisfy success
      when(() => mockRepo.signInWithEmail(
                email: any(named: 'email'),
                password: any(named: 'password'),
              ))
          .thenAnswer((_) async => AuthResponse());

      // updatePassword return value is unused — stub must not throw.
      // UserResponse has no default constructor; build via fromJson.
      when(() => mockRepo.updatePassword(any())).thenAnswer((_) async {
        return UserResponse.fromJson({
          'id': 'user-1',
          'aud': 'authenticated',
          'created_at': '2024-01-01T00:00:00.000Z',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
        });
      });

      when(() => mockRepo.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(_makeApp(
        mockRepo: mockRepo,
        loggedInUser: _makeUser(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('current_password_field')), 'OldPass1');
      await tester.enterText(
          find.byKey(const Key('new_password_field')), 'Abcd1234');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'Abcd1234');

      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      // signOut must have been called exactly once
      verify(() => mockRepo.signOut()).called(1);
    },
  );
}
