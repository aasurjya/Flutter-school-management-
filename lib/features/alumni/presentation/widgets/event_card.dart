import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/alumni.dart';
import '../../../../shared/widgets/glass_card.dart';

class AlumniEventCard extends StatelessWidget {
  final AlumniEvent event;
  final VoidCallback? onTap;

  const AlumniEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  Color _statusColor(AlumniEventStatus status) {
    switch (status) {
      case AlumniEventStatus.upcoming:
        return AppColors.info;
      case AlumniEventStatus.ongoing:
        return AppColors.success;
      case AlumniEventStatus.completed:
        return AppColors.textSecondaryLight;
      case AlumniEventStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _eventTypeIcon(AlumniEventType type) {
    switch (type) {
      case AlumniEventType.reunion:
        return Icons.groups;
      case AlumniEventType.networking:
        return Icons.handshake;
      case AlumniEventType.careerTalk:
        return Icons.mic;
      case AlumniEventType.fundraiser:
        return Icons.volunteer_activism;
      case AlumniEventType.meetup:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final statusColor = _statusColor(event.status);

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
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _eventTypeIcon(event.eventType),
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.status.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.eventType.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date and location row
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textTertiaryLight),
              const SizedBox(width: 4),
              Text(
                '${dateFormat.format(event.date)} at ${timeFormat.format(event.date)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                event.isVirtual ? Icons.videocam_outlined : Icons.location_on_outlined,
                size: 14,
                color: AppColors.textTertiaryLight,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.isVirtual
                      ? 'Virtual Event'
                      : event.location ?? 'Location TBD',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (event.maxAttendees != null) ...[
                Icon(Icons.people_outline,
                    size: 14, color: AppColors.textTertiaryLight),
                const SizedBox(width: 4),
                Text(
                  '${event.registrationCount ?? 0}/${event.maxAttendees}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
