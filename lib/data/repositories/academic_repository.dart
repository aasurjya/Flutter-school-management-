
import '../models/academic.dart';
import 'base_repository.dart';

class AcademicRepository extends BaseRepository {
  AcademicRepository(super.client);

  // ─── Classes ─────────────────────────────────────────────────────────────────

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

  Future<SchoolClass> createClass({
    required String name,
    required int sequenceOrder,
    int? numericName,
    String? description,
  }) async {
    final response = await client.from('classes').insert({
      'tenant_id': requireTenantId,
      'name': name,
      'sequence_order': sequenceOrder,
      'numeric_name': numericName,
      'description': description,
    }).select().single();

    return SchoolClass.fromJson(response);
  }

  Future<SchoolClass> updateClass(
    String classId, {
    String? name,
    int? sequenceOrder,
    int? numericName,
    String? description,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (sequenceOrder != null) data['sequence_order'] = sequenceOrder;
    if (numericName != null) data['numeric_name'] = numericName;
    if (description != null) data['description'] = description;

    final response = await client
        .from('classes')
        .update(data)
        .eq('id', classId)
        .eq('tenant_id', requireTenantId)
        .select()
        .single();

    return SchoolClass.fromJson(response);
  }

  Future<void> deleteClass(String classId) async {
    await client
        .from('classes')
        .delete()
        .eq('id', classId)
        .eq('tenant_id', requireTenantId);
  }

  // ─── Sections ────────────────────────────────────────────────────────────────

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

  Future<Section> createSection({
    required String classId,
    required String academicYearId,
    required String name,
    int capacity = 40,
    String? roomNumber,
  }) async {
    final response = await client.from('sections').insert({
      'tenant_id': requireTenantId,
      'class_id': classId,
      'academic_year_id': academicYearId,
      'name': name,
      'capacity': capacity,
      'room_number': roomNumber,
    }).select().single();

    return Section.fromJson(response);
  }

  Future<void> updateSection(
    String sectionId, {
    String? name,
    int? capacity,
    String? roomNumber,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (capacity != null) data['capacity'] = capacity;
    if (roomNumber != null) data['room_number'] = roomNumber;

    await client
        .from('sections')
        .update(data)
        .eq('id', sectionId)
        .eq('tenant_id', requireTenantId);
  }

  Future<void> deleteSection(String sectionId) async {
    await client
        .from('sections')
        .delete()
        .eq('id', sectionId)
        .eq('tenant_id', requireTenantId);
  }

  // ─── Academic Years ──────────────────────────────────────────────────────────

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

  Future<AcademicYear> createAcademicYear({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool isCurrent = false,
  }) async {
    // If setting as current, unset all others first
    if (isCurrent) {
      await client
          .from('academic_years')
          .update({'is_current': false})
          .eq('tenant_id', requireTenantId);
    }

    final response = await client.from('academic_years').insert({
      'tenant_id': requireTenantId,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_current': isCurrent,
    }).select().single();

    return AcademicYear.fromJson(response);
  }

  Future<void> setCurrentAcademicYear(String yearId) async {
    // Unset all
    await client
        .from('academic_years')
        .update({'is_current': false})
        .eq('tenant_id', requireTenantId);

    // Set the chosen one
    await client
        .from('academic_years')
        .update({'is_current': true})
        .eq('id', yearId)
        .eq('tenant_id', requireTenantId);
  }

  Future<void> deleteAcademicYear(String yearId) async {
    await client
        .from('academic_years')
        .delete()
        .eq('id', yearId)
        .eq('tenant_id', requireTenantId);
  }

  // ─── Terms ───────────────────────────────────────────────────────────────────

  Future<List<Term>> getTerms(String academicYearId) async {
    final response = await client
        .from('terms')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .eq('academic_year_id', academicYearId)
        .order('sequence_order');

    return (response as List)
        .map((json) => Term.fromJson(json))
        .toList();
  }

  Future<Term> createTerm({
    required String academicYearId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required int sequenceOrder,
  }) async {
    final response = await client.from('terms').insert({
      'tenant_id': requireTenantId,
      'academic_year_id': academicYearId,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'sequence_order': sequenceOrder,
    }).select().single();

    return Term.fromJson(response);
  }

  Future<void> deleteTerm(String termId) async {
    await client
        .from('terms')
        .delete()
        .eq('id', termId)
        .eq('tenant_id', requireTenantId);
  }

  // ─── Subjects ────────────────────────────────────────────────────────────────

  Future<List<Subject>> getSubjects() async {
    final response = await client
        .from('subjects')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .order('name');

    return (response as List)
        .map((json) => Subject.fromJson(json))
        .toList();
  }

  Future<Subject> createSubject({
    required String name,
    String? code,
    String subjectType = 'mandatory',
    String? description,
  }) async {
    final response = await client.from('subjects').insert({
      'tenant_id': requireTenantId,
      'name': name,
      'code': code,
      'subject_type': subjectType,
      'description': description,
    }).select().single();

    return Subject.fromJson(response);
  }

  Future<void> updateSubject(
    String subjectId, {
    String? name,
    String? code,
    String? subjectType,
    String? description,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (code != null) data['code'] = code;
    if (subjectType != null) data['subject_type'] = subjectType;
    if (description != null) data['description'] = description;

    await client
        .from('subjects')
        .update(data)
        .eq('id', subjectId)
        .eq('tenant_id', requireTenantId);
  }

  Future<void> deleteSubject(String subjectId) async {
    await client
        .from('subjects')
        .delete()
        .eq('id', subjectId)
        .eq('tenant_id', requireTenantId);
  }

  // ─── Teacher Assignment ──────────────────────────────────────────────────────

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
