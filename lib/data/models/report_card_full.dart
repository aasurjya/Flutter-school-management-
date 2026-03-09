/// Complete Report Card models for the Report Card Generator module.
/// Named `report_card_full.dart` to avoid conflicts with existing
/// `report_card.dart` which has simpler models used by the basic reports feature.
library;

// ---------------------------------------------------------------------------
// Grading Scale
// ---------------------------------------------------------------------------

class GradingScaleItem {
  final String grade;
  final double minMarks;
  final double maxMarks;
  final double? gpaValue;
  final String? description;

  const GradingScaleItem({
    required this.grade,
    required this.minMarks,
    required this.maxMarks,
    this.gpaValue,
    this.description,
  });

  factory GradingScaleItem.fromJson(Map<String, dynamic> json) {
    return GradingScaleItem(
      grade: json['grade'] as String,
      minMarks: (json['min_marks'] as num).toDouble(),
      maxMarks: (json['max_marks'] as num).toDouble(),
      gpaValue: (json['gpa_value'] as num?)?.toDouble(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'grade': grade,
        'min_marks': minMarks,
        'max_marks': maxMarks,
        'gpa_value': gpaValue,
        'description': description,
      };
}

class GradingScale {
  final String id;
  final String tenantId;
  final String name;
  final String type; // percentage | letter | gpa | cgpa
  final List<GradingScaleItem> scaleItems;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GradingScale({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    required this.scaleItems,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GradingScale.fromJson(Map<String, dynamic> json) {
    final items = json['scale_items'];
    List<GradingScaleItem> parsedItems = [];
    if (items is List) {
      parsedItems =
          items.map((e) => GradingScaleItem.fromJson(e as Map<String, dynamic>)).toList();
    }

    return GradingScale(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'percentage',
      scaleItems: parsedItems,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'name': name,
        'type': type,
        'scale_items': scaleItems.map((e) => e.toJson()).toList(),
        'is_default': isDefault,
      };

  String gradeFor(double percentage) {
    for (final item in scaleItems) {
      if (percentage >= item.minMarks && percentage <= item.maxMarks) {
        return item.grade;
      }
    }
    return 'N/A';
  }

  double? gpaFor(double percentage) {
    for (final item in scaleItems) {
      if (percentage >= item.minMarks && percentage <= item.maxMarks) {
        return item.gpaValue;
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Template Section Config
// ---------------------------------------------------------------------------

class TemplateSectionConfig {
  final String type; // grades | attendance | behavior | teacher_comment | principal_comment | skills | activities
  final bool enabled;
  final int order;
  final Map<String, dynamic> config;

  const TemplateSectionConfig({
    required this.type,
    this.enabled = true,
    this.order = 0,
    this.config = const {},
  });

  factory TemplateSectionConfig.fromJson(Map<String, dynamic> json) {
    return TemplateSectionConfig(
      type: json['type'] as String,
      enabled: json['enabled'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      config: (json['config'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'enabled': enabled,
        'order': order,
        'config': config,
      };
}

// ---------------------------------------------------------------------------
// Report Card Template
// ---------------------------------------------------------------------------

class ReportCardTemplateFull {
  final String id;
  final String tenantId;
  final String name;
  final String layout; // standard | detailed | competency_based | narrative
  final Map<String, dynamic> headerConfig;
  final List<TemplateSectionConfig> sections;
  final String? gradingScaleId;
  final String? footerText;
  final bool isDefault;
  final String pageSize; // A4 | letter
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final GradingScale? gradingScale;

  const ReportCardTemplateFull({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.layout,
    required this.headerConfig,
    required this.sections,
    this.gradingScaleId,
    this.footerText,
    this.isDefault = false,
    this.pageSize = 'A4',
    required this.createdAt,
    required this.updatedAt,
    this.gradingScale,
  });

  factory ReportCardTemplateFull.fromJson(Map<String, dynamic> json) {
    final sectionsRaw = json['sections'];
    List<TemplateSectionConfig> parsedSections = [];
    if (sectionsRaw is List) {
      parsedSections = sectionsRaw
          .map((e) => TemplateSectionConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ReportCardTemplateFull(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      layout: json['layout'] as String? ?? 'standard',
      headerConfig:
          (json['header_config'] as Map<String, dynamic>?) ?? {},
      sections: parsedSections,
      gradingScaleId: json['grading_scale_id'] as String?,
      footerText: json['footer_text'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      pageSize: json['page_size'] as String? ?? 'A4',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      gradingScale: json['grading_scale'] != null
          ? GradingScale.fromJson(json['grading_scale'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'name': name,
        'layout': layout,
        'header_config': headerConfig,
        'sections': sections.map((e) => e.toJson()).toList(),
        'grading_scale_id': gradingScaleId,
        'footer_text': footerText,
        'is_default': isDefault,
        'page_size': pageSize,
      };

  bool get hasGrades => sections.any((s) => s.type == 'grades' && s.enabled);
  bool get hasAttendance =>
      sections.any((s) => s.type == 'attendance' && s.enabled);
  bool get hasSkills => sections.any((s) => s.type == 'skills' && s.enabled);
  bool get hasActivities =>
      sections.any((s) => s.type == 'activities' && s.enabled);
  bool get hasTeacherComment =>
      sections.any((s) => s.type == 'teacher_comment' && s.enabled);
  bool get hasPrincipalComment =>
      sections.any((s) => s.type == 'principal_comment' && s.enabled);
  bool get hasBehavior =>
      sections.any((s) => s.type == 'behavior' && s.enabled);

  String get layoutDisplay {
    switch (layout) {
      case 'standard':
        return 'Standard';
      case 'detailed':
        return 'Detailed';
      case 'competency_based':
        return 'Competency Based';
      case 'narrative':
        return 'Narrative';
      default:
        return layout;
    }
  }
}

// ---------------------------------------------------------------------------
// Report Card (generated record)
// ---------------------------------------------------------------------------

class ReportCardFull {
  final String id;
  final String tenantId;
  final String studentId;
  final String academicYearId;
  final String termId;
  final String templateId;
  final List<String> examIds;
  final Map<String, dynamic> data;
  final String status; // draft | generated | reviewed | published | sent
  final DateTime? generatedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? publishedAt;
  final DateTime? sentAt;
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? studentName;
  final String? admissionNumber;
  final String? rollNumber;
  final String? className;
  final String? sectionName;
  final String? academicYearName;
  final String? termName;
  final String? templateName;
  final List<ReportCardComment> comments;
  final List<ReportCardSkill> skills;
  final List<ReportCardActivity> activities;

  const ReportCardFull({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.academicYearId,
    required this.termId,
    required this.templateId,
    this.examIds = const [],
    this.data = const {},
    required this.status,
    this.generatedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.publishedAt,
    this.sentAt,
    this.pdfUrl,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.admissionNumber,
    this.rollNumber,
    this.className,
    this.sectionName,
    this.academicYearName,
    this.termName,
    this.templateName,
    this.comments = const [],
    this.skills = const [],
    this.activities = const [],
  });

  factory ReportCardFull.fromJson(Map<String, dynamic> json) {
    List<String> examIdsList = [];
    final rawExamIds = json['exam_ids'];
    if (rawExamIds is List) {
      examIdsList = rawExamIds.map((e) => e.toString()).toList();
    }

    List<ReportCardComment> commentsList = [];
    final rawComments = json['report_card_comments'];
    if (rawComments is List) {
      commentsList = rawComments
          .map((e) => ReportCardComment.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<ReportCardSkill> skillsList = [];
    final rawSkills = json['report_card_skills'];
    if (rawSkills is List) {
      skillsList = rawSkills
          .map((e) => ReportCardSkill.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<ReportCardActivity> activitiesList = [];
    final rawActivities = json['report_card_activities'];
    if (rawActivities is List) {
      activitiesList = rawActivities
          .map((e) => ReportCardActivity.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Extract joined student data
    final student = json['student'] as Map<String, dynamic>?;
    final enrollment = json['student_enrollment'] as Map<String, dynamic>?;
    final section = enrollment?['section'] as Map<String, dynamic>? ??
        student?['section'] as Map<String, dynamic>?;
    final cls = section?['class'] as Map<String, dynamic>?;
    final user = student?['user'] as Map<String, dynamic>?;

    return ReportCardFull(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      studentId: json['student_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      termId: json['term_id'] as String,
      templateId: json['template_id'] as String,
      examIds: examIdsList,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      status: json['status'] as String? ?? 'draft',
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      pdfUrl: json['pdf_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      studentName: user?['full_name'] as String? ??
          student?['full_name'] as String? ??
          json['student_name'] as String?,
      admissionNumber: student?['admission_number'] as String? ??
          json['admission_number'] as String?,
      rollNumber: student?['roll_number'] as String? ??
          json['roll_number'] as String?,
      className: cls?['name'] as String? ?? json['class_name'] as String?,
      sectionName:
          section?['name'] as String? ?? json['section_name'] as String?,
      academicYearName:
          (json['academic_year'] as Map<String, dynamic>?)?['name'] as String? ??
              json['academic_year_name'] as String?,
      termName:
          (json['term'] as Map<String, dynamic>?)?['name'] as String? ??
              json['term_name'] as String?,
      templateName:
          (json['template'] as Map<String, dynamic>?)?['name'] as String? ??
              json['template_name'] as String?,
      comments: commentsList,
      skills: skillsList,
      activities: activitiesList,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'student_id': studentId,
        'academic_year_id': academicYearId,
        'term_id': termId,
        'template_id': templateId,
        'exam_ids': examIds,
        'data': data,
        'status': status,
      };

  bool get isDraft => status == 'draft';
  bool get isGenerated => status == 'generated';
  bool get isReviewed => status == 'reviewed';
  bool get isPublished => status == 'published';
  bool get isSent => status == 'sent';

  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'generated':
        return 'Generated';
      case 'reviewed':
        return 'Reviewed';
      case 'published':
        return 'Published';
      case 'sent':
        return 'Sent';
      default:
        return status;
    }
  }

  String get studentDisplayName =>
      studentName ?? admissionNumber ?? 'Unknown Student';
  String get classSection =>
      '${className ?? ''} ${sectionName ?? ''}'.trim();
}

// ---------------------------------------------------------------------------
// Report Card Comment
// ---------------------------------------------------------------------------

class ReportCardComment {
  final String id;
  final String reportCardId;
  final String commentType; // class_teacher | subject_teacher | principal | counselor
  final String? commentedBy;
  final String commentText;
  final bool isAiGenerated;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? commenterName;

  const ReportCardComment({
    required this.id,
    required this.reportCardId,
    required this.commentType,
    this.commentedBy,
    required this.commentText,
    this.isAiGenerated = false,
    required this.createdAt,
    required this.updatedAt,
    this.commenterName,
  });

  factory ReportCardComment.fromJson(Map<String, dynamic> json) {
    final commenter = json['commenter'] as Map<String, dynamic>?;
    return ReportCardComment(
      id: json['id'] as String,
      reportCardId: json['report_card_id'] as String,
      commentType: json['comment_type'] as String,
      commentedBy: json['commented_by'] as String?,
      commentText: json['comment_text'] as String,
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      commenterName: commenter?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'report_card_id': reportCardId,
        'comment_type': commentType,
        'commented_by': commentedBy,
        'comment_text': commentText,
        'is_ai_generated': isAiGenerated,
      };

  String get commentTypeDisplay {
    switch (commentType) {
      case 'class_teacher':
        return 'Class Teacher';
      case 'subject_teacher':
        return 'Subject Teacher';
      case 'principal':
        return 'Principal';
      case 'counselor':
        return 'Counselor';
      default:
        return commentType;
    }
  }
}

// ---------------------------------------------------------------------------
// Report Card Skill
// ---------------------------------------------------------------------------

class ReportCardSkill {
  final String id;
  final String reportCardId;
  final String skillCategory; // leadership | teamwork | communication | creativity | critical_thinking | time_management
  final int rating; // 1-5
  final String? comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportCardSkill({
    required this.id,
    required this.reportCardId,
    required this.skillCategory,
    required this.rating,
    this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportCardSkill.fromJson(Map<String, dynamic> json) {
    return ReportCardSkill(
      id: json['id'] as String,
      reportCardId: json['report_card_id'] as String,
      skillCategory: json['skill_category'] as String,
      rating: json['rating'] as int,
      comments: json['comments'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'report_card_id': reportCardId,
        'skill_category': skillCategory,
        'rating': rating,
        'comments': comments,
      };

  String get skillCategoryDisplay {
    switch (skillCategory) {
      case 'leadership':
        return 'Leadership';
      case 'teamwork':
        return 'Teamwork';
      case 'communication':
        return 'Communication';
      case 'creativity':
        return 'Creativity';
      case 'critical_thinking':
        return 'Critical Thinking';
      case 'time_management':
        return 'Time Management';
      default:
        return skillCategory;
    }
  }
}

// ---------------------------------------------------------------------------
// Report Card Activity
// ---------------------------------------------------------------------------

class ReportCardActivity {
  final String id;
  final String reportCardId;
  final String activityType; // sports | arts | clubs | community_service
  final String activityName;
  final String? achievement;
  final String? grade;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportCardActivity({
    required this.id,
    required this.reportCardId,
    required this.activityType,
    required this.activityName,
    this.achievement,
    this.grade,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportCardActivity.fromJson(Map<String, dynamic> json) {
    return ReportCardActivity(
      id: json['id'] as String,
      reportCardId: json['report_card_id'] as String,
      activityType: json['activity_type'] as String,
      activityName: json['activity_name'] as String,
      achievement: json['achievement'] as String?,
      grade: json['grade'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'report_card_id': reportCardId,
        'activity_type': activityType,
        'activity_name': activityName,
        'achievement': achievement,
        'grade': grade,
      };

  String get activityTypeDisplay {
    switch (activityType) {
      case 'sports':
        return 'Sports';
      case 'arts':
        return 'Arts';
      case 'clubs':
        return 'Clubs';
      case 'community_service':
        return 'Community Service';
      default:
        return activityType;
    }
  }
}

// ---------------------------------------------------------------------------
// Report Card Dashboard Summary (from view)
// ---------------------------------------------------------------------------

class ReportCardSummary {
  final String tenantId;
  final String academicYearId;
  final String termId;
  final String sectionId;
  final String sectionName;
  final String classId;
  final String className;
  final int totalReports;
  final int draftCount;
  final int generatedCount;
  final int reviewedCount;
  final int publishedCount;
  final int sentCount;

  const ReportCardSummary({
    required this.tenantId,
    required this.academicYearId,
    required this.termId,
    required this.sectionId,
    required this.sectionName,
    required this.classId,
    required this.className,
    required this.totalReports,
    required this.draftCount,
    required this.generatedCount,
    required this.reviewedCount,
    required this.publishedCount,
    required this.sentCount,
  });

  factory ReportCardSummary.fromJson(Map<String, dynamic> json) {
    return ReportCardSummary(
      tenantId: json['tenant_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      termId: json['term_id'] as String,
      sectionId: json['section_id'] as String,
      sectionName: json['section_name'] as String,
      classId: json['class_id'] as String,
      className: json['class_name'] as String,
      totalReports: json['total_reports'] as int? ?? 0,
      draftCount: json['draft_count'] as int? ?? 0,
      generatedCount: json['generated_count'] as int? ?? 0,
      reviewedCount: json['reviewed_count'] as int? ?? 0,
      publishedCount: json['published_count'] as int? ?? 0,
      sentCount: json['sent_count'] as int? ?? 0,
    );
  }

  int get pendingCount => draftCount + generatedCount + reviewedCount;
  double get publishedPercent =>
      totalReports > 0 ? (publishedCount + sentCount) / totalReports * 100 : 0;
}

// ---------------------------------------------------------------------------
// Filter
// ---------------------------------------------------------------------------

class ReportCardFullFilter {
  final String? academicYearId;
  final String? termId;
  final String? sectionId;
  final String? studentId;
  final String? status;
  final int limit;
  final int offset;

  const ReportCardFullFilter({
    this.academicYearId,
    this.termId,
    this.sectionId,
    this.studentId,
    this.status,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportCardFullFilter &&
          other.academicYearId == academicYearId &&
          other.termId == termId &&
          other.sectionId == sectionId &&
          other.studentId == studentId &&
          other.status == status &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(
        academicYearId,
        termId,
        sectionId,
        studentId,
        status,
        limit,
        offset,
      );
}
