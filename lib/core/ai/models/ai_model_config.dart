import 'ai_capability.dart';

/// Configuration for a specific AI model/provider combination.
class AIModelConfig {
  /// Provider identifier (e.g. 'deepseek', 'claude', 'openrouter').
  final String provider;

  /// Model ID sent in API requests (e.g. 'deepseek-chat', 'claude-sonnet-4-6').
  final String modelId;

  /// Base URL endpoint for the API.
  final String endpoint;

  /// Environment variable name that holds the API key.
  final String apiKeyEnvVar;

  /// Capabilities this model supports.
  final Set<AICapability> capabilities;

  /// Request timeout.
  final Duration timeout;

  const AIModelConfig({
    required this.provider,
    required this.modelId,
    required this.endpoint,
    required this.apiKeyEnvVar,
    this.capabilities = const {AICapability.textGeneration},
    this.timeout = const Duration(seconds: 15),
  });

  AIModelConfig copyWith({
    String? provider,
    String? modelId,
    String? endpoint,
    String? apiKeyEnvVar,
    Set<AICapability>? capabilities,
    Duration? timeout,
  }) =>
      AIModelConfig(
        provider: provider ?? this.provider,
        modelId: modelId ?? this.modelId,
        endpoint: endpoint ?? this.endpoint,
        apiKeyEnvVar: apiKeyEnvVar ?? this.apiKeyEnvVar,
        capabilities: capabilities ?? this.capabilities,
        timeout: timeout ?? this.timeout,
      );
}
