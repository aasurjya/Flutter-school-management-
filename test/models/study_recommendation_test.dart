import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/data/models/study_recommendation.dart';

void main() {
  group('RecommendationPriority', () {
    test('high priority has correct color, icon, and label', () {
      expect(RecommendationPriority.high.label, 'High Priority');
      expect(RecommendationPriority.high.color, const Color(0xFFEF4444));
      expect(RecommendationPriority.high.icon, Icons.priority_high);
      expect(
          RecommendationPriority.high.backgroundColor, const Color(0xFFFEE2E2));
    });

    test('medium priority has correct color and label', () {
      expect(RecommendationPriority.medium.label, 'Medium Priority');
      expect(RecommendationPriority.medium.color, const Color(0xFFF59E0B));
      expect(RecommendationPriority.medium.icon, Icons.info_outline);
    });

    test('low priority has correct color and label', () {
      expect(RecommendationPriority.low.label, 'Low Priority');
      expect(RecommendationPriority.low.color, const Color(0xFF22C55E));
      expect(RecommendationPriority.low.icon, Icons.check_circle_outline);
    });
  });

  group('RecommendationItem', () {
    test('fromJson / toJson roundtrip', () {
      const item = RecommendationItem(
        title: 'Focus on Math',
        description: 'Score below 80%.',
        subject: 'Mathematics',
        priority: RecommendationPriority.high,
        icon: Icons.priority_high,
      );

      final json = item.toJson();
      final restored = RecommendationItem.fromJson(json);

      expect(restored.title, 'Focus on Math');
      expect(restored.description, 'Score below 80%.');
      expect(restored.subject, 'Mathematics');
      expect(restored.priority, RecommendationPriority.high);
    });

    test('fromJson uses medium priority as default', () {
      final item = RecommendationItem.fromJson({
        'title': 'Test',
        'description': 'Desc',
      });

      expect(item.priority, RecommendationPriority.medium);
    });

    test('fromJson handles missing fields gracefully', () {
      final item = RecommendationItem.fromJson({
        'title': 'Test',
        'description': 'Desc',
        'subject': null,
      });

      expect(item.subject, isNull);
    });
  });

  group('StudyRecommendation', () {
    test('fromJson / toJson roundtrip', () {
      final rec = StudyRecommendation(
        studentId: 'student-001',
        recommendations: const [
          RecommendationItem(
            title: 'Study more',
            description: 'Spend extra time.',
            priority: RecommendationPriority.medium,
          ),
        ],
        generatedAt: DateTime(2026, 3, 16),
        isLLMGenerated: true,
      );

      final json = rec.toJson();
      final restored = StudyRecommendation.fromJson(json);

      expect(restored.studentId, 'student-001');
      expect(restored.recommendations, hasLength(1));
      expect(restored.isLLMGenerated, isTrue);
    });

    test('default isLLMGenerated is false', () {
      final rec = StudyRecommendation(
        studentId: 'student-001',
        recommendations: const [],
        generatedAt: DateTime.now(),
      );

      expect(rec.isLLMGenerated, isFalse);
    });
  });
}
