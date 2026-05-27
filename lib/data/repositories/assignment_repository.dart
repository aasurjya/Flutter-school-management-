import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assignment.dart';
import 'base_repository.dart';

class AssignmentRepository extends BaseRepository {
  AssignmentRepository(super.client);

  // Null-safe snake_case row mappers — the Freezed generated fromJson reads
  // camelCase keys that don't match Supabase's snake_case columns and can't
  // read nested joins.
  static String _str(Object? v) => (v as String?) ?? '';
  static double? _dblN(Object? v) => (v as num?)?.toDouble();
  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;
  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
  static List<Map<String, dynamic>> _attach(Object? v) =>
      (v as List?)
          ?.whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList() ??
      const [];

  Assignment _assignmentFromRow(Map<String, dynamic> j) {
    final section = j['sections'] as Map<String, dynamic>?;
    final cls = section?['classes'] as Map<String, dynamic>?;
    final subject = j['subjects'] as Map<String, dynamic>?;
    final teacher = j['users'] as Map<String, dynamic>?;
    return Assignment(
      id: _str(j['id']),
      tenantId: _str(j['tenant_id']),
      sectionId: _str(j['section_id']),
      subjectId: _str(j['subject_id']),
      teacherId: _str(j['teacher_id']),
      title: _str(j['title']),
      description: j['description'] as String?,
      instructions: j['instructions'] as String?,
      dueDate: _date(j['due_date']) ?? DateTime.now(),
      maxMarks: _dblN(j['max_marks']),
      attachments: _attach(j['attachments']),
      status: (j['status'] as String?) ?? 'draft',
      allowLateSubmission: j['allow_late_submission'] as bool? ?? false,
      topicId: j['topic_id'] as String?,
      createdAt: _date(j['created_at']),
      updatedAt: _date(j['updated_at']),
      sectionName: section?['name'] as String?,
      className: cls?['name'] as String?,
      subjectName: subject?['name'] as String?,
      subjectCode: subject?['code'] as String?,
      teacherName: teacher?['full_name'] as String?,
      totalStudents: (j['total_students'] as num?)?.toInt(),
      submittedCount: (j['submitted_count'] as num?)?.toInt(),
      gradedCount: (j['graded_count'] as num?)?.toInt(),
      lateCount: (j['late_count'] as num?)?.toInt(),
    );
  }

  Submission _submissionFromRow(Map<String, dynamic> j) {
    final student = j['students'] as Map<String, dynamic>?;
    final gradedByUser = j['users'] as Map<String, dynamic>?;
    final assignment = j['assignments'] as Map<String, dynamic>?;
    String? studentName;
    if (student != null) {
      final full =
          '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
      studentName = full.isEmpty ? null : full;
    }
    return Submission(
      id: _str(j['id']),
      tenantId: _str(j['tenant_id']),
      assignmentId: _str(j['assignment_id']),
      studentId: _str(j['student_id']),
      content: j['content'] as String?,
      attachments: _attach(j['attachments']),
      submittedAt: _date(j['submitted_at']),
      status: (j['status'] as String?) ?? 'pending',
      marksObtained: _dblN(j['marks_obtained']),
      feedback: j['feedback'] as String?,
      gradedBy: j['graded_by'] as String?,
      gradedAt: _date(j['graded_at']),
      createdAt: _date(j['created_at']),
      updatedAt: _date(j['updated_at']),
      studentName: studentName,
      admissionNumber: student?['admission_number'] as String?,
      assignmentTitle: assignment?['title'] as String?,
      maxMarks: _dblN(assignment?['max_marks']),
      dueDate: _date(assignment?['due_date']),
      gradedByName: gradedByUser?['full_name'] as String?,
    );
  }

  AssignmentSummary _assignmentSummaryFromRow(Map<String, dynamic> j) =>
      AssignmentSummary(
        tenantId: _str(j['tenant_id']),
        assignmentId: _str(j['assignment_id']),
        title: _str(j['title']),
        sectionId: _str(j['section_id']),
        sectionName: _str(j['section_name']),
        className: _str(j['class_name']),
        subjectId: _str(j['subject_id']),
        subjectName: _str(j['subject_name']),
        teacherId: _str(j['teacher_id']),
        teacherName: _str(j['teacher_name']),
        dueDate: _date(j['due_date']) ?? DateTime.now(),
        maxMarks: _dblN(j['max_marks']),
        status: (j['status'] as String?) ?? 'draft',
        totalStudents: _int(j['total_students']),
        submittedCount: _int(j['submitted_count']),
        gradedCount: _int(j['graded_count']),
        lateCount: _int(j['late_count']),
        isPastDue: j['is_past_due'] as bool? ?? false,
      );

  Future<List<Assignment>> getAssignments({
    String? sectionId,
    String? subjectId,
    String? teacherId,
    String? status,
    bool upcomingOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('assignments')
        .select('''
          *,
          sections(id, name, classes(id, name)),
          subjects(id, name, code),
          users!teacher_id(id, full_name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }
    if (teacherId != null) {
      query = query.eq('teacher_id', teacherId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (upcomingOnly) {
      query = query.gte('due_date', DateTime.now().toIso8601String());
    }

    final response = await query.order('due_date', ascending: false).range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => _assignmentFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Assignment>> getStudentAssignments({
    required String sectionId,
    bool pendingOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('assignments')
        .select('''
          *,
          sections(id, name, classes(id, name)),
          subjects(id, name, code),
          users!teacher_id(id, full_name)
        ''')
        .eq('section_id', sectionId)
        .eq('status', 'published');

    if (pendingOnly) {
      query = query.gte('due_date', DateTime.now().toIso8601String());
    }

    final response = await query.order('due_date').range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => _assignmentFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<Assignment?> getAssignmentById(String assignmentId) async {
    final response = await client
        .from('assignments')
        .select('''
          *,
          sections(id, name, classes(id, name)),
          subjects(id, name, code),
          users!teacher_id(id, full_name)
        ''')
        .eq('id', assignmentId)
        .single();

    return _assignmentFromRow(response);
  }

  Future<Assignment> createAssignment(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['teacher_id'] = currentUserId;

    final response = await client
        .from('assignments')
        .insert(data)
        .select()
        .single();

    return _assignmentFromRow(response);
  }

  Future<Assignment> updateAssignment(
    String assignmentId,
    Map<String, dynamic> data,
  ) async {
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await client
        .from('assignments')
        .update(data)
        .eq('id', assignmentId)
        .select()
        .single();

    return _assignmentFromRow(response);
  }

  Future<void> publishAssignment(String assignmentId) async {
    await client
        .from('assignments')
        .update({
          'status': 'published',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', assignmentId);
  }

  Future<void> closeAssignment(String assignmentId) async {
    await client
        .from('assignments')
        .update({
          'status': 'closed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', assignmentId);
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await client.from('assignments').delete().eq('id', assignmentId);
  }

  Future<List<Submission>> getSubmissions({
    required String assignmentId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('submissions')
        .select('''
          *,
          students(id, first_name, last_name, admission_number, photo_url),
          users!graded_by(id, full_name)
        ''')
        .eq('assignment_id', assignmentId);

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('submitted_at', ascending: false).range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => _submissionFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<Submission?> getStudentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    final response = await client
        .from('submissions')
        .select('''
          *,
          assignments(id, title, max_marks, due_date)
        ''')
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentId)
        .maybeSingle();

    if (response == null) return null;
    return _submissionFromRow(response);
  }

  Future<Submission> submitAssignment({
    required String assignmentId,
    required String studentId,
    String? content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final assignment = await getAssignmentById(assignmentId);
    final isLate = assignment != null && DateTime.now().isAfter(assignment.dueDate);

    final response = await client.from('submissions').upsert({
      'tenant_id': tenantId,
      'assignment_id': assignmentId,
      'student_id': studentId,
      'content': content,
      'attachments': attachments ?? [],
      'submitted_at': DateTime.now().toIso8601String(),
      'status': isLate ? 'late' : 'submitted',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'assignment_id,student_id').select().single();

    return _submissionFromRow(response);
  }

  Future<Submission> gradeSubmission({
    required String submissionId,
    required double marksObtained,
    String? feedback,
  }) async {
    final response = await client
        .from('submissions')
        .update({
          'marks_obtained': marksObtained,
          'feedback': feedback,
          'graded_by': currentUserId,
          'graded_at': DateTime.now().toIso8601String(),
          'status': 'graded',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', submissionId)
        .select()
        .single();

    return _submissionFromRow(response);
  }

  Future<Submission> returnSubmission({
    required String submissionId,
    String? feedback,
  }) async {
    final response = await client
        .from('submissions')
        .update({
          'feedback': feedback,
          'status': 'returned',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', submissionId)
        .select()
        .single();

    return _submissionFromRow(response);
  }

  Future<List<AssignmentSummary>> getAssignmentSummaries({
    String? sectionId,
    String? teacherId,
  }) async {
    var query = client
        .from('v_assignment_summary')
        .select('*')
        .eq('tenant_id', requireTenantId);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (teacherId != null) {
      query = query.eq('teacher_id', teacherId);
    }

    final response = await query.order('due_date', ascending: false);
    return (response as List)
        .map((json) => _assignmentSummaryFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Assignment>> getAssignmentsByTopic(String topicId) async {
    final response = await client
        .from('assignments')
        .select('''
          *,
          sections(id, name, classes(id, name)),
          subjects(id, name, code),
          users!teacher_id(id, full_name)
        ''')
        .eq('topic_id', topicId)
        .order('due_date', ascending: false);

    return (response as List)
        .map((json) => _assignmentFromRow(json as Map<String, dynamic>))
        .toList();
  }

  RealtimeChannel subscribeToAssignments({
    required String sectionId,
    required void Function(PostgresChangePayload) onUpdate,
  }) {
    return subscribeToTable(
      'assignments',
      filter: (column: 'section_id', value: sectionId),
      onInsert: onUpdate,
      onUpdate: onUpdate,
    );
  }
}
