import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:school_management/core/services/ai_text_generator.dart';
import 'package:school_management/core/services/deepseek_service.dart';

class MockDeepSeekService extends Mock implements DeepSeekService {}

void main() {
  late MockDeepSeekService mockService;

  setUp(() {
    mockService = MockDeepSeekService();
  });

  group('AITextGenerator — null service fallback', () {
    test('returns fallback when service is null', () async {
      const generator = AITextGenerator();

      final result = await generator.generateStudyPlan(
        studentName: 'Alice',
        subjectPerformance: {'Math': 80},
        attendancePercent: 90,
        fallback: 'Use flashcards.',
      );

      expect(result.text, 'Use flashcards.');
      expect(result.isLLMGenerated, isFalse);
    });

    test('all methods return fallback when service is null', () async {
      const generator = AITextGenerator();

      final digest = await generator.generateDigestSummary(
        studentName: 'Bob',
        presentDays: 4,
        totalDays: 5,
        highlights: ['Got A in Math'],
        fallback: 'Good week.',
      );
      expect(digest.text, 'Good week.');
      expect(digest.isLLMGenerated, isFalse);

      final risk = await generator.generateRiskExplanation(
        studentName: 'Bob',
        riskLevel: 'high',
        overallScore: 80,
        attendanceScore: 60,
        academicScore: 70,
        feeScore: 50,
        engagementScore: 40,
        flags: ['Low attendance'],
        fallback: 'Risk explanation.',
      );
      expect(risk.text, 'Risk explanation.');

      final schoolHealth = await generator.generateSchoolHealthNarrative(
        attendancePercent: 92,
        feeCollectionRate: 85,
        riskDistribution: {'high': 3, 'medium': 10},
        totalStudents: 500,
        fallback: 'School is healthy.',
      );
      expect(schoolHealth.text, 'School is healthy.');

      final platformHealth = await generator.generatePlatformHealthNarrative(
        tenantCount: 5,
        totalStudents: 2000,
        activePercent: 80,
        monthlyRevenue: 50000,
        fallback: 'Platform is stable.',
      );
      expect(platformHealth.text, 'Platform is stable.');
    });
  });

  group('AITextGenerator — with LLM service', () {
    test('returns LLM result when service succeeds', () async {
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((_) async => 'AI generated study plan.');

      final generator = AITextGenerator(service: mockService);
      final result = await generator.generateStudyPlan(
        studentName: 'Alice',
        subjectPerformance: {'Math': 85},
        attendancePercent: 90,
        fallback: 'Fallback plan.',
      );

      expect(result.text, 'AI generated study plan.');
      expect(result.isLLMGenerated, isTrue);
    });

    test('returns fallback when service throws', () async {
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenThrow(const DeepSeekException('API error', statusCode: 500));

      final generator = AITextGenerator(service: mockService);
      final result = await generator.generateStudyPlan(
        studentName: 'Alice',
        subjectPerformance: {'Math': 85},
        attendancePercent: 90,
        fallback: 'Fallback plan.',
      );

      expect(result.text, 'Fallback plan.');
      expect(result.isLLMGenerated, isFalse);
    });

    test('generateSchoolHealthNarrative passes correct data', () async {
      String? capturedUserPrompt;
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((invocation) async {
        capturedUserPrompt =
            invocation.namedArguments[#userPrompt] as String;
        return 'School health narrative.';
      });

      final generator = AITextGenerator(service: mockService);
      await generator.generateSchoolHealthNarrative(
        attendancePercent: 92.5,
        feeCollectionRate: 85.0,
        riskDistribution: {'high': 3, 'medium': 10, 'low': 50},
        totalStudents: 500,
        fallback: 'fallback',
      );

      expect(capturedUserPrompt, contains('500'));
      expect(capturedUserPrompt, contains('93%'));
      expect(capturedUserPrompt, contains('85%'));
      expect(capturedUserPrompt, contains('high: 3'));
    });

    test('generatePlatformHealthNarrative passes correct data', () async {
      String? capturedUserPrompt;
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((invocation) async {
        capturedUserPrompt =
            invocation.namedArguments[#userPrompt] as String;
        return 'Platform health narrative.';
      });

      final generator = AITextGenerator(service: mockService);
      await generator.generatePlatformHealthNarrative(
        tenantCount: 12,
        totalStudents: 5000,
        activePercent: 78,
        monthlyRevenue: 120000,
        fallback: 'fallback',
      );

      expect(capturedUserPrompt, contains('12'));
      expect(capturedUserPrompt, contains('5000'));
      expect(capturedUserPrompt, contains('78%'));
    });

    test('generateReportRemark includes student name and percentage',
        () async {
      String? capturedUserPrompt;
      when(() => mockService.chatCompletion(
            systemPrompt: any(named: 'systemPrompt'),
            userPrompt: any(named: 'userPrompt'),
            temperature: any(named: 'temperature'),
            maxTokens: any(named: 'maxTokens'),
          )).thenAnswer((invocation) async {
        capturedUserPrompt =
            invocation.namedArguments[#userPrompt] as String;
        return 'Remark for student.';
      });

      final generator = AITextGenerator(service: mockService);
      await generator.generateReportRemark(
        studentName: 'Aarav Sharma',
        attendancePercent: 95,
        averagePercentage: 88,
        fallback: 'fallback',
      );

      expect(capturedUserPrompt, contains('Aarav'));
      expect(capturedUserPrompt, contains('88%'));
      expect(capturedUserPrompt, contains('95%'));
    });
  });

  group('AITextResult', () {
    test('default isLLMGenerated is false', () {
      const result = AITextResult(text: 'hello');
      expect(result.isLLMGenerated, isFalse);
    });

    test('isLLMGenerated can be set to true', () {
      const result = AITextResult(text: 'hello', isLLMGenerated: true);
      expect(result.isLLMGenerated, isTrue);
    });
  });
}
