import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/services/ai_text_generator.dart';
import '../../attendance/providers/attendance_provider.dart';

/// Provides an AI-generated school health narrative for the admin dashboard.
///
/// Fetches today's attendance percentage and generates a summary.
/// Falls back to a template narrative when LLM is unavailable.
final schoolHealthNarrativeProvider = FutureProvider<AITextResult>((ref) async {
  final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

  // Fetch today's attendance.
  double attendancePercent = 0;
  try {
    attendancePercent =
        await ref.watch(todayAttendancePercentageProvider.future);
  } catch (_) {}

  // Placeholder values — in production these would come from fee & risk repos.
  const feeCollectionRate = 0.0;
  const riskDistribution = <String, int>{};
  const totalStudents = 0;

  final fallback = 'Today\'s school attendance is '
      '${attendancePercent > 0 ? '${attendancePercent.round()}%' : 'not yet recorded'}. '
      'Monitor fee collections and at-risk students throughout the day for '
      'a complete picture of school health.';

  try {
    return await aiTextGenerator.generateSchoolHealthNarrative(
      attendancePercent: attendancePercent,
      feeCollectionRate: feeCollectionRate,
      riskDistribution: riskDistribution,
      totalStudents: totalStudents,
      fallback: fallback,
    );
  } catch (_) {
    return AITextResult(text: fallback);
  }
});
