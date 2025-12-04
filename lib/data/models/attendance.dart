/// Attendance status enum
enum AttendanceStatus {
  present,
  absent,
  late,
  halfDay,
  excused;

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  String get dbValue {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.halfDay:
        return 'half_day';
      case AttendanceStatus.excused:
        return 'excused';
    }
  }

  static AttendanceStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'half_day':
        return AttendanceStatus.halfDay;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.present;
    }
  }
}

/// Attendance model
class Attendance {
  final String id;
  final String tenantId;
  final String studentId;
  final String sectionId;
  final DateTime date;
  final AttendanceStatus status;
  final String? remarks;
  final String? markedBy;
  final DateTime? markedAt;
  final DateTime? syncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final String? studentName;
  final String? studentRollNumber;
  final String? studentPhotoUrl;

  const Attendance({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.sectionId,
    required this.date,
    required this.status,
    this.remarks,
    this.markedBy,
    this.markedAt,
    this.syncedAt,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.studentRollNumber,
    this.studentPhotoUrl,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    // Extract student info if available
    String? studentName;
    String? rollNumber;
    String? photoUrl;
    if (json['student'] != null) {
      final student = json['student'];
      studentName = '${student['first_name']} ${student['last_name'] ?? ''}'.trim();
      photoUrl = student['photo_url'];
    }
    if (json['student_enrollments'] != null &&
        (json['student_enrollments'] as List).isNotEmpty) {
      rollNumber = json['student_enrollments'][0]['roll_number'];
    }

    return Attendance(
      id: json['id'],
      tenantId: json['tenant_id'],
      studentId: json['student_id'],
      sectionId: json['section_id'],
      date: DateTime.parse(json['date']),
      status: AttendanceStatus.fromString(json['status']),
      remarks: json['remarks'],
      markedBy: json['marked_by'],
      markedAt: json['marked_at'] != null
          ? DateTime.parse(json['marked_at'])
          : null,
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      studentName: studentName,
      studentRollNumber: rollNumber,
      studentPhotoUrl: photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'student_id': studentId,
      'section_id': sectionId,
      'date': date.toIso8601String().split('T')[0],
      'status': status.dbValue,
      'remarks': remarks,
      'marked_by': markedBy,
      'marked_at': markedAt?.toIso8601String(),
    };
  }

  Attendance copyWith({
    String? id,
    String? tenantId,
    String? studentId,
    String? sectionId,
    DateTime? date,
    AttendanceStatus? status,
    String? remarks,
    String? markedBy,
    DateTime? markedAt,
    DateTime? syncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? studentName,
    String? studentRollNumber,
    String? studentPhotoUrl,
  }) {
    return Attendance(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      studentId: studentId ?? this.studentId,
      sectionId: sectionId ?? this.sectionId,
      date: date ?? this.date,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      markedBy: markedBy ?? this.markedBy,
      markedAt: markedAt ?? this.markedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentName: studentName ?? this.studentName,
      studentRollNumber: studentRollNumber ?? this.studentRollNumber,
      studentPhotoUrl: studentPhotoUrl ?? this.studentPhotoUrl,
    );
  }
}

/// Attendance summary for a section/date
class AttendanceSummary {
  final String sectionId;
  final DateTime date;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final bool isComplete;

  const AttendanceSummary({
    required this.sectionId,
    required this.date,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.isComplete,
  });

  double get attendancePercentage {
    if (totalStudents == 0) return 0;
    return (presentCount + lateCount) / totalStudents * 100;
  }

  int get markedCount => presentCount + absentCount + lateCount + excusedCount;

  bool get isMarked => markedCount > 0;
}

/// Student attendance record (for marking)
class StudentAttendanceRecord {
  final String studentId;
  final String studentName;
  final String? rollNumber;
  final String? photoUrl;
  AttendanceStatus status;
  String? remarks;

  StudentAttendanceRecord({
    required this.studentId,
    required this.studentName,
    this.rollNumber,
    this.photoUrl,
    this.status = AttendanceStatus.present,
    this.remarks,
  });

  factory StudentAttendanceRecord.fromStudent(
    Map<String, dynamic> student, {
    AttendanceStatus? existingStatus,
    String? existingRemarks,
  }) {
    return StudentAttendanceRecord(
      studentId: student['id'],
      studentName: '${student['first_name']} ${student['last_name'] ?? ''}'.trim(),
      rollNumber: student['student_enrollments']?[0]?['roll_number'],
      photoUrl: student['photo_url'],
      status: existingStatus ?? AttendanceStatus.present,
      remarks: existingRemarks,
    );
  }
}
