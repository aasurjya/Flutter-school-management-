import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/quiz.dart';
import '../../../data/repositories/assessment_repository.dart';

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepository(ref.watch(supabaseProvider));
});

// ==================== QUIZ PROVIDERS ====================

final quizzesProvider = FutureProvider.family<List<Quiz>, QuizzesFilter>(
  (ref, filter) async {
    final repository = ref.watch(assessmentRepositoryProvider);
    return repository.getQuizzes(
      subjectId: filter.subjectId,
      sectionId: filter.sectionId,
      status: filter.status,
      createdBy: filter.createdBy,
    );
  },
);

final quizByIdProvider = FutureProvider.family<Quiz?, String>(
  (ref, quizId) async {
    final repository = ref.watch(assessmentRepositoryProvider);
    return repository.getQuizById(quizId);
  },
);

final quizQuestionsProvider = FutureProvider.family<List<QuizQuestion>, String>(
  (ref, quizId) async {
    final repository = ref.watch(assessmentRepositoryProvider);
    return repository.getQuizQuestions(quizId);
  },
);

final quizStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, quizId) async {
    final repository = ref.watch(assessmentRepositoryProvider);
    return repository.getQuizStatistics(quizId);
  },
);

// ==================== QUESTION BANK PROVIDERS ====================

final questionBankProvider =
    FutureProvider.family<List<QuestionBank>, QuestionBankFilter>(
  (ref, filter) async {
    final repository = ref.watch(assessmentRepositoryProvider);
    return repository.getQuestionBank(
      subjectId: filter.subjectId,
      questionType: filter.questionType,
      difficulty: filter.difficulty,
      chapter: filter.chapter,
      searchQuery: filter.searchQuery,
    );
  },
);

final questionByIdProvider = FutureProvider.family<QuestionBank?, String>(
  (ref, questionId) async {
    final repository = ref.watch(assessmentRepositoryProvider);
    return repository.getQuestionById(questionId);
  },
);

// ==================== ATTEMPT PROVIDERS ====================

final quizAttemptsProvider =
    FutureProvider.family<List<QuizAttempt>, AttemptsFilter>(
  (ref, filter) async {
    final repository = ref.watch(assessmentRepositoryProvider);
    return repository.getQuizAttempts(
      quizId: filter.quizId,
      studentId: filter.studentId,
      status: filter.status,
    );
  },
);

final attemptByIdProvider = FutureProvider.family<QuizAttempt?, String>(
  (ref, attemptId) async {
    final repository = ref.watch(assessmentRepositoryProvider);
    return repository.getAttemptById(attemptId);
  },
);

final studentAvailableQuizzesProvider =
    FutureProvider.family<List<Quiz>, String>(
  (ref, studentId) async {
    final repository = ref.watch(assessmentRepositoryProvider);
    return repository.getStudentAvailableQuizzes(studentId);
  },
);

// ==================== FILTER CLASSES ====================

class QuizzesFilter {
  final String? subjectId;
  final String? sectionId;
  final String? status;
  final String? createdBy;

  const QuizzesFilter({
    this.subjectId,
    this.sectionId,
    this.status,
    this.createdBy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizzesFilter &&
          other.subjectId == subjectId &&
          other.sectionId == sectionId &&
          other.status == status &&
          other.createdBy == createdBy;

  @override
  int get hashCode => Object.hash(subjectId, sectionId, status, createdBy);
}

class QuestionBankFilter {
  final String? subjectId;
  final String? questionType;
  final String? difficulty;
  final String? chapter;
  final String? searchQuery;

  const QuestionBankFilter({
    this.subjectId,
    this.questionType,
    this.difficulty,
    this.chapter,
    this.searchQuery,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionBankFilter &&
          other.subjectId == subjectId &&
          other.questionType == questionType &&
          other.difficulty == difficulty &&
          other.chapter == chapter &&
          other.searchQuery == searchQuery;

  @override
  int get hashCode =>
      Object.hash(subjectId, questionType, difficulty, chapter, searchQuery);
}

class AttemptsFilter {
  final String? quizId;
  final String? studentId;
  final String? status;

  const AttemptsFilter({
    this.quizId,
    this.studentId,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttemptsFilter &&
          other.quizId == quizId &&
          other.studentId == studentId &&
          other.status == status;

  @override
  int get hashCode => Object.hash(quizId, studentId, status);
}

// ==================== QUIZ SESSION NOTIFIER ====================

class QuizSessionNotifier extends StateNotifier<AsyncValue<QuizSession?>> {
  final AssessmentRepository _repository;
  Timer? _timer;

  QuizSessionNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> startQuiz(String quizId, String studentId) async {
    state = const AsyncValue.loading();

    try {
      // Get quiz details
      final quiz = await _repository.getQuizById(quizId);
      if (quiz == null) throw Exception('Quiz not found');

      // Check if quiz is active
      if (!quiz.isActive) throw Exception('Quiz is not available');

      // Start or resume attempt
      final attempt = await _repository.startQuizAttempt(quizId, studentId);

      // Get questions
      var questions = await _repository.getQuizQuestions(quizId);

      // Shuffle if needed
      if (quiz.shuffleQuestions) {
        questions = List.from(questions)..shuffle();
      }

      // Calculate remaining time
      final elapsedSeconds = DateTime.now().difference(attempt.startedAt).inSeconds;
      final remainingSeconds = (quiz.durationMinutes * 60) - elapsedSeconds;

      // Initialize answers from existing attempt
      final currentAnswers = <String, String?>{};
      for (final question in questions) {
        currentAnswers[question.id] = attempt.answers?[question.id] as String?;
      }

      state = AsyncValue.data(QuizSession(
        quiz: quiz,
        questions: questions,
        attempt: attempt,
        currentAnswers: currentAnswers,
        currentQuestionIndex: 0,
        startTime: attempt.startedAt,
        remainingSeconds: remainingSeconds > 0 ? remainingSeconds : 0,
      ));

      // Start timer
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
          submitQuiz();
        } else {
          state = AsyncValue.data(
            session.copyWith(remainingSeconds: session.remainingSeconds - 1),
          );
        }
      }
    });
  }

  void answerQuestion(String questionId, String? answer) {
    final session = state.value;
    if (session == null) return;

    final newAnswers = Map<String, String?>.from(session.currentAnswers);
    newAnswers[questionId] = answer;

    state = AsyncValue.data(session.copyWith(currentAnswers: newAnswers));

    // Save to database
    _repository.saveAnswer(session.attempt.id, questionId, answer);
  }

  void goToQuestion(int index) {
    final session = state.value;
    if (session == null) return;

    if (index >= 0 && index < session.questions.length) {
      state = AsyncValue.data(session.copyWith(currentQuestionIndex: index));
    }
  }

  void nextQuestion() {
    final session = state.value;
    if (session == null || session.isLastQuestion) return;
    goToQuestion(session.currentQuestionIndex + 1);
  }

  void previousQuestion() {
    final session = state.value;
    if (session == null || session.isFirstQuestion) return;
    goToQuestion(session.currentQuestionIndex - 1);
  }

  Future<QuizAttempt?> submitQuiz() async {
    final session = state.value;
    if (session == null) return null;

    _timer?.cancel();

    try {
      // Save all current answers first
      for (final entry in session.currentAnswers.entries) {
        await _repository.saveAnswer(
          session.attempt.id,
          entry.key,
          entry.value,
        );
      }

      // Submit the attempt
      final result = await _repository.submitQuizAttempt(session.attempt.id);
      state = const AsyncValue.data(null);
      return result;
    } catch (e) {
      // Don't clear state on error, let user retry
      return null;
    }
  }

  void cancelQuiz() {
    _timer?.cancel();
    state = const AsyncValue.data(null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final quizSessionProvider =
    StateNotifierProvider<QuizSessionNotifier, AsyncValue<QuizSession?>>((ref) {
  final repository = ref.watch(assessmentRepositoryProvider);
  return QuizSessionNotifier(repository);
});

// ==================== QUIZ BUILDER NOTIFIER ====================

class QuizBuilderState {
  final Quiz? quiz;
  final List<QuizQuestion> questions;
  final List<String> selectedBankQuestions;
  final bool isLoading;
  final String? error;

  const QuizBuilderState({
    this.quiz,
    this.questions = const [],
    this.selectedBankQuestions = const [],
    this.isLoading = false,
    this.error,
  });

  QuizBuilderState copyWith({
    Quiz? quiz,
    List<QuizQuestion>? questions,
    List<String>? selectedBankQuestions,
    bool? isLoading,
    String? error,
  }) {
    return QuizBuilderState(
      quiz: quiz ?? this.quiz,
      questions: questions ?? this.questions,
      selectedBankQuestions: selectedBankQuestions ?? this.selectedBankQuestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class QuizBuilderNotifier extends StateNotifier<QuizBuilderState> {
  final AssessmentRepository _repository;

  QuizBuilderNotifier(this._repository) : super(const QuizBuilderState());

  Future<void> loadQuiz(String quizId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final quiz = await _repository.getQuizById(quizId);
      final questions = await _repository.getQuizQuestions(quizId);

      state = state.copyWith(
        quiz: quiz,
        questions: questions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Quiz?> createQuiz(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final quiz = await _repository.createQuiz(data);
      state = state.copyWith(quiz: quiz, isLoading: false);
      return quiz;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> updateQuiz(Map<String, dynamic> data) async {
    if (state.quiz == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final quiz = await _repository.updateQuiz(state.quiz!.id, data);
      state = state.copyWith(quiz: quiz, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleBankQuestion(String questionId) {
    final selected = List<String>.from(state.selectedBankQuestions);
    if (selected.contains(questionId)) {
      selected.remove(questionId);
    } else {
      selected.add(questionId);
    }
    state = state.copyWith(selectedBankQuestions: selected);
  }

  Future<void> addSelectedQuestions() async {
    if (state.quiz == null || state.selectedBankQuestions.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.addQuestionsFromBank(
        state.quiz!.id,
        state.selectedBankQuestions,
      );
      final questions = await _repository.getQuizQuestions(state.quiz!.id);
      final quiz = await _repository.getQuizById(state.quiz!.id);

      state = state.copyWith(
        quiz: quiz,
        questions: questions,
        selectedBankQuestions: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addCustomQuestion({
    required String questionType,
    required String questionText,
    Map<String, dynamic>? options,
    String? correctAnswer,
    String? explanation,
    required int marks,
  }) async {
    if (state.quiz == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.addQuestionToQuiz(
        quizId: state.quiz!.id,
        sequenceOrder: state.questions.length + 1,
        questionType: questionType,
        questionText: questionText,
        options: options,
        correctAnswer: correctAnswer,
        explanation: explanation,
        marks: marks,
      );

      final questions = await _repository.getQuizQuestions(state.quiz!.id);
      final quiz = await _repository.getQuizById(state.quiz!.id);

      state = state.copyWith(
        quiz: quiz,
        questions: questions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeQuestion(String quizQuestionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.removeQuestionFromQuiz(quizQuestionId);
      final questions = await _repository.getQuizQuestions(state.quiz!.id);
      final quiz = await _repository.getQuizById(state.quiz!.id);

      state = state.copyWith(
        quiz: quiz,
        questions: questions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> publishQuiz() async {
    if (state.quiz == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.publishQuiz(state.quiz!.id);
      final quiz = await _repository.getQuizById(state.quiz!.id);
      state = state.copyWith(quiz: quiz, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const QuizBuilderState();
  }
}

final quizBuilderProvider =
    StateNotifierProvider<QuizBuilderNotifier, QuizBuilderState>((ref) {
  final repository = ref.watch(assessmentRepositoryProvider);
  return QuizBuilderNotifier(repository);
});
