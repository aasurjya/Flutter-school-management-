import 'package:flutter/material.dart';

class StudentRiskScore {
  final String id;
  final String studentId;
  final String academicYearId;
  final double overallRiskScore;
  final String riskLevel;
  final double attendanceScore;
  final double academicScore;
  final double feeScore;
  final double engagementScore;
  final double? previousScore;
  final String scoreTrend;
  final List<String> flags;
  final List<String> recommendedActions;
  final DateTime? computedAt;
  // Joined student info
  final String? studentName;
  final String? admissionNumber;
  final String? className;
  final String? sectionName;
  // LLM-generated explanation (null if not yet enriched)
  final String? riskExplanation;

  const StudentRiskScore({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.overallRiskScore,
    required this.riskLevel,
    this.attendanceScore = 0,
    this.academicScore = 0,
    this.feeScore = 0,
    this.engagementScore = 0,
    this.previousScore,
    this.scoreTrend = 'stable',
    this.flags = const [],
    this.recommendedActions = const [],
    this.computedAt,
    this.studentName,
    this.admissionNumber,
    this.className,
    this.sectionName,
    this.riskExplanation,
  });

  factory StudentRiskScore.fromJson(Map<String, dynamic> json) {
    // Parse flags — could be a Postgres text array or JSON list
    List<String> parseFlags(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String) {
        // Postgres text array format: {a,b,c}
        final trimmed = val.replaceAll(RegExp(r'[{}]'), '');
        if (trimmed.isEmpty) return [];
        return trimmed.split(',').map((e) => e.trim()).toList();
      }
      return [];
    }

    List<String> parseActions(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val
            .expand((e) => e is List ? e : [e])
            .map((e) => e.toString())
            .toList();
      }
      return [];
    }

    // Handle joined student data
    String? studentName;
    String? admissionNumber;
    String? className;
    String? sectionName;

    if (json['students'] != null) {
      final s = json['students'];
      studentName =
          '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
      admissionNumber = s['admission_number'];
    }
    if (json['student_name'] != null) {
      studentName = json['student_name'];
    }
    if (json['admission_number'] != null) {
      admissionNumber = json['admission_number'];
    }
    if (json['class_name'] != null) {
      className = json['class_name'];
    }
    if (json['section_name'] != null) {
      sectionName = json['section_name'];
    }

    return StudentRiskScore(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      academicYearId: json['academic_year_id'] ?? '',
      overallRiskScore:
          (json['overall_risk_score'] as num?)?.toDouble() ?? 0,
      riskLevel: json['risk_level'] ?? 'low',
      attendanceScore:
          (json['attendance_score'] as num?)?.toDouble() ?? 0,
      academicScore: (json['academic_score'] as num?)?.toDouble() ?? 0,
      feeScore: (json['fee_score'] as num?)?.toDouble() ?? 0,
      engagementScore:
          (json['engagement_score'] as num?)?.toDouble() ?? 0,
      previousScore: (json['previous_score'] as num?)?.toDouble(),
      scoreTrend: json['score_trend'] ?? 'stable',
      flags: parseFlags(json['flags']),
      recommendedActions: parseActions(json['recommended_actions']),
      computedAt: json['computed_at'] != null
          ? DateTime.tryParse(json['computed_at'])
          : null,
      studentName: studentName,
      admissionNumber: admissionNumber,
      className: className,
      sectionName: sectionName,
    );
  }

  StudentRiskScore copyWith({String? riskExplanation}) {
    return StudentRiskScore(
      id: id,
      studentId: studentId,
      academicYearId: academicYearId,
      overallRiskScore: overallRiskScore,
      riskLevel: riskLevel,
      attendanceScore: attendanceScore,
      academicScore: academicScore,
      feeScore: feeScore,
      engagementScore: engagementScore,
      previousScore: previousScore,
      scoreTrend: scoreTrend,
      flags: flags,
      recommendedActions: recommendedActions,
      computedAt: computedAt,
      studentName: studentName,
      admissionNumber: admissionNumber,
      className: className,
      sectionName: sectionName,
      riskExplanation: riskExplanation ?? this.riskExplanation,
    );
  }

  Color get riskColor {
    switch (riskLevel) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF22C55E);
    }
  }

  bool get isAtRisk => riskLevel == 'high' || riskLevel == 'critical';

  String get dominantFactor {
    final factors = {
      'Attendance': attendanceScore,
      'Academic': academicScore,
      'Fee': feeScore,
      'Engagement': engagementScore,
    };
    return factors.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  IconData get trendIcon {
    switch (scoreTrend) {
      case 'improving':
        return Icons.trending_down; // risk going down = good
      case 'declining':
        return Icons.trending_up; // risk going up = bad
      default:
        return Icons.trending_flat;
    }
  }

  Color get trendColor {
    switch (scoreTrend) {
      case 'improving':
        return const Color(0xFF22C55E);
      case 'declining':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  String get riskLevelLabel {
    switch (riskLevel) {
      case 'critical':
        return 'Critical';
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      default:
        return 'Low';
    }
  }
}
