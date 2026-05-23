import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';

/// In-memory request cache for Supabase reads.
///
/// **What it solves.** Every screen that opens fires its own provider, which
/// fires a Supabase SELECT. Tabbing between dashboard tabs re-runs the same
/// query. Pulling to refresh re-runs the same query. None of that needs a
/// network round-trip when the data is < 60 seconds old.
///
/// **What it isn't.** Not a write cache, not a persistent cache (Isar handles
/// offline). Pure in-memory TTL — survives app session, dies on cold start.
/// That's intentional: stale data on a fresh launch is worse than a slow one.
///
/// **Tenant safety.** Every key includes the current Supabase auth user's
/// tenant_id (or 'anon' if signed out). A cache hit for tenant A can NEVER
/// return tenant B's rows. Verified by [RequestCache.keyFor].
///
/// **Eviction.** Soft cap of 200 entries, LRU on insert overflow. Plenty for
/// a single session; we're not Wikipedia.
class RequestCache {
  static const int _maxEntries = 200;
  static const Duration _defaultTtl = Duration(seconds: 60);

  // LinkedHashMap insertion order = LRU. Most-recently-used at the back;
  // promote on access by re-inserting.
  final Map<String, _Entry> _entries = <String, _Entry>{};

  /// Returns the cached value if present and not expired, otherwise calls
  /// [load] and caches the result.
  ///
  /// [key] should be built via [keyFor] — never raw strings.
  Future<T> getOrLoad<T>(
    String key, {
    required Future<T> Function() load,
    Duration ttl = _defaultTtl,
  }) async {
    final hit = _entries[key];
    if (hit != null && !hit.isExpired) {
      // Promote LRU position.
      _entries.remove(key);
      _entries[key] = hit;
      return hit.value as T;
    }

    final value = await load();
    _entries[key] = _Entry(value, DateTime.now().add(ttl));

    // Trim if oversize. LinkedHashMap iteration is insertion-order;
    // first key is the oldest.
    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return value;
  }

  /// Invalidate exactly one key. Use after a write that targets that read.
  void invalidate(String key) {
    _entries.remove(key);
  }

  /// Invalidate every cached entry whose key starts with [prefix].
  /// Useful for "flush every cache for this tenant" or "flush every
  /// students-list page after a create".
  void invalidatePrefix(String prefix) {
    _entries.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// Nuke. Use on sign-out so the next signed-in user can never observe
  /// the prior session's data.
  void clear() {
    _entries.clear();
  }

  /// Diagnostic — number of currently-cached entries.
  int get size => _entries.length;

  /// Build a deterministic key from (tenant_id, namespace, params).
  /// Always go through this constructor so we can't accidentally key a
  /// cache entry without the tenant id.
  ///
  /// Example:
  /// ```dart
  /// final key = RequestCache.keyFor(
  ///   tenantId: tenantId,
  ///   namespace: 'students.count',
  ///   params: {'section_id': sectionId},
  /// );
  /// ```
  static String keyFor({
    required String? tenantId,
    required String namespace,
    Map<String, Object?> params = const {},
  }) {
    final paramsString = params.entries
        .where((e) => e.value != null)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final paramsJson =
        jsonEncode({for (final e in paramsString) e.key: e.value});
    return '${tenantId ?? 'anon'}::$namespace::$paramsJson';
  }
}

class _Entry {
  final Object? value;
  final DateTime expiresAt;

  _Entry(this.value, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Process-wide singleton cache. Single instance per app session.
///
/// Providers that wrap a Supabase read should resolve their cache key via
/// [RequestCache.keyFor] using the active tenant_id from JWT.
final requestCacheProvider = Provider<RequestCache>((ref) {
  final cache = RequestCache();
  // On Supabase sign-out, drop everything. This is the cross-tenant-leak
  // safety net even though every key already includes tenant_id.
  final SupabaseClient client = ref.read(supabaseProvider);
  final sub = client.auth.onAuthStateChange.listen((event) {
    if (event.event == AuthChangeEvent.signedOut) {
      cache.clear();
    }
  });
  ref.onDispose(sub.cancel);
  return cache;
});

/// Convenience: caller-facing helper that wraps any provider load with
/// caching. Use from inside a FutureProvider.
///
/// ```dart
/// final studentsCountProvider = FutureProvider.autoDispose
///     .family<int, String?>((ref, sectionId) async {
///   final repo = ref.watch(studentRepositoryProvider);
///   final tenantId = repo.tenantId; // from BaseRepository
///   return cachedLoad(
///     ref,
///     namespace: 'students.count',
///     params: {'section_id': sectionId},
///     tenantId: tenantId,
///     ttl: const Duration(seconds: 30),
///     load: () => repo.getStudentCount(sectionId: sectionId),
///   );
/// });
/// ```
Future<T> cachedLoad<T>(
  Ref ref, {
  required String namespace,
  required String? tenantId,
  required Future<T> Function() load,
  Map<String, Object?> params = const {},
  Duration ttl = const Duration(seconds: 60),
}) {
  final cache = ref.read(requestCacheProvider);
  final key = RequestCache.keyFor(
    tenantId: tenantId,
    namespace: namespace,
    params: params,
  );
  return cache.getOrLoad<T>(key, load: load, ttl: ttl);
}
