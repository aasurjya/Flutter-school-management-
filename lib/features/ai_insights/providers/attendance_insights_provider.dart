import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/services/ai_text_generator.dart';
import '../../../data/models/attendance_insights.dart';
import '../../../data/repositories/attendance_insights_repository.dart';

final attendanceInsightsRepositoryProvider =
    Provider<AttendanceInsightsRepository>((ref) {
  return AttendanceInsightsRepository(ref.watch(supabaseProvider));
});

// --- Providers ---

final dayPatternsProvider =
    FutureProvider.family<List<DayPattern>, String>(
  (ref, sectionId) async {
    final repo = ref.watch(attendanceInsightsRepositoryProvider);
    return repo.getDayPatterns(sectionId);
  },
);

final chronicAbsenteesProvider =
    FutureProvider.family<List<ChronicAbsentee>, String>(
  (ref, sectionId) async {
    final repo = ref.watch(attendanceInsightsRepositoryProvider);
    return repo.getChronicAbsentees(sectionId);
  },
);

final attendanceAnomaliesProvider =
    FutureProvider.family<List<AttendanceAnomaly>, String>(
  (ref, sectionId) async {
    final repo = ref.watch(attendanceInsightsRepositoryProvider);
    final history = await repo.getSectionDailyHistory(sectionId);
    return repo.detectAnomalies(history);
  },
);

final attendanceStreaksProvider =
    FutureProvider.family<List<StudentStreak>, String>(
  (ref, sectionId) async {
    final repo = ref.watch(attendanceInsightsRepositoryProvider);
    return repo.getStudentStreaks(sectionId);
  },
);

/// LLM-enhanced attendance narrative for a section.
/// Non-blocking: returns empty result while loading, never errors in UI.
final attendanceNarrativeProvider =
    FutureProvider.family<AITextResult, String>(
  (ref, sectionId) async {
    final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

    // Gather data from existing providers
    final patterns = await ref.watch(dayPatternsProvider(sectionId).future);
    final absentees = await ref.watch(chronicAbsenteesProvider(sectionId).future);
    final anomalies =
        await ref.watch(attendanceAnomaliesProvider(sectionId).future);

    final problematicDays = patterns
        .where((p) => p.isProblematic)
        .map((p) =>
            '${p.shortDayName} (${p.attendancePercentage.toStringAsFixed(1)}%)')
        .toList();

    // Build template fallback
    final fallback = problematicDays.isNotEmpty
        ? 'Attendance dips on ${problematicDays.join(", ")}. '
            '${absentees.length} chronic absentees identified. '
            '${anomalies.length} anomalies detected in the last 30 days.'
        : 'Attendance patterns are within normal range. '
            '${absentees.length} chronic absentees identified.';

    return aiTextGenerator.generateAttendanceNarrative(
      problematicDays: problematicDays,
      chronicAbsenteeCount: absentees.length,
      anomalyCount: anomalies.length,
      fallback: fallback,
    );
  },
);
