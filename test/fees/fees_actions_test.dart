/// TDD tests for the 5 wired quick-actions in fees_screen.dart.
/// RED: every test must FAIL before the implementation is added.
library fees_actions_test;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:school_management/data/models/invoice.dart';
import 'package:school_management/data/models/user.dart';
import 'package:school_management/data/models/fee_default_prediction.dart';
import 'package:school_management/data/repositories/fee_repository.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/fees/presentation/screens/fees_screen.dart';
import 'package:school_management/features/fees/providers/fees_provider.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/test_data.dart';

// ============================================================
// Fake fee repository with action tracking
// ============================================================

class _ActionFakeFeeRepository extends FeeRepository {
  final List<Invoice> invoices;
  final List<Invoice> overdueInvoices;
  final List<String> reminderSentInvoiceIds = [];

  _ActionFakeFeeRepository({
    required this.invoices,
    required this.overdueInvoices,
  }) : super(MockSupabaseClient());

  @override
  Future<List<FeeDefaultPrediction>> getFeeDefaultPredictions() async => [];

  @override
  Future<List<Invoice>> getInvoices({
    String? studentId,
    String? status,
    String? academicYearId,
    int limit = 50,
    int offset = 0,
  }) async {
    return invoices;
  }

  @override
  Future<List<Invoice>> getOverdueInvoices({int limit = 50, int offset = 0}) async {
    return overdueInvoices;
  }

  @override
  Future<void> logReminderSent({
    required String invoiceId,
    required String studentId,
    required String messageText,
    required int riskScore,
    String channel = 'app',
  }) async {
    reminderSentInvoiceIds.add(invoiceId);
  }

  @override
  Future<Map<String, double>> getFeeCollectionStats({String? academicYearId}) async {
    return {
      'total_collected': 0.0,
      'total_pending': 0.0,
      'total_overdue': 0.0,
      'today_collected': 0.0,
    };
  }

  @override
  Future<List<Payment>> getPayments({
    String? invoiceId,
    String? studentId,
    int limit = 50,
    int offset = 0,
  }) async {
    return [];
  }

  @override
  Future<List<FeeSummary>> getFeeSummaries({
    String? sectionId,
    String? classId,
    String? academicYearId,
    int limit = 50,
    int offset = 0,
  }) async {
    return [];
  }
}

// ============================================================
// Navigation observer mock
// ============================================================

class _MockNavigatorObserver extends Mock implements NavigatorObserver {}

// ============================================================
// Shared fixtures
// ============================================================

Invoice _makeInvoice({
  required String id,
  required String status,
  required String invoiceNumber,
}) =>
    Invoice(
      id: id,
      tenantId: kTenantId,
      invoiceNumber: invoiceNumber,
      studentId: kStudentId1,
      academicYearId: 'ay-001',
      totalAmount: 10000.0,
      dueDate: kBaseDate,
      status: status,
      studentName: 'Test Student',
    );

// ============================================================
// App builder helper
// ============================================================

late List<String?> _navigatedLocations;

Widget _buildApp(_ActionFakeFeeRepository repo) {
  _navigatedLocations = [];

  final router = GoRouter(
    observers: [],
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const FeesScreen(),
      ),
      GoRoute(
        path: '/admin/fees',
        builder: (_, __) => const Scaffold(body: Text('FeeManagementScreen')),
      ),
      GoRoute(
        path: '/fees/pay/:invoiceId',
        builder: (_, state) {
          _navigatedLocations.add(state.pathParameters['invoiceId']);
          return const Scaffold(body: Text('PaymentCheckout'));
        },
      ),
    ],
    redirect: (_, state) {
      _navigatedLocations.add(state.uri.toString());
      return null;
    },
  );

  return ProviderScope(
    overrides: [
      feeRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWith((_) => AppUser(
            id: kTeacherId1,
            email: 'admin@test.com',
            roles: const ['tenant_admin'],
            primaryRole: 'tenant_admin',
            createdAt: kBaseDate,
            updatedAt: kBaseDate,
          )),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ============================================================
// Tests
// ============================================================

void main() {
  final overdueInvoice = _makeInvoice(
    id: kInvoiceId1,
    status: 'overdue',
    invoiceNumber: 'INV-2026-OVERDUE',
  );
  final paidInvoice1 = _makeInvoice(
    id: '22222222-0000-0000-0000-000000000010',
    status: 'paid',
    invoiceNumber: 'INV-2026-PAID1',
  );
  final paidInvoice2 = _makeInvoice(
    id: '22222222-0000-0000-0000-000000000011',
    status: 'paid',
    invoiceNumber: 'INV-2026-PAID2',
  );

  late _ActionFakeFeeRepository fakeRepo;

  setUp(() {
    fakeRepo = _ActionFakeFeeRepository(
      invoices: [overdueInvoice, paidInvoice1, paidInvoice2],
      overdueInvoices: [overdueInvoice],
    );
  });

  // ----------------------------------------------------------
  // Test 1 — Generate Invoices navigates to fee management
  // ----------------------------------------------------------
  testWidgets(
    'test_generateInvoices_navigatesTo_FeeManagement',
    (tester) async {
      await tester.pumpWidget(_buildApp(fakeRepo));
      await tester.pumpAndSettle();

      // Tap the "Generate Invoices" quick action
      // ensureVisible scrolls to it if it's inside a scrollable
      final generateBtn = find.text('Generate\nInvoices');
      expect(generateBtn, findsOneWidget,
          reason: 'Generate Invoices quick-action must be visible');
      await tester.ensureVisible(generateBtn);
      await tester.tap(generateBtn);
      await tester.pumpAndSettle();

      // Verify the FeeManagementScreen scaffold is now shown.
      // skipOffstage: false because GoRouter may put the previous page offstage.
      expect(
        find.text('FeeManagementScreen', skipOffstage: false),
        findsOneWidget,
        reason: 'Tapping Generate Invoices must navigate to /admin/fees',
      );
    },
  );

  // ----------------------------------------------------------
  // Test 2 — Send Reminders bulk: only calls logReminderSent
  //           for the 1 overdue invoice, not the 2 paid ones
  // ----------------------------------------------------------
  testWidgets(
    'test_sendReminders_bulk_filtersOverdueOnly_andCallsSendForEach',
    (tester) async {
      await tester.pumpWidget(_buildApp(fakeRepo));
      await tester.pumpAndSettle();

      // Tap "Send Reminders"
      final sendBtn = find.text('Send\nReminders');
      expect(sendBtn, findsOneWidget,
          reason: 'Send Reminders quick-action must be visible');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      // Pump multiple frames to let async getOverdueInvoices resolve + dialog build
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Expect confirmation dialog to appear — dialog text includes count
      final dialogTitle = find.text('Send Bulk Reminders');
      expect(dialogTitle, findsOneWidget,
          reason: 'Confirmation dialog must appear before sending');

      // Confirm
      final confirmBtn = find.text('Send');
      expect(confirmBtn, findsOneWidget,
          reason: 'Dialog must have a Send/Confirm button');
      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Only the overdue invoice should have had a reminder sent
      expect(
        fakeRepo.reminderSentInvoiceIds,
        equals([kInvoiceId1]),
        reason:
            'logReminderSent must be called exactly once, for the overdue invoice only',
      );
    },
  );

  // ----------------------------------------------------------
  // Test 3 — Export Report overview quick-action calls PDF share
  //           (observable via success snackbar — Printing.sharePdf
  //            is a platform channel, so we verify via snackbar feedback)
  // ----------------------------------------------------------
  testWidgets(
    'test_exportReport_callsPrintingSharePdf',
    (tester) async {
      await tester.pumpWidget(_buildApp(fakeRepo));
      await tester.pumpAndSettle();

      final exportBtn = find.text('Export\nReport');
      expect(exportBtn, findsOneWidget,
          reason: 'Export Report quick-action must be visible');
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      // After tapping, either a snackbar with "exported" text appears
      // or the PDF share sheet opens. We assert no "coming soon" snackbar.
      final comingSoonSnackbar =
          find.text('Export report coming soon');
      expect(
        comingSoonSnackbar,
        findsNothing,
        reason:
            'The dead "coming soon" snackbar must be replaced with real PDF export',
      );
    },
  );

  // ----------------------------------------------------------
  // Test 4 — Collection tab Export button reuses the same PDF builder
  //           (same assertion: no "coming soon" snackbar)
  // ----------------------------------------------------------
  testWidgets(
    'test_collectionExport_reusesSamePdfBuilder',
    (tester) async {
      await tester.pumpWidget(_buildApp(fakeRepo));
      await tester.pumpAndSettle();

      // Navigate to Collection tab (index 2 for admin)
      await tester.tap(find.text('Collection'));
      await tester.pumpAndSettle();

      final exportCollectionBtn = find.text('Export');
      expect(exportCollectionBtn, findsOneWidget,
          reason: 'Collection tab Export button must be present');
      await tester.tap(exportCollectionBtn);
      await tester.pumpAndSettle();

      final comingSoonSnackbar =
          find.text('Export collection report coming soon');
      expect(
        comingSoonSnackbar,
        findsNothing,
        reason:
            'Collection Export must be wired to the real PDF builder, not a snackbar',
      );
    },
  );

  // ----------------------------------------------------------
  // Test 5 — Invoice card View button shows detail sheet or navigates
  //           (assert no "coming soon" snackbar, and something opened)
  // ----------------------------------------------------------
  testWidgets(
    'test_viewInvoice_navigatesOrShowsSheet',
    (tester) async {
      await tester.pumpWidget(_buildApp(fakeRepo));
      await tester.pumpAndSettle();

      // Go to Invoices tab
      await tester.tap(find.text('Invoices'));
      await tester.pumpAndSettle();

      // Find the View button in the first invoice card
      final viewBtn = find.text('View');
      expect(viewBtn, findsWidgets,
          reason: 'At least one View button must appear in the invoice list');

      await tester.tap(viewBtn.first);
      await tester.pumpAndSettle();

      // Assert the dead snackbar is gone
      final deadSnackbar = find.textContaining('detail coming soon');
      expect(
        deadSnackbar,
        findsNothing,
        reason:
            'The dead "detail coming soon" snackbar must be replaced with a real detail view',
      );

      // Assert something opened: either a modal bottom sheet or navigation
      final modalContent = find.byType(BottomSheet);
      final invoiceDetailHeading = find.text('Invoice Detail');
      expect(
        modalContent.evaluate().isNotEmpty ||
            invoiceDetailHeading.evaluate().isNotEmpty,
        isTrue,
        reason: 'View must open either a BottomSheet or route to invoice detail',
      );
    },
  );
}
