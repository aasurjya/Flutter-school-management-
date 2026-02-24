import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum AlertCategory {
  academicDecline,
  attendanceIssue,
  behavioralConcern,
  feeDefaultRisk,
  dropoutRisk,
  healthConcern;

  String get dbValue {
    switch (this) {
      case AlertCategory.academicDecline:
        return 'academic_decline';
      case AlertCategory.attendanceIssue:
        return 'attendance_issue';
      case AlertCategory.behavioralConcern:
        return 'behavioral_concern';
      case AlertCategory.feeDefaultRisk:
        return 'fee_default_risk';
      case AlertCategory.dropoutRisk:
        return 'dropout_risk';
      case AlertCategory.healthConcern:
        return 'health_concern';
    }
  }

  static AlertCategory fromDbValue(String value) {
    switch (value) {
      case 'academic_decline':
        return AlertCategory.academicDecline;
      case 'attendance_issue':
        return AlertCategory.attendanceIssue;
      case 'behavioral_concern':
        return AlertCategory.behavioralConcern;
      case 'fee_default_risk':
        return AlertCategory.feeDefaultRisk;
      case 'dropout_risk':
        return AlertCategory.dropoutRisk;
      case 'health_concern':
        return AlertCategory.healthConcern;
      default:
        return AlertCategory.academicDecline;
    }
  }

  String get displayLabel {
    switch (this) {
      case AlertCategory.academicDecline:
        return 'Academic Decline';
      case AlertCategory.attendanceIssue:
        return 'Attendance Issue';
      case AlertCategory.behavioralConcern:
        return 'Behavioral Concern';
      case AlertCategory.feeDefaultRisk:
        return 'Fee Default Risk';
      case AlertCategory.dropoutRisk:
        return 'Dropout Risk';
      case AlertCategory.healthConcern:
        return 'Health Concern';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertCategory.academicDecline:
        return Icons.trending_down;
      case AlertCategory.attendanceIssue:
        return Icons.event_busy;
      case AlertCategory.behavioralConcern:
        return Icons.warning_amber;
      case AlertCategory.feeDefaultRisk:
        return Icons.money_off;
      case AlertCategory.dropoutRisk:
        return Icons.exit_to_app;
      case AlertCategory.healthConcern:
        return Icons.local_hospital;
    }
  }
}

enum AlertSeverity {
  info,
  warning,
  critical,
  emergency;

  String get dbValue {
    switch (this) {
      case AlertSeverity.info:
        return 'info';
      case AlertSeverity.warning:
        return 'warning';
      case AlertSeverity.critical:
        return 'critical';
      case AlertSeverity.emergency:
        return 'emergency';
    }
  }

  static AlertSeverity fromDbValue(String value) {
    switch (value) {
      case 'info':
        return AlertSeverity.info;
      case 'warning':
        return AlertSeverity.warning;
      case 'critical':
        return AlertSeverity.critical;
      case 'emergency':
        return AlertSeverity.emergency;
      default:
        return AlertSeverity.info;
    }
  }

  String get displayLabel {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.emergency:
        return 'Emergency';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.amber;
      case AlertSeverity.critical:
        return Colors.orange;
      case AlertSeverity.emergency:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber_outlined;
      case AlertSeverity.critical:
        return Icons.error_outline;
      case AlertSeverity.emergency:
        return Icons.dangerous;
    }
  }
}

enum AlertStatus {
  newAlert,
  acknowledged,
  inProgress,
  resolved,
  falsePositive;

  String get dbValue {
    switch (this) {
      case AlertStatus.newAlert:
        return 'new';
      case AlertStatus.acknowledged:
        return 'acknowledged';
      case AlertStatus.inProgress:
        return 'in_progress';
      case AlertStatus.resolved:
        return 'resolved';
      case AlertStatus.falsePositive:
        return 'false_positive';
    }
  }

  static AlertStatus fromDbValue(String value) {
    switch (value) {
      case 'new':
        return AlertStatus.newAlert;
      case 'acknowledged':
        return AlertStatus.acknowledged;
      case 'in_progress':
        return AlertStatus.inProgress;
      case 'resolved':
        return AlertStatus.resolved;
      case 'false_positive':
        return AlertStatus.falsePositive;
      default:
        return AlertStatus.newAlert;
    }
  }

  String get displayLabel {
    switch (this) {
      case AlertStatus.newAlert:
        return 'New';
      case AlertStatus.acknowledged:
        return 'Acknowledged';
      case AlertStatus.inProgress:
        return 'In Progress';
      case AlertStatus.resolved:
        return 'Resolved';
      case AlertStatus.falsePositive:
        return 'False Positive';
    }
  }

  Color get color {
    switch (this) {
      case AlertStatus.newAlert:
        return Colors.blue;
      case AlertStatus.acknowledged:
        return Colors.orange;
      case AlertStatus.inProgress:
        return Colors.amber;
      case AlertStatus.resolved:
        return const Color(0xFF22C55E);
      case AlertStatus.falsePositive:
        return Colors.grey;
    }
  }

  bool get isOpen =>
      this == AlertStatus.newAlert ||
      this == AlertStatus.acknowledged ||
      this == AlertStatus.inProgress;
}

// ---------------------------------------------------------------------------
// EarlyWarningAlert
// ---------------------------------------------------------------------------

class EarlyWarningAlert {
  final String id;
  final String studentId;
  final AlertCategory category;
  final AlertSeverity severity;
  final AlertStatus status;
  final String title;
  final String? description;
  final String? detectedByModelId;
  final double? confidenceScore;
  final Map<String, dynamic> triggerConditions;
  final String? assignedTo;
  final bool parentNotified;
  final DateTime? parentNotifiedAt;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Joined student info
  final String? studentName;
  final String? admissionNumber;
  final String? className;
  final String? sectionName;
  // LLM-generated explanation (null if not yet enriched)
  final String? aiExplanation;

  const EarlyWarningAlert({
    required this.id,
    required this.studentId,
    required this.category,
    required this.severity,
    this.status = AlertStatus.newAlert,
    required this.title,
    this.description,
    this.detectedByModelId,
    this.confidenceScore,
    this.triggerConditions = const {},
    this.assignedTo,
    this.parentNotified = false,
    this.parentNotifiedAt,
    this.resolutionNotes,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.studentName,
    this.admissionNumber,
    this.className,
    this.sectionName,
    this.aiExplanation,
  });

  factory EarlyWarningAlert.fromJson(Map<String, dynamic> json) {
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

    // Parse trigger_conditions JSONB
    Map<String, dynamic> triggerConditions = {};
    if (json['trigger_conditions'] != null) {
      if (json['trigger_conditions'] is Map) {
        triggerConditions =
            Map<String, dynamic>.from(json['trigger_conditions']);
      }
    }

    return EarlyWarningAlert(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      category: AlertCategory.fromDbValue(
          json['alert_category'] ?? 'academic_decline'),
      severity:
          AlertSeverity.fromDbValue(json['severity'] ?? 'info'),
      status: AlertStatus.fromDbValue(json['status'] ?? 'new'),
      title: json['title'] ?? '',
      description: json['description'],
      detectedByModelId: json['detected_by_model_id'],
      confidenceScore:
          (json['confidence_score'] as num?)?.toDouble(),
      triggerConditions: triggerConditions,
      assignedTo: json['assigned_to'],
      parentNotified: json['parent_notified'] ?? false,
      parentNotifiedAt: json['parent_notified_at'] != null
          ? DateTime.tryParse(json['parent_notified_at'])
          : null,
      resolutionNotes: json['resolution_notes'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      studentName: studentName,
      admissionNumber: admissionNumber,
      className: className,
      sectionName: sectionName,
    );
  }

  EarlyWarningAlert copyWith({String? aiExplanation}) {
    return EarlyWarningAlert(
      id: id,
      studentId: studentId,
      category: category,
      severity: severity,
      status: status,
      title: title,
      description: description,
      detectedByModelId: detectedByModelId,
      confidenceScore: confidenceScore,
      triggerConditions: triggerConditions,
      assignedTo: assignedTo,
      parentNotified: parentNotified,
      parentNotifiedAt: parentNotifiedAt,
      resolutionNotes: resolutionNotes,
      resolvedAt: resolvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      studentName: studentName,
      admissionNumber: admissionNumber,
      className: className,
      sectionName: sectionName,
      aiExplanation: aiExplanation ?? this.aiExplanation,
    );
  }

  /// Whether this alert is still actionable (not resolved or dismissed).
  bool get isOpen => status.isOpen;

  /// Human-readable age of the alert (e.g. "2 days ago").
  String get ageLabel {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  /// Confidence as a percentage string, or null if not available.
  String? get confidenceLabel {
    if (confidenceScore == null) return null;
    return '${confidenceScore!.round()}%';
  }
}

// ---------------------------------------------------------------------------
// AlertRule
// ---------------------------------------------------------------------------

class AlertRule {
  final String id;
  final String tenantId;
  final String ruleName;
  final AlertCategory category;
  final AlertSeverity severity;
  final Map<String, dynamic> conditionLogic;
  final bool isActive;
  final String? autoAssignToRole;
  final bool notifyParents;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AlertRule({
    required this.id,
    required this.tenantId,
    required this.ruleName,
    required this.category,
    required this.severity,
    this.conditionLogic = const {},
    this.isActive = true,
    this.autoAssignToRole,
    this.notifyParents = false,
    this.createdAt,
    this.updatedAt,
  });

  factory AlertRule.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> conditionLogic = {};
    if (json['condition_logic'] != null) {
      if (json['condition_logic'] is Map) {
        conditionLogic =
            Map<String, dynamic>.from(json['condition_logic']);
      }
    }

    return AlertRule(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      ruleName: json['rule_name'] ?? '',
      category: AlertCategory.fromDbValue(
          json['alert_category'] ?? 'academic_decline'),
      severity:
          AlertSeverity.fromDbValue(json['severity'] ?? 'info'),
      conditionLogic: conditionLogic,
      isActive: json['is_active'] ?? true,
      autoAssignToRole: json['auto_assign_to_role'],
      notifyParents: json['notify_parents'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}
