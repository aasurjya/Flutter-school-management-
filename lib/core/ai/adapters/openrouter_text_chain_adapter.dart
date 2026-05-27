import 'package:http/http.dart' as http;

import '../models/ai_capability.dart';
import '../models/ai_completion_request.dart';
import '../models/ai_completion_response.dart';
import '../models/ai_model_config.dart';
import 'ai_adapter.dart';
import 'deepseek_adapter.dart' show AIAdapterException;
import 'openrouter_adapter.dart';

/// Text-generation adapter that walks an ordered chain of OpenRouter **free**
/// models, trying each one in turn until a call succeeds.
///
/// This is the client-side production path for AI text: the Supabase
/// `ai-gateway` edge function is the preferred (key-server-side) route, but
/// while it is undeployed this adapter generates text directly via OpenRouter
/// using the bundled `Riverflow_V2_Fast` key. If every model fails (rate-limit,
/// 5xx, unavailable), it throws so [AITextGenerator] falls back to its local
/// data-backed string.
class OpenRouterTextChainAdapter implements AIAdapter {
  final List<String> modelChain;
  final String _apiKey;
  final String _endpoint;
  final Duration _timeout;
  final http.Client _httpClient;
  final bool _ownsClient;

  OpenRouterTextChainAdapter({
    required List<String> modelChain,
    required String apiKey,
    String endpoint = 'https://openrouter.ai/api/v1/chat/completions',
    Duration timeout = const Duration(seconds: 30),
    http.Client? httpClient,
  })  : assert(modelChain.isNotEmpty, 'modelChain must not be empty'),
        modelChain = List.unmodifiable(modelChain),
        _apiKey = apiKey,
        _endpoint = endpoint,
        _timeout = timeout,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  @override
  String get providerId => 'openrouter-text';

  @override
  Set<AICapability> get capabilities => {
        AICapability.textGeneration,
        AICapability.jsonMode,
      };

  @override
  Future<AICompletionResponse> complete(AICompletionRequest request) async {
    Object? lastError;
    for (final modelId in modelChain) {
      // textGeneration-only capability so the underlying adapter sends
      // temperature/max_tokens (chat), not image modalities.
      final adapter = OpenRouterAdapter(
        config: AIModelConfig(
          provider: 'openrouter',
          modelId: modelId,
          endpoint: _endpoint,
          apiKeyEnvVar: 'Riverflow_V2_Fast',
          capabilities: const {AICapability.textGeneration},
          timeout: _timeout,
        ),
        apiKey: _apiKey,
        httpClient: _httpClient, // shared; not owned by the inner adapter
      );
      try {
        return await adapter.complete(request);
      } catch (e) {
        lastError = e;
        // Try the next model in the chain.
      }
    }
    throw AIAdapterException(
      'All OpenRouter free models failed (${modelChain.length} tried). '
      'Last error: $lastError',
      provider: providerId,
    );
  }

  @override
  void dispose() {
    if (_ownsClient) _httpClient.close();
  }
}
