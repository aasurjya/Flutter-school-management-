import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/offline_sync_service.dart';
import '../models/attendance.dart';
import 'base_repository.dart';

class AttendanceRepository extends BaseRepository {
  final OfflineSyncService? _syncService;

  AttendanceRepository(super.client, [this._syncService]) {
    // Wire sync callback so queued records get upserted on reconnect
    if (_syncService != null) {
      _syncService.onSync = (records) => _syncRecords(records);
    }
  }

  Future<void> _syncRecords(List<PendingAttendanceRecord> records) async {
    final upsertRecords = records
        .map((r) => {
              'tenant_id': tenantId,
              'student_id': r.studentId,
              'section_id': r.sectionId,
              'date': r.date,
              'status': r.status,
              'remarks': r.remarks,
              'marked_by': r.markedBy,
              'marked_at': r.markedAt,
            })
        .toList();

    await client.from('attendance').upsert(
      upsertRecords,
      onConflict: 'student_id,date',
    );
  }

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
        .eq('date', date.toIso8601String().split('T')[0])
        .limit(100);

    return (response as List)
        .map((json) => Attendance.fromJson(json))
        .toList();
  }

  Future<List<Attendance>> getStudentAttendance({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
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

    final response = await query.order('date', ascending: false).range(offset, offset + limit - 1);
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

    final response = await query.order('month', ascending: false).limit(100);
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

  Future<bool> markBulkAttendance({
    required String sectionId,
    required DateTime date,
    required List<Map<String, dynamic>> attendanceRecords,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final now = DateTime.now().toIso8601String();

    // If offline and sync service available, queue for later
    if (_syncService != null && !_syncService.isOnline) {
      final pending = attendanceRecords
          .map((record) => PendingAttendanceRecord(
                studentId: record['student_id'],
                sectionId: sectionId,
                date: dateStr,
                status: record['status'],
                remarks: record['remarks'],
                markedBy: currentUserId,
                markedAt: now,
              ))
          .toList();
      _syncService.enqueue(pending);
      return false; // false = saved offline
    }

    // Online path — direct upsert
    final records = attendanceRecords.map((record) => {
      'tenant_id': tenantId,
      'student_id': record['student_id'],
      'section_id': sectionId,
      'date': dateStr,
      'status': record['status'],
      'remarks': record['remarks'],
      'marked_by': currentUserId,
      'marked_at': now,
    }).toList();

    await client.from('attendance').upsert(
      records,
      onConflict: 'student_id,date',
    );
    return true; // true = saved online
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
        .eq('tenant_id', requireTenantId)
        .eq('date', today)
        .limit(100);

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
      filter: (column: 'section_id', value: sectionId),
      onInsert: onUpdate,
      onUpdate: onUpdate,
    );
  }
}
