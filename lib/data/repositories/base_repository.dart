import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
