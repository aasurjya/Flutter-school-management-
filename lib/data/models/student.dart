/// Student model
class Student {
  final String id;
  final String tenantId;
  final String? userId;
  final String admissionNumber;
  final String? rollNumber;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final DateTime dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? nationality;
  final String? religion;
  final String? motherTongue;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? photoUrl;
  final String? medicalConditions;
  final DateTime admissionDate;
  final String? previousSchool;
  final String paymentStatus;
  final double? paymentAmount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final StudentEnrollment? currentEnrollment;
  final List<Parent>? parents;

  const Student({
    required this.id,
    required this.tenantId,
    this.userId,
    required this.admissionNumber,
    this.rollNumber,
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    required this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.nationality,
    this.religion,
    this.motherTongue,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.photoUrl,
    this.medicalConditions,
    required this.admissionDate,
    this.previousSchool,
    this.paymentStatus = 'pending',
    this.paymentAmount,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.currentEnrollment,
    this.parents,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    // Parse current enrollment if available
    StudentEnrollment? enrollment;
    if (json['student_enrollments'] != null &&
        (json['student_enrollments'] as List).isNotEmpty) {
      enrollment = StudentEnrollment.fromJson(json['student_enrollments'][0]);
    } else if (json['enrollment'] != null) {
      enrollment = StudentEnrollment.fromJson(json['enrollment']);
    }

    // Parse parents if available
    List<Parent>? parents;
    if (json['student_parents'] != null) {
      parents = (json['student_parents'] as List)
          .map((p) => Parent.fromJson(p['parent'] ?? p))
          .toList();
    }

    final dobRaw = json['date_of_birth'];
    final admissionDateRaw = json['admission_date'];

    return Student(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      userId: json['user_id'],
      admissionNumber: json['admission_number'] ?? '',
      rollNumber: json['roll_number'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'],
      email: json['email'],
      phone: json['phone'],
      dateOfBirth:
          dobRaw != null ? DateTime.parse(dobRaw) : DateTime.now(),
      gender: json['gender'],
      bloodGroup: json['blood_group'],
      nationality: json['nationality'],
      religion: json['religion'],
      motherTongue: json['mother_tongue'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      photoUrl: json['photo_url'],
      medicalConditions: json['medical_conditions'],
      admissionDate: admissionDateRaw != null
          ? DateTime.parse(admissionDateRaw)
          : DateTime.now(),
      previousSchool: json['previous_school'],
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentAmount: json['payment_amount'] != null
          ? (json['payment_amount'] as num).toDouble()
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      currentEnrollment: enrollment,
      parents: parents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'user_id': userId,
      'admission_number': admissionNumber,
      'roll_number': rollNumber,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      'gender': gender,
      'blood_group': bloodGroup,
      'nationality': nationality,
      'religion': religion,
      'mother_tongue': motherTongue,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'photo_url': photoUrl,
      'medical_conditions': medicalConditions,
      'admission_date': admissionDate.toIso8601String().split('T')[0],
      'previous_school': previousSchool,
      'payment_status': paymentStatus,
      'payment_amount': paymentAmount,
      'is_active': isActive,
    };
  }

  /// Full name
  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  /// Initials for avatar
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName?.isNotEmpty == true ? lastName![0].toUpperCase() : '';
    return '$first$last';
  }

  /// Calculate age
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Full address
  String get fullAddress {
    final parts = [address, city, state, pincode]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  /// Current class display string
  String get currentClass {
    if (currentEnrollment == null) return 'Not Enrolled';
    final className = currentEnrollment!.className ?? '';
    final sectionName = currentEnrollment!.sectionName ?? '';
    return '$className - $sectionName';
  }
}

/// Student enrollment model
class StudentEnrollment {
  final String id;
  final String tenantId;
  final String studentId;
  final String sectionId;
  final String academicYearId;
  final String? rollNumber;
  final DateTime enrollmentDate;
  final String status;
  final DateTime createdAt;

  // Related data
  final String? className;
  final String? sectionName;
  final String? academicYearName;

  const StudentEnrollment({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.sectionId,
    required this.academicYearId,
    this.rollNumber,
    required this.enrollmentDate,
    this.status = 'active',
    required this.createdAt,
    this.className,
    this.sectionName,
    this.academicYearName,
  });

  factory StudentEnrollment.fromJson(Map<String, dynamic> json) {
    // Extract class and section names from nested data
    String? className;
    String? sectionName;
    if (json['section'] != null) {
      sectionName = json['section']['name'];
      if (json['section']['class'] != null) {
        className = json['section']['class']['name'];
      }
    }

    return StudentEnrollment(
      id: json['id'],
      tenantId: json['tenant_id'],
      studentId: json['student_id'],
      sectionId: json['section_id'],
      academicYearId: json['academic_year_id'],
      rollNumber: json['roll_number'],
      enrollmentDate: DateTime.parse(json['enrollment_date']),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      className: className,
      sectionName: sectionName,
      academicYearName: json['academic_year']?['name'],
    );
  }
}

/// Parent model
class Parent {
  final String id;
  final String tenantId;
  final String? userId;
  final String firstName;
  final String? lastName;
  final String relation;
  final String? email;
  final String phone;
  final String? occupation;
  final double? annualIncome;
  final String? address;
  final String? photoUrl;
  final bool isEmergencyContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Parent({
    required this.id,
    required this.tenantId,
    this.userId,
    required this.firstName,
    this.lastName,
    required this.relation,
    this.email,
    required this.phone,
    this.occupation,
    this.annualIncome,
    this.address,
    this.photoUrl,
    this.isEmergencyContact = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'],
      tenantId: json['tenant_id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      relation: json['relation'],
      email: json['email'],
      phone: json['phone'],
      occupation: json['occupation'],
      annualIncome: json['annual_income']?.toDouble(),
      address: json['address'],
      photoUrl: json['photo_url'],
      isEmergencyContact: json['is_emergency_contact'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Full name
  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  /// Relation display
  String get relationDisplay =>
      relation[0].toUpperCase() + relation.substring(1);
}
