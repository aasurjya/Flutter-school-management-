import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/school_event.dart';
import '../../../../shared/widgets/glass_card.dart';
import 'event_type_badge.dart';

/// A card widget displaying event summary information
class EventCard extends StatelessWidget {
  final SchoolEvent event;
  final VoidCallback? onTap;
  final bool showDate;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.showDate = true,
  });

  Color get _eventColor {
    final hex = event.colorHex ?? event.eventType.colorHex;
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color accent bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: _eventColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: badge + status
                    Row(
                      children: [
                        EventTypeBadge(eventType: event.eventType),
                        const Spacer(),
                        if (event.status != EventStatus.scheduled)
                          _StatusChip(status: event.status),
                        if (event.isMandatory) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Mandatory',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Title
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Info row
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        if (showDate)
                          _InfoChip(
                            icon: Icons.calendar_today,
                            label: _formatDateRange(
                                event.startDate, event.endDate),
                          ),
                        _InfoChip(
                          icon: Icons.access_time,
                          label: event.durationDisplay,
                        ),
                        if (event.location != null &&
                            event.location!.isNotEmpty)
                          _InfoChip(
                            icon: Icons.location_on,
                            label: event.location!,
                          ),
                        if (event.isRecurring)
                          const _InfoChip(
                            icon: Icons.repeat,
                            label: 'Recurring',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final fmt = DateFormat('MMM d');
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return fmt.format(start);
    }
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }
}

class _StatusChip extends StatelessWidget {
  final EventStatus status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case EventStatus.scheduled:
        return AppColors.info;
      case EventStatus.ongoing:
        return AppColors.success;
      case EventStatus.completed:
        return AppColors.textSecondaryLight;
      case EventStatus.cancelled:
        return AppColors.error;
      case EventStatus.postponed:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
