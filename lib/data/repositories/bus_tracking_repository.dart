import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bus_tracking.dart';
import 'base_repository.dart';

class BusTrackingRepository extends BaseRepository {
  BusTrackingRepository(super.client);

  // ==================== VEHICLES ====================

  Future<List<BusVehicle>> getVehicles({
    bool activeOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client.from('bus_vehicles').select('''
      *,
      bus_latest_locations(*),
      transport_routes(name),
      bus_trips!bus_trips_vehicle_id_fkey(id, trip_type, status, started_at)
    ''').eq('tenant_id', requireTenantId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response =
        await query.order('vehicle_number').range(offset, offset + limit - 1);
    return (response as List).map((j) => BusVehicle.fromJson(j)).toList();
  }

  Future<BusVehicle?> getVehicleById(String vehicleId) async {
    final response = await client.from('bus_vehicles').select('''
      *,
      bus_latest_locations(*),
      transport_routes(name),
      bus_trips!bus_trips_vehicle_id_fkey(id, trip_type, status, started_at)
    ''').eq('id', vehicleId).maybeSingle();

    if (response == null) return null;
    return BusVehicle.fromJson(response);
  }

  Future<BusVehicle> createVehicle(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    final response =
        await client.from('bus_vehicles').insert(data).select().single();
    return BusVehicle.fromJson(response);
  }

  Future<BusVehicle> updateVehicle(
      String vehicleId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('bus_vehicles')
        .update(data)
        .eq('id', vehicleId)
        .select()
        .single();
    return BusVehicle.fromJson(response);
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await client.from('bus_vehicles').delete().eq('id', vehicleId);
  }

  // ==================== LOCATION ====================

  Future<List<BusLatestLocation>> getAllLatestLocations() async {
    final response = await client
        .from('bus_latest_locations')
        .select()
        .eq('tenant_id', requireTenantId)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((j) => BusLatestLocation.fromJson(j))
        .toList();
  }

  Future<BusLatestLocation?> getLatestLocation(String vehicleId) async {
    final response = await client
        .from('bus_latest_locations')
        .select()
        .eq('vehicle_id', vehicleId)
        .maybeSingle();

    if (response == null) return null;
    return BusLatestLocation.fromJson(response);
  }

  /// Send a GPS ping from the driver's device
  Future<void> sendLocationPing({
    required String vehicleId,
    required double latitude,
    required double longitude,
    double speedKmh = 0,
    double heading = 0,
    double? accuracyMeters,
    bool isIgnitionOn = true,
  }) async {
    await client.from('bus_location_pings').insert({
      'tenant_id': requireTenantId,
      'vehicle_id': vehicleId,
      'latitude': latitude,
      'longitude': longitude,
      'speed_kmh': speedKmh,
      'heading': heading,
      'accuracy_meters': accuracyMeters,
      'is_ignition_on': isIgnitionOn,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get location history for a vehicle (trail)
  Future<List<BusLocationPing>> getLocationHistory(
    String vehicleId, {
    DateTime? since,
    int limit = 200,
  }) async {
    var query = client
        .from('bus_location_pings')
        .select()
        .eq('vehicle_id', vehicleId);

    if (since != null) {
      query = query.gte('recorded_at', since.toIso8601String());
    }

    final response =
        await query.order('recorded_at', ascending: false).limit(limit);
    return (response as List)
        .map((j) => BusLocationPing.fromJson(j))
        .toList();
  }

  /// Subscribe to real-time location updates for all vehicles
  RealtimeChannel subscribeToLocationUpdates({
    required void Function(BusLatestLocation location) onUpdate,
  }) {
    return subscribeToTable(
      'bus_latest_locations',
      onInsert: (payload) {
        if (payload.newRecord.isNotEmpty) {
          onUpdate(BusLatestLocation.fromJson(payload.newRecord));
        }
      },
      onUpdate: (payload) {
        if (payload.newRecord.isNotEmpty) {
          onUpdate(BusLatestLocation.fromJson(payload.newRecord));
        }
      },
      filter: (column: 'tenant_id', value: requireTenantId),
    );
  }

  // ==================== GEOFENCES ====================

  Future<List<BusGeofence>> getGeofences({bool activeOnly = true}) async {
    var query = client
        .from('bus_geofences')
        .select()
        .eq('tenant_id', requireTenantId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('name');
    return (response as List).map((j) => BusGeofence.fromJson(j)).toList();
  }

  Future<BusGeofence> createGeofence(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    final response =
        await client.from('bus_geofences').insert(data).select().single();
    return BusGeofence.fromJson(response);
  }

  Future<BusGeofence> updateGeofence(
      String geofenceId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('bus_geofences')
        .update(data)
        .eq('id', geofenceId)
        .select()
        .single();
    return BusGeofence.fromJson(response);
  }

  Future<void> deleteGeofence(String geofenceId) async {
    await client.from('bus_geofences').delete().eq('id', geofenceId);
  }

  Future<List<BusGeofenceEvent>> getGeofenceEvents({
    String? vehicleId,
    int limit = 50,
  }) async {
    var query = client.from('bus_geofence_events').select('''
      *,
      bus_vehicles(vehicle_number),
      bus_geofences(name)
    ''').eq('tenant_id', requireTenantId);

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }

    final response =
        await query.order('recorded_at', ascending: false).limit(limit);
    return (response as List)
        .map((j) => BusGeofenceEvent.fromJson(j))
        .toList();
  }

  // ==================== TRIPS ====================

  Future<List<BusTrip>> getTrips({
    String? vehicleId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client.from('bus_trips').select('''
      *,
      bus_vehicles(vehicle_number),
      transport_routes(name),
      bus_stop_checkins(*, transport_stops(name))
    ''').eq('tenant_id', requireTenantId);

    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('started_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((j) => BusTrip.fromJson(j)).toList();
  }

  Future<BusTrip> startTrip({
    required String vehicleId,
    String? routeId,
    required String tripType,
    double? latitude,
    double? longitude,
  }) async {
    final response = await client
        .from('bus_trips')
        .insert({
          'tenant_id': requireTenantId,
          'vehicle_id': vehicleId,
          'route_id': routeId,
          'trip_type': tripType,
          'started_at': DateTime.now().toIso8601String(),
          'start_latitude': latitude,
          'start_longitude': longitude,
          'status': 'in_progress',
        })
        .select()
        .single();
    return BusTrip.fromJson(response);
  }

  Future<BusTrip> endTrip(
    String tripId, {
    double? latitude,
    double? longitude,
    double? distanceKm,
  }) async {
    final response = await client
        .from('bus_trips')
        .update({
          'ended_at': DateTime.now().toIso8601String(),
          'end_latitude': latitude,
          'end_longitude': longitude,
          'distance_km': distanceKm,
          'status': 'completed',
        })
        .eq('id', tripId)
        .select()
        .single();
    return BusTrip.fromJson(response);
  }

  // ==================== STOP CHECKINS ====================

  Future<BusStopCheckin> checkinAtStop({
    required String tripId,
    required String stopId,
    required String vehicleId,
    double? latitude,
    double? longitude,
  }) async {
    final response = await client
        .from('bus_stop_checkins')
        .insert({
          'tenant_id': requireTenantId,
          'trip_id': tripId,
          'stop_id': stopId,
          'vehicle_id': vehicleId,
          'arrived_at': DateTime.now().toIso8601String(),
          'latitude': latitude,
          'longitude': longitude,
        })
        .select('*, transport_stops(name)')
        .single();
    return BusStopCheckin.fromJson(response);
  }

  Future<BusStopCheckin> departFromStop(
    String checkinId, {
    int studentsBoarded = 0,
    int studentsAlighted = 0,
  }) async {
    final response = await client
        .from('bus_stop_checkins')
        .update({
          'departed_at': DateTime.now().toIso8601String(),
          'students_boarded': studentsBoarded,
          'students_alighted': studentsAlighted,
        })
        .eq('id', checkinId)
        .select('*, transport_stops(name)')
        .single();
    return BusStopCheckin.fromJson(response);
  }

  // ==================== PARENT SUBSCRIPTIONS ====================

  Future<List<BusTrackingSubscription>> getParentSubscriptions(
      String parentUserId) async {
    final response =
        await client.from('bus_tracking_subscriptions').select('''
      *,
      bus_vehicles(vehicle_number),
      students(first_name, last_name)
    ''').eq('parent_user_id', parentUserId);

    return (response as List)
        .map((j) => BusTrackingSubscription.fromJson(j))
        .toList();
  }

  Future<BusTrackingSubscription> subscribeToVehicle({
    required String parentUserId,
    required String vehicleId,
    required String studentId,
  }) async {
    final response = await client
        .from('bus_tracking_subscriptions')
        .insert({
          'tenant_id': requireTenantId,
          'parent_user_id': parentUserId,
          'vehicle_id': vehicleId,
          'student_id': studentId,
        })
        .select()
        .single();
    return BusTrackingSubscription.fromJson(response);
  }

  Future<void> unsubscribeFromVehicle(String subscriptionId) async {
    await client
        .from('bus_tracking_subscriptions')
        .delete()
        .eq('id', subscriptionId);
  }

  // ==================== STATS ====================

  Future<Map<String, dynamic>> getTrackingStats() async {
    final vehicles = await client
        .from('bus_vehicles')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .eq('is_active', true);

    final activeTrips = await client
        .from('bus_trips')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .eq('status', 'in_progress');

    final onlineLocations = await client
        .from('bus_latest_locations')
        .select('vehicle_id, recorded_at')
        .eq('tenant_id', requireTenantId);

    final tenMinAgo = DateTime.now().subtract(const Duration(minutes: 10));
    final onlineCount = (onlineLocations as List)
        .where(
            (l) => DateTime.parse(l['recorded_at']).isAfter(tenMinAgo))
        .length;

    final geofences = await client
        .from('bus_geofences')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .eq('is_active', true);

    return {
      'total_vehicles': (vehicles as List).length,
      'active_trips': (activeTrips as List).length,
      'online_vehicles': onlineCount,
      'total_geofences': (geofences as List).length,
    };
  }
}
