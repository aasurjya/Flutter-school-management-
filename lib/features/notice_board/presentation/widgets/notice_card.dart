import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/notice_board.dart';
import 'notice_category_chip.dart';

class NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;
  final bool showAdminActions;

  const NoticeCard({
    super.key,
    required this.notice,
    this.onTap,
    this.onPin,
    this.onDelete,
    this.showAdminActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryColor = NoticeCategoryChip.categoryColor(notice.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notice.isPinned ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: notice.isPinned
            ? BorderSide(color: categoryColor.withValues(alpha: 0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: category + pinned icon + time
              Row(
                children: [
                  NoticeCategoryChip(category: notice.category),
                  const Spacer(),
                  if (notice.isPinned) ...[
                    Icon(Icons.push_pin, size: 16, color: categoryColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    notice.timeAgo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  if (showAdminActions) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(
                                notice.isPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(notice.isPinned ? 'Unpin' : 'Pin'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'pin') onPin?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                notice.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Body preview
              Text(
                notice.body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Footer: author + attachment badge
              if (notice.authorName != null || notice.attachmentUrl != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (notice.authorName != null) ...[
                      CircleAvatar(
                        radius: 10,
                        backgroundColor:
                            categoryColor.withValues(alpha: 0.15),
                        child: Text(
                          notice.authorName![0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        notice.authorName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (notice.attachmentUrl != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_file,
                                size: 12, color: AppColors.info),
                            const SizedBox(width: 4),
                            Text(
                              'Attachment',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],

              // Expiry warning
              if (notice.expiresAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 12, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Expires ${_formatDate(notice.expiresAt!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
