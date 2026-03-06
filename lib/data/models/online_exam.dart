/// Online Examination System models

// ============================================
// ENUMS
// ============================================

enum OnlineExamType {
  classTest,
  unitTest,
  midTerm,
  finalExam,
  competitive,
  practice;

  String get value {
    switch (this) {
      case OnlineExamType.classTest:
        return 'class_test';
      case OnlineExamType.unitTest:
        return 'unit_test';
      case OnlineExamType.midTerm:
        return 'mid_term';
      case OnlineExamType.finalExam:
        return 'final';
      case OnlineExamType.competitive:
        return 'competitive';
      case OnlineExamType.practice:
        return 'practice';
    }
  }

  String get label {
    switch (this) {
      case OnlineExamType.classTest:
        return 'Class Test';
      case OnlineExamType.unitTest:
        return 'Unit Test';
      case OnlineExamType.midTerm:
        return 'Mid Term';
      case OnlineExamType.finalExam:
        return 'Final Exam';
      case OnlineExamType.competitive:
        return 'Competitive';
      case OnlineExamType.practice:
        return 'Practice';
    }
  }

  static OnlineExamType fromString(String value) {
    switch (value) {
      case 'class_test':
        return OnlineExamType.classTest;
      case 'unit_test':
        return OnlineExamType.unitTest;
      case 'mid_term':
        return OnlineExamType.midTerm;
      case 'final':
        return OnlineExamType.finalExam;
      case 'competitive':
        return OnlineExamType.competitive;
      case 'practice':
        return OnlineExamType.practice;
      default:
        return OnlineExamType.classTest;
    }
  }
}

enum OnlineExamStatus {
  draft,
  scheduled,
  live,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case OnlineExamStatus.draft:
        return 'draft';
      case OnlineExamStatus.scheduled:
        return 'scheduled';
      case OnlineExamStatus.live:
        return 'live';
      case OnlineExamStatus.completed:
        return 'completed';
      case OnlineExamStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OnlineExamStatus.draft:
        return 'Draft';
      case OnlineExamStatus.scheduled:
        return 'Scheduled';
      case OnlineExamStatus.live:
        return 'Live';
      case OnlineExamStatus.completed:
        return 'Completed';
      case OnlineExamStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OnlineExamStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return OnlineExamStatus.draft;
      case 'scheduled':
        return OnlineExamStatus.scheduled;
      case 'live':
        return OnlineExamStatus.live;
      case 'completed':
        return OnlineExamStatus.completed;
      case 'cancelled':
        return OnlineExamStatus.cancelled;
      default:
        return OnlineExamStatus.draft;
    }
  }
}

enum ExamQuestionType {
  mcq,
  multiSelect,
  trueFalse,
  fillBlank,
  shortAnswer,
  longAnswer,
  matchPairs,
  ordering;

  String get value {
    switch (this) {
      case ExamQuestionType.mcq:
        return 'mcq';
      case ExamQuestionType.multiSelect:
        return 'multi_select';
      case ExamQuestionType.trueFalse:
        return 'true_false';
      case ExamQuestionType.fillBlank:
        return 'fill_blank';
      case ExamQuestionType.shortAnswer:
        return 'short_answer';
      case ExamQuestionType.longAnswer:
        return 'long_answer';
      case ExamQuestionType.matchPairs:
        return 'match_pairs';
      case ExamQuestionType.ordering:
        return 'ordering';
    }
  }

  String get label {
    switch (this) {
      case ExamQuestionType.mcq:
        return 'Multiple Choice';
      case ExamQuestionType.multiSelect:
        return 'Multi Select';
      case ExamQuestionType.trueFalse:
        return 'True / False';
      case ExamQuestionType.fillBlank:
        return 'Fill in the Blank';
      case ExamQuestionType.shortAnswer:
        return 'Short Answer';
      case ExamQuestionType.longAnswer:
        return 'Long Answer';
      case ExamQuestionType.matchPairs:
        return 'Match Pairs';
      case ExamQuestionType.ordering:
        return 'Ordering';
    }
  }

  bool get isAutoGradable {
    switch (this) {
      case ExamQuestionType.mcq:
      case ExamQuestionType.multiSelect:
      case ExamQuestionType.trueFalse:
      case ExamQuestionType.fillBlank:
      case ExamQuestionType.ordering:
        return true;
      case ExamQuestionType.shortAnswer:
      case ExamQuestionType.longAnswer:
      case ExamQuestionType.matchPairs:
        return false;
    }
  }

  static ExamQuestionType fromString(String value) {
    switch (value) {
      case 'mcq':
        return ExamQuestionType.mcq;
      case 'multi_select':
        return ExamQuestionType.multiSelect;
      case 'true_false':
        return ExamQuestionType.trueFalse;
      case 'fill_blank':
        return ExamQuestionType.fillBlank;
      case 'short_answer':
        return ExamQuestionType.shortAnswer;
      case 'long_answer':
        return ExamQuestionType.longAnswer;
      case 'match_pairs':
        return ExamQuestionType.matchPairs;
      case 'ordering':
        return ExamQuestionType.ordering;
      default:
        return ExamQuestionType.mcq;
    }
  }
}

enum ExamDifficulty {
  easy,
  medium,
  hard;

  String get value => name;

  String get label {
    switch (this) {
      case ExamDifficulty.easy:
        return 'Easy';
      case ExamDifficulty.medium:
        return 'Medium';
      case ExamDifficulty.hard:
        return 'Hard';
    }
  }

  static ExamDifficulty fromString(String value) {
    switch (value) {
      case 'easy':
        return ExamDifficulty.easy;
      case 'medium':
        return ExamDifficulty.medium;
      case 'hard':
        return ExamDifficulty.hard;
      default:
        return ExamDifficulty.medium;
    }
  }
}

enum ExamAttemptStatus {
  inProgress,
  submitted,
  autoSubmitted,
  underReview,
  graded;

  String get value {
    switch (this) {
      case ExamAttemptStatus.inProgress:
        return 'in_progress';
      case ExamAttemptStatus.submitted:
        return 'submitted';
      case ExamAttemptStatus.autoSubmitted:
        return 'auto_submitted';
      case ExamAttemptStatus.underReview:
        return 'under_review';
      case ExamAttemptStatus.graded:
        return 'graded';
    }
  }

  String get label {
    switch (this) {
      case ExamAttemptStatus.inProgress:
        return 'In Progress';
      case ExamAttemptStatus.submitted:
        return 'Submitted';
      case ExamAttemptStatus.autoSubmitted:
        return 'Auto Submitted';
      case ExamAttemptStatus.underReview:
        return 'Under Review';
      case ExamAttemptStatus.graded:
        return 'Graded';
    }
  }

  static ExamAttemptStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return ExamAttemptStatus.inProgress;
      case 'submitted':
        return ExamAttemptStatus.submitted;
      case 'auto_submitted':
        return ExamAttemptStatus.autoSubmitted;
      case 'under_review':
        return ExamAttemptStatus.underReview;
      case 'graded':
        return ExamAttemptStatus.graded;
      default:
        return ExamAttemptStatus.inProgress;
    }
  }
}

// ============================================
// SETTINGS MODEL
// ============================================

class ExamSettings {
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool showResultImmediately;
  final bool allowReview;
  final double negativeMarkingValue;
  final int maxAttempts;
  final bool proctoringEnabled;
  final bool fullscreenRequired;
  final int tabSwitchLimit;

  const ExamSettings({
    this.shuffleQuestions = true,
    this.shuffleOptions = true,
    this.showResultImmediately = true,
    this.allowReview = false,
    this.negativeMarkingValue = 0,
    this.maxAttempts = 1,
    this.proctoringEnabled = false,
    this.fullscreenRequired = false,
    this.tabSwitchLimit = 0,
  });

  factory ExamSettings.fromJson(Map<String, dynamic> json) {
    return ExamSettings(
      shuffleQuestions: json['shuffle_questions'] ?? true,
      shuffleOptions: json['shuffle_options'] ?? true,
      showResultImmediately: json['show_result_immediately'] ?? true,
      allowReview: json['allow_review'] ?? false,
      negativeMarkingValue:
          (json['negative_marking_value'] as num?)?.toDouble() ?? 0,
      maxAttempts: json['max_attempts'] ?? 1,
      proctoringEnabled: json['proctoring_enabled'] ?? false,
      fullscreenRequired: json['fullscreen_required'] ?? false,
      tabSwitchLimit: json['tab_switch_limit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shuffle_questions': shuffleQuestions,
      'shuffle_options': shuffleOptions,
      'show_result_immediately': showResultImmediately,
      'allow_review': allowReview,
      'negative_marking_value': negativeMarkingValue,
      'max_attempts': maxAttempts,
      'proctoring_enabled': proctoringEnabled,
      'fullscreen_required': fullscreenRequired,
      'tab_switch_limit': tabSwitchLimit,
    };
  }

  ExamSettings copyWith({
    bool? shuffleQuestions,
    bool? shuffleOptions,
    bool? showResultImmediately,
    bool? allowReview,
    double? negativeMarkingValue,
    int? maxAttempts,
    bool? proctoringEnabled,
    bool? fullscreenRequired,
    int? tabSwitchLimit,
  }) {
    return ExamSettings(
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      shuffleOptions: shuffleOptions ?? this.shuffleOptions,
      showResultImmediately:
          showResultImmediately ?? this.showResultImmediately,
      allowReview: allowReview ?? this.allowReview,
      negativeMarkingValue:
          negativeMarkingValue ?? this.negativeMarkingValue,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      proctoringEnabled: proctoringEnabled ?? this.proctoringEnabled,
      fullscreenRequired: fullscreenRequired ?? this.fullscreenRequired,
      tabSwitchLimit: tabSwitchLimit ?? this.tabSwitchLimit,
    );
  }
}

// ============================================
// MODEL CLASSES
// ============================================

/// Online Exam model
class OnlineExam {
  final String id;
  final String tenantId;
  final String title;
  final String? description;
  final OnlineExamType examType;
  final String subjectId;
  final String classId;
  final List<String> sectionIds;
  final String createdBy;
  final double totalMarks;
  final double passingMarks;
  final int durationMinutes;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? instructions;
  final ExamSettings settings;
  final OnlineExamStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? subjectName;
  final String? className;
  final String? creatorName;
  final List<ExamSection>? sections;
  final int? attemptCount;
  final int? questionCount;

  const OnlineExam({
    required this.id,
    required this.tenantId,
    required this.title,
    this.description,
    required this.examType,
    required this.subjectId,
    required this.classId,
    this.sectionIds = const [],
    required this.createdBy,
    required this.totalMarks,
    required this.passingMarks,
    required this.durationMinutes,
    this.startTime,
    this.endTime,
    this.instructions,
    this.settings = const ExamSettings(),
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
    this.className,
    this.creatorName,
    this.sections,
    this.attemptCount,
    this.questionCount,
  });

  factory OnlineExam.fromJson(Map<String, dynamic> json) {
    List<String> sectionIds = [];
    if (json['section_ids'] != null) {
      if (json['section_ids'] is List) {
        sectionIds =
            (json['section_ids'] as List).map((e) => e.toString()).toList();
      }
    }

    final settingsRaw = json['settings'];
    final settings = settingsRaw is Map<String, dynamic>
        ? ExamSettings.fromJson(settingsRaw)
        : const ExamSettings();

    String? subjectName;
    if (json['subjects'] != null) {
      subjectName = json['subjects']['name'];
    } else {
      subjectName = json['subject_name'];
    }

    String? className;
    if (json['classes'] != null) {
      className = json['classes']['name'];
    } else {
      className = json['class_name'];
    }

    String? creatorName;
    if (json['users'] != null) {
      creatorName = json['users']['full_name'];
    } else {
      creatorName = json['creator_name'];
    }

    List<ExamSection>? sections;
    if (json['exam_sections'] != null && json['exam_sections'] is List) {
      sections = (json['exam_sections'] as List)
          .map((s) => ExamSection.fromJson(s))
          .toList();
    }

    return OnlineExam(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      examType: OnlineExamType.fromString(json['exam_type'] ?? 'class_test'),
      subjectId: json['subject_id'] ?? '',
      classId: json['class_id'] ?? '',
      sectionIds: sectionIds,
      createdBy: json['created_by'] ?? '',
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0,
      passingMarks: (json['passing_marks'] as num?)?.toDouble() ?? 0,
      durationMinutes: json['duration_minutes'] ?? 60,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      instructions: json['instructions'],
      settings: settings,
      status: OnlineExamStatus.fromString(json['status'] ?? 'draft'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      subjectName: subjectName,
      className: className,
      creatorName: creatorName,
      sections: sections,
      attemptCount: json['attempt_count'],
      questionCount: json['question_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'exam_type': examType.value,
      'subject_id': subjectId,
      'class_id': classId,
      'section_ids': sectionIds,
      'created_by': createdBy,
      'total_marks': totalMarks,
      'passing_marks': passingMarks,
      'duration_minutes': durationMinutes,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'instructions': instructions,
      'settings': settings.toJson(),
      'status': status.value,
    };
  }

  bool get isDraft => status == OnlineExamStatus.draft;
  bool get isScheduled => status == OnlineExamStatus.scheduled;
  bool get isLive => status == OnlineExamStatus.live;
  bool get isCompleted => status == OnlineExamStatus.completed;
  bool get isCancelled => status == OnlineExamStatus.cancelled;

  bool get isAvailable {
    if (!isLive && !isScheduled) return false;
    final now = DateTime.now();
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    return true;
  }

  String get durationDisplay {
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${durationMinutes}m';
  }

  double get passingPercentage =>
      totalMarks > 0 ? (passingMarks / totalMarks) * 100 : 0;
}

/// Exam Section model
class ExamSection {
  final String id;
  final String examId;
  final String title;
  final String? description;
  final int sequenceOrder;
  final int questionCount;
  final double marksPerQuestion;
  final double negativeMarks;
  final int? sectionDurationMinutes;
  final bool isOptional;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final List<ExamQuestion>? questions;

  const ExamSection({
    required this.id,
    required this.examId,
    required this.title,
    this.description,
    required this.sequenceOrder,
    this.questionCount = 0,
    this.marksPerQuestion = 1,
    this.negativeMarks = 0,
    this.sectionDurationMinutes,
    this.isOptional = false,
    required this.createdAt,
    required this.updatedAt,
    this.questions,
  });

  factory ExamSection.fromJson(Map<String, dynamic> json) {
    List<ExamQuestion>? questions;
    if (json['exam_questions'] != null && json['exam_questions'] is List) {
      questions = (json['exam_questions'] as List)
          .map((q) => ExamQuestion.fromJson(q))
          .toList();
    }

    return ExamSection(
      id: json['id'] ?? '',
      examId: json['exam_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      sequenceOrder: json['sequence_order'] ?? 1,
      questionCount: json['question_count'] ?? 0,
      marksPerQuestion:
          (json['marks_per_question'] as num?)?.toDouble() ?? 1,
      negativeMarks:
          (json['negative_marks'] as num?)?.toDouble() ?? 0,
      sectionDurationMinutes: json['section_duration_minutes'],
      isOptional: json['is_optional'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exam_id': examId,
      'title': title,
      'description': description,
      'sequence_order': sequenceOrder,
      'marks_per_question': marksPerQuestion,
      'negative_marks': negativeMarks,
      'section_duration_minutes': sectionDurationMinutes,
      'is_optional': isOptional,
    };
  }

  double get totalMarks => questionCount * marksPerQuestion;
}

/// Exam Question model
class ExamQuestion {
  final String id;
  final String sectionId;
  final String? questionBankId;
  final ExamQuestionType questionType;
  final String questionText;
  final Map<String, dynamic>? questionMedia;
  final List<dynamic> options;
  final dynamic correctAnswer;
  final double marks;
  final String? explanation;
  final ExamDifficulty difficulty;
  final int sequenceOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExamQuestion({
    required this.id,
    required this.sectionId,
    this.questionBankId,
    required this.questionType,
    required this.questionText,
    this.questionMedia,
    this.options = const [],
    this.correctAnswer,
    required this.marks,
    this.explanation,
    this.difficulty = ExamDifficulty.medium,
    required this.sequenceOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    List<dynamic> options = [];
    if (json['options'] != null) {
      if (json['options'] is List) {
        options = json['options'] as List;
      }
    }

    return ExamQuestion(
      id: json['id'] ?? '',
      sectionId: json['section_id'] ?? '',
      questionBankId: json['question_bank_id'],
      questionType:
          ExamQuestionType.fromString(json['question_type'] ?? 'mcq'),
      questionText: json['question_text'] ?? '',
      questionMedia: json['question_media'],
      options: options,
      correctAnswer: json['correct_answer'],
      marks: (json['marks'] as num?)?.toDouble() ?? 1,
      explanation: json['explanation'],
      difficulty:
          ExamDifficulty.fromString(json['difficulty'] ?? 'medium'),
      sequenceOrder: json['sequence_order'] ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section_id': sectionId,
      'question_bank_id': questionBankId,
      'question_type': questionType.value,
      'question_text': questionText,
      'question_media': questionMedia,
      'options': options,
      'correct_answer': correctAnswer,
      'marks': marks,
      'explanation': explanation,
      'difficulty': difficulty.value,
      'sequence_order': sequenceOrder,
    };
  }

  bool get isAutoGradable => questionType.isAutoGradable;

  /// Convenience: for MCQ, options are stored as
  /// [{"key": "A", "text": "Option text"}, ...] or {"A": "text", "B": "text"}
  List<MapEntry<String, String>> get optionEntries {
    final result = <MapEntry<String, String>>[];
    for (final opt in options) {
      if (opt is Map) {
        final key = opt['key']?.toString() ?? '';
        final text = opt['text']?.toString() ?? opt['value']?.toString() ?? '';
        result.add(MapEntry(key, text));
      }
    }
    if (result.isEmpty && correctAnswer is Map) {
      // Handle old format where options might be in correct_answer map
    }
    return result;
  }
}

/// Exam Attempt model
class ExamAttempt {
  final String id;
  final String tenantId;
  final String examId;
  final String studentId;
  final int attemptNumber;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final int? timeTakenSeconds;
  final double totalMarksObtained;
  final double percentage;
  final ExamAttemptStatus status;
  final List<dynamic> proctoringFlags;
  final String? ipAddress;
  final String? browserInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? examTitle;
  final String? studentName;
  final String? subjectName;
  final List<ExamResponse>? responses;

  const ExamAttempt({
    required this.id,
    required this.tenantId,
    required this.examId,
    required this.studentId,
    this.attemptNumber = 1,
    required this.startedAt,
    this.submittedAt,
    this.timeTakenSeconds,
    this.totalMarksObtained = 0,
    this.percentage = 0,
    required this.status,
    this.proctoringFlags = const [],
    this.ipAddress,
    this.browserInfo,
    required this.createdAt,
    required this.updatedAt,
    this.examTitle,
    this.studentName,
    this.subjectName,
    this.responses,
  });

  factory ExamAttempt.fromJson(Map<String, dynamic> json) {
    String? examTitle;
    if (json['online_exams'] != null) {
      examTitle = json['online_exams']['title'];
    } else {
      examTitle = json['exam_title'];
    }

    String? studentName;
    if (json['students'] != null) {
      final s = json['students'];
      studentName = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
    } else {
      studentName = json['student_name'];
    }

    List<ExamResponse>? responses;
    if (json['exam_responses'] != null && json['exam_responses'] is List) {
      responses = (json['exam_responses'] as List)
          .map((r) => ExamResponse.fromJson(r))
          .toList();
    }

    List<dynamic> flags = [];
    if (json['proctoring_flags'] != null &&
        json['proctoring_flags'] is List) {
      flags = json['proctoring_flags'] as List;
    }

    return ExamAttempt(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      examId: json['exam_id'] ?? '',
      studentId: json['student_id'] ?? '',
      attemptNumber: json['attempt_number'] ?? 1,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : DateTime.now(),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
      timeTakenSeconds: json['time_taken_seconds'],
      totalMarksObtained:
          (json['total_marks_obtained'] as num?)?.toDouble() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      status:
          ExamAttemptStatus.fromString(json['status'] ?? 'in_progress'),
      proctoringFlags: flags,
      ipAddress: json['ip_address'],
      browserInfo: json['browser_info'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      examTitle: examTitle,
      studentName: studentName,
      subjectName: json['subject_name'],
      responses: responses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'exam_id': examId,
      'student_id': studentId,
      'attempt_number': attemptNumber,
      'started_at': startedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'time_taken_seconds': timeTakenSeconds,
      'total_marks_obtained': totalMarksObtained,
      'percentage': percentage,
      'status': status.value,
      'proctoring_flags': proctoringFlags,
      'ip_address': ipAddress,
      'browser_info': browserInfo,
    };
  }

  bool get isInProgress => status == ExamAttemptStatus.inProgress;
  bool get isSubmitted => status == ExamAttemptStatus.submitted;
  bool get isGraded => status == ExamAttemptStatus.graded;
  bool get needsReview => status == ExamAttemptStatus.underReview;

  String get timeTakenDisplay {
    final seconds = timeTakenSeconds ?? 0;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remainMins = mins % 60;
      return '${hours}h ${remainMins}m';
    }
    return '${mins}m ${secs}s';
  }
}

/// Exam Response model (per question answer)
class ExamResponse {
  final String id;
  final String attemptId;
  final String questionId;
  final dynamic response;
  final bool? isCorrect;
  final double marksAwarded;
  final int timeSpentSeconds;
  final bool flaggedForReview;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final ExamQuestion? question;

  const ExamResponse({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.response,
    this.isCorrect,
    this.marksAwarded = 0,
    this.timeSpentSeconds = 0,
    this.flaggedForReview = false,
    required this.createdAt,
    required this.updatedAt,
    this.question,
  });

  factory ExamResponse.fromJson(Map<String, dynamic> json) {
    ExamQuestion? question;
    if (json['exam_questions'] != null) {
      question = ExamQuestion.fromJson(json['exam_questions']);
    }

    return ExamResponse(
      id: json['id'] ?? '',
      attemptId: json['attempt_id'] ?? '',
      questionId: json['question_id'] ?? '',
      response: json['response'],
      isCorrect: json['is_correct'],
      marksAwarded: (json['marks_awarded'] as num?)?.toDouble() ?? 0,
      timeSpentSeconds: json['time_spent_seconds'] ?? 0,
      flaggedForReview: json['flagged_for_review'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      question: question,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attempt_id': attemptId,
      'question_id': questionId,
      'response': response,
      'is_correct': isCorrect,
      'marks_awarded': marksAwarded,
      'time_spent_seconds': timeSpentSeconds,
      'flagged_for_review': flaggedForReview,
    };
  }
}

/// Exam Analytics aggregate
class ExamAnalytics {
  final String examId;
  final String examTitle;
  final double totalMarks;
  final int totalAttempts;
  final int uniqueStudents;
  final int gradedAttempts;
  final double avgScore;
  final double highestScore;
  final double lowestScore;
  final double avgPercentage;
  final int passCount;
  final int failCount;
  final int avgTimeSeconds;
  final int inProgressCount;

  const ExamAnalytics({
    required this.examId,
    this.examTitle = '',
    this.totalMarks = 0,
    this.totalAttempts = 0,
    this.uniqueStudents = 0,
    this.gradedAttempts = 0,
    this.avgScore = 0,
    this.highestScore = 0,
    this.lowestScore = 0,
    this.avgPercentage = 0,
    this.passCount = 0,
    this.failCount = 0,
    this.avgTimeSeconds = 0,
    this.inProgressCount = 0,
  });

  factory ExamAnalytics.fromJson(Map<String, dynamic> json) {
    return ExamAnalytics(
      examId: json['exam_id'] ?? '',
      examTitle: json['exam_title'] ?? '',
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0,
      totalAttempts: json['total_attempts'] ?? 0,
      uniqueStudents: json['unique_students'] ?? 0,
      gradedAttempts: json['graded_attempts'] ?? 0,
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0,
      highestScore: (json['highest_score'] as num?)?.toDouble() ?? 0,
      lowestScore: (json['lowest_score'] as num?)?.toDouble() ?? 0,
      avgPercentage: (json['avg_percentage'] as num?)?.toDouble() ?? 0,
      passCount: json['pass_count'] ?? 0,
      failCount: json['fail_count'] ?? 0,
      avgTimeSeconds: json['avg_time_seconds'] ?? 0,
      inProgressCount: json['in_progress_count'] ?? 0,
    );
  }

  double get passRate =>
      gradedAttempts > 0 ? (passCount / gradedAttempts) * 100 : 0;

  String get avgTimeDisplay {
    if (avgTimeSeconds <= 0) return 'N/A';
    final mins = avgTimeSeconds ~/ 60;
    return '${mins}m';
  }
}

/// Exam session state for taking exams
class OnlineExamSession {
  final OnlineExam exam;
  final List<ExamSection> sections;
  final Map<String, List<ExamQuestion>> sectionQuestions;
  final ExamAttempt attempt;
  final Map<String, dynamic> responses; // questionId -> response value
  final Set<String> flaggedQuestions;
  final int currentSectionIndex;
  final int currentQuestionIndex;
  final int remainingSeconds;
  final int tabSwitchCount;

  const OnlineExamSession({
    required this.exam,
    required this.sections,
    required this.sectionQuestions,
    required this.attempt,
    this.responses = const {},
    this.flaggedQuestions = const {},
    this.currentSectionIndex = 0,
    this.currentQuestionIndex = 0,
    required this.remainingSeconds,
    this.tabSwitchCount = 0,
  });

  OnlineExamSession copyWith({
    OnlineExam? exam,
    List<ExamSection>? sections,
    Map<String, List<ExamQuestion>>? sectionQuestions,
    ExamAttempt? attempt,
    Map<String, dynamic>? responses,
    Set<String>? flaggedQuestions,
    int? currentSectionIndex,
    int? currentQuestionIndex,
    int? remainingSeconds,
    int? tabSwitchCount,
  }) {
    return OnlineExamSession(
      exam: exam ?? this.exam,
      sections: sections ?? this.sections,
      sectionQuestions: sectionQuestions ?? this.sectionQuestions,
      attempt: attempt ?? this.attempt,
      responses: responses ?? this.responses,
      flaggedQuestions: flaggedQuestions ?? this.flaggedQuestions,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
      currentQuestionIndex:
          currentQuestionIndex ?? this.currentQuestionIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      tabSwitchCount: tabSwitchCount ?? this.tabSwitchCount,
    );
  }

  ExamSection get currentSection => sections[currentSectionIndex];

  List<ExamQuestion> get currentSectionQuestionList =>
      sectionQuestions[currentSection.id] ?? [];

  ExamQuestion get currentQuestion =>
      currentSectionQuestionList[currentQuestionIndex];

  int get totalQuestions {
    int count = 0;
    for (final section in sections) {
      count += (sectionQuestions[section.id]?.length ?? 0);
    }
    return count;
  }

  int get answeredCount {
    return responses.values
        .where((v) => v != null && v.toString().isNotEmpty)
        .length;
  }

  int get flaggedCount => flaggedQuestions.length;

  double get progress =>
      totalQuestions > 0 ? answeredCount / totalQuestions : 0;

  bool get isTimeUp => remainingSeconds <= 0;

  String get timerDisplay {
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool isQuestionAnswered(String questionId) {
    final resp = responses[questionId];
    return resp != null && resp.toString().isNotEmpty;
  }

  bool isQuestionFlagged(String questionId) =>
      flaggedQuestions.contains(questionId);

  /// Flat index across all sections
  int get globalQuestionIndex {
    int index = 0;
    for (int i = 0; i < currentSectionIndex; i++) {
      index += (sectionQuestions[sections[i].id]?.length ?? 0);
    }
    return index + currentQuestionIndex;
  }
}
