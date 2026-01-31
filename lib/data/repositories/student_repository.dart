import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';
import 'base_repository.dart';

class StudentRepository extends BaseRepository {
  StudentRepository(super.client);

  Future<List<Student>> getStudents({
    String? sectionId,
    String? classId,
    String? searchQuery,
    bool activeOnly = true,
  }) async {
    var query = client
        .from('students')
        .select('''
          *,
          student_enrollments!inner(
            id,
            section_id,
            academic_year_id,
            roll_number,
            status,
            sections!inner(
              id,
              name,
              classes!inner(id, name)
            ),
            academic_years!inner(id, name, is_current)
          )
        ''')
        .eq('tenant_id', tenantId!)
        .eq('student_enrollments.academic_years.is_current', true);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    if (sectionId != null) {
      query = query.eq('student_enrollments.section_id', sectionId);
    }

    if (classId != null) {
      query = query.eq('student_enrollments.sections.class_id', classId);
    }

    final response = await query.order('first_name');

    return (response as List).map((json) => Student.fromJson(json)).toList();
  }

  Future<Student?> getStudentById(String studentId) async {
    final response = await client
        .from('students')
        .select('''
          *,
          student_enrollments(
            id,
            section_id,
            academic_year_id,
            roll_number,
            status,
            sections(id, name, classes(id, name)),
            academic_years(id, name, is_current)
          ),
          student_parents(
            id,
            is_primary,
            parents(*)
          )
        ''')
        .eq('id', studentId)
        .single();

    return Student.fromJson(response);
  }

  Future<Student?> getStudentByUserId(String userId) async {
    final response = await client
        .from('students')
        .select('''
          *,
          student_enrollments(
            id,
            section_id,
            academic_year_id,
            roll_number,
            status,
            sections(id, name, classes(id, name)),
            academic_years(id, name, is_current)
          )
        ''')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Student.fromJson(response);
  }

  Future<List<Student>> getStudentsBySection(String sectionId) async {
    final response = await client
        .from('students')
        .select('''
          *,
          student_enrollments!inner(
            id,
            section_id,
            roll_number,
            status,
            academic_years!inner(is_current)
          )
        ''')
        .eq('tenant_id', tenantId!)
        .eq('student_enrollments.section_id', sectionId)
        .eq('student_enrollments.academic_years.is_current', true)
        .eq('student_enrollments.status', 'active')
        .eq('is_active', true)
        .order('first_name');

    return (response as List).map((json) => Student.fromJson(json)).toList();
  }

  Future<Student> createStudent(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    
    final response = await client
        .from('students')
        .insert(data)
        .select()
        .single();

    return Student.fromJson(response);
  }

  Future<Student> updateStudent(String studentId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    
    final response = await client
        .from('students')
        .update(data)
        .eq('id', studentId)
        .select()
        .single();

    return Student.fromJson(response);
  }

  Future<int> getNextRollNumber({
    required String sectionId,
    required String academicYearId,
  }) async {
    final response = await client
        .from('student_enrollments')
        .select('roll_number')
        .eq('section_id', sectionId)
        .eq('academic_year_id', academicYearId)
        .order('roll_number', ascending: false)
        .limit(1);

    if (response is List && response.isNotEmpty) {
      final latest = response.first['roll_number'];
      final latestInt = latest is int
          ? latest
          : int.tryParse(latest?.toString() ?? '') ?? 0;
      return latestInt + 1;
    }

    return 1;
  }

  Future<void> enrollStudent({
    required String studentId,
    required String sectionId,
    required String academicYearId,
    String? rollNumber,
  }) async {
    await client.from('student_enrollments').insert({
      'tenant_id': tenantId,
      'student_id': studentId,
      'section_id': sectionId,
      'academic_year_id': academicYearId,
      'roll_number': rollNumber,
      'status': 'active',
    });
  }

  Future<void> changeSection({
    required String studentId,
    required String newSectionId,
    required String academicYearId,
  }) async {
    await client
        .from('student_enrollments')
        .update({'section_id': newSectionId})
        .eq('student_id', studentId)
        .eq('academic_year_id', academicYearId);
  }

  Future<void> deactivateStudent(String studentId) async {
    await client
        .from('students')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', studentId);
  }

  Future<List<Map<String, dynamic>>> getParentChildren(String userId) async {
    final response = await client.rpc('get_parent_children', params: {
      'p_user_id': userId,
    });
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getStudentCurrentEnrollment(String studentId) async {
    final response = await client.rpc('get_student_current_enrollment', params: {
      'p_student_id': studentId,
    });
    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return null;
  }

  Future<int> getStudentCount({String? sectionId, String? classId}) async {
    try {
      var query = client
          .from('students')
          .select('id')
          .eq('tenant_id', tenantId!)
          .eq('is_active', true);

      final response = await query;
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
