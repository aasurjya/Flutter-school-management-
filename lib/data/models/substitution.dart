import 'package:flutter/material.dart';

// ============================================================
// Enums
// ============================================================

enum AbsenceStatus {
  pending('pending', 'Pending', Colors.orange, Icons.hourglass_empty),
  confirmed('confirmed', 'Confirmed', Colors.green, Icons.check_circle),
  cancelled('cancelled', 'Cancelled', Colors.grey, Icons.cancel);

  const AbsenceStatus(this.dbValue, this.label, this.color, this.icon);
  final String dbValue;
  final String label;
  final Color color;
  final IconData icon;

  static AbsenceStatus fromString(String v) =>
      AbsenceStatus.values.firstWhere((e) => e.dbValue == v,
          orElse: () => AbsenceStatus.pending);
}

enum AbsenceLeaveType {
  sick('sick', 'Sick Leave'),
  casual('casual', 'Casual Leave'),
  personal('personal', 'Personal'),
  emergency('emergency', 'Emergency'),
  other('other', 'Other');

  const AbsenceLeaveType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static AbsenceLeaveType fromString(String v) =>
      AbsenceLeaveType.values.firstWhere((e) => e.dbValue == v,
          orElse: () => AbsenceLeaveType.other);
}

// ============================================================
// TeacherAbsence
// ============================================================

class TeacherAbsence {
  final String id;
  final String tenantId;
  final String teacherId;
  final DateTime absenceDate;
  final String? reason;
  final AbsenceLeaveType leaveType;
  final AbsenceStatus status;
  final String? reportedBy;
  final String? approvedBy;
  final String? notes;
  final DateTime createdAt;

  // Joined
  final String? teacherName;
  final String? reportedByName;

  const TeacherAbsence({
    required this.id,
    required this.tenantId,
    required this.teacherId,
    required this.absenceDate,
    this.reason,
    required this.leaveType,
    required this.status,
    this.reportedBy,
    this.approvedBy,
    this.notes,
    required this.createdAt,
    this.teacherName,
    this.reportedByName,
  });

  factory TeacherAbsence.fromJson(Map<String, dynamic> json) {
    return TeacherAbsence(
      id: json['id'],
      tenantId: json['tenant_id'],
      teacherId: json['teacher_id'],
      absenceDate: DateTime.parse(json['absence_date']),
      reason: json['reason'],
      leaveType: AbsenceLeaveType.fromString(json['leave_type'] ?? 'other'),
      status: AbsenceStatus.fromString(json['status'] ?? 'pending'),
      reportedBy: json['reported_by'],
      approvedBy: json['approved_by'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      teacherName:
          json['teacher']?['full_name'] ?? json['teacher_name'],
      reportedByName:
          json['reporter']?['full_name'] ?? json['reported_by_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'teacher_id': teacherId,
        'absence_date': absenceDate.toIso8601String().split('T')[0],
        'reason': reason,
        'leave_type': leaveType.dbValue,
        'status': status.dbValue,
        'notes': notes,
      };

  bool get isToday {
    final now = DateTime.now();
    return absenceDate.year == now.year &&
        absenceDate.month == now.month &&
        absenceDate.day == now.day;
  }
}

// ============================================================
// SubstituteCandidate — one ranked option per period
// ============================================================

class SubstituteCandidate {
  final String teacherId;
  final String teacherName;
  final int matchScore;
  final String matchReason;
  final int substitutionCountThisMonth;
  final int rank;

  const SubstituteCandidate({
    required this.teacherId,
    required this.teacherName,
    required this.matchScore,
    required this.matchReason,
    required this.substitutionCountThisMonth,
    required this.rank,
  });

  factory SubstituteCandidate.fromJson(Map<String, dynamic> json) {
    return SubstituteCandidate(
      teacherId: json['candidate_teacher_id'],
      teacherName: json['candidate_name'] ?? 'Unknown',
      matchScore: (json['match_score'] as num?)?.toInt() ?? 0,
      matchReason: json['match_reason'] ?? '',
      substitutionCountThisMonth:
          (json['substitution_count_this_month'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 1,
    );
  }

  Color get scoreColor {
    if (matchScore >= 80) return Colors.green;
    if (matchScore >= 50) return Colors.orange;
    return Colors.grey;
  }
}

// ============================================================
// SubstitutePeriod — one period + its ranked candidates
// ============================================================

class SubstitutePeriod {
  final String timetableId;
  final String slotId;
  final String slotName;
  final String startTime;
  final String endTime;
  final String sectionId;
  final String sectionName;
  final String className;
  final String? subjectId;
  final String? subjectName;
  final List<SubstituteCandidate> candidates;

  // Set after admin assigns
  String? assignedTeacherId;
  String? assignedTeacherName;

  SubstitutePeriod({
    required this.timetableId,
    required this.slotId,
    required this.slotName,
    required this.startTime,
    required this.endTime,
    required this.sectionId,
    required this.sectionName,
    required this.className,
    this.subjectId,
    this.subjectName,
    required this.candidates,
    this.assignedTeacherId,
    this.assignedTeacherName,
  });

  bool get isAssigned => assignedTeacherId != null;

  SubstituteCandidate? get topCandidate =>
      candidates.isNotEmpty ? candidates.first : null;
}

// ============================================================
// SubstitutionAssignment — persisted assignment record
// ============================================================

class SubstitutionAssignment {
  final String id;
  final String tenantId;
  final String? absenceId;
  final String? timetableId;
  final String absentTeacherId;
  final String substituteTeacherId;
  final String? slotId;
  final String? sectionId;
  final String? subjectId;
  final DateTime substitutionDate;
  final String status;
  final int matchScore;
  final String? notes;
  final DateTime createdAt;

  // Joined
  final String? slotName;
  final String? startTime;
  final String? endTime;
  final String? sectionName;
  final String? className;
  final String? subjectName;
  final String? absentTeacherName;
  final String? substituteTeacherName;

  const SubstitutionAssignment({
    required this.id,
    required this.tenantId,
    this.absenceId,
    this.timetableId,
    required this.absentTeacherId,
    required this.substituteTeacherId,
    this.slotId,
    this.sectionId,
    this.subjectId,
    required this.substitutionDate,
    required this.status,
    required this.matchScore,
    this.notes,
    required this.createdAt,
    this.slotName,
    this.startTime,
    this.endTime,
    this.sectionName,
    this.className,
    this.subjectName,
    this.absentTeacherName,
    this.substituteTeacherName,
  });

  factory SubstitutionAssignment.fromJson(Map<String, dynamic> json) {
    return SubstitutionAssignment(
      id: json['id'],
      tenantId: json['tenant_id'],
      absenceId: json['absence_id'],
      timetableId: json['timetable_id'],
      absentTeacherId: json['absent_teacher_id'],
      substituteTeacherId: json['substitute_teacher_id'],
      slotId: json['slot_id'],
      sectionId: json['section_id'],
      subjectId: json['subject_id'],
      substitutionDate: DateTime.parse(json['substitution_date']),
      status: json['status'] ?? 'confirmed',
      matchScore: (json['match_score'] as num?)?.toInt() ?? 0,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      slotName: json['timetable_slots']?['name'] ?? json['slot_name'],
      startTime:
          json['timetable_slots']?['start_time'] ?? json['start_time'],
      endTime: json['timetable_slots']?['end_time'] ?? json['end_time'],
      sectionName: json['sections']?['name'] ?? json['section_name'],
      className:
          json['sections']?['classes']?['name'] ?? json['class_name'],
      subjectName: json['subjects']?['name'] ?? json['subject_name'],
      absentTeacherName: json['absent_teacher']?['full_name'] ??
          json['absent_teacher_name'],
      substituteTeacherName: json['substitute_teacher']?['full_name'] ??
          json['substitute_teacher_name'],
    );
  }

  String get timeRange =>
      '${startTime ?? ''} – ${endTime ?? ''}';
}
