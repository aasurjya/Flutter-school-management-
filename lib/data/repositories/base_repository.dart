import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/paginated_result.dart';

/// In-memory TTL cache entry for read-heavy, low-change data.
class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Global per-tenant cache store. Keyed by (tenantId, cacheKey).
/// Static so cache survives provider recreation within a session.
final Map<String, _CacheEntry<dynamic>> _globalCache = {};

/// Clear the entire global cache. Call on logout / tenant switch.
void clearAllRepoCache() => _globalCache.clear();

abstract class BaseRepository {
  final SupabaseClient _client;

  BaseRepository(this._client);

  SupabaseClient get client => _client;
  
  String? get currentUserId => _client.auth.currentUser?.id;
  
  String? get tenantId {
    final claims = _client.auth.currentUser?.appMetadata;
    return claims?['tenant_id'] as String?;
  }

  String get requireTenantId {
    final id = tenantId;
    if (id == null) {
      throw StateError(
        'tenantId is null — user has no tenant_id in JWT claims. '
        'Ensure the user is logged in and assigned to a tenant.',
      );
    }
    return id;
  }

  /// True when the current user is super_admin (no tenant context).
  bool get isSuperAdmin => tenantId == null;

  /// Returns tenantId if present, otherwise returns [fallback].
  /// Use this in repositories that super_admin can also access.
  String requireTenantIdOr(String fallback) => tenantId ?? fallback;

  /// Returns tenantId or null — does NOT throw.
  String? get tenantIdOrNull => tenantId;

  /// Runs a paginated query against [table] and returns a [PaginatedResult].
  ///
  /// [builder] receives the base filter builder (from `.from(table).select(select)`)
  /// and applies filters/order before returning it. This helper then appends
  /// `.range(page*pageSize, (page+1)*pageSize - 1)` and runs a parallel count
  /// query to populate [PaginatedResult.totalCount].
  ///
  /// Use this for any list that can grow beyond ~100 rows per tenant.
  Future<PaginatedResult<Map<String, dynamic>>> queryPaginated({
    required String table,
    required String select,
    required int page,
    required int pageSize,
    required PostgrestTransformBuilder<PostgrestList> Function(
            PostgrestFilterBuilder<PostgrestList> query)
        builder,
  }) async {
    final offset = page * pageSize;

    // Data query — apply filters, then range.
    final dataQuery = builder(client.from(table).select(select));
    final response = await dataQuery.range(offset, offset + pageSize - 1);

    // Count query — same filters, head-only count. Reusing the same select
    // is fine; count() ignores returned columns.
    final countQuery = builder(client.from(table).select(select));
    final countRes = await countQuery.count(CountOption.exact);
    final totalCount = countRes.count;

    final items =
        (response as List).map((e) => e as Map<String, dynamic>).toList();
    return PaginatedResult<Map<String, dynamic>>(
      items: items,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
  }

  String get requireUserId {
    final id = currentUserId;
    if (id == null) {
      throw StateError(
        'currentUserId is null — no authenticated user found. '
        'Ensure the user is logged in before calling this method.',
      );
    }
    return id;
  }

  // ---- TTL cache for read-heavy, low-change data ---------------------------
  // Phase 2.1 — reduces repeated DB round-trips for data that rarely changes
  // (classes, sections, subjects, fee_heads, academic_years). Each entry
  // survives for [ttl] and is scoped to the current tenant so there's no
  // cross-tenant leakage.

  /// Read from the cache, or call [loader] and store the result.
  /// [key] should be table-specific (e.g. 'classes:all').
  /// [ttl] defaults to 5 minutes.
  Future<T> cached<T>({
    required String key,
    required Future<T> Function() loader,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final cacheKey = '${tenantId ?? 'global'}:$key';
    final entry = _globalCache[cacheKey];
    if (entry != null && !entry.isExpired) {
      return entry.value as T;
    }
    final value = await loader();
    _globalCache[cacheKey] = _CacheEntry<T>(value, DateTime.now().add(ttl));
    return value;
  }

  /// Invalidate a specific cache entry (call after a write to that table).
  void invalidateCache(String key) {
    final cacheKey = '${tenantId ?? 'global'}:$key';
    _globalCache.remove(cacheKey);
  }

  /// Invalidate all cache entries for the current tenant.
  /// Call on logout or when switching tenants.
  void invalidateAllCache() {
    final prefix = '${tenantId ?? 'global'}:';
    _globalCache.removeWhere((k, _) => k.startsWith(prefix));
  }
  
  RealtimeChannel subscribeToTable(
    String table, {
    required void Function(PostgresChangePayload payload) onInsert,
    void Function(PostgresChangePayload payload)? onUpdate,
    void Function(PostgresChangePayload payload)? onDelete,
    ({String column, String value})? filter,
  }) {
    var channel = _client.channel('public:$table');

    final pgFilter = filter != null
        ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filter.column,
            value: filter.value,
          )
        : null;

    channel = channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: table,
      filter: pgFilter,
      callback: onInsert,
    );

    if (onUpdate != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        filter: pgFilter,
        callback: onUpdate,
      );
    }

    if (onDelete != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        filter: pgFilter,
        callback: onDelete,
      );
    }

    channel.subscribe();
    return channel;
  }
  
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  /// Subscribe to a table and *automatically* unsubscribe when the provided
  /// Riverpod [ref] is disposed.
  ///
  /// Stage 2 / S2.16 — prefer this over [subscribeToTable] in all new code.
  /// The old direct API requires the caller to remember to call
  /// [unsubscribe] in `StateNotifier.dispose()` (and 6 of the 7 existing
  /// subscribe methods on this codebase have no live consumer that does
  /// that). Tying the cleanup to `ref.onDispose` makes the leak impossible
  /// at the call site:
  ///
  /// ```dart
  /// final notificationsProvider = StreamProvider.autoDispose<...>((ref) {
  ///   final repo = ref.watch(notificationRepositoryProvider);
  ///   final controller = StreamController<Notification>();
  ///   repo.subscribeToTableScoped(
  ///     ref,
  ///     'notifications',
  ///     filter: (column: 'user_id', value: userId),
  ///     onInsert: (p) => controller.add(Notification.fromJson(p.newRow)),
  ///   );
  ///   ref.onDispose(controller.close);
  ///   return controller.stream;
  /// });
  /// ```
  RealtimeChannel subscribeToTableScoped(
    Ref ref,
    String table, {
    required void Function(PostgresChangePayload payload) onInsert,
    void Function(PostgresChangePayload payload)? onUpdate,
    void Function(PostgresChangePayload payload)? onDelete,
    ({String column, String value})? filter,
  }) {
    final channel = subscribeToTable(
      table,
      onInsert: onInsert,
      onUpdate: onUpdate,
      onDelete: onDelete,
      filter: filter,
    );
    ref.onDispose(() {
      // Fire-and-forget; the channel is server-side anyway, and we don't
      // want to block dispose on the network round-trip.
      unsubscribe(channel);
    });
    return channel;
  }
}
