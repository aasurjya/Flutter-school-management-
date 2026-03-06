import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/online_exam.dart';
import '../../../data/repositories/online_exam_repository.dart';

// ==================== REPOSITORY PROVIDER ====================

final onlineExamRepositoryProvider = Provider<OnlineExamRepository>((ref) {
  return OnlineExamRepository(ref.watch(supabaseProvider));
});

// ==================== EXAM LIST PROVIDERS ====================

final onlineExamsProvider =
    FutureProvider.family<List<OnlineExam>, OnlineExamFilter>(
  (ref, filter) async {
    final repo = ref.watch(onlineExamRepositoryProvider);
    return repo.getExams(
      subjectId: filter.subjectId,
      classId: filter.classId,
      status: filter.status,
      createdBy: filter.createdBy,
    );
  },
);

final onlineExamByIdProvider = FutureProvider.family<OnlineExam?, String>(
  (ref, examId) async {
    final repo = ref.watch(onlineExamRepositoryProvider);
    return repo.getExamById(examId);
  },
);

final studentExamsProvider =
    FutureProvider.family<List<OnlineExam>, String>(
  (ref, sectionId) async {
    final repo = ref.watch(onlineExamRepositoryProvider);
    return repo.getStudentExams(sectionId);
  },
);

// ==================== ATTEMPT PROVIDERS ====================

final examAttemptsProvider =
    FutureProvider.family<List<ExamAttempt>, ExamAttemptsFilter>(
  (ref, filter) async {
    final repo = ref.watch(onlineExamRepositoryProvider);
    return repo.getExamAttempts(
      examId: filter.examId,
      studentId: filter.studentId,
      status: filter.status,
    );
  },
);

final examAttemptByIdProvider = FutureProvider.family<ExamAttempt?, String>(
  (ref, attemptId) async {
    final repo = ref.watch(onlineExamRepositoryProvider);
    return repo.getAttemptById(attemptId);
  },
);

// ==================== ANALYTICS PROVIDERS ====================

final examAnalyticsProvider =
    FutureProvider.family<ExamAnalytics?, String>(
  (ref, examId) async {
    final repo = ref.watch(onlineExamRepositoryProvider);
    return repo.getExamAnalytics(examId);
  },
);

final examQuestionAnalyticsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, examId) async {
    final repo = ref.watch(onlineExamRepositoryProvider);
    return repo.getQuestionAnalytics(examId);
  },
);

final examScoreDistributionProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, examId) async {
    final repo = ref.watch(onlineExamRepositoryProvider);
    return repo.getScoreDistribution(examId);
  },
);

// ==================== FILTER CLASSES ====================

class OnlineExamFilter {
  final String? subjectId;
  final String? classId;
  final String? status;
  final String? createdBy;

  const OnlineExamFilter({
    this.subjectId,
    this.classId,
    this.status,
    this.createdBy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnlineExamFilter &&
          other.subjectId == subjectId &&
          other.classId == classId &&
          other.status == status &&
          other.createdBy == createdBy;

  @override
  int get hashCode => Object.hash(subjectId, classId, status, createdBy);
}

class ExamAttemptsFilter {
  final String? examId;
  final String? studentId;
  final String? status;

  const ExamAttemptsFilter({
    this.examId,
    this.studentId,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamAttemptsFilter &&
          other.examId == examId &&
          other.studentId == studentId &&
          other.status == status;

  @override
  int get hashCode => Object.hash(examId, studentId, status);
}

// ==================== EXAM SESSION NOTIFIER ====================

class ExamSessionNotifier
    extends StateNotifier<AsyncValue<OnlineExamSession?>> {
  final OnlineExamRepository _repository;
  Timer? _timer;

  ExamSessionNotifier(this._repository)
      : super(const AsyncValue.data(null));

  Future<void> startExam(String examId, String studentId) async {
    state = const AsyncValue.loading();

    try {
      final exam = await _repository.getExamById(examId);
      if (exam == null) throw Exception('Exam not found');

      if (!exam.isAvailable && !exam.isLive) {
        throw Exception('Exam is not currently available');
      }

      // Start or resume attempt
      final attempt = await _repository.startExamAttempt(examId, studentId);

      // Get sections and their questions
      final sections = await _repository.getExamSections(examId);
      final sectionQuestions = <String, List<ExamQuestion>>{};

      for (final section in sections) {
        var questions = section.questions ??
            await _repository.getSectionQuestions(section.id);

        // Shuffle questions if enabled
        if (exam.settings.shuffleQuestions) {
          questions = List.from(questions)..shuffle();
        }

        // Shuffle MCQ options if enabled
        if (exam.settings.shuffleOptions) {
          for (int i = 0; i < questions.length; i++) {
            final q = questions[i];
            if (q.questionType == ExamQuestionType.mcq ||
                q.questionType == ExamQuestionType.multiSelect) {
              final shuffled = List.from(q.options)..shuffle();
              questions[i] = ExamQuestion(
                id: q.id,
                sectionId: q.sectionId,
                questionBankId: q.questionBankId,
                questionType: q.questionType,
                questionText: q.questionText,
                questionMedia: q.questionMedia,
                options: shuffled,
                correctAnswer: q.correctAnswer,
                marks: q.marks,
                explanation: q.explanation,
                difficulty: q.difficulty,
                sequenceOrder: q.sequenceOrder,
                createdAt: q.createdAt,
                updatedAt: q.updatedAt,
              );
            }
          }
        }

        sectionQuestions[section.id] = questions;
      }

      // Load existing responses
      final existingResponses =
          await _repository.getAttemptResponses(attempt.id);
      final responses = <String, dynamic>{};
      final flagged = <String>{};
      for (final r in existingResponses) {
        responses[r.questionId] = r.response;
        if (r.flaggedForReview) flagged.add(r.questionId);
      }

      // Calculate remaining time
      final elapsed =
          DateTime.now().difference(attempt.startedAt).inSeconds;
      final remaining = (exam.durationMinutes * 60) - elapsed;

      state = AsyncValue.data(OnlineExamSession(
        exam: exam,
        sections: sections,
        sectionQuestions: sectionQuestions,
        attempt: attempt,
        responses: responses,
        flaggedQuestions: flagged,
        currentSectionIndex: 0,
        currentQuestionIndex: 0,
        remainingSeconds: remaining > 0 ? remaining : 0,
        tabSwitchCount: 0,
      ));

      _startTimer();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = state.value;
      if (session != null) {
        if (session.remainingSeconds <= 0) {
          _timer?.cancel();
          submitExam(autoSubmit: true);
        } else {
          state = AsyncValue.data(
            session.copyWith(
                remainingSeconds: session.remainingSeconds - 1),
          );
        }
      }
    });
  }

  void answerQuestion(String questionId, dynamic answer) {
    final session = state.value;
    if (session == null) return;

    final newResponses = Map<String, dynamic>.from(session.responses);
    newResponses[questionId] = answer;

    state = AsyncValue.data(session.copyWith(responses: newResponses));

    // Save to database in background
    _repository.saveResponse(
      attemptId: session.attempt.id,
      questionId: questionId,
      response: answer,
      flaggedForReview: session.isQuestionFlagged(questionId),
    );
  }

  void toggleQuestionFlag(String questionId) {
    final session = state.value;
    if (session == null) return;

    final flags = Set<String>.from(session.flaggedQuestions);
    final isFlagged = flags.contains(questionId);
    if (isFlagged) {
      flags.remove(questionId);
    } else {
      flags.add(questionId);
    }

    state = AsyncValue.data(session.copyWith(flaggedQuestions: flags));

    _repository.toggleFlag(
        session.attempt.id, questionId, !isFlagged);
  }

  void goToQuestion(int sectionIndex, int questionIndex) {
    final session = state.value;
    if (session == null) return;

    if (sectionIndex >= 0 &&
        sectionIndex < session.sections.length &&
        questionIndex >= 0 &&
        questionIndex <
            (session.sectionQuestions[session.sections[sectionIndex].id]
                    ?.length ??
                0)) {
      state = AsyncValue.data(session.copyWith(
        currentSectionIndex: sectionIndex,
        currentQuestionIndex: questionIndex,
      ));
    }
  }

  void nextQuestion() {
    final session = state.value;
    if (session == null) return;

    final currentQuestions = session.currentSectionQuestionList;
    if (session.currentQuestionIndex < currentQuestions.length - 1) {
      goToQuestion(
          session.currentSectionIndex, session.currentQuestionIndex + 1);
    } else if (session.currentSectionIndex < session.sections.length - 1) {
      // Move to next section
      goToQuestion(session.currentSectionIndex + 1, 0);
    }
  }

  void previousQuestion() {
    final session = state.value;
    if (session == null) return;

    if (session.currentQuestionIndex > 0) {
      goToQuestion(
          session.currentSectionIndex, session.currentQuestionIndex - 1);
    } else if (session.currentSectionIndex > 0) {
      // Move to previous section's last question
      final prevSectionId =
          session.sections[session.currentSectionIndex - 1].id;
      final prevQuestions =
          session.sectionQuestions[prevSectionId]?.length ?? 0;
      goToQuestion(session.currentSectionIndex - 1, prevQuestions - 1);
    }
  }

  void recordTabSwitch() {
    final session = state.value;
    if (session == null) return;

    final newCount = session.tabSwitchCount + 1;
    state = AsyncValue.data(session.copyWith(tabSwitchCount: newCount));

    // Check tab switch limit
    final limit = session.exam.settings.tabSwitchLimit;
    if (limit > 0 && newCount >= limit) {
      submitExam(autoSubmit: true);
    }
  }

  Future<ExamAttempt?> submitExam({bool autoSubmit = false}) async {
    final session = state.value;
    if (session == null) return null;

    _timer?.cancel();

    try {
      // Save all current responses first
      for (final entry in session.responses.entries) {
        await _repository.saveResponse(
          attemptId: session.attempt.id,
          questionId: entry.key,
          response: entry.value,
          flaggedForReview: session.isQuestionFlagged(entry.key),
        );
      }

      final result = await _repository.submitExamAttempt(
        session.attempt.id,
        autoSubmit: autoSubmit,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e) {
      // Don't clear state on error so user can retry
      return null;
    }
  }

  void cancelExam() {
    _timer?.cancel();
    state = const AsyncValue.data(null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final examSessionProvider = StateNotifierProvider<ExamSessionNotifier,
    AsyncValue<OnlineExamSession?>>((ref) {
  final repo = ref.watch(onlineExamRepositoryProvider);
  return ExamSessionNotifier(repo);
});

// ==================== EXAM BUILDER NOTIFIER ====================

class ExamBuilderState {
  final OnlineExam? exam;
  final List<ExamSection> sections;
  final Map<String, List<ExamQuestion>> sectionQuestions;
  final bool isLoading;
  final String? error;

  const ExamBuilderState({
    this.exam,
    this.sections = const [],
    this.sectionQuestions = const {},
    this.isLoading = false,
    this.error,
  });

  ExamBuilderState copyWith({
    OnlineExam? exam,
    List<ExamSection>? sections,
    Map<String, List<ExamQuestion>>? sectionQuestions,
    bool? isLoading,
    String? error,
  }) {
    return ExamBuilderState(
      exam: exam ?? this.exam,
      sections: sections ?? this.sections,
      sectionQuestions: sectionQuestions ?? this.sectionQuestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get totalQuestions {
    int count = 0;
    for (final qs in sectionQuestions.values) {
      count += qs.length;
    }
    return count;
  }

  double get totalMarks {
    double marks = 0;
    for (final qs in sectionQuestions.values) {
      for (final q in qs) {
        marks += q.marks;
      }
    }
    return marks;
  }
}

class ExamBuilderNotifier extends StateNotifier<ExamBuilderState> {
  final OnlineExamRepository _repository;

  ExamBuilderNotifier(this._repository) : super(const ExamBuilderState());

  Future<void> loadExam(String examId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final exam = await _repository.getExamById(examId);
      final sections = await _repository.getExamSections(examId);
      final sectionQuestions = <String, List<ExamQuestion>>{};

      for (final section in sections) {
        sectionQuestions[section.id] =
            section.questions ?? await _repository.getSectionQuestions(section.id);
      }

      state = state.copyWith(
        exam: exam,
        sections: sections,
        sectionQuestions: sectionQuestions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<OnlineExam?> createExam(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final exam = await _repository.createExam(data);
      state = state.copyWith(exam: exam, isLoading: false);
      return exam;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> updateExam(Map<String, dynamic> data) async {
    if (state.exam == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final exam = await _repository.updateExam(state.exam!.id, data);
      state = state.copyWith(exam: exam, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addSection({
    required String title,
    String? description,
    double marksPerQuestion = 1,
    double negativeMarks = 0,
    int? durationMinutes,
    bool isOptional = false,
  }) async {
    if (state.exam == null) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.createSection({
        'exam_id': state.exam!.id,
        'title': title,
        'description': description,
        'sequence_order': state.sections.length + 1,
        'marks_per_question': marksPerQuestion,
        'negative_marks': negativeMarks,
        'section_duration_minutes': durationMinutes,
        'is_optional': isOptional,
      });
      await loadExam(state.exam!.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteSection(String sectionId) async {
    if (state.exam == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteSection(sectionId);
      await loadExam(state.exam!.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addQuestion(String sectionId, Map<String, dynamic> data) async {
    if (state.exam == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      data['section_id'] = sectionId;
      data['sequence_order'] =
          (state.sectionQuestions[sectionId]?.length ?? 0) + 1;
      await _repository.createQuestion(data);
      await loadExam(state.exam!.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addQuestionsFromBank(
      String sectionId, List<String> bankIds) async {
    if (state.exam == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.addQuestionsFromBank(sectionId, bankIds);
      await loadExam(state.exam!.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    if (state.exam == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteQuestion(questionId);
      await loadExam(state.exam!.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> publishExam() async {
    if (state.exam == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateExamStatus(state.exam!.id, 'scheduled');
      await loadExam(state.exam!.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> goLive() async {
    if (state.exam == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateExamStatus(state.exam!.id, 'live');
      await loadExam(state.exam!.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> completeExam() async {
    if (state.exam == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateExamStatus(state.exam!.id, 'completed');
      await loadExam(state.exam!.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const ExamBuilderState();
  }
}

final examBuilderProvider =
    StateNotifierProvider<ExamBuilderNotifier, ExamBuilderState>((ref) {
  final repo = ref.watch(onlineExamRepositoryProvider);
  return ExamBuilderNotifier(repo);
});

// ==================== GRADING NOTIFIER ====================

class GradingState {
  final ExamAttempt? attempt;
  final List<ExamResponse> responses;
  final Map<String, List<ExamQuestion>> sectionQuestions;
  final bool isLoading;
  final String? error;

  const GradingState({
    this.attempt,
    this.responses = const [],
    this.sectionQuestions = const {},
    this.isLoading = false,
    this.error,
  });

  GradingState copyWith({
    ExamAttempt? attempt,
    List<ExamResponse>? responses,
    Map<String, List<ExamQuestion>>? sectionQuestions,
    bool? isLoading,
    String? error,
  }) {
    return GradingState(
      attempt: attempt ?? this.attempt,
      responses: responses ?? this.responses,
      sectionQuestions: sectionQuestions ?? this.sectionQuestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<ExamResponse> get subjectiveResponses {
    return responses.where((r) {
      final q = r.question;
      return q != null && !q.isAutoGradable;
    }).toList();
  }

  bool get allGraded {
    return subjectiveResponses.every(
        (r) => r.marksAwarded > 0 || r.isCorrect != null);
  }
}

class GradingNotifier extends StateNotifier<GradingState> {
  final OnlineExamRepository _repository;

  GradingNotifier(this._repository) : super(const GradingState());

  Future<void> loadAttempt(String attemptId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final attempt = await _repository.getAttemptById(attemptId);
      if (attempt == null) throw Exception('Attempt not found');

      final responses = await _repository.getAttemptResponses(attemptId);
      final exam = await _repository.getExamById(attempt.examId);
      final sections =
          exam != null ? await _repository.getExamSections(exam.id) : <ExamSection>[];
      final sectionQuestions = <String, List<ExamQuestion>>{};
      for (final s in sections) {
        sectionQuestions[s.id] =
            s.questions ?? await _repository.getSectionQuestions(s.id);
      }

      state = state.copyWith(
        attempt: attempt,
        responses: responses,
        sectionQuestions: sectionQuestions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> gradeResponse(
      String responseId, double marks, bool isCorrect) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.gradeResponse(responseId,
          marks: marks, isCorrect: isCorrect);
      if (state.attempt != null) {
        await loadAttempt(state.attempt!.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ExamAttempt?> finalizeGrading() async {
    if (state.attempt == null) return null;
    state = state.copyWith(isLoading: true);
    try {
      final result =
          await _repository.finalizeGrading(state.attempt!.id);
      state = state.copyWith(attempt: result, isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final gradingProvider =
    StateNotifierProvider<GradingNotifier, GradingState>((ref) {
  final repo = ref.watch(onlineExamRepositoryProvider);
  return GradingNotifier(repo);
});
