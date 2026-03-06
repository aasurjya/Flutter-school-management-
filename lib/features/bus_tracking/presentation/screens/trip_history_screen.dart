import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/bus_tracking_provider.dart';

class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(busTripsProvider(null));
    final theme = Theme.of(context);
    final df = DateFormat('MMM d, yyyy');
    final tf = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
      ),
      body: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No trips recorded yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(busTripsProvider(null)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (trip.tripType == 'pickup'
                                        ? AppColors.info
                                        : AppColors.accent)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                trip.tripType == 'pickup'
                                    ? Icons.wb_sunny
                                    : Icons.wb_twilight,
                                color: trip.tripType == 'pickup'
                                    ? AppColors.info
                                    : AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.tripLabel,
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (trip.vehicleNumber != null)
                                    Text(
                                      trip.vehicleNumber!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (trip.isInProgress
                                        ? AppColors.success
                                        : Colors.grey)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                trip.isInProgress ? 'Active' : 'Completed',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: trip.isInProgress
                                      ? AppColors.success
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              df.format(trip.startedAt.toLocal()),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${tf.format(trip.startedAt.toLocal())} - ${trip.endedAt != null ? tf.format(trip.endedAt!.toLocal()) : "..."}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              trip.durationFormatted,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (trip.distanceKm != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.straighten,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                '${trip.distanceKm!.toStringAsFixed(1)} km',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                        if (trip.checkins != null &&
                            trip.checkins!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.place,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                '${trip.checkins!.length} stops visited',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
