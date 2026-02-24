import 'dart:developer' as developer;

import 'openrouter_image_service.dart';

class AIImageResult {
  final String? imageDataUrl;
  final bool isGenerated;

  const AIImageResult({this.imageDataUrl, this.isGenerated = false});
}

class AIImageGenerator {
  final OpenRouterImageService? _service;

  const AIImageGenerator({OpenRouterImageService? service}) : _service = service;

  Future<AIImageResult> _generate({required String prompt}) async {
    if (_service == null) {
      return const AIImageResult();
    }

    try {
      final dataUrl = await _service.generateImage(prompt: prompt);
      return AIImageResult(imageDataUrl: dataUrl, isGenerated: true);
    } catch (e) {
      developer.log(
        'AI image generation failed',
        name: 'AIImageGenerator',
        error: e,
      );
      return const AIImageResult();
    }
  }

  Future<AIImageResult> generateAchievementBadge({
    required String achievementName,
    required String category,
  }) {
    final prompt = 'Create a clean, flat-design circular badge icon for a '
        'school achievement called "$achievementName" in the '
        '"$category" category. Use vibrant colors, simple '
        'shapes, no text. Suitable for a mobile app badge.';
    return _generate(prompt: prompt);
  }
}
