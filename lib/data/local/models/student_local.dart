// Note: Isar is disabled for web builds. This model is kept for mobile/desktop.
// import 'package:isar/isar.dart';
// part 'student_local.g.dart';

/// Local student model for offline storage
// @collection
class StudentLocal {
  StudentLocal();

  int? isarId;

  late String id;

  late String tenantId;

  late String admissionNumber;
  String? rollNumber;
  late String firstName;
  String? lastName;
  late DateTime dateOfBirth;
  String? gender;
  String? bloodGroup;
  String? photoUrl;
  String? address;
  String? city;
  String? state;
  String? pincode;
  String? phone;
  String? email;
  bool isActive = true;

  // Current enrollment info
  String? currentSectionId;
  String? currentClassName;
  String? currentSectionName;

  // Sync metadata
  late DateTime syncedAt;
  bool pendingSync = false;

  /// Create from Supabase response
  factory StudentLocal.fromJson(Map<String, dynamic> json) {
    return StudentLocal()
      ..id = json['id']
      ..tenantId = json['tenant_id']
      ..admissionNumber = json['admission_number']
      ..rollNumber = json['roll_number']
      ..firstName = json['first_name']
      ..lastName = json['last_name']
      ..dateOfBirth = DateTime.parse(json['date_of_birth'])
      ..gender = json['gender']
      ..bloodGroup = json['blood_group']
      ..photoUrl = json['photo_url']
      ..address = json['address']
      ..city = json['city']
      ..state = json['state']
      ..pincode = json['pincode']
      ..isActive = json['is_active'] ?? true
      ..syncedAt = DateTime.now()
      ..pendingSync = false;
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'admission_number': admissionNumber,
      'roll_number': rollNumber,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      'gender': gender,
      'blood_group': bloodGroup,
      'photo_url': photoUrl,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
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
}
