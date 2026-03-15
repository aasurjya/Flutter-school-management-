import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/syllabus_topic.dart';
import '../../../../data/models/lesson_plan.dart';
import '../../providers/syllabus_provider.dart';

class TopicDetailScreen extends ConsumerWidget {
  final String topicId;
  final String? sectionId;

  const TopicDetailScreen({
    super.key,
    required this.topicId,
    this.sectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicAsync = ref.watch(topicDetailProvider(topicId));
    final linksAsync = ref.watch(topicLinksProvider(topicId));
    final lessonPlansAsync = ref.watch(lessonPlansProvider(topicId));

    return Scaffold(
      body: topicAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error loading topic: $error',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        data: (topic) {
          if (topic == null) {
            return const Center(
              child: Text(
                'Topic not found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    topic.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    tooltip: 'Edit',
                    onPressed: () {
                      context.push(
                        '${AppRoutes.topicForm}'
                        '?subjectId=${topic.subjectId}'
                        '&classId=${topic.classId}'
                        '&yearId=${topic.academicYearId}'
                        '&topicId=${topic.id}',
                      );
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title + Description card
                    _buildInfoCard(context, topic),
                    const SizedBox(height: 16),

                    // Learning Objectives
                    if (topic.learningObjectives.isNotEmpty) ...[
                      _buildLearningObjectives(context, topic),
                      const SizedBox(height: 16),
                    ],

                    // Coverage Status
                    if (sectionId != null && sectionId!.isNotEmpty) ...[
                      _buildCoverageSection(context, topic),
                      const SizedBox(height: 16),
                    ],

                    // Linked Resources
                    _buildLinkedResources(context, ref, linksAsync),
                    const SizedBox(height: 16),

                    // Lesson Plans
                    _buildLessonPlans(context, lessonPlansAsync, topic),
                    const SizedBox(height: 16),

                    // Action Buttons
                    _buildActionButtons(context, topic),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, SyllabusTopic topic) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _levelColor(topic.level).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  topic.level.icon,
                  color: _levelColor(topic.level),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topic.level.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _levelColor(topic.level),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (topic.description != null && topic.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              topic.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(
                Icons.schedule,
                '${topic.estimatedPeriods} period${topic.estimatedPeriods != 1 ? 's' : ''} estimated',
              ),
              if (topic.subjectName != null)
                _infoChip(Icons.book, topic.subjectName!),
              if (topic.className != null)
                _infoChip(Icons.class_, topic.className!),
              if (topic.termName != null)
                _infoChip(Icons.calendar_today, topic.termName!),
            ],
          ),
          if (topic.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topic.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12),
                      padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLearningObjectives(BuildContext context, SyllabusTopic topic) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Learning Objectives',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...topic.learningObjectives.map(
            (objective) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      objective,
                      style: theme.textTheme.bodyMedium,
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

  Widget _buildCoverageSection(BuildContext context, SyllabusTopic topic) {
    final theme = Theme.of(context);
    final coverage = topic.coverage;
    final status = coverage?.status ?? TopicStatus.notStarted;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes,
                  color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Coverage Status',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 16, color: status.color),
                    const SizedBox(width: 6),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: status.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (coverage != null && coverage.periodsSpent > 0)
                Text(
                  '${coverage.periodsSpent} period${coverage.periodsSpent != 1 ? 's' : ''} spent',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
          if (coverage?.startedDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Started: ${_formatDate(coverage!.startedDate!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
          if (coverage?.completedDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Completed: ${_formatDate(coverage!.completedDate!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.success,
              ),
            ),
          ],
          if (coverage?.notes != null && coverage!.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              coverage.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkedResources(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TopicResourceLink>> linksAsync,
  ) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Linked Resources',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          linksAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Text(
              'Failed to load links: $error',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            data: (links) {
              if (links.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No linked resources yet',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              }

              return Column(
                children: links.map((link) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        link.entityTypeIcon,
                        color: AppColors.info,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      link.entityTitle ?? link.entityId,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      link.entityTypeDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    dense: true,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonPlans(
    BuildContext context,
    AsyncValue<List<LessonPlan>> plansAsync,
    SyllabusTopic topic,
  ) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Lesson Plans',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          plansAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Text(
              'Failed to load lesson plans: $error',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            data: (plans) {
              if (plans.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No lesson plans yet',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              }

              return Column(
                children: plans.map((plan) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: plan.status.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        plan.status.icon,
                        color: plan.status.color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      plan.title,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: plan.status.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            plan.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: plan.status.color,
                            ),
                          ),
                        ),
                        if (plan.deliveredDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(plan.deliveredDate!),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    dense: true,
                    onTap: () {
                      context.push('/syllabus/lesson-plan/${plan.id}');
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SyllabusTopic topic) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.push(
                '/syllabus/topic/${topic.id}/lesson-plan'
                '?topicTitle=${Uri.encodeComponent(topic.title)}'
                '&sectionId=${sectionId ?? ''}',
              );
            },
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('Generate Lesson Plan'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showLinkContentSheet(context),
            icon: const Icon(Icons.link),
            label: const Text('Link Content'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showLinkContentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Link Content',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.assignment, color: AppColors.primary),
                title: const Text('Assignment'),
                subtitle: const Text('Link an existing assignment'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Assignment linking coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz, color: AppColors.accent),
                title: const Text('Quiz'),
                subtitle: const Text('Link a quiz to this topic'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quiz linking coming soon')),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.library_books, color: AppColors.secondary),
                title: const Text('Study Resource'),
                subtitle: const Text('Link a study resource'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Resource linking coming soon')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondaryLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
