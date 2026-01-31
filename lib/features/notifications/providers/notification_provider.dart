import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/notification.dart';
import '../../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final notificationsProvider = FutureProvider.family<List<AppNotification>, NotificationFilter>(
  (ref, filter) async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.getNotifications(
      unreadOnly: filter.unreadOnly,
      type: filter.type,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final unreadCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount();
});

final notificationByIdProvider = FutureProvider.family<AppNotification?, String>(
  (ref, notificationId) async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.getNotificationById(notificationId);
  },
);

// Notification state notifier for managing operations
class NotificationNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications({bool unreadOnly = false, String? type}) async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.getNotifications(
        unreadOnly: unreadOnly,
        type: type,
      );
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
    _ref.invalidate(unreadCountProvider);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    _ref.invalidate(unreadCountProvider);
    await loadNotifications();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _repository.deleteNotification(notificationId);
    _ref.invalidate(unreadCountProvider);
    await loadNotifications();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    _ref.invalidate(unreadCountProvider);
    state = const AsyncValue.data([]);
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<List<AppNotification>>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository, ref);
});

// Filter class
class NotificationFilter {
  final bool unreadOnly;
  final String? type;
  final int limit;
  final int offset;

  const NotificationFilter({
    this.unreadOnly = false,
    this.type,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationFilter &&
        other.unreadOnly == unreadOnly &&
        other.type == type &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(unreadOnly, type, limit, offset);
}
