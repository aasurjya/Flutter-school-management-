import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/school_event.dart';

/// A vertical timeline widget for academic calendar items
class AcademicTimeline extends StatelessWidget {
  final List<AcademicCalendarItem> items;
  final VoidCallback? onItemTap;

  const AcademicTimeline({
    super.key,
    required this.items,
    this.onItemTap,
  });

  Color _typeColor(AcademicItemType type) {
    switch (type) {
      case AcademicItemType.termStart:
        return AppColors.success;
      case AcademicItemType.termEnd:
        return AppColors.warning;
      case AcademicItemType.examStart:
        return AppColors.error;
      case AcademicItemType.examEnd:
        return AppColors.error;
      case AcademicItemType.holiday:
        return AppColors.accent;
      case AcademicItemType.resultDate:
        return AppColors.info;
      case AcademicItemType.admissionStart:
        return AppColors.primaryLight;
      case AcademicItemType.admissionEnd:
        return AppColors.primaryDark;
      case AcademicItemType.feeDeadline:
        return const Color(0xFFEF4444);
    }
  }

  IconData _typeIcon(AcademicItemType type) {
    switch (type) {
      case AcademicItemType.termStart:
        return Icons.play_circle_outline;
      case AcademicItemType.termEnd:
        return Icons.stop_circle_outlined;
      case AcademicItemType.examStart:
        return Icons.edit_note;
      case AcademicItemType.examEnd:
        return Icons.check_circle_outline;
      case AcademicItemType.holiday:
        return Icons.beach_access;
      case AcademicItemType.resultDate:
        return Icons.assessment;
      case AcademicItemType.admissionStart:
        return Icons.person_add;
      case AcademicItemType.admissionEnd:
        return Icons.person_add_disabled;
      case AcademicItemType.feeDeadline:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_note,
                size: 48,
                color: AppColors.textTertiaryLight,
              ),
              const SizedBox(height: 12),
              Text(
                'No academic calendar items',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLast = index == items.length - 1;
        final color = _typeColor(item.itemType);
        final icon = _typeIcon(item.itemType);
        final isPast = item.date.isBefore(DateTime.now());

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isPast
                            ? color.withValues(alpha: 0.2)
                            : color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: 2,
                        ),
                      ),
                      child: Icon(icon, size: 14, color: color),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: color.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 4, bottom: 20, right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isPast
                                        ? AppColors.textSecondaryLight
                                        : null,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.itemType.label,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(item.date, item.endDate),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                          ),
                        ],
                      ),
                      if (item.notes != null &&
                          item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.notes!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date, DateTime? endDate) {
    final fmt = DateFormat('MMM d, yyyy');
    if (endDate == null || endDate == date) {
      return fmt.format(date);
    }
    return '${fmt.format(date)} - ${fmt.format(endDate)}';
  }
}
