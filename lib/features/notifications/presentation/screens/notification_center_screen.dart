import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/notification.dart';
import '../../providers/notification_provider.dart';
import '../widgets/notification_card.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedType;
  bool _unreadOnly = false;

  static const _notificationTypes = [
    null, // All
    'attendance',
    'fee_reminder',
    'grade_update',
    'assignment',
    'announcement',
    'emergency',
    'ptm',
    'achievement',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationNotifierProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            const SizedBox(width: 8),
            unreadCountAsync.when(
              data: (count) => count > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  ref.read(notificationNotifierProvider.notifier).markAllAsRead();
                  break;
                case 'clear_all':
                  _showClearAllDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear all', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Filter chips
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedType == null,
                      onSelected: (_) => setState(() => _selectedType = null),
                    ),
                    const SizedBox(width: 8),
                    ..._notificationTypes
                        .where((t) => t != null)
                        .map(
                          (type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(_getTypeLabel(type!)),
                              selected: _selectedType == type,
                              onSelected: (_) =>
                                  setState(() => _selectedType = type),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              // Unread toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Unread only'),
                      selected: _unreadOnly,
                      onSelected: (val) => setState(() => _unreadOnly = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          // Filter notifications
          var filtered = notifications;
          if (_selectedType != null) {
            filtered =
                filtered.where((n) => n.type == _selectedType).toList();
          }
          if (_unreadOnly) {
            filtered = filtered.where((n) => !n.isRead).toList();
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('No notifications'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(notificationNotifierProvider.notifier)
                  .loadNotifications();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return NotificationCard(
                  notification: filtered[index],
                  onTap: () => _handleNotificationTap(filtered[index]),
                  onDismiss: () => ref
                      .read(notificationNotifierProvider.notifier)
                      .deleteNotification(filtered[index].id),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'attendance':
        return 'Attendance';
      case 'fee_reminder':
        return 'Fees';
      case 'grade_update':
        return 'Grades';
      case 'assignment':
        return 'Assignments';
      case 'announcement':
        return 'Announcements';
      case 'emergency':
        return 'Emergency';
      case 'ptm':
        return 'PTM';
      case 'achievement':
        return 'Achievements';
      default:
        return type;
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }

    // Navigate based on action type
    if (notification.actionType != null && notification.actionData != null) {
      switch (notification.actionType) {
        case 'view_attendance':
          context.push('/student/attendance');
          break;
        case 'view_fee':
          context.push('/student/fees');
          break;
        case 'view_result':
          context.push('/student/results');
          break;
        case 'view_assignment':
          context.push('/student/assignments');
          break;
        case 'view_announcement':
          // Navigate to specific announcement
          break;
        default:
          // Show notification details
          _showNotificationDetails(notification);
      }
    } else {
      _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(AppNotification notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _NotificationIcon(type: notification.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        notification.typeDisplay,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notification.body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              notification.timeAgo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content:
            const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notificationNotifierProvider.notifier).clearAll();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final String type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'attendance':
        icon = Icons.fact_check;
        color = Colors.blue;
        break;
      case 'fee_reminder':
        icon = Icons.payment;
        color = Colors.orange;
        break;
      case 'grade_update':
        icon = Icons.school;
        color = Colors.green;
        break;
      case 'assignment':
        icon = Icons.assignment;
        color = Colors.purple;
        break;
      case 'announcement':
        icon = Icons.campaign;
        color = Colors.teal;
        break;
      case 'emergency':
        icon = Icons.warning;
        color = Colors.red;
        break;
      case 'ptm':
        icon = Icons.people;
        color = Colors.indigo;
        break;
      case 'achievement':
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }
}
