import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_statistics.dart';
import 'base_repository.dart';

class ExamRepository extends BaseRepository {
  ExamRepository(super.client);

  Future<List<Exam>> getExams({
    String? academicYearId,
    String? termId,
    bool publishedOnly = false,
  }) async {
    var query = client
        .from('exams')
        .select('''
          *,
          terms(id, name),
          academic_years(id, name)
        ''')
        .eq('tenant_id', tenantId!);

    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }
    if (termId != null) {
      query = query.eq('term_id', termId);
    }
    if (publishedOnly) {
      query = query.eq('is_published', true);
    }

    final response = await query.order('start_date', ascending: false);
    return (response as List).map((json) => Exam.fromJson(json)).toList();
  }

  Future<Exam?> getExamById(String examId) async {
    final response = await client
        .from('exams')
        .select('''
          *,
          terms(id, name),
          academic_years(id, name),
          exam_subjects(
            *,
            subjects(id, name, code),
            classes(id, name)
          )
        ''')
        .eq('id', examId)
        .single();

    return Exam.fromJson(response);
  }

  Future<Exam> createExam(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('exams')
        .insert(data)
        .select()
        .single();

    return Exam.fromJson(response);
  }

  Future<Exam> updateExam(String examId, Map<String, dynamic> data) async {
    final response = await client
        .from('exams')
        .update(data)
        .eq('id', examId)
        .select()
        .single();

    return Exam.fromJson(response);
  }

  Future<void> publishExam(String examId) async {
    await client
        .from('exams')
        .update({'is_published': true})
        .eq('id', examId);
  }

  Future<List<ExamSubject>> getExamSubjects(String examId) async {
    final response = await client
        .from('exam_subjects')
        .select('''
          *,
          subjects(id, name, code),
          classes(id, name)
        ''')
        .eq('exam_id', examId)
        .order('exam_date');

    return (response as List).map((json) => ExamSubject.fromJson(json)).toList();
  }

  Future<ExamSubject> createExamSubject(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('exam_subjects')
        .insert(data)
        .select()
        .single();

    return ExamSubject.fromJson(response);
  }

  Future<List<Mark>> getMarks({
    required String examSubjectId,
    String? studentId,
  }) async {
    var query = client
        .from('marks')
        .select('''
          *,
          students(id, first_name, last_name, admission_number),
          exam_subjects(id, max_marks, passing_marks, subjects(id, name))
        ''')
        .eq('exam_subject_id', examSubjectId);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    final response = await query;
    return (response as List).map((json) => Mark.fromJson(json)).toList();
  }

  Future<void> enterMark({
    required String examSubjectId,
    required String studentId,
    double? marksObtained,
    bool isAbsent = false,
    String? remarks,
  }) async {
    await client.from('marks').upsert({
      'tenant_id': tenantId,
      'exam_subject_id': examSubjectId,
      'student_id': studentId,
      'marks_obtained': marksObtained,
      'is_absent': isAbsent,
      'remarks': remarks,
      'entered_by': currentUserId,
      'entered_at': DateTime.now().toIso8601String(),
    }, onConflict: 'exam_subject_id,student_id');
  }

  Future<void> enterBulkMarks(List<Map<String, dynamic>> marks) async {
    final records = marks.map((m) => {
      ...m,
      'tenant_id': tenantId,
      'entered_by': currentUserId,
      'entered_at': DateTime.now().toIso8601String(),
    }).toList();

    await client.from('marks').upsert(
      records,
      onConflict: 'exam_subject_id,student_id',
    );
  }

  Future<List<StudentPerformance>> getStudentPerformance({
    required String studentId,
    String? examId,
    String? subjectId,
  }) async {
    var query = client
        .from('mv_student_performance')
        .select('*')
        .eq('student_id', studentId);

    if (examId != null) {
      query = query.eq('exam_id', examId);
    }
    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }

    final response = await query;
    return (response as List)
        .map((json) => StudentPerformance.fromJson(json))
        .toList();
  }

  Future<List<StudentRank>> getStudentRanks({
    required String studentId,
    String? examId,
  }) async {
    var query = client
        .from('v_student_ranks')
        .select('*')
        .eq('student_id', studentId);

    if (examId != null) {
      query = query.eq('exam_id', examId);
    }

    final response = await query;
    return (response as List).map((json) => StudentRank.fromJson(json)).toList();
  }

  Future<StudentOverallRank?> getStudentOverallRank({
    required String studentId,
    required String examId,
  }) async {
    final response = await client
        .from('v_student_overall_ranks')
        .select('*')
        .eq('student_id', studentId)
        .eq('exam_id', examId)
        .maybeSingle();

    if (response == null) return null;
    return StudentOverallRank.fromJson(response);
  }

  Future<List<ClassExamStats>> getClassExamStats({
    required String examId,
    String? sectionId,
    String? subjectId,
  }) async {
    var query = client
        .from('v_class_exam_stats')
        .select('*')
        .eq('exam_id', examId);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }

    final response = await query;
    return (response as List)
        .map((json) => ClassExamStats.fromJson(json))
        .toList();
  }

  Future<List<GradeScale>> getGradeScales() async {
    final response = await client
        .from('grade_scales')
        .select('''
          *,
          grade_scale_items(*)
        ''')
        .eq('tenant_id', tenantId!)
        .order('name');

    return (response as List).map((json) => GradeScale.fromJson(json)).toList();
  }

  Future<void> refreshAnalytics() async {
    await client.rpc('refresh_analytics');
  }

  Future<List<StudentOverallRank>> getExamToppers({
    required String examId,
    String? sectionId,
    int limit = 10,
  }) async {
    var query = client
        .from('v_student_overall_ranks')
        .select('*')
        .eq('exam_id', examId);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }

    final response = await query
        .order('class_rank')
        .limit(limit);

    return (response as List)
        .map((json) => StudentOverallRank.fromJson(json))
        .toList();
  }
}
