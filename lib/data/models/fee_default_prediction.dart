import 'package:flutter/material.dart';

// ============================================================
// Risk Level
// ============================================================

enum FeeRiskLevel {
  low('low', 'Low Risk', Colors.green, 40),
  medium('medium', 'Medium Risk', Colors.orange, 70),
  high('high', 'High Risk', Colors.red, 101);

  const FeeRiskLevel(this.dbValue, this.label, this.color, this.maxScore);
  final String dbValue;
  final String label;
  final Color color;
  final int maxScore; // exclusive upper bound

  static FeeRiskLevel fromScore(int score) {
    if (score >= 71) return FeeRiskLevel.high;
    if (score >= 41) return FeeRiskLevel.medium;
    return FeeRiskLevel.low;
  }

  Color get bgColor => color.withValues(alpha: 0.12);
  Color get borderColor => color.withValues(alpha: 0.4);

  IconData get icon {
    switch (this) {
      case FeeRiskLevel.high:
        return Icons.warning_amber_rounded;
      case FeeRiskLevel.medium:
        return Icons.error_outline;
      case FeeRiskLevel.low:
        return Icons.check_circle_outline;
    }
  }
}

// ============================================================
// FeeDefaultPrediction — maps one row from predict_fee_defaults()
// ============================================================

class FeeDefaultPrediction {
  final String studentId;
  final String studentName;
  final String className;
  final String invoiceId;
  final String invoiceNumber;
  final double amountDue;
  final DateTime dueDate;
  final int riskScore;
  final List<String> riskFactors;
  final String recommendedAction;
  final DateTime? lastReminderAt;

  const FeeDefaultPrediction({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amountDue,
    required this.dueDate,
    required this.riskScore,
    required this.riskFactors,
    required this.recommendedAction,
    this.lastReminderAt,
  });

  factory FeeDefaultPrediction.fromJson(Map<String, dynamic> json) {
    return FeeDefaultPrediction(
      studentId: json['student_id'],
      studentName: json['student_name'] ?? 'Unknown',
      className: json['class_name'] ?? '',
      invoiceId: json['invoice_id'],
      invoiceNumber: json['invoice_number'] ?? '',
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.parse(json['due_date']),
      riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
      riskFactors: (json['risk_factors'] as List<dynamic>? ?? [])
          .map((f) => f.toString())
          .where((f) => f.isNotEmpty)
          .toList(),
      recommendedAction: json['recommended_action'] ?? '',
      lastReminderAt: json['last_reminder_at'] != null
          ? DateTime.parse(json['last_reminder_at'])
          : null,
    );
  }

  FeeRiskLevel get riskLevel => FeeRiskLevel.fromScore(riskScore);

  bool get isOverdue => dueDate.isBefore(DateTime.now());

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  int get daysUntilDue {
    if (isOverdue) return 0;
    return dueDate.difference(DateTime.now()).inDays;
  }

  bool get reminderSentRecently {
    if (lastReminderAt == null) return false;
    return DateTime.now().difference(lastReminderAt!).inHours < 24;
  }
}

// ============================================================
// FeeDefaultSummary — aggregate stats for the Risk tab header
// ============================================================

class FeeDefaultSummary {
  final int totalAtRisk;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final double totalAmountAtRisk;

  const FeeDefaultSummary({
    required this.totalAtRisk,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.totalAmountAtRisk,
  });

  factory FeeDefaultSummary.from(List<FeeDefaultPrediction> predictions) {
    return FeeDefaultSummary(
      totalAtRisk: predictions.length,
      highRiskCount: predictions
          .where((p) => p.riskLevel == FeeRiskLevel.high)
          .length,
      mediumRiskCount: predictions
          .where((p) => p.riskLevel == FeeRiskLevel.medium)
          .length,
      lowRiskCount: predictions
          .where((p) => p.riskLevel == FeeRiskLevel.low)
          .length,
      totalAmountAtRisk:
          predictions.fold(0.0, (sum, p) => sum + p.amountDue),
    );
  }

  String get formattedAmountAtRisk {
    if (totalAmountAtRisk >= 100000) {
      return '₹${(totalAmountAtRisk / 100000).toStringAsFixed(1)}L';
    }
    if (totalAmountAtRisk >= 1000) {
      return '₹${(totalAmountAtRisk / 1000).toStringAsFixed(0)}K';
    }
    return '₹${totalAmountAtRisk.toStringAsFixed(0)}';
  }
}
