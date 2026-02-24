import 'package:flutter/material.dart';

// ============================================================
// LessonPlanStatus Enum
// ============================================================

enum LessonPlanStatus {
  draft('draft', Icons.edit_outlined, 'Draft', Colors.grey),
  ready('ready', Icons.check_circle_outline, 'Ready', Colors.blue),
  delivered('delivered', Icons.done_all, 'Delivered', Colors.green),
  archived('archived', Icons.archive_outlined, 'Archived', Colors.blueGrey);

  const LessonPlanStatus(this.dbValue, this.icon, this.label, this.color);
  final String dbValue;
  final IconData icon;
  final String label;
  final Color color;

  static LessonPlanStatus fromString(String value) {
    return LessonPlanStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => LessonPlanStatus.draft,
    );
  }
}

// ============================================================
// LessonPlan Model
// ============================================================

class LessonPlan {
  final String id;
  final String tenantId;
  final String topicId;
  final String? sectionId;
  final String teacherId;
  final String title;
  final String? objective;
  final String? warmUp;
  final String? mainActivity;
  final String? assessmentActivity;
  final String? homework;
  final String? materialsNeeded;
  final String? differentiationNotes;
  final int durationMinutes;
  final LessonPlanStatus status;
  final bool isAiGenerated;
  final Map<String, dynamic>? aiPromptContext;
  final DateTime? deliveredDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? topicTitle;
  final String? sectionName;
  final String? teacherName;

  const LessonPlan({
    required this.id,
    required this.tenantId,
    required this.topicId,
    this.sectionId,
    required this.teacherId,
    required this.title,
    this.objective,
    this.warmUp,
    this.mainActivity,
    this.assessmentActivity,
    this.homework,
    this.materialsNeeded,
    this.differentiationNotes,
    this.durationMinutes = 40,
    this.status = LessonPlanStatus.draft,
    this.isAiGenerated = false,
    this.aiPromptContext,
    this.deliveredDate,
    required this.createdAt,
    required this.updatedAt,
    this.topicTitle,
    this.sectionName,
    this.teacherName,
  });

  factory LessonPlan.fromJson(Map<String, dynamic> json) {
    return LessonPlan(
      id: json['id'],
      tenantId: json['tenant_id'],
      topicId: json['topic_id'],
      sectionId: json['section_id'],
      teacherId: json['teacher_id'],
      title: json['title'],
      objective: json['objective'],
      warmUp: json['warm_up'],
      mainActivity: json['main_activity'],
      assessmentActivity: json['assessment_activity'],
      homework: json['homework'],
      materialsNeeded: json['materials_needed'],
      differentiationNotes: json['differentiation_notes'],
      durationMinutes: json['duration_minutes'] ?? 40,
      status: LessonPlanStatus.fromString(json['status'] ?? 'draft'),
      isAiGenerated: json['is_ai_generated'] ?? false,
      aiPromptContext: json['ai_prompt_context'],
      deliveredDate: json['delivered_date'] != null
          ? DateTime.parse(json['delivered_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      topicTitle:
          json['syllabus_topics']?['title'] ?? json['topic_title'],
      sectionName:
          json['sections']?['name'] ?? json['section_name'],
      teacherName:
          json['users']?['full_name'] ?? json['teacher_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'topic_id': topicId,
      'section_id': sectionId,
      'teacher_id': teacherId,
      'title': title,
      'objective': objective,
      'warm_up': warmUp,
      'main_activity': mainActivity,
      'assessment_activity': assessmentActivity,
      'homework': homework,
      'materials_needed': materialsNeeded,
      'differentiation_notes': differentiationNotes,
      'duration_minutes': durationMinutes,
      'status': status.dbValue,
      'is_ai_generated': isAiGenerated,
      'ai_prompt_context': aiPromptContext,
      'delivered_date': deliveredDate?.toIso8601String(),
    };
  }

  LessonPlan copyWith({
    String? id,
    String? tenantId,
    String? topicId,
    String? sectionId,
    String? teacherId,
    String? title,
    String? objective,
    String? warmUp,
    String? mainActivity,
    String? assessmentActivity,
    String? homework,
    String? materialsNeeded,
    String? differentiationNotes,
    int? durationMinutes,
    LessonPlanStatus? status,
    bool? isAiGenerated,
    Map<String, dynamic>? aiPromptContext,
    DateTime? deliveredDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? topicTitle,
    String? sectionName,
    String? teacherName,
  }) {
    return LessonPlan(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      topicId: topicId ?? this.topicId,
      sectionId: sectionId ?? this.sectionId,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      warmUp: warmUp ?? this.warmUp,
      mainActivity: mainActivity ?? this.mainActivity,
      assessmentActivity: assessmentActivity ?? this.assessmentActivity,
      homework: homework ?? this.homework,
      materialsNeeded: materialsNeeded ?? this.materialsNeeded,
      differentiationNotes: differentiationNotes ?? this.differentiationNotes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiPromptContext: aiPromptContext ?? this.aiPromptContext,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      topicTitle: topicTitle ?? this.topicTitle,
      sectionName: sectionName ?? this.sectionName,
      teacherName: teacherName ?? this.teacherName,
    );
  }

  bool get isDraft => status == LessonPlanStatus.draft;
  bool get isReady => status == LessonPlanStatus.ready;
  bool get isDelivered => status == LessonPlanStatus.delivered;
  bool get isArchived => status == LessonPlanStatus.archived;

  bool get hasContent =>
      (objective?.isNotEmpty ?? false) ||
      (warmUp?.isNotEmpty ?? false) ||
      (mainActivity?.isNotEmpty ?? false);
}
