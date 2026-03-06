import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_exam.dart';
import '../../providers/online_exam_provider.dart';

class ExamDetailScreen extends ConsumerWidget {
  final String examId;

  const ExamDetailScreen({super.key, required this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final examAsync = ref.watch(onlineExamByIdProvider(examId));

    return examAsync.when(
      data: (exam) {
        if (exam == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Exam not found')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Exam Details'),
            actions: [
              if (exam.isDraft)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      context.push('/online-exams/builder/${exam.id}'),
                ),
              PopupMenuButton<String>(
                itemBuilder: (ctx) => [
                  if (exam.isDraft)
                    const PopupMenuItem(
                        value: 'publish', child: Text('Schedule Exam')),
                  if (exam.isScheduled)
                    const PopupMenuItem(
                        value: 'go_live', child: Text('Go Live')),
                  if (exam.isLive)
                    const PopupMenuItem(
                        value: 'complete', child: Text('End Exam')),
                  const PopupMenuItem(
                    value: 'analytics',
                    child: Text('View Analytics'),
                  ),
                  if (exam.isDraft || exam.isScheduled)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ),
                ],
                onSelected: (v) async {
                  final repo = ref.read(onlineExamRepositoryProvider);
                  switch (v) {
                    case 'publish':
                      await repo.updateExamStatus(exam.id, 'scheduled');
                      ref.invalidate(onlineExamByIdProvider(examId));
                    case 'go_live':
                      await repo.updateExamStatus(exam.id, 'live');
                      ref.invalidate(onlineExamByIdProvider(examId));
                    case 'complete':
                      await repo.updateExamStatus(exam.id, 'completed');
                      ref.invalidate(onlineExamByIdProvider(examId));
                    case 'analytics':
                      context.push('/online-exams/analytics/$examId');
                    case 'delete':
                      await repo.deleteExam(exam.id);
                      if (context.mounted) context.pop();
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExamHeader(exam: exam),
                const SizedBox(height: 16),
                _ExamInfoGrid(exam: exam),
                const SizedBox(height: 16),
                if (exam.instructions != null &&
                    exam.instructions!.isNotEmpty)
                  _InstructionsCard(instructions: exam.instructions!),
                const SizedBox(height: 16),
                _SettingsCard(settings: exam.settings),
                const SizedBox(height: 16),
                if (exam.sections != null && exam.sections!.isNotEmpty)
                  _QuestionsPreview(sections: exam.sections!),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ExamHeader extends StatelessWidget {
  final OnlineExam exam;

  const _ExamHeader({required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exam.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusChip(status: exam.status),
              ],
            ),
            if (exam.description != null) ...[
              const SizedBox(height: 8),
              Text(
                exam.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (exam.subjectName != null)
                  Chip(
                    avatar: const Icon(Icons.book, size: 16),
                    label: Text(exam.subjectName!),
                  ),
                if (exam.className != null)
                  Chip(
                    avatar: const Icon(Icons.class_, size: 16),
                    label: Text(exam.className!),
                  ),
                Chip(
                  avatar: const Icon(Icons.category, size: 16),
                  label: Text(exam.examType.label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OnlineExamStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OnlineExamStatus.draft:
        color = Colors.grey;
      case OnlineExamStatus.scheduled:
        color = AppColors.info;
      case OnlineExamStatus.live:
        color = AppColors.success;
      case OnlineExamStatus.completed:
        color = AppColors.primary;
      case OnlineExamStatus.cancelled:
        color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == OnlineExamStatus.live)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamInfoGrid extends StatelessWidget {
  final OnlineExam exam;

  const _ExamInfoGrid({required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: exam.durationDisplay,
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.grade_outlined,
                    label: 'Total Marks',
                    value: exam.totalMarks.toStringAsFixed(0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.check_circle_outline,
                    label: 'Passing Marks',
                    value: exam.passingMarks.toStringAsFixed(0),
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.repeat,
                    label: 'Max Attempts',
                    value: '${exam.settings.maxAttempts}',
                  ),
                ),
              ],
            ),
            if (exam.startTime != null || exam.endTime != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (exam.startTime != null)
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.play_circle_outline,
                        label: 'Start',
                        value: _formatDateTime(exam.startTime!),
                      ),
                    ),
                  if (exam.endTime != null)
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.stop_circle_outlined,
                        label: 'End',
                        value: _formatDateTime(exam.endTime!),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  final String instructions;

  const _InstructionsCard({required this.instructions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Text('Instructions',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(instructions, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final ExamSettings settings;

  const _SettingsCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _SettingRow(
                label: 'Shuffle Questions', enabled: settings.shuffleQuestions),
            _SettingRow(
                label: 'Shuffle Options', enabled: settings.shuffleOptions),
            _SettingRow(
                label: 'Show Result Immediately',
                enabled: settings.showResultImmediately),
            _SettingRow(
                label: 'Allow Review', enabled: settings.allowReview),
            _SettingRow(
                label: 'Proctoring', enabled: settings.proctoringEnabled),
            _SettingRow(
                label: 'Fullscreen Required',
                enabled: settings.fullscreenRequired),
            if (settings.negativeMarkingValue > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Negative Marking'),
                    Text('${settings.negativeMarkingValue} per wrong answer',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            if (settings.tabSwitchLimit > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tab Switch Limit'),
                    Text('${settings.tabSwitchLimit}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final bool enabled;

  const _SettingRow({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: enabled ? AppColors.success : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}

class _QuestionsPreview extends StatelessWidget {
  final List<ExamSection> sections;

  const _QuestionsPreview({required this.sections});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int totalQ = 0;
    for (final s in sections) {
      totalQ += s.questionCount;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Questions Preview',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('$totalQ total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            ...sections.map((section) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(60),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(section.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '${section.questionCount} questions - ${section.marksPerQuestion} marks each',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Text(
                          '${section.totalMarks.toStringAsFixed(0)} marks',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
