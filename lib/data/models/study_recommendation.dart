import 'package:flutter/material.dart';

/// Represents a set of personalized study recommendations for a student.
class StudyRecommendation {
  final String studentId;
  final List<RecommendationItem> recommendations;
  final DateTime generatedAt;
  final bool isLLMGenerated;

  const StudyRecommendation({
    required this.studentId,
    required this.recommendations,
    required this.generatedAt,
    this.isLLMGenerated = false,
  });

  factory StudyRecommendation.fromJson(Map<String, dynamic> json) {
    return StudyRecommendation(
      studentId: json['student_id'] as String,
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) =>
                  RecommendationItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
      isLLMGenerated: json['is_llm_generated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'recommendations': recommendations.map((e) => e.toJson()).toList(),
        'generated_at': generatedAt.toIso8601String(),
        'is_llm_generated': isLLMGenerated,
      };
}

/// Priority level for a study recommendation.
enum RecommendationPriority {
  high,
  medium,
  low;

  /// Returns the semantic color for this priority level.
  Color get color {
    switch (this) {
      case RecommendationPriority.high:
        return const Color(0xFFEF4444); // AppColors.error
      case RecommendationPriority.medium:
        return const Color(0xFFF59E0B); // AppColors.warning
      case RecommendationPriority.low:
        return const Color(0xFF22C55E); // AppColors.success
    }
  }

  /// Returns the light background color for this priority level.
  Color get backgroundColor {
    switch (this) {
      case RecommendationPriority.high:
        return const Color(0xFFFEE2E2); // AppColors.errorLight
      case RecommendationPriority.medium:
        return const Color(0xFFFEF3C7); // AppColors.warningLight
      case RecommendationPriority.low:
        return const Color(0xFFDCFCE7); // AppColors.successLight
    }
  }

  /// Returns the representative icon for this priority level.
  IconData get icon {
    switch (this) {
      case RecommendationPriority.high:
        return Icons.priority_high;
      case RecommendationPriority.medium:
        return Icons.info_outline;
      case RecommendationPriority.low:
        return Icons.check_circle_outline;
    }
  }

  /// Returns a human-readable label for this priority.
  String get label {
    switch (this) {
      case RecommendationPriority.high:
        return 'High Priority';
      case RecommendationPriority.medium:
        return 'Medium Priority';
      case RecommendationPriority.low:
        return 'Low Priority';
    }
  }
}

/// A single study recommendation item.
class RecommendationItem {
  final String title;
  final String description;
  final String? subject;
  final RecommendationPriority priority;
  final IconData icon;

  const RecommendationItem({
    required this.title,
    required this.description,
    this.subject,
    this.priority = RecommendationPriority.medium,
    this.icon = Icons.lightbulb_outline,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      subject: json['subject'] as String?,
      priority: RecommendationPriority.values.firstWhere(
        (p) => p.name == (json['priority'] as String? ?? 'medium'),
        orElse: () => RecommendationPriority.medium,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        if (subject != null) 'subject': subject,
        'priority': priority.name,
      };
}
