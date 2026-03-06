import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/homework.dart';
import '../../providers/homework_provider.dart';

class HomeworkSubmissionsScreen extends ConsumerStatefulWidget {
  final String homeworkId;

  const HomeworkSubmissionsScreen({super.key, required this.homeworkId});

  @override
  ConsumerState<HomeworkSubmissionsScreen> createState() =>
      _HomeworkSubmissionsScreenState();
}

class _HomeworkSubmissionsScreenState
    extends ConsumerState<HomeworkSubmissionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(submissionsNotifierProvider(widget.homeworkId).notifier)
          .load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submissionsAsync =
        ref.watch(submissionsNotifierProvider(widget.homeworkId));
    final homeworkAsync = ref.watch(homeworkByIdProvider(widget.homeworkId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submissions'),
      ),
      body: Column(
        children: [
          // Homework header
          homeworkAsync.whenOrNull(
                data: (hw) {
                  if (hw == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppColors.primary.withValues(alpha: 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hw.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hw.subjectName ?? 'N/A'} | Max marks: ${hw.maxMarks ?? 'N/A'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ) ??
              const SizedBox.shrink(),

          // Submissions list
          Expanded(
            child: submissionsAsync.when(
              data: (submissions) {
                if (submissions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: AppColors.textSecondaryLight),
                        const SizedBox(height: 16),
                        Text(
                          'No submissions yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Summary stats
                final submitted = submissions
                    .where((s) =>
                        s.status == SubmissionStatus.submitted ||
                        s.status == SubmissionStatus.late_)
                    .length;
                final graded = submissions
                    .where((s) => s.status == SubmissionStatus.graded)
                    .length;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _StatBadge(
                            label: 'Total',
                            value: '${submissions.length}',
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _StatBadge(
                            label: 'Submitted',
                            value: '$submitted',
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 8),
                          _StatBadge(
                            label: 'Graded',
                            value: '$graded',
                            color: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await ref
                              .read(submissionsNotifierProvider(
                                      widget.homeworkId)
                                  .notifier)
                              .load();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: submissions.length,
                          itemBuilder: (context, index) {
                            return _SubmissionTile(
                              submission: submissions[index],
                              maxMarks: homeworkAsync.valueOrNull?.maxMarks,
                              onGrade: () => _showGradeDialog(
                                context,
                                submissions[index],
                                homeworkAsync.valueOrNull?.maxMarks,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showGradeDialog(
    BuildContext context,
    HomeworkSubmission submission,
    int? maxMarks,
  ) {
    final marksController = TextEditingController(
      text: submission.marks?.toString() ?? '',
    );
    final feedbackController = TextEditingController(
      text: submission.feedback ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Grade - ${submission.studentName ?? 'Student'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (submission.content != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  submission.content!,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: marksController,
              decoration: InputDecoration(
                labelText: maxMarks != null ? 'Marks (out of $maxMarks)' : 'Marks',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (submission.status == SubmissionStatus.submitted ||
              submission.status == SubmissionStatus.late_)
            TextButton(
              onPressed: () async {
                await ref
                    .read(
                        submissionsNotifierProvider(widget.homeworkId).notifier)
                    .returnSubmission(
                      submissionId: submission.id,
                      feedback: feedbackController.text.trim().isNotEmpty
                          ? feedbackController.text.trim()
                          : null,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Return for Revision'),
            ),
          FilledButton(
            onPressed: () async {
              final marks = int.tryParse(marksController.text);
              if (marks == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid marks'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (maxMarks != null && marks > maxMarks) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Marks cannot exceed $maxMarks'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              await ref
                  .read(
                      submissionsNotifierProvider(widget.homeworkId).notifier)
                  .grade(
                    submissionId: submission.id,
                    marks: marks,
                    feedback: feedbackController.text.trim().isNotEmpty
                        ? feedbackController.text.trim()
                        : null,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Grade'),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final HomeworkSubmission submission;
  final int? maxMarks;
  final VoidCallback onGrade;

  const _SubmissionTile({
    required this.submission,
    this.maxMarks,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, HH:mm');

    Color statusColor;
    IconData statusIcon;
    switch (submission.status) {
      case SubmissionStatus.pending:
        statusColor = AppColors.textSecondaryLight;
        statusIcon = Icons.hourglass_empty;
        break;
      case SubmissionStatus.submitted:
        statusColor = AppColors.info;
        statusIcon = Icons.check_circle_outline;
        break;
      case SubmissionStatus.late_:
        statusColor = AppColors.accent;
        statusIcon = Icons.schedule;
        break;
      case SubmissionStatus.graded:
        statusColor = AppColors.success;
        statusIcon = Icons.grading;
        break;
      case SubmissionStatus.returned:
        statusColor = AppColors.warning;
        statusIcon = Icons.replay;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: onGrade,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.studentName ?? 'Unknown Student',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (submission.studentRollNo != null)
                    Text(
                      'Roll: ${submission.studentRollNo}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  if (submission.submittedAt != null)
                    Text(
                      'Submitted: ${dateFormat.format(submission.submittedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    submission.status.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (submission.marks != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    maxMarks != null
                        ? '${submission.marks}/$maxMarks'
                        : '${submission.marks}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
