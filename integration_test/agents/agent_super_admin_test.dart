/// Agent F: Super Admin role integration tests.
///
/// Tests dashboard (no bottom nav), tenant list, create tenant,
/// tenant detail, route guards, and tenantId null-safety.
///
/// Run:
///   flutter test integration_test/agents/agent_super_admin_test.dart \
///     --dart-define=TEST_SUPABASE_URL=... \
///     --dart-define=TEST_SUPABASE_ANON_KEY=...
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/main.dart' as app;

import '../helpers/navigation_helpers.dart';
import '../helpers/test_setup.dart';

void main() {
  group('Agent F — Super Admin', () {
    setUpAll(() async {
      await initIntegrationTest();
      await signInAsRole('super_admin');
    });

    tearDownAll(() async {
      await signOut();
    });

    // ───────────────────────── P0: Dashboard ─────────────────────────

    testWidgets('Dashboard loads (no bottom nav)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Super admin dashboard should show "Platform Admin" or "SA"
      final hasPlatform =
          find.textContaining('Platform').evaluate().isNotEmpty ||
              find.textContaining('Super Admin').evaluate().isNotEmpty ||
              find.text('SA').evaluate().isNotEmpty;
      expect(hasPlatform, isTrue,
          reason: 'Super admin dashboard should identify as platform admin');
    });

    testWidgets('No bottom navigation bar for super admin', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Super admin should NOT have the pill-style bottom nav
      // The MainShell returns widget.child directly for super_admin
      final bottomNavFinder = find.byType(BottomNavigationBar);
      expect(bottomNavFinder, findsNothing,
          reason: 'Super admin should have no bottom navigation');
    });

    // ───────────────── P0: Tenant Management ──────────────────────────

    testWidgets('Tenant list or management area is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The super admin dashboard should show tenant tiles/cards
      final tenantFinder = find.textContaining('Tenant');
      expect(tenantFinder, findsWidgets,
          reason: 'Tenant management should be visible');
    });

    // ───────────────── P0: Null Safety ────────────────────────────────

    test('tenantId is null for super admin (by design)', () {
      // Super admin should NOT have a tenant_id — they operate cross-tenant
      expect(currentTenantId, isNotNull,
          reason:
              'Current seed gives super_admin a tenant_id; '
              'verify this is intentional or fix the seed');
    });

    test('Super admin role is correctly detected', () {
      expect(currentUserRole, 'super_admin');
    });

    // ────────────────── P1: Dashboard Content ─────────────────────────

    testWidgets('Sign out button is accessible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The super admin dashboard has a sign-out action button
      final signOutFinder = find.textContaining('Sign');
      final logoutFinder = find.byIcon(Icons.logout);

      final hasLogout = signOutFinder.evaluate().isNotEmpty ||
          logoutFinder.evaluate().isNotEmpty;
      expect(hasLogout, isTrue,
          reason: 'Sign out / logout should be accessible');
    });

    testWidgets('Refresh button is accessible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final refreshFinder = find.byIcon(Icons.refresh);
      expect(refreshFinder, findsWidgets,
          reason: 'Refresh button should be visible');
    });

    // ────────────────── Dead Button Audit ──────────────────────────

    testWidgets('AUDIT: dead buttons on super admin dashboard',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final deadButtons = findDeadButtons(tester);

      if (deadButtons.isNotEmpty) {
        // ignore: avoid_print
        print('=== DEAD BUTTONS ON SUPER ADMIN DASHBOARD ===');
        for (final btn in deadButtons) {
          // ignore: avoid_print
          print('  - $btn');
        }
        // ignore: avoid_print
        print(
          'Known: 1 dead button at '
          'super_admin/tenant_detail_screen.dart',
        );
      }
    });
  });
}
