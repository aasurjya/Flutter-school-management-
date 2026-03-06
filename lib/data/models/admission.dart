/// Admission module models

// ============================================
// ENUMS
// ============================================

enum InquiryStatus {
  newInquiry,
  contacted,
  visitScheduled,
  visitCompleted,
  applicationSent,
  converted,
  lost;

  String get value {
    switch (this) {
      case InquiryStatus.newInquiry:
        return 'new';
      case InquiryStatus.contacted:
        return 'contacted';
      case InquiryStatus.visitScheduled:
        return 'visit_scheduled';
      case InquiryStatus.visitCompleted:
        return 'visit_completed';
      case InquiryStatus.applicationSent:
        return 'application_sent';
      case InquiryStatus.converted:
        return 'converted';
      case InquiryStatus.lost:
        return 'lost';
    }
  }

  String get label {
    switch (this) {
      case InquiryStatus.newInquiry:
        return 'New';
      case InquiryStatus.contacted:
        return 'Contacted';
      case InquiryStatus.visitScheduled:
        return 'Visit Scheduled';
      case InquiryStatus.visitCompleted:
        return 'Visit Completed';
      case InquiryStatus.applicationSent:
        return 'Application Sent';
      case InquiryStatus.converted:
        return 'Converted';
      case InquiryStatus.lost:
        return 'Lost';
    }
  }

  static InquiryStatus fromString(String value) {
    switch (value) {
      case 'new':
        return InquiryStatus.newInquiry;
      case 'contacted':
        return InquiryStatus.contacted;
      case 'visit_scheduled':
        return InquiryStatus.visitScheduled;
      case 'visit_completed':
        return InquiryStatus.visitCompleted;
      case 'application_sent':
        return InquiryStatus.applicationSent;
      case 'converted':
        return InquiryStatus.converted;
      case 'lost':
        return InquiryStatus.lost;
      default:
        return InquiryStatus.newInquiry;
    }
  }
}

enum InquirySource {
  website,
  referral,
  walkIn,
  advertisement,
  socialMedia,
  phoneCall,
  email,
  event,
  other;

  String get value {
    switch (this) {
      case InquirySource.website:
        return 'website';
      case InquirySource.referral:
        return 'referral';
      case InquirySource.walkIn:
        return 'walk_in';
      case InquirySource.advertisement:
        return 'advertisement';
      case InquirySource.socialMedia:
        return 'social_media';
      case InquirySource.phoneCall:
        return 'phone_call';
      case InquirySource.email:
        return 'email';
      case InquirySource.event:
        return 'event';
      case InquirySource.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case InquirySource.website:
        return 'Website';
      case InquirySource.referral:
        return 'Referral';
      case InquirySource.walkIn:
        return 'Walk-in';
      case InquirySource.advertisement:
        return 'Advertisement';
      case InquirySource.socialMedia:
        return 'Social Media';
      case InquirySource.phoneCall:
        return 'Phone Call';
      case InquirySource.email:
        return 'Email';
      case InquirySource.event:
        return 'Event';
      case InquirySource.other:
        return 'Other';
    }
  }

  static InquirySource fromString(String value) {
    switch (value) {
      case 'website':
        return InquirySource.website;
      case 'referral':
        return InquirySource.referral;
      case 'walk_in':
        return InquirySource.walkIn;
      case 'advertisement':
        return InquirySource.advertisement;
      case 'social_media':
        return InquirySource.socialMedia;
      case 'phone_call':
        return InquirySource.phoneCall;
      case 'email':
        return InquirySource.email;
      case 'event':
        return InquirySource.event;
      default:
        return InquirySource.other;
    }
  }
}

enum ApplicationStatus {
  draft,
  submitted,
  underReview,
  interviewScheduled,
  accepted,
  rejected,
  waitlisted,
  enrolled,
  withdrawn;

  String get value {
    switch (this) {
      case ApplicationStatus.draft:
        return 'draft';
      case ApplicationStatus.submitted:
        return 'submitted';
      case ApplicationStatus.underReview:
        return 'under_review';
      case ApplicationStatus.interviewScheduled:
        return 'interview_scheduled';
      case ApplicationStatus.accepted:
        return 'accepted';
      case ApplicationStatus.rejected:
        return 'rejected';
      case ApplicationStatus.waitlisted:
        return 'waitlisted';
      case ApplicationStatus.enrolled:
        return 'enrolled';
      case ApplicationStatus.withdrawn:
        return 'withdrawn';
    }
  }

  String get label {
    switch (this) {
      case ApplicationStatus.draft:
        return 'Draft';
      case ApplicationStatus.submitted:
        return 'Submitted';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.interviewScheduled:
        return 'Interview Scheduled';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.waitlisted:
        return 'Waitlisted';
      case ApplicationStatus.enrolled:
        return 'Enrolled';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  static ApplicationStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return ApplicationStatus.draft;
      case 'submitted':
        return ApplicationStatus.submitted;
      case 'under_review':
        return ApplicationStatus.underReview;
      case 'interview_scheduled':
        return ApplicationStatus.interviewScheduled;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'waitlisted':
        return ApplicationStatus.waitlisted;
      case 'enrolled':
        return ApplicationStatus.enrolled;
      case 'withdrawn':
        return ApplicationStatus.withdrawn;
      default:
        return ApplicationStatus.draft;
    }
  }
}

enum InterviewStatus {
  scheduled,
  completed,
  cancelled,
  rescheduled,
  noShow;

  String get value {
    switch (this) {
      case InterviewStatus.scheduled:
        return 'scheduled';
      case InterviewStatus.completed:
        return 'completed';
      case InterviewStatus.cancelled:
        return 'cancelled';
      case InterviewStatus.rescheduled:
        return 'rescheduled';
      case InterviewStatus.noShow:
        return 'no_show';
    }
  }

  String get label {
    switch (this) {
      case InterviewStatus.scheduled:
        return 'Scheduled';
      case InterviewStatus.completed:
        return 'Completed';
      case InterviewStatus.cancelled:
        return 'Cancelled';
      case InterviewStatus.rescheduled:
        return 'Rescheduled';
      case InterviewStatus.noShow:
        return 'No Show';
    }
  }

  static InterviewStatus fromString(String value) {
    switch (value) {
      case 'scheduled':
        return InterviewStatus.scheduled;
      case 'completed':
        return InterviewStatus.completed;
      case 'cancelled':
        return InterviewStatus.cancelled;
      case 'rescheduled':
        return InterviewStatus.rescheduled;
      case 'no_show':
        return InterviewStatus.noShow;
      default:
        return InterviewStatus.scheduled;
    }
  }
}

enum DocumentStatus {
  pending,
  uploaded,
  verified,
  rejected;

  String get value {
    switch (this) {
      case DocumentStatus.pending:
        return 'pending';
      case DocumentStatus.uploaded:
        return 'uploaded';
      case DocumentStatus.verified:
        return 'verified';
      case DocumentStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.uploaded:
        return 'Uploaded';
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
    }
  }

  static DocumentStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return DocumentStatus.pending;
      case 'uploaded':
        return DocumentStatus.uploaded;
      case 'verified':
        return DocumentStatus.verified;
      case 'rejected':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.pending;
    }
  }
}

enum AdmissionDocumentType {
  birthCertificate,
  transferCertificate,
  reportCard,
  addressProof,
  photo,
  parentId,
  medicalCertificate,
  casteCertificate,
  incomeCertificate,
  migrationCertificate,
  other;

  String get value {
    switch (this) {
      case AdmissionDocumentType.birthCertificate:
        return 'birth_certificate';
      case AdmissionDocumentType.transferCertificate:
        return 'transfer_certificate';
      case AdmissionDocumentType.reportCard:
        return 'report_card';
      case AdmissionDocumentType.addressProof:
        return 'address_proof';
      case AdmissionDocumentType.photo:
        return 'photo';
      case AdmissionDocumentType.parentId:
        return 'parent_id';
      case AdmissionDocumentType.medicalCertificate:
        return 'medical_certificate';
      case AdmissionDocumentType.casteCertificate:
        return 'caste_certificate';
      case AdmissionDocumentType.incomeCertificate:
        return 'income_certificate';
      case AdmissionDocumentType.migrationCertificate:
        return 'migration_certificate';
      case AdmissionDocumentType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case AdmissionDocumentType.birthCertificate:
        return 'Birth Certificate';
      case AdmissionDocumentType.transferCertificate:
        return 'Transfer Certificate';
      case AdmissionDocumentType.reportCard:
        return 'Report Card';
      case AdmissionDocumentType.addressProof:
        return 'Address Proof';
      case AdmissionDocumentType.photo:
        return 'Photo';
      case AdmissionDocumentType.parentId:
        return 'Parent ID';
      case AdmissionDocumentType.medicalCertificate:
        return 'Medical Certificate';
      case AdmissionDocumentType.casteCertificate:
        return 'Caste Certificate';
      case AdmissionDocumentType.incomeCertificate:
        return 'Income Certificate';
      case AdmissionDocumentType.migrationCertificate:
        return 'Migration Certificate';
      case AdmissionDocumentType.other:
        return 'Other';
    }
  }

  static AdmissionDocumentType fromString(String value) {
    switch (value) {
      case 'birth_certificate':
        return AdmissionDocumentType.birthCertificate;
      case 'transfer_certificate':
        return AdmissionDocumentType.transferCertificate;
      case 'report_card':
        return AdmissionDocumentType.reportCard;
      case 'address_proof':
        return AdmissionDocumentType.addressProof;
      case 'photo':
        return AdmissionDocumentType.photo;
      case 'parent_id':
        return AdmissionDocumentType.parentId;
      case 'medical_certificate':
        return AdmissionDocumentType.medicalCertificate;
      case 'caste_certificate':
        return AdmissionDocumentType.casteCertificate;
      case 'income_certificate':
        return AdmissionDocumentType.incomeCertificate;
      case 'migration_certificate':
        return AdmissionDocumentType.migrationCertificate;
      default:
        return AdmissionDocumentType.other;
    }
  }
}

// ============================================
// MODEL CLASSES
// ============================================

/// Admission Inquiry model
class AdmissionInquiry {
  final String id;
  final String tenantId;
  final String studentName;
  final String parentName;
  final String? email;
  final String phone;
  final InquirySource source;
  final String? applyingForClassId;
  final String? academicYearId;
  final InquiryStatus status;
  final String? assignedTo;
  final DateTime? nextFollowupDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? className;
  final String? assignedToName;

  const AdmissionInquiry({
    required this.id,
    required this.tenantId,
    required this.studentName,
    required this.parentName,
    this.email,
    required this.phone,
    required this.source,
    this.applyingForClassId,
    this.academicYearId,
    required this.status,
    this.assignedTo,
    this.nextFollowupDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.className,
    this.assignedToName,
  });

  factory AdmissionInquiry.fromJson(Map<String, dynamic> json) {
    String? className;
    if (json['classes'] != null) {
      className = json['classes']['name'];
    }

    String? assignedToName;
    if (json['users'] != null) {
      assignedToName = json['users']['full_name'];
    }

    return AdmissionInquiry(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      studentName: json['student_name'] ?? '',
      parentName: json['parent_name'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      source: InquirySource.fromString(json['source'] ?? 'other'),
      applyingForClassId: json['applying_for_class_id'],
      academicYearId: json['academic_year_id'],
      status: InquiryStatus.fromString(json['status'] ?? 'new'),
      assignedTo: json['assigned_to'],
      nextFollowupDate: json['next_followup_date'] != null
          ? DateTime.parse(json['next_followup_date'])
          : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      className: className,
      assignedToName: assignedToName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'student_name': studentName,
      'parent_name': parentName,
      'email': email,
      'phone': phone,
      'source': source.value,
      'applying_for_class_id': applyingForClassId,
      'academic_year_id': academicYearId,
      'status': status.value,
      'assigned_to': assignedTo,
      'next_followup_date': nextFollowupDate?.toIso8601String().split('T')[0],
      'notes': notes,
    };
  }
}

/// Parent info embedded in application
class AdmissionParentInfo {
  final String? fatherName;
  final String? fatherPhone;
  final String? fatherEmail;
  final String? fatherOccupation;
  final String? motherName;
  final String? motherPhone;
  final String? motherEmail;
  final String? motherOccupation;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianRelation;

  const AdmissionParentInfo({
    this.fatherName,
    this.fatherPhone,
    this.fatherEmail,
    this.fatherOccupation,
    this.motherName,
    this.motherPhone,
    this.motherEmail,
    this.motherOccupation,
    this.guardianName,
    this.guardianPhone,
    this.guardianRelation,
  });

  factory AdmissionParentInfo.fromJson(Map<String, dynamic> json) {
    return AdmissionParentInfo(
      fatherName: json['father_name'],
      fatherPhone: json['father_phone'],
      fatherEmail: json['father_email'],
      fatherOccupation: json['father_occupation'],
      motherName: json['mother_name'],
      motherPhone: json['mother_phone'],
      motherEmail: json['mother_email'],
      motherOccupation: json['mother_occupation'],
      guardianName: json['guardian_name'],
      guardianPhone: json['guardian_phone'],
      guardianRelation: json['guardian_relation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'father_name': fatherName,
      'father_phone': fatherPhone,
      'father_email': fatherEmail,
      'father_occupation': fatherOccupation,
      'mother_name': motherName,
      'mother_phone': motherPhone,
      'mother_email': motherEmail,
      'mother_occupation': motherOccupation,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
      'guardian_relation': guardianRelation,
    };
  }
}

/// Admission Application model
class AdmissionApplication {
  final String id;
  final String tenantId;
  final String? inquiryId;
  final String? applicationNumber;
  final String studentName;
  final DateTime dateOfBirth;
  final String gender;
  final String applyingForClassId;
  final String academicYearId;
  final String? previousSchool;
  final String? previousClass;
  final AdmissionParentInfo parentInfo;
  final Map<String, dynamic> documents;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final ApplicationStatus status;
  final String? statusNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final int? waitlistPosition;
  final String? enrolledStudentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? className;
  final String? academicYearName;
  final List<AdmissionInterview>? interviews;
  final List<AdmissionDocument>? applicationDocuments;

  const AdmissionApplication({
    required this.id,
    required this.tenantId,
    this.inquiryId,
    this.applicationNumber,
    required this.studentName,
    required this.dateOfBirth,
    required this.gender,
    required this.applyingForClassId,
    required this.academicYearId,
    this.previousSchool,
    this.previousClass,
    required this.parentInfo,
    required this.documents,
    this.address,
    this.city,
    this.state,
    this.pincode,
    required this.status,
    this.statusNotes,
    this.reviewedBy,
    this.reviewedAt,
    this.waitlistPosition,
    this.enrolledStudentId,
    required this.createdAt,
    required this.updatedAt,
    this.className,
    this.academicYearName,
    this.interviews,
    this.applicationDocuments,
  });

  factory AdmissionApplication.fromJson(Map<String, dynamic> json) {
    String? className;
    if (json['classes'] != null) {
      className = json['classes']['name'];
    }

    String? academicYearName;
    if (json['academic_years'] != null) {
      academicYearName = json['academic_years']['name'];
    }

    List<AdmissionInterview>? interviews;
    if (json['admission_interviews_v2'] != null) {
      interviews = (json['admission_interviews_v2'] as List)
          .map((j) => AdmissionInterview.fromJson(j))
          .toList();
    }

    List<AdmissionDocument>? docs;
    if (json['admission_documents_v2'] != null) {
      docs = (json['admission_documents_v2'] as List)
          .map((j) => AdmissionDocument.fromJson(j))
          .toList();
    }

    final parentInfoRaw = json['parent_info'];
    final parentInfo = parentInfoRaw is Map<String, dynamic>
        ? AdmissionParentInfo.fromJson(parentInfoRaw)
        : const AdmissionParentInfo();

    final documentsRaw = json['documents'];
    final documents = documentsRaw is Map<String, dynamic>
        ? documentsRaw
        : <String, dynamic>{};

    return AdmissionApplication(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      inquiryId: json['inquiry_id'],
      applicationNumber: json['application_number'],
      studentName: json['student_name'] ?? '',
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : DateTime.now(),
      gender: json['gender'] ?? '',
      applyingForClassId: json['applying_for_class_id'] ?? '',
      academicYearId: json['academic_year_id'] ?? '',
      previousSchool: json['previous_school'],
      previousClass: json['previous_class'],
      parentInfo: parentInfo,
      documents: documents,
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      status: ApplicationStatus.fromString(json['status'] ?? 'draft'),
      statusNotes: json['status_notes'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      waitlistPosition: json['waitlist_position'],
      enrolledStudentId: json['enrolled_student_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      className: className,
      academicYearName: academicYearName,
      interviews: interviews,
      applicationDocuments: docs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'inquiry_id': inquiryId,
      'student_name': studentName,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      'gender': gender,
      'applying_for_class_id': applyingForClassId,
      'academic_year_id': academicYearId,
      'previous_school': previousSchool,
      'previous_class': previousClass,
      'parent_info': parentInfo.toJson(),
      'documents': documents,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'status': status.value,
      'status_notes': statusNotes,
    };
  }

  /// Full address string
  String get fullAddress {
    final parts = [address, city, state, pincode]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  /// Age at admission
  int get age {
    final now = DateTime.now();
    int a = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      a--;
    }
    return a;
  }
}

/// Admission Interview model
class AdmissionInterview {
  final String id;
  final String tenantId;
  final String applicationId;
  final DateTime scheduledAt;
  final String interviewerId;
  final String? location;
  final String? feedback;
  final int? score;
  final String? recommendation;
  final InterviewStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? interviewerName;
  final String? applicantName;

  const AdmissionInterview({
    required this.id,
    required this.tenantId,
    required this.applicationId,
    required this.scheduledAt,
    required this.interviewerId,
    this.location,
    this.feedback,
    this.score,
    this.recommendation,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.interviewerName,
    this.applicantName,
  });

  factory AdmissionInterview.fromJson(Map<String, dynamic> json) {
    String? interviewerName;
    if (json['users'] != null) {
      interviewerName = json['users']['full_name'];
    }

    String? applicantName;
    if (json['admission_applications_v2'] != null) {
      applicantName = json['admission_applications_v2']['student_name'];
    }

    return AdmissionInterview(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      applicationId: json['application_id'] ?? '',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : DateTime.now(),
      interviewerId: json['interviewer_id'] ?? '',
      location: json['location'],
      feedback: json['feedback'],
      score: json['score'],
      recommendation: json['recommendation'],
      status: InterviewStatus.fromString(json['status'] ?? 'scheduled'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      interviewerName: interviewerName,
      applicantName: applicantName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'application_id': applicationId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'interviewer_id': interviewerId,
      'location': location,
      'feedback': feedback,
      'score': score,
      'recommendation': recommendation,
      'status': status.value,
    };
  }
}

/// Admission Document model
class AdmissionDocument {
  final String id;
  final String tenantId;
  final String applicationId;
  final AdmissionDocumentType documentType;
  final String fileUrl;
  final String? fileName;
  final DocumentStatus status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdmissionDocument({
    required this.id,
    required this.tenantId,
    required this.applicationId,
    required this.documentType,
    required this.fileUrl,
    this.fileName,
    required this.status,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdmissionDocument.fromJson(Map<String, dynamic> json) {
    return AdmissionDocument(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      applicationId: json['application_id'] ?? '',
      documentType:
          AdmissionDocumentType.fromString(json['document_type'] ?? 'other'),
      fileUrl: json['file_url'] ?? '',
      fileName: json['file_name'],
      status: DocumentStatus.fromString(json['status'] ?? 'pending'),
      verifiedBy: json['verified_by'],
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      rejectionReason: json['rejection_reason'],
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
      'application_id': applicationId,
      'document_type': documentType.value,
      'file_url': fileUrl,
      'file_name': fileName,
      'status': status.value,
    };
  }
}

/// Admission Settings model (per class per year)
class AdmissionSettings {
  final String id;
  final String tenantId;
  final String academicYearId;
  final String classId;
  final int totalSeats;
  final int filledSeats;
  final int waitlistLimit;
  final double applicationFee;
  final List<String> documentsRequired;
  final bool admissionOpen;
  final DateTime? openDate;
  final DateTime? closeDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? className;
  final String? academicYearName;

  const AdmissionSettings({
    required this.id,
    required this.tenantId,
    required this.academicYearId,
    required this.classId,
    required this.totalSeats,
    required this.filledSeats,
    required this.waitlistLimit,
    required this.applicationFee,
    required this.documentsRequired,
    required this.admissionOpen,
    this.openDate,
    this.closeDate,
    required this.createdAt,
    required this.updatedAt,
    this.className,
    this.academicYearName,
  });

  int get availableSeats => totalSeats - filledSeats;

  factory AdmissionSettings.fromJson(Map<String, dynamic> json) {
    String? className;
    if (json['classes'] != null) {
      className = json['classes']['name'];
    }

    String? academicYearName;
    if (json['academic_years'] != null) {
      academicYearName = json['academic_years']['name'];
    }

    List<String> docsRequired = [];
    if (json['documents_required'] != null) {
      if (json['documents_required'] is List) {
        docsRequired = (json['documents_required'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return AdmissionSettings(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      academicYearId: json['academic_year_id'] ?? '',
      classId: json['class_id'] ?? '',
      totalSeats: json['total_seats'] ?? 40,
      filledSeats: json['filled_seats'] ?? 0,
      waitlistLimit: json['waitlist_limit'] ?? 10,
      applicationFee: json['application_fee'] != null
          ? (json['application_fee'] as num).toDouble()
          : 0,
      documentsRequired: docsRequired,
      admissionOpen: json['admission_open'] ?? false,
      openDate: json['open_date'] != null
          ? DateTime.parse(json['open_date'])
          : null,
      closeDate: json['close_date'] != null
          ? DateTime.parse(json['close_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      className: className,
      academicYearName: academicYearName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'academic_year_id': academicYearId,
      'class_id': classId,
      'total_seats': totalSeats,
      'filled_seats': filledSeats,
      'waitlist_limit': waitlistLimit,
      'application_fee': applicationFee,
      'documents_required': documentsRequired,
      'admission_open': admissionOpen,
      'open_date': openDate?.toIso8601String().split('T')[0],
      'close_date': closeDate?.toIso8601String().split('T')[0],
    };
  }
}

/// Admission statistics aggregate
class AdmissionStats {
  final int totalApplications;
  final int submitted;
  final int underReview;
  final int interviewScheduled;
  final int accepted;
  final int rejected;
  final int waitlisted;
  final int enrolled;
  final int withdrawn;
  final int draft;
  final int totalInquiries;
  final int openInquiries;

  const AdmissionStats({
    this.totalApplications = 0,
    this.submitted = 0,
    this.underReview = 0,
    this.interviewScheduled = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.waitlisted = 0,
    this.enrolled = 0,
    this.withdrawn = 0,
    this.draft = 0,
    this.totalInquiries = 0,
    this.openInquiries = 0,
  });

  int get pendingReview => submitted + underReview + interviewScheduled;
  double get acceptanceRate =>
      totalApplications > 0 ? (accepted + enrolled) / totalApplications : 0;
  double get conversionRate =>
      totalInquiries > 0 ? totalApplications / totalInquiries : 0;
}
