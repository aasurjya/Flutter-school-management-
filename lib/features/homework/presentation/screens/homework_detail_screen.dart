import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/homework.dart';
import '../../providers/homework_provider.dart';

class HomeworkDetailScreen extends ConsumerWidget {
  final String homeworkId;

  const HomeworkDetailScreen({super.key, required this.homeworkId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final homeworkAsync = ref.watch(homeworkByIdProvider(homeworkId));
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Details'),
        actions: [
          homeworkAsync.whenOrNull(
                data: (hw) {
                  if (hw == null) return const SizedBox.shrink();
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      if (hw.status == HomeworkStatus.draft)
                        const PopupMenuItem(
                          value: 'publish',
                          child: ListTile(
                            leading: Icon(Icons.publish, color: AppColors.success),
                            title: Text('Publish'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      if (hw.status == HomeworkStatus.published)
                        const PopupMenuItem(
                          value: 'close',
                          child: ListTile(
                            leading: Icon(Icons.lock, color: AppColors.info),
                            title: Text('Close Submissions'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: AppColors.error),
                          title: Text('Delete'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) =>
                        _handleAction(context, ref, value, hw),
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: homeworkAsync.when(
        data: (homework) {
          if (homework == null) {
            return const Center(child: Text('Homework not found'));
          }

          final isOverdue = homework.isOverdue;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title & Status
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            homework.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _StatusChip(
                          label: isOverdue ? 'Overdue' : homework.status.label,
                          color: _getStatusColor(homework.status, isOverdue),
                        ),
                      ],
                    ),
                    if (homework.description != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        homework.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info Cards
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.book_outlined,
                      label: 'Subject',
                      value: homework.subjectName ?? 'N/A',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.class_outlined,
                      label: 'Class',
                      value: homework.className != null && homework.sectionName != null
                          ? '${homework.className} - ${homework.sectionName}'
                          : 'N/A',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.calendar_today,
                      label: 'Assigned',
                      value: dateFormat.format(homework.assignedDate),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.event,
                      label: 'Due Date',
                      value: dateFormat.format(homework.dueDate),
                      valueColor: isOverdue ? AppColors.error : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.flag,
                      label: 'Priority',
                      value: homework.priority.label,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.grade,
                      label: 'Max Marks',
                      value: homework.maxMarks?.toString() ?? 'Not graded',
                    ),
                  ),
                ],
              ),

              if (homework.instructions != null) ...[
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.list_alt,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        homework.instructions!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],

              if (homework.assignedByName != null) ...[
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned by',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            homework.assignedByName!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              if (homework.status == HomeworkStatus.published) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                        '/homework/$homeworkId/submissions'),
                    icon: const Icon(Icons.assignment_turned_in),
                    label: const Text('View Submissions'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                        '/homework/$homeworkId/submit'),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Submit Homework'),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    Homework homework,
  ) async {
    switch (action) {
      case 'publish':
        await ref.read(homeworkNotifierProvider.notifier).publish(homework.id);
        ref.invalidate(homeworkByIdProvider(homeworkId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Homework published'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        break;
      case 'close':
        await ref.read(homeworkNotifierProvider.notifier).close(homework.id);
        ref.invalidate(homeworkByIdProvider(homeworkId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Submissions closed'),
              backgroundColor: AppColors.info,
            ),
          );
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Homework?'),
            content: const Text(
                'This will permanently delete this homework and all submissions. This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref
              .read(homeworkNotifierProvider.notifier)
              .delete(homework.id);
          if (context.mounted) context.pop();
        }
        break;
    }
  }

  Color _getStatusColor(HomeworkStatus status, bool isOverdue) {
    if (isOverdue) return AppColors.error;
    switch (status) {
      case HomeworkStatus.draft:
        return AppColors.textSecondaryLight;
      case HomeworkStatus.published:
        return AppColors.success;
      case HomeworkStatus.closed:
        return AppColors.info;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
