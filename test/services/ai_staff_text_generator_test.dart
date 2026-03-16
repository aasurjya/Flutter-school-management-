import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:school_management/core/services/ai_staff_text_generator.dart';
import 'package:school_management/core/services/deepseek_service.dart';

class MockDeepSeekService extends Mock implements DeepSeekService {}

void main() {
  late MockDeepSeekService mockService;

  setUp(() {
    mockService = MockDeepSeekService();
  });

  group('AIStaffTextGenerator — null service fallback', () {
    test('all methods return fallback when service is null', () async {
      const generator = AIStaffTextGenerator();

      final fee = await generator.generateFeeCollectionInsight(
        overdueCount: 5,
        collectionRate: 80,
        totalBilled: 100000,
        totalCollected: 80000,
        fallback: 'Fee fallback.',
      );
      expect(fee.text, 'Fee fallback.');
      expect(fee.isLLMGenerated, isFalse);

      final book = await generator.generateBookRecommendation(
        popularGenres: ['Fiction', 'Science'],
        totalIssued: 10,
        overdueReturns: 3,
        catalogSize: 500,
        fallback: 'Book fallback.',
      );
      expect(book.text, 'Book fallback.');

      final route = await generator.generateRouteInsight(
        activeRoutes: 8,
        capacityPercent: 75,
        totalVehicles: 12,
        activeTrips: 5,
        fallback: 'Route fallback.',
      );
      expect(route.text, 'Route fallback.');

      final hostel = await generator.generateHostelInsight(
        occupancyPercent: 85,
        availableBeds: 20,
        maintenanceRequests: 3,
        totalHostels: 2,
        fallback: 'Hostel fallback.',
      );
      expect(hostel.text, 'Hostel fallback.');

      final visitor = await generator.generateVisitorInsight(
        dailyVisitorCount: 15,
        onPremises: 5,
        preRegistrations: 3,
        checkedOut: 10,
        fallback: 'Visitor fallback.',
      );
      expect(visitor.text, 'Visitor fallback.');
    });
  });

  group('AIStaffTextGenerator — with LLM service', () {
    test('generateFeeCollectionInsight returns LLM result', () async {
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((_) async => 'AI fee insight.');

      final generator = AIStaffTextGenerator(service: mockService);
      final result = await generator.generateFeeCollectionInsight(
        overdueCount: 5,
        collectionRate: 80,
        totalBilled: 100000,
        totalCollected: 80000,
        fallback: 'fallback',
      );

      expect(result.text, 'AI fee insight.');
      expect(result.isLLMGenerated, isTrue);
    });

    test('generateBookRecommendation includes popular genres', () async {
      String? capturedPrompt;
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((inv) async {
        capturedPrompt = inv.namedArguments[#userPrompt] as String;
        return 'Book recommendation.';
      });

      final generator = AIStaffTextGenerator(service: mockService);
      await generator.generateBookRecommendation(
        popularGenres: ['Fiction', 'History'],
        totalIssued: 15,
        overdueReturns: 2,
        catalogSize: 1000,
        fallback: 'fallback',
      );

      expect(capturedPrompt, contains('Fiction'));
      expect(capturedPrompt, contains('History'));
      expect(capturedPrompt, contains('15'));
    });

    test('generateRouteInsight includes capacity percent', () async {
      String? capturedPrompt;
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((inv) async {
        capturedPrompt = inv.namedArguments[#userPrompt] as String;
        return 'Route insight.';
      });

      final generator = AIStaffTextGenerator(service: mockService);
      await generator.generateRouteInsight(
        activeRoutes: 8,
        capacityPercent: 75.5,
        totalVehicles: 12,
        activeTrips: 5,
        fallback: 'fallback',
      );

      expect(capturedPrompt, contains('76%'));
      expect(capturedPrompt, contains('8'));
      expect(capturedPrompt, contains('12'));
    });

    test('generateHostelInsight includes occupancy data', () async {
      String? capturedPrompt;
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((inv) async {
        capturedPrompt = inv.namedArguments[#userPrompt] as String;
        return 'Hostel insight.';
      });

      final generator = AIStaffTextGenerator(service: mockService);
      await generator.generateHostelInsight(
        occupancyPercent: 92,
        availableBeds: 8,
        maintenanceRequests: 5,
        totalHostels: 3,
        fallback: 'fallback',
      );

      expect(capturedPrompt, contains('92%'));
      expect(capturedPrompt, contains('8'));
      expect(capturedPrompt, contains('5'));
    });

    test('generateVisitorInsight includes visitor counts', () async {
      String? capturedPrompt;
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((inv) async {
        capturedPrompt = inv.namedArguments[#userPrompt] as String;
        return 'Visitor insight.';
      });

      final generator = AIStaffTextGenerator(service: mockService);
      await generator.generateVisitorInsight(
        dailyVisitorCount: 25,
        onPremises: 8,
        preRegistrations: 5,
        checkedOut: 17,
        fallback: 'fallback',
      );

      expect(capturedPrompt, contains('25'));
      expect(capturedPrompt, contains('8'));
      expect(capturedPrompt, contains('5'));
    });

    test('returns fallback when service throws', () async {
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenThrow(Exception('Network error'));

      final generator = AIStaffTextGenerator(service: mockService);
      final result = await generator.generateFeeCollectionInsight(
        overdueCount: 5,
        collectionRate: 80,
        totalBilled: 100000,
        totalCollected: 80000,
        fallback: 'Fee fallback on error.',
      );

      expect(result.text, 'Fee fallback on error.');
      expect(result.isLLMGenerated, isFalse);
    });
  });
}
