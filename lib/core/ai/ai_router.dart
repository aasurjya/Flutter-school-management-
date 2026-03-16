import 'dart:developer' as developer;

import 'adapters/ai_adapter.dart';
import 'adapters/deepseek_adapter.dart' show AIAdapterException;
import 'cache/ai_cache.dart';
import 'models/ai_capability.dart';
import 'models/ai_completion_request.dart';
import 'models/ai_completion_response.dart';

/// Routes AI completion requests to the correct adapter by capability,
/// and integrates the response cache.
class AIRouter {
  final Map<AICapability, AIAdapter> _adapters;
  final AICache? _cache;

  AIRouter({
    required Map<AICapability, AIAdapter> adapters,
    AICache? cache,
  })  : _adapters = Map.unmodifiable(adapters),
        _cache = cache;

  /// Send a completion request for the given [capability].
  ///
  /// Checks cache first (unless [AICompletionRequest.skipCache] is true).
  /// On cache miss, delegates to the adapter registered for [capability].
  Future<AICompletionResponse> complete(
    AICompletionRequest request, {
    required AICapability capability,
  }) async {
    final adapter = _adapters[capability];
    if (adapter == null) {
      throw AIAdapterException(
        'No adapter registered for capability: $capability',
        provider: 'router',
      );
    }

    // --- Cache lookup ---
    if (_cache != null && !request.skipCache) {
      final cached = _cache.get(request, adapter.providerId);
      if (cached != null) {
        developer.log(
          'Cache HIT for ${adapter.providerId}',
          name: 'AIRouter',
        );
        return cached;
      }
    }

    // --- Adapter call ---
    final response = await adapter.complete(request);

    // --- Cache store ---
    if (_cache != null && !request.skipCache) {
      _cache.put(
        request,
        adapter.providerId,
        response,
        ttl: request.cacheTtl,
      );
    }

    return response;
  }

  /// Convenience: send a simple system + user prompt for text generation.
  Future<AICompletionResponse> generateText({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 300,
    String? responseFormat,
    bool skipCache = false,
    Duration? cacheTtl,
  }) {
    return complete(
      AICompletionRequest.simple(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
        responseFormat: responseFormat,
        skipCache: skipCache,
        cacheTtl: cacheTtl,
      ),
      capability: AICapability.textGeneration,
    );
  }

  /// True if an adapter is registered for [capability].
  bool supports(AICapability capability) =>
      _adapters.containsKey(capability);

  /// Release all adapter resources.
  void dispose() {
    final disposed = <String>{};
    for (final adapter in _adapters.values) {
      if (disposed.add(adapter.providerId)) {
        adapter.dispose();
      }
    }
  }
}
