import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/admin_user_service.dart';
import '../../../core/utils/credential_generator.dart';
import '../../../data/models/admission.dart';
import '../../../data/models/student.dart';
import '../../../data/models/tenant.dart';
import '../../../data/repositories/admission_repository.dart';
import '../../../data/repositories/parent_repository.dart';
import '../../../data/repositories/student_repository.dart';

/// Result returned after a successful Accept-and-Enroll flow.
class EnrollmentResult {
  final Student student;
  final String email;
  final String password;

  const EnrollmentResult({
    required this.student,
    required this.email,
    required this.password,
  });
}

/// Executes the Accept-and-Enroll transactional chain:
///
///   1. Creates a `students` row from the application data.
///   2. Creates a `student_enrollments` row (student → section → academic year).
///   3. Creates an auth user via [AdminUserService] and links it to the student.
///   4. If parent contacts exist on the application, inserts `parents` rows
///      and `student_parents` links.
///   5. Marks the application status `enrolled` and records `enrolled_student_id`.
///
/// All writes are best-effort sequential. If student creation or auth-user
/// creation fails, the orphaned auth user is deleted before rethrowing so the
/// caller receives a clean error and can retry.
class EnrollmentService {
  final SupabaseClient _client;

  const EnrollmentService(this._client);

  /// Generates a suggested admission number in the format `ADM<year><millis4>`.
  static String suggestAdmissionNumber() {
    final year = DateTime.now().year;
    final suffix = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'ADM$year${suffix.toString().padLeft(4, '0')}';
  }

  /// Full Accept-and-Enroll sequence.
  ///
  /// [sectionId] is the section the student should be enrolled into.
  /// [admissionNumber] should be pre-validated by the confirmation sheet UI.
  /// [tenant] is used for email slug generation and logging.
  Future<EnrollmentResult> enroll({
    required AdmissionApplication app,
    required String sectionId,
    required String academicYearId,
    required String admissionNumber,
    required Tenant? tenant,
  }) async {
    final studentRepo = StudentRepository(_client);
    final admissionRepo = AdmissionRepository(_client);
    final parentRepo = ParentRepository(_client);
    final adminService = AdminUserService(_client);

    // Split student name: first word → firstName, rest → lastName.
    final nameParts = app.studentName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : app.studentName;
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;

    // Generate credentials.
    final tenantSlug = tenant?.slug ?? 'school';
    final email = CredentialGenerator.generateUsername(
      firstName: firstName,
      lastName: lastName ?? '',
      tenantSlug: tenantSlug,
    );
    final password = CredentialGenerator.generatePassword();

    String? createdUserId;

    try {
      // ── Step 1: Create auth user ──────────────────────────────────────────
      final tenantId = _client.auth.currentUser?.appMetadata['tenant_id'] as String? ?? '';
      final result = await adminService.createUser(
        email: email,
        password: password,
        fullName: app.studentName,
        tenantId: tenantId,
        role: 'student',
        phone: app.parentInfo.fatherPhone ??
            app.parentInfo.motherPhone ??
            app.parentInfo.guardianPhone,
      );
      createdUserId = result.userId;

      // ── Step 2: Create students row ───────────────────────────────────────
      final studentData = <String, dynamic>{
        'user_id': createdUserId,
        'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        'email': email,
        'date_of_birth': app.dateOfBirth.toIso8601String().split('T')[0],
        'gender': app.gender,
        'admission_number': admissionNumber,
        'admission_date': DateTime.now().toIso8601String().split('T')[0],
        'is_active': true,
        if (app.address != null) 'address': app.address,
        if (app.city != null) 'city': app.city,
        if (app.state != null) 'state': app.state,
        if (app.pincode != null) 'pincode': app.pincode,
      };
      final student = await studentRepo.createStudent(studentData);

      // ── Step 3: Enroll in section ─────────────────────────────────────────
      final rollNumber = await studentRepo.getNextRollNumber(
        sectionId: sectionId,
        academicYearId: academicYearId,
      );
      await studentRepo.enrollStudent(
        studentId: student.id,
        sectionId: sectionId,
        academicYearId: academicYearId,
        rollNumber: rollNumber.toString(),
      );

      // ── Step 4: Create parents rows if contacts exist ─────────────────────
      await _createParentLinks(
        parentRepo: parentRepo,
        studentId: student.id,
        parentInfo: app.parentInfo,
      );

      // ── Step 5: Mark application enrolled ────────────────────────────────
      await admissionRepo.updateApplicationStatus(
        app.id,
        status: ApplicationStatus.enrolled,
        statusNotes: 'Enrolled as student $admissionNumber.',
      );
      // Record the enrolled_student_id on the application row.
      await _client
          .from('admission_applications_v2')
          .update({'enrolled_student_id': student.id})
          .eq('id', app.id);

      return EnrollmentResult(
        student: student,
        email: email,
        password: password,
      );
    } catch (e) {
      // Rollback: remove orphaned auth user if it was created.
      if (createdUserId != null) {
        try {
          await adminService.deleteUser(createdUserId);
        } catch (_) {
          // Best-effort; ignore rollback failure.
        }
      }
      rethrow;
    }
  }

  Future<void> _createParentLinks({
    required ParentRepository parentRepo,
    required String studentId,
    required AdmissionParentInfo parentInfo,
  }) async {
    // Father
    if (parentInfo.fatherName != null &&
        parentInfo.fatherName!.trim().isNotEmpty) {
      try {
        final fatherParts =
            parentInfo.fatherName!.trim().split(RegExp(r'\s+'));
        final parent = await parentRepo.createParent(
          firstName: fatherParts.first,
          lastName:
              fatherParts.length > 1 ? fatherParts.sublist(1).join(' ') : '',
          relation: 'father',
          phone: parentInfo.fatherPhone,
          email: parentInfo.fatherEmail,
        );
        await parentRepo.linkParent(
          studentId: studentId,
          parentId: parent.id,
          relation: 'father',
          isPrimary: true,
          canPickup: true,
        );
      } catch (_) {
        // Non-fatal: student is created, parent link is best-effort.
      }
    }

    // Mother
    if (parentInfo.motherName != null &&
        parentInfo.motherName!.trim().isNotEmpty) {
      try {
        final motherParts =
            parentInfo.motherName!.trim().split(RegExp(r'\s+'));
        final parent = await parentRepo.createParent(
          firstName: motherParts.first,
          lastName:
              motherParts.length > 1 ? motherParts.sublist(1).join(' ') : '',
          relation: 'mother',
          phone: parentInfo.motherPhone,
          email: parentInfo.motherEmail,
        );
        await parentRepo.linkParent(
          studentId: studentId,
          parentId: parent.id,
          relation: 'mother',
          isPrimary: parentInfo.fatherName == null ||
              parentInfo.fatherName!.trim().isEmpty,
          canPickup: true,
        );
      } catch (_) {
        // Non-fatal.
      }
    }

    // Guardian
    if (parentInfo.guardianName != null &&
        parentInfo.guardianName!.trim().isNotEmpty) {
      try {
        final guardianParts =
            parentInfo.guardianName!.trim().split(RegExp(r'\s+'));
        final parent = await parentRepo.createParent(
          firstName: guardianParts.first,
          lastName: guardianParts.length > 1
              ? guardianParts.sublist(1).join(' ')
              : '',
          relation: 'guardian',
          phone: parentInfo.guardianPhone,
        );
        await parentRepo.linkParent(
          studentId: studentId,
          parentId: parent.id,
          relation: 'guardian',
          isPrimary: parentInfo.fatherName == null &&
              parentInfo.motherName == null,
          canPickup: true,
        );
      } catch (_) {
        // Non-fatal.
      }
    }
  }
}
