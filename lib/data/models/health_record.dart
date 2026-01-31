/// Student health record model
class StudentHealthRecord {
  final String id;
  final String tenantId;
  final String studentId;
  final String? bloodGroup;
  final double? heightCm;
  final double? weightKg;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<Map<String, dynamic>> currentMedications;
  final List<Map<String, dynamic>> vaccinations;
  final List<String> dietaryRestrictions;
  final String? visionLeft;
  final String? visionRight;
  final String? hearingStatus;
  final String? physicalDisabilities;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? familyDoctorName;
  final String? familyDoctorPhone;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final String? notes;
  final DateTime? lastCheckupDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentHealthRecord({
    required this.id,
    required this.tenantId,
    required this.studentId,
    this.bloodGroup,
    this.heightCm,
    this.weightKg,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    this.vaccinations = const [],
    this.dietaryRestrictions = const [],
    this.visionLeft,
    this.visionRight,
    this.hearingStatus,
    this.physicalDisabilities,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.familyDoctorName,
    this.familyDoctorPhone,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.notes,
    this.lastCheckupDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentHealthRecord.fromJson(Map<String, dynamic> json) {
    return StudentHealthRecord(
      id: json['id'],
      tenantId: json['tenant_id'],
      studentId: json['student_id'],
      bloodGroup: json['blood_group'],
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : [],
      chronicConditions: json['chronic_conditions'] != null
          ? List<String>.from(json['chronic_conditions'])
          : [],
      currentMedications: json['current_medications'] != null
          ? List<Map<String, dynamic>>.from(json['current_medications'])
          : [],
      vaccinations: json['vaccinations'] != null
          ? List<Map<String, dynamic>>.from(json['vaccinations'])
          : [],
      dietaryRestrictions: json['dietary_restrictions'] != null
          ? List<String>.from(json['dietary_restrictions'])
          : [],
      visionLeft: json['vision_left'],
      visionRight: json['vision_right'],
      hearingStatus: json['hearing_status'],
      physicalDisabilities: json['physical_disabilities'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      emergencyContactRelation: json['emergency_contact_relation'],
      familyDoctorName: json['family_doctor_name'],
      familyDoctorPhone: json['family_doctor_phone'],
      insuranceProvider: json['insurance_provider'],
      insurancePolicyNumber: json['insurance_policy_number'],
      notes: json['notes'],
      lastCheckupDate: json['last_checkup_date'] != null
          ? DateTime.parse(json['last_checkup_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blood_group': bloodGroup,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      'current_medications': currentMedications,
      'vaccinations': vaccinations,
      'dietary_restrictions': dietaryRestrictions,
      'vision_left': visionLeft,
      'vision_right': visionRight,
      'hearing_status': hearingStatus,
      'physical_disabilities': physicalDisabilities,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relation': emergencyContactRelation,
      'family_doctor_name': familyDoctorName,
      'family_doctor_phone': familyDoctorPhone,
      'insurance_provider': insuranceProvider,
      'insurance_policy_number': insurancePolicyNumber,
      'notes': notes,
      'last_checkup_date': lastCheckupDate?.toIso8601String().split('T')[0],
    };
  }

  double? get bmi {
    if (heightCm == null || weightKg == null) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'N/A';
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  bool get hasAllergies => allergies.isNotEmpty;
  bool get hasChronicConditions => chronicConditions.isNotEmpty;
  bool get hasMedications => currentMedications.isNotEmpty;
}

/// Health incident model
class HealthIncident {
  final String id;
  final String tenantId;
  final String studentId;
  final DateTime incidentDate;
  final String? incidentTime;
  final String severity;
  final String description;
  final List<String>? symptoms;
  final String? treatmentGiven;
  final String? medicationAdministered;
  final bool referredToHospital;
  final String? hospitalName;
  final bool parentNotified;
  final DateTime? parentNotifiedAt;
  final bool followUpRequired;
  final DateTime? followUpDate;
  final String? followUpNotes;
  final String? reportedBy;
  final DateTime createdAt;

  const HealthIncident({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.incidentDate,
    this.incidentTime,
    required this.severity,
    required this.description,
    this.symptoms,
    this.treatmentGiven,
    this.medicationAdministered,
    this.referredToHospital = false,
    this.hospitalName,
    this.parentNotified = false,
    this.parentNotifiedAt,
    this.followUpRequired = false,
    this.followUpDate,
    this.followUpNotes,
    this.reportedBy,
    required this.createdAt,
  });

  factory HealthIncident.fromJson(Map<String, dynamic> json) {
    return HealthIncident(
      id: json['id'],
      tenantId: json['tenant_id'],
      studentId: json['student_id'],
      incidentDate: DateTime.parse(json['incident_date']),
      incidentTime: json['incident_time'],
      severity: json['severity'],
      description: json['description'],
      symptoms: json['symptoms'] != null
          ? List<String>.from(json['symptoms'])
          : null,
      treatmentGiven: json['treatment_given'],
      medicationAdministered: json['medication_administered'],
      referredToHospital: json['referred_to_hospital'] ?? false,
      hospitalName: json['hospital_name'],
      parentNotified: json['parent_notified'] ?? false,
      parentNotifiedAt: json['parent_notified_at'] != null
          ? DateTime.parse(json['parent_notified_at'])
          : null,
      followUpRequired: json['follow_up_required'] ?? false,
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'])
          : null,
      followUpNotes: json['follow_up_notes'],
      reportedBy: json['reported_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get severityDisplay {
    switch (severity) {
      case 'minor':
        return 'Minor';
      case 'moderate':
        return 'Moderate';
      case 'serious':
        return 'Serious';
      case 'critical':
        return 'Critical';
      default:
        return severity;
    }
  }

  bool get isCritical => severity == 'critical' || severity == 'serious';
}
