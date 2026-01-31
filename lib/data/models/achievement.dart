/// Achievement model
class Achievement {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String category;
  final String? iconName;
  final String? iconUrl;
  final int points;
  final Map<String, dynamic>? criteria;
  final bool isAutomatic;
  final bool isActive;
  final DateTime createdAt;

  const Achievement({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.category,
    this.iconName,
    this.iconUrl,
    this.points = 10,
    this.criteria,
    this.isAutomatic = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      iconName: json['icon_name'],
      iconUrl: json['icon_url'],
      points: json['points'] ?? 10,
      criteria: json['criteria'] != null
          ? Map<String, dynamic>.from(json['criteria'])
          : null,
      isAutomatic: json['is_automatic'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get categoryDisplay {
    switch (category) {
      case 'academic':
        return 'Academic';
      case 'attendance':
        return 'Attendance';
      case 'sports':
        return 'Sports';
      case 'arts':
        return 'Arts';
      case 'behavior':
        return 'Behavior';
      case 'leadership':
        return 'Leadership';
      case 'community':
        return 'Community';
      case 'special':
        return 'Special';
      default:
        return category;
    }
  }
}

/// Student achievement model
class StudentAchievement {
  final String id;
  final String tenantId;
  final String studentId;
  final String achievementId;
  final DateTime earnedAt;
  final String? awardedBy;
  final String? notes;

  // Related data
  final Achievement? achievement;

  const StudentAchievement({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.achievementId,
    required this.earnedAt,
    this.awardedBy,
    this.notes,
    this.achievement,
  });

  factory StudentAchievement.fromJson(Map<String, dynamic> json) {
    Achievement? achievement;
    if (json['achievements'] != null) {
      achievement = Achievement.fromJson(json['achievements']);
    }

    return StudentAchievement(
      id: json['id'],
      tenantId: json['tenant_id'],
      studentId: json['student_id'],
      achievementId: json['achievement_id'],
      earnedAt: DateTime.parse(json['earned_at']),
      awardedBy: json['awarded_by'],
      notes: json['notes'],
      achievement: achievement,
    );
  }
}

/// Student points model
class StudentPoints {
  final String id;
  final String tenantId;
  final String studentId;
  final String category;
  final int points;
  final String? academicYearId;
  final DateTime updatedAt;

  const StudentPoints({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.category,
    required this.points,
    this.academicYearId,
    required this.updatedAt,
  });

  factory StudentPoints.fromJson(Map<String, dynamic> json) {
    return StudentPoints(
      id: json['id'],
      tenantId: json['tenant_id'],
      studentId: json['student_id'],
      category: json['category'],
      points: json['points'] ?? 0,
      academicYearId: json['academic_year_id'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get categoryDisplay {
    switch (category) {
      case 'academic':
        return 'Academic';
      case 'attendance':
        return 'Attendance';
      case 'sports':
        return 'Sports';
      case 'arts':
        return 'Arts';
      case 'behavior':
        return 'Behavior';
      case 'leadership':
        return 'Leadership';
      case 'community':
        return 'Community';
      case 'special':
        return 'Special';
      default:
        return category;
    }
  }
}

/// Point transaction model
class PointTransaction {
  final String id;
  final String tenantId;
  final String studentId;
  final int points;
  final String category;
  final String reason;
  final String? referenceType;
  final String? referenceId;
  final String? awardedBy;
  final DateTime createdAt;

  const PointTransaction({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.points,
    required this.category,
    required this.reason,
    this.referenceType,
    this.referenceId,
    this.awardedBy,
    required this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'],
      tenantId: json['tenant_id'],
      studentId: json['student_id'],
      points: json['points'],
      category: json['category'],
      reason: json['reason'],
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      awardedBy: json['awarded_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isPositive => points > 0;
}

/// Leaderboard entry model
class LeaderboardEntry {
  final String studentId;
  final String tenantId;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String? sectionId;
  final String? sectionName;
  final String? className;
  final int totalPoints;
  final int achievementCount;
  final int tenantRank;
  final int sectionRank;

  const LeaderboardEntry({
    required this.studentId,
    required this.tenantId,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.sectionId,
    this.sectionName,
    this.className,
    required this.totalPoints,
    required this.achievementCount,
    required this.tenantRank,
    required this.sectionRank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      studentId: json['student_id'],
      tenantId: json['tenant_id'],
      firstName: json['first_name'],
      lastName: json['last_name'] ?? '',
      photoUrl: json['photo_url'],
      sectionId: json['section_id'],
      sectionName: json['section_name'],
      className: json['class_name'],
      totalPoints: json['total_points'] ?? 0,
      achievementCount: json['achievement_count'] ?? 0,
      tenantRank: json['tenant_rank'] ?? 0,
      sectionRank: json['section_rank'] ?? 0,
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }
}
