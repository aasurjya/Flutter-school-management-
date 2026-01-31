/// Transport route model
class TransportRoute {
  final String id;
  final String tenantId;
  final String name;
  final String? code;
  final String? vehicleNumber;
  final String? driverName;
  final String? driverPhone;
  final String? helperName;
  final String? helperPhone;
  final int? capacity;
  final double? farePerMonth;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final List<TransportStop>? stops;
  final int? studentCount;

  const TransportRoute({
    required this.id,
    required this.tenantId,
    required this.name,
    this.code,
    this.vehicleNumber,
    this.driverName,
    this.driverPhone,
    this.helperName,
    this.helperPhone,
    this.capacity,
    this.farePerMonth,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.stops,
    this.studentCount,
  });

  factory TransportRoute.fromJson(Map<String, dynamic> json) {
    List<TransportStop>? stops;
    if (json['transport_stops'] != null) {
      stops = (json['transport_stops'] as List)
          .map((stop) => TransportStop.fromJson(stop))
          .toList();
      stops.sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
    }

    return TransportRoute(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      code: json['code'],
      vehicleNumber: json['vehicle_number'],
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      helperName: json['helper_name'],
      helperPhone: json['helper_phone'],
      capacity: json['capacity'],
      farePerMonth: (json['fare_per_month'] as num?)?.toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      stops: stops,
      studentCount: json['student_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'code': code,
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'helper_name': helperName,
      'helper_phone': helperPhone,
      'capacity': capacity,
      'fare_per_month': farePerMonth,
      'is_active': isActive,
    };
  }

  String get fareFormatted =>
      farePerMonth != null ? '\u20B9${farePerMonth!.toStringAsFixed(2)}/month' : 'N/A';
}

/// Transport stop model
class TransportStop {
  final String id;
  final String tenantId;
  final String routeId;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? pickupTime;
  final String? dropTime;
  final int sequenceOrder;
  final DateTime createdAt;

  const TransportStop({
    required this.id,
    required this.tenantId,
    required this.routeId,
    required this.name,
    this.latitude,
    this.longitude,
    this.pickupTime,
    this.dropTime,
    required this.sequenceOrder,
    required this.createdAt,
  });

  factory TransportStop.fromJson(Map<String, dynamic> json) {
    return TransportStop(
      id: json['id'],
      tenantId: json['tenant_id'],
      routeId: json['route_id'],
      name: json['name'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      pickupTime: json['pickup_time'],
      dropTime: json['drop_time'],
      sequenceOrder: json['sequence_order'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'route_id': routeId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'pickup_time': pickupTime,
      'drop_time': dropTime,
      'sequence_order': sequenceOrder,
    };
  }

  bool get hasLocation => latitude != null && longitude != null;
}

/// Student transport allocation model
class StudentTransport {
  final String id;
  final String tenantId;
  final String studentId;
  final String routeId;
  final String stopId;
  final String academicYearId;
  final bool pickupEnabled;
  final bool dropEnabled;
  final DateTime createdAt;

  // Related data
  final TransportRoute? route;
  final TransportStop? stop;
  final String? studentName;

  const StudentTransport({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.routeId,
    required this.stopId,
    required this.academicYearId,
    this.pickupEnabled = true,
    this.dropEnabled = true,
    required this.createdAt,
    this.route,
    this.stop,
    this.studentName,
  });

  factory StudentTransport.fromJson(Map<String, dynamic> json) {
    TransportRoute? route;
    if (json['transport_routes'] != null) {
      route = TransportRoute.fromJson(json['transport_routes']);
    }

    TransportStop? stop;
    if (json['transport_stops'] != null) {
      stop = TransportStop.fromJson(json['transport_stops']);
    }

    String? studentName;
    if (json['students'] != null) {
      studentName =
          '${json['students']['first_name']} ${json['students']['last_name'] ?? ''}'.trim();
    }

    return StudentTransport(
      id: json['id'],
      tenantId: json['tenant_id'],
      studentId: json['student_id'],
      routeId: json['route_id'],
      stopId: json['stop_id'],
      academicYearId: json['academic_year_id'],
      pickupEnabled: json['pickup_enabled'] ?? true,
      dropEnabled: json['drop_enabled'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      route: route,
      stop: stop,
      studentName: studentName,
    );
  }

  String get serviceType {
    if (pickupEnabled && dropEnabled) return 'Both Way';
    if (pickupEnabled) return 'Pickup Only';
    if (dropEnabled) return 'Drop Only';
    return 'None';
  }
}
