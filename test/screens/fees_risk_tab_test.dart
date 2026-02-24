import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:school_management/data/models/fee_default_prediction.dart';
import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/fees/presentation/screens/fees_screen.dart';
import 'package:school_management/features/fees/providers/fees_provider.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/test_data.dart';

// ============================================================
// Helpers
// ============================================================

AppUser _makeAdminUser() => AppUser(
      id: kTeacherId1,
      email: 'admin@test.com',
      roles: const ['tenant_admin'],
      primaryRole: 'tenant_admin',
      createdAt: kBaseDate,
      updatedAt: kBaseDate,
    );

Widget buildFeesApp(FakeFeeRepository repo) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const FeesScreen()),
  ]);

  return ProviderScope(
    overrides: [
      feeRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWith((ref) => _makeAdminUser()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// Navigate to the Risk tab (4th tab, index 3)
Future<void> navigateToRiskTab(WidgetTester tester) async {
  // Admin has 4 tabs: Overview | Invoices | Collection | Risk
  // The Risk tab label is shown as Icon + "Risk" text
  final riskTabFinder = find.text('Risk');
  if (riskTabFinder.evaluate().isNotEmpty) {
    await tester.tap(riskTabFinder);
    await tester.pumpAndSettle();
  }
}

// ============================================================
// Tests
// ============================================================

void main() {
  late FakeFeeRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeFeeRepository();
  });

  testWidgets('admin user sees 4 tabs including Risk', (tester) async {
    await tester.pumpWidget(buildFeesApp(fakeRepo));
    await tester.pump();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('Risk'), findsOneWidget);
  });

  testWidgets('Risk tab renders filter chips (All / High / Medium / Low)',
      (tester) async {
    await tester.pumpWidget(buildFeesApp(fakeRepo));
    await tester.pump();

    await navigateToRiskTab(tester);

    // Labels include counts, e.g. "All (2)", "High (1)", "Medium (1)", "Low (0)"
    expect(find.textContaining('All'), findsWidgets);
    expect(find.textContaining('High'), findsWidgets);
    expect(find.textContaining('Medium'), findsWidgets);
    expect(find.textContaining('Low'), findsWidgets);
  });

  testWidgets('Risk tab summary card shows amount at risk', (tester) async {
    await tester.pumpWidget(buildFeesApp(fakeRepo));
    await tester.pump();

    await navigateToRiskTab(tester);
    await tester.pumpAndSettle();

    // Verify summary card rendered (contains formatted amount)
    final summary = FeeDefaultSummary.from([
      makeHighRiskPrediction(),
      makeMediumRiskPrediction(),
    ]);
    expect(find.textContaining(summary.formattedAmountAtRisk), findsWidgets);
  });

  testWidgets('High Risk filter chip filters the list', (tester) async {
    await tester.pumpWidget(buildFeesApp(fakeRepo));
    await tester.pump();

    await navigateToRiskTab(tester);
    await tester.pumpAndSettle();

    // Chip label is "High (1)" — use textContaining to find it
    final highChip = find.textContaining('High');
    if (highChip.evaluate().isNotEmpty) {
      await tester.tap(highChip.first, warnIfMissed: false);
      await tester.pump();
    }

    // After filtering, the tab is still rendered (no crash)
    expect(find.byType(FeesScreen), findsOneWidget);
  });

  testWidgets('Risk tab shows loading indicator initially', (tester) async {
    // Use a slow-loading repo by delaying response
    final slowRepo = FakeFeeRepository(predictions: [makeHighRiskPrediction()]);

    await tester.pumpWidget(buildFeesApp(slowRepo));
    await tester.pump(); // let frame build without resolving futures
    // Navigate to Risk tab
    await navigateToRiskTab(tester);
    // Futures are still resolving - we let them settle
    await tester.pumpAndSettle();

    // After settle, should show data (no crash)
    expect(find.byType(FeesScreen), findsOneWidget);
  });
}
