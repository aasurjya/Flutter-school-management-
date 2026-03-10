import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/syllabus_topic.dart';
import '../../providers/syllabus_provider.dart';
import '../widgets/topic_tree_item.dart';
import '../widgets/coverage_progress_bar.dart';

class SyllabusEditorScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String classId;
  final String academicYearId;
  final String? sectionId;
  final String? subjectName;
  final String? className;

  const SyllabusEditorScreen({
    super.key,
    required this.subjectId,
    required this.classId,
    required this.academicYearId,
    this.sectionId,
    this.subjectName,
    this.className,
  });

  @override
  ConsumerState<SyllabusEditorScreen> createState() =>
      _SyllabusEditorScreenState();
}

class _SyllabusEditorScreenState extends ConsumerState<SyllabusEditorScreen> {
  final Set<String> _expandedIds = {};

  SyllabusFilter get _filter => SyllabusFilter(
        subjectId: widget.subjectId,
        classId: widget.classId,
        academicYearId: widget.academicYearId,
        sectionId: widget.sectionId,
      );

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(syllabusTreeProvider(_filter));
    final coverageAsync = widget.sectionId != null
        ? ref.watch(coverageSummaryProvider(_filter))
        : null;

    final title = (widget.subjectName != null && widget.className != null)
        ? '${widget.subjectName} - ${widget.className}'
        : 'Syllabus Editor';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                tooltip: 'AI Generate',
                onPressed: () {
                  context.push(
                    '${AppRoutes.syllabusAIGenerator}'
                    '?subjectId=${widget.subjectId}'
                    '&classId=${widget.classId}'
                    '&yearId=${widget.academicYearId}'
                    '&subjectName=${Uri.encodeComponent(widget.subjectName ?? '')}'
                    '&className=${Uri.encodeComponent(widget.className ?? '')}',
                  );
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary bar
                if (coverageAsync != null)
                  coverageAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (summary) {
                      if (summary == null) return const SizedBox.shrink();
                      return _buildSummaryBar(context, summary);
                    },
                  )
                else
                  treeAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (topics) => _buildBasicSummary(context, topics),
                  ),
                const SizedBox(height: 16),

                // Tree list
                treeAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'Error loading syllabus: $error',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (topics) {
                    if (topics.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.library_books_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No topics yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add units to start building your syllabus or use AI to generate one.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildTreeItems(context, topics),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, SyllabusCoverageSummary summary) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: summary.coveragePercentage / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        summary.coveragePercentage >= 75
                            ? AppColors.success
                            : summary.coveragePercentage >= 50
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                    ),
                    Text(
                      '${summary.coveragePercentage.round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.totalTopics} topics',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.totalEstimatedPeriods} periods estimated',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CoverageProgressBar(
            completed: summary.completedTopics,
            inProgress: summary.inProgressTopics,
            notStarted: summary.notStartedTopics,
            skipped: summary.skippedTopics,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendDot(AppColors.success, 'Done ${summary.completedTopics}'),
              _legendDot(AppColors.warning, 'In Progress ${summary.inProgressTopics}'),
              _legendDot(Colors.grey, 'Pending ${summary.notStartedTopics}'),
              _legendDot(Colors.blueGrey, 'Skipped ${summary.skippedTopics}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSummary(BuildContext context, List<SyllabusTopic> topics) {
    final totalTopics = _countAllTopics(topics);
    final totalPeriods = _sumEstimatedPeriods(topics);
    final theme = Theme.of(context);

    if (totalTopics == 0) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.library_books, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            '$totalTopics topics',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.schedule, color: AppColors.textSecondaryLight, size: 20),
          const SizedBox(width: 4),
          Text(
            '$totalPeriods periods estimated',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  int _countAllTopics(List<SyllabusTopic> topics) {
    int count = 0;
    for (final topic in topics) {
      count += 1;
      count += _countAllTopics(topic.children);
    }
    return count;
  }

  int _sumEstimatedPeriods(List<SyllabusTopic> topics) {
    int total = 0;
    for (final topic in topics) {
      total += topic.estimatedPeriods;
      total += _sumEstimatedPeriods(topic.children);
    }
    return total;
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  List<Widget> _buildTreeItems(BuildContext context, List<SyllabusTopic> topics) {
    final widgets = <Widget>[];
    for (final topic in topics) {
      widgets.addAll(_buildTopicAndChildren(context, topic));
    }
    return widgets;
  }

  List<Widget> _buildTopicAndChildren(BuildContext context, SyllabusTopic topic) {
    final isExpanded = _expandedIds.contains(topic.id);

    return [
      TopicTreeItem(
        topic: topic,
        sectionId: widget.sectionId,
        isExpanded: isExpanded,
        onTap: () {
          context.push(
            '/syllabus/topic/${topic.id}'
            '?sectionId=${widget.sectionId ?? ''}',
          );
        },
        onToggleExpand: () {
          setState(() {
            if (isExpanded) {
              _expandedIds.remove(topic.id);
            } else {
              _expandedIds.add(topic.id);
            }
          });
        },
        onStatusChanged: (status) async {
          if (widget.sectionId == null) return;
          try {
            await ref.read(syllabusRepositoryProvider).updateCoverage(
                  topicId: topic.id,
                  sectionId: widget.sectionId!,
                  status: status,
                );
            ref.invalidate(syllabusTreeProvider(_filter));
            ref.invalidate(coverageSummaryProvider(_filter));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update status: $e')),
              );
            }
          }
        },
        onAddChild: () {
          context.push(
            '${AppRoutes.topicForm}'
            '?subjectId=${widget.subjectId}'
            '&classId=${widget.classId}'
            '&yearId=${widget.academicYearId}'
            '&parentId=${topic.id}'
            '&parentLevel=${topic.level.dbValue}',
          );
        },
        onEdit: () {
          context.push(
            '${AppRoutes.topicForm}'
            '?subjectId=${widget.subjectId}'
            '&classId=${widget.classId}'
            '&yearId=${widget.academicYearId}'
            '&topicId=${topic.id}',
          );
        },
        onDelete: () => _confirmDelete(context, topic),
      ),
      if (isExpanded && topic.children.isNotEmpty)
        ...topic.children
            .expand((child) => _buildTopicAndChildren(context, child)),
    ];
  }

  Future<void> _confirmDelete(BuildContext context, SyllabusTopic topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Topic?'),
        content: Text(
          'Are you sure you want to delete "${topic.title}"? '
          '${topic.hasChildren ? 'All child topics will also be deleted.' : 'This action cannot be undone.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(syllabusRepositoryProvider).deleteTopic(topic.id);
        ref.invalidate(syllabusTreeProvider(_filter));
        ref.invalidate(coverageSummaryProvider(_filter));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topic deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  void _showAddMenu(BuildContext context) {
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
                'Add to Syllabus',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text('Add Unit'),
                subtitle: const Text('Create a new top-level unit'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '${AppRoutes.topicForm}'
                    '?subjectId=${widget.subjectId}'
                    '&classId=${widget.classId}'
                    '&yearId=${widget.academicYearId}',
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.accent,
                  ),
                ),
                title: const Text('AI Generate'),
                subtitle: const Text('Auto-generate syllabus structure'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '${AppRoutes.syllabusAIGenerator}'
                    '?subjectId=${widget.subjectId}'
                    '&classId=${widget.classId}'
                    '&yearId=${widget.academicYearId}'
                    '&subjectName=${Uri.encodeComponent(widget.subjectName ?? '')}'
                    '&className=${Uri.encodeComponent(widget.className ?? '')}',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
