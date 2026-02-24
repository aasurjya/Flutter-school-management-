import '../../features/ai_insights/utils/digest_template_engine.dart';

class ParentDigest {
  final String id;
  final String studentId;
  final String parentId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final String title;
  final String? summary;
  final List<DigestSection> sections;
  final WeeklyAttendance attendance;
  final List<AcademicHighlight> highlights;
  final List<UpcomingEvent> events;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  const ParentDigest({
    required this.id,
    required this.studentId,
    required this.parentId,
    required this.weekStart,
    required this.weekEnd,
    required this.title,
    this.summary,
    this.sections = const [],
    required this.attendance,
    this.highlights = const [],
    this.events = const [],
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });

  factory ParentDigest.fromJson(Map<String, dynamic> json) {
    return ParentDigest(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      parentId: json['parent_id'] ?? '',
      weekStart: DateTime.parse(json['week_start']),
      weekEnd: DateTime.parse(json['week_end']),
      title: json['title'] ?? '',
      summary: json['summary'],
      sections: (json['sections'] as List?)
              ?.map((s) => DigestSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      attendance: WeeklyAttendance(
        present: json['attendance_present'] ?? 0,
        absent: json['attendance_absent'] ?? 0,
        late: json['attendance_late'] ?? 0,
        total: json['attendance_total'] ?? 0,
      ),
      highlights: (json['highlights'] as List?)
              ?.map(
                  (h) => AcademicHighlight.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      events: (json['upcoming_events'] as List?)
              ?.map((e) => UpcomingEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  String get weekLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekStart.day} ${months[weekStart.month - 1]} - '
        '${weekEnd.day} ${months[weekEnd.month - 1]}';
  }

  bool get hasUrgentItems {
    return sections.any((s) => s.urgency == 'urgent') ||
        attendance.percentage < 60;
  }
}

class WeeklyAttendance {
  final int present;
  final int absent;
  final int late;
  final int total;

  const WeeklyAttendance({
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.total = 0,
  });

  double get percentage => total > 0 ? (present / total) * 100 : 0;
}

class AcademicHighlight {
  final String type;
  final String description;
  final String? subjectName;
  final double? score;

  const AcademicHighlight({
    required this.type,
    required this.description,
    this.subjectName,
    this.score,
  });

  factory AcademicHighlight.fromJson(Map<String, dynamic> json) {
    return AcademicHighlight(
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      subjectName: json['subject_name'],
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        if (subjectName != null) 'subject_name': subjectName,
        if (score != null) 'score': score,
      };
}

class UpcomingEvent {
  final String title;
  final DateTime date;
  final String? type;

  const UpcomingEvent({
    required this.title,
    required this.date,
    this.type,
  });

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) {
    return UpcomingEvent(
      title: json['title'] ?? '',
      date: DateTime.parse(json['date']),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date.toIso8601String(),
        if (type != null) 'type': type,
      };
}
