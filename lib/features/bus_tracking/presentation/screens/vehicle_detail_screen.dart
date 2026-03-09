import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../data/models/bus_tracking.dart';
import '../../providers/bus_tracking_provider.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(busVehicleByIdProvider(vehicleId));
    final liveLocations = ref.watch(liveLocationProvider);
    final tripsAsync = ref.watch(busTripsProvider(vehicleId));
    final historyAsync = ref.watch(locationHistoryProvider(vehicleId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Track on Map',
            onPressed: () {
              ref.read(selectedVehicleIdProvider.notifier).state = vehicleId;
              context.push(AppRoutes.busTrackingLiveMap);
            },
          ),
        ],
      ),
      body: vehicleAsync.when(
        data: (vehicle) {
          if (vehicle == null) {
            return const Center(child: Text('Vehicle not found'));
          }

          final location = liveLocations[vehicle.id] ?? vehicle.latestLocation;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(busVehicleByIdProvider(vehicleId));
              ref.invalidate(busTripsProvider(vehicleId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Vehicle header card
                _VehicleHeaderCard(vehicle: vehicle, location: location),
                const SizedBox(height: 16),

                // Location card
                if (location != null) ...[
                  _LocationCard(location: location),
                  const SizedBox(height: 16),
                ],

                // Driver info
                _DriverInfoCard(vehicle: vehicle),
                const SizedBox(height: 16),

                // Recent trips
                _SectionHeader(title: 'RECENT TRIPS'),
                const SizedBox(height: 8),
                tripsAsync.when(
                  data: (trips) {
                    if (trips.isEmpty) {
                      return _EmptySection(message: 'No trips recorded yet');
                    }
                    return Column(
                      children: trips.take(5).map((trip) {
                        return _TripTile(trip: trip);
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                ),

                const SizedBox(height: 16),

                // Location history summary
                _SectionHeader(title: 'LOCATION HISTORY (2H)'),
                const SizedBox(height: 8),
                historyAsync.when(
                  data: (pings) {
                    if (pings.isEmpty) {
                      return _EmptySection(message: 'No location data');
                    }
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pings.length} location pings',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _StatChip(
                                  label: 'Avg Speed',
                                  value:
                                      '${(pings.fold<double>(0, (s, p) => s + p.speedKmh) / pings.length).toStringAsFixed(1)} km/h',
                                  color: AppColors.info,
                                ),
                                const SizedBox(width: 8),
                                _StatChip(
                                  label: 'Max Speed',
                                  value:
                                      '${pings.fold<double>(0, (m, p) => p.speedKmh > m ? p.speedKmh : m).toStringAsFixed(0)} km/h',
                                  color: AppColors.warning,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
      ),
    );
  }
}

class _VehicleHeaderCard extends StatelessWidget {
  final BusVehicle vehicle;
  final BusLatestLocation? location;

  const _VehicleHeaderCard({required this.vehicle, this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = location != null && !location!.isStale;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isOnline ? AppColors.success : AppColors.grey400)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.directions_bus_filled,
                    size: 32,
                    color: isOnline ? AppColors.success : AppColors.grey400,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.vehicleNumber,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (vehicle.routeName != null)
                        Text(
                          'Route: ${vehicle.routeName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(vehicle.statusLabel)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    vehicle.statusLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _statusColor(vehicle.statusLabel),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoColumn(
                  label: 'Type',
                  value: vehicle.vehicleType.toUpperCase(),
                ),
                _InfoColumn(
                  label: 'Capacity',
                  value: '${vehicle.capacity}',
                ),
                _InfoColumn(
                  label: 'Speed',
                  value: location?.speedFormatted ?? '--',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'On Trip':
        return AppColors.success;
      case 'Online':
        return AppColors.info;
      case 'Inactive':
        return AppColors.error;
      default:
        return AppColors.grey400;
    }
  }
}

class _LocationCard extends StatelessWidget {
  final BusLatestLocation location;

  const _LocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 20, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  'CURRENT LOCATION',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: location.isStale
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    location.timeSinceUpdate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: location.isStale
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lat: ${location.latitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'Lng: ${location.longitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      location.speedFormatted,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: location.heading * 3.14159 / 180,
                          child: Icon(
                            Icons.navigation,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${location.heading.toStringAsFixed(0)} deg',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  location.isIgnitionOn
                      ? Icons.key
                      : Icons.key_off,
                  size: 16,
                  color: location.isIgnitionOn
                      ? AppColors.success
                      : AppColors.grey400,
                ),
                const SizedBox(width: 6),
                Text(
                  location.isIgnitionOn ? 'Ignition ON' : 'Ignition OFF',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: location.isIgnitionOn
                        ? AppColors.success
                        : AppColors.grey400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverInfoCard extends StatelessWidget {
  final BusVehicle vehicle;

  const _DriverInfoCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DRIVER & HELPER',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (vehicle.driverName != null)
              _PersonRow(
                icon: Icons.person,
                name: vehicle.driverName!,
                phone: vehicle.driverPhone,
                role: 'Driver',
              ),
            if (vehicle.helperName != null) ...[
              const Divider(height: 16),
              _PersonRow(
                icon: Icons.person_outline,
                name: vehicle.helperName!,
                phone: vehicle.helperPhone,
                role: 'Helper',
              ),
            ],
            if (vehicle.driverName == null && vehicle.helperName == null)
              Text(
                'No driver/helper assigned',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.grey500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String? phone;
  final String role;

  const _PersonRow({
    required this.icon,
    required this.name,
    this.phone,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.bodyMedium),
              Text(
                role,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (phone != null)
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling $phone...')),
              );
            },
            icon: const Icon(Icons.phone, size: 16),
            label: Text(phone!),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}

class _TripTile extends StatelessWidget {
  final BusTrip trip;

  const _TripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('MMM d, HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (trip.tripType == 'pickup'
                    ? AppColors.info
                    : AppColors.accent)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            trip.tripType == 'pickup'
                ? Icons.wb_sunny_outlined
                : Icons.wb_twilight_outlined,
            color: trip.tripType == 'pickup'
                ? AppColors.info
                : AppColors.accent,
          ),
        ),
        title: Text(trip.tripLabel),
        subtitle: Text(
          '${df.format(trip.startedAt.toLocal())} - ${trip.durationFormatted}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: trip.isInProgress
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.grey200.withValues(alpha: 1.0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            trip.isInProgress ? 'Active' : 'Done',
            style: theme.textTheme.labelSmall?.copyWith(
              color: trip.isInProgress ? AppColors.success : AppColors.grey500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;

  const _InfoColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
