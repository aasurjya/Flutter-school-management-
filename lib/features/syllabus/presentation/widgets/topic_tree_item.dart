import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/syllabus_topic.dart';

/// Recursive expandable tree node widget for topic hierarchy.
///
/// Each node indents by [topic.level.depth * 24.0], shows an expand/collapse
/// icon when children exist, a level-specific icon badge, the topic title,
/// and an optional status chip when [sectionId] is provided.
class TopicTreeItem extends StatelessWidget {
  final SyllabusTopic topic;
  final String? sectionId;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onToggleExpand;
  final ValueChanged<TopicStatus>? onStatusChanged;
  final VoidCallback? onAddChild;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TopicTreeItem({
    super.key,
    required this.topic,
    this.sectionId,
    this.isExpanded = false,
    this.onTap,
    this.onToggleExpand,
    this.onStatusChanged,
    this.onAddChild,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indent = topic.level.depth * 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main row
        GestureDetector(
          onTap: onTap,
          onLongPress: () => _showPopupMenu(context),
          child: Padding(
            padding: EdgeInsets.only(left: indent),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isExpanded
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // Expand / collapse icon (or spacer)
                  if (topic.hasChildren)
                    GestureDetector(
                      onTap: onToggleExpand,
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.chevron_right,
                          size: 22,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 22),

                  const SizedBox(width: 8),

                  // Level icon badge
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _levelColor(topic.level).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      topic.level.icon,
                      size: 18,
                      color: _levelColor(topic.level),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Title
                  Expanded(
                    child: Text(
                      topic.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: topic.level == TopicLevel.unit ||
                                topic.level == TopicLevel.chapter
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Status chip (only when section context is provided)
                  if (sectionId != null) ...[
                    const SizedBox(width: 8),
                    _buildStatusChip(topic.coverage?.status ?? TopicStatus.notStarted),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Children (recursive)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: topic.children.map((child) {
              return TopicTreeItem(
                topic: child,
                sectionId: sectionId,
                isExpanded: false,
                onTap: onTap,
                onToggleExpand: onToggleExpand,
                onStatusChanged: onStatusChanged,
                onAddChild: onAddChild,
                onEdit: onEdit,
                onDelete: onDelete,
              );
            }).toList(),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildStatusChip(TopicStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPopupMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + renderBox.size.width,
        offset.dy,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Edit'),
            ],
          ),
        ),
        if (topic.level != TopicLevel.subtopic)
          PopupMenuItem<String>(
            value: 'add_child',
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline,
                    size: 18, color: AppColors.secondary),
                const SizedBox(width: 10),
                Text('Add ${topic.level.childLevel?.label ?? 'Child'}'),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              SizedBox(width: 10),
              Text('Delete'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'edit':
          onEdit?.call();
          break;
        case 'add_child':
          onAddChild?.call();
          break;
        case 'delete':
          onDelete?.call();
          break;
      }
    });
  }

  Color _levelColor(TopicLevel level) {
    switch (level) {
      case TopicLevel.unit:
        return AppColors.primary;
      case TopicLevel.chapter:
        return AppColors.info;
      case TopicLevel.topic:
        return AppColors.secondary;
      case TopicLevel.subtopic:
        return AppColors.textSecondaryLight;
    }
  }
}
