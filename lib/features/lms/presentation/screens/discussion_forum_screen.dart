import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/lms_provider.dart';
import '../widgets/forum_post_card.dart';

class DiscussionForumScreen extends ConsumerStatefulWidget {
  final String courseId;

  const DiscussionForumScreen({super.key, required this.courseId});

  @override
  ConsumerState<DiscussionForumScreen> createState() =>
      _DiscussionForumScreenState();
}

class _DiscussionForumScreenState
    extends ConsumerState<DiscussionForumScreen> {
  String? _selectedForumId;

  @override
  Widget build(BuildContext context) {
    final forumsAsync = ref.watch(courseForumsProvider(widget.courseId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Discussion',
            onPressed: () => _showCreateForumDialog(),
          ),
        ],
      ),
      body: forumsAsync.when(
        data: (forums) {
          if (forums.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.forum_outlined,
                      size: 64, color: AppColors.textTertiaryLight),
                  const SizedBox(height: 16),
                  Text(
                    'No discussions yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a discussion to get the conversation going',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showCreateForumDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('New Discussion'),
                  ),
                ],
              ),
            );
          }

          if (_selectedForumId != null) {
            final forum =
                forums.where((f) => f.id == _selectedForumId).firstOrNull;
            if (forum != null) {
              return _ForumPostsView(
                forum: forum,
                onBack: () => setState(() => _selectedForumId = null),
              );
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(courseForumsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: forums.length,
              itemBuilder: (context, index) {
                final forum = forums[index];
                return _ForumListItem(
                  forum: forum,
                  onTap: () =>
                      setState(() => _selectedForumId = forum.id),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showCreateForumDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Discussion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Topic Title *',
                hintText: 'What would you like to discuss?',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(context, {
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim().isNotEmpty
                    ? descCtrl.text.trim()
                    : null,
                'course_id': widget.courseId,
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final repo = ref.read(lmsRepositoryProvider);
        await repo.createForum(result);
        ref.invalidate(courseForumsProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

class _ForumListItem extends StatelessWidget {
  final DiscussionForum forum;
  final VoidCallback onTap;

  const _ForumListItem({required this.forum, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: forum.isPinned
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              forum.isPinned
                  ? Icons.push_pin
                  : forum.isLocked
                      ? Icons.lock_outline
                      : Icons.forum_outlined,
              color:
                  forum.isPinned ? AppColors.warning : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forum.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'by ${forum.createdByName ?? "Unknown"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chat_bubble_outline,
                        size: 12,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight),
                    const SizedBox(width: 4),
                    Text(
                      '${forum.postCount ?? 0}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ],
      ),
    );
  }
}

class _ForumPostsView extends ConsumerStatefulWidget {
  final DiscussionForum forum;
  final VoidCallback onBack;

  const _ForumPostsView({required this.forum, required this.onBack});

  @override
  ConsumerState<_ForumPostsView> createState() =>
      _ForumPostsViewState();
}

class _ForumPostsViewState extends ConsumerState<_ForumPostsView> {
  final _replyController = TextEditingController();
  String? _replyToPostId;
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(forumPostsProvider(widget.forum.id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final repo = ref.read(lmsRepositoryProvider);
    final currentUserId = repo.currentUserId;

    return Column(
      children: [
        // Forum header
        GlassCard(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                    onPressed: widget.onBack,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.forum.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.forum.isLocked)
                    const Icon(Icons.lock_outline,
                        size: 16, color: AppColors.warning),
                ],
              ),
              if (widget.forum.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.forum.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Posts
        Expanded(
          child: postsAsync.when(
            data: (posts) {
              // Organize into threads
              final topLevel =
                  posts.where((p) => p.parentPostId == null).toList();
              final replies = posts.where((p) => p.parentPostId != null);

              if (topLevel.isEmpty) {
                return Center(
                  child: Text(
                    'No posts yet. Be the first to respond!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(forumPostsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: topLevel.length,
                  itemBuilder: (context, index) {
                    final post = topLevel[index];
                    final postReplies = replies
                        .where((r) => r.parentPostId == post.id)
                        .toList()
                      ..sort((a, b) =>
                          a.createdAt.compareTo(b.createdAt));

                    return Column(
                      children: [
                        ForumPostCard(
                          post: post,
                          currentUserId: currentUserId,
                          onReply: widget.forum.isLocked
                              ? null
                              : () => setState(
                                  () => _replyToPostId = post.id),
                          onUpvote: () => _upvotePost(post.id),
                          onMarkAnswer: () =>
                              _markAsAnswer(post.id),
                          onDelete: currentUserId == post.authorId
                              ? () => _deletePost(post.id)
                              : null,
                        ),
                        ...postReplies.map((reply) => ForumPostCard(
                              post: reply,
                              isReply: true,
                              currentUserId: currentUserId,
                              onUpvote: () =>
                                  _upvotePost(reply.id),
                              onDelete:
                                  currentUserId == reply.authorId
                                      ? () =>
                                          _deletePost(reply.id)
                                      : null,
                            )),
                      ],
                    );
                  },
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        // Reply input
        if (!widget.forum.isLocked)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_replyToPostId != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.reply,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      const Text(
                        'Replying...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        tooltip: 'Close',
                        onPressed: () =>
                            setState(() => _replyToPostId = null),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: InputDecoration(
                          hintText: 'Write a response...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          isDense: true,
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isSending ? null : _sendPost,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _sendPost() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      final repo = ref.read(lmsRepositoryProvider);
      await repo.createPost({
        'forum_id': widget.forum.id,
        'content': _replyController.text.trim(),
        'parent_post_id': _replyToPostId,
      });
      _replyController.clear();
      _replyToPostId = null;
      ref.invalidate(forumPostsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _upvotePost(String postId) async {
    try {
      final repo = ref.read(lmsRepositoryProvider);
      await repo.upvotePost(postId);
      ref.invalidate(forumPostsProvider);
    } catch (_) {}
  }

  Future<void> _markAsAnswer(String postId) async {
    try {
      final repo = ref.read(lmsRepositoryProvider);
      await repo.updatePost(postId, {'is_answer': true});
      ref.invalidate(forumPostsProvider);
    } catch (_) {}
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(lmsRepositoryProvider);
        await repo.deletePost(postId);
        ref.invalidate(forumPostsProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
