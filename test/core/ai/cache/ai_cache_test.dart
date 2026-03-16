import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/ai/cache/ai_cache.dart';
import 'package:school_management/core/ai/cache/ai_cache_key.dart';
import 'package:school_management/core/ai/models/ai_completion_request.dart';
import 'package:school_management/core/ai/models/ai_completion_response.dart';

void main() {
  group('AICache', () {
    late AICache cache;

    setUp(() {
      cache = AICache(maxEntries: 5);
    });

    AICompletionRequest makeRequest(String prompt) =>
        AICompletionRequest.simple(
          systemPrompt: 'system',
          userPrompt: prompt,
        );

    const testResponse = AICompletionResponse(
      text: 'Hello world',
      model: 'test-model',
      tokensUsed: 10,
    );

    test('get returns null on cache miss', () {
      final result = cache.get(makeRequest('test'), 'provider');
      expect(result, isNull);
    });

    test('put then get returns cached response', () {
      final request = makeRequest('test');
      cache.put(request, 'provider', testResponse);

      final result = cache.get(request, 'provider');
      expect(result, isNotNull);
      expect(result!.text, 'Hello world');
      expect(result.isFromCache, true);
    });

    test('hit count increments on cache hits', () {
      final request = makeRequest('test');
      cache.put(request, 'provider', testResponse);

      cache.get(request, 'provider');
      cache.get(request, 'provider');
      cache.get(request, 'provider');

      expect(cache.totalHits, 3);
    });

    test('expired entries return null', () {
      final request = makeRequest('test');
      cache.put(
        request,
        'provider',
        testResponse,
        ttl: Duration.zero, // Immediately expires.
      );

      final result = cache.get(request, 'provider');
      expect(result, isNull);
    });

    test('LRU eviction removes oldest entry when maxEntries exceeded', () {
      for (var i = 0; i < 6; i++) {
        cache.put(
          makeRequest('prompt-$i'),
          'provider',
          AICompletionResponse(text: 'response-$i', model: 'test'),
        );
      }

      // Cache has maxEntries=5, so first entry should be evicted.
      expect(cache.length, 5);
      expect(cache.get(makeRequest('prompt-0'), 'provider'), isNull);
      expect(cache.get(makeRequest('prompt-5'), 'provider'), isNotNull);
    });

    test('invalidateMatching removes matching entries', () {
      cache.put(
        makeRequest('attendance report'),
        'provider',
        const AICompletionResponse(text: 'Attendance is 95%', model: 'test'),
      );
      cache.put(
        makeRequest('fee status'),
        'provider',
        const AICompletionResponse(text: 'Fees are paid', model: 'test'),
      );

      final removed = cache.invalidateMatching('attendance');
      expect(removed, 1);
      expect(cache.length, 1);
    });

    test('clear removes all entries', () {
      cache.put(makeRequest('a'), 'p', testResponse);
      cache.put(makeRequest('b'), 'p', testResponse);
      cache.clear();
      expect(cache.length, 0);
    });

    test('different providers produce different cache keys', () {
      final request = makeRequest('same prompt');
      final key1 = AICacheKey.compute(request, 'deepseek');
      final key2 = AICacheKey.compute(request, 'claude');
      expect(key1, isNot(equals(key2)));
    });

    test('same request produces same cache key', () {
      final request = makeRequest('same prompt');
      final key1 = AICacheKey.compute(request, 'provider');
      final key2 = AICacheKey.compute(request, 'provider');
      expect(key1, equals(key2));
    });
  });
}
