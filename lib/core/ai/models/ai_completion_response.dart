/// A provider-agnostic AI completion response.
class AICompletionResponse {
  /// Generated text content.
  final String text;

  /// Model ID that produced this response.
  final String model;

  /// Approximate tokens consumed (input + output) if reported by the provider.
  final int tokensUsed;

  /// True when this response was served from the local cache.
  final bool isFromCache;

  const AICompletionResponse({
    required this.text,
    required this.model,
    this.tokensUsed = 0,
    this.isFromCache = false,
  });

  /// Return a copy marked as cached.
  AICompletionResponse asFromCache() => AICompletionResponse(
        text: text,
        model: model,
        tokensUsed: tokensUsed,
        isFromCache: true,
      );
}
