// Student Insights Model for Parent Dashboard
// Provides comprehensive analysis of student performance

class StudentInsights {
  final String studentId;
  final String studentName;
  final String className;
  final String sectionName;

  // Overall Performance
  final double overallPercentage;
  final int classRank;
  final int totalInClass;
  final double attendancePercentage;

  // Subject-wise performance
  final List<SubjectInsight> subjectInsights;

  // Comparison with class average
  final double classAveragePercentage;
  final double performanceVsClass; // positive = above average

  // Trends
  final List<PerformanceTrend> trends;

  // Strengths and weaknesses
  final List<String> strengths;
  final List<String> areasForImprovement;

  // Improvement tips
  final List<ImprovementTip> tips;

  // Gamification data
  final int totalPoints;
  final int achievementsCount;
  final int schoolRank;

  const StudentInsights({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.sectionName,
    required this.overallPercentage,
    required this.classRank,
    required this.totalInClass,
    required this.attendancePercentage,
    required this.subjectInsights,
    required this.classAveragePercentage,
    required this.performanceVsClass,
    required this.trends,
    required this.strengths,
    required this.areasForImprovement,
    required this.tips,
    this.totalPoints = 0,
    this.achievementsCount = 0,
    this.schoolRank = 0,
  });

  factory StudentInsights.fromJson(Map<String, dynamic> json) {
    return StudentInsights(
      studentId: json['student_id'],
      studentName: json['student_name'],
      className: json['class_name'] ?? '',
      sectionName: json['section_name'] ?? '',
      overallPercentage: (json['overall_percentage'] as num?)?.toDouble() ?? 0,
      classRank: json['class_rank'] ?? 0,
      totalInClass: json['total_in_class'] ?? 0,
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble() ?? 0,
      subjectInsights: (json['subject_insights'] as List?)
              ?.map((s) => SubjectInsight.fromJson(s))
              .toList() ??
          [],
      classAveragePercentage:
          (json['class_average_percentage'] as num?)?.toDouble() ?? 0,
      performanceVsClass:
          (json['performance_vs_class'] as num?)?.toDouble() ?? 0,
      trends: (json['trends'] as List?)
              ?.map((t) => PerformanceTrend.fromJson(t))
              .toList() ??
          [],
      strengths: (json['strengths'] as List?)?.cast<String>() ?? [],
      areasForImprovement:
          (json['areas_for_improvement'] as List?)?.cast<String>() ?? [],
      tips: (json['tips'] as List?)
              ?.map((t) => ImprovementTip.fromJson(t))
              .toList() ??
          [],
      totalPoints: json['total_points'] ?? 0,
      achievementsCount: json['achievements_count'] ?? 0,
      schoolRank: json['school_rank'] ?? 0,
    );
  }

  /// Get performance level based on percentage
  String get performanceLevel {
    if (overallPercentage >= 90) return 'Excellent';
    if (overallPercentage >= 75) return 'Good';
    if (overallPercentage >= 60) return 'Average';
    if (overallPercentage >= 40) return 'Below Average';
    return 'Needs Improvement';
  }

  /// Get attendance status
  String get attendanceStatus {
    if (attendancePercentage >= 90) return 'Excellent';
    if (attendancePercentage >= 75) return 'Good';
    if (attendancePercentage >= 60) return 'Concerning';
    return 'Critical';
  }

  /// Check if performing above class average
  bool get isAboveClassAverage => performanceVsClass > 0;
}

class SubjectInsight {
  final String subjectId;
  final String subjectName;
  final String? subjectCode;
  final double percentage;
  final double classAverage;
  final int subjectRank;
  final int totalInSubject;
  final double performanceVsClass;
  final String trend; // 'improving', 'declining', 'stable'
  final List<double> recentScores;

  const SubjectInsight({
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
    required this.percentage,
    required this.classAverage,
    required this.subjectRank,
    required this.totalInSubject,
    required this.performanceVsClass,
    required this.trend,
    required this.recentScores,
  });

  factory SubjectInsight.fromJson(Map<String, dynamic> json) {
    return SubjectInsight(
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
      subjectCode: json['subject_code'],
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      classAverage: (json['class_average'] as num?)?.toDouble() ?? 0,
      subjectRank: json['subject_rank'] ?? 0,
      totalInSubject: json['total_in_subject'] ?? 0,
      performanceVsClass:
          (json['performance_vs_class'] as num?)?.toDouble() ?? 0,
      trend: json['trend'] ?? 'stable',
      recentScores: (json['recent_scores'] as List?)
              ?.map((s) => (s as num).toDouble())
              .toList() ??
          [],
    );
  }

  /// Check if this is a strength subject
  bool get isStrength => performanceVsClass >= 10;

  /// Check if this needs improvement
  bool get needsImprovement => performanceVsClass <= -10;

  /// Get trend icon name
  String get trendIcon {
    switch (trend) {
      case 'improving':
        return 'trending_up';
      case 'declining':
        return 'trending_down';
      default:
        return 'trending_flat';
    }
  }
}

class PerformanceTrend {
  final String examName;
  final String examType;
  final DateTime examDate;
  final double percentage;
  final int classRank;

  const PerformanceTrend({
    required this.examName,
    required this.examType,
    required this.examDate,
    required this.percentage,
    required this.classRank,
  });

  factory PerformanceTrend.fromJson(Map<String, dynamic> json) {
    return PerformanceTrend(
      examName: json['exam_name'],
      examType: json['exam_type'],
      examDate: DateTime.parse(json['exam_date']),
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      classRank: json['class_rank'] ?? 0,
    );
  }
}

class ImprovementTip {
  final String category;
  final String title;
  final String description;
  final String? subjectName;
  final int priority; // 1 = high, 2 = medium, 3 = low

  const ImprovementTip({
    required this.category,
    required this.title,
    required this.description,
    this.subjectName,
    this.priority = 2,
  });

  factory ImprovementTip.fromJson(Map<String, dynamic> json) {
    return ImprovementTip(
      category: json['category'],
      title: json['title'],
      description: json['description'],
      subjectName: json['subject_name'],
      priority: json['priority'] ?? 2,
    );
  }

  factory ImprovementTip.forSubject({
    required String subjectName,
    required double percentage,
    required String trend,
  }) {
    if (percentage < 40) {
      return ImprovementTip(
        category: 'academic',
        title: 'Focus on $subjectName',
        description:
            'Consider getting extra help or tutoring for $subjectName. Practice more problems and review fundamentals.',
        subjectName: subjectName,
        priority: 1,
      );
    } else if (percentage < 60) {
      return ImprovementTip(
        category: 'academic',
        title: 'Improve $subjectName',
        description:
            'Dedicate 30 minutes daily to $subjectName practice. Focus on understanding concepts rather than memorization.',
        subjectName: subjectName,
        priority: 2,
      );
    } else if (trend == 'declining') {
      return ImprovementTip(
        category: 'academic',
        title: 'Maintain $subjectName performance',
        description:
            'Your performance in $subjectName has been declining. Review recent topics and identify areas of confusion.',
        subjectName: subjectName,
        priority: 2,
      );
    }
    return ImprovementTip(
      category: 'academic',
      title: 'Keep up the good work in $subjectName',
      description:
          'Continue your efforts in $subjectName. Challenge yourself with advanced problems.',
      subjectName: subjectName,
      priority: 3,
    );
  }

  factory ImprovementTip.forAttendance(double percentage) {
    if (percentage < 60) {
      return const ImprovementTip(
        category: 'attendance',
        title: 'Critical: Improve Attendance',
        description:
            'Attendance below 60% severely impacts learning. Regular attendance is essential for academic success.',
        priority: 1,
      );
    } else if (percentage < 75) {
      return const ImprovementTip(
        category: 'attendance',
        title: 'Improve Attendance',
        description:
            'Try to attend school more regularly. Missing classes can lead to gaps in understanding.',
        priority: 2,
      );
    }
    return const ImprovementTip(
      category: 'attendance',
      title: 'Great Attendance',
      description: 'Keep maintaining good attendance for continued success.',
      priority: 3,
    );
  }
}

/// Monthly attendance summary for charts
class MonthlyAttendanceSummary {
  final int month;
  final int year;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;

  const MonthlyAttendanceSummary({
    required this.month,
    required this.year,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
  });

  factory MonthlyAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceSummary(
      month: json['month'],
      year: json['year'],
      totalDays: json['total_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      lateDays: json['late_days'] ?? 0,
    );
  }

  double get attendancePercentage =>
      totalDays > 0 ? (presentDays / totalDays) * 100 : 0;

  String get monthName {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

/// Comparison data for radar chart
class SubjectComparison {
  final String subjectName;
  final double studentScore;
  final double classAverage;
  final double topperScore;

  const SubjectComparison({
    required this.subjectName,
    required this.studentScore,
    required this.classAverage,
    required this.topperScore,
  });

  factory SubjectComparison.fromJson(Map<String, dynamic> json) {
    return SubjectComparison(
      subjectName: json['subject_name'],
      studentScore: (json['student_score'] as num?)?.toDouble() ?? 0,
      classAverage: (json['class_average'] as num?)?.toDouble() ?? 0,
      topperScore: (json['topper_score'] as num?)?.toDouble() ?? 0,
    );
  }
}
