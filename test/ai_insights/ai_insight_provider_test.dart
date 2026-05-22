import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/core/ai/ai_router.dart';
import 'package:school_management/core/providers/ai_providers.dart';
import 'package:school_management/core/services/ai_text_generator.dart';
import 'package:school_management/features/ai_insights/providers/ai_insight_provider.dart';

class _TestInput {
  final int routes;
  final double capacity;
  const _TestInput(this.routes, this.capacity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestInput &&
          routes == other.routes &&
          capacity == other.capacity;

  @override
  int get hashCode => Object.hash(routes, capacity);
}

void main() {
  group('aiInsightProvider', () {
    test('returns fallback when no AI backends are configured', () async {
      final provider = aiInsightProvider<_TestInput>(
        featureType: 'test_insight',
        systemPrompt: 'system',
        userPromptBuilder: (i) => 'routes=${i.routes} cap=${i.capacity}',
        fallbackBuilder: (i) =>
            '${i.routes} routes at ${i.capacity.round()}% capacity.',
      );

      final container = ProviderContainer(overrides: [
        // No AIRouter / DeepSeekService — generator will fall through to
        // the fallback path immediately.
        aiTextGeneratorProvider.overrideWithValue(
          const AITextGenerator(),
        ),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(
        provider(const _TestInput(3, 78.5)).future,
      );
      expect(result.text, '3 routes at 79% capacity.');
      expect(result.isLLMGenerated, isFalse);
    });

    test('passes fallback through when generator throws', () async {
      final provider = aiInsightProvider<_TestInput>(
        featureType: 'test_insight',
        systemPrompt: 'system',
        userPromptBuilder: (i) => 'in',
        fallbackBuilder: (i) => 'FB-${i.routes}',
      );

      final container = ProviderContainer(overrides: [
        aiTextGeneratorProvider.overrideWithValue(
          AITextGenerator(router: _ThrowingRouter()),
        ),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(provider(const _TestInput(7, 0)).future);
      expect(result.text, 'FB-7');
      expect(result.isLLMGenerated, isFalse);
    });
  });
}

/// AIRouter stub that always throws — exercises the fallback path of
/// [aiInsightProvider] without needing a real network/LLM.
class _ThrowingRouter implements AIRouter {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #generateText) {
      throw StateError('test: generator failed');
    }
    return super.noSuchMethod(invocation);
  }
}
