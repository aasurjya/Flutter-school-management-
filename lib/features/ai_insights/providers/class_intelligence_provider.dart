import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/class_intelligence.dart';
import '../../../data/repositories/class_intelligence_repository.dart';

class SectionYearFilter {
  final String sectionId;
  final String academicYearId;

  const SectionYearFilter({
    required this.sectionId,
    required this.academicYearId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionYearFilter &&
          sectionId == other.sectionId &&
          academicYearId == other.academicYearId;

  @override
  int get hashCode => Object.hash(sectionId, academicYearId);
}

final classIntelligenceRepositoryProvider =
    Provider<ClassIntelligenceRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return ClassIntelligenceRepository(client);
});

final classIntelligenceProvider =
    FutureProvider.family<ClassIntelligence, SectionYearFilter>(
  (ref, filter) async {
    final repo = ref.watch(classIntelligenceRepositoryProvider);
    return repo.getClassIntelligence(
      sectionId: filter.sectionId,
      academicYearId: filter.academicYearId,
    );
  },
);

final enrichedClassIntelligenceProvider =
    FutureProvider.family<ClassIntelligence, SectionYearFilter>(
  (ref, filter) async {
    final intelligence =
        await ref.watch(classIntelligenceProvider(filter).future);
    final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

    // Find best and worst subjects
    final sorted = [...intelligence.subjectStats]
      ..sort((a, b) => b.averagePercentage.compareTo(a.averagePercentage));
    final bestSubject = sorted.isNotEmpty ? sorted.first.subjectName : 'N/A';
    final worstSubject = sorted.isNotEmpty ? sorted.last.subjectName : 'N/A';
    final riskCount = (intelligence.riskDistribution['high'] ?? 0) +
        (intelligence.riskDistribution['critical'] ?? 0);

    try {
      final result = await aiTextGenerator.generateClassNarrative(
        className: intelligence.className,
        sectionName: intelligence.sectionName,
        passRate: intelligence.passRate,
        avgPercentage: intelligence.averageExamScore,
        bestSubject: bestSubject,
        worstSubject: worstSubject,
        attendancePct: intelligence.averageAttendance,
        riskCount: riskCount,
        fallback: '',
      );

      if (result.text.isNotEmpty && result.isLLMGenerated) {
        return intelligence.copyWith(aiNarrative: result.text);
      }
    } catch (_) {
      // LLM call failed or method not yet available -- fall through to
      // template narrative below.
    }

    // Fallback narrative
    final fallbackNarrative =
        '${intelligence.className} ${intelligence.sectionName} has '
        '${intelligence.totalStudents} students with an average exam score of '
        '${intelligence.averageExamScore.toStringAsFixed(1)}% and '
        '${intelligence.averageAttendance.toStringAsFixed(1)}% attendance. '
        '$bestSubject is the strongest subject while $worstSubject needs more '
        'attention. '
        '${riskCount > 0 ? '$riskCount student${riskCount == 1 ? '' : 's'} require${riskCount == 1 ? 's' : ''} immediate intervention.' : 'No students are in the high-risk category.'}';

    return intelligence.copyWith(aiNarrative: fallbackNarrative);
  },
);
