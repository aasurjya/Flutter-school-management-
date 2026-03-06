import '../models/online_exam.dart';
import 'base_repository.dart';

class OnlineExamRepository extends BaseRepository {
  OnlineExamRepository(super.client);

  static const _examSelect = '''
    *,
    subjects(name),
    classes(name),
    users(full_name),
    exam_sections(
      *,
      exam_questions(*)
    )
  ''';

  static const _attemptSelect = '''
    *,
    online_exams(title, subject_id, total_marks, passing_marks),
    students(first_name, last_name)
  ''';

  // ==================== EXAMS ====================

  Future<List<OnlineExam>> getExams({
    String? subjectId,
    String? classId,
    String? status,
    String? createdBy,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('online_exams')
        .select(_examSelect)
        .eq('tenant_id', requireTenantId);

    if (subjectId != null) query = query.eq('subject_id', subjectId);
    if (classId != null) query = query.eq('class_id', classId);
    if (status != null) query = query.eq('status', status);
    if (createdBy != null) query = query.eq('created_by', createdBy);

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((j) => OnlineExam.fromJson(j)).toList();
  }

  Future<OnlineExam?> getExamById(String examId) async {
    final response = await client
        .from('online_exams')
        .select(_examSelect)
        .eq('id', examId)
        .maybeSingle();

    if (response == null) return null;
    return OnlineExam.fromJson(response);
  }

  Future<OnlineExam> createExam(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['created_by'] = requireUserId;
    data['status'] = 'draft';

    final response =
        await client.from('online_exams').insert(data).select().single();
    return OnlineExam.fromJson(response);
  }

  Future<OnlineExam> updateExam(
      String examId, Map<String, dynamic> data) async {
    final response = await client
        .from('online_exams')
        .update(data)
        .eq('id', examId)
        .select()
        .single();
    return OnlineExam.fromJson(response);
  }

  Future<void> updateExamStatus(String examId, String status) async {
    await client.from('online_exams').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', examId);
  }

  Future<void> deleteExam(String examId) async {
    await client.from('online_exams').delete().eq('id', examId);
  }

  /// Get exams available for a student (live or scheduled, matching their section)
  Future<List<OnlineExam>> getStudentExams(String sectionId) async {
    final response = await client
        .from('online_exams')
        .select(_examSelect)
        .eq('tenant_id', requireTenantId)
        .inFilter('status', ['scheduled', 'live', 'completed'])
        .order('start_time', ascending: false);

    // Filter by section_ids containing the student's section
    final exams = (response as List).map((j) => OnlineExam.fromJson(j)).toList();
    return exams.where((e) {
      if (e.sectionIds.isEmpty) return true; // All sections
      return e.sectionIds.contains(sectionId);
    }).toList();
  }

  // ==================== SECTIONS ====================

  Future<ExamSection> createSection(Map<String, dynamic> data) async {
    final response =
        await client.from('exam_sections').insert(data).select().single();
    return ExamSection.fromJson(response);
  }

  Future<ExamSection> updateSection(
      String sectionId, Map<String, dynamic> data) async {
    final response = await client
        .from('exam_sections')
        .update(data)
        .eq('id', sectionId)
        .select()
        .single();
    return ExamSection.fromJson(response);
  }

  Future<void> deleteSection(String sectionId) async {
    await client.from('exam_sections').delete().eq('id', sectionId);
  }

  Future<List<ExamSection>> getExamSections(String examId) async {
    final response = await client
        .from('exam_sections')
        .select('*, exam_questions(*)')
        .eq('exam_id', examId)
        .order('sequence_order');
    return (response as List).map((j) => ExamSection.fromJson(j)).toList();
  }

  // ==================== QUESTIONS ====================

  Future<ExamQuestion> createQuestion(Map<String, dynamic> data) async {
    final response =
        await client.from('exam_questions').insert(data).select().single();
    return ExamQuestion.fromJson(response);
  }

  Future<ExamQuestion> updateQuestion(
      String questionId, Map<String, dynamic> data) async {
    final response = await client
        .from('exam_questions')
        .update(data)
        .eq('id', questionId)
        .select()
        .single();
    return ExamQuestion.fromJson(response);
  }

  Future<void> deleteQuestion(String questionId) async {
    await client.from('exam_questions').delete().eq('id', questionId);
  }

  Future<List<ExamQuestion>> getSectionQuestions(String sectionId) async {
    final response = await client
        .from('exam_questions')
        .select('*')
        .eq('section_id', sectionId)
        .order('sequence_order');
    return (response as List).map((j) => ExamQuestion.fromJson(j)).toList();
  }

  Future<void> addQuestionsFromBank(
      String sectionId, List<String> bankQuestionIds) async {
    final existing = await getSectionQuestions(sectionId);
    int order = existing.isNotEmpty ? existing.last.sequenceOrder + 1 : 1;

    for (final bankId in bankQuestionIds) {
      final bankQ = await client
          .from('question_bank')
          .select()
          .eq('id', bankId)
          .maybeSingle();
      if (bankQ == null) continue;

      // Convert question bank format to exam question format
      List<dynamic> options = [];
      if (bankQ['options'] is Map) {
        final optMap = bankQ['options'] as Map<String, dynamic>;
        optMap.forEach((key, value) {
          options.add({'key': key, 'text': value.toString()});
        });
      }

      await client.from('exam_questions').insert({
        'section_id': sectionId,
        'question_bank_id': bankId,
        'question_type': bankQ['question_type'] ?? 'mcq',
        'question_text': bankQ['question_text'],
        'options': options,
        'correct_answer': {'value': bankQ['correct_answer']},
        'marks': bankQ['marks'] ?? 1,
        'explanation': bankQ['explanation'],
        'difficulty': bankQ['difficulty'] ?? 'medium',
        'sequence_order': order++,
      });
    }
  }

  // ==================== ATTEMPTS ====================

  Future<List<ExamAttempt>> getExamAttempts({
    String? examId,
    String? studentId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('exam_attempts')
        .select(_attemptSelect)
        .eq('tenant_id', requireTenantId);

    if (examId != null) query = query.eq('exam_id', examId);
    if (studentId != null) query = query.eq('student_id', studentId);
    if (status != null) query = query.eq('status', status);

    final response = await query
        .order('started_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((j) => ExamAttempt.fromJson(j)).toList();
  }

  Future<ExamAttempt?> getAttemptById(String attemptId) async {
    final response = await client
        .from('exam_attempts')
        .select('''
          $_attemptSelect,
          exam_responses(*, exam_questions(*))
        ''')
        .eq('id', attemptId)
        .maybeSingle();

    if (response == null) return null;
    return ExamAttempt.fromJson(response);
  }

  Future<ExamAttempt?> getExistingAttempt(
      String examId, String studentId) async {
    final response = await client
        .from('exam_attempts')
        .select()
        .eq('exam_id', examId)
        .eq('student_id', studentId)
        .eq('status', 'in_progress')
        .maybeSingle();

    if (response == null) return null;
    return ExamAttempt.fromJson(response);
  }

  Future<int> getAttemptCount(String examId, String studentId) async {
    final response = await client
        .from('exam_attempts')
        .select('id')
        .eq('exam_id', examId)
        .eq('student_id', studentId);
    return (response as List).length;
  }

  Future<ExamAttempt> startExamAttempt(
      String examId, String studentId) async {
    // Check for existing in-progress attempt
    final existing = await getExistingAttempt(examId, studentId);
    if (existing != null) return existing;

    // Check max attempts
    final exam = await getExamById(examId);
    if (exam == null) throw Exception('Exam not found');

    final maxAttempts = exam.settings.maxAttempts;
    if (maxAttempts > 0) {
      final count = await getAttemptCount(examId, studentId);
      if (count >= maxAttempts) {
        throw Exception('Maximum attempts ($maxAttempts) reached');
      }
    }

    final attemptNumber = (await getAttemptCount(examId, studentId)) + 1;

    final response = await client
        .from('exam_attempts')
        .insert({
          'tenant_id': requireTenantId,
          'exam_id': examId,
          'student_id': studentId,
          'attempt_number': attemptNumber,
          'started_at': DateTime.now().toIso8601String(),
          'status': 'in_progress',
        })
        .select()
        .single();

    return ExamAttempt.fromJson(response);
  }

  // ==================== RESPONSES ====================

  Future<void> saveResponse({
    required String attemptId,
    required String questionId,
    dynamic response,
    bool flaggedForReview = false,
    int timeSpentSeconds = 0,
  }) async {
    await client.from('exam_responses').upsert(
      {
        'attempt_id': attemptId,
        'question_id': questionId,
        'response': response,
        'flagged_for_review': flaggedForReview,
        'time_spent_seconds': timeSpentSeconds,
      },
      onConflict: 'attempt_id,question_id',
    );
  }

  Future<void> toggleFlag(
      String attemptId, String questionId, bool flagged) async {
    await client.from('exam_responses').upsert(
      {
        'attempt_id': attemptId,
        'question_id': questionId,
        'flagged_for_review': flagged,
      },
      onConflict: 'attempt_id,question_id',
    );
  }

  Future<List<ExamResponse>> getAttemptResponses(String attemptId) async {
    final response = await client
        .from('exam_responses')
        .select('*, exam_questions(*)')
        .eq('attempt_id', attemptId);
    return (response as List).map((j) => ExamResponse.fromJson(j)).toList();
  }

  // ==================== SUBMIT & GRADE ====================

  Future<ExamAttempt> submitExamAttempt(String attemptId,
      {bool autoSubmit = false}) async {
    final attempt = await getAttemptById(attemptId);
    if (attempt == null) throw Exception('Attempt not found');

    final exam = await getExamById(attempt.examId);
    if (exam == null) throw Exception('Exam not found');

    // Get all sections and questions
    final sections = await getExamSections(exam.id);
    final responses = await getAttemptResponses(attemptId);
    final responseMap = {for (final r in responses) r.questionId: r};

    double totalObtained = 0;
    bool hasSubjectiveQuestions = false;

    // Auto-grade objective questions
    for (final section in sections) {
      final questions = section.questions ?? await getSectionQuestions(section.id);
      for (final question in questions) {
        final resp = responseMap[question.id];
        if (resp == null) continue;

        if (question.isAutoGradable) {
          final isCorrect = _checkAnswer(question, resp.response);
          double marks = 0;
          if (isCorrect) {
            marks = question.marks;
          } else if (exam.settings.negativeMarkingValue > 0 &&
              resp.response != null &&
              resp.response.toString().isNotEmpty) {
            marks = -exam.settings.negativeMarkingValue;
          }
          totalObtained += marks;

          await client.from('exam_responses').update({
            'is_correct': isCorrect,
            'marks_awarded': marks,
          }).eq('id', resp.id);
        } else {
          hasSubjectiveQuestions = true;
        }
      }
    }

    final timeTaken =
        DateTime.now().difference(attempt.startedAt).inSeconds;
    final percentage =
        exam.totalMarks > 0 ? (totalObtained / exam.totalMarks) * 100 : 0.0;

    String newStatus;
    if (hasSubjectiveQuestions) {
      newStatus = 'under_review';
    } else if (autoSubmit) {
      newStatus = 'auto_submitted';
    } else {
      newStatus = 'graded';
    }

    // If fully auto-graded, mark as graded directly
    if (!hasSubjectiveQuestions) {
      newStatus = 'graded';
    }

    final response = await client
        .from('exam_attempts')
        .update({
          'submitted_at': DateTime.now().toIso8601String(),
          'time_taken_seconds': timeTaken,
          'total_marks_obtained': totalObtained,
          'percentage': percentage,
          'status': newStatus,
        })
        .eq('id', attemptId)
        .select(_attemptSelect)
        .single();

    return ExamAttempt.fromJson(response);
  }

  bool _checkAnswer(ExamQuestion question, dynamic response) {
    if (response == null) return false;
    final correct = question.correctAnswer;
    if (correct == null) return false;

    switch (question.questionType) {
      case ExamQuestionType.mcq:
      case ExamQuestionType.trueFalse:
        final correctValue =
            correct is Map ? correct['value']?.toString() : correct.toString();
        final responseValue =
            response is Map ? response['value']?.toString() : response.toString();
        return correctValue == responseValue;
      case ExamQuestionType.multiSelect:
        final correctList = correct is Map
            ? (correct['values'] as List?)?.map((e) => e.toString()).toSet()
            : <String>{};
        final responseList = response is Map
            ? (response['values'] as List?)?.map((e) => e.toString()).toSet()
            : <String>{};
        return correctList != null &&
            responseList != null &&
            correctList.length == responseList.length &&
            correctList.containsAll(responseList);
      case ExamQuestionType.fillBlank:
        final correctText = (correct is Map ? correct['value'] : correct)
            .toString()
            .toLowerCase()
            .trim();
        final responseText = (response is Map ? response['value'] : response)
            .toString()
            .toLowerCase()
            .trim();
        return correctText == responseText;
      case ExamQuestionType.ordering:
        final correctOrder = correct is Map
            ? (correct['order'] as List?)
            : (correct is List ? correct : null);
        final responseOrder = response is Map
            ? (response['order'] as List?)
            : (response is List ? response : null);
        if (correctOrder == null || responseOrder == null) return false;
        if (correctOrder.length != responseOrder.length) return false;
        for (int i = 0; i < correctOrder.length; i++) {
          if (correctOrder[i].toString() != responseOrder[i].toString()) {
            return false;
          }
        }
        return true;
      default:
        return false;
    }
  }

  /// Teacher grades a subjective response
  Future<void> gradeResponse(
    String responseId, {
    required double marks,
    required bool isCorrect,
  }) async {
    await client.from('exam_responses').update({
      'marks_awarded': marks,
      'is_correct': isCorrect,
    }).eq('id', responseId);
  }

  /// Finalize grading for an attempt (after all subjective Qs graded)
  Future<ExamAttempt> finalizeGrading(String attemptId) async {
    final responses = await getAttemptResponses(attemptId);
    final attempt = await getAttemptById(attemptId);
    if (attempt == null) throw Exception('Attempt not found');

    final exam = await getExamById(attempt.examId);
    if (exam == null) throw Exception('Exam not found');

    double total = 0;
    for (final r in responses) {
      total += r.marksAwarded;
    }

    final percentage =
        exam.totalMarks > 0 ? (total / exam.totalMarks) * 100 : 0.0;

    final result = await client
        .from('exam_attempts')
        .update({
          'total_marks_obtained': total,
          'percentage': percentage,
          'status': 'graded',
        })
        .eq('id', attemptId)
        .select(_attemptSelect)
        .single();

    return ExamAttempt.fromJson(result);
  }

  // ==================== ANALYTICS ====================

  Future<ExamAnalytics?> getExamAnalytics(String examId) async {
    final response = await client
        .from('v_exam_analytics')
        .select()
        .eq('exam_id', examId)
        .maybeSingle();

    if (response == null) return null;
    return ExamAnalytics.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> getQuestionAnalytics(
      String examId) async {
    final response = await client
        .from('v_exam_question_analytics')
        .select()
        .eq('exam_id', examId)
        .order('accuracy_rate');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Score distribution: returns buckets (0-10, 10-20, ... 90-100) with counts
  Future<List<Map<String, dynamic>>> getScoreDistribution(
      String examId) async {
    final attempts = await getExamAttempts(examId: examId, status: 'graded');
    final buckets = List.generate(10, (i) => {
      'range': '${i * 10}-${(i + 1) * 10}',
      'count': 0,
    });

    for (final a in attempts) {
      final bucket = (a.percentage / 10).floor().clamp(0, 9);
      buckets[bucket]['count'] = (buckets[bucket]['count'] as int) + 1;
    }
    return buckets;
  }
}
