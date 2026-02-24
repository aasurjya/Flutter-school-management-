import '../models/substitution.dart';
import 'base_repository.dart';

class SubstitutionRepository extends BaseRepository {
  SubstitutionRepository(super.client);

  // ==================== TEACHER ABSENCES ====================

  /// Returns all absences for a given date (admin: all teachers).
  Future<List<TeacherAbsence>> getAbsencesByDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await client
        .from('teacher_absences')
        .select('*, teacher:users!teacher_id(full_name)')
        .eq('tenant_id', requireTenantId)
        .eq('absence_date', dateStr)
        .order('created_at');

    return (response as List)
        .map((j) => TeacherAbsence.fromJson(j))
        .toList();
  }

  /// Returns absences reported by a specific teacher.
  Future<List<TeacherAbsence>> getMyAbsences(String teacherId,
      {int limit = 20}) async {
    final response = await client
        .from('teacher_absences')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .eq('teacher_id', teacherId)
        .order('absence_date', ascending: false)
        .limit(limit);

    return (response as List)
        .map((j) => TeacherAbsence.fromJson(j))
        .toList();
  }

  /// Report a teacher absence (upsert — same teacher+date is idempotent).
  Future<TeacherAbsence> reportAbsence({
    required String teacherId,
    required DateTime date,
    required AbsenceLeaveType leaveType,
    String? reason,
    String? notes,
  }) async {
    final data = {
      'tenant_id': requireTenantId,
      'teacher_id': teacherId,
      'absence_date': date.toIso8601String().split('T')[0],
      'leave_type': leaveType.dbValue,
      'reason': reason,
      'notes': notes,
      'status': 'confirmed',
      'reported_by': client.auth.currentUser?.id,
    };

    final response = await client
        .from('teacher_absences')
        .upsert(data, onConflict: 'tenant_id,teacher_id,absence_date')
        .select()
        .single();

    return TeacherAbsence.fromJson(response);
  }

  /// Cancel / update absence status.
  Future<void> updateAbsenceStatus(
      String absenceId, AbsenceStatus status) async {
    await client
        .from('teacher_absences')
        .update({'status': status.dbValue})
        .eq('id', absenceId)
        .eq('tenant_id', requireTenantId);
  }

  // ==================== SUGGESTIONS ====================

  /// Calls the suggest_substitutes() SQL function and groups results by period.
  Future<List<SubstitutePeriod>> getSuggestedSubstitutes({
    required String absentTeacherId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await client.rpc('suggest_substitutes', params: {
      'p_tenant_id': requireTenantId,
      'p_absent_teacher_id': absentTeacherId,
      'p_date': dateStr,
    });

    final rows = (response as List).cast<Map<String, dynamic>>();

    // Group rows by timetable_id (one SubstitutePeriod per period)
    final Map<String, SubstitutePeriod> periods = {};
    for (final row in rows) {
      final tid = row['timetable_id'] as String;
      if (!periods.containsKey(tid)) {
        periods[tid] = SubstitutePeriod(
          timetableId: tid,
          slotId: row['slot_id'] as String,
          slotName: row['slot_name'] as String? ?? '',
          startTime: row['start_time'] as String? ?? '',
          endTime: row['end_time'] as String? ?? '',
          sectionId: row['section_id'] as String,
          sectionName: row['section_name'] as String? ?? '',
          className: row['class_name'] as String? ?? '',
          subjectId: row['subject_id'] as String?,
          subjectName: row['subject_name'] as String?,
          candidates: [],
        );
      }
      if (row['candidate_teacher_id'] != null) {
        periods[tid]!.candidates.add(SubstituteCandidate.fromJson(row));
      }
    }

    // Sort candidates by rank within each period
    for (final period in periods.values) {
      period.candidates.sort((a, b) => a.rank.compareTo(b.rank));
    }

    return periods.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // ==================== ASSIGNMENTS ====================

  /// Assign a substitute for a period.
  Future<SubstitutionAssignment> assignSubstitute({
    required String absenceId,
    required String timetableId,
    required String absentTeacherId,
    required String substituteTeacherId,
    required String slotId,
    required String sectionId,
    String? subjectId,
    required DateTime date,
    int matchScore = 0,
    String? notes,
  }) async {
    final response = await client
        .from('substitution_assignments')
        .upsert({
          'tenant_id': requireTenantId,
          'absence_id': absenceId,
          'timetable_id': timetableId,
          'absent_teacher_id': absentTeacherId,
          'substitute_teacher_id': substituteTeacherId,
          'slot_id': slotId,
          'section_id': sectionId,
          'subject_id': subjectId,
          'substitution_date': date.toIso8601String().split('T')[0],
          'match_score': matchScore,
          'notes': notes,
          'status': 'confirmed',
          'assigned_by': client.auth.currentUser?.id,
        }, onConflict: 'tenant_id,timetable_id,substitution_date')
        .select()
        .single();

    return SubstitutionAssignment.fromJson(response);
  }

  /// Get all assignments for a given date (admin overview).
  Future<List<SubstitutionAssignment>> getAssignmentsByDate(
      DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await client
        .from('substitution_assignments')
        .select('''
          *,
          timetable_slots!slot_id(name, start_time, end_time),
          sections!section_id(name, classes(name)),
          subjects!subject_id(name),
          absent_teacher:users!absent_teacher_id(full_name),
          substitute_teacher:users!substitute_teacher_id(full_name)
        ''')
        .eq('tenant_id', requireTenantId)
        .eq('substitution_date', dateStr)
        .eq('status', 'confirmed')
        .order('created_at');

    return (response as List)
        .map((j) => SubstitutionAssignment.fromJson(j))
        .toList();
  }

  /// Get substitute duties assigned to a specific teacher.
  Future<List<SubstitutionAssignment>> getMySubstituteDuties(
      String teacherId,
      {int limit = 20}) async {
    final response = await client
        .from('substitution_assignments')
        .select('''
          *,
          timetable_slots!slot_id(name, start_time, end_time),
          sections!section_id(name, classes(name)),
          subjects!subject_id(name),
          absent_teacher:users!absent_teacher_id(full_name)
        ''')
        .eq('tenant_id', requireTenantId)
        .eq('substitute_teacher_id', teacherId)
        .eq('status', 'confirmed')
        .gte('substitution_date',
            DateTime.now().subtract(const Duration(days: 7))
                .toIso8601String().split('T')[0])
        .order('substitution_date', ascending: false)
        .limit(limit);

    return (response as List)
        .map((j) => SubstitutionAssignment.fromJson(j))
        .toList();
  }

  /// Cancel an assignment.
  Future<void> cancelAssignment(String assignmentId) async {
    await client
        .from('substitution_assignments')
        .update({'status': 'cancelled'})
        .eq('id', assignmentId)
        .eq('tenant_id', requireTenantId);
  }
}
