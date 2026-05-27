import '../models/exam_statistics.dart';
import 'base_repository.dart';

class ExamRepository extends BaseRepository {
  ExamRepository(super.client);

  // Null-safe snake_case row mappers — the Freezed generated fromJson reads
  // camelCase keys that don't match Supabase's snake_case columns / views and
  // can't read nested joins.
  static String _s(Object? v) => (v as String?) ?? '';
  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
  static double? _dN(Object? v) => (v as num?)?.toDouble();
  static int _i(Object? v) => (v as num?)?.toInt() ?? 0;
  static bool _b(Object? v) => v as bool? ?? false;
  static DateTime? _dt(Object? v) => v is String ? DateTime.tryParse(v) : null;

  Exam _examFromRow(Map<String, dynamic> j) {
    final term = j['terms'] as Map<String, dynamic>?;
    final year = j['academic_years'] as Map<String, dynamic>?;
    return Exam(
      id: _s(j['id']),
      tenantId: _s(j['tenant_id']),
      academicYearId: _s(j['academic_year_id']),
      termId: j['term_id'] as String?,
      name: _s(j['name']),
      examType: _s(j['exam_type']),
      startDate: _dt(j['start_date']),
      endDate: _dt(j['end_date']),
      description: j['description'] as String?,
      isPublished: _b(j['is_published']),
      createdAt: _dt(j['created_at']),
      termName: term?['name'] as String?,
      academicYearName: year?['name'] as String?,
    );
  }

  ExamSubject _examSubjectFromRow(Map<String, dynamic> j) {
    final subject = j['subjects'] as Map<String, dynamic>?;
    final cls = j['classes'] as Map<String, dynamic>?;
    return ExamSubject(
      id: _s(j['id']),
      tenantId: _s(j['tenant_id']),
      examId: _s(j['exam_id']),
      subjectId: _s(j['subject_id']),
      classId: _s(j['class_id']),
      examDate: _dt(j['exam_date']),
      startTime: j['start_time'] as String?,
      endTime: j['end_time'] as String?,
      maxMarks: _d(j['max_marks']),
      passingMarks: _d(j['passing_marks']),
      weightage: (j['weightage'] as num?)?.toDouble() ?? 1.0,
      syllabus: j['syllabus'] as String?,
      createdAt: _dt(j['created_at']),
      subjectName: subject?['name'] as String?,
      subjectCode: subject?['code'] as String?,
      className: cls?['name'] as String?,
    );
  }

  Mark _markFromRow(Map<String, dynamic> j) {
    final student = j['students'] as Map<String, dynamic>?;
    final examSubject = j['exam_subjects'] as Map<String, dynamic>?;
    final subject = examSubject?['subjects'] as Map<String, dynamic>?;
    String? studentName;
    if (student != null) {
      final full =
          '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
      studentName = full.isEmpty ? null : full;
    }
    return Mark(
      id: _s(j['id']),
      tenantId: _s(j['tenant_id']),
      examSubjectId: _s(j['exam_subject_id']),
      studentId: _s(j['student_id']),
      marksObtained: _dN(j['marks_obtained']),
      isAbsent: _b(j['is_absent']),
      remarks: j['remarks'] as String?,
      enteredBy: j['entered_by'] as String?,
      enteredAt: _dt(j['entered_at']),
      updatedAt: _dt(j['updated_at']),
      studentName: studentName,
      admissionNumber: student?['admission_number'] as String?,
      subjectName: subject?['name'] as String?,
      maxMarks: _dN(examSubject?['max_marks']),
      passingMarks: _dN(examSubject?['passing_marks']),
    );
  }

  StudentPerformance _performanceFromRow(Map<String, dynamic> j) =>
      StudentPerformance(
        tenantId: _s(j['tenant_id']),
        studentId: _s(j['student_id']),
        studentName: _s(j['student_name']),
        admissionNumber: _s(j['admission_number']),
        sectionId: _s(j['section_id']),
        sectionName: _s(j['section_name']),
        classId: _s(j['class_id']),
        className: _s(j['class_name']),
        examId: _s(j['exam_id']),
        examName: _s(j['exam_name']),
        examType: _s(j['exam_type']),
        subjectId: _s(j['subject_id']),
        subjectName: _s(j['subject_name']),
        subjectCode: j['subject_code'] as String?,
        marksObtained: _d(j['marks_obtained']),
        maxMarks: _d(j['max_marks']),
        passingMarks: _d(j['passing_marks']),
        percentage: _d(j['percentage']),
        isPassed: _b(j['is_passed']),
        isAbsent: _b(j['is_absent']),
        academicYearId: _s(j['academic_year_id']),
        termId: j['term_id'] as String?,
      );

  StudentRank _rankFromRow(Map<String, dynamic> j) => StudentRank(
        tenantId: _s(j['tenant_id']),
        studentId: _s(j['student_id']),
        studentName: _s(j['student_name']),
        admissionNumber: _s(j['admission_number']),
        sectionId: _s(j['section_id']),
        sectionName: _s(j['section_name']),
        classId: _s(j['class_id']),
        className: _s(j['class_name']),
        examId: _s(j['exam_id']),
        examName: _s(j['exam_name']),
        examType: _s(j['exam_type']),
        subjectId: _s(j['subject_id']),
        subjectName: _s(j['subject_name']),
        marksObtained: _d(j['marks_obtained']),
        maxMarks: _d(j['max_marks']),
        percentage: _d(j['percentage']),
        subjectRank: _i(j['subject_rank']),
        totalInSubject: _i(j['total_in_subject']),
        academicYearId: _s(j['academic_year_id']),
      );

  StudentOverallRank _overallRankFromRow(Map<String, dynamic> j) =>
      StudentOverallRank(
        tenantId: _s(j['tenant_id']),
        studentId: _s(j['student_id']),
        studentName: _s(j['student_name']),
        admissionNumber: _s(j['admission_number']),
        sectionId: _s(j['section_id']),
        sectionName: _s(j['section_name']),
        classId: _s(j['class_id']),
        className: _s(j['class_name']),
        examId: _s(j['exam_id']),
        examName: _s(j['exam_name']),
        examType: _s(j['exam_type']),
        academicYearId: _s(j['academic_year_id']),
        totalObtained: _d(j['total_obtained']),
        totalMaxMarks: _d(j['total_max_marks']),
        overallPercentage: _d(j['overall_percentage']),
        subjectsCount: _i(j['subjects_count']),
        subjectsPassed: _i(j['subjects_passed']),
        classRank: _i(j['class_rank']),
      );

  ClassExamStats _classStatsFromRow(Map<String, dynamic> j) => ClassExamStats(
        tenantId: _s(j['tenant_id']),
        examId: _s(j['exam_id']),
        examName: _s(j['exam_name']),
        examType: _s(j['exam_type']),
        sectionId: _s(j['section_id']),
        sectionName: _s(j['section_name']),
        classId: _s(j['class_id']),
        className: _s(j['class_name']),
        subjectId: _s(j['subject_id']),
        subjectName: _s(j['subject_name']),
        academicYearId: _s(j['academic_year_id']),
        totalStudents: _i(j['total_students']),
        studentsAppeared: _i(j['students_appeared']),
        classAverage: _d(j['class_average']),
        highestPercentage: _d(j['highest_percentage']),
        lowestPercentage: _d(j['lowest_percentage']),
        passedCount: _i(j['passed_count']),
        failedCount: _i(j['failed_count']),
        absentCount: _i(j['absent_count']),
        passPercentage: _d(j['pass_percentage']),
      );

  GradeScaleItem _gradeScaleItemFromRow(Map<String, dynamic> j) =>
      GradeScaleItem(
        id: _s(j['id']),
        gradeScaleId: _s(j['grade_scale_id']),
        grade: _s(j['grade']),
        minPercentage: _d(j['min_percentage']),
        maxPercentage: _d(j['max_percentage']),
        gradePoint: _dN(j['grade_point']),
        description: j['description'] as String?,
      );

  GradeScale _gradeScaleFromRow(Map<String, dynamic> j) {
    final items = j['grade_scale_items'] as List?;
    return GradeScale(
      id: _s(j['id']),
      tenantId: _s(j['tenant_id']),
      name: _s(j['name']),
      isDefault: _b(j['is_default']),
      createdAt: _dt(j['created_at']),
      items: items
          ?.whereType<Map>()
          .map((e) => _gradeScaleItemFromRow(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Future<List<Exam>> getExams({
    String? academicYearId,
    String? termId,
    bool publishedOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('exams')
        .select('''
          *,
          terms(id, name),
          academic_years(id, name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }
    if (termId != null) {
      query = query.eq('term_id', termId);
    }
    if (publishedOnly) {
      query = query.eq('is_published', true);
    }

    final response = await query.order('start_date', ascending: false).range(offset, offset + limit - 1);
    return (response as List).map((json) => _examFromRow(json as Map<String, dynamic>)).toList();
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

    return _examFromRow(response);
  }

  Future<Exam> createExam(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('exams')
        .insert(data)
        .select()
        .single();

    return _examFromRow(response);
  }

  Future<Exam> updateExam(String examId, Map<String, dynamic> data) async {
    final response = await client
        .from('exams')
        .update(data)
        .eq('id', examId)
        .select()
        .single();

    return _examFromRow(response);
  }

  Future<void> publishExam(String examId) async {
    await client
        .from('exams')
        .update({'is_published': true})
        .eq('id', examId);
  }

  Future<void> unpublishExam(String examId) async {
    await client
        .from('exams')
        .update({'is_published': false})
        .eq('id', examId);
  }

  Future<void> deleteExam(String examId) async {
    await client.from('exams').delete().eq('id', examId);
  }

  Future<void> deleteExamSubject(String examSubjectId) async {
    await client.from('exam_subjects').delete().eq('id', examSubjectId);
  }

  /// Patch one or more fields on an exam_subjects row. Used by the
  /// per-subject scheduling sheet (exam date / start time / end time).
  /// Pass only the keys that change.
  ///
  /// Returns void — callers should invalidate [examSubjectsProvider]
  /// to refresh the list.
  Future<void> updateExamSubject(
    String examSubjectId,
    Map<String, dynamic> data,
  ) async {
    await client
        .from('exam_subjects')
        .update(data)
        .eq('id', examSubjectId);
  }

  /// All marks for every exam_subject under an exam — joined with student
  /// and subject info so the analytics screen can compute pass-rate,
  /// averages, toppers and distribution without N+1 calls.
  ///
  /// Returns raw rows (snake_case, with nested `students` / `exam_subjects`
  /// objects) because the freezed [Mark] model uses camelCase keys and
  /// can't deserialise the joined shape directly.
  Future<List<Map<String, dynamic>>> getMarksForExam(String examId) async {
    final response = await client
        .from('marks')
        .select('''
          id,
          student_id,
          marks_obtained,
          is_absent,
          remarks,
          students(id, first_name, last_name, admission_number),
          exam_subjects!inner(
            id,
            exam_id,
            max_marks,
            passing_marks,
            subjects(id, name)
          )
        ''')
        .eq('exam_subjects.exam_id', examId);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
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

    return (response as List).map((json) => _examSubjectFromRow(json as Map<String, dynamic>)).toList();
  }

  Future<ExamSubject> createExamSubject(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('exam_subjects')
        .insert(data)
        .select()
        .single();

    return _examSubjectFromRow(response);
  }

  Future<List<Mark>> getMarks({
    required String examSubjectId,
    String? studentId,
    int limit = 50,
    int offset = 0,
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

    final response = await query.range(offset, offset + limit - 1);
    return (response as List).map((json) => _markFromRow(json as Map<String, dynamic>)).toList();
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
    int limit = 50,
    int offset = 0,
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

    final response = await query.range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => _performanceFromRow(json as Map<String, dynamic>))
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
    return (response as List).map((json) => _rankFromRow(json as Map<String, dynamic>)).toList();
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
    return _overallRankFromRow(response);
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
        .map((json) => _classStatsFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<GradeScale>> getGradeScales() async {
    final response = await client
        .from('grade_scales')
        .select('''
          *,
          grade_scale_items(*)
        ''')
        .eq('tenant_id', requireTenantId)
        .order('name');

    return (response as List).map((json) => _gradeScaleFromRow(json as Map<String, dynamic>)).toList();
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
        .map((json) => _overallRankFromRow(json as Map<String, dynamic>))
        .toList();
  }
}
