import 'package:flutter/material.dart';

// ============================================================
// Enums
// ============================================================

enum TopicLevel {
  unit('unit', Icons.folder_outlined, 'Unit'),
  chapter('chapter', Icons.menu_book_outlined, 'Chapter'),
  topic('topic', Icons.topic_outlined, 'Topic'),
  subtopic('subtopic', Icons.subdirectory_arrow_right, 'Subtopic');

  const TopicLevel(this.dbValue, this.icon, this.label);
  final String dbValue;
  final IconData icon;
  final String label;

  static TopicLevel fromString(String value) {
    return TopicLevel.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => TopicLevel.topic,
    );
  }

  TopicLevel? get childLevel {
    switch (this) {
      case TopicLevel.unit:
        return TopicLevel.chapter;
      case TopicLevel.chapter:
        return TopicLevel.topic;
      case TopicLevel.topic:
        return TopicLevel.subtopic;
      case TopicLevel.subtopic:
        return null;
    }
  }

  int get depth {
    switch (this) {
      case TopicLevel.unit:
        return 0;
      case TopicLevel.chapter:
        return 1;
      case TopicLevel.topic:
        return 2;
      case TopicLevel.subtopic:
        return 3;
    }
  }
}

enum TopicStatus {
  notStarted('not_started', Icons.circle_outlined, 'Not Started', Colors.grey),
  inProgress('in_progress', Icons.timelapse, 'In Progress', Colors.amber),
  completed('completed', Icons.check_circle, 'Completed', Colors.green),
  skipped('skipped', Icons.skip_next, 'Skipped', Colors.blueGrey);

  const TopicStatus(this.dbValue, this.icon, this.label, this.color);
  final String dbValue;
  final IconData icon;
  final String label;
  final Color color;

  static TopicStatus fromString(String value) {
    return TopicStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => TopicStatus.notStarted,
    );
  }
}

// ============================================================
// SyllabusTopic
// ============================================================

class SyllabusTopic {
  final String id;
  final String tenantId;
  final String subjectId;
  final String classId;
  final String academicYearId;
  final String? parentTopicId;
  final TopicLevel level;
  final int sequenceOrder;
  final String title;
  final String? description;
  final List<String> learningObjectives;
  final int estimatedPeriods;
  final String? termId;
  final List<String> tags;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? subjectName;
  final String? className;
  final String? termName;

  // Tree structure (populated client-side)
  final List<SyllabusTopic> children;
  final int childCount;

  // Coverage (populated when section context is provided)
  final TopicCoverage? coverage;

  const SyllabusTopic({
    required this.id,
    required this.tenantId,
    required this.subjectId,
    required this.classId,
    required this.academicYearId,
    this.parentTopicId,
    required this.level,
    required this.sequenceOrder,
    required this.title,
    this.description,
    this.learningObjectives = const [],
    this.estimatedPeriods = 1,
    this.termId,
    this.tags = const [],
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
    this.className,
    this.termName,
    this.children = const [],
    this.childCount = 0,
    this.coverage,
  });

  factory SyllabusTopic.fromJson(Map<String, dynamic> json) {
    return SyllabusTopic(
      id: json['id'],
      tenantId: json['tenant_id'],
      subjectId: json['subject_id'],
      classId: json['class_id'],
      academicYearId: json['academic_year_id'],
      parentTopicId: json['parent_topic_id'],
      level: TopicLevel.fromString(json['level'] ?? 'topic'),
      sequenceOrder: json['sequence_order'] ?? 0,
      title: json['title'],
      description: json['description'],
      learningObjectives:
          List<String>.from(json['learning_objectives'] ?? []),
      estimatedPeriods: json['estimated_periods'] ?? 1,
      termId: json['term_id'],
      tags: List<String>.from(json['tags'] ?? []),
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      subjectName: json['subjects']?['name'] ?? json['subject_name'],
      className: json['classes']?['name'] ?? json['class_name'],
      termName: json['terms']?['name'] ?? json['term_name'],
      coverage: json['topic_coverage'] != null &&
              (json['topic_coverage'] is List
                  ? (json['topic_coverage'] as List).isNotEmpty
                  : true)
          ? TopicCoverage.fromJson(
              json['topic_coverage'] is List
                  ? (json['topic_coverage'] as List).first
                  : json['topic_coverage'],
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'subject_id': subjectId,
      'class_id': classId,
      'academic_year_id': academicYearId,
      'parent_topic_id': parentTopicId,
      'level': level.dbValue,
      'sequence_order': sequenceOrder,
      'title': title,
      'description': description,
      'learning_objectives': learningObjectives,
      'estimated_periods': estimatedPeriods,
      'term_id': termId,
      'tags': tags,
      'created_by': createdBy,
    };
  }

  SyllabusTopic copyWith({
    String? id,
    String? tenantId,
    String? subjectId,
    String? classId,
    String? academicYearId,
    String? parentTopicId,
    TopicLevel? level,
    int? sequenceOrder,
    String? title,
    String? description,
    List<String>? learningObjectives,
    int? estimatedPeriods,
    String? termId,
    List<String>? tags,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? subjectName,
    String? className,
    String? termName,
    List<SyllabusTopic>? children,
    int? childCount,
    TopicCoverage? coverage,
  }) {
    return SyllabusTopic(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      academicYearId: academicYearId ?? this.academicYearId,
      parentTopicId: parentTopicId ?? this.parentTopicId,
      level: level ?? this.level,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      title: title ?? this.title,
      description: description ?? this.description,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      estimatedPeriods: estimatedPeriods ?? this.estimatedPeriods,
      termId: termId ?? this.termId,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subjectName: subjectName ?? this.subjectName,
      className: className ?? this.className,
      termName: termName ?? this.termName,
      children: children ?? this.children,
      childCount: childCount ?? this.childCount,
      coverage: coverage ?? this.coverage,
    );
  }

  bool get hasChildren => children.isNotEmpty || childCount > 0;
  bool get isRoot => parentTopicId == null;
  bool get isLeaf => !hasChildren;
}

// ============================================================
// TopicCoverage
// ============================================================

class TopicCoverage {
  final String id;
  final String topicId;
  final String sectionId;
  final String? teacherId;
  final TopicStatus status;
  final DateTime? startedDate;
  final DateTime? completedDate;
  final int periodsSpent;
  final String? notes;

  const TopicCoverage({
    required this.id,
    required this.topicId,
    required this.sectionId,
    this.teacherId,
    this.status = TopicStatus.notStarted,
    this.startedDate,
    this.completedDate,
    this.periodsSpent = 0,
    this.notes,
  });

  factory TopicCoverage.fromJson(Map<String, dynamic> json) {
    return TopicCoverage(
      id: json['id'],
      topicId: json['topic_id'],
      sectionId: json['section_id'],
      teacherId: json['teacher_id'],
      status: TopicStatus.fromString(json['status'] ?? 'not_started'),
      startedDate: json['started_date'] != null
          ? DateTime.parse(json['started_date'])
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'])
          : null,
      periodsSpent: json['periods_spent'] ?? 0,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic_id': topicId,
      'section_id': sectionId,
      'teacher_id': teacherId,
      'status': status.dbValue,
      'started_date': startedDate?.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'periods_spent': periodsSpent,
      'notes': notes,
    };
  }
}

// ============================================================
// SyllabusFilter (used as Riverpod family key)
// ============================================================

class SyllabusFilter {
  final String subjectId;
  final String classId;
  final String academicYearId;
  final String? sectionId;

  const SyllabusFilter({
    required this.subjectId,
    required this.classId,
    required this.academicYearId,
    this.sectionId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyllabusFilter &&
          other.subjectId == subjectId &&
          other.classId == classId &&
          other.academicYearId == academicYearId &&
          other.sectionId == sectionId;

  @override
  int get hashCode =>
      Object.hash(subjectId, classId, academicYearId, sectionId);
}

// ============================================================
// SyllabusCoverageSummary
// ============================================================

class SyllabusCoverageSummary {
  final String subjectId;
  final String classId;
  final String academicYearId;
  final String? sectionId;
  final int totalTopics;
  final int completedTopics;
  final int inProgressTopics;
  final int skippedTopics;
  final double coveragePercentage;
  final int totalEstimatedPeriods;
  final int totalPeriodsSpent;

  // Joined data
  final String? subjectName;
  final String? className;
  final String? sectionName;

  const SyllabusCoverageSummary({
    required this.subjectId,
    required this.classId,
    required this.academicYearId,
    this.sectionId,
    this.totalTopics = 0,
    this.completedTopics = 0,
    this.inProgressTopics = 0,
    this.skippedTopics = 0,
    this.coveragePercentage = 0,
    this.totalEstimatedPeriods = 0,
    this.totalPeriodsSpent = 0,
    this.subjectName,
    this.className,
    this.sectionName,
  });

  factory SyllabusCoverageSummary.fromJson(Map<String, dynamic> json) {
    return SyllabusCoverageSummary(
      subjectId: json['subject_id'],
      classId: json['class_id'],
      academicYearId: json['academic_year_id'],
      sectionId: json['section_id'],
      totalTopics: json['total_topics'] ?? 0,
      completedTopics: json['completed_topics'] ?? 0,
      inProgressTopics: json['in_progress_topics'] ?? 0,
      skippedTopics: json['skipped_topics'] ?? 0,
      coveragePercentage:
          (json['coverage_percentage'] as num?)?.toDouble() ?? 0,
      totalEstimatedPeriods: json['total_estimated_periods'] ?? 0,
      totalPeriodsSpent: json['total_periods_spent'] ?? 0,
      subjectName: json['subject_name'],
      className: json['class_name'],
      sectionName: json['section_name'],
    );
  }

  int get notStartedTopics =>
      totalTopics - completedTopics - inProgressTopics - skippedTopics;
}

// ============================================================
// TopicResourceLink
// ============================================================

class TopicResourceLink {
  final String id;
  final String topicId;
  final String entityType;
  final String entityId;
  final DateTime createdAt;

  // Joined data
  final String? entityTitle;

  const TopicResourceLink({
    required this.id,
    required this.topicId,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.entityTitle,
  });

  factory TopicResourceLink.fromJson(Map<String, dynamic> json) {
    return TopicResourceLink(
      id: json['id'],
      topicId: json['topic_id'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      createdAt: DateTime.parse(json['created_at']),
      entityTitle: json['entity_title'],
    );
  }

  String get entityTypeDisplay {
    switch (entityType) {
      case 'assignment':
        return 'Assignment';
      case 'quiz':
        return 'Quiz';
      case 'question_bank':
        return 'Question';
      case 'study_resource':
        return 'Resource';
      case 'exam_subject':
        return 'Exam';
      default:
        return entityType;
    }
  }

  IconData get entityTypeIcon {
    switch (entityType) {
      case 'assignment':
        return Icons.assignment;
      case 'quiz':
        return Icons.quiz;
      case 'question_bank':
        return Icons.help_outline;
      case 'study_resource':
        return Icons.library_books;
      case 'exam_subject':
        return Icons.school;
      default:
        return Icons.link;
    }
  }
}
