import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/services/ai_text_generator.dart';
import '../../../data/models/trend_prediction.dart';
import '../../../data/repositories/trend_prediction_repository.dart';

final trendPredictionRepositoryProvider =
    Provider<TrendPredictionRepository>((ref) {
  return TrendPredictionRepository(ref.watch(supabaseProvider));
});

// --- Providers ---

final studentExamPredictionProvider =
    FutureProvider.family<TrendPrediction, String>(
  (ref, studentId) async {
    final repo = ref.watch(trendPredictionRepositoryProvider);
    return repo.buildStudentExamPrediction(studentId);
  },
);

final sectionAttendancePredictionProvider =
    FutureProvider.family<TrendPrediction, String>(
  (ref, sectionId) async {
    final repo = ref.watch(trendPredictionRepositoryProvider);
    return repo.buildSectionAttendancePrediction(sectionId);
  },
);

// ---------------------------------------------------------------------------
// LLM-enhanced trend narratives
// ---------------------------------------------------------------------------

AITextResult _buildTrendFallback(TrendPrediction p) {
  final direction = p.trendDirection;
  final confidence = p.confidenceLabel.toLowerCase();
  final text = 'The ${p.metricType} trend is $direction with $confidence '
      'confidence (R²=${p.rSquared.toStringAsFixed(2)}). '
      'Based on ${p.historicalData.length} data points.';
  return AITextResult(text: text);
}

final studentExamNarrativeProvider =
    FutureProvider.family<AITextResult, String>(
  (ref, studentId) async {
    final prediction =
        await ref.watch(studentExamPredictionProvider(studentId).future);
    final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

    final fallback = _buildTrendFallback(prediction);
    if (!prediction.hasEnoughData) return fallback;

    return aiTextGenerator.generateTrendNarrative(
      metricType: 'exam performance',
      trendDirection: prediction.trendDirection,
      rSquared: prediction.rSquared,
      dataPointCount: prediction.historicalData.length,
      latestValue: prediction.historicalData.isNotEmpty
          ? prediction.historicalData.last.y
          : null,
      predictedValue: prediction.predictedData.isNotEmpty
          ? prediction.predictedData.last.y
          : null,
      fallback: fallback.text,
    );
  },
);

final sectionAttendanceNarrativeProvider =
    FutureProvider.family<AITextResult, String>(
  (ref, sectionId) async {
    final prediction =
        await ref.watch(sectionAttendancePredictionProvider(sectionId).future);
    final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

    final fallback = _buildTrendFallback(prediction);
    if (!prediction.hasEnoughData) return fallback;

    return aiTextGenerator.generateTrendNarrative(
      metricType: 'section attendance',
      trendDirection: prediction.trendDirection,
      rSquared: prediction.rSquared,
      dataPointCount: prediction.historicalData.length,
      latestValue: prediction.historicalData.isNotEmpty
          ? prediction.historicalData.last.y
          : null,
      predictedValue: prediction.predictedData.isNotEmpty
          ? prediction.predictedData.last.y
          : null,
      fallback: fallback.text,
    );
  },
);
