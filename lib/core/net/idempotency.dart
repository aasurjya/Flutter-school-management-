import 'dart:math';

/// Generates one v4-shaped UUID per user action; the **same** key is reused
/// across automatic retries of that action so the server's `client_request_id`
/// UNIQUE index can dedupe.
///
/// **Usage pattern:**
/// ```dart
/// final key = IdempotencyKey.generate();
/// // First attempt:
/// await repo.markAttendance(..., clientRequestId: key);
/// // On retry (caller decides — see BaseRepository.retryWrite):
/// await repo.markAttendance(..., clientRequestId: key);
/// // Backend sees the same key on both calls, INSERT ... ON CONFLICT
/// // DO NOTHING means the row is created exactly once.
/// ```
///
/// Why not the `uuid` package? Avoids adding a dependency for a single use
/// site. Cryptographically random isn't required — collision resistance over
/// a single user action's retry window (seconds) is plenty.
class IdempotencyKey {
  IdempotencyKey._();

  static final Random _rng = Random.secure();

  /// Returns a fresh idempotency key (lowercase UUID-v4 shape).
  static String generate() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    // Set version (4) and variant (10xx) per RFC 4122.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
