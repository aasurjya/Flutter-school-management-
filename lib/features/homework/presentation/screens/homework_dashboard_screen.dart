import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/homework.dart';
import '../../providers/homework_provider.dart';

class HomeworkDashboardScreen extends ConsumerStatefulWidget {
  const HomeworkDashboardScreen({super.key});

  @override
  ConsumerState<HomeworkDashboardScreen> createState() =>
      _HomeworkDashboardScreenState();
}

class _HomeworkDashboardScreenState
    extends ConsumerState<HomeworkDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeworkNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(homeworkDashboardStatsProvider(null));
    final homeworkAsync = ref.watch(homeworkNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendar View',
            onPressed: () => context.push(AppRoutes.homeworkCalendar),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.homeworkCreate),
        icon: const Icon(Icons.add),
        label: const Text('Assign Homework'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeworkDashboardStatsProvider(null));
          await ref.read(homeworkNotifierProvider.notifier).load();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats Cards
            statsAsync.when(
              data: (stats) => _buildStatsSection(theme, stats),
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading stats: $e'),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.assignment_add,
                    label: 'Assign New',
                    color: AppColors.primary,
                    onTap: () => context.push(AppRoutes.homeworkCreate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.calendar_month,
                    label: 'Calendar',
                    color: AppColors.info,
                    onTap: () => context.push(AppRoutes.homeworkCalendar),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Homework
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Homework',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            homeworkAsync.when(
              data: (homeworkList) {
                if (homeworkList.isEmpty) {
                  return GlassCard(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No homework assigned yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to assign homework',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: homeworkList.take(10).map((hw) {
                    return _HomeworkListTile(homework: hw);
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme, HomeworkDashboardStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassStatCard(
                title: 'Total',
                value: '${stats.totalHomework}',
                icon: Icons.assignment,
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassStatCard(
                title: 'Active',
                value: '${stats.activeHomework}',
                icon: Icons.pending_actions,
                iconColor: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassStatCard(
                title: 'Overdue',
                value: '${stats.overdueHomework}',
                icon: Icons.warning_amber,
                iconColor: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassStatCard(
                title: 'To Grade',
                value: '${stats.pendingSubmissions}',
                icon: Icons.grading,
                iconColor: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkListTile extends StatelessWidget {
  final Homework homework;

  const _HomeworkListTile({required this.homework});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isOverdue = homework.isOverdue;

    Color statusColor;
    switch (homework.status) {
      case HomeworkStatus.draft:
        statusColor = AppColors.textSecondaryLight;
        break;
      case HomeworkStatus.published:
        statusColor = isOverdue ? AppColors.error : AppColors.success;
        break;
      case HomeworkStatus.closed:
        statusColor = AppColors.info;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: () => context.push('/homework/${homework.id}'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    homework.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOverdue ? 'Overdue' : homework.status.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (homework.subjectName != null) ...[
                  Icon(Icons.book_outlined,
                      size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    homework.subjectName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (homework.className != null &&
                    homework.sectionName != null) ...[
                  Icon(Icons.class_outlined,
                      size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    '${homework.className} - ${homework.sectionName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  'Due: ${dateFormat.format(homework.dueDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOverdue ? AppColors.error : AppColors.textSecondaryLight,
                    fontWeight: isOverdue ? FontWeight.w600 : null,
                  ),
                ),
                const Spacer(),
                if (homework.priority == HomeworkPriority.high)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'HIGH',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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
}
