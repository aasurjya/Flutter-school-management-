import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/question_paper.dart';
import '../../../data/repositories/question_paper_repository.dart';

// ==================== REPOSITORY ====================

final questionPaperRepositoryProvider =
    Provider<QuestionPaperRepository>((ref) {
  return QuestionPaperRepository(ref.watch(supabaseProvider));
});

// ==================== LIST ====================

class QuestionPaperFilter {
  final String? subjectId;
  final String? classId;
  final PaperStatus? status;

  const QuestionPaperFilter({this.subjectId, this.classId, this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionPaperFilter &&
          other.subjectId == subjectId &&
          other.classId == classId &&
          other.status == status;

  @override
  int get hashCode => Object.hash(subjectId, classId, status);
}

final questionPapersProvider =
    FutureProvider.family<List<QuestionPaper>, QuestionPaperFilter>(
  (ref, filter) async {
    final repo = ref.watch(questionPaperRepositoryProvider);
    return repo.getQuestionPapers(
      subjectId: filter.subjectId,
      classId: filter.classId,
      status: filter.status,
    );
  },
);

// ==================== DETAIL ====================

final questionPaperDetailProvider =
    FutureProvider.family<QuestionPaper, String>(
  (ref, paperId) async {
    final repo = ref.watch(questionPaperRepositoryProvider);
    return repo.getQuestionPaper(paperId);
  },
);

// ==================== GENERATOR STATE ====================

enum GeneratorStep { configure, generating, preview, saving, done, error }

class GeneratorState {
  final QuestionPaperConfig config;
  final GeneratorStep step;
  final List<Map<String, dynamic>> generatedSections;
  final String? errorMessage;
  final bool isAiGenerated;

  const GeneratorState({
    required this.config,
    this.step = GeneratorStep.configure,
    this.generatedSections = const [],
    this.errorMessage,
    this.isAiGenerated = false,
  });

  GeneratorState copyWith({
    QuestionPaperConfig? config,
    GeneratorStep? step,
    List<Map<String, dynamic>>? generatedSections,
    String? errorMessage,
    bool? isAiGenerated,
  }) =>
      GeneratorState(
        config: config ?? this.config,
        step: step ?? this.step,
        generatedSections: generatedSections ?? this.generatedSections,
        errorMessage: errorMessage ?? this.errorMessage,
        isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      );

  int get totalQuestions => generatedSections.fold(0, (sum, s) {
        final questions = s['questions'] as List<dynamic>? ?? [];
        return sum + questions.length;
      });

  double get totalMarksFromSections => generatedSections.fold(0.0, (sum, s) {
        final questions = s['questions'] as List<dynamic>? ?? [];
        return sum +
            questions.fold(0.0, (qSum, q) {
              return qSum + ((q['marks'] as num?)?.toDouble() ?? 1.0);
            });
      });
}

class QuestionPaperGeneratorNotifier
    extends StateNotifier<GeneratorState> {
  final Ref _ref;

  QuestionPaperGeneratorNotifier(this._ref, QuestionPaperConfig initialConfig)
      : super(GeneratorState(config: initialConfig));

  void updateConfig(QuestionPaperConfig config) {
    state = state.copyWith(config: config);
  }

  Future<void> generate() async {
    state = state.copyWith(
      step: GeneratorStep.generating,
      errorMessage: null,
    );

    try {
      final ai = _ref.read(aiTextGeneratorProvider);
      final config = state.config;

      final fallback = _buildFallbackPaper(config);

      final result = await ai.generateQuestionPaper(
        subjectName: config.subjectName,
        className: config.className,
        examType: config.examType,
        totalMarks: config.totalMarks,
        durationMinutes: config.durationMinutes,
        difficulty: config.difficulty.dbValue,
        topics: config.topics,
        board: config.board,
        questionTypeCounts: config.questionTypeCounts.isEmpty
            ? null
            : {
                for (final e in config.questionTypeCounts.entries)
                  e.key.dbValue: e.value
              },
        extraInstructions: config.extraInstructions,
        fallback: fallback,
      );

      List<Map<String, dynamic>> sections = [];

      if (result.isLLMGenerated) {
        try {
          final decoded = jsonDecode(result.text);
          sections = List<Map<String, dynamic>>.from(
              decoded['sections'] as List<dynamic>? ?? []);
        } catch (e) {
          developer.log('Failed to parse AI paper JSON', error: e);
          sections = _parseFallbackSections(fallback);
        }
      } else {
        sections = _parseFallbackSections(result.text);
      }

      state = state.copyWith(
        step: GeneratorStep.preview,
        generatedSections: sections,
        isAiGenerated: result.isLLMGenerated,
      );
    } catch (e) {
      state = state.copyWith(
        step: GeneratorStep.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<QuestionPaper?> save({
    required String title,
    String? subjectId,
    String? classId,
    String? academicYearId,
  }) async {
    state = state.copyWith(step: GeneratorStep.saving);

    try {
      final config = state.config;
      final repo = _ref.read(questionPaperRepositoryProvider);

      final paperData = {
        'title': title,
        'subject_id': subjectId,
        'class_id': classId,
        'academic_year_id': academicYearId,
        'exam_type': config.examType,
        'difficulty': config.difficulty.dbValue,
        'total_marks': config.totalMarks,
        'duration_minutes': config.durationMinutes,
        'is_ai_generated': state.isAiGenerated,
        'status': 'draft',
        'instructions': config.extraInstructions,
        'ai_prompt_context': {
          'board': config.board,
          'topics': config.topics,
          'question_type_counts': {
            for (final e in config.questionTypeCounts.entries)
              e.key.dbValue: e.value
          },
        },
      };

      final sectionsWithItems = state.generatedSections.map((section) {
        final questions =
            (section['questions'] as List<dynamic>? ?? [])
                .map((q) => Map<String, dynamic>.from(q))
                .toList();
        return {
          'title': section['title'] ?? 'Section',
          'instructions': section['instructions'],
          'total_marks': questions.fold<int>(
              0,
              (sum, q) =>
                  sum + ((q['marks'] as num?)?.round() ?? 1)),
          'items': questions
              .map((q) => {
                    'question_text': q['question_text'] ?? '',
                    'question_type': q['question_type'] ?? 'mcq',
                    'marks': q['marks'] ?? 1,
                    'difficulty': q['difficulty'] ?? 'medium',
                    'options': q['options'] ?? [],
                    'correct_answer': q['correct_answer'],
                    'explanation': q['explanation'],
                  })
              .toList(),
        };
      }).toList();

      final paper = await repo.createQuestionPaper(
        paperData: paperData,
        sectionsWithItems: sectionsWithItems,
      );

      state = state.copyWith(step: GeneratorStep.done);
      return paper;
    } catch (e) {
      state = state.copyWith(
        step: GeneratorStep.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void reset() {
    state = state.copyWith(
      step: GeneratorStep.configure,
      generatedSections: [],
      errorMessage: null,
    );
  }

  // ==================== FALLBACK PAPER ====================

  String _buildFallbackPaper(QuestionPaperConfig config) {
    final mcqCount = (config.totalMarks * 0.3).round();
    final shortCount = (config.totalMarks * 0.4 / 3).round();
    final longCount = (config.totalMarks * 0.3 / 5).round();

    final sections = [
      {
        'title': 'Section A — Objective Questions',
        'instructions':
            'Choose the correct answer. Each question carries 1 mark.',
        'questions': List.generate(
          mcqCount.clamp(0, 10),
          (i) => {
            'question_text':
                'Sample MCQ question ${i + 1} on ${config.subjectName}.',
            'question_type': 'mcq',
            'marks': 1,
            'difficulty': config.difficulty.dbValue,
            'options': [
              'A) Option 1',
              'B) Option 2',
              'C) Option 3',
              'D) Option 4',
            ],
            'correct_answer': 'A',
            'explanation': 'Explanation for question ${i + 1}.',
          },
        ),
      },
      {
        'title': 'Section B — Short Answer Questions',
        'instructions':
            'Answer in 3-4 sentences. Each question carries 3 marks.',
        'questions': List.generate(
          shortCount.clamp(0, 5),
          (i) => {
            'question_text':
                'Sample short answer question ${i + 1} on ${config.subjectName}.',
            'question_type': 'short_answer',
            'marks': 3,
            'difficulty': config.difficulty.dbValue,
            'options': [],
            'correct_answer': 'Key points for answer.',
            'explanation': '',
          },
        ),
      },
      {
        'title': 'Section C — Long Answer Questions',
        'instructions':
            'Answer in detail. Each question carries 5 marks.',
        'questions': List.generate(
          longCount.clamp(0, 4),
          (i) => {
            'question_text':
                'Sample long answer question ${i + 1} on ${config.subjectName}.',
            'question_type': 'long_answer',
            'marks': 5,
            'difficulty': 'hard',
            'options': [],
            'correct_answer': 'Detailed key points for answer.',
            'explanation': '',
          },
        ),
      },
    ];

    return jsonEncode({'sections': sections});
  }

  List<Map<String, dynamic>> _parseFallbackSections(String json) {
    try {
      final decoded = jsonDecode(json);
      return List<Map<String, dynamic>>.from(
          decoded['sections'] as List<dynamic>? ?? []);
    } catch (_) {
      return [];
    }
  }
}

final questionPaperGeneratorProvider = StateNotifierProvider.family<
    QuestionPaperGeneratorNotifier,
    GeneratorState,
    QuestionPaperConfig>(
  (ref, initialConfig) =>
      QuestionPaperGeneratorNotifier(ref, initialConfig),
);
