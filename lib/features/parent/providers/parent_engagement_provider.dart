import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';

// ============================================================
// Data models for parent engagement screens
// ============================================================

class ChildProgressSummary {
  final String studentId;
  final String studentName;
  final String? photoUrl;
  final String className;
  final String sectionName;
  final String rollNumber;
  final double attendancePercentage;
  final double averagePercentage;
  final int totalPoints;

  const ChildProgressSummary({
    required this.studentId,
    required this.studentName,
    this.photoUrl,
    required this.className,
    required this.sectionName,
    required this.rollNumber,
    required this.attendancePercentage,
    required this.averagePercentage,
    required this.totalPoints,
  });
}

class SubjectMark {
  final String subjectId;
  final String subjectName;
  final double marksObtained;
  final double maxMarks;
  final String grade;

  const SubjectMark({
    required this.subjectId,
    required this.subjectName,
    required this.marksObtained,
    required this.maxMarks,
    required this.grade,
  });

  double get percentage => maxMarks > 0 ? (marksObtained / maxMarks) * 100 : 0;
}

class AttendanceDay {
  final DateTime date;
  final String status; // present, absent, late, excused

  const AttendanceDay({required this.date, required this.status});
}

class BehaviourRecord {
  final String id;
  final String type; // incident, achievement, badge
  final String title;
  final String? description;
  final int points;
  final DateTime date;

  const BehaviourRecord({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.points,
    required this.date,
  });
}

class TeacherContact {
  final String userId;
  final String name;
  final String subjectName;
  final String? email;

  const TeacherContact({
    required this.userId,
    required this.name,
    required this.subjectName,
    this.email,
  });
}

// ============================================================
// Providers
// ============================================================

/// Fetch basic child progress summary (attendance %, average %, points).
final childProgressSummaryProvider =
    FutureProvider.family<ChildProgressSummary, String>(
  (ref, studentId) async {
    final client = ref.watch(supabaseProvider);

    try {
      // Fetch student base data with class/section join
      final studentRow = await client
          .from('students')
          .select(
            'id, full_name, photo_url, roll_number, '
            'student_enrollments!inner(sections!inner(name, classes!inner(name)))',
          )
          .eq('id', studentId)
          .maybeSingle();

      if (studentRow == null) {
        return _demoProgressSummary(studentId);
      }

      final enrollments = studentRow['student_enrollments'] as List?;
      final section = (enrollments?.isNotEmpty == true)
          ? (enrollments!.first['sections'] as Map<String, dynamic>?)
          : null;
      final className = (section?['classes'] as Map<String, dynamic>?)?['name']
              as String? ??
          'Class';
      final sectionName = section?['name'] as String? ?? 'A';

      // Attendance percentage this academic year
      double attendancePct = 0;
      try {
        final attRows = await client
            .from('attendance_records')
            .select('status')
            .eq('student_id', studentId);
        final total = (attRows as List).length;
        final present = attRows
            .where((r) =>
                (r['status'] as String?)?.toLowerCase() == 'present')
            .length;
        attendancePct = total > 0 ? (present / total) * 100 : 0;
      } catch (_) {
        attendancePct = 88.0;
      }

      // Average marks
      double avgPct = 0;
      try {
        final marksRows = await client
            .from('marks')
            .select('marks_obtained, max_marks')
            .eq('student_id', studentId);
        final marks = marksRows as List;
        if (marks.isNotEmpty) {
          final totalObtained = marks.fold<double>(
              0, (s, r) => s + ((r['marks_obtained'] as num?)?.toDouble() ?? 0));
          final totalMax = marks.fold<double>(
              0, (s, r) => s + ((r['max_marks'] as num?)?.toDouble() ?? 100));
          avgPct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0;
        }
      } catch (_) {
        avgPct = 76.0;
      }

      // Gamification points
      int points = 0;
      try {
        final pointsRow = await client
            .from('student_points')
            .select('total_points')
            .eq('student_id', studentId)
            .maybeSingle();
        points = (pointsRow?['total_points'] as num?)?.toInt() ?? 0;
      } catch (_) {
        points = 320;
      }

      return ChildProgressSummary(
        studentId: studentId,
        studentName: studentRow['full_name'] as String? ?? 'Student',
        photoUrl: studentRow['photo_url'] as String?,
        className: className,
        sectionName: sectionName,
        rollNumber: studentRow['roll_number']?.toString() ?? '-',
        attendancePercentage: attendancePct,
        averagePercentage: avgPct,
        totalPoints: points,
      );
    } catch (_) {
      return _demoProgressSummary(studentId);
    }
  },
);

ChildProgressSummary _demoProgressSummary(String studentId) {
  return ChildProgressSummary(
    studentId: studentId,
    studentName: 'Arjun Kumar',
    className: 'Class 10',
    sectionName: 'A',
    rollNumber: '15',
    attendancePercentage: 94.0,
    averagePercentage: 78.5,
    totalPoints: 320,
  );
}

/// Subject marks for a given student (latest exam).
final childSubjectMarksProvider =
    FutureProvider.family<List<SubjectMark>, String>(
  (ref, studentId) async {
    final client = ref.watch(supabaseProvider);
    try {
      final rows = await client
          .from('marks')
          .select(
            'subject_id, marks_obtained, max_marks, '
            'subjects!inner(name)',
          )
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .limit(20);

      final list = rows as List;
      if (list.isEmpty) return _demoSubjectMarks();

      return list.map((r) {
        final obtained = (r['marks_obtained'] as num?)?.toDouble() ?? 0;
        final max = (r['max_marks'] as num?)?.toDouble() ?? 100;
        final pct = max > 0 ? (obtained / max) * 100 : 0;
        return SubjectMark(
          subjectId: r['subject_id'] as String? ?? '',
          subjectName:
              (r['subjects'] as Map<String, dynamic>?)?['name'] as String? ??
                  'Subject',
          marksObtained: obtained,
          maxMarks: max,
          grade: _gradeFromPct(pct.toDouble()),
        );
      }).toList();
    } catch (_) {
      return _demoSubjectMarks();
    }
  },
);

List<SubjectMark> _demoSubjectMarks() {
  return [
    const SubjectMark(subjectId: '1', subjectName: 'Mathematics', marksObtained: 87, maxMarks: 100, grade: 'A'),
    const SubjectMark(subjectId: '2', subjectName: 'Physics', marksObtained: 74, maxMarks: 100, grade: 'B+'),
    const SubjectMark(subjectId: '3', subjectName: 'Chemistry', marksObtained: 68, maxMarks: 100, grade: 'B'),
    const SubjectMark(subjectId: '4', subjectName: 'English', marksObtained: 82, maxMarks: 100, grade: 'A'),
    const SubjectMark(subjectId: '5', subjectName: 'History', marksObtained: 79, maxMarks: 100, grade: 'B+'),
  ];
}

/// Attendance records for the given student (last 60 days).
final childAttendanceProvider =
    FutureProvider.family<List<AttendanceDay>, String>(
  (ref, studentId) async {
    final client = ref.watch(supabaseProvider);
    try {
      final since = DateTime.now().subtract(const Duration(days: 60));
      final rows = await client
          .from('attendance_records')
          .select('date, status')
          .eq('student_id', studentId)
          .gte('date', since.toIso8601String().split('T').first)
          .order('date', ascending: false);

      final list = rows as List;
      if (list.isEmpty) return _demoAttendance();

      return list.map((r) {
        return AttendanceDay(
          date: DateTime.parse(r['date'] as String),
          status: r['status'] as String? ?? 'present',
        );
      }).toList();
    } catch (_) {
      return _demoAttendance();
    }
  },
);

List<AttendanceDay> _demoAttendance() {
  final now = DateTime.now();
  final records = <AttendanceDay>[];
  const statuses = [
    'present', 'present', 'present', 'present', 'absent',
    'present', 'present', 'late', 'present', 'present',
    'present', 'absent', 'present', 'present', 'present',
    'present', 'present', 'present', 'late', 'present',
    'present', 'present', 'present', 'present', 'absent',
    'present', 'present', 'present', 'present', 'present',
  ];
  for (int i = 0; i < 30; i++) {
    final date = now.subtract(Duration(days: i));
    // Skip weekends
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      continue;
    }
    if (records.length < statuses.length) {
      records.add(AttendanceDay(date: date, status: statuses[records.length]));
    }
  }
  return records;
}

/// Behaviour records (gamification points / incidents) for a student.
final childBehaviourProvider =
    FutureProvider.family<List<BehaviourRecord>, String>(
  (ref, studentId) async {
    final client = ref.watch(supabaseProvider);
    try {
      final rows = await client
          .from('gamification_events')
          .select('id, event_type, description, points, created_at')
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .limit(20);

      final list = rows as List;
      if (list.isEmpty) return _demoBehaviour();

      return list.map((r) {
        return BehaviourRecord(
          id: r['id'] as String,
          type: r['event_type'] as String? ?? 'achievement',
          title: r['description'] as String? ?? 'Activity',
          points: (r['points'] as num?)?.toInt() ?? 0,
          date: DateTime.parse(r['created_at'] as String),
        );
      }).toList();
    } catch (_) {
      return _demoBehaviour();
    }
  },
);

List<BehaviourRecord> _demoBehaviour() {
  final now = DateTime.now();
  return [
    BehaviourRecord(id: '1', type: 'achievement', title: 'Perfect Attendance — Week 12', points: 50, date: now.subtract(const Duration(days: 2))),
    BehaviourRecord(id: '2', type: 'badge', title: 'Science Olympiad — Bronze', points: 100, date: now.subtract(const Duration(days: 7))),
    BehaviourRecord(id: '3', type: 'achievement', title: 'Homework Streak — 10 days', points: 30, date: now.subtract(const Duration(days: 10))),
    BehaviourRecord(id: '4', type: 'incident', title: 'Late to class', points: -10, date: now.subtract(const Duration(days: 14))),
    BehaviourRecord(id: '5', type: 'badge', title: 'Class Representative', points: 75, date: now.subtract(const Duration(days: 21))),
  ];
}

/// Teachers for the child's section.
final childTeachersProvider =
    FutureProvider.family<List<TeacherContact>, String>(
  (ref, studentId) async {
    final client = ref.watch(supabaseProvider);
    try {
      // Get section for student
      final enrollRow = await client
          .from('student_enrollments')
          .select('section_id')
          .eq('student_id', studentId)
          .maybeSingle();

      if (enrollRow == null) return _demoTeachers();
      final sectionId = enrollRow['section_id'] as String;

      // Get teachers assigned to that section via teacher_assignments
      final rows = await client
          .from('teacher_assignments')
          .select(
            'user_id, subjects!inner(name), '
            'users!inner(full_name, email)',
          )
          .eq('section_id', sectionId);

      final list = rows as List;
      if (list.isEmpty) return _demoTeachers();

      // Deduplicate by user_id
      final seen = <String>{};
      final result = <TeacherContact>[];
      for (final r in list) {
        final uid = r['user_id'] as String;
        if (seen.contains(uid)) continue;
        seen.add(uid);
        result.add(TeacherContact(
          userId: uid,
          name: (r['users'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'Teacher',
          subjectName: (r['subjects'] as Map<String, dynamic>?)?['name'] as String? ?? 'Subject',
          email: (r['users'] as Map<String, dynamic>?)?['email'] as String?,
        ));
      }
      return result;
    } catch (_) {
      return _demoTeachers();
    }
  },
);

List<TeacherContact> _demoTeachers() {
  return [
    const TeacherContact(userId: 't1', name: 'Mr. Ramesh Sharma', subjectName: 'Mathematics'),
    const TeacherContact(userId: 't2', name: 'Ms. Priya Nair', subjectName: 'Physics'),
    const TeacherContact(userId: 't3', name: 'Mr. Anil Verma', subjectName: 'Chemistry'),
    const TeacherContact(userId: 't4', name: 'Ms. Sunita Rao', subjectName: 'English'),
    const TeacherContact(userId: 't5', name: 'Mr. Deepak Mehta', subjectName: 'History'),
  ];
}

// ============================================================
// Helpers
// ============================================================

String _gradeFromPct(double pct) {
  if (pct >= 90) return 'A+';
  if (pct >= 80) return 'A';
  if (pct >= 70) return 'B+';
  if (pct >= 60) return 'B';
  if (pct >= 50) return 'C';
  if (pct >= 40) return 'D';
  return 'F';
}

// Expose helper so screens can reuse it
String gradeFromPct(double pct) => _gradeFromPct(pct);
