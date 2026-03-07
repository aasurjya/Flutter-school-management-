/// Student Portfolio Models

class PortfolioSummary {
  final String studentId;
  final String studentName;
  final String? photoUrl;
  final String? className;
  final String? sectionName;
  final String rollNumber;

  // Academic stats
  final double? overallPercentage;
  final String? overallGrade;
  final int totalSubjects;
  final List<SubjectScore> subjectScores;

  // Attendance stats
  final int totalWorkingDays;
  final int presentDays;
  final double attendancePercentage;

  // Achievements
  final List<PortfolioAchievement> achievements;
  final int totalPoints;
  final int badgeCount;

  // Homework / Assignments
  final int assignmentsSubmitted;
  final int assignmentsPending;

  const PortfolioSummary({
    required this.studentId,
    required this.studentName,
    this.photoUrl,
    this.className,
    this.sectionName,
    required this.rollNumber,
    this.overallPercentage,
    this.overallGrade,
    required this.totalSubjects,
    required this.subjectScores,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.attendancePercentage,
    required this.achievements,
    required this.totalPoints,
    required this.badgeCount,
    required this.assignmentsSubmitted,
    required this.assignmentsPending,
  });
}

class SubjectScore {
  final String subjectId;
  final String subjectName;
  final double? marksObtained;
  final double? maxMarks;
  final String? grade;
  final double? percentage;

  const SubjectScore({
    required this.subjectId,
    required this.subjectName,
    this.marksObtained,
    this.maxMarks,
    this.grade,
    this.percentage,
  });

  factory SubjectScore.fromJson(Map<String, dynamic> json) {
    final marks = (json['marks_obtained'] as num?)?.toDouble();
    final max = (json['max_marks'] as num?)?.toDouble();
    final pct = (marks != null && max != null && max > 0)
        ? (marks / max * 100)
        : (json['percentage'] as num?)?.toDouble();

    return SubjectScore(
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? json['subjects']?['name'] as String? ?? 'Unknown',
      marksObtained: marks,
      maxMarks: max,
      grade: json['grade'] as String?,
      percentage: pct,
    );
  }
}

class PortfolioAchievement {
  final String id;
  final String title;
  final String? description;
  final String badgeIcon;
  final DateTime earnedAt;
  final int points;

  const PortfolioAchievement({
    required this.id,
    required this.title,
    this.description,
    required this.badgeIcon,
    required this.earnedAt,
    required this.points,
  });

  factory PortfolioAchievement.fromJson(Map<String, dynamic> json) {
    return PortfolioAchievement(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['badge_name'] as String? ?? 'Achievement',
      description: json['description'] as String?,
      badgeIcon: json['badge_icon'] as String? ?? 'star',
      earnedAt: DateTime.parse(json['earned_at'] as String? ?? json['created_at'] as String),
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class PortfolioWork {
  final String id;
  final String title;
  final String? description;
  final String workType; // assignment, project, artwork, certificate
  final String? fileUrl;
  final String? thumbnailUrl;
  final DateTime submittedAt;
  final String? subjectName;
  final String? grade;

  const PortfolioWork({
    required this.id,
    required this.title,
    this.description,
    required this.workType,
    this.fileUrl,
    this.thumbnailUrl,
    required this.submittedAt,
    this.subjectName,
    this.grade,
  });

  factory PortfolioWork.fromJson(Map<String, dynamic> json) {
    return PortfolioWork(
      id: json['id'] as String,
      title: json['title'] as String? ??
          json['assignments']?['title'] as String? ??
          'Work',
      description: json['description'] as String?,
      workType: json['work_type'] as String? ?? 'assignment',
      fileUrl: json['file_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      submittedAt: DateTime.parse(
        json['submitted_at'] as String? ?? json['created_at'] as String,
      ),
      subjectName: json['subject_name'] as String?,
      grade: json['grade'] as String?,
    );
  }
}
