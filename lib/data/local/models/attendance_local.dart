// Note: Isar is disabled for web builds. This model is kept for mobile/desktop.
// import 'package:isar/isar.dart';
// part 'attendance_local.g.dart';

/// Local attendance model for offline storage
// @collection
class AttendanceLocal {
  AttendanceLocal();

  int? isarId;

  late String id;

  late String tenantId;

  late String studentId;

  late String sectionId;

  late DateTime date;

  late AttendanceStatusLocal status;

  String? remarks;
  String? markedBy;
  DateTime? markedAt;

  // Sync metadata
  DateTime? syncedAt;
  bool pendingSync = false;

  // Composite index for efficient queries
  String get studentDate => '$studentId-${date.toIso8601String().split('T')[0]}';

  /// Create from Supabase response
  factory AttendanceLocal.fromJson(Map<String, dynamic> json) {
    return AttendanceLocal()
      ..id = json['id']
      ..tenantId = json['tenant_id']
      ..studentId = json['student_id']
      ..sectionId = json['section_id']
      ..date = DateTime.parse(json['date'])
      ..status = AttendanceStatusLocal.fromString(json['status'])
      ..remarks = json['remarks']
      ..markedBy = json['marked_by']
      ..markedAt = json['marked_at'] != null
          ? DateTime.parse(json['marked_at'])
          : null
      ..syncedAt = json['synced_at'] != null
          ? DateTime.parse(json['synced_at'])
          : null
      ..pendingSync = false;
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'student_id': studentId,
      'section_id': sectionId,
      'date': date.toIso8601String().split('T')[0],
      'status': status.name,
      'remarks': remarks,
      'marked_by': markedBy,
      'marked_at': markedAt?.toIso8601String(),
    };
  }
}

/// Attendance status enum for local storage
enum AttendanceStatusLocal {
  present,
  absent,
  late,
  halfDay,
  excused;

  static AttendanceStatusLocal fromString(String value) {
    switch (value.toLowerCase()) {
      case 'present':
        return AttendanceStatusLocal.present;
      case 'absent':
        return AttendanceStatusLocal.absent;
      case 'late':
        return AttendanceStatusLocal.late;
      case 'half_day':
        return AttendanceStatusLocal.halfDay;
      case 'excused':
        return AttendanceStatusLocal.excused;
      default:
        return AttendanceStatusLocal.present;
    }
  }
}
