import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';

class MaintenanceCalendar extends StatelessWidget {
  final List<AssetMaintenance> maintenanceList;
  final VoidCallback? onViewAll;

  const MaintenanceCalendar({
    super.key,
    required this.maintenanceList,
    this.onViewAll,
  });

  Color _typeColor(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.preventive:
        return AppColors.info;
      case MaintenanceType.corrective:
        return AppColors.warning;
      case MaintenanceType.emergency:
        return AppColors.error;
    }
  }

  IconData _typeIcon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.preventive:
        return Icons.shield_outlined;
      case MaintenanceType.corrective:
        return Icons.build_outlined;
      case MaintenanceType.emergency:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd');

    if (maintenanceList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.success.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No pending maintenance',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<AssetMaintenance>>{};
    for (final m in maintenanceList) {
      final key = dateFormat.format(m.scheduledDate);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(m);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Maintenance',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...grouped.entries.take(5).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...entry.value.map((m) {
                  final color = _typeColor(m.maintenanceType);
                  final isOverdue = m.isOverdue;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppColors.errorLight
                          : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOverdue
                            ? AppColors.error.withValues(alpha: 0.3)
                            : color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _typeIcon(m.maintenanceType),
                          size: 18,
                          color: isOverdue ? AppColors.error : color,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.asset?.name ?? 'Asset #${m.assetId.substring(0, 8)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                m.maintenanceType.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiaryLight,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Overdue',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          )
                        else
                          Text(
                            m.status.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
