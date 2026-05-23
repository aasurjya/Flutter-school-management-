import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Retry-with-jitter for Supabase calls.
///
/// Defaults: 3 attempts total (1 initial + 2 retries), exponential backoff
/// 250 ms → 750 ms → 2 s, with ±30 % jitter so a flaky network doesn't
/// produce thundering-herd retries from many devices.
///
/// **Only retries transient transport errors** (timeouts, network failures,
/// 5xx). A 4xx is a bug — retrying doesn't help and would just add latency.
///
/// For writes, the caller is responsible for passing a stable
/// `client_request_id` (see [IdempotencyKey]) so duplicate writes from
/// retried-after-success scenarios become no-ops at the database.
///
/// Usage:
/// ```dart
/// await retryNetwork(() => client
///     .from('messages')
///     .insert({..., 'client_request_id': key}));
/// ```
Future<T> retryNetwork<T>(
  Future<T> Function() op, {
  int maxAttempts = 3,
  Duration initialBackoff = const Duration(milliseconds: 250),
  double jitterRatio = 0.3,
  String label = 'supabase',
}) async {
  assert(maxAttempts >= 1, 'maxAttempts must be >= 1');
  assert(jitterRatio >= 0 && jitterRatio < 1, 'jitterRatio must be in [0,1)');

  final rng = Random();
  Object? lastError;
  StackTrace? lastStack;
  var backoff = initialBackoff;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await op();
    } on PostgrestException catch (e, st) {
      // PostgREST 4xx → don't retry (auth, constraint, validation). 5xx → retry.
      final code = int.tryParse(e.code ?? '') ?? 0;
      if (code >= 400 && code < 500) rethrow;
      lastError = e;
      lastStack = st;
    } on AuthException catch (_) {
      // Auth errors are never transient.
      rethrow;
    } on TimeoutException catch (e, st) {
      lastError = e;
      lastStack = st;
    } catch (e, st) {
      // Treat any other I/O / socket error as transient.
      lastError = e;
      lastStack = st;
    }

    if (attempt == maxAttempts) break;

    final jitterMs = (backoff.inMilliseconds * jitterRatio).toInt();
    final delta = jitterMs == 0 ? 0 : rng.nextInt(jitterMs * 2) - jitterMs;
    final sleep = Duration(milliseconds: backoff.inMilliseconds + delta);
    developer.log(
      'retry $label attempt $attempt/$maxAttempts after ${sleep.inMilliseconds} ms — $lastError',
      name: 'retryNetwork',
    );
    await Future<void>.delayed(sleep);
    backoff *= 3; // 250 → 750 → 2250 ms
  }

  // All attempts exhausted. Re-throw the most recent failure preserving stack.
  Error.throwWithStackTrace(lastError ?? StateError('retryNetwork exhausted'),
      lastStack ?? StackTrace.current);
}
