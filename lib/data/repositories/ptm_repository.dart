import '../models/ptm.dart';
import 'base_repository.dart';

class PTMRepository extends BaseRepository {
  PTMRepository(super.client);

  // ==================== PTM SCHEDULES ====================

  Future<List<PTMSchedule>> getPTMSchedules({
    String? status,
    bool upcomingOnly = false,
  }) async {
    var query = client
        .from('ptm_schedules')
        .select('''
          *,
          academic_year:academic_years(name)
        ''')
        .eq('tenant_id', tenantId!);

    if (status != null) {
      query = query.eq('status', status);
    }

    if (upcomingOnly) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      query = query.gte('date', today);
    }

    final response = await query.order('date', ascending: false);
    return (response as List).map((json) => PTMSchedule.fromJson(json)).toList();
  }

  Future<PTMSchedule?> getPTMScheduleById(String scheduleId) async {
    final response = await client
        .from('ptm_schedules')
        .select('''
          *,
          academic_year:academic_years(name)
        ''')
        .eq('id', scheduleId)
        .maybeSingle();

    if (response == null) return null;
    return PTMSchedule.fromJson(response);
  }

  Future<PTMSchedule> createPTMSchedule(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['status'] = 'draft';

    final response =
        await client.from('ptm_schedules').insert(data).select().single();
    return PTMSchedule.fromJson(response);
  }

  Future<PTMSchedule> updatePTMSchedule(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    final response = await client
        .from('ptm_schedules')
        .update(data)
        .eq('id', scheduleId)
        .select()
        .single();
    return PTMSchedule.fromJson(response);
  }

  Future<void> openPTMSchedule(String scheduleId) async {
    await client
        .from('ptm_schedules')
        .update({'status': 'open'}).eq('id', scheduleId);
  }

  Future<void> closePTMSchedule(String scheduleId) async {
    await client
        .from('ptm_schedules')
        .update({'status': 'closed'}).eq('id', scheduleId);
  }

  Future<void> deletePTMSchedule(String scheduleId) async {
    // Delete appointments first
    await client
        .from('ptm_appointments')
        .delete()
        .eq('ptm_schedule_id', scheduleId);
    // Delete teacher availability
    await client
        .from('ptm_teacher_availability')
        .delete()
        .eq('ptm_schedule_id', scheduleId);
    // Delete schedule
    await client.from('ptm_schedules').delete().eq('id', scheduleId);
  }

  // ==================== TEACHER AVAILABILITY ====================

  Future<List<TeacherAvailability>> getTeacherAvailability(
    String scheduleId,
  ) async {
    final response = await client
        .from('ptm_teacher_availability')
        .select('''
          *,
          teacher:users(full_name)
        ''')
        .eq('ptm_schedule_id', scheduleId)
        .order('room_number');

    return (response as List)
        .map((json) => TeacherAvailability.fromJson(json))
        .toList();
  }

  Future<TeacherAvailability?> getTeacherAvailabilityById(String id) async {
    final response = await client
        .from('ptm_teacher_availability')
        .select('''
          *,
          teacher:users(full_name)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return TeacherAvailability.fromJson(response);
  }

  Future<void> setTeacherAvailability({
    required String scheduleId,
    required String teacherId,
    required String roomNumber,
    bool isAvailable = true,
    String? notes,
  }) async {
    // Check if already exists
    final existing = await client
        .from('ptm_teacher_availability')
        .select('id')
        .eq('ptm_schedule_id', scheduleId)
        .eq('teacher_id', teacherId)
        .maybeSingle();

    if (existing != null) {
      await client.from('ptm_teacher_availability').update({
        'room_number': roomNumber,
        'is_available': isAvailable,
        'notes': notes,
      }).eq('id', existing['id']);
    } else {
      await client.from('ptm_teacher_availability').insert({
        'ptm_schedule_id': scheduleId,
        'teacher_id': teacherId,
        'room_number': roomNumber,
        'is_available': isAvailable,
        'notes': notes,
      });
    }
  }

  Future<void> removeTeacherAvailability(String availabilityId) async {
    // Cancel any appointments first
    await client
        .from('ptm_appointments')
        .update({'status': 'cancelled'}).eq(
            'teacher_availability_id', availabilityId);
    // Remove availability
    await client
        .from('ptm_teacher_availability')
        .delete()
        .eq('id', availabilityId);
  }

  // ==================== APPOINTMENTS ====================

  Future<List<PTMAppointment>> getAppointments({
    String? scheduleId,
    String? teacherAvailabilityId,
    String? parentId,
    String? studentId,
    String? status,
  }) async {
    var query = client
        .from('ptm_appointments')
        .select('''
          *,
          teacher_availability:ptm_teacher_availability(
            room_number,
            teacher:users(full_name)
          ),
          parent:parents(first_name, last_name),
          student:students(first_name, last_name)
        ''')
        .eq('tenant_id', tenantId!);

    if (scheduleId != null) {
      query = query.eq('ptm_schedule_id', scheduleId);
    }
    if (teacherAvailabilityId != null) {
      query = query.eq('teacher_availability_id', teacherAvailabilityId);
    }
    if (parentId != null) {
      query = query.eq('parent_id', parentId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('time_slot');
    return (response as List)
        .map((json) => PTMAppointment.fromJson(json))
        .toList();
  }

  Future<PTMAppointment?> getAppointmentById(String appointmentId) async {
    final response = await client
        .from('ptm_appointments')
        .select('''
          *,
          teacher_availability:ptm_teacher_availability(
            room_number,
            teacher:users(full_name)
          ),
          parent:parents(first_name, last_name),
          student:students(first_name, last_name)
        ''')
        .eq('id', appointmentId)
        .maybeSingle();

    if (response == null) return null;
    return PTMAppointment.fromJson(response);
  }

  Future<List<String>> getBookedSlots(
    String scheduleId,
    String teacherAvailabilityId,
  ) async {
    final response = await client
        .from('ptm_appointments')
        .select('time_slot')
        .eq('ptm_schedule_id', scheduleId)
        .eq('teacher_availability_id', teacherAvailabilityId)
        .neq('status', 'cancelled');

    return (response as List)
        .map((json) => json['time_slot'] as String)
        .toList();
  }

  Future<PTMAppointment> bookAppointment({
    required String scheduleId,
    required String teacherAvailabilityId,
    required String parentId,
    required String studentId,
    required String timeSlot,
    String? notes,
  }) async {
    // Check if slot is available
    final bookedSlots = await getBookedSlots(scheduleId, teacherAvailabilityId);
    if (bookedSlots.contains(timeSlot)) {
      throw Exception('This time slot is already booked');
    }

    // Check if parent already has appointment at this time
    final existingAppointments = await getAppointments(
      scheduleId: scheduleId,
      parentId: parentId,
    );

    final hasConflict = existingAppointments.any(
      (a) => a.timeSlot == timeSlot && !a.isCancelled,
    );

    if (hasConflict) {
      throw Exception('You already have an appointment at this time');
    }

    final response = await client
        .from('ptm_appointments')
        .insert({
          'tenant_id': tenantId,
          'ptm_schedule_id': scheduleId,
          'teacher_availability_id': teacherAvailabilityId,
          'parent_id': parentId,
          'student_id': studentId,
          'time_slot': timeSlot,
          'status': 'pending',
          'parent_notes': notes,
        })
        .select()
        .single();

    return PTMAppointment.fromJson(response);
  }

  Future<void> confirmAppointment(String appointmentId) async {
    await client
        .from('ptm_appointments')
        .update({'status': 'confirmed'}).eq('id', appointmentId);
  }

  Future<void> cancelAppointment(String appointmentId, {String? reason}) async {
    await client.from('ptm_appointments').update({
      'status': 'cancelled',
      'notes': reason,
    }).eq('id', appointmentId);
  }

  Future<void> completeAppointment(
    String appointmentId, {
    String? teacherNotes,
  }) async {
    await client.from('ptm_appointments').update({
      'status': 'completed',
      'teacher_notes': teacherNotes,
    }).eq('id', appointmentId);
  }

  Future<void> updateAppointmentNotes(
    String appointmentId, {
    String? parentNotes,
    String? teacherNotes,
  }) async {
    final data = <String, dynamic>{};
    if (parentNotes != null) data['parent_notes'] = parentNotes;
    if (teacherNotes != null) data['teacher_notes'] = teacherNotes;

    if (data.isNotEmpty) {
      await client.from('ptm_appointments').update(data).eq('id', appointmentId);
    }
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getPTMStatistics(String scheduleId) async {
    final appointments = await getAppointments(scheduleId: scheduleId);

    final confirmed =
        appointments.where((a) => a.status == 'confirmed').length;
    final pending = appointments.where((a) => a.status == 'pending').length;
    final cancelled =
        appointments.where((a) => a.status == 'cancelled').length;
    final completed =
        appointments.where((a) => a.status == 'completed').length;

    final teachers = await getTeacherAvailability(scheduleId);
    final availableTeachers = teachers.where((t) => t.isAvailable).length;

    return {
      'total_appointments': appointments.length,
      'confirmed': confirmed,
      'pending': pending,
      'cancelled': cancelled,
      'completed': completed,
      'total_teachers': teachers.length,
      'available_teachers': availableTeachers,
    };
  }

  // ==================== PARENT HELPERS ====================

  Future<List<TeacherAvailability>> getTeachersForParent(
    String scheduleId,
    String parentId,
  ) async {
    // Get parent's children
    final childrenResponse = await client
        .from('student_parents')
        .select('student_id')
        .eq('parent_id', parentId);

    if ((childrenResponse as List).isEmpty) return [];

    final childIds = childrenResponse.map((c) => c['student_id'] as String).toList();

    // Get children's section IDs
    final enrollmentResponse = await client
        .from('student_enrollments')
        .select('section_id')
        .inFilter('student_id', childIds)
        .eq('status', 'active');

    if ((enrollmentResponse as List).isEmpty) return [];

    final sectionIds =
        enrollmentResponse.map((e) => e['section_id'] as String).toSet().toList();

    // Get teachers assigned to these sections
    final teacherAssignments = await client
        .from('teacher_assignments')
        .select('teacher_id')
        .inFilter('section_id', sectionIds);

    if ((teacherAssignments as List).isEmpty) return [];

    final teacherIds =
        teacherAssignments.map((t) => t['teacher_id'] as String).toSet().toList();

    // Get availability for these teachers
    final availabilityResponse = await client
        .from('ptm_teacher_availability')
        .select('''
          *,
          teacher:users(full_name)
        ''')
        .eq('ptm_schedule_id', scheduleId)
        .inFilter('teacher_id', teacherIds)
        .eq('is_available', true);

    return (availabilityResponse as List)
        .map((json) => TeacherAvailability.fromJson(json))
        .toList();
  }
}
