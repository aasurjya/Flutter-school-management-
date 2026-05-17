// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppUser _makeUser({required String role, String id = 'user-1'}) {
  final now = DateTime(2024, 1, 1);
  return AppUser(
    id: id,
    email: '$role@test.com',
    tenantId: 'tenant-$role',
    roles: [role],
    primaryRole: role,
    createdAt: now,
    updatedAt: now,
  );
}

/// A minimal [AuthNotifier] subclass that skips the real `_init` call and
/// starts directly from a given [AsyncValue]. Uses the
/// [AuthNotifier.forTest] constructor so no network or Supabase is touched.
class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(super.initialState)
      : super.forTest();
}

/// Builds a [ProviderContainer] whose [authNotifierProvider] is stubbed to
/// start at [value].
ProviderContainer _makeContainer(AsyncValue<AppUser?> value) {
  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        (ref) => _StubAuthNotifier(value),
      ),
    ],
  );
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('currentUserProvider — no stale state across role switches', () {
    // ------------------------------------------------------------------
    // Test 1: currentUserProvider derives from authNotifierProvider
    // ------------------------------------------------------------------
    test(
      'test_currentUserProvider_teacherSession_returnsTeacher',
      () {
        final teacher = _makeUser(role: 'teacher');
        final container = _makeContainer(AsyncValue.data(teacher));
        addTearDown(container.dispose);

        final user = container.read(currentUserProvider);
        expect(user, isNotNull);
        expect(user!.primaryRole, equals('teacher'));
      },
    );

    test(
      'test_currentUserProvider_roleSwitch_returnsNewRoleImmediately',
      () {
        // Simulate sign-out → sign-in as parent (a fresh container with
        // parent session, as the router would see on redirect).
        final parent = _makeUser(role: 'parent');
        final container = _makeContainer(AsyncValue.data(parent));
        addTearDown(container.dispose);

        final user = container.read(currentUserProvider);
        expect(user, isNotNull);
        expect(user!.primaryRole, equals('parent'),
            reason:
                'currentUserProvider must reflect the new role immediately; '
                'a stale StateProvider would still return teacher here');
      },
    );

    test(
      'test_currentUserProvider_asyncLoading_returnsNull',
      () {
        final container = _makeContainer(const AsyncValue.loading());
        addTearDown(container.dispose);

        final user = container.read(currentUserProvider);
        expect(user, isNull,
            reason:
                'While auth is loading, currentUserProvider must expose null '
                'so the router never redirects to any dashboard prematurely');
      },
    );

    // ------------------------------------------------------------------
    // Test 2: currentTenantIdProvider derives from authNotifierProvider
    // ------------------------------------------------------------------
    test(
      'test_currentTenantIdProvider_teacherSession_returnsTenantId',
      () {
        final teacher = _makeUser(role: 'teacher');
        final container = _makeContainer(AsyncValue.data(teacher));
        addTearDown(container.dispose);

        final tenantId = container.read(currentTenantIdProvider);
        expect(tenantId, equals('tenant-teacher'));
      },
    );

    test(
      'test_currentTenantIdProvider_asyncLoading_returnsNull',
      () {
        final container = _makeContainer(const AsyncValue.loading());
        addTearDown(container.dispose);

        final tenantId = container.read(currentTenantIdProvider);
        expect(tenantId, isNull);
      },
    );

    test(
      'test_currentTenantIdProvider_nullUser_returnsNull',
      () {
        final container = _makeContainer(const AsyncValue.data(null));
        addTearDown(container.dispose);

        final tenantId = container.read(currentTenantIdProvider);
        expect(tenantId, isNull);
      },
    );

    // ------------------------------------------------------------------
    // Test 3: Core regression — both derived providers propagate a state
    // change on the notifier synchronously (no separate .notifier.state=
    // call needed). The old StateProvider copy would NOT update until
    // _loadUserProfile ran, so there was a window where the router read
    // stale role data.
    // ------------------------------------------------------------------
    test(
      'test_currentUserProvider_notifierStateChange_propagatesInstantly',
      () {
        final teacher = _makeUser(role: 'teacher');
        final stub = _StubAuthNotifier(AsyncValue.data(teacher));

        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((_) => stub),
          ],
        );
        addTearDown(container.dispose);

        // Prime initial reads.
        expect(container.read(currentUserProvider)?.primaryRole, 'teacher');
        expect(container.read(currentTenantIdProvider), 'tenant-teacher');

        // Simulate sign-out → sign-in as parent by mutating notifier state.
        final parent = _makeUser(role: 'parent', id: 'user-2');
        stub.state = AsyncValue.data(parent);

        // Derived providers must reflect the change without any extra
        // .notifier.state = assignment.
        expect(container.read(currentUserProvider)?.primaryRole, 'parent',
            reason: 'Derived Provider must propagate notifier state change '
                'synchronously; stale StateProvider copy would still be teacher');
        expect(container.read(currentTenantIdProvider), 'tenant-parent');
      },
    );
  });
}
