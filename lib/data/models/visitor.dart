// Visitor Management module models

// ============================================
// ENUMS
// ============================================

enum VisitorIdType {
  nationalId,
  passport,
  driversLicense;

  String get value {
    switch (this) {
      case VisitorIdType.nationalId:
        return 'national_id';
      case VisitorIdType.passport:
        return 'passport';
      case VisitorIdType.driversLicense:
        return 'drivers_license';
    }
  }

  String get label {
    switch (this) {
      case VisitorIdType.nationalId:
        return 'National ID';
      case VisitorIdType.passport:
        return 'Passport';
      case VisitorIdType.driversLicense:
        return "Driver's License";
    }
  }

  static VisitorIdType fromString(String value) {
    switch (value) {
      case 'national_id':
        return VisitorIdType.nationalId;
      case 'passport':
        return VisitorIdType.passport;
      case 'drivers_license':
        return VisitorIdType.driversLicense;
      default:
        return VisitorIdType.nationalId;
    }
  }
}

enum VisitorLogPurpose {
  parentVisit,
  delivery,
  maintenance,
  meeting,
  interview,
  vendor,
  other;

  String get value {
    switch (this) {
      case VisitorLogPurpose.parentVisit:
        return 'parent_visit';
      case VisitorLogPurpose.delivery:
        return 'delivery';
      case VisitorLogPurpose.maintenance:
        return 'maintenance';
      case VisitorLogPurpose.meeting:
        return 'meeting';
      case VisitorLogPurpose.interview:
        return 'interview';
      case VisitorLogPurpose.vendor:
        return 'vendor';
      case VisitorLogPurpose.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case VisitorLogPurpose.parentVisit:
        return 'Parent Visit';
      case VisitorLogPurpose.delivery:
        return 'Delivery';
      case VisitorLogPurpose.maintenance:
        return 'Maintenance';
      case VisitorLogPurpose.meeting:
        return 'Meeting';
      case VisitorLogPurpose.interview:
        return 'Interview';
      case VisitorLogPurpose.vendor:
        return 'Vendor';
      case VisitorLogPurpose.other:
        return 'Other';
    }
  }

  static VisitorLogPurpose fromString(String value) {
    switch (value) {
      case 'parent_visit':
        return VisitorLogPurpose.parentVisit;
      case 'delivery':
        return VisitorLogPurpose.delivery;
      case 'maintenance':
        return VisitorLogPurpose.maintenance;
      case 'meeting':
        return VisitorLogPurpose.meeting;
      case 'interview':
        return VisitorLogPurpose.interview;
      case 'vendor':
        return VisitorLogPurpose.vendor;
      default:
        return VisitorLogPurpose.other;
    }
  }
}

enum VisitorLogStatus {
  preRegistered,
  checkedIn,
  checkedOut,
  denied;

  String get value {
    switch (this) {
      case VisitorLogStatus.preRegistered:
        return 'pre_registered';
      case VisitorLogStatus.checkedIn:
        return 'checked_in';
      case VisitorLogStatus.checkedOut:
        return 'checked_out';
      case VisitorLogStatus.denied:
        return 'denied';
    }
  }

  String get label {
    switch (this) {
      case VisitorLogStatus.preRegistered:
        return 'Pre-Registered';
      case VisitorLogStatus.checkedIn:
        return 'Checked In';
      case VisitorLogStatus.checkedOut:
        return 'Checked Out';
      case VisitorLogStatus.denied:
        return 'Denied';
    }
  }

  static VisitorLogStatus fromString(String value) {
    switch (value) {
      case 'pre_registered':
        return VisitorLogStatus.preRegistered;
      case 'checked_in':
        return VisitorLogStatus.checkedIn;
      case 'checked_out':
        return VisitorLogStatus.checkedOut;
      case 'denied':
        return VisitorLogStatus.denied;
      default:
        return VisitorLogStatus.preRegistered;
    }
  }
}

enum VisitorPreRegStatus {
  pending,
  approved,
  denied,
  completed;

  String get value {
    switch (this) {
      case VisitorPreRegStatus.pending:
        return 'pending';
      case VisitorPreRegStatus.approved:
        return 'approved';
      case VisitorPreRegStatus.denied:
        return 'denied';
      case VisitorPreRegStatus.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case VisitorPreRegStatus.pending:
        return 'Pending';
      case VisitorPreRegStatus.approved:
        return 'Approved';
      case VisitorPreRegStatus.denied:
        return 'Denied';
      case VisitorPreRegStatus.completed:
        return 'Completed';
    }
  }

  static VisitorPreRegStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return VisitorPreRegStatus.pending;
      case 'approved':
        return VisitorPreRegStatus.approved;
      case 'denied':
        return VisitorPreRegStatus.denied;
      case 'completed':
        return VisitorPreRegStatus.completed;
      default:
        return VisitorPreRegStatus.pending;
    }
  }
}

// ============================================
// MODEL CLASSES
// ============================================

/// Visitor profile (recurring visitor)
class Visitor {
  final String id;
  final String tenantId;
  final String fullName;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final VisitorIdType? idType;
  final String? idNumber;
  final String? company;
  final bool isBlacklisted;
  final int visitCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Visitor({
    required this.id,
    required this.tenantId,
    required this.fullName,
    this.phone,
    this.email,
    this.photoUrl,
    this.idType,
    this.idNumber,
    this.company,
    this.isBlacklisted = false,
    this.visitCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      photoUrl: json['photo_url'],
      idType: json['id_type'] != null
          ? VisitorIdType.fromString(json['id_type'])
          : null,
      idNumber: json['id_number'],
      company: json['company'],
      isBlacklisted: json['is_blacklisted'] ?? false,
      visitCount: json['visit_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'photo_url': photoUrl,
      'id_type': idType?.value,
      'id_number': idNumber,
      'company': company,
      'is_blacklisted': isBlacklisted,
    };
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

/// Visitor log entry (check-in / check-out)
class VisitorLog {
  final String id;
  final String tenantId;
  final String visitorId;
  final VisitorLogPurpose purpose;
  final String? personToMeet;
  final String? department;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? badgeNumber;
  final String? vehicleNumber;
  final String? itemsCarried;
  final VisitorLogStatus status;
  final String? notes;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final Visitor? visitor;
  final String? personToMeetName;
  final String? approvedByName;

  const VisitorLog({
    required this.id,
    required this.tenantId,
    required this.visitorId,
    required this.purpose,
    this.personToMeet,
    this.department,
    required this.checkInTime,
    this.checkOutTime,
    this.badgeNumber,
    this.vehicleNumber,
    this.itemsCarried,
    required this.status,
    this.notes,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.visitor,
    this.personToMeetName,
    this.approvedByName,
  });

  factory VisitorLog.fromJson(Map<String, dynamic> json) {
    Visitor? visitor;
    if (json['visitors'] != null && json['visitors'] is Map) {
      visitor = Visitor.fromJson(json['visitors']);
    }

    String? personToMeetName;
    if (json['person_to_meet_user'] != null) {
      personToMeetName = json['person_to_meet_user']['full_name'];
    }

    String? approvedByName;
    if (json['approved_by_user'] != null) {
      approvedByName = json['approved_by_user']['full_name'];
    }

    return VisitorLog(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      visitorId: json['visitor_id'] ?? '',
      purpose:
          VisitorLogPurpose.fromString(json['purpose'] ?? 'other'),
      personToMeet: json['person_to_meet'],
      department: json['department'],
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : DateTime.now(),
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      badgeNumber: json['badge_number'],
      vehicleNumber: json['vehicle_number'],
      itemsCarried: json['items_carried'],
      status:
          VisitorLogStatus.fromString(json['status'] ?? 'checked_in'),
      notes: json['notes'],
      approvedBy: json['approved_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      visitor: visitor,
      personToMeetName: personToMeetName,
      approvedByName: approvedByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'visitor_id': visitorId,
      'purpose': purpose.value,
      'person_to_meet': personToMeet,
      'department': department,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'badge_number': badgeNumber,
      'vehicle_number': vehicleNumber,
      'items_carried': itemsCarried,
      'status': status.value,
      'notes': notes,
      'approved_by': approvedBy,
    };
  }

  /// Duration of visit
  Duration? get visitDuration {
    if (checkOutTime != null) {
      return checkOutTime!.difference(checkInTime);
    }
    return null;
  }

  String get durationString {
    final d = visitDuration;
    if (d == null) return 'Ongoing';
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }
}

/// Pre-registration model
class VisitorPreRegistration {
  final String id;
  final String tenantId;
  final DateTime expectedDate;
  final String visitorName;
  final String? visitorPhone;
  final String? visitorEmail;
  final VisitorLogPurpose purpose;
  final String? hostId;
  final VisitorPreRegStatus status;
  final String? qrCodeData;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? hostName;

  const VisitorPreRegistration({
    required this.id,
    required this.tenantId,
    required this.expectedDate,
    required this.visitorName,
    this.visitorPhone,
    this.visitorEmail,
    required this.purpose,
    this.hostId,
    required this.status,
    this.qrCodeData,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.hostName,
  });

  factory VisitorPreRegistration.fromJson(Map<String, dynamic> json) {
    String? hostName;
    if (json['users'] != null) {
      hostName = json['users']['full_name'];
    }

    return VisitorPreRegistration(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      expectedDate: json['expected_date'] != null
          ? DateTime.parse(json['expected_date'])
          : DateTime.now(),
      visitorName: json['visitor_name'] ?? '',
      visitorPhone: json['visitor_phone'],
      visitorEmail: json['visitor_email'],
      purpose:
          VisitorLogPurpose.fromString(json['purpose'] ?? 'other'),
      hostId: json['host_id'],
      status: VisitorPreRegStatus.fromString(json['status'] ?? 'pending'),
      qrCodeData: json['qr_code_data'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      hostName: hostName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'expected_date': expectedDate.toIso8601String().split('T')[0],
      'visitor_name': visitorName,
      'visitor_phone': visitorPhone,
      'visitor_email': visitorEmail,
      'purpose': purpose.value,
      'host_id': hostId,
      'status': status.value,
      'qr_code_data': qrCodeData,
      'notes': notes,
    };
  }
}

/// Stats aggregate for dashboard
class VisitorStats {
  final int todayTotal;
  final int currentlyCheckedIn;
  final int preRegisteredToday;
  final int checkedOutToday;
  final int deniedToday;
  final int blacklisted;

  const VisitorStats({
    this.todayTotal = 0,
    this.currentlyCheckedIn = 0,
    this.preRegisteredToday = 0,
    this.checkedOutToday = 0,
    this.deniedToday = 0,
    this.blacklisted = 0,
  });
}
