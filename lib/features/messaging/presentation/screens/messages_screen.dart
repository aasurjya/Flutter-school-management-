import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/pagination/paginated_notifier.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/message.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/messages_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../../../notifications/presentation/widgets/notification_card.dart';
import '../../../../core/copy/warm_strings.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearchVisible = false;

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
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            tooltip: _isSearchVisible ? 'Close search' : 'Search',
            onPressed: () {
              setState(() => _isSearchVisible = !_isSearchVisible);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchVisible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (_) {
                  // Search functionality coming soon
                },
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ChatsTab(),
                _AnnouncementsTab(),
                _NotificationsTab(),
              ],
            ),
          ),
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
                  const Text('Message Type',
                      style: TextStyle(fontWeight: FontWeight.w500)),
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
                      const Spacer(),
                      ElevatedButton.icon(
                        // Starting a brand-new conversation needs a recipient
                        // user_id, but there is no users-search provider yet and
                        // the student<->parent<->user linkage is incomplete
                        // (see ai_message_composer_screen.dart:195). Be honest
                        // instead of silently pretending the message was sent.
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'New conversations are not available yet. '
                                'Open an existing chat to reply.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text('Send',
                            style: TextStyle(color: Colors.white)),
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

class _ChatsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends ConsumerState<_ChatsTab> {
  final _scrollController = ScrollController();
  PaginationScrollListener? _scrollListener;

  @override
  void initState() {
    super.initState();
    // Kick the first page after the widget mounts; `loadInitial` resets
    // offset and emits an isLoading state for the loading spinner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedThreadsProvider.notifier).loadInitial();
    });
    _scrollListener = PaginationScrollListener(
      controller: _scrollController,
      onLoadMore: () => ref.read(paginatedThreadsProvider.notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollListener?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paginatedThreadsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(WarmCopy.loadFailed('chats')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(paginatedThreadsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No messages yet'),
            SizedBox(height: 4),
            Text(
              'Start a conversation using the compose button',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final threads = state.items;
    return RefreshIndicator(
      onRefresh: () => ref.read(paginatedThreadsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        // +1 for the trailing loader when more pages remain.
        itemCount: threads.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= threads.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final thread = threads[index];
          final lastMsgTime = thread.lastMessageAt != null
              ? _formatChatTime(thread.lastMessageAt!)
              : '';
          final lastMsg = thread.lastMessage?.content ?? '';

          return _ChatItem(
            name: thread.displayTitle,
            lastMessage: lastMsg,
            time: lastMsgTime,
            unreadCount: thread.unreadCount ?? 0,
            isGroup: thread.isGroup || thread.isClass,
            avatarColor: AppColors.primary,
            onTap: () => _openChat(context, thread),
          );
        },
      ),
    );
  }

  String _formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    }
    return '${dateTime.day}/${dateTime.month}';
  }

  void _openChat(BuildContext context, Thread thread) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChatDetailScreen(thread: thread),
      ),
    );
  }
}

class _AnnouncementsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider(true));

    return announcementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(WarmCopy.loadFailed('announcements')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(announcementsProvider(true)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (announcements) {
        if (announcements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No announcements yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            final dateStr = announcement.createdAt != null
                ? '${_monthName(announcement.createdAt!.month)} ${announcement.createdAt!.day}, ${announcement.createdAt!.year}'
                : '';
            return _AnnouncementCard(
              title: announcement.title,
              content: announcement.content,
              date: dateStr,
              author: announcement.createdByName ?? 'Unknown',
              priority: announcement.priority,
            );
          },
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _NotificationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationNotifierProvider);
    return notificationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "Couldn't load notifications.",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No notifications yet'),
                SizedBox(height: 4),
                Text(
                  'You will see important alerts here',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final n = items[index];
            return NotificationCard(
              notification: n,
              onTap: () => ref
                  .read(notificationNotifierProvider.notifier)
                  .markAsRead(n.id),
              onDismiss: () => ref
                  .read(notificationNotifierProvider.notifier)
                  .deleteNotification(n.id),
            );
          },
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

class _ChatDetailScreen extends ConsumerStatefulWidget {
  final Thread thread;

  const _ChatDetailScreen({required this.thread});

  @override
  ConsumerState<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<_ChatDetailScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  bool get _isGroup => widget.thread.isGroup || widget.thread.isClass;

  @override
  void initState() {
    super.initState();
    // Load this thread's real messages into the shared notifier on open.
    Future.microtask(() => ref
        .read(messagesNotifierProvider.notifier)
        .loadMessages(threadId: widget.thread.id));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(messagesNotifierProvider.notifier)
          .sendMessage(content: text);
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't send. Tap send to try again."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesNotifierProvider);
    final myId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                _isGroup ? Icons.group : Icons.person,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.thread.displayTitle,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "Couldn't load messages.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Say hello.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                // Repository returns newest-first; reverse so the latest sits
                // at the bottom and the view opens scrolled to it.
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = myId != null && m.senderId == myId;
                    return _MessageBubble(
                      message: m.content,
                      time: _formatTime(m.createdAt),
                      isMe: isMe,
                      senderName: isMe ? null : m.senderName,
                    );
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _controller,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$hour12:$m $ampm';
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
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
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                tooltip: 'Send',
                onPressed: sending ? null : onSend,
              ),
            ),
          ],
        ),
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
                  style: const TextStyle(
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
