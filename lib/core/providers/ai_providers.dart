import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ai/adapters/ai_adapter.dart';
import '../ai/adapters/claude_adapter.dart';
import '../ai/adapters/deepseek_adapter.dart';
import '../ai/adapters/openrouter_adapter.dart';
import '../ai/agents/ai_agent.dart';
import '../ai/agents/tools/compose_message_tool.dart';
import '../ai/agents/tools/fetch_attendance_tool.dart';
import '../ai/agents/tools/fetch_fee_status_tool.dart';
import '../ai/agents/tools/fetch_marks_tool.dart';
import '../ai/agents/tools/fetch_risk_score_tool.dart';
import '../ai/agents/tools/fetch_student_tool.dart';
import '../ai/ai_router.dart';
import '../ai/cache/ai_cache.dart';
import '../ai/context/ai_context_builder.dart';
import '../ai/models/ai_capability.dart';
import '../ai/models/ai_model_config.dart';
import '../config/app_environment.dart';
import '../services/ai_image_generator.dart';
import '../services/ai_staff_text_generator.dart';
import '../services/ai_text_generator.dart';
import '../services/deepseek_service.dart';
import '../services/openrouter_image_service.dart';

// =============================================================================
// Legacy providers — kept as aliases for backward compatibility
// =============================================================================

final deepSeekServiceProvider = Provider<DeepSeekService?>((ref) {
  final apiKey = AppEnvironment.deepSeekApiKey;
  if (apiKey == null) return null;

  final service = DeepSeekService(apiKey: apiKey);
  ref.onDispose(() => service.dispose());
  return service;
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

// =============================================================================
// AI Cache
// =============================================================================

final aiCacheProvider = Provider<AICache>((ref) {
  final cache = AICache();
  // Load persisted cache entries asynchronously — non-blocking.
  cache.loadFromDisk();
  return cache;
});

// =============================================================================
// AI Router — the central dispatcher
// =============================================================================

final aiRouterProvider = Provider<AIRouter?>((ref) {
  final cache = ref.watch(aiCacheProvider);
  final adapters = <AICapability, AIAdapter>{};

  // DeepSeek adapter for text generation.
  final deepSeekKey = AppEnvironment.deepSeekApiKey;
  if (deepSeekKey != null) {
    final adapter = DeepSeekAdapter(
      config: const AIModelConfig(
        provider: 'deepseek',
        modelId: 'deepseek-chat',
        endpoint: 'https://api.deepseek.com/chat/completions',
        apiKeyEnvVar: 'Deepseek_API',
      ),
      apiKey: deepSeekKey,
    );
    adapters[AICapability.textGeneration] = adapter;
    adapters[AICapability.jsonMode] = adapter;
    ref.onDispose(() => adapter.dispose());
  }

  // Claude adapter for vision.
  final claudeKey = AppEnvironment.claudeApiKey;
  if (claudeKey != null) {
    final adapter = ClaudeAdapter(
      config: const AIModelConfig(
        provider: 'claude',
        modelId: 'claude-sonnet-4-6',
        endpoint: 'https://api.anthropic.com/v1/messages',
        apiKeyEnvVar: 'CLAUDE_API_KEY',
        capabilities: {AICapability.textGeneration, AICapability.vision},
        timeout: Duration(seconds: 30),
      ),
      apiKey: claudeKey,
    );
    adapters[AICapability.vision] = adapter;
    // If no DeepSeek key, Claude can handle text too.
    adapters.putIfAbsent(AICapability.textGeneration, () => adapter);
    ref.onDispose(() => adapter.dispose());
  }

  // OpenRouter adapter for image generation.
  final openRouterKey = AppEnvironment.openRouterApiKey;
  if (openRouterKey != null) {
    final adapter = OpenRouterAdapter(
      config: const AIModelConfig(
        provider: 'openrouter',
        modelId: 'sourceful/riverflow-v2-fast',
        endpoint: 'https://openrouter.ai/api/v1/chat/completions',
        apiKeyEnvVar: 'Riverflow_V2_Fast',
        capabilities: {AICapability.imageGeneration},
        timeout: Duration(seconds: 30),
      ),
      apiKey: openRouterKey,
    );
    adapters[AICapability.imageGeneration] = adapter;
    ref.onDispose(() => adapter.dispose());
  }

  if (adapters.isEmpty) return null;

  return AIRouter(adapters: adapters, cache: cache);
});

// =============================================================================
// Text generators — now route through AIRouter with fallback to direct service
// =============================================================================

final aiTextGeneratorProvider = Provider<AITextGenerator>((ref) {
  final router = ref.watch(aiRouterProvider);
  final legacyService = ref.watch(deepSeekServiceProvider);
  return AITextGenerator(service: legacyService, router: router);
});

final aiStaffTextGeneratorProvider = Provider<AIStaffTextGenerator>((ref) {
  final router = ref.watch(aiRouterProvider);
  final legacyService = ref.watch(deepSeekServiceProvider);
  return AIStaffTextGenerator(service: legacyService, router: router);
});

// =============================================================================
// AI Context Builder
// =============================================================================

final aiContextBuilderProvider = Provider<AIContextBuilder>((ref) {
  final client = Supabase.instance.client;
  return AIContextBuilder(client);
});

// =============================================================================
// AI Agent
// =============================================================================

final aiAgentProvider = Provider<AIAgent?>((ref) {
  final router = ref.watch(aiRouterProvider);
  if (router == null) return null;

  final client = Supabase.instance.client;
  return AIAgent(
    router: router,
    tools: [
      FetchStudentTool(client),
      FetchAttendanceTool(client),
      FetchMarksTool(client),
      FetchRiskScoreTool(client),
      FetchFeeStatusTool(client),
      ComposeMessageTool(router),
    ],
  );
});
