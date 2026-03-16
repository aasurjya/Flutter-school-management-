import '../models/ai_capability.dart';
import '../models/ai_completion_request.dart';
import '../models/ai_completion_response.dart';

/// Provider-agnostic interface for AI model backends.
///
/// Each concrete adapter wraps a single LLM provider's HTTP API and
/// translates between the unified [AICompletionRequest]/[AICompletionResponse]
/// types and the provider's native format.
abstract class AIAdapter {
  /// Unique identifier for this provider (e.g. 'deepseek', 'claude').
  String get providerId;

  /// Capabilities this adapter supports.
  Set<AICapability> get capabilities;

  /// Send a completion request and return the response.
  Future<AICompletionResponse> complete(AICompletionRequest request);

  /// Release HTTP resources.
  void dispose();
}
