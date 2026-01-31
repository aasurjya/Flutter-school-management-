// Emergency Alert Models

class EmergencyAlert {
  final String id;
  final String tenantId;
  final String alertType; // fire, earthquake, lockdown, medical, weather, other
  final String title;
  final String message;
  final String severity; // low, medium, high, critical
  final String status; // active, resolved
  final String initiatedBy;
  final DateTime initiatedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;
  final Map<String, dynamic>? metadata;

  // Joined data
  final String? initiatorName;
  final String? resolverName;
  final int? responseCount;

  const EmergencyAlert({
    required this.id,
    required this.tenantId,
    required this.alertType,
    required this.title,
    required this.message,
    required this.severity,
    required this.status,
    required this.initiatedBy,
    required this.initiatedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
    this.metadata,
    this.initiatorName,
    this.resolverName,
    this.responseCount,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'],
      tenantId: json['tenant_id'],
      alertType: json['alert_type'],
      title: json['title'],
      message: json['message'],
      severity: json['severity'] ?? 'medium',
      status: json['status'] ?? 'active',
      initiatedBy: json['initiated_by'],
      initiatedAt: DateTime.parse(json['initiated_at']),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolvedBy: json['resolved_by'],
      resolutionNotes: json['resolution_notes'],
      metadata: json['metadata'],
      initiatorName: json['initiator']?['full_name'] ?? json['initiator_name'],
      resolverName: json['resolver']?['full_name'] ?? json['resolver_name'],
      responseCount: json['response_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'alert_type': alertType,
      'title': title,
      'message': message,
      'severity': severity,
      'status': status,
      'initiated_by': initiatedBy,
      'initiated_at': initiatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'resolution_notes': resolutionNotes,
      'metadata': metadata,
    };
  }

  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';

  String get alertTypeDisplay {
    switch (alertType) {
      case 'fire':
        return 'Fire Emergency';
      case 'earthquake':
        return 'Earthquake';
      case 'lockdown':
        return 'Lockdown';
      case 'medical':
        return 'Medical Emergency';
      case 'weather':
        return 'Severe Weather';
      case 'other':
        return 'Emergency';
      default:
        return alertType;
    }
  }

  String get severityDisplay {
    switch (severity) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return severity;
    }
  }
}

class EmergencyResponse {
  final String id;
  final String alertId;
  final String responderId;
  final String responderType; // teacher, staff, parent
  final String status; // safe, needs_help, not_responded
  final String? location;
  final String? notes;
  final DateTime respondedAt;

  // Joined data
  final String? responderName;
  final int? studentCount; // For teachers/staff

  const EmergencyResponse({
    required this.id,
    required this.alertId,
    required this.responderId,
    required this.responderType,
    required this.status,
    this.location,
    this.notes,
    required this.respondedAt,
    this.responderName,
    this.studentCount,
  });

  factory EmergencyResponse.fromJson(Map<String, dynamic> json) {
    return EmergencyResponse(
      id: json['id'],
      alertId: json['alert_id'],
      responderId: json['responder_id'],
      responderType: json['responder_type'],
      status: json['status'] ?? 'not_responded',
      location: json['location'],
      notes: json['notes'],
      respondedAt: DateTime.parse(json['responded_at']),
      responderName: json['responder']?['full_name'] ?? json['responder_name'],
      studentCount: json['student_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_id': alertId,
      'responder_id': responderId,
      'responder_type': responderType,
      'status': status,
      'location': location,
      'notes': notes,
      'responded_at': respondedAt.toIso8601String(),
    };
  }

  bool get isSafe => status == 'safe';
  bool get needsHelp => status == 'needs_help';
}

class EmergencyContact {
  final String id;
  final String tenantId;
  final String name;
  final String phone;
  final String? email;
  final String contactType; // emergency_services, hospital, police, parent
  final int priority;
  final bool isActive;

  const EmergencyContact({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.phone,
    this.email,
    required this.contactType,
    required this.priority,
    this.isActive = true,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      contactType: json['contact_type'],
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'name': name,
      'phone': phone,
      'email': email,
      'contact_type': contactType,
      'priority': priority,
      'is_active': isActive,
    };
  }

  String get contactTypeDisplay {
    switch (contactType) {
      case 'emergency_services':
        return 'Emergency Services';
      case 'hospital':
        return 'Hospital';
      case 'police':
        return 'Police';
      case 'fire':
        return 'Fire Department';
      case 'parent':
        return 'Parent Contact';
      default:
        return contactType;
    }
  }
}
