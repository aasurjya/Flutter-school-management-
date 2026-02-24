import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekException implements Exception {
  final String message;
  final int? statusCode;

  const DeepSeekException(this.message, {this.statusCode});

  @override
  String toString() => 'DeepSeekException($statusCode): $message';
}

class DeepSeekService {
  static const _baseUrl = 'https://api.deepseek.com/chat/completions';
  static const _model = 'deepseek-chat';
  static const _timeout = Duration(seconds: 15);

  final String _apiKey;
  final http.Client _httpClient;
  final bool _ownsClient;

  DeepSeekService({
    required String apiKey,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  Future<String> chatCompletion({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 300,
  }) async {
    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    final response = await _httpClient
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw DeepSeekException(
        'API returned ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const DeepSeekException('No choices in response');
    }

    final content = choices[0]['message']?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw const DeepSeekException('Empty content in response');
    }

    return content.trim();
  }

  void dispose() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }
}
