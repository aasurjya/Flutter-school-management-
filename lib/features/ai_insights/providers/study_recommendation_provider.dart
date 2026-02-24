import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../data/models/study_recommendation.dart';

/// Provider that fetches personalized study recommendations for a student.
///
/// Attempts to generate recommendations via the LLM. If the LLM is
/// unavailable or returns an unparseable response, falls back to a set of
/// curated template recommendations.
final studyRecommendationsProvider =
    FutureProvider.family<StudyRecommendation, String>(
  (ref, studentId) async {
    final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

    // Build context for the LLM.
    // In a future iteration this will pull real exam scores and attendance
    // data from the respective repositories. For now, use representative
    // template data so the feature is functional end-to-end.
    try {
      final result = await aiTextGenerator.generateStudyPlan(
        studentName: 'Student',
        subjectPerformance: {
          'Mathematics': 85.0,
          'Science': 78.0,
          'English': 92.0,
        },
        attendancePercent: 90.0,
        fallback: '',
      );

      if (result.text.isNotEmpty && result.isLLMGenerated) {
        // Parse the LLM response into discrete recommendation items.
        final lines =
            result.text.split('\n').where((l) => l.trim().isNotEmpty).toList();
        final items = <RecommendationItem>[];

        for (final line in lines) {
          final trimmed = line.trim();
          // Skip very short lines that are likely artefacts.
          if (trimmed.length < 10) continue;

          items.add(RecommendationItem(
            title: trimmed.length > 60 ? trimmed.substring(0, 60) : trimmed,
            description: trimmed,
            priority: RecommendationPriority.medium,
          ));
        }

        if (items.isNotEmpty) {
          return StudyRecommendation(
            studentId: studentId,
            recommendations: items,
            generatedAt: DateTime.now(),
            isLLMGenerated: true,
          );
        }
      }
    } catch (_) {
      // LLM call failed -- fall through to template recommendations.
    }

    // Fallback: curated template recommendations.
    return StudyRecommendation(
      studentId: studentId,
      recommendations: const [
        RecommendationItem(
          title: 'Focus on weaker subjects first',
          description:
              'Allocate more study time to subjects where your scores are '
              'below 80%. Use active recall techniques like flashcards and '
              'spaced repetition to reinforce difficult concepts.',
          priority: RecommendationPriority.high,
          icon: Icons.priority_high,
        ),
        RecommendationItem(
          title: 'Maintain regular attendance',
          description:
              'Consistent attendance is strongly correlated with better '
              'academic performance. Try not to miss more than 2 days per '
              'month and always review the material covered on absent days.',
          priority: RecommendationPriority.medium,
          icon: Icons.calendar_today,
        ),
        RecommendationItem(
          title: 'Practice previous year papers',
          description:
              'Solve at least 3 previous year question papers before each '
              'exam to understand the pattern, identify frequently asked '
              'topics, and improve your time management.',
          priority: RecommendationPriority.medium,
          icon: Icons.description,
        ),
        RecommendationItem(
          title: 'Create a daily study schedule',
          description:
              'Plan your study sessions in advance with specific time '
              'blocks for each subject. Include short breaks to maintain '
              'focus and avoid burnout.',
          subject: 'General',
          priority: RecommendationPriority.medium,
          icon: Icons.schedule,
        ),
        RecommendationItem(
          title: 'Join study groups',
          description:
              'Collaborate with classmates for difficult topics. Teaching '
              'others is one of the best ways to solidify your understanding '
              'and discover gaps in your own knowledge.',
          priority: RecommendationPriority.low,
          icon: Icons.group,
        ),
      ],
      generatedAt: DateTime.now(),
    );
  },
);
