import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assignment.dart';
import 'base_repository.dart';

class AssignmentRepository extends BaseRepository {
  AssignmentRepository(super.client);

  Future<List<Assignment>> getAssignments({
    String? sectionId,
    String? subjectId,
    String? teacherId,
    String? status,
    bool upcomingOnly = false,
  }) async {
    var query = client
        .from('assignments')
        .select('''
          *,
          sections(id, name, classes(id, name)),
          subjects(id, name, code),
          users!teacher_id(id, full_name)
        ''')
        .eq('tenant_id', tenantId!);

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

    final response = await query.order('due_date', ascending: false);
    return (response as List).map((json) => Assignment.fromJson(json)).toList();
  }

  Future<List<Assignment>> getStudentAssignments({
    required String sectionId,
    bool pendingOnly = false,
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

    final response = await query.order('due_date');
    return (response as List).map((json) => Assignment.fromJson(json)).toList();
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

    return Assignment.fromJson(response);
  }

  Future<Assignment> createAssignment(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['teacher_id'] = currentUserId;

    final response = await client
        .from('assignments')
        .insert(data)
        .select()
        .single();

    return Assignment.fromJson(response);
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

    return Assignment.fromJson(response);
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

    final response = await query.order('submitted_at', ascending: false);
    return (response as List).map((json) => Submission.fromJson(json)).toList();
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
    return Submission.fromJson(response);
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

    return Submission.fromJson(response);
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

    return Submission.fromJson(response);
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

    return Submission.fromJson(response);
  }

  Future<List<AssignmentSummary>> getAssignmentSummaries({
    String? sectionId,
    String? teacherId,
  }) async {
    var query = client
        .from('v_assignment_summary')
        .select('*')
        .eq('tenant_id', tenantId!);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (teacherId != null) {
      query = query.eq('teacher_id', teacherId);
    }

    final response = await query.order('due_date', ascending: false);
    return (response as List)
        .map((json) => AssignmentSummary.fromJson(json))
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
