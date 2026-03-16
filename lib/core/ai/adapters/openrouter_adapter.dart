import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_capability.dart';
import '../models/ai_completion_request.dart';
import '../models/ai_completion_response.dart';
import '../models/ai_model_config.dart';
import 'ai_adapter.dart';
import 'deepseek_adapter.dart' show AIAdapterException;

/// Adapter for the OpenRouter API (used primarily for image generation).
class OpenRouterAdapter implements AIAdapter {
  final AIModelConfig config;
  final http.Client _httpClient;
  final String _apiKey;
  final bool _ownsClient;

  OpenRouterAdapter({
    required this.config,
    required String apiKey,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  @override
  String get providerId => 'openrouter';

  @override
  Set<AICapability> get capabilities => {
        AICapability.textGeneration,
        AICapability.imageGeneration,
      };

  @override
  Future<AICompletionResponse> complete(AICompletionRequest request) async {
    final messages = request.messages
        .map((m) => {'role': m.role.name, 'content': m.content})
        .toList();

    final bodyMap = <String, dynamic>{
      'model': config.modelId,
      'messages': messages,
    };

    // For image generation, add modalities.
    if (config.capabilities.contains(AICapability.imageGeneration)) {
      bodyMap['modalities'] = ['image'];
    } else {
      bodyMap['temperature'] = request.temperature;
      bodyMap['max_tokens'] = request.maxTokens;
    }

    final response = await _httpClient
        .post(
          Uri.parse(config.endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode(bodyMap),
        )
        .timeout(config.timeout);

    if (response.statusCode != 200) {
      throw AIAdapterException(
        'OpenRouter API returned ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
        provider: providerId,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw AIAdapterException(
        'No choices in OpenRouter response',
        provider: providerId,
      );
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    if (message == null) {
      throw AIAdapterException(
        'No message in OpenRouter response',
        provider: providerId,
      );
    }

    // Check for image data first (image generation format).
    final images = message['images'] as List?;
    if (images != null && images.isNotEmpty) {
      final imageUrl = images[0]['image_url']?['url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return AICompletionResponse(
          text: imageUrl,
          model: config.modelId,
        );
      }
    }

    // Fallback: text content.
    final content = message['content'] as String?;
    if (content != null && content.isNotEmpty) {
      return AICompletionResponse(
        text: content.trim(),
        model: config.modelId,
      );
    }

    throw AIAdapterException(
      'No usable data in OpenRouter response',
      provider: providerId,
    );
  }

  @override
  void dispose() {
    if (_ownsClient) _httpClient.close();
  }
}
