import '../models/quiz.dart';
import 'base_repository.dart';

class AssessmentRepository extends BaseRepository {
  AssessmentRepository(super.client);

  // ==================== QUIZZES ====================

  Future<List<Quiz>> getQuizzes({
    String? subjectId,
    String? sectionId,
    String? status,
    String? createdBy,
  }) async {
    var query = client
        .from('quizzes')
        .select('''
          *,
          subject:subjects(name),
          section:sections(name, class:classes(name)),
          creator:users(full_name)
        ''')
        .eq('tenant_id', tenantId!);

    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }
    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (createdBy != null) {
      query = query.eq('created_by', createdBy);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Quiz.fromJson(json)).toList();
  }

  Future<Quiz?> getQuizById(String quizId) async {
    final response = await client
        .from('quizzes')
        .select('''
          *,
          subject:subjects(name),
          section:sections(name, class:classes(name)),
          creator:users(full_name)
        ''')
        .eq('id', quizId)
        .maybeSingle();

    if (response == null) return null;
    return Quiz.fromJson(response);
  }

  Future<Quiz> createQuiz(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['created_by'] = currentUserId;
    data['status'] = 'draft';

    final response = await client.from('quizzes').insert(data).select().single();
    return Quiz.fromJson(response);
  }

  Future<Quiz> updateQuiz(String quizId, Map<String, dynamic> data) async {
    final response = await client
        .from('quizzes')
        .update(data)
        .eq('id', quizId)
        .select()
        .single();
    return Quiz.fromJson(response);
  }

  Future<void> publishQuiz(String quizId) async {
    await client.from('quizzes').update({
      'status': 'published',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', quizId);
  }

  Future<void> closeQuiz(String quizId) async {
    await client.from('quizzes').update({
      'status': 'closed',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', quizId);
  }

  Future<void> deleteQuiz(String quizId) async {
    // Delete questions first
    await client.from('quiz_questions').delete().eq('quiz_id', quizId);
    // Then delete the quiz
    await client.from('quizzes').delete().eq('id', quizId);
  }

  // ==================== QUESTION BANK ====================

  Future<List<QuestionBank>> getQuestionBank({
    String? subjectId,
    String? questionType,
    String? difficulty,
    String? chapter,
    String? searchQuery,
    int limit = 50,
  }) async {
    var query = client
        .from('question_bank')
        .select('''
          *,
          subject:subjects(name)
        ''')
        .eq('tenant_id', tenantId!);

    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }
    if (questionType != null) {
      query = query.eq('question_type', questionType);
    }
    if (difficulty != null) {
      query = query.eq('difficulty', difficulty);
    }
    if (chapter != null) {
      query = query.eq('chapter', chapter);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('question_text', '%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false).limit(limit);
    return (response as List).map((json) => QuestionBank.fromJson(json)).toList();
  }

  Future<QuestionBank?> getQuestionById(String questionId) async {
    final response = await client
        .from('question_bank')
        .select('''
          *,
          subject:subjects(name)
        ''')
        .eq('id', questionId)
        .maybeSingle();

    if (response == null) return null;
    return QuestionBank.fromJson(response);
  }

  Future<QuestionBank> createQuestion(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['created_by'] = currentUserId;

    final response =
        await client.from('question_bank').insert(data).select().single();
    return QuestionBank.fromJson(response);
  }

  Future<QuestionBank> updateQuestion(
    String questionId,
    Map<String, dynamic> data,
  ) async {
    final response = await client
        .from('question_bank')
        .update(data)
        .eq('id', questionId)
        .select()
        .single();
    return QuestionBank.fromJson(response);
  }

  Future<void> deleteQuestion(String questionId) async {
    await client.from('question_bank').delete().eq('id', questionId);
  }

  // ==================== QUIZ QUESTIONS ====================

  Future<List<QuizQuestion>> getQuizQuestions(String quizId) async {
    final response = await client
        .from('quiz_questions')
        .select('''
          *,
          question_bank(*)
        ''')
        .eq('quiz_id', quizId)
        .order('sequence_order');

    return (response as List).map((json) => QuizQuestion.fromJson(json)).toList();
  }

  Future<void> addQuestionToQuiz({
    required String quizId,
    String? questionBankId,
    required int sequenceOrder,
    required String questionType,
    required String questionText,
    Map<String, dynamic>? options,
    String? correctAnswer,
    String? explanation,
    required int marks,
  }) async {
    await client.from('quiz_questions').insert({
      'quiz_id': quizId,
      'question_bank_id': questionBankId,
      'sequence_order': sequenceOrder,
      'question_type': questionType,
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'marks': marks,
    });

    // Update quiz total marks
    await _updateQuizTotalMarks(quizId);
  }

  Future<void> addQuestionsFromBank(
    String quizId,
    List<String> questionIds,
  ) async {
    // Get current max sequence order
    final existingQuestions = await getQuizQuestions(quizId);
    int sequenceOrder = existingQuestions.isNotEmpty
        ? existingQuestions.last.sequenceOrder + 1
        : 1;

    for (final questionId in questionIds) {
      final bankQuestion = await getQuestionById(questionId);
      if (bankQuestion != null) {
        await client.from('quiz_questions').insert({
          'quiz_id': quizId,
          'question_bank_id': questionId,
          'sequence_order': sequenceOrder,
          'question_type': bankQuestion.questionType,
          'question_text': bankQuestion.questionText,
          'options': bankQuestion.options,
          'correct_answer': bankQuestion.correctAnswer,
          'explanation': bankQuestion.explanation,
          'marks': bankQuestion.marks,
        });
        sequenceOrder++;
      }
    }

    await _updateQuizTotalMarks(quizId);
  }

  Future<void> removeQuestionFromQuiz(String quizQuestionId) async {
    final question = await client
        .from('quiz_questions')
        .select('quiz_id')
        .eq('id', quizQuestionId)
        .single();

    await client.from('quiz_questions').delete().eq('id', quizQuestionId);

    await _updateQuizTotalMarks(question['quiz_id']);
  }

  Future<void> reorderQuizQuestions(
    String quizId,
    List<String> questionIds,
  ) async {
    for (var i = 0; i < questionIds.length; i++) {
      await client
          .from('quiz_questions')
          .update({'sequence_order': i + 1}).eq('id', questionIds[i]);
    }
  }

  Future<void> _updateQuizTotalMarks(String quizId) async {
    final questions = await getQuizQuestions(quizId);
    final totalMarks = questions.fold<int>(0, (sum, q) => sum + q.marks);

    await client.from('quizzes').update({
      'total_marks': totalMarks,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', quizId);
  }

  // ==================== QUIZ ATTEMPTS ====================

  Future<List<QuizAttempt>> getQuizAttempts({
    String? quizId,
    String? studentId,
    String? status,
  }) async {
    var query = client
        .from('quiz_attempts')
        .select('''
          *,
          quiz:quizzes(title),
          student:students(first_name, last_name)
        ''')
        .eq('tenant_id', tenantId!);

    if (quizId != null) {
      query = query.eq('quiz_id', quizId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('started_at', ascending: false);
    return (response as List).map((json) => QuizAttempt.fromJson(json)).toList();
  }

  Future<QuizAttempt?> getAttemptById(String attemptId) async {
    final response = await client
        .from('quiz_attempts')
        .select('''
          *,
          quiz:quizzes(title),
          student:students(first_name, last_name)
        ''')
        .eq('id', attemptId)
        .maybeSingle();

    if (response == null) return null;
    return QuizAttempt.fromJson(response);
  }

  Future<QuizAttempt?> getExistingAttempt(String quizId, String studentId) async {
    final response = await client
        .from('quiz_attempts')
        .select()
        .eq('quiz_id', quizId)
        .eq('student_id', studentId)
        .eq('status', 'in_progress')
        .maybeSingle();

    if (response == null) return null;
    return QuizAttempt.fromJson(response);
  }

  Future<int> getAttemptCount(String quizId, String studentId) async {
    final response = await client
        .from('quiz_attempts')
        .select('id')
        .eq('quiz_id', quizId)
        .eq('student_id', studentId);

    return (response as List).length;
  }

  Future<QuizAttempt> startQuizAttempt(String quizId, String studentId) async {
    // Check if there's an existing in-progress attempt
    final existing = await getExistingAttempt(quizId, studentId);
    if (existing != null) return existing;

    // Check max attempts
    final quiz = await getQuizById(quizId);
    if (quiz?.maxAttempts != null) {
      final attemptCount = await getAttemptCount(quizId, studentId);
      if (attemptCount >= quiz!.maxAttempts!) {
        throw Exception('Maximum attempts reached');
      }
    }

    final response = await client
        .from('quiz_attempts')
        .insert({
          'tenant_id': tenantId,
          'quiz_id': quizId,
          'student_id': studentId,
          'started_at': DateTime.now().toIso8601String(),
          'status': 'in_progress',
          'answers': {},
        })
        .select()
        .single();

    return QuizAttempt.fromJson(response);
  }

  Future<void> saveAnswer(
    String attemptId,
    String questionId,
    String? answer,
  ) async {
    // Get current answers
    final attempt = await getAttemptById(attemptId);
    if (attempt == null) return;

    final answers = Map<String, dynamic>.from(attempt.answers ?? {});
    answers[questionId] = answer;

    await client
        .from('quiz_attempts')
        .update({'answers': answers}).eq('id', attemptId);
  }

  Future<QuizAttempt> submitQuizAttempt(String attemptId) async {
    final attempt = await getAttemptById(attemptId);
    if (attempt == null) throw Exception('Attempt not found');

    final quiz = await getQuizById(attempt.quizId);
    if (quiz == null) throw Exception('Quiz not found');

    final questions = await getQuizQuestions(attempt.quizId);

    // Auto-grade MCQ and True/False questions
    int obtainedMarks = 0;
    final feedback = <String, dynamic>{};

    for (final question in questions) {
      final answer = attempt.answers?[question.id];
      if (question.isAutoGradable) {
        final isCorrect = answer == question.correctAnswer;
        final marks = isCorrect ? question.marks : 0;
        obtainedMarks += marks;
        feedback[question.id] = {
          'marks': marks,
          'is_correct': isCorrect,
          'correct_answer': question.correctAnswer,
        };
      }
    }

    // Check if all questions are auto-gradable
    final allAutoGradable = questions.every((q) => q.isAutoGradable);
    final percentage = quiz.totalMarks > 0
        ? (obtainedMarks / quiz.totalMarks) * 100
        : 0.0;
    final isPassed = percentage >= (quiz.passingMarks / quiz.totalMarks * 100);

    final response = await client
        .from('quiz_attempts')
        .update({
          'submitted_at': DateTime.now().toIso8601String(),
          'status': allAutoGradable ? 'graded' : 'submitted',
          'total_marks': quiz.totalMarks,
          'obtained_marks': obtainedMarks,
          'percentage': percentage,
          'is_passed': isPassed,
          'feedback': feedback,
        })
        .eq('id', attemptId)
        .select()
        .single();

    return QuizAttempt.fromJson(response);
  }

  Future<void> gradeAttempt(
    String attemptId,
    Map<String, dynamic> feedback,
    int obtainedMarks,
  ) async {
    final attempt = await getAttemptById(attemptId);
    if (attempt == null) throw Exception('Attempt not found');

    final percentage = attempt.totalMarks != null && attempt.totalMarks! > 0
        ? (obtainedMarks / attempt.totalMarks!) * 100
        : 0.0;

    await client.from('quiz_attempts').update({
      'status': 'graded',
      'obtained_marks': obtainedMarks,
      'percentage': percentage,
      'is_passed': percentage >= 40, // Default passing percentage
      'feedback': feedback,
    }).eq('id', attemptId);
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getQuizStatistics(String quizId) async {
    final attempts = await getQuizAttempts(quizId: quizId, status: 'graded');

    if (attempts.isEmpty) {
      return {
        'total_attempts': 0,
        'average_score': 0.0,
        'highest_score': 0.0,
        'lowest_score': 0.0,
        'pass_rate': 0.0,
      };
    }

    final scores =
        attempts.map((a) => a.percentage ?? 0.0).toList()..sort();
    final passedCount = attempts.where((a) => a.isPassed).length;

    return {
      'total_attempts': attempts.length,
      'average_score': scores.reduce((a, b) => a + b) / scores.length,
      'highest_score': scores.last,
      'lowest_score': scores.first,
      'pass_rate': (passedCount / attempts.length) * 100,
    };
  }

  Future<List<Quiz>> getStudentAvailableQuizzes(String studentId) async {
    // Get student's section
    final enrollmentResponse = await client
        .from('student_enrollments')
        .select('section_id')
        .eq('student_id', studentId)
        .eq('status', 'active')
        .maybeSingle();

    if (enrollmentResponse == null) return [];

    final sectionId = enrollmentResponse['section_id'] as String;

    // Get published quizzes for the section
    return getQuizzes(sectionId: sectionId, status: 'published');
  }
}
