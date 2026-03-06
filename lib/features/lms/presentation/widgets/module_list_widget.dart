import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../../../shared/widgets/glass_card.dart';

class ModuleListWidget extends StatelessWidget {
  final List<CourseModule> modules;
  final Map<String, ContentProgressStatus>? contentProgressMap;
  final void Function(CourseModule module)? onModuleTap;
  final void Function(ModuleContent content, CourseModule module)?
      onContentTap;
  final bool isEditable;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(CourseModule module)? onEditModule;
  final void Function(CourseModule module)? onDeleteModule;
  final void Function(CourseModule module)? onAddContent;

  const ModuleListWidget({
    super.key,
    required this.modules,
    this.contentProgressMap,
    this.onModuleTap,
    this.onContentTap,
    this.isEditable = false,
    this.onReorder,
    this.onEditModule,
    this.onDeleteModule,
    this.onAddContent,
  });

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.view_module_outlined,
                  size: 48, color: AppColors.textTertiaryLight),
              const SizedBox(height: 12),
              Text(
                'No modules yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: modules.asMap().entries.map((entry) {
        final index = entry.key;
        final module = entry.value;
        return _ModuleExpansionTile(
          module: module,
          index: index,
          contentProgressMap: contentProgressMap,
          onContentTap: onContentTap,
          isEditable: isEditable,
          onEditModule: onEditModule,
          onDeleteModule: onDeleteModule,
          onAddContent: onAddContent,
        );
      }).toList(),
    );
  }
}

class _ModuleExpansionTile extends StatelessWidget {
  final CourseModule module;
  final int index;
  final Map<String, ContentProgressStatus>? contentProgressMap;
  final void Function(ModuleContent content, CourseModule module)?
      onContentTap;
  final bool isEditable;
  final void Function(CourseModule module)? onEditModule;
  final void Function(CourseModule module)? onDeleteModule;
  final void Function(CourseModule module)? onAddContent;

  const _ModuleExpansionTile({
    required this.module,
    required this.index,
    this.contentProgressMap,
    this.onContentTap,
    this.isEditable = false,
    this.onEditModule,
    this.onDeleteModule,
    this.onAddContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final contents = module.contents ?? [];

    // Calculate module progress
    int completedCount = 0;
    if (contentProgressMap != null) {
      for (final content in contents) {
        if (contentProgressMap![content.id] ==
            ContentProgressStatus.completed) {
          completedCount++;
        }
      }
    }
    final progress =
        contents.isEmpty ? 0.0 : completedCount / contents.length;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: progress >= 1
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: progress >= 1
                  ? const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  module.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (module.isLocked)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.lock_outline, size: 16, color: AppColors.warning),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Text(
                '${contents.length} items',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
              if (module.durationMinutes > 0) ...[
                const SizedBox(width: 8),
                Icon(Icons.access_time,
                    size: 12,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight),
                const SizedBox(width: 2),
                Text(
                  '${module.durationMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
              if (contentProgressMap != null) ...[
                const Spacer(),
                Text(
                  '$completedCount/${contents.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        progress >= 1 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
          children: [
            // Progress bar
            if (contentProgressMap != null && contents.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1 ? AppColors.success : AppColors.primary,
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Content list
            ...contents.asMap().entries.map((entry) {
              final content = entry.value;
              final cStatus = contentProgressMap?[content.id];
              return _ContentListItem(
                content: content,
                status: cStatus,
                onTap: onContentTap != null
                    ? () => onContentTap!(content, module)
                    : null,
              );
            }),
            // Edit actions
            if (isEditable) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onAddContent != null)
                    TextButton.icon(
                      onPressed: () => onAddContent!(module),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Content'),
                    ),
                  if (onEditModule != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => onEditModule!(module),
                      tooltip: 'Edit Module',
                    ),
                  if (onDeleteModule != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      onPressed: () => onDeleteModule!(module),
                      tooltip: 'Delete Module',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContentListItem extends StatelessWidget {
  final ModuleContent content;
  final ContentProgressStatus? status;
  final VoidCallback? onTap;

  const _ContentListItem({
    required this.content,
    this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = status == ContentProgressStatus.completed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Content type icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : _contentTypeColor(content.contentType)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle
                    : _contentTypeIcon(content.contentType),
                size: 16,
                color: isCompleted
                    ? AppColors.success
                    : _contentTypeColor(content.contentType),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted
                          ? (isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight)
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        content.contentType.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                          fontSize: 11,
                        ),
                      ),
                      if (content.isMandatory) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (status == ContentProgressStatus.inProgress)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'In Progress',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }

  IconData _contentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.video:
        return Icons.play_circle_outlined;
      case ContentType.document:
        return Icons.description_outlined;
      case ContentType.presentation:
        return Icons.slideshow_outlined;
      case ContentType.link:
        return Icons.link;
      case ContentType.text:
        return Icons.article_outlined;
      case ContentType.quiz:
        return Icons.quiz_outlined;
      case ContentType.assignment:
        return Icons.assignment_outlined;
    }
  }

  Color _contentTypeColor(ContentType type) {
    switch (type) {
      case ContentType.video:
        return const Color(0xFFEF4444);
      case ContentType.document:
        return const Color(0xFF3B82F6);
      case ContentType.presentation:
        return const Color(0xFFF59E0B);
      case ContentType.link:
        return const Color(0xFF8B5CF6);
      case ContentType.text:
        return const Color(0xFF6366F1);
      case ContentType.quiz:
        return const Color(0xFF22C55E);
      case ContentType.assignment:
        return const Color(0xFFF97316);
    }
  }
}
