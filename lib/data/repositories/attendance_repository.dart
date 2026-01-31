import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';
import 'base_repository.dart';

class AttendanceRepository extends BaseRepository {
  AttendanceRepository(super.client);

  Future<List<Attendance>> getAttendanceBySection({
    required String sectionId,
    required DateTime date,
  }) async {
    final response = await client
        .from('attendance')
        .select('''
          *,
          students!inner(
            id,
            first_name,
            last_name,
            admission_number,
            photo_url
          )
        ''')
        .eq('section_id', sectionId)
        .eq('date', date.toIso8601String().split('T')[0]);

    return (response as List)
        .map((json) => Attendance.fromJson(json))
        .toList();
  }

  Future<List<Attendance>> getStudentAttendance({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = client
        .from('attendance')
        .select('*')
        .eq('student_id', studentId);

    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('date', ascending: false);
    return (response as List)
        .map((json) => Attendance.fromJson(json))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAttendanceSummary({
    required String studentId,
    int? year,
  }) async {
    var query = client
        .from('v_attendance_summary')
        .select('*')
        .eq('student_id', studentId);

    if (year != null) {
      query = query.eq('year', year);
    }

    final response = await query.order('month', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getSectionDailyAttendance({
    required String sectionId,
    required DateTime date,
  }) async {
    final response = await client
        .from('v_section_daily_attendance')
        .select('*')
        .eq('section_id', sectionId)
        .eq('date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    return response;
  }

  Future<void> markAttendance({
    required String studentId,
    required String sectionId,
    required DateTime date,
    required String status,
    String? remarks,
  }) async {
    await client.from('attendance').upsert({
      'tenant_id': tenantId,
      'student_id': studentId,
      'section_id': sectionId,
      'date': date.toIso8601String().split('T')[0],
      'status': status,
      'remarks': remarks,
      'marked_by': currentUserId,
      'marked_at': DateTime.now().toIso8601String(),
    }, onConflict: 'student_id,date');
  }

  Future<void> markBulkAttendance({
    required String sectionId,
    required DateTime date,
    required List<Map<String, dynamic>> attendanceRecords,
  }) async {
    final records = attendanceRecords.map((record) => {
      'tenant_id': tenantId,
      'student_id': record['student_id'],
      'section_id': sectionId,
      'date': date.toIso8601String().split('T')[0],
      'status': record['status'],
      'remarks': record['remarks'],
      'marked_by': currentUserId,
      'marked_at': DateTime.now().toIso8601String(),
    }).toList();

    await client.from('attendance').upsert(
      records,
      onConflict: 'student_id,date',
    );
  }

  Future<void> updateAttendance({
    required String attendanceId,
    required String status,
    String? remarks,
  }) async {
    await client.from('attendance').update({
      'status': status,
      'remarks': remarks,
      'marked_by': currentUserId,
      'marked_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', attendanceId);
  }

  Future<Map<String, int>> getAttendanceStats({
    required String studentId,
    String? academicYearId,
  }) async {
    final summary = await getAttendanceSummary(studentId: studentId);
    
    int totalDays = 0;
    int presentDays = 0;
    int absentDays = 0;
    int lateDays = 0;
    
    for (final month in summary) {
      totalDays += (month['total_days'] as num).toInt();
      presentDays += (month['present_days'] as num).toInt();
      absentDays += (month['absent_days'] as num).toInt();
      lateDays += (month['late_days'] as num).toInt();
    }
    
    return {
      'total_days': totalDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'late_days': lateDays,
      'attendance_percentage': totalDays > 0 
          ? ((presentDays + lateDays) * 100 ~/ totalDays) 
          : 0,
    };
  }

  Future<double> getTodayAttendancePercentage() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final response = await client
        .from('v_section_daily_attendance')
        .select('attendance_percentage')
        .eq('tenant_id', tenantId!)
        .eq('date', today);

    if (response.isEmpty) return 0;
    
    final percentages = (response as List)
        .map((r) => (r['attendance_percentage'] as num?)?.toDouble() ?? 0)
        .toList();
    
    return percentages.reduce((a, b) => a + b) / percentages.length;
  }

  RealtimeChannel subscribeToSectionAttendance({
    required String sectionId,
    required DateTime date,
    required void Function(PostgresChangePayload) onUpdate,
  }) {
    return subscribeToTable(
      'attendance',
      filter: 'section_id=eq.$sectionId',
      onInsert: onUpdate,
      onUpdate: onUpdate,
    );
  }
}
