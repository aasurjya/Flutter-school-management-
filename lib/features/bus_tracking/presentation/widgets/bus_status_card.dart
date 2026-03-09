import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/bus_tracking.dart';

class BusStatusCard extends StatelessWidget {
  final BusVehicle vehicle;
  final BusLatestLocation? liveLocation;
  final VoidCallback? onTap;
  final VoidCallback? onTrack;

  const BusStatusCard({
    super.key,
    required this.vehicle,
    this.liveLocation,
    this.onTap,
    this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = liveLocation ?? vehicle.latestLocation;
    final isOnline = location != null && !location.isStale;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOnline
              ? AppColors.success.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.directions_bus_filled,
                      color: _statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Vehicle info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                vehicle.vehicleNumber,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (vehicle.routeName != null)
                          Text(
                            vehicle.routeName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          vehicle.statusLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location details row
              Row(
                children: [
                  if (location != null) ...[
                    // Speed
                    _MetricChip(
                      icon: Icons.speed,
                      label: location.speedFormatted,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    // Last update
                    _MetricChip(
                      icon: Icons.access_time,
                      label: location.timeSinceUpdate,
                      color: location.isStale
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    // Ignition
                    _MetricChip(
                      icon: location.isIgnitionOn
                          ? Icons.key
                          : Icons.key_off,
                      label: location.isIgnitionOn ? 'ON' : 'OFF',
                      color: location.isIgnitionOn
                          ? AppColors.success
                          : Colors.grey,
                    ),
                  ] else ...[
                    const _MetricChip(
                      icon: Icons.gps_off,
                      label: 'No GPS data',
                      color: Colors.grey,
                    ),
                  ],
                  const Spacer(),
                  // Track button
                  if (isOnline && onTrack != null)
                    FilledButton.tonalIcon(
                      onPressed: onTrack,
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('Track'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                ],
              ),

              // Driver info
              if (vehicle.driverName != null) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      vehicle.driverName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (vehicle.driverPhone != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.phone,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.driverPhone!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${vehicle.capacity} seats',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (vehicle.statusLabel) {
      case 'On Trip':
        return AppColors.success;
      case 'Online':
        return AppColors.info;
      case 'Inactive':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
