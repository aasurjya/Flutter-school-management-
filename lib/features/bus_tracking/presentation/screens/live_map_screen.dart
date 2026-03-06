import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/bus_tracking.dart';
import '../../providers/bus_tracking_provider.dart';
import '../widgets/bus_map_marker.dart';

/// Live GPS tracking map view using a custom-rendered canvas.
/// For production, integrate with google_maps_flutter or flutter_map.
/// This screen provides a functional simulated map that shows real-time
/// vehicle locations with heading, speed, and status indicators.
class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  Timer? _refreshTimer;
  String? _selectedVehicleId;
  bool _showGeofences = true;
  bool _showTrail = false;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.read(liveLocationProvider.notifier).refresh();
    });

    // Check if a specific vehicle was pre-selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = ref.read(selectedVehicleIdProvider);
      if (selected != null) {
        setState(() => _selectedVehicleId = selected);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveLocations = ref.watch(liveLocationProvider);
    final vehiclesAsync = ref.watch(busVehiclesProvider(true));
    final geofencesAsync = ref.watch(busGeofencesProvider(true));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          IconButton(
            icon: Icon(
              _showGeofences ? Icons.fence : Icons.fence_outlined,
              color: _showGeofences ? AppColors.primary : null,
            ),
            tooltip: 'Toggle Geofences',
            onPressed: () => setState(() => _showGeofences = !_showGeofences),
          ),
          IconButton(
            icon: Icon(
              _showTrail ? Icons.timeline : Icons.timeline_outlined,
              color: _showTrail ? AppColors.primary : null,
            ),
            tooltip: 'Toggle Trail',
            onPressed: () => setState(() => _showTrail = !_showTrail),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map area
          Expanded(
            child: Stack(
              children: [
                // Simulated map canvas
                Container(
                  color: const Color(0xFFE8F0FE),
                  child: CustomPaint(
                    painter: _MapPainter(
                      locations: liveLocations,
                      selectedVehicleId: _selectedVehicleId,
                      geofences: _showGeofences
                          ? (geofencesAsync.valueOrNull ?? [])
                          : [],
                    ),
                    size: Size.infinite,
                  ),
                ),

                // Vehicle markers overlay
                ...liveLocations.entries.map((entry) {
                  final loc = entry.value;
                  return Positioned(
                    left: _mapX(loc.longitude, context),
                    top: _mapY(loc.latitude, context),
                    child: BusMapMarker(
                      location: loc,
                      isSelected: _selectedVehicleId == entry.key,
                      onTap: () {
                        setState(() => _selectedVehicleId = entry.key);
                      },
                    ),
                  );
                }),

                // Map attribution
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Simulated Map View - Integrate google_maps_flutter for production',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),

                // No vehicles online message
                if (liveLocations.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.satellite_alt,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No buses currently online',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Buses will appear here when drivers start tracking',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom vehicle list
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: vehiclesAsync.when(
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return const Center(child: Text('No vehicles registered'));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final v = vehicles[index];
                    final loc = liveLocations[v.id];
                    final isSelected = _selectedVehicleId == v.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedVehicleId = v.id);
                      },
                      onDoubleTap: () {
                        context.push(
                          AppRoutes.busTrackingVehicleDetail
                              .replaceAll(':vehicleId', v.id),
                        );
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : Border.all(
                                  color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: loc != null && !loc.isStale
                                        ? AppColors.success
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    v.vehicleNumber,
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (v.routeName != null)
                              Text(
                                v.routeName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            const Spacer(),
                            if (loc != null) ...[
                              Text(
                                loc.speedFormatted,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Updated ${loc.timeSinceUpdate}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ] else
                              Text(
                                'No GPS data',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  // Simple coordinate-to-screen mapping for the simulated map view
  double _mapX(double longitude, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Normalize longitude to screen coordinates (simplified)
    return ((longitude + 180) / 360 * width) % width;
  }

  double _mapY(double latitude, BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.6;
    // Normalize latitude to screen coordinates (simplified)
    return ((90 - latitude) / 180 * height) % height;
  }
}

/// Custom painter for the simulated map background
class _MapPainter extends CustomPainter {
  final Map<String, BusLatestLocation> locations;
  final String? selectedVehicleId;
  final List<BusGeofence> geofences;

  _MapPainter({
    required this.locations,
    this.selectedVehicleId,
    required this.geofences,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw geofence circles
    for (final gf in geofences) {
      final cx = ((gf.longitude + 180) / 360 * size.width) % size.width;
      final cy = ((90 - gf.latitude) / 180 * size.height) % size.height;
      final radius = gf.radiusMeters / 10; // Simplified scaling

      final fillPaint = Paint()
        ..color = (gf.zoneType == 'school'
                ? AppColors.success
                : gf.zoneType == 'restricted'
                    ? AppColors.error
                    : AppColors.info)
            .withValues(alpha: 0.15);

      final borderPaint = Paint()
        ..color = (gf.zoneType == 'school'
                ? AppColors.success
                : gf.zoneType == 'restricted'
                    ? AppColors.error
                    : AppColors.info)
            .withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(cx, cy), radius, fillPaint);
      canvas.drawCircle(Offset(cx, cy), radius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.locations != locations ||
        oldDelegate.selectedVehicleId != selectedVehicleId ||
        oldDelegate.geofences != geofences;
  }
}
