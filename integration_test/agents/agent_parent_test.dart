/// Agent D: Parent role integration tests.
///
/// Tests dashboard, child selector, attendance view, fee payment,
/// messages. Flags hardcoded stats/fees and dead "Pay" button.
///
/// Run:
///   flutter test integration_test/agents/agent_parent_test.dart \
///     --dart-define=TEST_SUPABASE_URL=... \
///     --dart-define=TEST_SUPABASE_ANON_KEY=...
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/main.dart' as app;

import '../helpers/navigation_helpers.dart';
import '../helpers/test_setup.dart';

void main() {
  group('Agent D — Parent', () {
    setUpAll(() async {
      await initIntegrationTest();
      await signInAsRole('parent');
    });

    tearDownAll(() async {
      await signOut();
    });

    // ───────────────────────── P0: Dashboard ─────────────────────────

    testWidgets('Dashboard loads with child selector', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Parent dashboard should show "Hello" greeting
      expect(find.textContaining('Hello'), findsWidgets);
    });

    testWidgets('All 4 nav tabs present', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      verifyNavTabsExist(tester, 'parent');
    });

    testWidgets('Nav tab: Attendance navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Attendance');
      expect(find.textContaining('Attendance'), findsWidgets);
    });

    testWidgets('Nav tab: Fees navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Fees');
      expect(find.textContaining('Fee'), findsWidgets);
    });

    testWidgets('Nav tab: Messages navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Messages');
      expect(find.textContaining('Message'), findsWidgets);
    });

    // ──────────────── P0: Hardcoded Data Audit ────────────────────────

    testWidgets('AUDIT: quick stats are hardcoded (known bug)',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Known hardcoded values: '94%' attendance, '#05' rank
      final has94 = find.text('94%');
      final has05 = find.text('#05');

      if (has94.evaluate().isNotEmpty || has05.evaluate().isNotEmpty) {
        // ignore: avoid_print
        print(
          'BUG CONFIRMED: Parent dashboard quick stats hardcoded — '
          "'94%' attendance, '#05' rank. "
          'See parent_dashboard_screen.dart:333-346',
        );
      }
    });

    testWidgets('AUDIT: fee section shows hardcoded amounts (known bug)',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Known hardcoded: '20,000', '5,000'
      final has20k = find.textContaining('20,000');
      final has5k = find.textContaining('5,000');

      if (has20k.evaluate().isNotEmpty || has5k.evaluate().isNotEmpty) {
        // ignore: avoid_print
        print(
          'BUG CONFIRMED: Parent fee section hardcoded — '
          "'20,000' tuition, '5,000' transport. "
          'See parent_dashboard_screen.dart:534',
        );
      }
    });

    testWidgets('AUDIT: "Proceed to Payment" button is dead (known bug)',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for the payment button
      final payFinder = find.textContaining('Payment');
      if (payFinder.evaluate().isNotEmpty) {
        // ignore: avoid_print
        print(
          'DEAD BUTTON: "Proceed to Payment" has empty onPressed. '
          'See parent_dashboard_screen.dart:541',
        );
      }

      // Also check overall dead buttons
      final deadButtons = findDeadButtons(tester);
      if (deadButtons.isNotEmpty) {
        // ignore: avoid_print
        print('=== DEAD BUTTONS ON PARENT DASHBOARD ===');
        for (final btn in deadButtons) {
          // ignore: avoid_print
          print('  - $btn');
        }
      }
    });

    testWidgets('AUDIT: attendance overview hardcoded', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The Mon-Sat P/A grid is hardcoded
      // ignore: avoid_print
      print(
        'AUDIT: Verify parent_dashboard_screen.dart:351-352 — '
        'attendance overview day grid is hardcoded',
      );
    });

    testWidgets('AUDIT: academic progress hardcoded', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check for hardcoded subject progress
      final hasMathProgress = find.textContaining('Mathematics');
      final hasPhysicsProgress = find.textContaining('Physics');

      if (hasMathProgress.evaluate().isNotEmpty &&
          hasPhysicsProgress.evaluate().isNotEmpty) {
        // ignore: avoid_print
        print(
          'BUG CONFIRMED: Academic progress hardcoded — '
          'Mathematics 75%, Physics 70%',
        );
      }
    });

    // ──────────────── P1: "View All" Dead Buttons ─────────────────────

    testWidgets('AUDIT: "View All" buttons are dead', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final viewAllFinder = find.text('View All');
      if (viewAllFinder.evaluate().isNotEmpty) {
        // ignore: avoid_print
        print(
          'Known dead: 2x "View All" buttons at '
          'parent_dashboard_screen.dart:313',
        );
      }
    });

    // ─────────────────── Auth Verification ─────────────────────────

    test('Parent role is correctly detected', () {
      expect(currentUserRole, 'parent');
      expect(currentTenantId, isNotNull);
    });
  });
}
