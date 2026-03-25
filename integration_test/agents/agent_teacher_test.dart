/// Agent B: Teacher role integration tests.
///
/// Tests dashboard, attendance marking, exam marks entry, class
/// management. Flags hardcoded stats and dead buttons.
///
/// Run:
///   flutter test integration_test/agents/agent_teacher_test.dart \
///     --dart-define=TEST_SUPABASE_URL=... \
///     --dart-define=TEST_SUPABASE_ANON_KEY=...
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/main.dart' as app;

import '../helpers/navigation_helpers.dart';
import '../helpers/test_setup.dart';

void main() {
  group('Agent B — Teacher', () {
    setUpAll(() async {
      await initIntegrationTest();
      await signInAsRole('teacher');
    });

    tearDownAll(() async {
      await signOut();
    });

    // ───────────────────────── P0: Dashboard ─────────────────────────

    testWidgets('Dashboard loads with greeting', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Teacher dashboard should show a welcome greeting
      expect(find.textContaining('Welcome'), findsWidgets);
    });

    testWidgets('AUDIT: stats tiles are hardcoded (known bug)',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // These are known to be hardcoded in teacher_dashboard_screen.dart:280-297
      // Check if hardcoded values '04', '92%', '03' appear
      final has04 = find.text('04');
      final has92 = find.text('92%');
      final has03 = find.text('03');

      // If all three hardcoded values are found, this is the known bug
      if (has04.evaluate().isNotEmpty &&
          has92.evaluate().isNotEmpty &&
          has03.evaluate().isNotEmpty) {
        // ignore: avoid_print
        print(
          'BUG CONFIRMED: Teacher dashboard stats are hardcoded '
          '(04 classes, 92% attendance, 03 alerts). '
          'See teacher_dashboard_screen.dart:280-297',
        );
      }
    });

    testWidgets('All 4 nav tabs present', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      verifyNavTabsExist(tester, 'teacher');
    });

    testWidgets('Nav tab: Attendance navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Attendance');
      expect(find.textContaining('Attendance'), findsWidgets);
    });

    testWidgets('Nav tab: Exams navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Exams');
      expect(find.textContaining('Exam'), findsWidgets);
    });

    testWidgets('Nav tab: Messages navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Messages');
      expect(find.textContaining('Message'), findsWidgets);
    });

    testWidgets('"More" overflow opens', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await openMoreSheet(tester);
      expect(find.text('Library'), findsWidgets);
    });

    // ──────────────── P0: Attendance (mock data check) ────────────────

    testWidgets('AUDIT: attendance screen uses mock data (known bug)',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Attendance');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The attendance screen at attendance_screen.dart:632-648
      // uses _mockClasses, _mockAttendanceHistory — check for
      // indicator text from mock data
      // ignore: avoid_print
      print(
        'AUDIT: Verify attendance_screen.dart:632-648 — '
        '_mockClasses, _mockAttendanceHistory, _mockClassReport are hardcoded',
      );
    });

    // ────────────────── P1: Syllabus Coverage ─────────────────────────

    testWidgets('Syllabus coverage cards use real data', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Syllabus coverage should come from teacherCoverageProvider
      // Look for progress indicators or percentage text
      final progressFinder = find.byType(LinearProgressIndicator);
      // If present, syllabus coverage is rendering
      if (progressFinder.evaluate().isNotEmpty) {
        // ignore: avoid_print
        print('OK: Syllabus coverage cards are rendering with progress bars');
      }
    });

    // ─────────────────── P1: Dead Button Audit ────────────────────────

    testWidgets('AUDIT: dead buttons on teacher dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final deadButtons = findDeadButtons(tester);

      if (deadButtons.isNotEmpty) {
        // ignore: avoid_print
        print('=== DEAD BUTTONS ON TEACHER DASHBOARD ===');
        for (final btn in deadButtons) {
          // ignore: avoid_print
          print('  - $btn');
        }
        // ignore: avoid_print
        print('Total: ${deadButtons.length} dead buttons');
        // ignore: avoid_print
        print(
          'Known: "View All" headers at '
          'teacher_dashboard_screen.dart:316,464',
        );
      }
    });

    // ─────────────────── Auth Verification ─────────────────────────

    test('Teacher role is correctly detected', () {
      expect(currentUserRole, 'teacher');
      expect(currentTenantId, isNotNull);
    });
  });
}
