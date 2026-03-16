import 'ai_message.dart';

/// A provider-agnostic request for AI completion.
class AICompletionRequest {
  /// Ordered list of messages (system, user, assistant turns).
  final List<AIMessage> messages;

  /// Sampling temperature (0.0 = deterministic, 1.0 = creative).
  final double temperature;

  /// Maximum tokens to generate.
  final int maxTokens;

  /// If 'json', request JSON output mode from the provider.
  final String? responseFormat;

  /// When true, bypass the response cache even if a cached entry exists.
  final bool skipCache;

  /// Custom TTL for caching this response. Null uses the default.
  final Duration? cacheTtl;

  const AICompletionRequest({
    required this.messages,
    this.temperature = 0.7,
    this.maxTokens = 300,
    this.responseFormat,
    this.skipCache = false,
    this.cacheTtl,
  });

  /// Convenience: build a simple system + user prompt request.
  factory AICompletionRequest.simple({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 300,
    String? responseFormat,
    bool skipCache = false,
    Duration? cacheTtl,
  }) =>
      AICompletionRequest(
        messages: [
          AIMessage(role: AIMessageRole.system, content: systemPrompt),
          AIMessage(role: AIMessageRole.user, content: userPrompt),
        ],
        temperature: temperature,
        maxTokens: maxTokens,
        responseFormat: responseFormat,
        skipCache: skipCache,
        cacheTtl: cacheTtl,
      );
}
