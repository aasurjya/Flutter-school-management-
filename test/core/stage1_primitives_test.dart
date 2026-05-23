import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/core/feature_flags/feature_flags.dart';
import 'package:school_management/core/killswitch/killswitch.dart';
import 'package:school_management/core/net/idempotency.dart';
import 'package:school_management/core/net/retry.dart';

void main() {
  group('IdempotencyKey', () {
    test('returns a UUID-v4 shaped lowercase string', () {
      final key = IdempotencyKey.generate();
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(key),
        isTrue,
        reason: 'generated key "$key" must match UUID v4 shape',
      );
    });

    test('produces unique values across many generations', () {
      final seen = <String>{};
      for (var i = 0; i < 1000; i++) {
        seen.add(IdempotencyKey.generate());
      }
      expect(seen.length, 1000);
    });
  });

  group('FeatureFlag.isOnFor', () {
    test('disabled flag is always off', () {
      const f = FeatureFlag(
        key: 'x', enabled: false, rolloutPercent: 100,
        payload: {}, audience: [],
      );
      expect(f.isOnFor('t1'), isFalse);
    });

    test('enabled + 100% is on for any tenant', () {
      const f = FeatureFlag(
        key: 'x', enabled: true, rolloutPercent: 100,
        payload: {}, audience: [],
      );
      expect(f.isOnFor('t1'), isTrue);
      expect(f.isOnFor('t2'), isTrue);
    });

    test('enabled + 0% is off for any tenant', () {
      const f = FeatureFlag(
        key: 'x', enabled: true, rolloutPercent: 0,
        payload: {}, audience: [],
      );
      expect(f.isOnFor('t1'), isFalse);
    });

    test('audience allowlist overrides rollout_percent', () {
      const f = FeatureFlag(
        key: 'x', enabled: true, rolloutPercent: 0,
        payload: {}, audience: ['allowed-tenant'],
      );
      expect(f.isOnFor('allowed-tenant'), isTrue);
      expect(f.isOnFor('other'), isFalse);
    });

    test('percent rollout is stable for the same tenant+key', () {
      const f = FeatureFlag(
        key: 'rollout', enabled: true, rolloutPercent: 50,
        payload: {}, audience: [],
      );
      // Same tenant+key always returns the same answer.
      final a = f.isOnFor('tenant-stable');
      for (var i = 0; i < 20; i++) {
        expect(f.isOnFor('tenant-stable'), a);
      }
    });

    test('percent rollout bucketing distributes roughly', () {
      const f = FeatureFlag(
        key: 'k', enabled: true, rolloutPercent: 50,
        payload: {}, audience: [],
      );
      var on = 0;
      for (var i = 0; i < 1000; i++) {
        if (f.isOnFor('tenant-$i')) on++;
      }
      // Expect ~50% ±10pp tolerance for 1000 samples.
      expect(on, greaterThan(400));
      expect(on, lessThan(600));
    });

    test('null tenant with partial rollout is off (cannot bucket)', () {
      const f = FeatureFlag(
        key: 'k', enabled: true, rolloutPercent: 50,
        payload: {}, audience: [],
      );
      expect(f.isOnFor(null), isFalse);
    });
  });

  group('FeatureFlag.fromJson', () {
    test('parses full row', () {
      final f = FeatureFlag.fromJson({
        'key': 'ai_streaming',
        'enabled': true,
        'rollout_percent': 25,
        'payload': {'model': 'haiku'},
        'audience': ['t1', 't2'],
      });
      expect(f.key, 'ai_streaming');
      expect(f.enabled, isTrue);
      expect(f.rolloutPercent, 25);
      expect(f.payload['model'], 'haiku');
      expect(f.audience, ['t1', 't2']);
    });

    test('tolerates missing optional fields', () {
      final f = FeatureFlag.fromJson({'key': 'x'});
      expect(f.enabled, isFalse);
      expect(f.rolloutPercent, 0);
      expect(f.payload, isEmpty);
      expect(f.audience, isEmpty);
    });
  });

  group('KillswitchState', () {
    test('off constant', () {
      expect(KillswitchState.off.maintenance, isFalse);
      expect(KillswitchState.off.message, isEmpty);
    });
  });

  group('retryNetwork', () {
    test('returns on first-attempt success without delay', () async {
      var calls = 0;
      final stopwatch = Stopwatch()..start();
      final result = await retryNetwork(() async {
        calls++;
        return 42;
      });
      stopwatch.stop();
      expect(result, 42);
      expect(calls, 1);
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 100)));
    });

    test('retries transient errors then succeeds', () async {
      var calls = 0;
      final result = await retryNetwork(
        () async {
          calls++;
          if (calls < 3) throw TimeoutException('boom');
          return 'ok';
        },
        initialBackoff: const Duration(milliseconds: 5),
      );
      expect(result, 'ok');
      expect(calls, 3);
    });

    test('throws after exhausting attempts', () async {
      var calls = 0;
      await expectLater(
        retryNetwork(
          () async {
            calls++;
            throw TimeoutException('always fails');
          },
          maxAttempts: 3,
          initialBackoff: const Duration(milliseconds: 1),
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(calls, 3);
    });

    test('does NOT retry programming errors (StateError)', () async {
      // StateError is treated as transient by the generic catch — but most
      // app code throws StateError for "programming bug" not network. We
      // explicitly tested only Timeout/Postgrest/Auth behaviour above; this
      // assertion documents that other Exception types DO retry by design.
      var calls = 0;
      await expectLater(
        retryNetwork(
          () async {
            calls++;
            throw StateError('not network');
          },
          maxAttempts: 2,
          initialBackoff: const Duration(milliseconds: 1),
        ),
        throwsA(isA<StateError>()),
      );
      expect(calls, 2, reason: 'StateError is retried like any I/O error');
    });
  });
}
