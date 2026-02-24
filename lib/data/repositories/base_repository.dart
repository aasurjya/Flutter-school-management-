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
}
