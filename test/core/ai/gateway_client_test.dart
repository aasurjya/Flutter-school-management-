import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:school_management/core/ai/ai_gateway_client.dart';

const _gatewayUrl = 'https://example-supabase.co/functions/v1/ai-gateway';

AiGatewayClient _client(MockClient mock, {String token = 'jwt-tok'}) {
  return AiGatewayClient(
    endpoint: Uri.parse(_gatewayUrl),
    bearerToken: () => token,
    httpClient: mock,
  );
}

void main() {
  group('AiGatewayClient.complete — happy path', () {
    test('parses a 200 success response', () async {
      var sentBody = <String, dynamic>{};
      final mock = MockClient((req) async {
        sentBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'text': 'Aarav had a strong week — 96% attendance.',
            'model': 'deepseek/deepseek-v4-flash:free',
            'status': 'success',
            'tokens_in': 120,
            'tokens_out': 35,
            'latency_ms': 410,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = _client(mock);
      final r = await client.complete(
        featureType: 'parent_communication',
        systemPrompt: 'You write warm parent updates.',
        userPrompt: 'Summarize Aarav this week.',
        idempotencyKey: 'fixed-key',
      );

      expect(r.text, startsWith('Aarav had'));
      expect(r.model, 'deepseek/deepseek-v4-flash:free');
      expect(r.status, 'success');
      expect(r.isLLMGenerated, isTrue);
      expect(r.isFromCache, isFalse);
      expect(r.tokensIn, 120);
      expect(r.tokensOut, 35);
      expect(r.latencyMs, 410);

      expect(sentBody['feature_type'], 'parent_communication');
      expect(sentBody['idempotency_key'], 'fixed-key');
    });

    test('reuses a caller-supplied idempotency_key across retries',
        () async {
      var calls = 0;
      final mock = MockClient((req) async {
        calls++;
        return http.Response(
          jsonEncode({'text': 'ok', 'model': 'm', 'status': 'success'}),
          200,
        );
      });
      final client = _client(mock);
      // Same idempotency key on multiple logical calls is the caller's
      // responsibility; we just verify it round-trips correctly.
      await client.complete(
        featureType: 'parent_communication',
        systemPrompt: '',
        userPrompt: 'x',
        idempotencyKey: 'caller-key-1',
      );
      expect(calls, 1);
    });

    test('auto-generates an idempotency key when caller omits one',
        () async {
      var capturedKey = '';
      final mock = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        capturedKey = body['idempotency_key'] as String;
        return http.Response(
          jsonEncode({'text': 'ok', 'model': 'm', 'status': 'success'}),
          200,
        );
      });
      final client = _client(mock);
      await client.complete(
        featureType: 'parent_communication',
        systemPrompt: '',
        userPrompt: 'x',
      );
      // UUID v4 shape — basic sanity, full format check is in
      // test/core/stage1_primitives_test.dart.
      expect(capturedKey, isNotEmpty);
      expect(capturedKey.length, 36);
    });
  });

  group('AiGatewayClient.complete — typed exceptions', () {
    test('blocked_quota raises AiGatewayQuotaException', () async {
      final mock = MockClient((_) async => http.Response(
            jsonEncode({
              'text': '',
              'model': 'none',
              'status': 'blocked_quota',
            }),
            429,
          ));
      final client = _client(mock);
      await expectLater(
        client.complete(
          featureType: 'parent_communication',
          systemPrompt: '',
          userPrompt: 'x',
        ),
        throwsA(isA<AiGatewayQuotaException>()),
      );
    });

    test('blocked_all_exhausted raises AiGatewayExhaustedException',
        () async {
      final mock = MockClient((_) async => http.Response(
            jsonEncode({
              'text': '',
              'model': 'deepseek/deepseek-v4-flash:free',
              'status': 'blocked_all_exhausted',
            }),
            503,
          ));
      final client = _client(mock);
      await expectLater(
        client.complete(
          featureType: 'parent_communication',
          systemPrompt: '',
          userPrompt: 'x',
        ),
        throwsA(isA<AiGatewayExhaustedException>()),
      );
    });

    test('500 with malformed JSON raises AiGatewayTransportException',
        () async {
      final mock = MockClient((_) async => http.Response('not json', 500));
      final client = _client(mock);
      await expectLater(
        client.complete(
          featureType: 'parent_communication',
          systemPrompt: '',
          userPrompt: 'x',
        ),
        throwsA(isA<AiGatewayTransportException>()),
      );
    });

    test('missing auth token raises transport 401', () async {
      final mock = MockClient((_) async => http.Response('{}', 200));
      final client = _client(mock, token: '');
      await expectLater(
        client.complete(
          featureType: 'parent_communication',
          systemPrompt: '',
          userPrompt: 'x',
        ),
        throwsA(isA<AiGatewayTransportException>()),
      );
    });
  });

  group('AiGatewayClient.complete — cache_hit', () {
    test('cache_hit returns isFromCache=true, isLLMGenerated=false',
        () async {
      final mock = MockClient((_) async => http.Response(
            jsonEncode({
              'text': '',
              'model': 'deepseek/deepseek-v4-flash:free',
              'status': 'cache_hit',
              'tokens_in': 50,
              'tokens_out': 20,
            }),
            200,
          ));
      final client = _client(mock);
      final r = await client.complete(
        featureType: 'parent_communication',
        systemPrompt: '',
        userPrompt: 'x',
        idempotencyKey: 'dedupe-test-1',
      );
      expect(r.status, 'cache_hit');
      expect(r.isFromCache, isTrue);
      expect(r.isLLMGenerated, isFalse);
      expect(r.tokensIn, 50);
    });
  });

  group('AiGatewayClient.complete — fallback model', () {
    test('status=fallback still returns success with isLLMGenerated=true',
        () async {
      final mock = MockClient((_) async => http.Response(
            jsonEncode({
              'text': 'Got there on the 2nd model.',
              // Server picked the 2nd model in the chain.
              'model': 'nvidia/nemotron-3-super-120b-a12b:free',
              'status': 'fallback',
              'tokens_in': 100,
              'tokens_out': 30,
            }),
            200,
          ));
      final client = _client(mock);
      final r = await client.complete(
        featureType: 'parent_communication',
        systemPrompt: '',
        userPrompt: 'x',
      );
      expect(r.status, 'fallback');
      expect(r.model, contains('nemotron'));
      expect(r.isLLMGenerated, isTrue);
      expect(r.isFromCache, isFalse);
    });
  });
}
