/// Agent C: Student role integration tests.
///
/// Tests dashboard, attendance view, results, messages, portfolio.
/// Flags hardcoded schedule and missing rank.
///
/// Run:
///   flutter test integration_test/agents/agent_student_test.dart \
///     --dart-define=TEST_SUPABASE_URL=... \
///     --dart-define=TEST_SUPABASE_ANON_KEY=...
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/main.dart' as app;

import '../helpers/navigation_helpers.dart';
import '../helpers/test_setup.dart';

void main() {
  group('Agent C — Student', () {
    setUpAll(() async {
      await initIntegrationTest();
      await signInAsRole('student');
    });

    tearDownAll(() async {
      await signOut();
    });

    // ───────────────────────── P0: Dashboard ─────────────────────────

    testWidgets('Dashboard loads with personalized greeting',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Student dashboard should show time-based greeting
      final hasGreeting = find.textContaining('Good').evaluate().isNotEmpty ||
          find.textContaining('Welcome').evaluate().isNotEmpty;
      expect(hasGreeting, isTrue,
          reason: 'Should show personalized greeting');
    });

    testWidgets('Attendance health metric shows real percentage',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show attendance percentage from attendanceStatsProvider
      final percentFinder = find.textContaining('%');
      expect(percentFinder, findsWidgets,
          reason: 'Attendance % should be visible on dashboard');
    });

    testWidgets('All 4 nav tabs present', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      verifyNavTabsExist(tester, 'student');
    });

    testWidgets('Nav tab: Attendance navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Attendance');
      expect(find.textContaining('Attendance'), findsWidgets);
    });

    testWidgets('Nav tab: Results navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Results');
      expect(find.textContaining('Result'), findsWidgets);
    });

    testWidgets('Nav tab: Messages navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Messages');
      expect(find.textContaining('Message'), findsWidgets);
    });

    // ──────────────── P1: Known Issues Audit ──────────────────────────

    testWidgets('AUDIT: rank always shows "--" (known missing feature)',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final rankDash = find.text('--');
      if (rankDash.evaluate().isNotEmpty) {
        // ignore: avoid_print
        print(
          'CONFIRMED: Student rank shows "--" — '
          'feature not implemented. See student_dashboard_screen.dart',
        );
      }
    });

    testWidgets('AUDIT: schedule card uses hardcoded data', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Known hardcoded subjects in _TodayScheduleCard
      final hasMath = find.textContaining('Mathematics');
      final hasPhysics = find.textContaining('Physics');
      final hasChem = find.textContaining('Chemistry');

      if (hasMath.evaluate().isNotEmpty &&
          hasPhysics.evaluate().isNotEmpty &&
          hasChem.evaluate().isNotEmpty) {
        // ignore: avoid_print
        print(
          'BUG CONFIRMED: Student schedule is hardcoded — '
          'Mathematics, Physics, Chemistry. '
          'See student_dashboard_screen.dart:_TodayScheduleCard',
        );
      }
    });

    testWidgets('AUDIT: dead "View All" button', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final deadButtons = findDeadButtons(tester);

      if (deadButtons.isNotEmpty) {
        // ignore: avoid_print
        print('=== DEAD BUTTONS ON STUDENT DASHBOARD ===');
        for (final btn in deadButtons) {
          // ignore: avoid_print
          print('  - $btn');
        }
        // ignore: avoid_print
        print(
          'Known: "View All" at student_dashboard_screen.dart:537',
        );
      }
    });

    // ──────────────── P2: Feature Screens ──────────────────────────

    testWidgets('"More" overflow opens with Library, Canteen, etc.',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await openMoreSheet(tester);
      expect(find.text('Library'), findsWidgets);
      expect(find.text('Canteen'), findsWidgets);
    });

    // ─────────────────── Auth Verification ─────────────────────────

    test('Student role is correctly detected', () {
      expect(currentUserRole, 'student');
      expect(currentTenantId, isNotNull);
    });
  });
}
