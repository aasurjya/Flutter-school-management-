/// Notification model
class AppNotification {
  final String id;
  final String tenantId;
  final String userId;
  final String type;
  final String priority;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? actionType;
  final Map<String, dynamic>? actionData;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.type,
    this.priority = 'normal',
    required this.title,
    required this.body,
    this.data,
    this.actionType,
    this.actionData,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      tenantId: json['tenant_id'],
      userId: json['user_id'],
      type: json['type'] ?? 'general',
      priority: json['priority'] ?? 'normal',
      title: json['title'],
      body: json['body'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      actionType: json['action_type'],
      actionData: json['action_data'] != null
          ? Map<String, dynamic>.from(json['action_data'])
          : null,
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'user_id': userId,
      'type': type,
      'priority': priority,
      'title': title,
      'body': body,
      'data': data,
      'action_type': actionType,
      'action_data': actionData,
      'is_read': isRead,
    };
  }

  String get typeDisplay {
    switch (type) {
      case 'attendance':
        return 'Attendance';
      case 'fee_reminder':
        return 'Fee Reminder';
      case 'grade_update':
        return 'Grade Update';
      case 'assignment':
        return 'Assignment';
      case 'announcement':
        return 'Announcement';
      case 'emergency':
        return 'Emergency';
      case 'ptm':
        return 'PTM';
      case 'achievement':
        return 'Achievement';
      case 'general':
      default:
        return 'General';
    }
  }

  bool get isUrgent => priority == 'urgent' || priority == 'high';

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
