import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_exam.dart';

class ExamCard extends StatelessWidget {
  final OnlineExam exam;
  final VoidCallback? onTap;
  final bool showActions;
  final VoidCallback? onStart;

  const ExamCard({
    super.key,
    required this.exam,
    this.onTap,
    this.showActions = false,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: title + status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _examTypeColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _examTypeIcon,
                      color: _examTypeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (exam.subjectName != null) ...[
                              Icon(Icons.book_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                exam.subjectName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (exam.className != null) ...[
                              Icon(Icons.class_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                exam.className!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: exam.status),
                ],
              ),
              const SizedBox(height: 12),
              // Info chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: exam.durationDisplay,
                  ),
                  _InfoChip(
                    icon: Icons.grade_outlined,
                    label: '${exam.totalMarks.toStringAsFixed(0)} marks',
                  ),
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: exam.examType.label,
                  ),
                  if (exam.startTime != null)
                    _InfoChip(
                      icon: Icons.schedule_outlined,
                      label: _formatDateTime(exam.startTime!),
                    ),
                ],
              ),
              // Start button for students
              if (showActions && exam.isAvailable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Exam'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color get _examTypeColor {
    switch (exam.examType) {
      case OnlineExamType.classTest:
        return AppColors.info;
      case OnlineExamType.unitTest:
        return AppColors.primary;
      case OnlineExamType.midTerm:
        return AppColors.warning;
      case OnlineExamType.finalExam:
        return AppColors.error;
      case OnlineExamType.competitive:
        return AppColors.accent;
      case OnlineExamType.practice:
        return AppColors.secondary;
    }
  }

  IconData get _examTypeIcon {
    switch (exam.examType) {
      case OnlineExamType.classTest:
        return Icons.quiz_outlined;
      case OnlineExamType.unitTest:
        return Icons.assignment_outlined;
      case OnlineExamType.midTerm:
        return Icons.event_note_outlined;
      case OnlineExamType.finalExam:
        return Icons.school_outlined;
      case OnlineExamType.competitive:
        return Icons.emoji_events_outlined;
      case OnlineExamType.practice:
        return Icons.auto_stories_outlined;
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }
}

class _StatusBadge extends StatelessWidget {
  final OnlineExamStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case OnlineExamStatus.draft:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
      case OnlineExamStatus.scheduled:
        bgColor = AppColors.infoLight;
        textColor = AppColors.info;
      case OnlineExamStatus.live:
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
      case OnlineExamStatus.completed:
        bgColor = AppColors.primaryLight.withAlpha(40);
        textColor = AppColors.primaryDark;
      case OnlineExamStatus.cancelled:
        bgColor = AppColors.errorLight;
        textColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == OnlineExamStatus.live) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
