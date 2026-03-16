/// End-to-end integration tests for AI features.
///
/// These tests run the full widget tree with mocked providers,
/// verifying that AI cards render correctly across all role dashboards.
///
/// Run via:
///   flutter test integration_test/ai_features_test.dart -d chrome
///   flutter test integration_test/ai_features_test.dart -d macos
library ai_features_test;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:school_management/core/providers/ai_providers.dart';
import 'package:school_management/core/services/ai_staff_text_generator.dart';
import 'package:school_management/core/services/ai_text_generator.dart';
// Use basic ThemeData instead of AppTheme to avoid Google Fonts HTTP calls
// in sandboxed macOS/Chrome integration tests.
import 'package:school_management/features/ai_insights/presentation/widgets/admin_ai_narrative_card.dart';
import 'package:school_management/features/ai_insights/presentation/widgets/platform_ai_health_card.dart';
import 'package:school_management/features/ai_insights/presentation/widgets/staff_ai_insight_card.dart';
import 'package:school_management/features/ai_insights/providers/fee_insight_provider.dart';
import 'package:school_management/features/ai_insights/providers/hostel_insight_provider.dart';
import 'package:school_management/features/ai_insights/providers/library_insight_provider.dart';
import 'package:school_management/features/ai_insights/providers/school_health_provider.dart';
import 'package:school_management/features/ai_insights/providers/transport_insight_provider.dart';
import 'package:school_management/features/ai_insights/providers/visitor_insight_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Helper: wraps a widget in MaterialApp + ProviderScope with AI overrides.
  Widget wrapWithApp(Widget child) {
    return ProviderScope(
      overrides: [
        aiTextGeneratorProvider.overrideWithValue(const AITextGenerator()),
        aiStaffTextGeneratorProvider
            .overrideWithValue(const AIStaffTextGenerator()),
      ],
      child: MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  // ─── 1. AdminAINarrativeCard E2E ─────────────────────────────────────────

  group('E2E: AdminAINarrativeCard', () {
    testWidgets('renders school health summary with fallback text',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiTextGeneratorProvider
                .overrideWithValue(const AITextGenerator()),
            schoolHealthNarrativeProvider.overrideWith(
              (ref) async => const AITextResult(
                text:
                    'Today\'s school attendance is 92%. Fee collection is on track. No critical alerts.',
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(body: AdminAINarrativeCard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify card structure.
      expect(find.text('School Health Summary'), findsOneWidget);
      expect(find.textContaining('92%'), findsOneWidget);
      expect(find.byIcon(Icons.health_and_safety_outlined), findsOneWidget);
    });

    testWidgets('shows AI badge when LLM-generated', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolHealthNarrativeProvider.overrideWith(
              (ref) async => const AITextResult(
                text: 'AI-powered school health narrative.',
                isLLMGenerated: true,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(body: AdminAINarrativeCard()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AI-generated insight'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
    });
  });

  // ─── 2. PlatformAIHealthCard E2E ─────────────────────────────────────────

  group('E2E: PlatformAIHealthCard', () {
    testWidgets('renders platform stats in fallback mode', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const PlatformAIHealthCard(tenantCount: 12, totalUsers: 5000),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Platform AI Health'), findsOneWidget);
      expect(find.textContaining('12'), findsWidgets);
      expect(find.textContaining('5000'), findsWidgets);
      expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
    });

    testWidgets('renders empty state when no tenants', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const PlatformAIHealthCard(tenantCount: 0, totalUsers: 0),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Platform AI Health'), findsOneWidget);
      // Should show fallback text about 0 tenants.
      expect(find.textContaining('0'), findsWidgets);
    });
  });

  // ─── 3. StaffAIInsightCard E2E — all 6 roles ────────────────────────────

  group('E2E: StaffAIInsightCard — Fee (Accountant)', () {
    testWidgets('renders fee insight with overdue data', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        StaffAIInsightCard(
          provider: feeInsightProvider(
            const FeeInsightInput(
              overdueCount: 7,
              totalBilled: 500000,
              totalCollected: 400000,
            ),
          ),
          title: 'Fee Insight',
          icon: Icons.account_balance_wallet_outlined,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Fee Insight'), findsOneWidget);
      expect(find.textContaining('7'), findsWidgets);
      expect(find.textContaining('overdue'), findsOneWidget);
    });
  });

  group('E2E: StaffAIInsightCard — Library (Librarian)', () {
    testWidgets('renders library insight with issued count', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        StaffAIInsightCard(
          provider: libraryInsightProvider(
            const LibraryInsightInput(
              popularGenres: ['Fiction', 'Science'],
              totalIssued: 15,
              overdueReturns: 4,
              catalogSize: 2000,
            ),
          ),
          title: 'Library Insight',
          icon: Icons.auto_stories_outlined,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Library Insight'), findsOneWidget);
      expect(find.textContaining('15'), findsWidgets);
      expect(find.textContaining('4'), findsWidgets);
    });
  });

  group('E2E: StaffAIInsightCard — Transport', () {
    testWidgets('renders transport insight with route data', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        StaffAIInsightCard(
          provider: transportInsightProvider(
            const TransportInsightInput(
              activeRoutes: 10,
              capacityPercent: 82,
              totalVehicles: 15,
              activeTrips: 8,
            ),
          ),
          title: 'Transport Insight',
          icon: Icons.directions_bus_outlined,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Transport Insight'), findsOneWidget);
      expect(find.textContaining('10'), findsWidgets);
    });
  });

  group('E2E: StaffAIInsightCard — Hostel', () {
    testWidgets('renders hostel insight with occupancy', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        StaffAIInsightCard(
          provider: hostelInsightProvider(
            const HostelInsightInput(
              occupancyPercent: 88,
              availableBeds: 12,
              maintenanceRequests: 2,
              totalHostels: 3,
            ),
          ),
          title: 'Hostel Insight',
          icon: Icons.hotel_outlined,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Hostel Insight'), findsOneWidget);
      expect(find.textContaining('88'), findsWidgets);
    });
  });

  group('E2E: StaffAIInsightCard — Visitor (Receptionist)', () {
    testWidgets('renders visitor insight with daily count', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        StaffAIInsightCard(
          provider: visitorInsightProvider(
            const VisitorInsightInput(
              dailyVisitorCount: 20,
              onPremises: 8,
              preRegistrations: 5,
              checkedOut: 12,
            ),
          ),
          title: 'Visitor Insight',
          icon: Icons.badge_outlined,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Visitor Insight'), findsOneWidget);
      expect(find.textContaining('20'), findsWidgets);
    });
  });

  // ─── 4. Card interaction tests ───────────────────────────────────────────

  group('E2E: Card interactions', () {
    testWidgets('AI card is scrollable within a list of cards',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiTextGeneratorProvider
                .overrideWithValue(const AITextGenerator()),
            aiStaffTextGeneratorProvider
                .overrideWithValue(const AIStaffTextGenerator()),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ListView(
                children: [
                  const SizedBox(height: 800), // Push card below fold.
                  StaffAIInsightCard(
                    provider: feeInsightProvider(
                      const FeeInsightInput(
                        overdueCount: 3,
                        totalBilled: 100000,
                        totalCollected: 80000,
                      ),
                    ),
                    title: 'Scrollable Fee Card',
                    icon: Icons.account_balance,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card should not be visible before scrolling.
      expect(find.text('Scrollable Fee Card'), findsNothing);

      // Scroll down to reveal the card.
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();

      expect(find.text('Scrollable Fee Card'), findsOneWidget);
    });

    testWidgets('multiple AI cards render in a Column without overflow',
        (tester) async {
      await tester.pumpWidget(wrapWithApp(
        Column(
          children: [
            StaffAIInsightCard(
              provider: feeInsightProvider(
                const FeeInsightInput(
                  overdueCount: 2,
                  totalBilled: 50000,
                  totalCollected: 40000,
                ),
              ),
              title: 'Card 1',
              icon: Icons.one_k,
            ),
            const SizedBox(height: 16),
            StaffAIInsightCard(
              provider: libraryInsightProvider(
                const LibraryInsightInput(
                  popularGenres: ['Fiction'],
                  totalIssued: 5,
                  overdueReturns: 1,
                  catalogSize: 500,
                ),
              ),
              title: 'Card 2',
              icon: Icons.two_k,
            ),
          ],
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Card 1'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
      // No overflow errors.
      expect(tester.takeException(), isNull);
    });
  });

  // ─── 5. Edge cases ───────────────────────────────────────────────────────

  group('E2E: Edge cases', () {
    testWidgets('zero-value inputs do not crash', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        StaffAIInsightCard(
          provider: feeInsightProvider(
            const FeeInsightInput(
              overdueCount: 0,
              totalBilled: 0,
              totalCollected: 0,
            ),
          ),
          title: 'Zero Fee Card',
          icon: Icons.money_off,
        ),
      ));

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Zero Fee Card'), findsOneWidget);
    });

    testWidgets('large numbers render without overflow', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        StaffAIInsightCard(
          provider: feeInsightProvider(
            const FeeInsightInput(
              overdueCount: 99999,
              totalBilled: 999999999,
              totalCollected: 888888888,
            ),
          ),
          title: 'Large Numbers',
          icon: Icons.numbers,
        ),
      ));

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Large Numbers'), findsOneWidget);
    });

    testWidgets('platform card with huge tenant count', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const PlatformAIHealthCard(tenantCount: 10000, totalUsers: 500000),
      ));

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Platform AI Health'), findsOneWidget);
    });
  });
}
