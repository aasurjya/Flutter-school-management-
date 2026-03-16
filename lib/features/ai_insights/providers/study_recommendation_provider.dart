import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../data/models/study_recommendation.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../exams/providers/exams_provider.dart';
import '../../students/providers/students_provider.dart';

/// Provider that fetches personalized study recommendations for a student.
///
/// Fetches real exam performance and attendance data, then attempts to
/// generate recommendations via the LLM. Falls back to curated templates
/// if data or LLM is unavailable.
final studyRecommendationsProvider =
    FutureProvider.family<StudyRecommendation, String>(
  (ref, studentId) async {
    final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

    // Resolve the student record from userId to get the DB student id.
    final studentRepo = ref.watch(studentRepositoryProvider);
    final student = await studentRepo.getStudentByUserId(studentId);

    String studentName = 'Student';
    Map<String, double> subjectPerformance = {};
    double attendancePercent = 0;

    if (student != null) {
      studentName = student.fullName;

      // Fetch real exam performance data.
      final examRepo = ref.watch(examRepositoryProvider);
      try {
        final performances = await examRepo.getStudentPerformance(
          studentId: student.id,
        );

        // Build subject performance map — average percentage per subject
        // across all exams.
        final subjectTotals = <String, List<double>>{};
        for (final perf in performances) {
          if (!perf.isAbsent) {
            subjectTotals
                .putIfAbsent(perf.subjectName, () => [])
                .add(perf.percentage);
          }
        }
        subjectPerformance = {
          for (final entry in subjectTotals.entries)
            entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length,
        };
      } catch (_) {
        // Exam data unavailable — proceed with empty map.
      }

      // Fetch real attendance stats.
      final attendanceRepo = ref.watch(attendanceRepositoryProvider);
      try {
        final stats = await attendanceRepo.getAttendanceStats(
          studentId: student.id,
        );
        attendancePercent = (stats['attendance_percentage'] ?? 0).toDouble();
      } catch (_) {
        // Attendance data unavailable — proceed with 0.
      }
    }

    // Attempt LLM generation with real data.
    if (subjectPerformance.isNotEmpty) {
      try {
        final result = await aiTextGenerator.generateStudyPlan(
          studentName: studentName,
          subjectPerformance: subjectPerformance,
          attendancePercent: attendancePercent,
          fallback: '',
        );

        if (result.text.isNotEmpty && result.isLLMGenerated) {
          final lines = result.text
              .split('\n')
              .where((l) => l.trim().isNotEmpty)
              .toList();
          final items = <RecommendationItem>[];

          for (final line in lines) {
            final trimmed = line.trim();
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
        // LLM call failed — fall through to template recommendations.
      }
    }

    // Build context-aware fallback using real subject data.
    final weakSubjects = subjectPerformance.entries
        .where((e) => e.value < 80)
        .map((e) => e.key)
        .toList();

    final strongSubjects = subjectPerformance.entries
        .where((e) => e.value >= 85)
        .map((e) => e.key)
        .toList();

    return StudyRecommendation(
      studentId: studentId,
      recommendations: [
        if (weakSubjects.isNotEmpty)
          RecommendationItem(
            title: 'Focus on ${weakSubjects.take(2).join(" & ")}',
            description:
                'Your scores in ${weakSubjects.join(", ")} are below 80%. '
                'Allocate more study time to these subjects using active recall '
                'techniques like flashcards and spaced repetition.',
            priority: RecommendationPriority.high,
            icon: Icons.priority_high,
          )
        else
          const RecommendationItem(
            title: 'Focus on weaker subjects first',
            description:
                'Allocate more study time to subjects where your scores are '
                'below 80%. Use active recall techniques like flashcards and '
                'spaced repetition to reinforce difficult concepts.',
            priority: RecommendationPriority.high,
            icon: Icons.priority_high,
          ),
        if (strongSubjects.isNotEmpty)
          RecommendationItem(
            title: 'Strength: ${strongSubjects.first}',
            description:
                'Great work in ${strongSubjects.join(", ")}! Consider helping '
                'classmates in these subjects — teaching others solidifies your '
                'own understanding.',
            priority: RecommendationPriority.low,
            icon: Icons.star,
          ),
        if (attendancePercent > 0 && attendancePercent < 90)
          RecommendationItem(
            title: 'Improve attendance (${attendancePercent.round()}%)',
            description:
                'Your attendance is ${attendancePercent.round()}%. Consistent '
                'attendance is strongly correlated with better academic '
                'performance. Try not to miss more than 2 days per month.',
            priority: RecommendationPriority.medium,
            icon: Icons.calendar_today,
          )
        else
          const RecommendationItem(
            title: 'Maintain regular attendance',
            description:
                'Consistent attendance is strongly correlated with better '
                'academic performance. Try not to miss more than 2 days per '
                'month and always review the material covered on absent days.',
            priority: RecommendationPriority.medium,
            icon: Icons.calendar_today,
          ),
        const RecommendationItem(
          title: 'Practice previous year papers',
          description:
              'Solve at least 3 previous year question papers before each '
              'exam to understand the pattern, identify frequently asked '
              'topics, and improve your time management.',
          priority: RecommendationPriority.medium,
          icon: Icons.description,
        ),
        const RecommendationItem(
          title: 'Create a daily study schedule',
          description:
              'Plan your study sessions in advance with specific time '
              'blocks for each subject. Include short breaks to maintain '
              'focus and avoid burnout.',
          subject: 'General',
          priority: RecommendationPriority.medium,
          icon: Icons.schedule,
        ),
      ],
      generatedAt: DateTime.now(),
    );
  },
);
