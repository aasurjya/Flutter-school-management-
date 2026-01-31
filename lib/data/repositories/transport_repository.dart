import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transport.dart';
import 'base_repository.dart';

class TransportRepository extends BaseRepository {
  TransportRepository(super.client);

  // ==================== ROUTES ====================

  Future<List<TransportRoute>> getRoutes({bool activeOnly = true}) async {
    var query = client
        .from('transport_routes')
        .select('''
          *,
          transport_stops(*)
        ''')
        .eq('tenant_id', tenantId!);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('name');
    return (response as List).map((json) => TransportRoute.fromJson(json)).toList();
  }

  Future<TransportRoute?> getRouteById(String routeId) async {
    final response = await client
        .from('transport_routes')
        .select('''
          *,
          transport_stops(*)
        ''')
        .eq('id', routeId)
        .maybeSingle();

    if (response == null) return null;
    return TransportRoute.fromJson(response);
  }

  Future<TransportRoute> createRoute(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    final response = await client
        .from('transport_routes')
        .insert(data)
        .select()
        .single();
    return TransportRoute.fromJson(response);
  }

  Future<TransportRoute> updateRoute(String routeId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('transport_routes')
        .update(data)
        .eq('id', routeId)
        .select()
        .single();
    return TransportRoute.fromJson(response);
  }

  Future<void> deleteRoute(String routeId) async {
    await client.from('transport_routes').delete().eq('id', routeId);
  }

  // ==================== STOPS ====================

  Future<List<TransportStop>> getStops(String routeId) async {
    final response = await client
        .from('transport_stops')
        .select()
        .eq('route_id', routeId)
        .order('sequence_order');

    return (response as List).map((json) => TransportStop.fromJson(json)).toList();
  }

  Future<TransportStop> createStop(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    final response = await client
        .from('transport_stops')
        .insert(data)
        .select()
        .single();
    return TransportStop.fromJson(response);
  }

  Future<TransportStop> updateStop(String stopId, Map<String, dynamic> data) async {
    final response = await client
        .from('transport_stops')
        .update(data)
        .eq('id', stopId)
        .select()
        .single();
    return TransportStop.fromJson(response);
  }

  Future<void> deleteStop(String stopId) async {
    await client.from('transport_stops').delete().eq('id', stopId);
  }

  // ==================== STUDENT TRANSPORT ====================

  Future<List<StudentTransport>> getStudentsByRoute(String routeId) async {
    final response = await client
        .from('student_transport')
        .select('''
          *,
          transport_routes(*),
          transport_stops(*),
          students(first_name, last_name)
        ''')
        .eq('route_id', routeId)
        .order('created_at');

    return (response as List)
        .map((json) => StudentTransport.fromJson(json))
        .toList();
  }

  Future<List<StudentTransport>> getStudentsByStop(String stopId) async {
    final response = await client
        .from('student_transport')
        .select('''
          *,
          transport_routes(*),
          transport_stops(*),
          students(first_name, last_name)
        ''')
        .eq('stop_id', stopId)
        .order('created_at');

    return (response as List)
        .map((json) => StudentTransport.fromJson(json))
        .toList();
  }

  Future<StudentTransport?> getStudentTransport(String studentId) async {
    // Get current academic year
    final academicYearResponse = await client
        .from('academic_years')
        .select('id')
        .eq('tenant_id', tenantId!)
        .eq('is_current', true)
        .maybeSingle();

    if (academicYearResponse == null) return null;

    final response = await client
        .from('student_transport')
        .select('''
          *,
          transport_routes(*,transport_stops(*)),
          transport_stops(*)
        ''')
        .eq('student_id', studentId)
        .eq('academic_year_id', academicYearResponse['id'])
        .maybeSingle();

    if (response == null) return null;
    return StudentTransport.fromJson(response);
  }

  Future<StudentTransport?> getMyTransport(String userId) async {
    // First get student ID
    final studentResponse = await client
        .from('students')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (studentResponse == null) return null;
    return getStudentTransport(studentResponse['id']);
  }

  Future<StudentTransport> allocateTransport({
    required String studentId,
    required String routeId,
    required String stopId,
    required String academicYearId,
    bool pickupEnabled = true,
    bool dropEnabled = true,
  }) async {
    final response = await client
        .from('student_transport')
        .insert({
          'tenant_id': tenantId,
          'student_id': studentId,
          'route_id': routeId,
          'stop_id': stopId,
          'academic_year_id': academicYearId,
          'pickup_enabled': pickupEnabled,
          'drop_enabled': dropEnabled,
        })
        .select()
        .single();

    return StudentTransport.fromJson(response);
  }

  Future<void> updateTransportAllocation(
    String allocationId,
    Map<String, dynamic> data,
  ) async {
    await client
        .from('student_transport')
        .update(data)
        .eq('id', allocationId);
  }

  Future<void> removeTransportAllocation(String allocationId) async {
    await client.from('student_transport').delete().eq('id', allocationId);
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getTransportStats() async {
    final routesResponse = await client
        .from('transport_routes')
        .select('id, capacity')
        .eq('tenant_id', tenantId!)
        .eq('is_active', true);

    final routes = routesResponse as List;
    final totalRoutes = routes.length;
    final totalCapacity = routes.fold<int>(0, (sum, r) => sum + ((r['capacity'] as int?) ?? 0));

    // Get current academic year
    final academicYearResponse = await client
        .from('academic_years')
        .select('id')
        .eq('tenant_id', tenantId!)
        .eq('is_current', true)
        .maybeSingle();

    int totalAllocations = 0;
    if (academicYearResponse != null) {
      final allocationsResponse = await client
          .from('student_transport')
          .select('id')
          .eq('tenant_id', tenantId!)
          .eq('academic_year_id', academicYearResponse['id']);

      totalAllocations = (allocationsResponse as List).length;
    }

    return {
      'total_routes': totalRoutes,
      'total_capacity': totalCapacity,
      'total_students': totalAllocations,
      'available_seats': totalCapacity - totalAllocations,
    };
  }
}
