import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterImageException implements Exception {
  final String message;
  final int? statusCode;

  const OpenRouterImageException(this.message, {this.statusCode});

  @override
  String toString() => 'OpenRouterImageException($statusCode): $message';
}

class OpenRouterImageService {
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'sourceful/riverflow-v2-fast';
  static const _timeout = Duration(seconds: 30);

  final String _apiKey;
  final http.Client _httpClient;
  final bool _ownsClient;

  OpenRouterImageService({
    required String apiKey,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  Future<String> generateImage({required String prompt}) async {
    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'modalities': ['image'],
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
      throw OpenRouterImageException(
        'API returned ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const OpenRouterImageException('No choices in response');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    if (message == null) {
      throw const OpenRouterImageException('No message in response');
    }

    // Check for images array (OpenRouter image generation format)
    final images = message['images'] as List?;
    if (images != null && images.isNotEmpty) {
      final imageUrl = images[0]['image_url']?['url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return imageUrl;
      }
    }

    // Fallback: check content field
    final content = message['content'] as String?;
    if (content != null && content.isNotEmpty) {
      return content.trim();
    }

    throw const OpenRouterImageException('No image data in response');
  }

  void dispose() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }
}
