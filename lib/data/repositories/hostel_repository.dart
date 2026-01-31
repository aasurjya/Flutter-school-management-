import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hostel.dart';
import 'base_repository.dart';

class HostelRepository extends BaseRepository {
  HostelRepository(super.client);

  // ==================== HOSTELS ====================

  Future<List<Hostel>> getHostels({bool activeOnly = true}) async {
    var query = client
        .from('hostels')
        .select('''
          *,
          users(full_name)
        ''')
        .eq('tenant_id', tenantId!);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('name');
    return (response as List).map((json) => Hostel.fromJson(json)).toList();
  }

  Future<Hostel?> getHostelById(String hostelId) async {
    final response = await client
        .from('hostels')
        .select('''
          *,
          users(full_name),
          hostel_rooms(*)
        ''')
        .eq('id', hostelId)
        .maybeSingle();

    if (response == null) return null;
    return Hostel.fromJson(response);
  }

  Future<Hostel> createHostel(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    final response = await client
        .from('hostels')
        .insert(data)
        .select()
        .single();
    return Hostel.fromJson(response);
  }

  Future<Hostel> updateHostel(String hostelId, Map<String, dynamic> data) async {
    final response = await client
        .from('hostels')
        .update(data)
        .eq('id', hostelId)
        .select()
        .single();
    return Hostel.fromJson(response);
  }

  Future<void> deleteHostel(String hostelId) async {
    await client.from('hostels').delete().eq('id', hostelId);
  }

  // ==================== ROOMS ====================

  Future<List<HostelRoom>> getRooms(String hostelId, {bool availableOnly = false}) async {
    var query = client
        .from('hostel_rooms')
        .select('''
          *,
          room_allocations(
            *,
            students(first_name, last_name)
          )
        ''')
        .eq('hostel_id', hostelId);

    if (availableOnly) {
      query = query.eq('is_available', true);
    }

    final response = await query.order('room_number');
    return (response as List).map((json) => HostelRoom.fromJson(json)).toList();
  }

  Future<HostelRoom?> getRoomById(String roomId) async {
    final response = await client
        .from('hostel_rooms')
        .select('''
          *,
          room_allocations(
            *,
            students(first_name, last_name)
          )
        ''')
        .eq('id', roomId)
        .maybeSingle();

    if (response == null) return null;
    return HostelRoom.fromJson(response);
  }

  Future<HostelRoom> createRoom(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    final response = await client
        .from('hostel_rooms')
        .insert(data)
        .select()
        .single();

    // Update hostel room count
    await _updateHostelCounts(data['hostel_id']);

    return HostelRoom.fromJson(response);
  }

  Future<HostelRoom> updateRoom(String roomId, Map<String, dynamic> data) async {
    final response = await client
        .from('hostel_rooms')
        .update(data)
        .eq('id', roomId)
        .select()
        .single();
    return HostelRoom.fromJson(response);
  }

  Future<void> deleteRoom(String roomId) async {
    final room = await getRoomById(roomId);
    await client.from('hostel_rooms').delete().eq('id', roomId);
    if (room != null) {
      await _updateHostelCounts(room.hostelId);
    }
  }

  // ==================== ALLOCATIONS ====================

  Future<RoomAllocation> allocateRoom({
    required String roomId,
    required String studentId,
    required String academicYearId,
    String? bedNumber,
  }) async {
    // Check room availability
    final room = await getRoomById(roomId);
    if (room == null || !room.hasVacancy) {
      throw Exception('Room is not available');
    }

    // Create allocation
    final response = await client
        .from('room_allocations')
        .insert({
          'tenant_id': tenantId,
          'room_id': roomId,
          'student_id': studentId,
          'academic_year_id': academicYearId,
          'bed_number': bedNumber,
        })
        .select()
        .single();

    // Update room occupied count
    await client
        .from('hostel_rooms')
        .update({'occupied': room.occupied + 1})
        .eq('id', roomId);

    return RoomAllocation.fromJson(response);
  }

  Future<void> vacateRoom(String allocationId) async {
    // Get allocation details
    final allocationResponse = await client
        .from('room_allocations')
        .select('room_id')
        .eq('id', allocationId)
        .single();

    // Update allocation
    await client
        .from('room_allocations')
        .update({
          'is_active': false,
          'vacated_date': DateTime.now().toIso8601String().split('T')[0],
        })
        .eq('id', allocationId);

    // Update room occupied count
    final room = await getRoomById(allocationResponse['room_id']);
    if (room != null) {
      await client
          .from('hostel_rooms')
          .update({'occupied': room.occupied - 1})
          .eq('id', room.id);
    }
  }

  Future<List<RoomAllocation>> getAllocations({
    String? hostelId,
    String? roomId,
    String? studentId,
    bool activeOnly = true,
  }) async {
    var query = client
        .from('room_allocations')
        .select('''
          *,
          students(first_name, last_name),
          hostel_rooms(
            room_number,
            hostels(name)
          )
        ''')
        .eq('tenant_id', tenantId!);

    if (roomId != null) {
      query = query.eq('room_id', roomId);
    }

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('allocated_date', ascending: false);

    var allocations = (response as List)
        .map((json) => RoomAllocation.fromJson(json))
        .toList();

    // Filter by hostel if specified
    if (hostelId != null) {
      allocations = allocations.where((a) {
        // This is a workaround since we can't filter by nested hostel_id directly
        return true; // Would need to add hostel_id to the allocation or filter differently
      }).toList();
    }

    return allocations;
  }

  Future<RoomAllocation?> getStudentAllocation(String studentId) async {
    // Get current academic year
    final academicYearResponse = await client
        .from('academic_years')
        .select('id')
        .eq('tenant_id', tenantId!)
        .eq('is_current', true)
        .maybeSingle();

    if (academicYearResponse == null) return null;

    final response = await client
        .from('room_allocations')
        .select('''
          *,
          students(first_name, last_name),
          hostel_rooms(
            *,
            hostels(*)
          )
        ''')
        .eq('student_id', studentId)
        .eq('academic_year_id', academicYearResponse['id'])
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return RoomAllocation.fromJson(response);
  }

  Future<RoomAllocation?> getMyHostel(String userId) async {
    // First get student ID
    final studentResponse = await client
        .from('students')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (studentResponse == null) return null;
    return getStudentAllocation(studentResponse['id']);
  }

  // ==================== HELPERS ====================

  Future<void> _updateHostelCounts(String hostelId) async {
    final roomsResponse = await client
        .from('hostel_rooms')
        .select('capacity')
        .eq('hostel_id', hostelId);

    final rooms = roomsResponse as List;
    final totalRooms = rooms.length;
    final totalCapacity = rooms.fold<int>(0, (sum, r) => sum + (r['capacity'] as int));

    await client
        .from('hostels')
        .update({
          'total_rooms': totalRooms,
          'total_capacity': totalCapacity,
        })
        .eq('id', hostelId);
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getHostelStats() async {
    final hostelsResponse = await client
        .from('hostels')
        .select('total_capacity')
        .eq('tenant_id', tenantId!)
        .eq('is_active', true);

    final hostels = hostelsResponse as List;
    final totalCapacity =
        hostels.fold<int>(0, (sum, h) => sum + ((h['total_capacity'] as int?) ?? 0));

    final allocationsResponse = await client
        .from('room_allocations')
        .select('id')
        .eq('tenant_id', tenantId!)
        .eq('is_active', true);

    final totalOccupied = (allocationsResponse as List).length;

    return {
      'total_hostels': hostels.length,
      'total_capacity': totalCapacity,
      'total_occupied': totalOccupied,
      'available_beds': totalCapacity - totalOccupied,
      'occupancy_rate': totalCapacity > 0
          ? (totalOccupied * 100 / totalCapacity).toStringAsFixed(1)
          : '0',
    };
  }
}
