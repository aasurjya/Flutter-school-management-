import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_capability.dart';
import '../models/ai_completion_request.dart';
import '../models/ai_completion_response.dart';
import '../models/ai_message.dart';
import '../models/ai_model_config.dart';
import 'ai_adapter.dart';
import 'deepseek_adapter.dart' show AIAdapterException;

/// Adapter for the Anthropic Claude Messages API.
///
/// Supports text generation and vision (image input).
class ClaudeAdapter implements AIAdapter {
  static const _anthropicVersion = '2023-06-01';

  final AIModelConfig config;
  final http.Client _httpClient;
  final String _apiKey;
  final bool _ownsClient;

  ClaudeAdapter({
    required this.config,
    required String apiKey,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  @override
  String get providerId => 'claude';

  @override
  Set<AICapability> get capabilities => {
        AICapability.textGeneration,
        AICapability.vision,
      };

  @override
  Future<AICompletionResponse> complete(AICompletionRequest request) async {
    // Separate system message from conversation messages.
    String? systemText;
    final messages = <Map<String, dynamic>>[];

    for (final msg in request.messages) {
      if (msg.role == AIMessageRole.system) {
        systemText = msg.content;
        continue;
      }
      messages.add(_toClaudeMessage(msg));
    }

    final bodyMap = <String, dynamic>{
      'model': config.modelId,
      'max_tokens': request.maxTokens,
      'messages': messages,
    };

    if (systemText != null) {
      bodyMap['system'] = systemText;
    }

    final response = await _httpClient
        .post(
          Uri.parse(config.endpoint),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _apiKey,
            'anthropic-version': _anthropicVersion,
          },
          body: jsonEncode(bodyMap),
        )
        .timeout(config.timeout);

    if (response.statusCode != 200) {
      throw AIAdapterException(
        'Claude API returned ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
        provider: providerId,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final contentBlocks = json['content'] as List?;
    if (contentBlocks == null || contentBlocks.isEmpty) {
      throw AIAdapterException(
        'Empty content in Claude response',
        provider: providerId,
      );
    }

    final text = (contentBlocks.first as Map<String, dynamic>)['text'] as String?;
    if (text == null || text.isEmpty) {
      throw AIAdapterException(
        'No text in Claude response content block',
        provider: providerId,
      );
    }

    final usage = json['usage'] as Map<String, dynamic>?;
    final tokensUsed = ((usage?['input_tokens'] as int?) ?? 0) +
        ((usage?['output_tokens'] as int?) ?? 0);

    return AICompletionResponse(
      text: text,
      model: config.modelId,
      tokensUsed: tokensUsed,
    );
  }

  Map<String, dynamic> _toClaudeMessage(AIMessage msg) {
    final role = msg.role == AIMessageRole.user ? 'user' : 'assistant';

    // If the message has an image, send multimodal content.
    if (msg.imageBase64 != null) {
      return {
        'role': role,
        'content': [
          {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': 'image/png',
              'data': msg.imageBase64,
            },
          },
          {'type': 'text', 'text': msg.content},
        ],
      };
    }

    return {'role': role, 'content': msg.content};
  }

  @override
  void dispose() {
    if (_ownsClient) _httpClient.close();
  }
}
