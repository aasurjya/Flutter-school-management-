import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_management/core/ai/adapters/deepseek_adapter.dart';
import 'package:school_management/core/ai/models/ai_capability.dart';
import 'package:school_management/core/ai/models/ai_completion_request.dart';
import 'package:school_management/core/ai/models/ai_model_config.dart';

void main() {
  const config = AIModelConfig(
    provider: 'deepseek',
    modelId: 'deepseek-chat',
    endpoint: 'https://api.deepseek.com/chat/completions',
    apiKeyEnvVar: 'Deepseek_API',
  );

  group('DeepSeekAdapter', () {
    test('providerId returns deepseek', () {
      final adapter = DeepSeekAdapter(
        config: config,
        apiKey: 'test-key',
        httpClient: MockClient((_) async => http.Response('', 200)),
      );
      expect(adapter.providerId, 'deepseek');
      adapter.dispose();
    });

    test('capabilities include textGeneration and jsonMode', () {
      final adapter = DeepSeekAdapter(
        config: config,
        apiKey: 'test-key',
        httpClient: MockClient((_) async => http.Response('', 200)),
      );
      expect(adapter.capabilities, contains(AICapability.textGeneration));
      expect(adapter.capabilities, contains(AICapability.jsonMode));
      adapter.dispose();
    });

    test('complete returns response text on success', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'deepseek-chat');
        expect(body['messages'], isNotEmpty);

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'Hello from DeepSeek'}
              }
            ],
            'usage': {'total_tokens': 42},
          }),
          200,
        );
      });

      final adapter = DeepSeekAdapter(
        config: config,
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final response = await adapter.complete(
        AICompletionRequest.simple(
          systemPrompt: 'You are helpful.',
          userPrompt: 'Hi',
        ),
      );

      expect(response.text, 'Hello from DeepSeek');
      expect(response.model, 'deepseek-chat');
      expect(response.tokensUsed, 42);
      expect(response.isFromCache, false);

      adapter.dispose();
    });

    test('complete throws AIAdapterException on non-200 status', () async {
      final mockClient = MockClient((_) async {
        return http.Response('{"error": "rate limit"}', 429);
      });

      final adapter = DeepSeekAdapter(
        config: config,
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      expect(
        () => adapter.complete(
          AICompletionRequest.simple(
            systemPrompt: 'test',
            userPrompt: 'test',
          ),
        ),
        throwsA(isA<AIAdapterException>()),
      );

      adapter.dispose();
    });

    test('complete throws on empty choices', () async {
      final mockClient = MockClient((_) async {
        return http.Response(jsonEncode({'choices': []}), 200);
      });

      final adapter = DeepSeekAdapter(
        config: config,
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      expect(
        () => adapter.complete(
          AICompletionRequest.simple(
            systemPrompt: 'test',
            userPrompt: 'test',
          ),
        ),
        throwsA(isA<AIAdapterException>()),
      );

      adapter.dispose();
    });
  });
}
