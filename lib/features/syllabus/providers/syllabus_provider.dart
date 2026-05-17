import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/syllabus_topic.dart';
import '../../../data/models/lesson_plan.dart';
import '../../../data/repositories/syllabus_repository.dart';

// ==================== REPOSITORY ====================

final syllabusRepositoryProvider = Provider<SyllabusRepository>((ref) {
  return SyllabusRepository(ref.watch(supabaseProvider));
});

// ==================== TOPIC TREE ====================

final syllabusTreeProvider =
    FutureProvider.autoDispose.family<List<SyllabusTopic>, SyllabusFilter>(
  (ref, filter) async {
    final repository = ref.watch(syllabusRepositoryProvider);
    return repository.getTopicTree(
      subjectId: filter.subjectId,
      classId: filter.classId,
      academicYearId: filter.academicYearId,
      sectionId: filter.sectionId,
    );
  },
);

// ==================== COVERAGE SUMMARY ====================

final coverageSummaryProvider =
    FutureProvider.autoDispose.family<SyllabusCoverageSummary?, SyllabusFilter>(
  (ref, filter) async {
    if (filter.sectionId == null) return null;
    final repository = ref.watch(syllabusRepositoryProvider);
    return repository.getCoverageSummary(
      subjectId: filter.subjectId,
      classId: filter.classId,
      academicYearId: filter.academicYearId,
      sectionId: filter.sectionId!,
    );
  },
);

// ==================== TEACHER COVERAGE ====================

/// Returns coverage summaries across all subject assignments for a teacher.
/// Parameter is a record of (teacherId, academicYearId).
final teacherCoverageProvider = FutureProvider.autoDispose.family<
    List<SyllabusCoverageSummary>, ({String teacherId, String academicYearId})>(
  (ref, params) async {
    final repository = ref.watch(syllabusRepositoryProvider);
    return repository.getTeacherCoverageSummaries(
      teacherId: params.teacherId,
      academicYearId: params.academicYearId,
    );
  },
);

// ==================== TOPIC SEARCH ====================

final topicSearchProvider =
    FutureProvider.autoDispose.family<List<SyllabusTopic>, String>(
  (ref, query) async {
    if (query.length < 2) return [];
    final repository = ref.watch(syllabusRepositoryProvider);
    return repository.searchTopics(query: query);
  },
);

// ==================== TOPIC DETAIL ====================

final topicDetailProvider =
    FutureProvider.autoDispose.family<SyllabusTopic?, String>(
  (ref, topicId) async {
    final repository = ref.watch(syllabusRepositoryProvider);
    return repository.getTopicById(topicId);
  },
);

// ==================== TOPIC LINKS ====================

final topicLinksProvider =
    FutureProvider.autoDispose.family<List<TopicResourceLink>, String>(
  (ref, topicId) async {
    final repository = ref.watch(syllabusRepositoryProvider);
    return repository.getTopicLinks(topicId);
  },
);

// ==================== LESSON PLANS ====================

final lessonPlansProvider =
    FutureProvider.autoDispose.family<List<LessonPlan>, String>(
  (ref, topicId) async {
    final repository = ref.watch(syllabusRepositoryProvider);
    return repository.getLessonPlans(topicId: topicId);
  },
);

final lessonPlanDetailProvider =
    FutureProvider.autoDispose.family<LessonPlan?, String>(
  (ref, planId) async {
    final repository = ref.watch(syllabusRepositoryProvider);
    return repository.getLessonPlanById(planId);
  },
);

// ==================== STATE PROVIDERS ====================

final selectedSyllabusSubjectProvider = StateProvider<String?>((ref) => null);
final selectedSyllabusClassProvider = StateProvider<String?>((ref) => null);
