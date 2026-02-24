import '../models/student_checkin.dart';
import 'base_repository.dart';

class CheckinRepository extends BaseRepository {
  CheckinRepository(super.client);

  /// Record a student check-in or check-out.
  Future<StudentCheckin> recordCheckin({
    required String studentId,
    required String sectionId,
    required CheckType checkType,
    String method = 'qr_scan',
    String? notes,
  }) async {
    final response = await client
        .from('student_checkins')
        .insert({
          'tenant_id': tenantId,
          'student_id': studentId,
          'section_id': sectionId,
          'check_type': checkType.dbValue,
          'checked_at': DateTime.now().toIso8601String(),
          'checked_by': currentUserId,
          'method': method,
          'notes': notes,
        })
        .select('''
          *,
          students(id, first_name, last_name, photo_url),
          users(full_name)
        ''')
        .single();

    return StudentCheckin.fromJson(response);
  }

  /// Get check-in history for a student.
  Future<List<StudentCheckin>> getStudentCheckins({
    required String studentId,
    DateTime? date,
  }) async {
    var query = client
        .from('student_checkins')
        .select('''
          *,
          students(id, first_name, last_name, photo_url),
          users(full_name)
        ''')
        .eq('student_id', studentId);

    if (date != null) {
      final dateStr = date.toIso8601String().split('T')[0];
      query = query
          .gte('checked_at', '${dateStr}T00:00:00')
          .lte('checked_at', '${dateStr}T23:59:59');
    }

    final response = await query.order('checked_at', ascending: false);
    return (response as List)
        .map((json) => StudentCheckin.fromJson(json))
        .toList();
  }

  /// Get all check-ins for a section on a given date.
  Future<List<StudentCheckin>> getSectionCheckins({
    required String sectionId,
    DateTime? date,
  }) async {
    var query = client
        .from('student_checkins')
        .select('''
          *,
          students(id, first_name, last_name, photo_url),
          users(full_name)
        ''')
        .eq('section_id', sectionId);

    if (date != null) {
      final dateStr = date.toIso8601String().split('T')[0];
      query = query
          .gte('checked_at', '${dateStr}T00:00:00')
          .lte('checked_at', '${dateStr}T23:59:59');
    }

    final response = await query.order('checked_at', ascending: false);
    return (response as List)
        .map((json) => StudentCheckin.fromJson(json))
        .toList();
  }
}
