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
