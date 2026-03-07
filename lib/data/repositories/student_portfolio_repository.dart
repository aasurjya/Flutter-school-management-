import '../models/student_portfolio.dart';
import 'base_repository.dart';

class StudentPortfolioRepository extends BaseRepository {
  StudentPortfolioRepository(super.client);

  // ============================================================
  // PORTFOLIO SUMMARY
  // ============================================================

  Future<PortfolioSummary> getPortfolioSummary(String studentId) async {
    // Fetch student basic info
    final studentResponse = await client
        .from('students')
        .select('''
          id, full_name, photo_url, roll_number,
          student_enrollments!inner(
            sections(name, classes(name))
          )
        ''')
        .eq('id', studentId)
        .maybeSingle();

    final student = studentResponse != null
        ? Map<String, dynamic>.from(studentResponse as Map)
        : <String, dynamic>{};
    final enrollments = (student['student_enrollments'] as List?)?.firstOrNull;
    final section = enrollments?['sections'] as Map<String, dynamic>?;
    final classInfo = section?['classes'] as Map<String, dynamic>?;

    // Fetch marks for grade summary
    final marksResponse = await client
        .from('marks')
        .select('''
          marks_obtained, max_marks, grade,
          exam_subjects!inner(
            subjects(name, id)
          )
        ''')
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(100);

    final allMarks = (marksResponse as List)
        .map((json) => _marksToSubjectScore(json as Map<String, dynamic>))
        .toList();

    // Deduplicate: keep latest mark per subject
    final Map<String, SubjectScore> subjectMap = {};
    for (final score in allMarks) {
      if (!subjectMap.containsKey(score.subjectId)) {
        subjectMap[score.subjectId] = score;
      }
    }
    final subjectScores = subjectMap.values.toList();

    final overallPct = subjectScores.isEmpty
        ? null
        : subjectScores
                .where((s) => s.percentage != null)
                .fold<double>(0.0, (sum, s) => sum + s.percentage!) /
            (subjectScores.where((s) => s.percentage != null).isEmpty
                ? 1
                : subjectScores.where((s) => s.percentage != null).length);

    // Fetch attendance
    final attendanceResponse = await client
        .from('attendance')
        .select('status')
        .eq('student_id', studentId)
        .eq('tenant_id', requireTenantId);

    final attendanceList = attendanceResponse as List;
    final presentDays =
        attendanceList.where((a) => a['status'] == 'present').length;
    final totalDays = attendanceList.length;
    final attendancePct =
        totalDays > 0 ? (presentDays / totalDays * 100) : 0.0;

    // Fetch achievements / gamification points
    final achievementsResponse = await client
        .from('student_points')
        .select('id, title:reason, points, created_at, badge_icon')
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(20);

    final achievements = (achievementsResponse as List)
        .map((json) => PortfolioAchievement.fromJson(json as Map<String, dynamic>))
        .toList();

    final totalPoints =
        achievements.fold<int>(0, (sum, a) => sum + a.points);

    // Fetch badge count from student_badges table if available
    int badgeCount = 0;
    try {
      final badgesResponse = await client
          .from('student_badges')
          .select('id')
          .eq('student_id', studentId);
      badgeCount = (badgesResponse as List).length;
    } catch (_) {
      badgeCount = achievements.length;
    }

    // Fetch assignment stats
    int submitted = 0;
    int pending = 0;
    try {
      final submissionsResponse = await client
          .from('submissions')
          .select('id')
          .eq('student_id', studentId);
      submitted = (submissionsResponse as List).length;

      final pendingResponse = await client
          .from('assignments')
          .select('id')
          .eq('tenant_id', requireTenantId)
          .gt('due_date', DateTime.now().toIso8601String());
      final allAssignments = (pendingResponse as List).length;
      pending = (allAssignments - submitted).clamp(0, allAssignments);
    } catch (_) {}

    return PortfolioSummary(
      studentId: studentId,
      studentName: student['full_name'] as String? ?? 'Student',
      photoUrl: student['photo_url'] as String?,
      className: classInfo?['name'] as String?,
      sectionName: section?['name'] as String?,
      rollNumber: student['roll_number'] as String? ?? '-',
      overallPercentage: overallPct?.isNaN == true ? null : overallPct,
      overallGrade: _percentageToGrade(overallPct),
      totalSubjects: subjectScores.length,
      subjectScores: subjectScores,
      totalWorkingDays: totalDays,
      presentDays: presentDays,
      attendancePercentage: attendancePct,
      achievements: achievements,
      totalPoints: totalPoints,
      badgeCount: badgeCount,
      assignmentsSubmitted: submitted,
      assignmentsPending: pending,
    );
  }

  // ============================================================
  // PORTFOLIO WORK
  // ============================================================

  Future<List<PortfolioWork>> getPortfolioWork(String studentId) async {
    try {
      final response = await client
          .from('submissions')
          .select('''
            id, file_url, created_at, grade,
            assignments!inner(title, description, subject_id,
              subjects(name)
            )
          ''')
          .eq('student_id', studentId)
          .not('file_url', 'is', null)
          .order('created_at', ascending: false)
          .limit(30);

      return (response as List).map((json) {
        final raw = json as Map<String, dynamic>;
        final assignment =
            raw['assignments'] as Map<String, dynamic>? ?? {};
        return PortfolioWork(
          id: raw['id'] as String,
          title: assignment['title'] as String? ?? 'Work',
          description: assignment['description'] as String?,
          workType: 'assignment',
          fileUrl: raw['file_url'] as String?,
          submittedAt: DateTime.parse(raw['created_at'] as String),
          subjectName: (assignment['subjects'] as Map<String, dynamic>?)?['name']
              as String?,
          grade: raw['grade'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  SubjectScore _marksToSubjectScore(Map<String, dynamic> json) {
    final examSubject =
        json['exam_subjects'] as Map<String, dynamic>? ?? {};
    final subject =
        examSubject['subjects'] as Map<String, dynamic>? ?? {};

    final marks = (json['marks_obtained'] as num?)?.toDouble();
    final max = (json['max_marks'] as num?)?.toDouble();
    final pct =
        (marks != null && max != null && max > 0) ? (marks / max * 100) : null;

    return SubjectScore(
      subjectId: subject['id'] as String? ?? '',
      subjectName: subject['name'] as String? ?? 'Unknown',
      marksObtained: marks,
      maxMarks: max,
      grade: json['grade'] as String?,
      percentage: pct,
    );
  }

  String? _percentageToGrade(double? pct) {
    if (pct == null) return null;
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 40) return 'D';
    return 'F';
  }
}
