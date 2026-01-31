import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import 'base_repository.dart';

class NotificationRepository extends BaseRepository {
  NotificationRepository(super.client);

  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('notifications')
        .select()
        .eq('user_id', currentUserId!);

    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    if (type != null) {
      query = query.eq('type', type);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AppNotification.fromJson(json))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await client
        .from('notifications')
        .select('id')
        .eq('user_id', currentUserId!)
        .eq('is_read', false);

    return (response as List).length;
  }

  Future<AppNotification?> getNotificationById(String notificationId) async {
    final response = await client
        .from('notifications')
        .select()
        .eq('id', notificationId)
        .maybeSingle();

    if (response == null) return null;
    return AppNotification.fromJson(response);
  }

  Future<void> markAsRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', currentUserId!)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await client.from('notifications').delete().eq('id', notificationId);
  }

  Future<void> clearAll() async {
    await client.from('notifications').delete().eq('user_id', currentUserId!);
  }

  Future<AppNotification> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String priority = 'normal',
    String? actionType,
    Map<String, dynamic>? actionData,
  }) async {
    final response = await client
        .from('notifications')
        .insert({
          'tenant_id': tenantId,
          'user_id': userId,
          'type': type,
          'title': title,
          'body': body,
          'priority': priority,
          'action_type': actionType,
          'action_data': actionData,
        })
        .select()
        .single();

    return AppNotification.fromJson(response);
  }

  // Subscribe to real-time notifications
  RealtimeChannel subscribeToNotifications({
    required void Function(AppNotification notification) onNewNotification,
  }) {
    return subscribeToTable(
      'notifications',
      filter: 'user_id=eq.$currentUserId',
      onInsert: (payload) {
        final notification = AppNotification.fromJson(payload.newRecord);
        onNewNotification(notification);
      },
    );
  }
}
