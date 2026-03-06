/// GPS-enabled bus vehicle
class BusVehicle {
  final String id;
  final String tenantId;
  final String? routeId;
  final String vehicleNumber;
  final String vehicleType;
  final String? driverName;
  final String? driverPhone;
  final String? driverUserId;
  final String? helperName;
  final String? helperPhone;
  final int capacity;
  final bool isActive;
  final String? gpsDeviceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related
  final BusLatestLocation? latestLocation;
  final String? routeName;
  final BusTrip? activeTrip;

  const BusVehicle({
    required this.id,
    required this.tenantId,
    this.routeId,
    required this.vehicleNumber,
    this.vehicleType = 'bus',
    this.driverName,
    this.driverPhone,
    this.driverUserId,
    this.helperName,
    this.helperPhone,
    this.capacity = 40,
    this.isActive = true,
    this.gpsDeviceId,
    required this.createdAt,
    required this.updatedAt,
    this.latestLocation,
    this.routeName,
    this.activeTrip,
  });

  factory BusVehicle.fromJson(Map<String, dynamic> json) {
    BusLatestLocation? location;
    if (json['bus_latest_locations'] != null) {
      final locData = json['bus_latest_locations'];
      if (locData is List && locData.isNotEmpty) {
        location = BusLatestLocation.fromJson(locData[0]);
      } else if (locData is Map<String, dynamic>) {
        location = BusLatestLocation.fromJson(locData);
      }
    }

    BusTrip? activeTrip;
    if (json['bus_trips'] != null) {
      final trips = json['bus_trips'];
      if (trips is List && trips.isNotEmpty) {
        activeTrip = BusTrip.fromJson(trips[0]);
      }
    }

    String? routeName;
    if (json['transport_routes'] != null) {
      routeName = json['transport_routes']['name'];
    }

    return BusVehicle(
      id: json['id'],
      tenantId: json['tenant_id'],
      routeId: json['route_id'],
      vehicleNumber: json['vehicle_number'],
      vehicleType: json['vehicle_type'] ?? 'bus',
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      driverUserId: json['driver_user_id'],
      helperName: json['helper_name'],
      helperPhone: json['helper_phone'],
      capacity: json['capacity'] ?? 40,
      isActive: json['is_active'] ?? true,
      gpsDeviceId: json['gps_device_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      latestLocation: location,
      routeName: routeName,
      activeTrip: activeTrip,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'route_id': routeId,
        'vehicle_number': vehicleNumber,
        'vehicle_type': vehicleType,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'driver_user_id': driverUserId,
        'helper_name': helperName,
        'helper_phone': helperPhone,
        'capacity': capacity,
        'is_active': isActive,
        'gps_device_id': gpsDeviceId,
      };

  String get vehicleIcon {
    switch (vehicleType) {
      case 'van':
        return 'airport_shuttle';
      case 'minibus':
        return 'directions_bus';
      default:
        return 'directions_bus_filled';
    }
  }

  bool get isTracking =>
      latestLocation != null &&
      latestLocation!.recordedAt
          .isAfter(DateTime.now().subtract(const Duration(minutes: 10)));

  String get statusLabel {
    if (!isActive) return 'Inactive';
    if (activeTrip != null) return 'On Trip';
    if (isTracking) return 'Online';
    return 'Offline';
  }
}

/// Latest known location for a vehicle
class BusLatestLocation {
  final String vehicleId;
  final String tenantId;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double heading;
  final bool isIgnitionOn;
  final DateTime recordedAt;
  final DateTime updatedAt;

  const BusLatestLocation({
    required this.vehicleId,
    required this.tenantId,
    required this.latitude,
    required this.longitude,
    this.speedKmh = 0,
    this.heading = 0,
    this.isIgnitionOn = true,
    required this.recordedAt,
    required this.updatedAt,
  });

  factory BusLatestLocation.fromJson(Map<String, dynamic> json) {
    return BusLatestLocation(
      vehicleId: json['vehicle_id'],
      tenantId: json['tenant_id'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      isIgnitionOn: json['is_ignition_on'] ?? true,
      recordedAt: DateTime.parse(json['recorded_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get speedFormatted => '${speedKmh.toStringAsFixed(0)} km/h';

  String get timeSinceUpdate {
    final diff = DateTime.now().difference(recordedAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  bool get isStale =>
      DateTime.now().difference(recordedAt) > const Duration(minutes: 10);
}

/// A location ping record
class BusLocationPing {
  final String id;
  final String tenantId;
  final String vehicleId;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double heading;
  final double? accuracyMeters;
  final bool isIgnitionOn;
  final DateTime recordedAt;

  const BusLocationPing({
    required this.id,
    required this.tenantId,
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    this.speedKmh = 0,
    this.heading = 0,
    this.accuracyMeters,
    this.isIgnitionOn = true,
    required this.recordedAt,
  });

  factory BusLocationPing.fromJson(Map<String, dynamic> json) {
    return BusLocationPing(
      id: json['id'],
      tenantId: json['tenant_id'],
      vehicleId: json['vehicle_id'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
      isIgnitionOn: json['is_ignition_on'] ?? true,
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'vehicle_id': vehicleId,
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmh': speedKmh,
        'heading': heading,
        'accuracy_meters': accuracyMeters,
        'is_ignition_on': isIgnitionOn,
        'recorded_at': recordedAt.toIso8601String(),
      };
}

/// Geofence zone
class BusGeofence {
  final String id;
  final String tenantId;
  final String name;
  final String zoneType;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;
  final bool notifyOnEnter;
  final bool notifyOnExit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusGeofence({
    required this.id,
    required this.tenantId,
    required this.name,
    this.zoneType = 'school',
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200,
    this.isActive = true,
    this.notifyOnEnter = true,
    this.notifyOnExit = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusGeofence.fromJson(Map<String, dynamic> json) {
    return BusGeofence(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      zoneType: json['zone_type'] ?? 'school',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 200,
      isActive: json['is_active'] ?? true,
      notifyOnEnter: json['notify_on_enter'] ?? true,
      notifyOnExit: json['notify_on_exit'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'name': name,
        'zone_type': zoneType,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'is_active': isActive,
        'notify_on_enter': notifyOnEnter,
        'notify_on_exit': notifyOnExit,
      };

  String get zoneLabel {
    switch (zoneType) {
      case 'school':
        return 'School';
      case 'stop':
        return 'Bus Stop';
      case 'restricted':
        return 'Restricted';
      case 'custom':
        return 'Custom';
      default:
        return zoneType;
    }
  }
}

/// Geofence event
class BusGeofenceEvent {
  final String id;
  final String tenantId;
  final String vehicleId;
  final String geofenceId;
  final String eventType; // entered, exited
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final bool notified;

  // Related
  final String? vehicleNumber;
  final String? geofenceName;

  const BusGeofenceEvent({
    required this.id,
    required this.tenantId,
    required this.vehicleId,
    required this.geofenceId,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.notified = false,
    this.vehicleNumber,
    this.geofenceName,
  });

  factory BusGeofenceEvent.fromJson(Map<String, dynamic> json) {
    return BusGeofenceEvent(
      id: json['id'],
      tenantId: json['tenant_id'],
      vehicleId: json['vehicle_id'],
      geofenceId: json['geofence_id'],
      eventType: json['event_type'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at']),
      notified: json['notified'] ?? false,
      vehicleNumber: json['bus_vehicles']?['vehicle_number'],
      geofenceName: json['bus_geofences']?['name'],
    );
  }
}

/// Bus trip record
class BusTrip {
  final String id;
  final String tenantId;
  final String vehicleId;
  final String? routeId;
  final String tripType; // pickup, drop
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final double? distanceKm;
  final String status; // in_progress, completed, cancelled

  // Related
  final String? vehicleNumber;
  final String? routeName;
  final List<BusStopCheckin>? checkins;

  const BusTrip({
    required this.id,
    required this.tenantId,
    required this.vehicleId,
    this.routeId,
    this.tripType = 'pickup',
    required this.startedAt,
    this.endedAt,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.distanceKm,
    this.status = 'in_progress',
    this.vehicleNumber,
    this.routeName,
    this.checkins,
  });

  factory BusTrip.fromJson(Map<String, dynamic> json) {
    List<BusStopCheckin>? checkins;
    if (json['bus_stop_checkins'] != null) {
      checkins = (json['bus_stop_checkins'] as List)
          .map((e) => BusStopCheckin.fromJson(e))
          .toList();
    }

    return BusTrip(
      id: json['id'],
      tenantId: json['tenant_id'],
      vehicleId: json['vehicle_id'],
      routeId: json['route_id'],
      tripType: json['trip_type'] ?? 'pickup',
      startedAt: DateTime.parse(json['started_at']),
      endedAt:
          json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      startLatitude: (json['start_latitude'] as num?)?.toDouble(),
      startLongitude: (json['start_longitude'] as num?)?.toDouble(),
      endLatitude: (json['end_latitude'] as num?)?.toDouble(),
      endLongitude: (json['end_longitude'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      status: json['status'] ?? 'in_progress',
      vehicleNumber: json['bus_vehicles']?['vehicle_number'],
      routeName: json['transport_routes']?['name'],
      checkins: checkins,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'vehicle_id': vehicleId,
        'route_id': routeId,
        'trip_type': tripType,
        'started_at': startedAt.toIso8601String(),
        'start_latitude': startLatitude,
        'start_longitude': startLongitude,
        'status': status,
      };

  bool get isInProgress => status == 'in_progress';

  String get tripLabel => tripType == 'pickup' ? 'Morning Pickup' : 'Afternoon Drop';

  String get durationFormatted {
    final end = endedAt ?? DateTime.now();
    final diff = end.difference(startedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }
}

/// Stop check-in by driver
class BusStopCheckin {
  final String id;
  final String tenantId;
  final String tripId;
  final String stopId;
  final String vehicleId;
  final DateTime arrivedAt;
  final DateTime? departedAt;
  final int studentsBoarded;
  final int studentsAlighted;
  final double? latitude;
  final double? longitude;

  // Related
  final String? stopName;

  const BusStopCheckin({
    required this.id,
    required this.tenantId,
    required this.tripId,
    required this.stopId,
    required this.vehicleId,
    required this.arrivedAt,
    this.departedAt,
    this.studentsBoarded = 0,
    this.studentsAlighted = 0,
    this.latitude,
    this.longitude,
    this.stopName,
  });

  factory BusStopCheckin.fromJson(Map<String, dynamic> json) {
    return BusStopCheckin(
      id: json['id'],
      tenantId: json['tenant_id'],
      tripId: json['trip_id'],
      stopId: json['stop_id'],
      vehicleId: json['vehicle_id'],
      arrivedAt: DateTime.parse(json['arrived_at']),
      departedAt: json['departed_at'] != null
          ? DateTime.parse(json['departed_at'])
          : null,
      studentsBoarded: json['students_boarded'] ?? 0,
      studentsAlighted: json['students_alighted'] ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      stopName: json['transport_stops']?['name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'trip_id': tripId,
        'stop_id': stopId,
        'vehicle_id': vehicleId,
        'arrived_at': arrivedAt.toIso8601String(),
        'departed_at': departedAt?.toIso8601String(),
        'students_boarded': studentsBoarded,
        'students_alighted': studentsAlighted,
        'latitude': latitude,
        'longitude': longitude,
      };
}

/// Parent's tracking subscription
class BusTrackingSubscription {
  final String id;
  final String tenantId;
  final String parentUserId;
  final String vehicleId;
  final String studentId;
  final bool notifyArrival;
  final bool notifyDeparture;
  final bool notifyDelay;
  final DateTime createdAt;

  // Related
  final String? vehicleNumber;
  final String? studentName;

  const BusTrackingSubscription({
    required this.id,
    required this.tenantId,
    required this.parentUserId,
    required this.vehicleId,
    required this.studentId,
    this.notifyArrival = true,
    this.notifyDeparture = true,
    this.notifyDelay = true,
    required this.createdAt,
    this.vehicleNumber,
    this.studentName,
  });

  factory BusTrackingSubscription.fromJson(Map<String, dynamic> json) {
    String? studentName;
    if (json['students'] != null) {
      studentName =
          '${json['students']['first_name']} ${json['students']['last_name'] ?? ''}'
              .trim();
    }

    return BusTrackingSubscription(
      id: json['id'],
      tenantId: json['tenant_id'],
      parentUserId: json['parent_user_id'],
      vehicleId: json['vehicle_id'],
      studentId: json['student_id'],
      notifyArrival: json['notify_arrival'] ?? true,
      notifyDeparture: json['notify_departure'] ?? true,
      notifyDelay: json['notify_delay'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      vehicleNumber: json['bus_vehicles']?['vehicle_number'],
      studentName: studentName,
    );
  }
}
