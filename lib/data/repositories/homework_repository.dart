import '../models/homework.dart';
import 'base_repository.dart';

class HomeworkRepository extends BaseRepository {
  HomeworkRepository(super.client);

  static const _homeworkSelect =
      '*, subjects(id, name), sections(id, name, classes(id, name)), users!assigned_by(id, full_name)';

  static const _submissionSelect =
      '*, students(id, full_name, roll_number)';

  // ============================================================
  // Homework CRUD
  // ============================================================

  Future<List<Homework>> getHomeworkList({
    String? sectionId,
    String? subjectId,
    HomeworkStatus? status,
    String? assignedBy,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('homework')
        .select(_homeworkSelect)
        .eq('tenant_id', requireTenantId);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }
    if (status != null) {
      query = query.eq('status', status.value);
    }
    if (assignedBy != null) {
      query = query.eq('assigned_by', assignedBy);
    }
    if (fromDate != null) {
      query = query.gte('due_date', fromDate.toIso8601String().split('T').first);
    }
    if (toDate != null) {
      query = query.lte('due_date', toDate.toIso8601String().split('T').first);
    }

    final response = await query
        .order('due_date', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => Homework.fromJson(json))
        .toList();
  }

  Future<Homework?> getHomeworkById(String id) async {
    final response = await client
        .from('homework')
        .select(_homeworkSelect)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Homework.fromJson(response);
  }

  Future<Homework> createHomework(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['assigned_by'] = requireUserId;

    final response = await client
        .from('homework')
        .insert(data)
        .select(_homeworkSelect)
        .single();

    return Homework.fromJson(response);
  }

  Future<Homework> updateHomework(String id, Map<String, dynamic> data) async {
    final response = await client
        .from('homework')
        .update(data)
        .eq('id', id)
        .select(_homeworkSelect)
        .single();

    return Homework.fromJson(response);
  }

  Future<void> deleteHomework(String id) async {
    await client.from('homework').delete().eq('id', id);
  }

  Future<Homework> publishHomework(String id) async {
    return updateHomework(id, {
      'status': HomeworkStatus.published.value,
    });
  }

  Future<Homework> closeHomework(String id) async {
    return updateHomework(id, {
      'status': HomeworkStatus.closed.value,
    });
  }

  // ============================================================
  // Student homework (for student portal)
  // ============================================================

  Future<List<Homework>> getStudentHomework({
    required String studentId,
    HomeworkStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    // First get student's enrolled sections
    final enrollments = await client
        .from('student_enrollments')
        .select('section_id')
        .eq('student_id', studentId)
        .eq('is_active', true);

    final sectionIds =
        (enrollments as List).map((e) => e['section_id'] as String).toList();
    if (sectionIds.isEmpty) return [];

    var query = client
        .from('homework')
        .select(_homeworkSelect)
        .eq('tenant_id', requireTenantId)
        .inFilter('section_id', sectionIds)
        .eq('status', HomeworkStatus.published.value);

    if (fromDate != null) {
      query = query.gte('due_date', fromDate.toIso8601String().split('T').first);
    }
    if (toDate != null) {
      query = query.lte('due_date', toDate.toIso8601String().split('T').first);
    }

    final response = await query
        .order('due_date', ascending: true)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => Homework.fromJson(json))
        .toList();
  }

  // ============================================================
  // Submissions
  // ============================================================

  Future<List<HomeworkSubmission>> getSubmissions(
    String homeworkId, {
    SubmissionStatus? status,
    int limit = 100,
    int offset = 0,
  }) async {
    var query = client
        .from('homework_submissions')
        .select(_submissionSelect)
        .eq('homework_id', homeworkId);

    if (status != null) {
      query = query.eq('status', status.value);
    }

    final response = await query
        .order('submitted_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => HomeworkSubmission.fromJson(json))
        .toList();
  }

  Future<HomeworkSubmission?> getStudentSubmission(
    String homeworkId,
    String studentId,
  ) async {
    final response = await client
        .from('homework_submissions')
        .select(_submissionSelect)
        .eq('homework_id', homeworkId)
        .eq('student_id', studentId)
        .maybeSingle();

    if (response == null) return null;
    return HomeworkSubmission.fromJson(response);
  }

  Future<HomeworkSubmission> submitHomework({
    required String homeworkId,
    required String studentId,
    String? content,
    List<String> attachmentUrls = const [],
  }) async {
    final now = DateTime.now();

    // Check if homework is overdue
    final homework = await getHomeworkById(homeworkId);
    final isLate = homework != null && now.isAfter(homework.dueDate);

    // Upsert: create or update submission
    final data = {
      'homework_id': homeworkId,
      'student_id': studentId,
      'content': content,
      'attachment_urls': attachmentUrls,
      'status': isLate ? SubmissionStatus.late_.value : SubmissionStatus.submitted.value,
      'submitted_at': now.toIso8601String(),
    };

    // Check existing
    final existing = await getStudentSubmission(homeworkId, studentId);
    if (existing != null) {
      final response = await client
          .from('homework_submissions')
          .update(data)
          .eq('id', existing.id)
          .select(_submissionSelect)
          .single();
      return HomeworkSubmission.fromJson(response);
    } else {
      final response = await client
          .from('homework_submissions')
          .insert(data)
          .select(_submissionSelect)
          .single();
      return HomeworkSubmission.fromJson(response);
    }
  }

  Future<HomeworkSubmission> gradeSubmission({
    required String submissionId,
    required int marks,
    String? feedback,
  }) async {
    final response = await client
        .from('homework_submissions')
        .update({
          'marks': marks,
          'feedback': feedback,
          'graded_by': requireUserId,
          'graded_at': DateTime.now().toIso8601String(),
          'status': SubmissionStatus.graded.value,
        })
        .eq('id', submissionId)
        .select(_submissionSelect)
        .single();

    return HomeworkSubmission.fromJson(response);
  }

  Future<HomeworkSubmission> returnSubmission({
    required String submissionId,
    String? feedback,
  }) async {
    final response = await client
        .from('homework_submissions')
        .update({
          'feedback': feedback,
          'status': SubmissionStatus.returned.value,
        })
        .eq('id', submissionId)
        .select(_submissionSelect)
        .single();

    return HomeworkSubmission.fromJson(response);
  }

  // ============================================================
  // Stats
  // ============================================================

  Future<HomeworkDashboardStats> getDashboardStats({String? sectionId}) async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T').first;

    var baseQuery = client
        .from('homework')
        .select('id, status, due_date')
        .eq('tenant_id', requireTenantId);

    if (sectionId != null) {
      baseQuery = baseQuery.eq('section_id', sectionId);
    }

    final allHomework = await baseQuery;
    final homeworkList = allHomework as List;

    final total = homeworkList.length;
    final active = homeworkList.where((h) => h['status'] == 'published').length;
    final overdue = homeworkList.where((h) =>
        h['status'] == 'published' &&
        (h['due_date'] as String).compareTo(todayStr) < 0).length;

    // Get submission counts
    final submissionCounts = await client
        .from('homework_submissions')
        .select('status')
        .inFilter(
          'homework_id',
          homeworkList.map((h) => h['id'] as String).toList(),
        );

    final submissions = submissionCounts as List;
    final pending = submissions.where((s) =>
        s['status'] == 'pending' || s['status'] == 'submitted' || s['status'] == 'late').length;
    final graded = submissions.where((s) => s['status'] == 'graded').length;

    return HomeworkDashboardStats(
      totalHomework: total,
      activeHomework: active,
      overdueHomework: overdue,
      pendingSubmissions: pending,
      gradedSubmissions: graded,
      averageSubmissionRate: total > 0 ? (graded / (total > 0 ? total : 1)) * 100 : 0,
    );
  }

  // ============================================================
  // Homework by date range (for calendar view)
  // ============================================================

  Future<Map<DateTime, List<Homework>>> getHomeworkByDateRange({
    required DateTime start,
    required DateTime end,
    String? sectionId,
  }) async {
    var query = client
        .from('homework')
        .select(_homeworkSelect)
        .eq('tenant_id', requireTenantId)
        .gte('due_date', start.toIso8601String().split('T').first)
        .lte('due_date', end.toIso8601String().split('T').first);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }

    final response = await query.order('due_date');
    final homeworkList = (response as List)
        .map((json) => Homework.fromJson(json))
        .toList();

    final Map<DateTime, List<Homework>> grouped = {};
    for (final hw in homeworkList) {
      final dateKey = DateTime(hw.dueDate.year, hw.dueDate.month, hw.dueDate.day);
      grouped.putIfAbsent(dateKey, () => []).add(hw);
    }
    return grouped;
  }
}
