// ─── Enums ───────────────────────────────────────────────────

enum BehaviorCategoryType {
  positive,
  negative;

  String get value => name;

  static BehaviorCategoryType fromString(String s) =>
      BehaviorCategoryType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => BehaviorCategoryType.negative,
      );
}

enum IncidentSeverity {
  minor,
  moderate,
  major,
  critical;

  String get value => name;

  String get displayLabel =>
      '${name[0].toUpperCase()}${name.substring(1)}';

  static IncidentSeverity fromString(String s) =>
      IncidentSeverity.values.firstWhere(
        (e) => e.name == s,
        orElse: () => IncidentSeverity.minor,
      );
}

enum IncidentStatus {
  reported,
  investigating,
  resolved,
  escalated;

  String get value => name;

  String get displayLabel =>
      '${name[0].toUpperCase()}${name.substring(1)}';

  static IncidentStatus fromString(String s) =>
      IncidentStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => IncidentStatus.reported,
      );
}

enum BehaviorActionType {
  verbalWarning('verbal_warning', 'Verbal Warning'),
  writtenWarning('written_warning', 'Written Warning'),
  detention('detention', 'Detention'),
  suspension('suspension', 'Suspension'),
  expulsion('expulsion', 'Expulsion'),
  counseling('counseling', 'Counseling'),
  parentMeeting('parent_meeting', 'Parent Meeting'),
  communityService('community_service', 'Community Service');

  final String value;
  final String displayLabel;

  const BehaviorActionType(this.value, this.displayLabel);

  static BehaviorActionType fromString(String s) =>
      BehaviorActionType.values.firstWhere(
        (e) => e.value == s,
        orElse: () => BehaviorActionType.verbalWarning,
      );
}

enum BehaviorPlanStatus {
  active,
  completed,
  discontinued;

  String get value => name;

  String get displayLabel =>
      '${name[0].toUpperCase()}${name.substring(1)}';

  static BehaviorPlanStatus fromString(String s) =>
      BehaviorPlanStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => BehaviorPlanStatus.active,
      );
}

enum DetentionAssignmentStatus {
  assigned,
  served,
  missed,
  excused;

  String get value => name;

  String get displayLabel =>
      '${name[0].toUpperCase()}${name.substring(1)}';

  static DetentionAssignmentStatus fromString(String s) =>
      DetentionAssignmentStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => DetentionAssignmentStatus.assigned,
      );
}

// ─── Models ──────────────────────────────────────────────────

class BehaviorCategory {
  final String id;
  final String tenantId;
  final String name;
  final BehaviorCategoryType type;
  final int points;
  final String? icon;
  final String? color;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BehaviorCategory({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    this.points = 0,
    this.icon,
    this.color,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BehaviorCategory.fromJson(Map<String, dynamic> json) {
    return BehaviorCategory(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      name: json['name'] ?? '',
      type: BehaviorCategoryType.fromString(json['type'] ?? 'negative'),
      points: json['points'] ?? 0,
      icon: json['icon'],
      color: json['color'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'name': name,
        'type': type.value,
        'points': points,
        'icon': icon,
        'color': color,
        'description': description,
        'is_active': isActive,
      };
}

class BehaviorIncident {
  final String id;
  final String tenantId;
  final String studentId;
  final String reportedBy;
  final String? categoryId;
  final DateTime incidentDate;
  final String? incidentTime;
  final String description;
  final IncidentSeverity severity;
  final String? location;
  final List<dynamic> witnesses;
  final List<dynamic> evidenceUrls;
  final IncidentStatus status;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? studentName;
  final String? studentPhotoUrl;
  final String? reporterName;
  final String? categoryName;
  final BehaviorCategoryType? categoryType;
  final List<BehaviorAction>? actions;

  const BehaviorIncident({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.reportedBy,
    this.categoryId,
    required this.incidentDate,
    this.incidentTime,
    required this.description,
    this.severity = IncidentSeverity.minor,
    this.location,
    this.witnesses = const [],
    this.evidenceUrls = const [],
    this.status = IncidentStatus.reported,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.studentPhotoUrl,
    this.reporterName,
    this.categoryName,
    this.categoryType,
    this.actions,
  });

  factory BehaviorIncident.fromJson(Map<String, dynamic> json) {
    // Extract student name from nested join
    String? studentName;
    String? studentPhotoUrl;
    if (json['student'] != null) {
      final s = json['student'];
      studentName =
          '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
      studentPhotoUrl = s['photo_url'];
    }

    // Extract reporter name
    String? reporterName;
    if (json['reporter'] != null) {
      reporterName = json['reporter']['full_name'];
    }

    // Extract category
    String? categoryName;
    BehaviorCategoryType? categoryType;
    if (json['category'] != null) {
      categoryName = json['category']['name'];
      categoryType = BehaviorCategoryType.fromString(
        json['category']['type'] ?? 'negative',
      );
    }

    // Parse actions
    List<BehaviorAction>? actions;
    if (json['behavior_actions'] != null) {
      actions = (json['behavior_actions'] as List)
          .map((a) => BehaviorAction.fromJson(a))
          .toList();
    }

    return BehaviorIncident(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      studentId: json['student_id'] ?? '',
      reportedBy: json['reported_by'] ?? '',
      categoryId: json['category_id'],
      incidentDate: json['incident_date'] != null
          ? DateTime.parse(json['incident_date'])
          : DateTime.now(),
      incidentTime: json['incident_time'],
      description: json['description'] ?? '',
      severity:
          IncidentSeverity.fromString(json['severity'] ?? 'minor'),
      location: json['location'],
      witnesses: json['witnesses'] ?? [],
      evidenceUrls: json['evidence_urls'] ?? [],
      status: IncidentStatus.fromString(json['status'] ?? 'reported'),
      resolutionNotes: json['resolution_notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      studentName: studentName,
      studentPhotoUrl: studentPhotoUrl,
      reporterName: reporterName,
      categoryName: categoryName,
      categoryType: categoryType,
      actions: actions,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'student_id': studentId,
        'reported_by': reportedBy,
        'category_id': categoryId,
        'incident_date':
            incidentDate.toIso8601String().split('T')[0],
        'incident_time': incidentTime,
        'description': description,
        'severity': severity.value,
        'location': location,
        'witnesses': witnesses,
        'evidence_urls': evidenceUrls,
        'status': status.value,
        'resolution_notes': resolutionNotes,
      };
}

class BehaviorAction {
  final String id;
  final String incidentId;
  final BehaviorActionType actionType;
  final String assignedBy;
  final String? assignedTo;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final bool completed;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? assignedByName;
  final String? assignedToName;

  const BehaviorAction({
    required this.id,
    required this.incidentId,
    required this.actionType,
    required this.assignedBy,
    this.assignedTo,
    this.startDate,
    this.endDate,
    this.notes,
    this.completed = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.assignedByName,
    this.assignedToName,
  });

  factory BehaviorAction.fromJson(Map<String, dynamic> json) {
    String? assignedByName;
    if (json['assigner'] != null) {
      assignedByName = json['assigner']['full_name'];
    }
    String? assignedToName;
    if (json['assignee'] != null) {
      assignedToName = json['assignee']['full_name'];
    }

    return BehaviorAction(
      id: json['id'] ?? '',
      incidentId: json['incident_id'] ?? '',
      actionType:
          BehaviorActionType.fromString(json['action_type'] ?? 'verbal_warning'),
      assignedBy: json['assigned_by'] ?? '',
      assignedTo: json['assigned_to'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      notes: json['notes'],
      completed: json['completed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      assignedByName: assignedByName,
      assignedToName: assignedToName,
    );
  }

  Map<String, dynamic> toJson() => {
        'incident_id': incidentId,
        'action_type': actionType.value,
        'assigned_by': assignedBy,
        'assigned_to': assignedTo,
        'start_date': startDate?.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'notes': notes,
        'completed': completed,
      };
}

class BehaviorPlan {
  final String id;
  final String tenantId;
  final String studentId;
  final String createdBy;
  final String title;
  final String? description;
  final List<dynamic> goals;
  final List<dynamic> strategies;
  final DateTime startDate;
  final DateTime? reviewDate;
  final BehaviorPlanStatus status;
  final bool parentAcknowledged;
  final DateTime? parentAcknowledgedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? studentName;
  final String? createdByName;
  final List<BehaviorPlanReview>? reviews;

  const BehaviorPlan({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.createdBy,
    required this.title,
    this.description,
    this.goals = const [],
    this.strategies = const [],
    required this.startDate,
    this.reviewDate,
    this.status = BehaviorPlanStatus.active,
    this.parentAcknowledged = false,
    this.parentAcknowledgedAt,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.createdByName,
    this.reviews,
  });

  factory BehaviorPlan.fromJson(Map<String, dynamic> json) {
    String? studentName;
    if (json['student'] != null) {
      final s = json['student'];
      studentName =
          '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
    }
    String? createdByName;
    if (json['creator'] != null) {
      createdByName = json['creator']['full_name'];
    }

    List<BehaviorPlanReview>? reviews;
    if (json['behavior_plan_reviews'] != null) {
      reviews = (json['behavior_plan_reviews'] as List)
          .map((r) => BehaviorPlanReview.fromJson(r))
          .toList();
    }

    return BehaviorPlan(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      studentId: json['student_id'] ?? '',
      createdBy: json['created_by'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      goals: json['goals'] ?? [],
      strategies: json['strategies'] ?? [],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      reviewDate: json['review_date'] != null
          ? DateTime.parse(json['review_date'])
          : null,
      status:
          BehaviorPlanStatus.fromString(json['status'] ?? 'active'),
      parentAcknowledged: json['parent_acknowledged'] ?? false,
      parentAcknowledgedAt: json['parent_acknowledged_at'] != null
          ? DateTime.parse(json['parent_acknowledged_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      studentName: studentName,
      createdByName: createdByName,
      reviews: reviews,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'student_id': studentId,
        'created_by': createdBy,
        'title': title,
        'description': description,
        'goals': goals,
        'strategies': strategies,
        'start_date': startDate.toIso8601String().split('T')[0],
        'review_date': reviewDate?.toIso8601String().split('T')[0],
        'status': status.value,
        'parent_acknowledged': parentAcknowledged,
      };
}

class BehaviorPlanReview {
  final String id;
  final String planId;
  final String reviewedBy;
  final DateTime reviewDate;
  final String? progressNotes;
  final Map<String, dynamic> goalProgress;
  final String? outcome;
  final DateTime? nextReviewDate;
  final DateTime createdAt;

  // Joined
  final String? reviewerName;

  const BehaviorPlanReview({
    required this.id,
    required this.planId,
    required this.reviewedBy,
    required this.reviewDate,
    this.progressNotes,
    this.goalProgress = const {},
    this.outcome,
    this.nextReviewDate,
    required this.createdAt,
    this.reviewerName,
  });

  factory BehaviorPlanReview.fromJson(Map<String, dynamic> json) {
    String? reviewerName;
    if (json['reviewer'] != null) {
      reviewerName = json['reviewer']['full_name'];
    }

    return BehaviorPlanReview(
      id: json['id'] ?? '',
      planId: json['plan_id'] ?? '',
      reviewedBy: json['reviewed_by'] ?? '',
      reviewDate: json['review_date'] != null
          ? DateTime.parse(json['review_date'])
          : DateTime.now(),
      progressNotes: json['progress_notes'],
      goalProgress:
          (json['goal_progress'] as Map<String, dynamic>?) ?? {},
      outcome: json['outcome'],
      nextReviewDate: json['next_review_date'] != null
          ? DateTime.parse(json['next_review_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      reviewerName: reviewerName,
    );
  }

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'reviewed_by': reviewedBy,
        'review_date': reviewDate.toIso8601String().split('T')[0],
        'progress_notes': progressNotes,
        'goal_progress': goalProgress,
        'outcome': outcome,
        'next_review_date':
            nextReviewDate?.toIso8601String().split('T')[0],
      };
}

class PositiveRecognition {
  final String id;
  final String tenantId;
  final String studentId;
  final String recognizedBy;
  final String? categoryId;
  final String description;
  final int pointsAwarded;
  final bool isPublic;
  final DateTime createdAt;

  // Joined
  final String? studentName;
  final String? studentPhotoUrl;
  final String? recognizerName;
  final String? categoryName;

  const PositiveRecognition({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.recognizedBy,
    this.categoryId,
    required this.description,
    this.pointsAwarded = 0,
    this.isPublic = true,
    required this.createdAt,
    this.studentName,
    this.studentPhotoUrl,
    this.recognizerName,
    this.categoryName,
  });

  factory PositiveRecognition.fromJson(Map<String, dynamic> json) {
    String? studentName;
    String? studentPhotoUrl;
    if (json['student'] != null) {
      final s = json['student'];
      studentName =
          '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
      studentPhotoUrl = s['photo_url'];
    }
    String? recognizerName;
    if (json['recognizer'] != null) {
      recognizerName = json['recognizer']['full_name'];
    }
    String? categoryName;
    if (json['category'] != null) {
      categoryName = json['category']['name'];
    }

    return PositiveRecognition(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      studentId: json['student_id'] ?? '',
      recognizedBy: json['recognized_by'] ?? '',
      categoryId: json['category_id'],
      description: json['description'] ?? '',
      pointsAwarded: json['points_awarded'] ?? 0,
      isPublic: json['is_public'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      studentName: studentName,
      studentPhotoUrl: studentPhotoUrl,
      recognizerName: recognizerName,
      categoryName: categoryName,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'student_id': studentId,
        'recognized_by': recognizedBy,
        'category_id': categoryId,
        'description': description,
        'points_awarded': pointsAwarded,
        'is_public': isPublic,
      };
}

class DetentionSchedule {
  final String id;
  final String tenantId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String location;
  final String? supervisorId;
  final int capacity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? supervisorName;

  const DetentionSchedule({
    required this.id,
    required this.tenantId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.supervisorId,
    this.capacity = 30,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.supervisorName,
  });

  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek];
  }

  factory DetentionSchedule.fromJson(Map<String, dynamic> json) {
    String? supervisorName;
    if (json['supervisor'] != null) {
      supervisorName = json['supervisor']['full_name'];
    }

    return DetentionSchedule(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 0,
      startTime: json['start_time'] ?? '15:00',
      endTime: json['end_time'] ?? '16:00',
      location: json['location'] ?? '',
      supervisorId: json['supervisor_id'],
      capacity: json['capacity'] ?? 30,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      supervisorName: supervisorName,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'location': location,
        'supervisor_id': supervisorId,
        'capacity': capacity,
        'is_active': isActive,
      };
}

class DetentionAssignment {
  final String id;
  final String tenantId;
  final String studentId;
  final String? incidentId;
  final String? scheduleId;
  final DateTime detentionDate;
  final String assignedBy;
  final DetentionAssignmentStatus status;
  final String? notes;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? studentName;
  final String? assignerName;

  const DetentionAssignment({
    required this.id,
    required this.tenantId,
    required this.studentId,
    this.incidentId,
    this.scheduleId,
    required this.detentionDate,
    required this.assignedBy,
    this.status = DetentionAssignmentStatus.assigned,
    this.notes,
    this.checkInTime,
    this.checkOutTime,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.assignerName,
  });

  factory DetentionAssignment.fromJson(Map<String, dynamic> json) {
    String? studentName;
    if (json['student'] != null) {
      final s = json['student'];
      studentName =
          '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
    }
    String? assignerName;
    if (json['assigner'] != null) {
      assignerName = json['assigner']['full_name'];
    }

    return DetentionAssignment(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      studentId: json['student_id'] ?? '',
      incidentId: json['incident_id'],
      scheduleId: json['schedule_id'],
      detentionDate: json['detention_date'] != null
          ? DateTime.parse(json['detention_date'])
          : DateTime.now(),
      assignedBy: json['assigned_by'] ?? '',
      status: DetentionAssignmentStatus.fromString(
          json['status'] ?? 'assigned'),
      notes: json['notes'],
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      studentName: studentName,
      assignerName: assignerName,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'student_id': studentId,
        'incident_id': incidentId,
        'schedule_id': scheduleId,
        'detention_date':
            detentionDate.toIso8601String().split('T')[0],
        'assigned_by': assignedBy,
        'status': status.value,
        'notes': notes,
      };
}

/// Aggregated behavior score for a student
class BehaviorScore {
  final String studentId;
  final int positivePoints;
  final int negativePoints;
  final int netScore;
  final int incidentCount;
  final int recognitionCount;

  const BehaviorScore({
    required this.studentId,
    this.positivePoints = 0,
    this.negativePoints = 0,
    this.netScore = 0,
    this.incidentCount = 0,
    this.recognitionCount = 0,
  });

  factory BehaviorScore.fromJson(Map<String, dynamic> json) {
    return BehaviorScore(
      studentId: json['student_id'] ?? '',
      positivePoints: json['positive_points'] ?? 0,
      negativePoints: json['negative_points'] ?? 0,
      netScore: json['net_score'] ?? 0,
      incidentCount: json['incident_count'] ?? 0,
      recognitionCount: json['recognition_count'] ?? 0,
    );
  }
}

/// Statistics for the discipline dashboard
class BehaviorStats {
  final int totalIncidents;
  final int openIncidents;
  final int resolvedIncidents;
  final int totalRecognitions;
  final Map<String, int> incidentsBySeverity;
  final Map<String, int> incidentsByCategory;
  final List<DailyIncidentCount> dailyTrend;

  const BehaviorStats({
    this.totalIncidents = 0,
    this.openIncidents = 0,
    this.resolvedIncidents = 0,
    this.totalRecognitions = 0,
    this.incidentsBySeverity = const {},
    this.incidentsByCategory = const {},
    this.dailyTrend = const [],
  });
}

class DailyIncidentCount {
  final DateTime date;
  final int count;

  const DailyIncidentCount({required this.date, required this.count});
}

/// Filter for listing incidents
class IncidentFilter {
  final IncidentSeverity? severity;
  final IncidentStatus? status;
  final String? classId;
  final String? sectionId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? studentId;
  final int limit;
  final int offset;

  const IncidentFilter({
    this.severity,
    this.status,
    this.classId,
    this.sectionId,
    this.startDate,
    this.endDate,
    this.studentId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncidentFilter &&
        other.severity == severity &&
        other.status == status &&
        other.classId == classId &&
        other.sectionId == sectionId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.studentId == studentId &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        status,
        classId,
        sectionId,
        startDate,
        endDate,
        studentId,
        limit,
        offset,
      );
}
