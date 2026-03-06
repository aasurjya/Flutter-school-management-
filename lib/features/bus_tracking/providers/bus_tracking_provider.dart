import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/bus_tracking.dart';
import '../../../data/repositories/bus_tracking_repository.dart';

// ==================== REPOSITORY ====================

final busTrackingRepositoryProvider = Provider<BusTrackingRepository>((ref) {
  return BusTrackingRepository(ref.watch(supabaseProvider));
});

// ==================== VEHICLES ====================

final busVehiclesProvider =
    FutureProvider.family<List<BusVehicle>, bool>((ref, activeOnly) async {
  final repo = ref.watch(busTrackingRepositoryProvider);
  return repo.getVehicles(activeOnly: activeOnly);
});

final busVehicleByIdProvider =
    FutureProvider.family<BusVehicle?, String>((ref, vehicleId) async {
  final repo = ref.watch(busTrackingRepositoryProvider);
  return repo.getVehicleById(vehicleId);
});

// ==================== LIVE LOCATIONS ====================

final busLatestLocationsProvider =
    FutureProvider<List<BusLatestLocation>>((ref) async {
  final repo = ref.watch(busTrackingRepositoryProvider);
  return repo.getAllLatestLocations();
});

/// Real-time location state notifier that listens to Supabase changes
class LiveLocationNotifier extends StateNotifier<Map<String, BusLatestLocation>> {
  final BusTrackingRepository _repo;
  RealtimeChannel? _channel;

  LiveLocationNotifier(this._repo) : super({}) {
    _init();
  }

  Future<void> _init() async {
    // Load initial locations
    try {
      final locations = await _repo.getAllLatestLocations();
      final map = <String, BusLatestLocation>{};
      for (final loc in locations) {
        map[loc.vehicleId] = loc;
      }
      state = map;
    } catch (_) {
      // Silently handle initial load failure
    }

    // Subscribe to real-time updates
    _channel = _repo.subscribeToLocationUpdates(
      onUpdate: (location) {
        state = {...state, location.vehicleId: location};
      },
    );
  }

  void refresh() => _init();

  @override
  void dispose() {
    if (_channel != null) {
      _repo.unsubscribe(_channel!);
    }
    super.dispose();
  }
}

final liveLocationProvider =
    StateNotifierProvider<LiveLocationNotifier, Map<String, BusLatestLocation>>(
        (ref) {
  final repo = ref.watch(busTrackingRepositoryProvider);
  return LiveLocationNotifier(repo);
});

// ==================== GEOFENCES ====================

final busGeofencesProvider =
    FutureProvider.family<List<BusGeofence>, bool>((ref, activeOnly) async {
  final repo = ref.watch(busTrackingRepositoryProvider);
  return repo.getGeofences(activeOnly: activeOnly);
});

final busGeofenceEventsProvider =
    FutureProvider.family<List<BusGeofenceEvent>, String?>(
        (ref, vehicleId) async {
  final repo = ref.watch(busTrackingRepositoryProvider);
  return repo.getGeofenceEvents(vehicleId: vehicleId);
});

// ==================== TRIPS ====================

final busTripsProvider = FutureProvider.family<List<BusTrip>, String?>(
    (ref, vehicleId) async {
  final repo = ref.watch(busTrackingRepositoryProvider);
  return repo.getTrips(vehicleId: vehicleId);
});

final activeTripsProvider = FutureProvider<List<BusTrip>>((ref) async {
  final repo = ref.watch(busTrackingRepositoryProvider);
  return repo.getTrips(status: 'in_progress');
});

// ==================== LOCATION HISTORY ====================

final locationHistoryProvider =
    FutureProvider.family<List<BusLocationPing>, String>(
        (ref, vehicleId) async {
  final repo = ref.watch(busTrackingRepositoryProvider);
  return repo.getLocationHistory(
    vehicleId,
    since: DateTime.now().subtract(const Duration(hours: 2)),
  );
});

// ==================== PARENT SUBSCRIPTIONS ====================

final parentTrackingSubscriptionsProvider =
    FutureProvider<List<BusTrackingSubscription>>((ref) async {
  final repo = ref.watch(busTrackingRepositoryProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
  if (userId == null) return [];
  return repo.getParentSubscriptions(userId);
});

// ==================== STATS ====================

final busTrackingStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(busTrackingRepositoryProvider);
  return repo.getTrackingStats();
});

// ==================== SELECTED VEHICLE ====================

final selectedVehicleIdProvider = StateProvider<String?>((ref) => null);
