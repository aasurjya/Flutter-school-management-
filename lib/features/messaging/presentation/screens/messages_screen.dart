import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Announcements'),
            Tab(text: 'Notifications'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChatsTab(),
          _AnnouncementsTab(),
          _NotificationsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewMessageSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  void _showNewMessageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Message',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Message Type
                  const Text('Message Type', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Private'),
                        selected: true,
                        onSelected: (_) {},
                      ),
                      ChoiceChip(
                        label: const Text('Class'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                      ChoiceChip(
                        label: const Text('Announcement'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Recipient
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'To',
                      hintText: 'Search for recipient...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subject
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      hintText: 'Enter subject',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Message
                  Expanded(
                    child: TextFormField(
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Type your message...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () {},
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text('Send', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ChatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockChats.length,
      itemBuilder: (context, index) {
        final chat = _mockChats[index];
        return _ChatItem(
          name: chat['name'] as String,
          lastMessage: chat['lastMessage'] as String,
          time: chat['time'] as String,
          unreadCount: chat['unread'] as int,
          isGroup: chat['isGroup'] as bool,
          avatarColor: chat['color'] as Color,
          onTap: () => _openChat(context, chat),
        );
      },
    );
  }

  void _openChat(BuildContext context, Map<String, dynamic> chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChatDetailScreen(
          name: chat['name'] as String,
          isGroup: chat['isGroup'] as bool,
        ),
      ),
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockAnnouncements.length,
      itemBuilder: (context, index) {
        final announcement = _mockAnnouncements[index];
        return _AnnouncementCard(
          title: announcement['title'] as String,
          content: announcement['content'] as String,
          date: announcement['date'] as String,
          author: announcement['author'] as String,
          priority: announcement['priority'] as String,
        );
      },
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockNotifications.length,
      itemBuilder: (context, index) {
        final notification = _mockNotifications[index];
        return _NotificationItem(
          title: notification['title'] as String,
          message: notification['message'] as String,
          time: notification['time'] as String,
          type: notification['type'] as String,
          isRead: notification['isRead'] as bool,
        );
      },
    );
  }
}

class _ChatItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isGroup;
  final Color avatarColor;
  final VoidCallback onTap;

  const _ChatItem({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isGroup,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: avatarColor.withValues(alpha: 0.1),
        child: Icon(
          isGroup ? Icons.group : Icons.person,
          color: avatarColor,
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: unreadCount > 0 ? AppColors.primary : Colors.grey,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String content;
  final String date;
  final String author;
  final String priority;

  const _AnnouncementCard({
    required this.title,
    required this.content,
    required this.date,
    required this.author,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = priority == 'high'
        ? AppColors.error
        : priority == 'normal'
            ? AppColors.info
            : Colors.grey;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (priority == 'high')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'IMPORTANT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: Colors.grey[700]),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                author,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const Spacer(),
              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final String type;
  final bool isRead;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconForType(type);
    final color = _getColorForType(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'attendance':
        return Icons.fact_check;
      case 'fee':
        return Icons.payment;
      case 'exam':
        return Icons.assignment;
      case 'event':
        return Icons.event;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'attendance':
        return AppColors.warning;
      case 'fee':
        return AppColors.error;
      case 'exam':
        return AppColors.info;
      case 'event':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}

class _ChatDetailScreen extends StatelessWidget {
  final String name;
  final bool isGroup;

  const _ChatDetailScreen({required this.name, required this.isGroup});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                isGroup ? Icons.group : Icons.person,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16)),
                if (isGroup)
                  Text(
                    '42 members',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _MessageBubble(
                  message: 'Hello! How is Arjun doing in class?',
                  time: '10:30 AM',
                  isMe: false,
                  senderName: 'Parent',
                ),
                _MessageBubble(
                  message: 'Hi! Arjun is doing very well. He\'s been very attentive in class lately.',
                  time: '10:32 AM',
                  isMe: true,
                ),
                _MessageBubble(
                  message: 'That\'s great to hear! We\'ve been helping him with his studies at home.',
                  time: '10:35 AM',
                  isMe: false,
                  senderName: 'Parent',
                ),
                _MessageBubble(
                  message: 'It shows! His recent test scores have improved significantly. Keep up the good work!',
                  time: '10:38 AM',
                  isMe: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;
  final String? senderName;

  const _MessageBubble({
    required this.message,
    required this.time,
    required this.isMe,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe && senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mock Data
final _mockChats = [
  {
    'name': 'Class 10-A Parents',
    'lastMessage': 'PTM scheduled for next Saturday',
    'time': '10:30 AM',
    'unread': 3,
    'isGroup': true,
    'color': AppColors.primary,
  },
  {
    'name': 'Mr. Rajesh Kumar (Parent)',
    'lastMessage': 'Thank you for the update',
    'time': '9:15 AM',
    'unread': 0,
    'isGroup': false,
    'color': AppColors.secondary,
  },
  {
    'name': 'Teachers Group',
    'lastMessage': 'Staff meeting at 3 PM',
    'time': 'Yesterday',
    'unread': 5,
    'isGroup': true,
    'color': AppColors.accent,
  },
  {
    'name': 'Mrs. Sunita Sharma (Parent)',
    'lastMessage': 'How is Priya doing in class?',
    'time': 'Yesterday',
    'unread': 1,
    'isGroup': false,
    'color': AppColors.info,
  },
];

final _mockAnnouncements = [
  {
    'title': 'Winter Vacation Notice',
    'content': 'School will remain closed from December 25 to January 5 for winter vacation. Classes will resume on January 6, 2025.',
    'date': 'Dec 4, 2024',
    'author': 'Principal',
    'priority': 'high',
  },
  {
    'title': 'Annual Day Celebration',
    'content': 'Annual Day will be celebrated on December 20th. All students are requested to participate in various cultural activities.',
    'date': 'Dec 2, 2024',
    'author': 'Cultural Committee',
    'priority': 'normal',
  },
  {
    'title': 'Fee Payment Reminder',
    'content': 'Term 2 fee payment deadline is December 15th. Please clear your dues to avoid late fee charges.',
    'date': 'Dec 1, 2024',
    'author': 'Accounts Department',
    'priority': 'normal',
  },
];

final _mockNotifications = [
  {
    'title': 'Attendance Alert',
    'message': 'Your child Arjun was marked absent today.',
    'time': '1 hour ago',
    'type': 'attendance',
    'isRead': false,
  },
  {
    'title': 'Fee Payment Due',
    'message': 'Term 2 fee payment of ₹25,000 is due in 5 days.',
    'time': '3 hours ago',
    'type': 'fee',
    'isRead': false,
  },
  {
    'title': 'Exam Results Published',
    'message': 'Mid-term examination results have been published.',
    'time': 'Yesterday',
    'type': 'exam',
    'isRead': true,
  },
  {
    'title': 'PTM Scheduled',
    'message': 'Parent-Teacher Meeting scheduled for Dec 14, 2024.',
    'time': '2 days ago',
    'type': 'event',
    'isRead': true,
  },
];
