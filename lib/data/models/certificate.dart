// Certificate Generator module models

// ============================================
// ENUMS
// ============================================

enum CertificateType {
  transfer,
  bonafide,
  character,
  migration,
  achievement,
  participation,
  merit,
  custom;

  String get value {
    switch (this) {
      case CertificateType.transfer:
        return 'transfer';
      case CertificateType.bonafide:
        return 'bonafide';
      case CertificateType.character:
        return 'character';
      case CertificateType.migration:
        return 'migration';
      case CertificateType.achievement:
        return 'achievement';
      case CertificateType.participation:
        return 'participation';
      case CertificateType.merit:
        return 'merit';
      case CertificateType.custom:
        return 'custom';
    }
  }

  String get label {
    switch (this) {
      case CertificateType.transfer:
        return 'Transfer Certificate';
      case CertificateType.bonafide:
        return 'Bonafide Certificate';
      case CertificateType.character:
        return 'Character Certificate';
      case CertificateType.migration:
        return 'Migration Certificate';
      case CertificateType.achievement:
        return 'Achievement Certificate';
      case CertificateType.participation:
        return 'Participation Certificate';
      case CertificateType.merit:
        return 'Merit Certificate';
      case CertificateType.custom:
        return 'Custom Certificate';
    }
  }

  static CertificateType fromString(String value) {
    switch (value) {
      case 'transfer':
        return CertificateType.transfer;
      case 'bonafide':
        return CertificateType.bonafide;
      case 'character':
        return CertificateType.character;
      case 'migration':
        return CertificateType.migration;
      case 'achievement':
        return CertificateType.achievement;
      case 'participation':
        return CertificateType.participation;
      case 'merit':
        return CertificateType.merit;
      default:
        return CertificateType.custom;
    }
  }
}

enum CertificateStatus {
  draft,
  issued,
  revoked;

  String get value {
    switch (this) {
      case CertificateStatus.draft:
        return 'draft';
      case CertificateStatus.issued:
        return 'issued';
      case CertificateStatus.revoked:
        return 'revoked';
    }
  }

  String get label {
    switch (this) {
      case CertificateStatus.draft:
        return 'Draft';
      case CertificateStatus.issued:
        return 'Issued';
      case CertificateStatus.revoked:
        return 'Revoked';
    }
  }

  static CertificateStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return CertificateStatus.draft;
      case 'issued':
        return CertificateStatus.issued;
      case 'revoked':
        return CertificateStatus.revoked;
      default:
        return CertificateStatus.draft;
    }
  }
}

// ============================================
// MODEL CLASSES
// ============================================

/// Certificate template
class CertificateTemplate {
  final String id;
  final String tenantId;
  final String name;
  final CertificateType type;
  final Map<String, dynamic> layoutData;
  final List<dynamic> variables;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CertificateTemplate({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    required this.layoutData,
    required this.variables,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CertificateTemplate.fromJson(Map<String, dynamic> json) {
    final layoutRaw = json['layout_data'];
    final layout = layoutRaw is Map<String, dynamic>
        ? layoutRaw
        : <String, dynamic>{};

    final varsRaw = json['variables'];
    final vars = varsRaw is List ? varsRaw : <dynamic>[];

    return CertificateTemplate(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      name: json['name'] ?? '',
      type: CertificateType.fromString(json['type'] ?? 'custom'),
      layoutData: layout,
      variables: vars,
      isActive: json['is_active'] ?? true,
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
      'name': name,
      'type': type.value,
      'layout_data': layoutData,
      'variables': variables,
      'is_active': isActive,
    };
  }

  /// Get background URL from layout data
  String? get backgroundUrl => layoutData['background_url'] as String?;

  /// Get margins from layout data
  Map<String, double> get margins {
    final m = layoutData['margins'];
    if (m is Map) {
      return {
        'top': (m['top'] as num?)?.toDouble() ?? 40,
        'bottom': (m['bottom'] as num?)?.toDouble() ?? 40,
        'left': (m['left'] as num?)?.toDouble() ?? 40,
        'right': (m['right'] as num?)?.toDouble() ?? 40,
      };
    }
    return {'top': 40, 'bottom': 40, 'left': 40, 'right': 40};
  }

  /// Get field definitions from layout data
  List<Map<String, dynamic>> get fields {
    final f = layoutData['fields'];
    if (f is List) {
      return f.cast<Map<String, dynamic>>();
    }
    return [];
  }
}

/// Issued certificate
class IssuedCertificate {
  final String id;
  final String tenantId;
  final String templateId;
  final String studentId;
  final String certificateNumber;
  final DateTime issuedDate;
  final String? issuedBy;
  final String? purpose;
  final Map<String, dynamic> data;
  final String? pdfUrl;
  final CertificateStatus status;
  final String? revokedReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final CertificateTemplate? template;
  final String? studentName;
  final String? studentAdmissionNumber;
  final String? className;
  final String? issuedByName;

  const IssuedCertificate({
    required this.id,
    required this.tenantId,
    required this.templateId,
    required this.studentId,
    required this.certificateNumber,
    required this.issuedDate,
    this.issuedBy,
    this.purpose,
    required this.data,
    this.pdfUrl,
    required this.status,
    this.revokedReason,
    required this.createdAt,
    required this.updatedAt,
    this.template,
    this.studentName,
    this.studentAdmissionNumber,
    this.className,
    this.issuedByName,
  });

  factory IssuedCertificate.fromJson(Map<String, dynamic> json) {
    CertificateTemplate? template;
    if (json['certificate_templates'] != null &&
        json['certificate_templates'] is Map) {
      template =
          CertificateTemplate.fromJson(json['certificate_templates']);
    }

    String? studentName;
    String? admissionNumber;
    String? className;
    if (json['students'] != null) {
      final s = json['students'];
      studentName =
          '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
      admissionNumber = s['admission_number'];
      if (s['student_enrollments'] != null &&
          (s['student_enrollments'] as List).isNotEmpty) {
        final enrollment = (s['student_enrollments'] as List).first;
        if (enrollment['sections'] != null) {
          final sec = enrollment['sections'];
          if (sec['classes'] != null) {
            className =
                '${sec['classes']['name'] ?? ''} - ${sec['name'] ?? ''}';
          }
        }
      }
    }

    String? issuedByName;
    if (json['users'] != null) {
      issuedByName = json['users']['full_name'];
    }

    final dataRaw = json['data'];
    final data = dataRaw is Map<String, dynamic>
        ? dataRaw
        : <String, dynamic>{};

    return IssuedCertificate(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      templateId: json['template_id'] ?? '',
      studentId: json['student_id'] ?? '',
      certificateNumber: json['certificate_number'] ?? '',
      issuedDate: json['issued_date'] != null
          ? DateTime.parse(json['issued_date'])
          : DateTime.now(),
      issuedBy: json['issued_by'],
      purpose: json['purpose'],
      data: data,
      pdfUrl: json['pdf_url'],
      status: CertificateStatus.fromString(json['status'] ?? 'draft'),
      revokedReason: json['revoked_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      template: template,
      studentName: studentName,
      studentAdmissionNumber: admissionNumber,
      className: className,
      issuedByName: issuedByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'template_id': templateId,
      'student_id': studentId,
      'certificate_number': certificateNumber,
      'issued_date': issuedDate.toIso8601String().split('T')[0],
      'issued_by': issuedBy,
      'purpose': purpose,
      'data': data,
      'pdf_url': pdfUrl,
      'status': status.value,
      'revoked_reason': revokedReason,
    };
  }
}

/// Certificate number sequence
class CertificateNumberSequence {
  final String id;
  final String tenantId;
  final CertificateType templateType;
  final String prefix;
  final int currentNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CertificateNumberSequence({
    required this.id,
    required this.tenantId,
    required this.templateType,
    required this.prefix,
    required this.currentNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CertificateNumberSequence.fromJson(Map<String, dynamic> json) {
    return CertificateNumberSequence(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      templateType:
          CertificateType.fromString(json['template_type'] ?? 'custom'),
      prefix: json['prefix'] ?? 'CERT',
      currentNumber: json['current_number'] ?? 0,
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
      'template_type': templateType.value,
      'prefix': prefix,
      'current_number': currentNumber,
    };
  }
}

/// Stats aggregate for dashboard
class CertificateStats {
  final int totalIssued;
  final int drafts;
  final int issued;
  final int revoked;
  final int templatesCount;
  final Map<String, int> byType;

  const CertificateStats({
    this.totalIssued = 0,
    this.drafts = 0,
    this.issued = 0,
    this.revoked = 0,
    this.templatesCount = 0,
    this.byType = const {},
  });
}
