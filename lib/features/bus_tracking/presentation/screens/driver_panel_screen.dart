import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/bus_tracking.dart';
import '../../providers/bus_tracking_provider.dart';

/// Driver panel for starting/ending trips and checking in at stops.
/// In production, this would use geolocator package for real GPS.
class DriverPanelScreen extends ConsumerStatefulWidget {
  const DriverPanelScreen({super.key});

  @override
  ConsumerState<DriverPanelScreen> createState() => _DriverPanelScreenState();
}

class _DriverPanelScreenState extends ConsumerState<DriverPanelScreen> {
  String? _selectedVehicleId;
  BusTrip? _activeTrip;
  bool _isStartingTrip = false;
  bool _isEndingTrip = false;
  bool _isTracking = false;
  Timer? _locationTimer;
  String _tripType = 'pickup';

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _sendMockLocationPing();
    });
    setState(() => _isTracking = true);
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    setState(() => _isTracking = false);
  }

  Future<void> _sendMockLocationPing() async {
    if (_selectedVehicleId == null) return;
    try {
      final repo = ref.read(busTrackingRepositoryProvider);
      // In production, use geolocator to get real coordinates
      // For now, send mock data to demonstrate the pipeline
      await repo.sendLocationPing(
        vehicleId: _selectedVehicleId!,
        latitude: 12.9716 + (DateTime.now().millisecond / 100000),
        longitude: 77.5946 + (DateTime.now().millisecond / 100000),
        speedKmh: 30.0 + (DateTime.now().second % 20).toDouble(),
        heading: (DateTime.now().second * 6).toDouble(),
      );
    } catch (_) {
      // Silently handle ping failures
    }
  }

  Future<void> _startTrip() async {
    if (_selectedVehicleId == null) return;

    setState(() => _isStartingTrip = true);
    try {
      final repo = ref.read(busTrackingRepositoryProvider);
      final trip = await repo.startTrip(
        vehicleId: _selectedVehicleId!,
        tripType: _tripType,
        latitude: 12.9716,
        longitude: 77.5946,
      );
      setState(() {
        _activeTrip = trip;
        _isStartingTrip = false;
      });
      _startLocationTracking();
      ref.invalidate(activeTripsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip started: ${trip.tripLabel}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isStartingTrip = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _endTrip() async {
    if (_activeTrip == null) return;

    setState(() => _isEndingTrip = true);
    try {
      final repo = ref.read(busTrackingRepositoryProvider);
      await repo.endTrip(
        _activeTrip!.id,
        latitude: 12.9716,
        longitude: 77.5946,
      );
      _stopLocationTracking();
      setState(() {
        _activeTrip = null;
        _isEndingTrip = false;
      });
      ref.invalidate(activeTripsProvider);
      ref.invalidate(busTripsProvider(_selectedVehicleId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip completed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isEndingTrip = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(busVehiclesProvider(true));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Panel'),
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Vehicle selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT VEHICLE',
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleId,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.directions_bus),
                          hintText: 'Choose your bus',
                        ),
                        items: vehicles.map((v) {
                          return DropdownMenuItem(
                            value: v.id,
                            child: Text(
                                '${v.vehicleNumber} (${v.vehicleType})'),
                          );
                        }).toList(),
                        onChanged: _activeTrip != null
                            ? null
                            : (v) => setState(() => _selectedVehicleId = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Trip type selector
              if (_activeTrip == null && _selectedVehicleId != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRIP TYPE',
                          style: theme.textTheme.labelMedium?.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'pickup',
                              label: Text('Morning Pickup'),
                              icon: Icon(Icons.wb_sunny_outlined),
                            ),
                            ButtonSegment(
                              value: 'drop',
                              label: Text('Afternoon Drop'),
                              icon: Icon(Icons.wb_twilight_outlined),
                            ),
                          ],
                          selected: {_tripType},
                          onSelectionChanged: (s) =>
                              setState(() => _tripType = s.first),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Trip control
              if (_selectedVehicleId != null) ...[
                if (_activeTrip == null) ...[
                  // Start trip button
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: FilledButton.icon(
                      onPressed: _isStartingTrip ? null : _startTrip,
                      icon: _isStartingTrip
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow, size: 32),
                      label: Text(
                        _isStartingTrip ? 'Starting...' : 'START TRIP',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Active trip info
                  Card(
                    color: AppColors.success.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isTracking
                                      ? Icons.gps_fixed
                                      : Icons.gps_not_fixed,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TRIP IN PROGRESS',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        letterSpacing: 1.0,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _activeTrip!.tripLabel,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Duration: ${_activeTrip!.durationFormatted}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Tracking toggle
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isTracking
                                      ? _stopLocationTracking
                                      : _startLocationTracking,
                                  icon: Icon(
                                    _isTracking
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                  label: Text(
                                    _isTracking ? 'Pause GPS' : 'Resume GPS',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // End trip button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: _isEndingTrip ? null : _endTrip,
                              icon: _isEndingTrip
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.stop),
                              label: Text(
                                _isEndingTrip ? 'Ending...' : 'END TRIP',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.error,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],

              if (_selectedVehicleId == null) ...[
                const SizedBox(height: 48),
                Icon(Icons.directions_bus_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Select a vehicle to begin',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
