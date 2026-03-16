import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_capability.dart';
import '../models/ai_completion_request.dart';
import '../models/ai_completion_response.dart';
import '../models/ai_message.dart';
import '../models/ai_model_config.dart';
import 'ai_adapter.dart';

/// Adapter for the DeepSeek chat completion API.
class DeepSeekAdapter implements AIAdapter {
  final AIModelConfig config;
  final http.Client _httpClient;
  final String _apiKey;
  final bool _ownsClient;

  DeepSeekAdapter({
    required this.config,
    required String apiKey,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  @override
  String get providerId => 'deepseek';

  @override
  Set<AICapability> get capabilities => {
        AICapability.textGeneration,
        AICapability.jsonMode,
      };

  @override
  Future<AICompletionResponse> complete(AICompletionRequest request) async {
    final messages = request.messages.map(_toDeepSeekMessage).toList();

    final bodyMap = <String, dynamic>{
      'model': config.modelId,
      'messages': messages,
      'temperature': request.temperature,
      'max_tokens': request.maxTokens,
    };

    if (request.responseFormat == 'json') {
      bodyMap['response_format'] = {'type': 'json_object'};
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
        'DeepSeek API returned ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
        provider: providerId,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw AIAdapterException(
        'No choices in DeepSeek response',
        provider: providerId,
      );
    }

    final content = choices[0]['message']?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw AIAdapterException(
        'Empty content in DeepSeek response',
        provider: providerId,
      );
    }

    final usage = json['usage'] as Map<String, dynamic>?;
    final tokensUsed =
        (usage?['total_tokens'] as int?) ?? 0;

    return AICompletionResponse(
      text: content.trim(),
      model: config.modelId,
      tokensUsed: tokensUsed,
    );
  }

  Map<String, dynamic> _toDeepSeekMessage(AIMessage msg) => {
        'role': msg.role.name,
        'content': msg.content,
      };

  @override
  void dispose() {
    if (_ownsClient) _httpClient.close();
  }
}

/// Exception thrown by any AI adapter.
class AIAdapterException implements Exception {
  final String message;
  final int? statusCode;
  final String provider;

  const AIAdapterException(
    this.message, {
    this.statusCode,
    this.provider = 'unknown',
  });

  @override
  String toString() => 'AIAdapterException($provider, $statusCode): $message';
}
