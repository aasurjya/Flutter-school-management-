import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/core/providers/ai_providers.dart';
import 'package:school_management/core/services/ai_staff_text_generator.dart';
import 'package:school_management/core/services/ai_text_generator.dart';
import 'package:school_management/features/ai_insights/providers/fee_insight_provider.dart';
import 'package:school_management/features/ai_insights/providers/hostel_insight_provider.dart';
import 'package:school_management/features/ai_insights/providers/library_insight_provider.dart';
import 'package:school_management/features/ai_insights/providers/platform_ai_stats_provider.dart';
import 'package:school_management/features/ai_insights/providers/transport_insight_provider.dart';
import 'package:school_management/features/ai_insights/providers/visitor_insight_provider.dart';

void main() {
  // All staff providers use null service (no API key) → fallback path.
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [
      aiTextGeneratorProvider.overrideWithValue(const AITextGenerator()),
      aiStaffTextGeneratorProvider
          .overrideWithValue(const AIStaffTextGenerator()),
    ]);
  });

  tearDown(() => container.dispose());

  group('feeInsightProvider', () {
    test('returns fallback text with overdue count', () async {
      const input = FeeInsightInput(
        overdueCount: 5,
        totalBilled: 100000,
        totalCollected: 80000,
      );

      final result = await container.read(feeInsightProvider(input).future);
      expect(result.text, contains('5'));
      expect(result.text, contains('overdue'));
      expect(result.isLLMGenerated, isFalse);
    });

    test('handles zero values', () async {
      const input = FeeInsightInput(
        overdueCount: 0,
        totalBilled: 0,
        totalCollected: 0,
      );

      final result = await container.read(feeInsightProvider(input).future);
      expect(result.text, isNotEmpty);
    });
  });

  group('libraryInsightProvider', () {
    test('returns fallback text with issued count', () async {
      const input = LibraryInsightInput(
        popularGenres: ['Fiction'],
        totalIssued: 10,
        overdueReturns: 3,
        catalogSize: 500,
      );

      final result =
          await container.read(libraryInsightProvider(input).future);
      expect(result.text, contains('10'));
      expect(result.text, contains('3'));
    });
  });

  group('transportInsightProvider', () {
    test('returns fallback text with route count', () async {
      const input = TransportInsightInput(
        activeRoutes: 8,
        capacityPercent: 75,
        totalVehicles: 12,
        activeTrips: 5,
      );

      final result =
          await container.read(transportInsightProvider(input).future);
      expect(result.text, contains('8'));
      expect(result.text, contains('12'));
    });
  });

  group('hostelInsightProvider', () {
    test('returns fallback text with occupancy', () async {
      const input = HostelInsightInput(
        occupancyPercent: 85,
        availableBeds: 20,
        maintenanceRequests: 3,
        totalHostels: 2,
      );

      final result =
          await container.read(hostelInsightProvider(input).future);
      expect(result.text, contains('85'));
      expect(result.text, contains('20'));
    });

    test('shows no maintenance message when 0 requests', () async {
      const input = HostelInsightInput(
        occupancyPercent: 50,
        availableBeds: 50,
        maintenanceRequests: 0,
        totalHostels: 1,
      );

      final result =
          await container.read(hostelInsightProvider(input).future);
      expect(result.text, contains('No pending'));
    });
  });

  group('visitorInsightProvider', () {
    test('returns fallback text with visitor count', () async {
      const input = VisitorInsightInput(
        dailyVisitorCount: 15,
        onPremises: 5,
        preRegistrations: 3,
        checkedOut: 10,
      );

      final result =
          await container.read(visitorInsightProvider(input).future);
      expect(result.text, contains('15'));
    });

    test('suggests pre-registration when count is 0', () async {
      const input = VisitorInsightInput(
        dailyVisitorCount: 5,
        onPremises: 2,
        preRegistrations: 0,
        checkedOut: 3,
      );

      final result =
          await container.read(visitorInsightProvider(input).future);
      expect(result.text, contains('pre-register'));
    });
  });

  group('platformHealthNarrativeProvider', () {
    test('returns fallback text with tenant count', () async {
      const stats = PlatformStats(
        tenantCount: 5,
        totalStudents: 2000,
        activePercent: 80,
        monthlyRevenue: 50000,
      );

      final result = await container
          .read(platformHealthNarrativeProvider(stats).future);
      expect(result.text, contains('5'));
      expect(result.text, contains('2000'));
    });
  });

  group('Filter equality', () {
    test('FeeInsightInput equality', () {
      const a = FeeInsightInput(
          overdueCount: 5, totalBilled: 100, totalCollected: 80);
      const b = FeeInsightInput(
          overdueCount: 5, totalBilled: 100, totalCollected: 80);
      const c = FeeInsightInput(
          overdueCount: 3, totalBilled: 100, totalCollected: 80);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('PlatformStats equality', () {
      const a = PlatformStats(
        tenantCount: 5,
        totalStudents: 100,
        activePercent: 80,
        monthlyRevenue: 1000,
      );
      const b = PlatformStats(
        tenantCount: 5,
        totalStudents: 100,
        activePercent: 80,
        monthlyRevenue: 1000,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('TransportInsightInput equality', () {
      const a = TransportInsightInput(
        activeRoutes: 8,
        capacityPercent: 75,
        totalVehicles: 12,
        activeTrips: 5,
      );
      const b = TransportInsightInput(
        activeRoutes: 8,
        capacityPercent: 75,
        totalVehicles: 12,
        activeTrips: 5,
      );

      expect(a, equals(b));
    });
  });
}
