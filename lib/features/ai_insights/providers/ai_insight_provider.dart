import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/services/ai_text_generator.dart';

/// Generic AI-insight Riverpod factory.
///
/// **Problem:** 21 hand-rolled `*_insight_provider.dart` files all did the
/// same thing — build a fallback string, call an AI generator with a feature-
/// specific method, catch any exception, return the fallback. That's a
/// 30-50 line file per insight, ~600 lines of duplication.
///
/// **Solution:** a single factory that produces an autoDispose family
/// `FutureProvider<AITextResult, TInput>` from three closures:
///   • [systemPrompt]   — shared across calls (rarely depends on input).
///   • [userPromptBuilder] — turns the input into the prompt body.
///   • [fallbackBuilder]   — produces deterministic non-AI copy.
///
/// **Migration path:** existing providers stay as-is; new insight surfaces
/// use [aiInsightProvider]. As specialized generator methods on
/// `AITextGenerator` lose their last call site, they can be deleted.
///
/// **Example — full transport insight in 12 lines:**
/// ```dart
/// final transportInsightProvider =
///     aiInsightProvider<TransportInsightInput>(
///   featureType: 'transport_insight',
///   systemPrompt: 'You are a transport-ops analyst…',
///   userPromptBuilder: (i) =>
///       'Active routes: ${i.activeRoutes}, capacity ${i.capacityPercent}%.',
///   fallbackBuilder: (i) =>
///       '${i.activeRoutes} active routes at ${i.capacityPercent.round()}%.',
/// );
/// ```
AutoDisposeFutureProviderFamily<AITextResult, T> aiInsightProvider<T>({
  required String featureType,
  required String systemPrompt,
  required String Function(T input) userPromptBuilder,
  required String Function(T input) fallbackBuilder,
  double temperature = 0.7,
  int maxTokens = 300,
  bool skipCache = false,
  Duration? cacheTtl,
}) {
  return FutureProvider.autoDispose.family<AITextResult, T>(
    (ref, input) async {
      final ai = ref.watch(aiTextGeneratorProvider);
      final fallback = fallbackBuilder(input);
      try {
        return await ai.generate(
          systemPrompt: systemPrompt,
          userPrompt: userPromptBuilder(input),
          fallback: fallback,
          temperature: temperature,
          maxTokens: maxTokens,
          skipCache: skipCache,
          cacheTtl: cacheTtl,
        );
      } catch (_) {
        return AITextResult(text: fallback);
      }
    },
  );
}
