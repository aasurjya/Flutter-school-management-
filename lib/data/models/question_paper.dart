import 'package:flutter/material.dart';

// ============================================================
// Enums
// ============================================================

enum QuestionType {
  mcq('mcq', 'Multiple Choice', Icons.radio_button_checked),
  shortAnswer('short_answer', 'Short Answer', Icons.short_text),
  longAnswer('long_answer', 'Long Answer', Icons.article),
  trueFalse('true_false', 'True / False', Icons.check_circle_outline),
  fillBlank('fill_blank', 'Fill in the Blank', Icons.edit),
  matchFollowing('match_following', 'Match the Following', Icons.compare_arrows),
  diagram('diagram', 'Diagram / Draw', Icons.draw);

  const QuestionType(this.dbValue, this.label, this.icon);
  final String dbValue;
  final String label;
  final IconData icon;

  static QuestionType fromString(String value) =>
      QuestionType.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => QuestionType.mcq,
      );
}

enum DifficultyLevel {
  easy('easy', 'Easy', Colors.green),
  medium('medium', 'Medium', Colors.orange),
  hard('hard', 'Hard', Colors.red);

  const DifficultyLevel(this.dbValue, this.label, this.color);
  final String dbValue;
  final String label;
  final Color color;

  static DifficultyLevel fromString(String value) =>
      DifficultyLevel.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => DifficultyLevel.medium,
      );
}

enum PaperStatus {
  draft('draft', 'Draft', Icons.edit_note, Colors.grey),
  published('published', 'Published', Icons.check_circle, Colors.green),
  archived('archived', 'Archived', Icons.archive, Colors.blueGrey);

  const PaperStatus(this.dbValue, this.label, this.icon, this.color);
  final String dbValue;
  final String label;
  final IconData icon;
  final Color color;

  static PaperStatus fromString(String value) =>
      PaperStatus.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => PaperStatus.draft,
      );
}

// ============================================================
// QuestionPaperItem
// ============================================================

class QuestionPaperItem {
  final String id;
  final String paperId;
  final String? sectionId;
  final String? questionBankId;
  final String questionText;
  final QuestionType questionType;
  final double marks;
  final DifficultyLevel difficulty;
  final List<String> options;
  final String? correctAnswer;
  final String? explanation;
  final String? imageUrl;
  final int sequenceOrder;
  final DateTime createdAt;

  const QuestionPaperItem({
    required this.id,
    required this.paperId,
    this.sectionId,
    this.questionBankId,
    required this.questionText,
    required this.questionType,
    required this.marks,
    required this.difficulty,
    this.options = const [],
    this.correctAnswer,
    this.explanation,
    this.imageUrl,
    required this.sequenceOrder,
    required this.createdAt,
  });

  factory QuestionPaperItem.fromJson(Map<String, dynamic> json) {
    return QuestionPaperItem(
      id: json['id'],
      paperId: json['paper_id'],
      sectionId: json['section_id'],
      questionBankId: json['question_bank_id'],
      questionText: json['question_text'],
      questionType: QuestionType.fromString(json['question_type'] ?? 'mcq'),
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      difficulty:
          DifficultyLevel.fromString(json['difficulty'] ?? 'medium'),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
      imageUrl: json['image_url'],
      sequenceOrder: json['sequence_order'] ?? 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'paper_id': paperId,
        'section_id': sectionId,
        'question_bank_id': questionBankId,
        'question_text': questionText,
        'question_type': questionType.dbValue,
        'marks': marks,
        'difficulty': difficulty.dbValue,
        'options': options,
        'correct_answer': correctAnswer,
        'explanation': explanation,
        'image_url': imageUrl,
        'sequence_order': sequenceOrder,
      };

  bool get isMCQ => questionType == QuestionType.mcq;
  bool get isTrueFalse => questionType == QuestionType.trueFalse;
  bool get hasOptions => isMCQ || isTrueFalse || questionType == QuestionType.matchFollowing;
}

// ============================================================
// QuestionPaperSection
// ============================================================

class QuestionPaperSection {
  final String id;
  final String paperId;
  final String title;
  final String? instructions;
  final int totalMarks;
  final int sequenceOrder;
  final DateTime createdAt;
  final List<QuestionPaperItem> items;

  const QuestionPaperSection({
    required this.id,
    required this.paperId,
    required this.title,
    this.instructions,
    required this.totalMarks,
    required this.sequenceOrder,
    required this.createdAt,
    this.items = const [],
  });

  factory QuestionPaperSection.fromJson(Map<String, dynamic> json) {
    return QuestionPaperSection(
      id: json['id'],
      paperId: json['paper_id'],
      title: json['title'],
      instructions: json['instructions'],
      totalMarks: json['total_marks'] ?? 0,
      sequenceOrder: json['sequence_order'] ?? 1,
      createdAt: DateTime.parse(json['created_at']),
      items: (json['question_paper_items'] as List<dynamic>? ?? [])
          .map((i) => QuestionPaperItem.fromJson(i))
          .toList()
        ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder)),
    );
  }

  Map<String, dynamic> toJson() => {
        'paper_id': paperId,
        'title': title,
        'instructions': instructions,
        'total_marks': totalMarks,
        'sequence_order': sequenceOrder,
      };

  int get questionCount => items.length;
  double get actualMarks =>
      items.fold(0.0, (sum, item) => sum + item.marks);
}

// ============================================================
// QuestionPaper
// ============================================================

class QuestionPaper {
  final String id;
  final String tenantId;
  final String title;
  final String? subjectId;
  final String? classId;
  final String? academicYearId;
  final String examType;
  final DifficultyLevel difficulty;
  final int totalMarks;
  final int durationMinutes;
  final String? instructions;
  final bool isAiGenerated;
  final PaperStatus status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? subjectName;
  final String? className;
  final List<QuestionPaperSection> sections;

  const QuestionPaper({
    required this.id,
    required this.tenantId,
    required this.title,
    this.subjectId,
    this.classId,
    this.academicYearId,
    required this.examType,
    required this.difficulty,
    required this.totalMarks,
    required this.durationMinutes,
    this.instructions,
    required this.isAiGenerated,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
    this.className,
    this.sections = const [],
  });

  factory QuestionPaper.fromJson(Map<String, dynamic> json) {
    return QuestionPaper(
      id: json['id'],
      tenantId: json['tenant_id'],
      title: json['title'],
      subjectId: json['subject_id'],
      classId: json['class_id'],
      academicYearId: json['academic_year_id'],
      examType: json['exam_type'] ?? 'unit_test',
      difficulty:
          DifficultyLevel.fromString(json['difficulty'] ?? 'medium'),
      totalMarks: json['total_marks'] ?? 100,
      durationMinutes: json['duration_minutes'] ?? 180,
      instructions: json['instructions'],
      isAiGenerated: json['is_ai_generated'] ?? false,
      status: PaperStatus.fromString(json['status'] ?? 'draft'),
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      subjectName: json['subjects']?['name'] ?? json['subject_name'],
      className: json['classes']?['name'] ?? json['class_name'],
      sections: (json['question_paper_sections'] as List<dynamic>? ?? [])
          .map((s) => QuestionPaperSection.fromJson(s))
          .toList()
        ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder)),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'title': title,
        'subject_id': subjectId,
        'class_id': classId,
        'academic_year_id': academicYearId,
        'exam_type': examType,
        'difficulty': difficulty.dbValue,
        'total_marks': totalMarks,
        'duration_minutes': durationMinutes,
        'instructions': instructions,
        'is_ai_generated': isAiGenerated,
        'status': status.dbValue,
        'created_by': createdBy,
      };

  int get totalQuestions =>
      sections.fold(0, (sum, s) => sum + s.questionCount);

  String get examTypeDisplay {
    switch (examType) {
      case 'unit_test':
        return 'Unit Test';
      case 'mid_term':
        return 'Mid Term';
      case 'final':
        return 'Final Exam';
      case 'practice':
        return 'Practice Paper';
      default:
        return examType;
    }
  }
}

// ============================================================
// QuestionPaperConfig — used for AI generation wizard
// ============================================================

class QuestionPaperConfig {
  final String subjectName;
  final String className;
  final String examType;
  final int totalMarks;
  final int durationMinutes;
  final DifficultyLevel difficulty;
  final List<String> topics;
  final Map<QuestionType, int> questionTypeCounts;
  final String? board;
  final String? extraInstructions;

  const QuestionPaperConfig({
    required this.subjectName,
    required this.className,
    required this.examType,
    required this.totalMarks,
    required this.durationMinutes,
    required this.difficulty,
    this.topics = const [],
    this.questionTypeCounts = const {},
    this.board,
    this.extraInstructions,
  });

  QuestionPaperConfig copyWith({
    String? subjectName,
    String? className,
    String? examType,
    int? totalMarks,
    int? durationMinutes,
    DifficultyLevel? difficulty,
    List<String>? topics,
    Map<QuestionType, int>? questionTypeCounts,
    String? board,
    String? extraInstructions,
  }) =>
      QuestionPaperConfig(
        subjectName: subjectName ?? this.subjectName,
        className: className ?? this.className,
        examType: examType ?? this.examType,
        totalMarks: totalMarks ?? this.totalMarks,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        difficulty: difficulty ?? this.difficulty,
        topics: topics ?? this.topics,
        questionTypeCounts: questionTypeCounts ?? this.questionTypeCounts,
        board: board ?? this.board,
        extraInstructions: extraInstructions ?? this.extraInstructions,
      );

  String get questionBreakdownText {
    if (questionTypeCounts.isEmpty) return 'Auto-distribute';
    return questionTypeCounts.entries
        .map((e) => '${e.value} ${e.key.label}')
        .join(', ');
  }
}
