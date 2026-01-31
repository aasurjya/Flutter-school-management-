import 'package:flutter/material.dart';
import '../../../../data/models/notification.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: notification.isRead
            ? null
            : theme.colorScheme.primaryContainer.withOpacity(0.3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationIcon(
                  type: notification.type,
                  isUrgent: notification.isUrgent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            notification.timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(notification.type)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              notification.typeDisplay,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getTypeColor(notification.type),
                              ),
                            ),
                          ),
                          if (notification.isUrgent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Urgent',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'attendance':
        return Colors.blue;
      case 'fee_reminder':
        return Colors.orange;
      case 'grade_update':
        return Colors.green;
      case 'assignment':
        return Colors.purple;
      case 'announcement':
        return Colors.teal;
      case 'emergency':
        return Colors.red;
      case 'ptm':
        return Colors.indigo;
      case 'achievement':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

class _NotificationIcon extends StatelessWidget {
  final String type;
  final bool isUrgent;

  const _NotificationIcon({
    required this.type,
    this.isUrgent = false,
  });

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

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        if (isUrgent)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
