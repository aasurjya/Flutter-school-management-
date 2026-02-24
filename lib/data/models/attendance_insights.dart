class AttendanceInsights {
  final String sectionId;
  final List<DayPattern> dayPatterns;
  final List<ChronicAbsentee> chronicAbsentees;
  final List<AttendanceAnomaly> anomalies;
  final List<StudentStreak> streaks;
  final double overallTrend;

  const AttendanceInsights({
    required this.sectionId,
    this.dayPatterns = const [],
    this.chronicAbsentees = const [],
    this.anomalies = const [],
    this.streaks = const [],
    this.overallTrend = 0,
  });
}

class DayPattern {
  final int dayOfWeek; // 0=Sunday, 1=Monday, ...
  final String dayName;
  final int totalRecords;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final double attendancePercentage;

  const DayPattern({
    required this.dayOfWeek,
    required this.dayName,
    this.totalRecords = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.attendancePercentage = 0,
  });

  factory DayPattern.fromJson(Map<String, dynamic> json) {
    return DayPattern(
      dayOfWeek: json['day_of_week'] ?? 0,
      dayName: (json['day_name'] as String?)?.trim() ?? '',
      totalRecords: json['total_records'] ?? 0,
      presentCount: json['present_count'] ?? 0,
      absentCount: json['absent_count'] ?? 0,
      lateCount: json['late_count'] ?? 0,
      attendancePercentage:
          (json['attendance_percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get isProblematic => attendancePercentage < 85;

  String get shortDayName {
    final clean = dayName.trim();
    return clean.length >= 3 ? clean.substring(0, 3) : clean;
  }
}

class ChronicAbsentee {
  final String studentId;
  final String studentName;
  final String? admissionNumber;
  final String sectionId;
  final String? sectionName;
  final String? className;
  final int totalDays;
  final int absentDays;
  final double absenceRate;

  const ChronicAbsentee({
    required this.studentId,
    required this.studentName,
    this.admissionNumber,
    required this.sectionId,
    this.sectionName,
    this.className,
    this.totalDays = 0,
    this.absentDays = 0,
    this.absenceRate = 0,
  });

  factory ChronicAbsentee.fromJson(Map<String, dynamic> json) {
    return ChronicAbsentee(
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      admissionNumber: json['admission_number'],
      sectionId: json['section_id'] ?? '',
      sectionName: json['section_name'],
      className: json['class_name'],
      totalDays: json['total_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      absenceRate: (json['absence_rate'] as num?)?.toDouble() ?? 0,
    );
  }

  String get severityLabel {
    if (absenceRate > 40) return 'Critical';
    if (absenceRate > 30) return 'High';
    return 'Moderate';
  }
}

class AttendanceAnomaly {
  final DateTime date;
  final double attendancePercentage;
  final double expectedPercentage;
  final double deviation;
  final String type; // 'drop', 'spike'

  const AttendanceAnomaly({
    required this.date,
    required this.attendancePercentage,
    required this.expectedPercentage,
    required this.deviation,
    required this.type,
  });
}

class StudentStreak {
  final String studentId;
  final String studentName;
  final String streakType; // 'present', 'absent'
  final int streakLength;
  final DateTime? streakStart;
  final DateTime? streakEnd;

  const StudentStreak({
    required this.studentId,
    required this.studentName,
    required this.streakType,
    required this.streakLength,
    this.streakStart,
    this.streakEnd,
  });
}
