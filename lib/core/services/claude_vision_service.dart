import 'dart:convert';
import 'package:http/http.dart' as http;

class ClaudeVisionException implements Exception {
  final String message;
  final int? statusCode;

  const ClaudeVisionException(this.message, {this.statusCode});

  @override
  String toString() => 'ClaudeVisionException($statusCode): $message';
}

/// Calls Claude API (claude-sonnet-4-6) with optional screenshot for vision.
class ClaudeVisionService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';
  static const _version = '2023-06-01';
  static const _timeout = Duration(seconds: 30);

  static const _systemPrompt =
      'You are an AI tutor embedded in a school management app. '
      'When the user sends a message, you can see the current screen they are looking at (provided as an image). '
      'Use what you see on screen to give highly contextual, helpful answers. '
      'Explain concepts shown on screen clearly. Guide students step by step. '
      'Be encouraging, concise, and age-appropriate for school students. '
      'If no image is provided, answer from the conversation context alone. '
      'Keep answers under 200 words unless a detailed explanation is essential.';

  /// Expose system prompt for use by the AIRouter-based tutor.
  static String get systemPromptText => _systemPrompt;

  final String _apiKey;
  final http.Client _httpClient;
  final bool _ownsClient;

  ClaudeVisionService({
    required String apiKey,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  /// Ask the AI tutor a question. Optionally include a base64 PNG screenshot.
  Future<String> ask({
    required String question,
    String? screenshotBase64,
    List<Map<String, dynamic>> history = const [],
  }) async {
    final messages = <Map<String, dynamic>>[
      ...history,
      {
        'role': 'user',
        'content': screenshotBase64 != null
            ? [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/png',
                    'data': screenshotBase64,
                  },
                },
                {'type': 'text', 'text': question},
              ]
            : question,
      },
    ];

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1024,
      'system': _systemPrompt,
      'messages': messages,
    });

    final response = await _httpClient
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _apiKey,
            'anthropic-version': _version,
          },
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw ClaudeVisionException(
        'API returned ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (json['content'] as List?)?.first as Map<String, dynamic>?;
    final text = content?['text'] as String?;

    if (text == null || text.isEmpty) {
      throw const ClaudeVisionException('Empty response from Claude API');
    }

    return text;
  }

  void dispose() {
    if (_ownsClient) _httpClient.close();
  }
}
