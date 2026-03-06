import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../../../shared/widgets/glass_card.dart';

class ForumPostCard extends StatelessWidget {
  final ForumPost post;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onUpvote;
  final VoidCallback? onMarkAnswer;
  final VoidCallback? onDelete;
  final String? currentUserId;
  final bool isTeacher;

  const ForumPostCard({
    super.key,
    required this.post,
    this.isReply = false,
    this.onReply,
    this.onUpvote,
    this.onMarkAnswer,
    this.onDelete,
    this.currentUserId,
    this.isTeacher = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAuthor = currentUserId == post.authorId;
    final timeAgo = _timeAgo(post.createdAt);

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 32 : 0),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        borderColor: post.isAnswer
            ? AppColors.success.withValues(alpha: 0.5)
            : null,
        backgroundColor: post.isAnswer
            ? (isDark
                ? AppColors.success.withValues(alpha: 0.05)
                : AppColors.successLight.withValues(alpha: 0.3))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    (post.authorName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorName ?? 'Unknown',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (post.isAnswer) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 10, color: AppColors.success),
                                  SizedBox(width: 3),
                                  Text(
                                    'Answer',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAuthor || isTeacher)
                  PopupMenuButton<String>(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => [
                      if (isTeacher && !post.isAnswer)
                        const PopupMenuItem(
                          value: 'answer',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 16),
                              SizedBox(width: 8),
                              Text('Mark as Answer'),
                            ],
                          ),
                        ),
                      if (isAuthor)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 16, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      if (value == 'answer') onMarkAnswer?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Content
            Text(
              post.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            // Actions
            Row(
              children: [
                InkWell(
                  onTap: onUpvote,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          post.upvotes > 0
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          size: 14,
                          color: post.upvotes > 0
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight),
                        ),
                        if (post.upvotes > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${post.upvotes}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (onReply != null && !isReply)
                  InkWell(
                    onTap: onReply,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.reply,
                              size: 14,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight),
                          const SizedBox(width: 4),
                          Text(
                            'Reply',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return DateFormat('MMM d, y').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
