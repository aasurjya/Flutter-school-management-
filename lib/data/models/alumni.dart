// Alumni Management module models

// ============================================
// ENUMS
// ============================================

enum AlumniVisibility {
  public,
  alumniOnly,
  private_;

  String get value {
    switch (this) {
      case AlumniVisibility.public:
        return 'public';
      case AlumniVisibility.alumniOnly:
        return 'alumni_only';
      case AlumniVisibility.private_:
        return 'private';
    }
  }

  String get label {
    switch (this) {
      case AlumniVisibility.public:
        return 'Public';
      case AlumniVisibility.alumniOnly:
        return 'Alumni Only';
      case AlumniVisibility.private_:
        return 'Private';
    }
  }

  static AlumniVisibility fromString(String value) {
    switch (value) {
      case 'public':
        return AlumniVisibility.public;
      case 'alumni_only':
        return AlumniVisibility.alumniOnly;
      case 'private':
        return AlumniVisibility.private_;
      default:
        return AlumniVisibility.alumniOnly;
    }
  }
}

enum AlumniEventType {
  reunion,
  networking,
  careerTalk,
  fundraiser,
  meetup;

  String get value {
    switch (this) {
      case AlumniEventType.reunion:
        return 'reunion';
      case AlumniEventType.networking:
        return 'networking';
      case AlumniEventType.careerTalk:
        return 'career_talk';
      case AlumniEventType.fundraiser:
        return 'fundraiser';
      case AlumniEventType.meetup:
        return 'meetup';
    }
  }

  String get label {
    switch (this) {
      case AlumniEventType.reunion:
        return 'Reunion';
      case AlumniEventType.networking:
        return 'Networking';
      case AlumniEventType.careerTalk:
        return 'Career Talk';
      case AlumniEventType.fundraiser:
        return 'Fundraiser';
      case AlumniEventType.meetup:
        return 'Meetup';
    }
  }

  static AlumniEventType fromString(String value) {
    switch (value) {
      case 'reunion':
        return AlumniEventType.reunion;
      case 'networking':
        return AlumniEventType.networking;
      case 'career_talk':
        return AlumniEventType.careerTalk;
      case 'fundraiser':
        return AlumniEventType.fundraiser;
      case 'meetup':
        return AlumniEventType.meetup;
      default:
        return AlumniEventType.meetup;
    }
  }
}

enum AlumniEventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case AlumniEventStatus.upcoming:
        return 'upcoming';
      case AlumniEventStatus.ongoing:
        return 'ongoing';
      case AlumniEventStatus.completed:
        return 'completed';
      case AlumniEventStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case AlumniEventStatus.upcoming:
        return 'Upcoming';
      case AlumniEventStatus.ongoing:
        return 'Ongoing';
      case AlumniEventStatus.completed:
        return 'Completed';
      case AlumniEventStatus.cancelled:
        return 'Cancelled';
    }
  }

  static AlumniEventStatus fromString(String value) {
    switch (value) {
      case 'upcoming':
        return AlumniEventStatus.upcoming;
      case 'ongoing':
        return AlumniEventStatus.ongoing;
      case 'completed':
        return AlumniEventStatus.completed;
      case 'cancelled':
        return AlumniEventStatus.cancelled;
      default:
        return AlumniEventStatus.upcoming;
    }
  }
}

enum AlumniRegistrationStatus {
  registered,
  attended,
  cancelled;

  String get value {
    switch (this) {
      case AlumniRegistrationStatus.registered:
        return 'registered';
      case AlumniRegistrationStatus.attended:
        return 'attended';
      case AlumniRegistrationStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case AlumniRegistrationStatus.registered:
        return 'Registered';
      case AlumniRegistrationStatus.attended:
        return 'Attended';
      case AlumniRegistrationStatus.cancelled:
        return 'Cancelled';
    }
  }

  static AlumniRegistrationStatus fromString(String value) {
    switch (value) {
      case 'registered':
        return AlumniRegistrationStatus.registered;
      case 'attended':
        return AlumniRegistrationStatus.attended;
      case 'cancelled':
        return AlumniRegistrationStatus.cancelled;
      default:
        return AlumniRegistrationStatus.registered;
    }
  }
}

enum AlumniDonationPurpose {
  general,
  scholarship,
  infrastructure,
  sports,
  library;

  String get value {
    switch (this) {
      case AlumniDonationPurpose.general:
        return 'general';
      case AlumniDonationPurpose.scholarship:
        return 'scholarship';
      case AlumniDonationPurpose.infrastructure:
        return 'infrastructure';
      case AlumniDonationPurpose.sports:
        return 'sports';
      case AlumniDonationPurpose.library:
        return 'library';
    }
  }

  String get label {
    switch (this) {
      case AlumniDonationPurpose.general:
        return 'General Fund';
      case AlumniDonationPurpose.scholarship:
        return 'Scholarship';
      case AlumniDonationPurpose.infrastructure:
        return 'Infrastructure';
      case AlumniDonationPurpose.sports:
        return 'Sports';
      case AlumniDonationPurpose.library:
        return 'Library';
    }
  }

  static AlumniDonationPurpose fromString(String value) {
    switch (value) {
      case 'general':
        return AlumniDonationPurpose.general;
      case 'scholarship':
        return AlumniDonationPurpose.scholarship;
      case 'infrastructure':
        return AlumniDonationPurpose.infrastructure;
      case 'sports':
        return AlumniDonationPurpose.sports;
      case 'library':
        return AlumniDonationPurpose.library;
      default:
        return AlumniDonationPurpose.general;
    }
  }
}

enum AlumniDonationStatus {
  pending,
  completed,
  failed;

  String get value {
    switch (this) {
      case AlumniDonationStatus.pending:
        return 'pending';
      case AlumniDonationStatus.completed:
        return 'completed';
      case AlumniDonationStatus.failed:
        return 'failed';
    }
  }

  String get label {
    switch (this) {
      case AlumniDonationStatus.pending:
        return 'Pending';
      case AlumniDonationStatus.completed:
        return 'Completed';
      case AlumniDonationStatus.failed:
        return 'Failed';
    }
  }

  static AlumniDonationStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return AlumniDonationStatus.pending;
      case 'completed':
        return AlumniDonationStatus.completed;
      case 'failed':
        return AlumniDonationStatus.failed;
      default:
        return AlumniDonationStatus.pending;
    }
  }
}

enum MentorshipProgramStatus {
  open,
  inProgress,
  completed;

  String get value {
    switch (this) {
      case MentorshipProgramStatus.open:
        return 'open';
      case MentorshipProgramStatus.inProgress:
        return 'in_progress';
      case MentorshipProgramStatus.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case MentorshipProgramStatus.open:
        return 'Open';
      case MentorshipProgramStatus.inProgress:
        return 'In Progress';
      case MentorshipProgramStatus.completed:
        return 'Completed';
    }
  }

  static MentorshipProgramStatus fromString(String value) {
    switch (value) {
      case 'open':
        return MentorshipProgramStatus.open;
      case 'in_progress':
        return MentorshipProgramStatus.inProgress;
      case 'completed':
        return MentorshipProgramStatus.completed;
      default:
        return MentorshipProgramStatus.open;
    }
  }
}

enum MentorshipRequestStatus {
  pending,
  accepted,
  rejected,
  completed;

  String get value {
    switch (this) {
      case MentorshipRequestStatus.pending:
        return 'pending';
      case MentorshipRequestStatus.accepted:
        return 'accepted';
      case MentorshipRequestStatus.rejected:
        return 'rejected';
      case MentorshipRequestStatus.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case MentorshipRequestStatus.pending:
        return 'Pending';
      case MentorshipRequestStatus.accepted:
        return 'Accepted';
      case MentorshipRequestStatus.rejected:
        return 'Rejected';
      case MentorshipRequestStatus.completed:
        return 'Completed';
    }
  }

  static MentorshipRequestStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return MentorshipRequestStatus.pending;
      case 'accepted':
        return MentorshipRequestStatus.accepted;
      case 'rejected':
        return MentorshipRequestStatus.rejected;
      case 'completed':
        return MentorshipRequestStatus.completed;
      default:
        return MentorshipRequestStatus.pending;
    }
  }
}

enum AlumniStoryStatus {
  draft,
  published;

  String get value {
    switch (this) {
      case AlumniStoryStatus.draft:
        return 'draft';
      case AlumniStoryStatus.published:
        return 'published';
    }
  }

  String get label {
    switch (this) {
      case AlumniStoryStatus.draft:
        return 'Draft';
      case AlumniStoryStatus.published:
        return 'Published';
    }
  }

  static AlumniStoryStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return AlumniStoryStatus.draft;
      case 'published':
        return AlumniStoryStatus.published;
      default:
        return AlumniStoryStatus.draft;
    }
  }
}

// ============================================
// MODEL CLASSES
// ============================================

/// Alumni Profile model
class AlumniProfile {
  final String id;
  final String tenantId;
  final String? userId;
  final String? studentId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final int graduationYear;
  final String? className;
  final String? profilePhotoUrl;
  final String? currentCompany;
  final String? currentDesignation;
  final String? industry;
  final String? locationCity;
  final String? locationCountry;
  final String? linkedinUrl;
  final String? bio;
  final List<String> skills;
  final bool isVerified;
  final bool isMentor;
  final AlumniVisibility visibility;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AlumniProfile({
    required this.id,
    required this.tenantId,
    this.userId,
    this.studentId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    required this.graduationYear,
    this.className,
    this.profilePhotoUrl,
    this.currentCompany,
    this.currentDesignation,
    this.industry,
    this.locationCity,
    this.locationCountry,
    this.linkedinUrl,
    this.bio,
    this.skills = const [],
    this.isVerified = false,
    this.isMentor = false,
    this.visibility = AlumniVisibility.alumniOnly,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  String get locationDisplay {
    final parts = [locationCity, locationCountry]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Not specified' : parts.join(', ');
  }

  String get careerDisplay {
    if (currentDesignation != null && currentCompany != null) {
      return '$currentDesignation at $currentCompany';
    }
    return currentDesignation ?? currentCompany ?? 'Not specified';
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  factory AlumniProfile.fromJson(Map<String, dynamic> json) {
    List<String> skills = [];
    if (json['skills'] != null) {
      if (json['skills'] is List) {
        skills = (json['skills'] as List).map((e) => e.toString()).toList();
      }
    }

    return AlumniProfile(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      userId: json['user_id'],
      studentId: json['student_id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      graduationYear: json['graduation_year'] ?? 0,
      className: json['class_name'],
      profilePhotoUrl: json['profile_photo_url'],
      currentCompany: json['current_company'],
      currentDesignation: json['current_designation'],
      industry: json['industry'],
      locationCity: json['location_city'],
      locationCountry: json['location_country'],
      linkedinUrl: json['linkedin_url'],
      bio: json['bio'],
      skills: skills,
      isVerified: json['is_verified'] ?? false,
      isMentor: json['is_mentor'] ?? false,
      visibility:
          AlumniVisibility.fromString(json['visibility'] ?? 'alumni_only'),
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
      'user_id': userId,
      'student_id': studentId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'graduation_year': graduationYear,
      'class_name': className,
      'profile_photo_url': profilePhotoUrl,
      'current_company': currentCompany,
      'current_designation': currentDesignation,
      'industry': industry,
      'location_city': locationCity,
      'location_country': locationCountry,
      'linkedin_url': linkedinUrl,
      'bio': bio,
      'skills': skills,
      'is_verified': isVerified,
      'is_mentor': isMentor,
      'visibility': visibility.value,
    };
  }
}

/// Alumni Event model
class AlumniEvent {
  final String id;
  final String tenantId;
  final String title;
  final String? description;
  final AlumniEventType eventType;
  final DateTime date;
  final DateTime? endDate;
  final String? location;
  final bool isVirtual;
  final String? virtualLink;
  final int? maxAttendees;
  final String? imageUrl;
  final String? organizerId;
  final AlumniEventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final AlumniProfile? organizer;
  final int? registrationCount;

  const AlumniEvent({
    required this.id,
    required this.tenantId,
    required this.title,
    this.description,
    required this.eventType,
    required this.date,
    this.endDate,
    this.location,
    this.isVirtual = false,
    this.virtualLink,
    this.maxAttendees,
    this.imageUrl,
    this.organizerId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.organizer,
    this.registrationCount,
  });

  bool get hasCapacity =>
      maxAttendees == null || (registrationCount ?? 0) < maxAttendees!;

  int get spotsRemaining =>
      maxAttendees != null ? maxAttendees! - (registrationCount ?? 0) : -1;

  factory AlumniEvent.fromJson(Map<String, dynamic> json) {
    AlumniProfile? organizer;
    if (json['alumni_profiles'] != null &&
        json['alumni_profiles'] is Map<String, dynamic>) {
      organizer = AlumniProfile.fromJson(json['alumni_profiles']);
    }

    int? regCount;
    if (json['alumni_event_registrations'] != null &&
        json['alumni_event_registrations'] is List) {
      regCount = (json['alumni_event_registrations'] as List).length;
    }

    return AlumniEvent(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      eventType:
          AlumniEventType.fromString(json['event_type'] ?? 'meetup'),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      location: json['location'],
      isVirtual: json['is_virtual'] ?? false,
      virtualLink: json['virtual_link'],
      maxAttendees: json['max_attendees'],
      imageUrl: json['image_url'],
      organizerId: json['organizer_id'],
      status:
          AlumniEventStatus.fromString(json['status'] ?? 'upcoming'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      organizer: organizer,
      registrationCount: regCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'event_type': eventType.value,
      'date': date.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'is_virtual': isVirtual,
      'virtual_link': virtualLink,
      'max_attendees': maxAttendees,
      'image_url': imageUrl,
      'organizer_id': organizerId,
      'status': status.value,
    };
  }
}

/// Event Registration model
class AlumniEventRegistration {
  final String id;
  final String eventId;
  final String alumniId;
  final AlumniRegistrationStatus status;
  final DateTime registeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final AlumniProfile? alumni;

  const AlumniEventRegistration({
    required this.id,
    required this.eventId,
    required this.alumniId,
    required this.status,
    required this.registeredAt,
    required this.createdAt,
    required this.updatedAt,
    this.alumni,
  });

  factory AlumniEventRegistration.fromJson(Map<String, dynamic> json) {
    AlumniProfile? alumni;
    if (json['alumni_profiles'] != null &&
        json['alumni_profiles'] is Map<String, dynamic>) {
      alumni = AlumniProfile.fromJson(json['alumni_profiles']);
    }

    return AlumniEventRegistration(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      alumniId: json['alumni_id'] ?? '',
      status: AlumniRegistrationStatus.fromString(
          json['status'] ?? 'registered'),
      registeredAt: json['registered_at'] != null
          ? DateTime.parse(json['registered_at'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      alumni: alumni,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'alumni_id': alumniId,
      'status': status.value,
    };
  }
}

/// Alumni Donation model
class AlumniDonation {
  final String id;
  final String tenantId;
  final String alumniId;
  final double amount;
  final String currency;
  final AlumniDonationPurpose purpose;
  final String? paymentMethod;
  final String? transactionRef;
  final String? message;
  final bool isAnonymous;
  final AlumniDonationStatus status;
  final DateTime donatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final AlumniProfile? alumni;

  const AlumniDonation({
    required this.id,
    required this.tenantId,
    required this.alumniId,
    required this.amount,
    this.currency = 'INR',
    required this.purpose,
    this.paymentMethod,
    this.transactionRef,
    this.message,
    this.isAnonymous = false,
    required this.status,
    required this.donatedAt,
    required this.createdAt,
    required this.updatedAt,
    this.alumni,
  });

  factory AlumniDonation.fromJson(Map<String, dynamic> json) {
    AlumniProfile? alumni;
    if (json['alumni_profiles'] != null &&
        json['alumni_profiles'] is Map<String, dynamic>) {
      alumni = AlumniProfile.fromJson(json['alumni_profiles']);
    }

    return AlumniDonation(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      alumniId: json['alumni_id'] ?? '',
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : 0.0,
      currency: json['currency'] ?? 'INR',
      purpose:
          AlumniDonationPurpose.fromString(json['purpose'] ?? 'general'),
      paymentMethod: json['payment_method'],
      transactionRef: json['transaction_ref'],
      message: json['message'],
      isAnonymous: json['is_anonymous'] ?? false,
      status:
          AlumniDonationStatus.fromString(json['status'] ?? 'pending'),
      donatedAt: json['donated_at'] != null
          ? DateTime.parse(json['donated_at'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      alumni: alumni,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'alumni_id': alumniId,
      'amount': amount,
      'currency': currency,
      'purpose': purpose.value,
      'payment_method': paymentMethod,
      'transaction_ref': transactionRef,
      'message': message,
      'is_anonymous': isAnonymous,
      'status': status.value,
      'donated_at': donatedAt.toIso8601String(),
    };
  }
}

/// Mentorship Program model
class MentorshipProgram {
  final String id;
  final String tenantId;
  final String title;
  final String? description;
  final String mentorId;
  final int menteeCountLimit;
  final List<String> skillsOffered;
  final MentorshipProgramStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final AlumniProfile? mentor;
  final int? requestCount;

  const MentorshipProgram({
    required this.id,
    required this.tenantId,
    required this.title,
    this.description,
    required this.mentorId,
    this.menteeCountLimit = 5,
    this.skillsOffered = const [],
    required this.status,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.mentor,
    this.requestCount,
  });

  bool get hasMenteeSlots =>
      (requestCount ?? 0) < menteeCountLimit;

  int get slotsRemaining => menteeCountLimit - (requestCount ?? 0);

  factory MentorshipProgram.fromJson(Map<String, dynamic> json) {
    AlumniProfile? mentor;
    if (json['alumni_profiles'] != null &&
        json['alumni_profiles'] is Map<String, dynamic>) {
      mentor = AlumniProfile.fromJson(json['alumni_profiles']);
    }

    int? reqCount;
    if (json['mentorship_requests'] != null &&
        json['mentorship_requests'] is List) {
      reqCount = (json['mentorship_requests'] as List).length;
    }

    List<String> skills = [];
    if (json['skills_offered'] != null && json['skills_offered'] is List) {
      skills =
          (json['skills_offered'] as List).map((e) => e.toString()).toList();
    }

    return MentorshipProgram(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      mentorId: json['mentor_id'] ?? '',
      menteeCountLimit: json['mentee_count_limit'] ?? 5,
      skillsOffered: skills,
      status: MentorshipProgramStatus.fromString(
          json['status'] ?? 'open'),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      mentor: mentor,
      requestCount: reqCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'mentor_id': mentorId,
      'mentee_count_limit': menteeCountLimit,
      'skills_offered': skillsOffered,
      'status': status.value,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
    };
  }
}

/// Mentorship Request model
class MentorshipRequest {
  final String id;
  final String programId;
  final String studentId;
  final String? message;
  final MentorshipRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final MentorshipProgram? program;

  const MentorshipRequest({
    required this.id,
    required this.programId,
    required this.studentId,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.program,
  });

  factory MentorshipRequest.fromJson(Map<String, dynamic> json) {
    MentorshipProgram? program;
    if (json['mentorship_programs'] != null &&
        json['mentorship_programs'] is Map<String, dynamic>) {
      program = MentorshipProgram.fromJson(json['mentorship_programs']);
    }

    return MentorshipRequest(
      id: json['id'] ?? '',
      programId: json['program_id'] ?? '',
      studentId: json['student_id'] ?? '',
      message: json['message'],
      status: MentorshipRequestStatus.fromString(
          json['status'] ?? 'pending'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      program: program,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'program_id': programId,
      'student_id': studentId,
      'message': message,
      'status': status.value,
    };
  }
}

/// Alumni Success Story model
class AlumniSuccessStory {
  final String id;
  final String tenantId;
  final String alumniId;
  final String title;
  final String storyText;
  final String? imageUrl;
  final bool isFeatured;
  final String? approvedBy;
  final AlumniStoryStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final AlumniProfile? alumni;

  const AlumniSuccessStory({
    required this.id,
    required this.tenantId,
    required this.alumniId,
    required this.title,
    required this.storyText,
    this.imageUrl,
    this.isFeatured = false,
    this.approvedBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.alumni,
  });

  factory AlumniSuccessStory.fromJson(Map<String, dynamic> json) {
    AlumniProfile? alumni;
    if (json['alumni_profiles'] != null &&
        json['alumni_profiles'] is Map<String, dynamic>) {
      alumni = AlumniProfile.fromJson(json['alumni_profiles']);
    }

    return AlumniSuccessStory(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      alumniId: json['alumni_id'] ?? '',
      title: json['title'] ?? '',
      storyText: json['story_text'] ?? '',
      imageUrl: json['image_url'],
      isFeatured: json['is_featured'] ?? false,
      approvedBy: json['approved_by'],
      status: AlumniStoryStatus.fromString(json['status'] ?? 'draft'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      alumni: alumni,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'alumni_id': alumniId,
      'title': title,
      'story_text': storyText,
      'image_url': imageUrl,
      'is_featured': isFeatured,
      'status': status.value,
    };
  }
}

/// Alumni Stats aggregate
class AlumniStats {
  final int totalAlumni;
  final int verifiedAlumni;
  final int mentorCount;
  final int upcomingEventsCount;
  final double totalDonations;
  final int donationCount;
  final int storiesCount;
  final int activeMentorships;

  const AlumniStats({
    this.totalAlumni = 0,
    this.verifiedAlumni = 0,
    this.mentorCount = 0,
    this.upcomingEventsCount = 0,
    this.totalDonations = 0,
    this.donationCount = 0,
    this.storiesCount = 0,
    this.activeMentorships = 0,
  });
}
