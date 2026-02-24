import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../services/ai_image_generator.dart';
import '../services/ai_text_generator.dart';
import '../services/deepseek_service.dart';
import '../services/openrouter_image_service.dart';

final deepSeekServiceProvider = Provider<DeepSeekService?>((ref) {
  final apiKey = AppEnvironment.deepSeekApiKey;
  if (apiKey == null) return null;

  final service = DeepSeekService(apiKey: apiKey);
  ref.onDispose(() => service.dispose());
  return service;
});

final aiTextGeneratorProvider = Provider<AITextGenerator>((ref) {
  final service = ref.watch(deepSeekServiceProvider);
  return AITextGenerator(service: service);
});

final openRouterImageServiceProvider = Provider<OpenRouterImageService?>((ref) {
  final apiKey = AppEnvironment.openRouterApiKey;
  if (apiKey == null) return null;

  final service = OpenRouterImageService(apiKey: apiKey);
  ref.onDispose(() => service.dispose());
  return service;
});

final aiImageGeneratorProvider = Provider<AIImageGenerator>((ref) {
  final service = ref.watch(openRouterImageServiceProvider);
  return AIImageGenerator(service: service);
});
