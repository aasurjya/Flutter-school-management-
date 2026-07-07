import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/data/models/student.dart';

void main() {
  group('StudentEnrollment.fromJson', () {
    test('partial embed missing tenant_id/student_id/enrollment_date/created_at does not throw', () {
      // Shape returned by the partial embeds in student_repository.dart
      // (getStudentByUserId and friends) that only select a subset of
      // columns — this used to crash the student dashboard.
      final json = {
        'id': 'enroll-1',
        'section_id': 'section-1',
        'academic_year_id': 'year-1',
        'roll_number': '6',
        'status': 'active',
        'sections': {
          'id': 'section-1',
          'name': 'A',
          'classes': {'id': 'class-1', 'name': 'Class 10'},
        },
        'academic_years': {'id': 'year-1', 'name': '2024-25', 'is_current': true},
      };

      final enrollment = StudentEnrollment.fromJson(json);

      expect(enrollment.id, 'enroll-1');
      expect(enrollment.tenantId, '');
      expect(enrollment.studentId, '');
      expect(enrollment.enrollmentDate, isA<DateTime>());
      expect(enrollment.createdAt, isA<DateTime>());
      expect(enrollment.sectionName, 'A');
      expect(enrollment.className, 'Class 10');
      expect(enrollment.academicYearName, '2024-25');
    });

    test('full embed with all columns populates every field', () {
      final json = {
        'id': 'enroll-2',
        'tenant_id': 'tenant-1',
        'student_id': 'student-1',
        'section_id': 'section-1',
        'academic_year_id': 'year-1',
        'roll_number': '1',
        'status': 'active',
        'enrollment_date': '2024-04-01',
        'created_at': '2024-04-01T00:00:00.000Z',
        'sections': {
          'id': 'section-1',
          'name': 'A',
          'classes': {'id': 'class-1', 'name': 'Class 10'},
        },
        'academic_years': {'id': 'year-1', 'name': '2024-25', 'is_current': true},
      };

      final enrollment = StudentEnrollment.fromJson(json);

      expect(enrollment.tenantId, 'tenant-1');
      expect(enrollment.studentId, 'student-1');
      expect(enrollment.enrollmentDate, DateTime.parse('2024-04-01'));
      expect(enrollment.createdAt, DateTime.parse('2024-04-01T00:00:00.000Z'));
    });

    test('falls back to singular section/class embed keys', () {
      final json = {
        'id': 'enroll-3',
        'section_id': 'section-1',
        'academic_year_id': 'year-1',
        'status': 'active',
        'section': {
          'name': 'B',
          'class': {'name': 'Class 9'},
        },
        'academic_year': {'name': '2023-24'},
      };

      final enrollment = StudentEnrollment.fromJson(json);

      expect(enrollment.sectionName, 'B');
      expect(enrollment.className, 'Class 9');
      expect(enrollment.academicYearName, '2023-24');
    });

    test('null enrollment_date with valid created_at does not throw', () {
      final json = {
        'id': 'enroll-4',
        'section_id': 'section-1',
        'academic_year_id': 'year-1',
        'status': 'active',
        'enrollment_date': null,
        'created_at': '2024-04-01T00:00:00.000Z',
      };

      final enrollment = StudentEnrollment.fromJson(json);

      expect(enrollment.enrollmentDate, isA<DateTime>());
      expect(enrollment.createdAt, DateTime.parse('2024-04-01T00:00:00.000Z'));
    });

    test('empty map constructs with all-empty/now() defaults, no throw', () {
      final enrollment = StudentEnrollment.fromJson({});

      expect(enrollment.id, '');
      expect(enrollment.tenantId, '');
      expect(enrollment.studentId, '');
      expect(enrollment.sectionId, '');
      expect(enrollment.academicYearId, '');
      expect(enrollment.status, 'active');
      expect(enrollment.enrollmentDate, isA<DateTime>());
      expect(enrollment.createdAt, isA<DateTime>());
      expect(enrollment.className, isNull);
      expect(enrollment.sectionName, isNull);
    });
  });
}
