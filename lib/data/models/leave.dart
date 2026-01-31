// Leave Management Models

class LeaveApplication {
  final String id;
  final String tenantId;
  final String applicantId;
  final String applicantType; // student, teacher, staff
  final String leaveType; // sick, casual, personal, medical, emergency
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? attachmentUrl;
  final String status; // pending, approved, rejected, cancelled
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  // Joined data
  final String? applicantName;
  final String? approverName;
  final String? className;

  const LeaveApplication({
    required this.id,
    required this.tenantId,
    required this.applicantId,
    required this.applicantType,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.attachmentUrl,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.applicantName,
    this.approverName,
    this.className,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: json['id'],
      tenantId: json['tenant_id'],
      applicantId: json['applicant_id'],
      applicantType: json['applicant_type'],
      leaveType: json['leave_type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      reason: json['reason'],
      attachmentUrl: json['attachment_url'],
      status: json['status'] ?? 'pending',
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      applicantName: json['applicant_name'],
      approverName: json['approver']?['full_name'] ?? json['approver_name'],
      className: json['class_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'applicant_id': applicantId,
      'applicant_type': applicantType,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'reason': reason,
      'attachment_url': attachmentUrl,
      'status': status,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  int get duration => endDate.difference(startDate).inDays + 1;

  String get leaveTypeDisplay {
    switch (leaveType) {
      case 'sick':
        return 'Sick Leave';
      case 'casual':
        return 'Casual Leave';
      case 'personal':
        return 'Personal Leave';
      case 'medical':
        return 'Medical Leave';
      case 'emergency':
        return 'Emergency Leave';
      case 'vacation':
        return 'Vacation';
      default:
        return leaveType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get dateRange {
    final startStr = '${startDate.day}/${startDate.month}/${startDate.year}';
    final endStr = '${endDate.day}/${endDate.month}/${endDate.year}';
    if (startStr == endStr) return startStr;
    return '$startStr - $endStr';
  }
}

class LeaveBalance {
  final String id;
  final String tenantId;
  final String userId;
  final String leaveType;
  final int totalDays;
  final int usedDays;
  final int academicYear;

  const LeaveBalance({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.leaveType,
    required this.totalDays,
    required this.usedDays,
    required this.academicYear,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: json['id'],
      tenantId: json['tenant_id'],
      userId: json['user_id'],
      leaveType: json['leave_type'],
      totalDays: json['total_days'] ?? 0,
      usedDays: json['used_days'] ?? 0,
      academicYear: json['academic_year'],
    );
  }

  int get remainingDays => totalDays - usedDays;

  String get leaveTypeDisplay {
    switch (leaveType) {
      case 'sick':
        return 'Sick Leave';
      case 'casual':
        return 'Casual Leave';
      case 'personal':
        return 'Personal Leave';
      default:
        return leaveType;
    }
  }
}
