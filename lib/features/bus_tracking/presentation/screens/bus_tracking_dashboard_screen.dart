import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/bus_tracking_provider.dart';
import '../widgets/bus_status_card.dart';
import '../widgets/tracking_stats_row.dart';

class BusTrackingDashboardScreen extends ConsumerWidget {
  const BusTrackingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(busTrackingStatsProvider);
    final vehiclesAsync = ref.watch(busVehiclesProvider(true));
    final liveLocations = ref.watch(liveLocationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Live Map',
            onPressed: () => context.push(AppRoutes.busTrackingLiveMap),
          ),
          IconButton(
            icon: const Icon(Icons.fence_outlined),
            tooltip: 'Geofences',
            onPressed: () => context.push(AppRoutes.busTrackingGeofences),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'trips':
                  context.push(AppRoutes.busTrackingTrips);
                  break;
                case 'alerts':
                  context.push(AppRoutes.busTrackingAlerts);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'trips',
                child: ListTile(
                  leading: Icon(Icons.route),
                  title: Text('Trip History'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'alerts',
                child: ListTile(
                  leading: Icon(Icons.notifications_active),
                  title: Text('Geofence Alerts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(busTrackingStatsProvider);
          ref.invalidate(busVehiclesProvider(true));
          ref.read(liveLocationProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats row
            statsAsync.when(
              data: (stats) => TrackingStatsRow(stats: stats),
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.satellite_alt,
                    label: 'LIVE MAP',
                    color: AppColors.info,
                    onTap: () => context.push(AppRoutes.busTrackingLiveMap),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.play_circle_outline,
                    label: 'START TRIP',
                    color: AppColors.success,
                    onTap: () => context.push(AppRoutes.busTrackingDriverPanel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.add_circle_outline,
                    label: 'ADD BUS',
                    color: AppColors.primary,
                    onTap: () =>
                        context.push(AppRoutes.busTrackingVehicleForm),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section header
            Row(
              children: [
                Text(
                  'FLEET STATUS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      context.push(AppRoutes.busTrackingLiveMap),
                  child: const Text('View All on Map'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vehicle list
            vehiclesAsync.when(
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return _EmptyState(
                    onAdd: () =>
                        context.push(AppRoutes.busTrackingVehicleForm),
                  );
                }

                return Column(
                  children: vehicles.map((vehicle) {
                    final location = liveLocations[vehicle.id];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BusStatusCard(
                        vehicle: vehicle,
                        liveLocation: location,
                        onTap: () => context.push(
                          AppRoutes.busTrackingVehicleDetail
                              .replaceAll(':vehicleId', vehicle.id),
                        ),
                        onTrack: () {
                          ref.read(selectedVehicleIdProvider.notifier).state =
                              vehicle.id;
                          context.push(AppRoutes.busTrackingLiveMap);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(child: Text('Error loading fleet: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No buses registered yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first bus to start tracking',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Bus'),
          ),
        ],
      ),
    );
  }
}
