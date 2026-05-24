import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/timetable.dart';
import '../../auth/providers/auth_provider.dart';
import '../../students/providers/students_provider.dart';
import '../../timetable/providers/timetable_provider.dart';
import 'attendance_provider.dart';

/// The class the teacher is about to (or currently in) — the target of the
/// dashboard "Mark all N present" CTA.
class NextClassTarget {
  final String sectionId;
  final String sectionLabel; // e.g. "10-A · Mathematics"
  final String? roomNumber;
  final String startTime; // HH:mm
  final String endTime;
  final bool isNow; // true when wall-clock is inside [start, end)
  final int? minutesUntilStart; // null if already started
  final List<RosterStudent> roster;

  const NextClassTarget({
    required this.sectionId,
    required this.sectionLabel,
    required this.roomNumber,
    required this.startTime,
    required this.endTime,
    required this.isNow,
    required this.minutesUntilStart,
    required this.roster,
  });
}

class RosterStudent {
  final String studentId;
  final String name;
  final String? rollNumber;
  final String? photoUrl;

  const RosterStudent({
    required this.studentId,
    required this.name,
    required this.rollNumber,
    required this.photoUrl,
  });
}

/// Resolves "what should I mark right now?" for a teacher.
///
/// Returns null when no teachable class remains today (weekend, holiday,
/// last bell rung, or no timetable published yet). Sheets should handle
/// the null by pointing the teacher to the full Mark Attendance picker.
final quickMarkTargetProvider =
    FutureProvider.autoDispose<NextClassTarget?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final today = DateTime.now();
  final filter = TeacherTimetableFilter(
    teacherId: user.id,
    dayOfWeek: today.weekday,
  );
  final slots = await ref.watch(teacherTimetableProvider(filter).future);
  if (slots.isEmpty) return null;

  final ranked = _rankBySlotStart(slots);
  final pick = _pickNextOrCurrent(ranked, today);
  if (pick == null) return null;

  final students = await ref.read(studentRepositoryProvider).getStudentsBySection(
        pick.sectionId,
        limit: 200,
      );

  final roster = students
      .map((s) => RosterStudent(
            studentId: s.id,
            name: s.fullName,
            rollNumber: s.rollNumber,
            photoUrl: s.photoUrl,
          ))
      .toList(growable: false);

  return NextClassTarget(
    sectionId: pick.sectionId,
    sectionLabel: _labelFor(pick),
    roomNumber: pick.roomNumber,
    startTime: pick.slot?.startTime ?? '',
    endTime: pick.slot?.endTime ?? '',
    isNow: _isWithin(pick, today),
    minutesUntilStart: _minutesUntil(pick, today),
    roster: roster,
  );
});

// ---- helpers ----

List<Timetable> _rankBySlotStart(List<Timetable> slots) {
  final list = [...slots];
  list.sort((a, b) {
    final aStart = a.slot?.startTime ?? '99:99';
    final bStart = b.slot?.startTime ?? '99:99';
    return aStart.compareTo(bStart);
  });
  return list;
}

Timetable? _pickNextOrCurrent(List<Timetable> ranked, DateTime now) {
  final nowMinutes = now.hour * 60 + now.minute;
  for (final t in ranked) {
    final end = t.slot?.endTime;
    if (end == null) continue;
    final endMinutes = _hhmmToMinutes(end);
    if (endMinutes == null) continue;
    if (endMinutes <= nowMinutes) continue; // class already done
    return t;
  }
  return null;
}

bool _isWithin(Timetable t, DateTime now) {
  final start = _hhmmToMinutes(t.slot?.startTime);
  final end = _hhmmToMinutes(t.slot?.endTime);
  if (start == null || end == null) return false;
  final m = now.hour * 60 + now.minute;
  return m >= start && m < end;
}

int? _minutesUntil(Timetable t, DateTime now) {
  final start = _hhmmToMinutes(t.slot?.startTime);
  if (start == null) return null;
  final m = now.hour * 60 + now.minute;
  if (start <= m) return null; // already started
  return start - m;
}

String _labelFor(Timetable t) {
  final section = t.sectionName ?? t.className ?? 'Section';
  final subject = t.subjectName;
  return subject != null ? '$section · $subject' : section;
}

int? _hhmmToMinutes(String? s) {
  if (s == null) return null;
  final parts = s.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// Side-effect helper used by [QuickMarkSheet]: persist a one-shot
/// roster of present/absent marks for [target] on today's date.
///
/// Returns true when the network sync succeeded, false when the write
/// was queued for offline sync.
Future<bool> persistQuickMark(
  WidgetRef ref, {
  required NextClassTarget target,
  required Set<String> absentStudentIds,
  String? absenceRemark,
}) async {
  final repo = ref.read(attendanceRepositoryProvider);
  final records = target.roster.map((s) {
    final isAbsent = absentStudentIds.contains(s.studentId);
    return <String, dynamic>{
      'student_id': s.studentId,
      'status': isAbsent ? 'absent' : 'present',
      'remarks': isAbsent ? absenceRemark : null,
    };
  }).toList(growable: false);

  return repo.markBulkAttendance(
    sectionId: target.sectionId,
    date: DateTime.now(),
    attendanceRecords: records,
  );
}
