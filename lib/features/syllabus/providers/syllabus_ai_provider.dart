import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../data/models/lesson_plan.dart';
import 'syllabus_provider.dart';

// ============================================================
// AI Generation State
// ============================================================

enum AIGenerationStatus { idle, generating, preview, saving, saved, error }

class SyllabusAIState {
  final AIGenerationStatus status;
  final List<Map<String, dynamic>> generatedTree;
  final String? errorMessage;

  const SyllabusAIState({
    this.status = AIGenerationStatus.idle,
    this.generatedTree = const [],
    this.errorMessage,
  });

  SyllabusAIState copyWith({
    AIGenerationStatus? status,
    List<Map<String, dynamic>>? generatedTree,
    String? errorMessage,
  }) {
    return SyllabusAIState(
      status: status ?? this.status,
      generatedTree: generatedTree ?? this.generatedTree,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ============================================================
// AI Notifier
// ============================================================

class SyllabusAINotifier extends StateNotifier<SyllabusAIState> {
  final Ref _ref;

  SyllabusAINotifier(this._ref) : super(const SyllabusAIState());

  /// Generate a syllabus structure via DeepSeek.
  Future<void> generateSyllabus({
    required String subjectName,
    required String className,
    String? board,
    String? textbookName,
  }) async {
    state = state.copyWith(
      status: AIGenerationStatus.generating,
      errorMessage: null,
    );

    try {
      final aiGenerator = _ref.read(aiTextGeneratorProvider);
      final result = await aiGenerator.generateSyllabusStructure(
        subjectName: subjectName,
        className: className,
        board: board,
        textbookName: textbookName,
        fallback: _buildFallbackSyllabus(subjectName),
      );

      final parsed = _parseJsonTree(result.text);
      if (parsed.isEmpty) {
        state = state.copyWith(
          status: AIGenerationStatus.error,
          errorMessage: 'Failed to parse AI response. Please try again.',
        );
        return;
      }

      state = state.copyWith(
        status: AIGenerationStatus.preview,
        generatedTree: parsed,
      );
    } catch (e) {
      developer.log('Syllabus AI generation failed',
          name: 'SyllabusAINotifier', error: e);
      state = state.copyWith(
        status: AIGenerationStatus.error,
        errorMessage: 'Generation failed: $e',
      );
    }
  }

  /// Remove a node from the preview tree by index path.
  void removePreviewNode(int unitIndex, [int? chapterIndex, int? topicIndex]) {
    final tree = List<Map<String, dynamic>>.from(
      state.generatedTree.map((e) => Map<String, dynamic>.from(e)),
    );

    if (topicIndex != null && chapterIndex != null) {
      final chapters = List<Map<String, dynamic>>.from(
        tree[unitIndex]['chapters'] ?? [],
      );
      final topics = List<Map<String, dynamic>>.from(
        chapters[chapterIndex]['topics'] ?? [],
      );
      topics.removeAt(topicIndex);
      chapters[chapterIndex] = {...chapters[chapterIndex], 'topics': topics};
      tree[unitIndex] = {...tree[unitIndex], 'chapters': chapters};
    } else if (chapterIndex != null) {
      final chapters = List<Map<String, dynamic>>.from(
        tree[unitIndex]['chapters'] ?? [],
      );
      chapters.removeAt(chapterIndex);
      tree[unitIndex] = {...tree[unitIndex], 'chapters': chapters};
    } else {
      tree.removeAt(unitIndex);
    }

    state = state.copyWith(generatedTree: tree);
  }

  /// Save the generated preview tree to the database.
  Future<void> saveGeneratedTopics({
    required String subjectId,
    required String classId,
    required String academicYearId,
  }) async {
    state = state.copyWith(status: AIGenerationStatus.saving);

    try {
      final repository = _ref.read(syllabusRepositoryProvider);
      final rows = <Map<String, dynamic>>[];

      for (var ui = 0; ui < state.generatedTree.length; ui++) {
        final unit = state.generatedTree[ui];

        // Create the unit
        final unitData = <String, dynamic>{
          'subject_id': subjectId,
          'class_id': classId,
          'academic_year_id': academicYearId,
          'parent_topic_id': null,
          'level': 'unit',
          'sequence_order': ui,
          'title': unit['title'] ?? 'Unit ${ui + 1}',
          'description': unit['description'],
          'learning_objectives': unit['learning_objectives'] ?? [],
          'estimated_periods': unit['estimated_periods'] ?? 5,
          'tags': [],
        };

        final createdUnit = await repository.createTopic(unitData);

        // Chapters
        final chapters =
            List<Map<String, dynamic>>.from(unit['chapters'] ?? []);
        for (var ci = 0; ci < chapters.length; ci++) {
          final chapter = chapters[ci];

          final chapterData = <String, dynamic>{
            'subject_id': subjectId,
            'class_id': classId,
            'academic_year_id': academicYearId,
            'parent_topic_id': createdUnit.id,
            'level': 'chapter',
            'sequence_order': ci,
            'title': chapter['title'] ?? 'Chapter ${ci + 1}',
            'description': chapter['description'],
            'learning_objectives': chapter['learning_objectives'] ?? [],
            'estimated_periods': chapter['estimated_periods'] ?? 3,
            'tags': [],
          };

          final createdChapter = await repository.createTopic(chapterData);

          // Topics
          final topics =
              List<Map<String, dynamic>>.from(chapter['topics'] ?? []);
          for (var ti = 0; ti < topics.length; ti++) {
            final topic = topics[ti];
            rows.add({
              'subject_id': subjectId,
              'class_id': classId,
              'academic_year_id': academicYearId,
              'parent_topic_id': createdChapter.id,
              'level': 'topic',
              'sequence_order': ti,
              'title': topic['title'] ?? 'Topic ${ti + 1}',
              'description': topic['description'],
              'learning_objectives': topic['learning_objectives'] ?? [],
              'estimated_periods': topic['estimated_periods'] ?? 1,
              'tags': [],
            });
          }
        }
      }

      // Bulk-create leaf topics
      if (rows.isNotEmpty) {
        await repository.bulkCreateTopics(rows);
      }

      state = state.copyWith(status: AIGenerationStatus.saved);
    } catch (e) {
      developer.log('Saving AI syllabus failed',
          name: 'SyllabusAINotifier', error: e);
      state = state.copyWith(
        status: AIGenerationStatus.error,
        errorMessage: 'Save failed: $e',
      );
    }
  }

  void reset() {
    state = const SyllabusAIState();
  }

  // ============================================================
  // Helpers
  // ============================================================

  List<Map<String, dynamic>> _parseJsonTree(String text) {
    try {
      // Try to extract JSON array from the text
      var jsonStr = text.trim();

      // Strip markdown code fences if present
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
        jsonStr = jsonStr.trim();
      }

      // Find the first [ and last ]
      final start = jsonStr.indexOf('[');
      final end = jsonStr.lastIndexOf(']');
      if (start == -1 || end == -1) return [];

      jsonStr = jsonStr.substring(start, end + 1);
      final decoded = jsonDecode(jsonStr);

      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      developer.log('Failed to parse syllabus JSON',
          name: 'SyllabusAINotifier', error: e);
      return [];
    }
  }

  String _buildFallbackSyllabus(String subjectName) {
    return jsonEncode([
      {
        'title': 'Unit 1: Introduction to $subjectName',
        'description': 'Foundational concepts and overview',
        'estimated_periods': 5,
        'learning_objectives': [
          'Understand basic concepts',
          'Identify key terminology'
        ],
        'chapters': [
          {
            'title': 'Chapter 1: Fundamentals',
            'description': 'Core principles and definitions',
            'estimated_periods': 3,
            'learning_objectives': ['Define key terms', 'Explain core ideas'],
            'topics': [
              {
                'title': 'Basic Concepts',
                'description': 'Introduction to basic concepts',
                'estimated_periods': 1,
                'learning_objectives': ['List basic concepts']
              },
              {
                'title': 'Terminology',
                'description': 'Key terms and definitions',
                'estimated_periods': 1,
                'learning_objectives': ['Define important terms']
              }
            ]
          }
        ]
      },
      {
        'title': 'Unit 2: Core Topics',
        'description': 'In-depth study of main topics',
        'estimated_periods': 8,
        'learning_objectives': [
          'Apply concepts to problems',
          'Analyze relationships'
        ],
        'chapters': [
          {
            'title': 'Chapter 2: Main Concepts',
            'description': 'Detailed study of main concepts',
            'estimated_periods': 4,
            'learning_objectives': ['Explain main concepts'],
            'topics': [
              {
                'title': 'Concept A',
                'description': 'First main concept',
                'estimated_periods': 2,
                'learning_objectives': ['Understand Concept A']
              },
              {
                'title': 'Concept B',
                'description': 'Second main concept',
                'estimated_periods': 2,
                'learning_objectives': ['Understand Concept B']
              }
            ]
          }
        ]
      }
    ]);
  }
}

// ============================================================
// Provider
// ============================================================

final syllabusAIProvider =
    StateNotifierProvider<SyllabusAINotifier, SyllabusAIState>((ref) {
  return SyllabusAINotifier(ref);
});

// ============================================================
// Lesson Plan AI Generation (simpler, single-shot)
// ============================================================

class LessonPlanAIState {
  final bool isGenerating;
  final LessonPlan? generatedPlan;
  final String? errorMessage;

  const LessonPlanAIState({
    this.isGenerating = false,
    this.generatedPlan,
    this.errorMessage,
  });
}

class LessonPlanAINotifier extends StateNotifier<LessonPlanAIState> {
  final Ref _ref;

  LessonPlanAINotifier(this._ref) : super(const LessonPlanAIState());

  Future<Map<String, dynamic>?> generateLessonPlan({
    required String topicTitle,
    required String subjectName,
    required String className,
    int durationMinutes = 40,
    List<String>? learningObjectives,
  }) async {
    state = const LessonPlanAIState(isGenerating: true);

    try {
      final aiGenerator = _ref.read(aiTextGeneratorProvider);
      final result = await aiGenerator.generateLessonPlan(
        topicTitle: topicTitle,
        subjectName: subjectName,
        className: className,
        durationMinutes: durationMinutes,
        learningObjectives: learningObjectives,
        fallback: jsonEncode({
          'objective':
              'Students will understand the key concepts of $topicTitle',
          'warm_up':
              'Begin with a 5-minute review of previous lesson and ask students to share what they remember.',
          'main_activity':
              'Explain the core concepts of $topicTitle using examples and visual aids. Engage students with questions throughout.',
          'assessment_activity':
              'Quick 5-minute quiz or class discussion to check understanding of key points.',
          'homework':
              'Complete practice exercises related to $topicTitle from the textbook.',
          'materials_needed':
              'Textbook, whiteboard, markers, worksheet handouts',
          'differentiation_notes':
              'Provide additional examples for struggling students. Advanced students can work on extension problems.',
        }),
      );

      final parsed = _parseLessonPlanJson(result.text);
      state = const LessonPlanAIState();
      return parsed;
    } catch (e) {
      developer.log('Lesson plan AI generation failed',
          name: 'LessonPlanAINotifier', error: e);
      state = LessonPlanAIState(errorMessage: 'Generation failed: $e');
      return null;
    }
  }

  Map<String, dynamic>? _parseLessonPlanJson(String text) {
    try {
      var jsonStr = text.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
        jsonStr = jsonStr.trim();
      }

      final start = jsonStr.indexOf('{');
      final end = jsonStr.lastIndexOf('}');
      if (start == -1 || end == -1) return null;

      jsonStr = jsonStr.substring(start, end + 1);
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (e) {
      developer.log('Failed to parse lesson plan JSON',
          name: 'LessonPlanAINotifier', error: e);
      return null;
    }
  }

  void reset() {
    state = const LessonPlanAIState();
  }
}

final lessonPlanAIProvider =
    StateNotifierProvider<LessonPlanAINotifier, LessonPlanAIState>((ref) {
  return LessonPlanAINotifier(ref);
});
