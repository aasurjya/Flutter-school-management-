import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/alumni.dart';
import '../../../../shared/widgets/glass_card.dart';

class MentorshipCard extends StatelessWidget {
  final MentorshipProgram program;
  final VoidCallback? onTap;
  final VoidCallback? onApply;

  const MentorshipCard({
    super.key,
    required this.program,
    this.onTap,
    this.onApply,
  });

  Color _statusColor(MentorshipProgramStatus status) {
    switch (status) {
      case MentorshipProgramStatus.open:
        return AppColors.success;
      case MentorshipProgramStatus.inProgress:
        return AppColors.info;
      case MentorshipProgramStatus.completed:
        return AppColors.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(program.status);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (program.mentor != null)
                      Text(
                        'by ${program.mentor!.fullName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  program.status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (program.description != null) ...[
            const SizedBox(height: 10),
            Text(
              program.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (program.skillsOffered.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: program.skillsOffered.take(4).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    skill,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_outline,
                  size: 14, color: AppColors.textTertiaryLight),
              const SizedBox(width: 4),
              Text(
                '${program.requestCount ?? 0}/${program.menteeCountLimit} mentees',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
              const Spacer(),
              if (program.status == MentorshipProgramStatus.open &&
                  program.hasMenteeSlots &&
                  onApply != null)
                TextButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Apply'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
