import '../models/whatsapp_config.dart';
import 'base_repository.dart';

class WhatsAppRepository extends BaseRepository {
  WhatsAppRepository(super.client);

  static const _configTable = 'sms_whatsapp_configs';
  static const _logsTable = 'notification_logs';

  // ----------------------------------------------------------------
  // Config
  // ----------------------------------------------------------------

  Future<WhatsAppConfig?> getConfig() async {
    final tid = requireTenantId;
    final response = await client
        .from(_configTable)
        .select()
        .eq('tenant_id', tid)
        .maybeSingle();
    if (response == null) return null;
    return WhatsAppConfig.fromJson(response);
  }

  Future<WhatsAppConfig> saveConfig(WhatsAppConfig config) async {
    final tid = requireTenantId;
    final payload = {
      ...config.toJson(),
      'tenant_id': tid,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Remove id from payload so upsert resolves on tenant_id unique constraint
    payload.remove('id');

    final response = await client
        .from(_configTable)
        .upsert(payload, onConflict: 'tenant_id')
        .select()
        .single();

    return WhatsAppConfig.fromJson(response);
  }

  // ----------------------------------------------------------------
  // Logs
  // ----------------------------------------------------------------

  Future<List<NotificationLog>> getLogs({int limit = 50}) async {
    final tid = requireTenantId;
    final response = await client
        .from(_logsTable)
        .select()
        .eq('tenant_id', tid)
        .order('sent_at', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((e) => NotificationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ----------------------------------------------------------------
  // Test Message
  // ----------------------------------------------------------------

  /// Logs a simulated test message and returns true on success.
  Future<bool> sendTestMessage({
    required String channel,
    required String phone,
    required String message,
  }) async {
    try {
      final tid = requireTenantId;
      await client.from(_logsTable).insert({
        'tenant_id': tid,
        'channel': channel,
        'recipient_phone': phone,
        'recipient_name': 'Test Recipient',
        'message_body': message,
        'message_template': 'test',
        'status': 'sent',
        'triggered_by': 'manual_test',
        'sent_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ----------------------------------------------------------------
  // Delivery Stats
  // ----------------------------------------------------------------

  Future<Map<String, int>> getDeliveryStats() async {
    final tid = requireTenantId;

    final rows = await client
        .from(_logsTable)
        .select('status')
        .eq('tenant_id', tid);

    final counts = <String, int>{'sent': 0, 'delivered': 0, 'failed': 0, 'pending': 0};

    for (final row in rows as List<dynamic>) {
      final status = (row as Map<String, dynamic>)['status'] as String? ?? 'sent';
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }
}
