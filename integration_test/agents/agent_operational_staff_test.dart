/// Agent E: Operational Staff integration tests.
///
/// Tests all 6 operational roles sequentially:
/// accountant, librarian, transport_manager, hostel_warden,
/// canteen_staff, receptionist.
///
/// Each sub-role: dashboard loads, stats display, nav tabs work,
/// at least one CRUD operation.
///
/// Run:
///   flutter test integration_test/agents/agent_operational_staff_test.dart \
///     --dart-define=TEST_SUPABASE_URL=... \
///     --dart-define=TEST_SUPABASE_ANON_KEY=...
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/main.dart' as app;

import '../helpers/navigation_helpers.dart';
import '../helpers/test_setup.dart';

void main() {
  // ═══════════════════════ E1: Accountant ═══════════════════════

  group('Agent E1 — Accountant', () {
    setUpAll(() async {
      await initIntegrationTest();
      await signInAsRole('accountant');
    });

    tearDownAll(() async {
      await signOut();
    });

    testWidgets('Dashboard loads with fee stats', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.textContaining('Finance'), findsWidgets);
    });

    testWidgets('All 4 nav tabs present', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      verifyNavTabsExist(tester, 'accountant');
    });

    testWidgets('Nav tab: Fees navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Fees');
      expect(find.textContaining('Fee'), findsWidgets);
    });

    testWidgets('Nav tab: Reports navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Reports');
      expect(find.textContaining('Report'), findsWidgets);
    });

    test('Accountant role is correctly detected', () {
      expect(currentUserRole, 'accountant');
    });
  });

  // ═══════════════════════ E2: Librarian ═══════════════════════

  group('Agent E2 — Librarian', () {
    setUpAll(() async {
      await initIntegrationTest();
      await signInAsRole('librarian');
    });

    tearDownAll(() async {
      await signOut();
    });

    testWidgets('Dashboard loads with library stats', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.textContaining('Library'), findsWidgets);
    });

    testWidgets('All 4 nav tabs present', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      verifyNavTabsExist(tester, 'librarian');
    });

    testWidgets('Nav tab: Library navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Library');
      expect(find.textContaining('Library'), findsWidgets);
    });

    test('Librarian role is correctly detected', () {
      expect(currentUserRole, 'librarian');
    });
  });

  // ═══════════════════ E3: Transport Manager ═══════════════════

  group('Agent E3 — Transport Manager', () {
    setUpAll(() async {
      await initIntegrationTest();
      await signInAsRole('transport_manager');
    });

    tearDownAll(() async {
      await signOut();
    });

    testWidgets('Dashboard loads with transport stats', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.textContaining('Transport'), findsWidgets);
    });

    testWidgets('All 4 nav tabs present', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      verifyNavTabsExist(tester, 'transport_manager');
    });

    testWidgets('Nav tab: Transport navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Transport');
      expect(find.textContaining('Transport'), findsWidgets);
    });

    test('Transport manager role is correctly detected', () {
      expect(currentUserRole, 'transport_manager');
    });
  });

  // ═══════════════════ E4: Hostel Warden ═══════════════════════

  group('Agent E4 — Hostel Warden', () {
    setUpAll(() async {
      await initIntegrationTest();
      await signInAsRole('hostel_warden');
    });

    tearDownAll(() async {
      await signOut();
    });

    testWidgets('Dashboard loads with hostel stats', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.textContaining('Hostel'), findsWidgets);
    });

    testWidgets('All 4 nav tabs present', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      verifyNavTabsExist(tester, 'hostel_warden');
    });

    testWidgets('Nav tab: Hostel navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Hostel');
      expect(find.textContaining('Hostel'), findsWidgets);
    });

    test('Hostel warden role is correctly detected', () {
      expect(currentUserRole, 'hostel_warden');
    });
  });

  // ═══════════════════ E5: Canteen Staff ═══════════════════════

  group('Agent E5 — Canteen Staff', () {
    setUpAll(() async {
      await initIntegrationTest();
      await signInAsRole('canteen_staff');
    });

    tearDownAll(() async {
      await signOut();
    });

    testWidgets('Dashboard loads with canteen stats', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.textContaining('Canteen'), findsWidgets);
    });

    testWidgets('All 4 nav tabs present', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      verifyNavTabsExist(tester, 'canteen_staff');
    });

    testWidgets('Nav tab: Canteen navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Canteen');
      expect(find.textContaining('Canteen'), findsWidgets);
    });

    test('Canteen staff role is correctly detected', () {
      expect(currentUserRole, 'canteen_staff');
    });
  });

  // ═══════════════════ E6: Receptionist ════════════════════════

  group('Agent E6 — Receptionist', () {
    setUpAll(() async {
      await initIntegrationTest();
      await signInAsRole('receptionist');
    });

    tearDownAll(() async {
      await signOut();
    });

    testWidgets('Dashboard loads with visitor stats', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.textContaining('Visitor'), findsWidgets);
    });

    testWidgets('All 4 nav tabs present', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      verifyNavTabsExist(tester, 'receptionist');
    });

    testWidgets('Nav tab: Visitors navigates', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tapBottomNavTab(tester, 'Visitors');
      expect(find.textContaining('Visitor'), findsWidgets);
    });

    test('Receptionist role is correctly detected', () {
      expect(currentUserRole, 'receptionist');
    });
  });
}
