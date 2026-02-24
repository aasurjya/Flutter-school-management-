/// Check-in type enum
enum CheckType {
  checkIn,
  checkOut;

  String get dbValue {
    switch (this) {
      case CheckType.checkIn:
        return 'check_in';
      case CheckType.checkOut:
        return 'check_out';
    }
  }

  String get displayName {
    switch (this) {
      case CheckType.checkIn:
        return 'Check In';
      case CheckType.checkOut:
        return 'Check Out';
    }
  }

  static CheckType fromString(String value) {
    switch (value) {
      case 'check_in':
        return CheckType.checkIn;
      case 'check_out':
        return CheckType.checkOut;
      default:
        return CheckType.checkIn;
    }
  }
}

/// Student check-in/check-out model
class StudentCheckin {
  final String id;
  final String tenantId;
  final String studentId;
  final String sectionId;
  final CheckType checkType;
  final DateTime checkedAt;
  final String? checkedBy;
  final String method;
  final String? notes;
  final DateTime createdAt;

  // Related data
  final String? studentName;
  final String? studentPhotoUrl;
  final String? checkedByName;

  const StudentCheckin({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.sectionId,
    required this.checkType,
    required this.checkedAt,
    this.checkedBy,
    this.method = 'qr_scan',
    this.notes,
    required this.createdAt,
    this.studentName,
    this.studentPhotoUrl,
    this.checkedByName,
  });

  factory StudentCheckin.fromJson(Map<String, dynamic> json) {
    String? studentName;
    String? photoUrl;
    if (json['students'] != null) {
      final student = json['students'];
      studentName =
          '${student['first_name']} ${student['last_name'] ?? ''}'.trim();
      photoUrl = student['photo_url'];
    }

    return StudentCheckin(
      id: json['id'],
      tenantId: json['tenant_id'],
      studentId: json['student_id'],
      sectionId: json['section_id'],
      checkType: CheckType.fromString(json['check_type']),
      checkedAt: DateTime.parse(json['checked_at']),
      checkedBy: json['checked_by'],
      method: json['method'] ?? 'qr_scan',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      studentName: studentName,
      studentPhotoUrl: photoUrl,
      checkedByName: json['users']?['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'student_id': studentId,
      'section_id': sectionId,
      'check_type': checkType.dbValue,
      'checked_at': checkedAt.toIso8601String(),
      'checked_by': checkedBy,
      'method': method,
      'notes': notes,
    };
  }
}
