import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/lesson_plan.dart';
import '../../providers/syllabus_provider.dart';

class LessonPlanScreen extends ConsumerWidget {
  final String planId;

  const LessonPlanScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(lessonPlanDetailProvider(planId));

    return Scaffold(
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plan) {
          if (plan == null) {
            return const Center(child: Text('Lesson plan not found.'));
          }
          return _buildContent(context, ref, plan);
        },
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, LessonPlan plan) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Edit',
              onPressed: () {
                context.push(
                  '${AppRoutes.lessonPlanForm.replaceFirst(':topicId', plan.topicId)}'
                  '?planId=${plan.id}'
                  '&topicTitle=${Uri.encodeComponent(plan.topicTitle ?? '')}',
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) =>
                  _handleAction(context, ref, plan, value),
              itemBuilder: (context) => [
                if (!plan.isDelivered)
                  const PopupMenuItem(
                    value: 'delivered',
                    child: ListTile(
                      leading: Icon(Icons.done_all, color: AppColors.success),
                      title: Text('Mark as Delivered'),
                    ),
                  ),
                if (plan.isDraft)
                  const PopupMenuItem(
                    value: 'ready',
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline,
                          color: AppColors.info),
                      title: Text('Mark as Ready'),
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: AppColors.error),
                    title: Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              plan.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.oceanGradient,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Status + Meta row
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: plan.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(plan.status.icon,
                            size: 16, color: plan.status.color),
                        const SizedBox(width: 4),
                        Text(
                          plan.status.label,
                          style: TextStyle(
                            color: plan.status.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (plan.isAiGenerated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 14, color: AppColors.accent),
                          SizedBox(width: 4),
                          Text(
                            'AI Generated',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '${plan.durationMinutes} min',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sections
              if (plan.objective?.isNotEmpty ?? false)
                _buildSection(
                    context, 'Objective', plan.objective!, Icons.flag),
              if (plan.warmUp?.isNotEmpty ?? false)
                _buildSection(
                    context, 'Warm Up', plan.warmUp!, Icons.wb_sunny),
              if (plan.mainActivity?.isNotEmpty ?? false)
                _buildSection(context, 'Main Activity',
                    plan.mainActivity!, Icons.play_circle),
              if (plan.assessmentActivity?.isNotEmpty ?? false)
                _buildSection(context, 'Assessment Activity',
                    plan.assessmentActivity!, Icons.assessment),
              if (plan.homework?.isNotEmpty ?? false)
                _buildSection(
                    context, 'Homework', plan.homework!, Icons.home_work),
              if (plan.materialsNeeded?.isNotEmpty ?? false)
                _buildSection(context, 'Materials Needed',
                    plan.materialsNeeded!, Icons.inventory_2),
              if (plan.differentiationNotes?.isNotEmpty ?? false)
                _buildSection(context, 'Differentiation Notes',
                    plan.differentiationNotes!, Icons.accessibility_new),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
      BuildContext context, String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    LessonPlan plan,
    String action,
  ) async {
    final repository = ref.read(syllabusRepositoryProvider);

    switch (action) {
      case 'delivered':
        await repository.updateLessonPlan(plan.id, {
          'status': 'delivered',
          'delivered_date': DateTime.now().toIso8601String().split('T')[0],
        });
        ref.invalidate(lessonPlanDetailProvider);
        break;
      case 'ready':
        await repository.updateLessonPlan(plan.id, {
          'status': 'ready',
        });
        ref.invalidate(lessonPlanDetailProvider);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Lesson Plan?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          final nav = GoRouter.of(context);
          await repository.deleteLessonPlan(plan.id);
          ref.invalidate(lessonPlansProvider);
          nav.pop();
        }
        break;
    }
  }
}
