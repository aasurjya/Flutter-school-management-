// Quiz and Assessment Models

class Quiz {
  final String id;
  final String tenantId;
  final String title;
  final String? description;
  final String subjectId;
  final String sectionId;
  final String createdBy;
  final String status; // draft, published, closed
  final int durationMinutes;
  final int totalMarks;
  final int passingMarks;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool showResults;
  final bool allowReview;
  final int? maxAttempts;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? subjectName;
  final String? sectionName;
  final String? className;
  final String? creatorName;
  final int? questionCount;
  final int? attemptCount;

  const Quiz({
    required this.id,
    required this.tenantId,
    required this.title,
    this.description,
    required this.subjectId,
    required this.sectionId,
    required this.createdBy,
    required this.status,
    required this.durationMinutes,
    required this.totalMarks,
    required this.passingMarks,
    this.startTime,
    this.endTime,
    this.shuffleQuestions = true,
    this.shuffleOptions = true,
    this.showResults = true,
    this.allowReview = false,
    this.maxAttempts,
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
    this.sectionName,
    this.className,
    this.creatorName,
    this.questionCount,
    this.attemptCount,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      tenantId: json['tenant_id'],
      title: json['title'],
      description: json['description'],
      subjectId: json['subject_id'],
      sectionId: json['section_id'],
      createdBy: json['created_by'],
      status: json['status'] ?? 'draft',
      durationMinutes: json['duration_minutes'] ?? 30,
      totalMarks: json['total_marks'] ?? 0,
      passingMarks: json['passing_marks'] ?? 0,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      shuffleQuestions: json['shuffle_questions'] ?? true,
      shuffleOptions: json['shuffle_options'] ?? true,
      showResults: json['show_results'] ?? true,
      allowReview: json['allow_review'] ?? false,
      maxAttempts: json['max_attempts'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      subjectName: json['subject']?['name'] ?? json['subject_name'],
      sectionName: json['section']?['name'] ?? json['section_name'],
      className: json['section']?['class']?['name'] ?? json['class_name'],
      creatorName: json['creator']?['full_name'] ?? json['creator_name'],
      questionCount: json['question_count'],
      attemptCount: json['attempt_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'section_id': sectionId,
      'created_by': createdBy,
      'status': status,
      'duration_minutes': durationMinutes,
      'total_marks': totalMarks,
      'passing_marks': passingMarks,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'shuffle_questions': shuffleQuestions,
      'shuffle_options': shuffleOptions,
      'show_results': showResults,
      'allow_review': allowReview,
      'max_attempts': maxAttempts,
    };
  }

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isClosed => status == 'closed';

  bool get isActive {
    if (!isPublished) return false;
    final now = DateTime.now();
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    return true;
  }

  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'published':
        return 'Published';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }
}

class QuestionBank {
  final String id;
  final String tenantId;
  final String subjectId;
  final String? chapter;
  final String? topic;
  final String questionType; // mcq, true_false, short_answer, long_answer
  final String questionText;
  final Map<String, dynamic>? options; // For MCQ: {A: 'text', B: 'text', ...}
  final String? correctAnswer;
  final String? explanation;
  final int marks;
  final String difficulty; // easy, medium, hard
  final List<String>? tags;
  final String createdBy;
  final DateTime createdAt;

  // Joined data
  final String? subjectName;

  const QuestionBank({
    required this.id,
    required this.tenantId,
    required this.subjectId,
    this.chapter,
    this.topic,
    required this.questionType,
    required this.questionText,
    this.options,
    this.correctAnswer,
    this.explanation,
    required this.marks,
    required this.difficulty,
    this.tags,
    required this.createdBy,
    required this.createdAt,
    this.subjectName,
  });

  factory QuestionBank.fromJson(Map<String, dynamic> json) {
    return QuestionBank(
      id: json['id'],
      tenantId: json['tenant_id'],
      subjectId: json['subject_id'],
      chapter: json['chapter'],
      topic: json['topic'],
      questionType: json['question_type'],
      questionText: json['question_text'],
      options: json['options'],
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
      marks: json['marks'] ?? 1,
      difficulty: json['difficulty'] ?? 'medium',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      subjectName: json['subject']?['name'] ?? json['subject_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'subject_id': subjectId,
      'chapter': chapter,
      'topic': topic,
      'question_type': questionType,
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'marks': marks,
      'difficulty': difficulty,
      'tags': tags,
      'created_by': createdBy,
    };
  }

  String get questionTypeDisplay {
    switch (questionType) {
      case 'mcq':
        return 'Multiple Choice';
      case 'true_false':
        return 'True/False';
      case 'short_answer':
        return 'Short Answer';
      case 'long_answer':
        return 'Long Answer';
      default:
        return questionType;
    }
  }

  String get difficultyDisplay {
    switch (difficulty) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return difficulty;
    }
  }

  List<String> get optionKeys {
    if (options == null) return [];
    return options!.keys.toList()..sort();
  }

  bool get isAutoGradable =>
      questionType == 'mcq' || questionType == 'true_false';
}

class QuizQuestion {
  final String id;
  final String quizId;
  final String? questionBankId;
  final int sequenceOrder;
  final String questionType;
  final String questionText;
  final Map<String, dynamic>? options;
  final String? correctAnswer;
  final String? explanation;
  final int marks;

  // Joined data
  final QuestionBank? bankQuestion;

  const QuizQuestion({
    required this.id,
    required this.quizId,
    this.questionBankId,
    required this.sequenceOrder,
    required this.questionType,
    required this.questionText,
    this.options,
    this.correctAnswer,
    this.explanation,
    required this.marks,
    this.bankQuestion,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      quizId: json['quiz_id'],
      questionBankId: json['question_bank_id'],
      sequenceOrder: json['sequence_order'] ?? 0,
      questionType: json['question_type'],
      questionText: json['question_text'],
      options: json['options'],
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
      marks: json['marks'] ?? 1,
      bankQuestion: json['question_bank'] != null
          ? QuestionBank.fromJson(json['question_bank'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quiz_id': quizId,
      'question_bank_id': questionBankId,
      'sequence_order': sequenceOrder,
      'question_type': questionType,
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'marks': marks,
    };
  }

  List<String> get optionKeys {
    if (options == null) return [];
    return options!.keys.toList()..sort();
  }

  bool get isAutoGradable =>
      questionType == 'mcq' || questionType == 'true_false';
}

class QuizAttempt {
  final String id;
  final String tenantId;
  final String quizId;
  final String studentId;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final int? totalMarks;
  final int? obtainedMarks;
  final double? percentage;
  final bool isPassed;
  final String status; // in_progress, submitted, graded
  final Map<String, dynamic>? answers; // {questionId: answer}
  final Map<String, dynamic>? feedback; // {questionId: {marks, feedback}}

  // Joined data
  final String? quizTitle;
  final String? studentName;

  const QuizAttempt({
    required this.id,
    required this.tenantId,
    required this.quizId,
    required this.studentId,
    required this.startedAt,
    this.submittedAt,
    this.totalMarks,
    this.obtainedMarks,
    this.percentage,
    this.isPassed = false,
    required this.status,
    this.answers,
    this.feedback,
    this.quizTitle,
    this.studentName,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      tenantId: json['tenant_id'],
      quizId: json['quiz_id'],
      studentId: json['student_id'],
      startedAt: DateTime.parse(json['started_at']),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
      totalMarks: json['total_marks'],
      obtainedMarks: json['obtained_marks'],
      percentage: (json['percentage'] as num?)?.toDouble(),
      isPassed: json['is_passed'] ?? false,
      status: json['status'] ?? 'in_progress',
      answers: json['answers'],
      feedback: json['feedback'],
      quizTitle: json['quiz']?['title'] ?? json['quiz_title'],
      studentName: json['student']?['first_name'] ?? json['student_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'quiz_id': quizId,
      'student_id': studentId,
      'started_at': startedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'total_marks': totalMarks,
      'obtained_marks': obtainedMarks,
      'percentage': percentage,
      'is_passed': isPassed,
      'status': status,
      'answers': answers,
      'feedback': feedback,
    };
  }

  bool get isInProgress => status == 'in_progress';
  bool get isSubmitted => status == 'submitted';
  bool get isGraded => status == 'graded';

  String get statusDisplay {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'submitted':
        return 'Submitted';
      case 'graded':
        return 'Graded';
      default:
        return status;
    }
  }

  Duration? get duration {
    if (submittedAt == null) return null;
    return submittedAt!.difference(startedAt);
  }

  String? get durationDisplay {
    final d = duration;
    if (d == null) return null;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

// For quiz-taking state
class QuizSession {
  final Quiz quiz;
  final List<QuizQuestion> questions;
  final QuizAttempt attempt;
  final Map<String, String?> currentAnswers;
  final int currentQuestionIndex;
  final DateTime startTime;
  final int remainingSeconds;

  const QuizSession({
    required this.quiz,
    required this.questions,
    required this.attempt,
    required this.currentAnswers,
    this.currentQuestionIndex = 0,
    required this.startTime,
    required this.remainingSeconds,
  });

  QuizSession copyWith({
    Quiz? quiz,
    List<QuizQuestion>? questions,
    QuizAttempt? attempt,
    Map<String, String?>? currentAnswers,
    int? currentQuestionIndex,
    DateTime? startTime,
    int? remainingSeconds,
  }) {
    return QuizSession(
      quiz: quiz ?? this.quiz,
      questions: questions ?? this.questions,
      attempt: attempt ?? this.attempt,
      currentAnswers: currentAnswers ?? this.currentAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      startTime: startTime ?? this.startTime,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }

  QuizQuestion get currentQuestion => questions[currentQuestionIndex];
  bool get isFirstQuestion => currentQuestionIndex == 0;
  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;
  int get answeredCount =>
      currentAnswers.values.where((v) => v != null && v.isNotEmpty).length;
  int get totalQuestions => questions.length;
  double get progress => answeredCount / totalQuestions;

  String get timerDisplay {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isTimeUp => remainingSeconds <= 0;
}
