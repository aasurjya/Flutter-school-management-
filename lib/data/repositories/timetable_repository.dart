import '../models/timetable.dart';
import 'base_repository.dart';

class TimetableRepository extends BaseRepository {
  TimetableRepository(super.client);

  // Supabase returns snake_case columns, but the Freezed models' generated
  // fromJson expects camelCase keys — and Timetable's joined fields
  // (subject/teacher/section names) live in nested objects the generated
  // parser can't read. So map rows manually here, null-safe throughout.

  TimetableSlot _slotFromRow(Map<String, dynamic> j) => TimetableSlot(
        id: (j['id'] as String?) ?? '',
        tenantId: (j['tenant_id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        startTime: (j['start_time'] as String?) ?? '',
        endTime: (j['end_time'] as String?) ?? '',
        slotType: (j['slot_type'] as String?) ?? 'class',
        sequenceOrder: (j['sequence_order'] as num?)?.toInt() ?? 0,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  Timetable _timetableFromRow(Map<String, dynamic> j) {
    final subject = j['subjects'] as Map<String, dynamic>?;
    final teacher = j['users'] as Map<String, dynamic>?;
    final section = j['sections'] as Map<String, dynamic>?;
    final cls = section?['classes'] as Map<String, dynamic>?;
    final slotJson = j['timetable_slots'] as Map<String, dynamic>?;
    return Timetable(
      id: (j['id'] as String?) ?? '',
      tenantId: (j['tenant_id'] as String?) ?? '',
      sectionId: (j['section_id'] as String?) ?? '',
      subjectId: j['subject_id'] as String?,
      teacherId: j['teacher_id'] as String?,
      slotId: (j['slot_id'] as String?) ?? '',
      dayOfWeek: (j['day_of_week'] as num?)?.toInt() ?? 0,
      roomNumber: j['room_number'] as String?,
      academicYearId: (j['academic_year_id'] as String?) ?? '',
      effectiveFrom: j['effective_from'] != null
          ? DateTime.tryParse(j['effective_from'] as String)
          : null,
      effectiveUntil: j['effective_until'] != null
          ? DateTime.tryParse(j['effective_until'] as String)
          : null,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'] as String)
          : null,
      slot: slotJson != null ? _slotFromRow(slotJson) : null,
      subjectName: subject?['name'] as String?,
      subjectCode: subject?['code'] as String?,
      teacherName: teacher?['full_name'] as String?,
      sectionName: section?['name'] as String?,
      className: cls?['name'] as String?,
    );
  }

  Future<List<TimetableSlot>> getTimetableSlots() async {
    final response = await client
        .from('timetable_slots')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .order('sequence_order');

    return (response as List)
        .map((json) => _slotFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<TimetableSlot> createTimetableSlot(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('timetable_slots')
        .insert(data)
        .select()
        .single();

    return _slotFromRow(response);
  }

  Future<List<Timetable>> getTimetables({
    required String sectionId,
    String? academicYearId,
    int? dayOfWeek,
  }) async {
    var query = client
        .from('timetables')
        .select('''
          *,
          timetable_slots(*),
          subjects(id, name, code),
          users!teacher_id(id, full_name),
          sections(id, name, classes(id, name))
        ''')
        .eq('section_id', sectionId);

    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }
    if (dayOfWeek != null) {
      query = query.eq('day_of_week', dayOfWeek);
    }

    final response = await query.order('day_of_week').order('timetable_slots(sequence_order)');
    return (response as List)
        .map((json) => _timetableFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<WeeklyTimetable> getWeeklyTimetable({
    required String sectionId,
    String? academicYearId,
  }) async {
    final slots = await getTimetableSlots();
    final timetables = await getTimetables(
      sectionId: sectionId,
      academicYearId: academicYearId,
    );

    final sectionInfo = await client
        .from('sections')
        .select('id, name, classes(id, name)')
        .eq('id', sectionId)
        .single();

    final days = <DayTimetable>[];
    const dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (int day = 1; day <= 7; day++) {
      final dayTimetables = timetables.where((t) => t.dayOfWeek == day).toList();
      final entries = <TimetableEntry>[];

      for (final slot in slots) {
        final timetable = dayTimetables.firstWhere(
          (t) => t.slotId == slot.id,
          orElse: () => Timetable(
            id: '',
            tenantId: requireTenantId,
            sectionId: sectionId,
            slotId: slot.id,
            dayOfWeek: day,
            academicYearId: academicYearId ?? '',
          ),
        );

        entries.add(TimetableEntry(
          slotId: slot.id,
          slotName: slot.name,
          startTime: slot.startTime,
          endTime: slot.endTime,
          slotType: slot.slotType,
          subjectId: timetable.subjectId,
          subjectName: timetable.subjectName,
          subjectCode: timetable.subjectCode,
          teacherId: timetable.teacherId,
          teacherName: timetable.teacherName,
          roomNumber: timetable.roomNumber,
          sequenceOrder: slot.sequenceOrder,
        ));
      }

      days.add(DayTimetable(
        dayOfWeek: day,
        dayName: dayNames[day],
        entries: entries,
      ));
    }

    return WeeklyTimetable(
      sectionId: sectionId,
      sectionName: (sectionInfo['name'] as String?) ?? '',
      className:
          ((sectionInfo['classes'] as Map<String, dynamic>?)?['name'] as String?) ?? '',
      academicYearId: academicYearId ?? '',
      days: days,
    );
  }

  Future<List<TimetableEntry>> getTodayTimetable({
    required String sectionId,
    String? academicYearId,
  }) async {
    final today = DateTime.now().weekday;
    final slots = await getTimetableSlots();
    final timetables = await getTimetables(
      sectionId: sectionId,
      academicYearId: academicYearId,
      dayOfWeek: today,
    );

    final entries = <TimetableEntry>[];

    for (final slot in slots) {
      final timetable = timetables.firstWhere(
        (t) => t.slotId == slot.id,
        orElse: () => Timetable(
          id: '',
          tenantId: requireTenantId,
          sectionId: sectionId,
          slotId: slot.id,
          dayOfWeek: today,
          academicYearId: academicYearId ?? '',
        ),
      );

      if (timetable.subjectId != null) {
        entries.add(TimetableEntry(
          slotId: slot.id,
          slotName: slot.name,
          startTime: slot.startTime,
          endTime: slot.endTime,
          slotType: slot.slotType,
          subjectId: timetable.subjectId,
          subjectName: timetable.subjectName,
          subjectCode: timetable.subjectCode,
          teacherId: timetable.teacherId,
          teacherName: timetable.teacherName,
          roomNumber: timetable.roomNumber,
          sequenceOrder: slot.sequenceOrder,
        ));
      }
    }

    return entries;
  }

  Future<List<Timetable>> getTeacherTimetable({
    required String teacherId,
    String? academicYearId,
    int? dayOfWeek,
  }) async {
    var query = client
        .from('timetables')
        .select('''
          *,
          timetable_slots(*),
          subjects(id, name, code),
          sections(id, name, classes(id, name))
        ''')
        .eq('teacher_id', teacherId);

    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }
    if (dayOfWeek != null) {
      query = query.eq('day_of_week', dayOfWeek);
    }

    final response = await query.order('day_of_week').order('timetable_slots(sequence_order)');
    return (response as List)
        .map((json) => _timetableFromRow(json as Map<String, dynamic>))
        .toList();
  }

  Future<Timetable> createTimetableEntry(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('timetables')
        .insert(data)
        .select()
        .single();

    return _timetableFromRow(response);
  }

  Future<Timetable> updateTimetableEntry(
    String timetableId,
    Map<String, dynamic> data,
  ) async {
    final response = await client
        .from('timetables')
        .update(data)
        .eq('id', timetableId)
        .select()
        .single();

    return _timetableFromRow(response);
  }

  Future<void> deleteTimetableEntry(String timetableId) async {
    await client.from('timetables').delete().eq('id', timetableId);
  }

  Future<void> copyTimetable({
    required String fromSectionId,
    required String toSectionId,
    required String academicYearId,
  }) async {
    final sourceTimetables = await getTimetables(
      sectionId: fromSectionId,
      academicYearId: academicYearId,
    );

    final newTimetables = sourceTimetables.map((t) => {
      'tenant_id': tenantId,
      'section_id': toSectionId,
      'subject_id': t.subjectId,
      'teacher_id': t.teacherId,
      'slot_id': t.slotId,
      'day_of_week': t.dayOfWeek,
      'room_number': t.roomNumber,
      'academic_year_id': academicYearId,
    }).toList();

    await client.from('timetables').insert(newTimetables);
  }

  /// Get unique sections assigned to a teacher (for My Classes screen)
  Future<List<TeacherClassInfo>> getTeacherClasses(String teacherId) async {
    final response = await client
        .from('timetables')
        .select('''
          section_id,
          subject_id,
          sections!inner(id, name, classes(id, name)),
          subjects(id, name, code)
        ''')
        .eq('teacher_id', teacherId)
        .eq('tenant_id', requireTenantId);

    // Group by section and subject to get unique class-subject combinations
    final Map<String, TeacherClassInfo> classMap = {};
    
    for (final item in response as List) {
      final sectionId = item['section_id'] as String;
      final subjectId = item['subject_id'] as String?;
      final key = '$sectionId-${subjectId ?? 'none'}';
      
      if (!classMap.containsKey(key)) {
        final section = item['sections'];
        final subject = item['subjects'];
        
        classMap[key] = TeacherClassInfo(
          sectionId: sectionId,
          sectionName: section['name'] as String,
          className: section['classes']['name'] as String,
          subjectId: subjectId,
          subjectName: subject?['name'] as String?,
          subjectCode: subject?['code'] as String?,
        );
      }
    }
    
    return classMap.values.toList();
  }
}

/// Teacher's class info model
class TeacherClassInfo {
  final String sectionId;
  final String sectionName;
  final String className;
  final String? subjectId;
  final String? subjectName;
  final String? subjectCode;

  TeacherClassInfo({
    required this.sectionId,
    required this.sectionName,
    required this.className,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
  });
}
