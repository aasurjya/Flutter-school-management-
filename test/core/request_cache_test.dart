import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/core/cache/request_cache.dart';

void main() {
  group('RequestCache.keyFor', () {
    test('different tenant ids produce different keys', () {
      final a = RequestCache.keyFor(
        tenantId: 'tenant-A',
        namespace: 'students.count',
        params: const {'section_id': 's1'},
      );
      final b = RequestCache.keyFor(
        tenantId: 'tenant-B',
        namespace: 'students.count',
        params: const {'section_id': 's1'},
      );
      expect(a, isNot(b));
    });

    test('null tenant id is encoded as "anon"', () {
      final k = RequestCache.keyFor(
        tenantId: null,
        namespace: 'feature_flags.list',
      );
      expect(k, startsWith('anon::'));
    });

    test('parameter order does not affect key', () {
      final a = RequestCache.keyFor(
        tenantId: 't1',
        namespace: 'q',
        params: const {'a': 1, 'b': 2},
      );
      final b = RequestCache.keyFor(
        tenantId: 't1',
        namespace: 'q',
        params: const {'b': 2, 'a': 1},
      );
      expect(a, b, reason: 'sorted by key for determinism');
    });

    test('null param values are excluded', () {
      final a = RequestCache.keyFor(
        tenantId: 't1',
        namespace: 'q',
        params: const {'section_id': null, 'class_id': 'c1'},
      );
      final b = RequestCache.keyFor(
        tenantId: 't1',
        namespace: 'q',
        params: const {'class_id': 'c1'},
      );
      expect(a, b);
    });
  });

  group('RequestCache.getOrLoad', () {
    test('miss → calls load, hit → does not call load again', () async {
      final cache = RequestCache();
      var calls = 0;
      Future<int> load() async {
        calls++;
        return 42;
      }

      final a = await cache.getOrLoad<int>('k1', load: load);
      final b = await cache.getOrLoad<int>('k1', load: load);
      expect(a, 42);
      expect(b, 42);
      expect(calls, 1, reason: 'second call should hit cache');
    });

    test('expired entry calls load again', () async {
      final cache = RequestCache();
      var calls = 0;
      Future<int> load() async {
        calls++;
        return calls; // returns 1 then 2
      }

      final a = await cache.getOrLoad<int>(
        'k1',
        load: load,
        ttl: const Duration(milliseconds: 10),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final b = await cache.getOrLoad<int>('k1', load: load);
      expect(a, 1);
      expect(b, 2, reason: 'TTL expired → reload');
      expect(calls, 2);
    });

    test('invalidate(key) forces next call to reload', () async {
      final cache = RequestCache();
      var calls = 0;
      Future<int> load() async {
        calls++;
        return calls;
      }

      await cache.getOrLoad<int>('k1', load: load);
      cache.invalidate('k1');
      await cache.getOrLoad<int>('k1', load: load);
      expect(calls, 2);
    });

    test('invalidatePrefix(prefix) drops matching keys', () async {
      final cache = RequestCache();
      await cache.getOrLoad<int>('students.count::a', load: () async => 1);
      await cache.getOrLoad<int>('students.count::b', load: () async => 2);
      await cache.getOrLoad<int>('messages.list::c', load: () async => 3);

      cache.invalidatePrefix('students.count');

      // Re-loading the students keys should miss (call load), but messages
      // should hit (no call).
      var studentsLoads = 0;
      var messagesLoads = 0;
      await cache.getOrLoad<int>(
        'students.count::a',
        load: () async {
          studentsLoads++;
          return 10;
        },
      );
      await cache.getOrLoad<int>(
        'messages.list::c',
        load: () async {
          messagesLoads++;
          return 30;
        },
      );
      expect(studentsLoads, 1);
      expect(messagesLoads, 0);
    });

    test('clear() drops everything', () async {
      final cache = RequestCache();
      await cache.getOrLoad<int>('k1', load: () async => 1);
      await cache.getOrLoad<int>('k2', load: () async => 2);
      cache.clear();
      expect(cache.size, 0);
    });

    test('LRU caps at 200 entries; oldest entry is evicted first', () async {
      final cache = RequestCache();
      // Insert 250 unique keys; oldest 50 should be evicted.
      for (var i = 0; i < 250; i++) {
        await cache.getOrLoad<int>('k$i', load: () async => i);
      }
      expect(cache.size, lessThanOrEqualTo(200));

      // Key k0 was inserted first → should have been evicted.
      var reloaded = false;
      await cache.getOrLoad<int>(
        'k0',
        load: () async {
          reloaded = true;
          return -1;
        },
      );
      expect(reloaded, isTrue, reason: 'k0 was evicted, must reload');
    });

    test('tenant A cache hit does NOT return tenant B data', () async {
      // The cross-tenant guarantee. Same namespace + params, different tenant
      // ids → different keys → never hit each other.
      final cache = RequestCache();

      final keyA = RequestCache.keyFor(
        tenantId: 'tenant-A',
        namespace: 'students.list',
      );
      final keyB = RequestCache.keyFor(
        tenantId: 'tenant-B',
        namespace: 'students.list',
      );

      await cache.getOrLoad<String>(keyA, load: () async => 'A-data');
      var bLoaded = false;
      final result = await cache.getOrLoad<String>(
        keyB,
        load: () async {
          bLoaded = true;
          return 'B-data';
        },
      );
      expect(bLoaded, isTrue);
      expect(result, 'B-data');
    });
  });
}
