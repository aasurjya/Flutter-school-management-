
import '../models/academic.dart';
import 'base_repository.dart';

class AcademicRepository extends BaseRepository {
  AcademicRepository(super.client);

  Future<List<SchoolClass>> getClasses() async {
    final response = await client
        .from('classes')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .order('sequence_order');

    return (response as List)
        .map((json) => SchoolClass.fromJson(json))
        .toList();
  }

  Future<List<Section>> getSections({String? classId}) async {
    var query = client
        .from('sections')
        .select('''
          *,
          classes!inner(id, name),
          users!class_teacher_id(id, full_name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (classId != null) {
      query = query.eq('class_id', classId);
    }

    final response = await query.order('name');

    return (response as List).map((json) {
      if (json['classes'] != null) {
        json['class'] = json['classes'];
      }
      if (json['users'] != null) {
        json['class_teacher'] = json['users'];
      }
      return Section.fromJson(json);
    }).toList();
  }

  Future<AcademicYear?> getCurrentAcademicYear() async {
    final current = await client
        .from('academic_years')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .eq('is_current', true)
        .maybeSingle();

    if (current != null) {
      return AcademicYear.fromJson(current);
    }

    final latest = await client
        .from('academic_years')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .order('start_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (latest != null) {
      return AcademicYear.fromJson(latest);
    }

    return null;
  }

  Future<List<AcademicYear>> getAcademicYears() async {
    final response = await client
        .from('academic_years')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .order('start_date', ascending: false);

    return (response as List)
        .map((json) => AcademicYear.fromJson(json))
        .toList();
  }

  /// Assign a class teacher to a section.
  Future<void> assignClassTeacher({
    required String sectionId,
    required String teacherId,
  }) async {
    await client
        .from('sections')
        .update({'class_teacher_id': teacherId})
        .eq('id', sectionId);
  }

  /// Get sections where a teacher is assigned as class teacher.
  Future<List<Section>> getClassTeacherSections(String teacherId) async {
    final response = await client
        .from('sections')
        .select('''
          *,
          classes!inner(id, name),
          users!class_teacher_id(id, full_name)
        ''')
        .eq('tenant_id', requireTenantId)
        .eq('class_teacher_id', teacherId);

    return (response as List).map((json) {
      if (json['classes'] != null) {
        json['class'] = json['classes'];
      }
      if (json['users'] != null) {
        json['class_teacher'] = json['users'];
      }
      return Section.fromJson(json);
    }).toList();
  }

  /// Get all users with teacher role for the tenant.
  Future<List<Map<String, dynamic>>> getTeachersList() async {
    final response = await client
        .from('users')
        .select('''
          id, full_name, email,
          user_roles!inner(role)
        ''')
        .eq('user_roles.role', 'teacher');

    return List<Map<String, dynamic>>.from(response);
  }
}
