import '../models/parent_digest.dart';
import '../../core/services/ai_text_generator.dart';
import '../../features/ai_insights/utils/digest_template_engine.dart';
import 'base_repository.dart';

class ParentDigestRepository extends BaseRepository {
  final AITextGenerator _aiTextGenerator;

  ParentDigestRepository(super.client, this._aiTextGenerator);

  Future<List<ParentDigest>> getDigestsForParent(
    String parentId, {
    String? studentId,
    int limit = 20,
  }) async {
    try {
      var query = client
          .from('parent_digests')
          .select()
          .eq('parent_id', parentId);

      if (studentId != null) {
        query = query.eq('student_id', studentId);
      }

      final response = await query
          .order('week_start', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ParentDigest.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<ParentDigest?> getDigestById(String digestId) async {
    try {
      final response = await client
          .from('parent_digests')
          .select()
          .eq('id', digestId)
          .maybeSingle();

      if (response == null) return null;
      return ParentDigest.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<int> getUnreadCount(String parentId) async {
    try {
      final response = await client
          .from('parent_digests')
          .select('id')
          .eq('parent_id', parentId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(String digestId) async {
    await client
        .from('parent_digests')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('id', digestId);
  }

  Future<void> generateWeeklyDigest({
    required String studentId,
    required String parentId,
    required String academicYearId,
    required DateTime weekStart,
  }) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekStartStr = weekStart.toIso8601String().split('T')[0];
    final weekEndStr = weekEnd.toIso8601String().split('T')[0];

    // 1. Get student info
    final studentResp = await client
        .from('students')
        .select('first_name, last_name')
        .eq('id', studentId)
        .single();
    final studentName =
        '${studentResp['first_name']} ${studentResp['last_name'] ?? ''}'
            .trim();

    // 2. Get attendance for the week
    final attendanceResp = await client
        .from('attendance')
        .select('status')
        .eq('student_id', studentId)
        .gte('date', weekStartStr)
        .lte('date', weekEndStr);

    final attList = attendanceResp as List;
    final present =
        attList.where((r) => r['status'] == 'present').length;
    final absent = attList.where((r) => r['status'] == 'absent').length;
    final late = attList.where((r) => r['status'] == 'late').length;
    final total = attList.length;

    // 3. Get academic highlights (recent marks/submissions)
    final highlights = <AcademicHighlight>[];
    try {
      final marksResp = await client
          .from('marks')
          .select('''
            marks_obtained,
            exam_subjects!inner(
              max_marks,
              subjects!inner(name),
              exams!inner(name, is_published)
            )
          ''')
          .eq('student_id', studentId)
          .eq('exam_subjects.exams.is_published', true)
          .gte('entered_at', weekStartStr)
          .lte('entered_at', weekEndStr)
          .limit(5);

      for (final mark in (marksResp as List)) {
        final es = mark['exam_subjects'];
        final maxMarks = (es['max_marks'] as num?)?.toDouble() ?? 1;
        final obtained = (mark['marks_obtained'] as num?)?.toDouble() ?? 0;
        final pct = (obtained / maxMarks * 100).round();
        final subjectName = es['subjects']?['name'] ?? 'Subject';
        highlights.add(AcademicHighlight(
          type: 'exam_result',
          description: 'Scored $pct% in $subjectName',
          subjectName: subjectName,
          score: pct.toDouble(),
        ));
      }
    } catch (_) {}

    // 4. Get upcoming events
    final events = <UpcomingEvent>[];
    try {
      final eventsResp = await client
          .from('calendar_events')
          .select('title, start_date, event_type')
          .gte('start_date', weekEndStr)
          .lte('start_date',
              weekEnd.add(const Duration(days: 7)).toIso8601String())
          .order('start_date')
          .limit(5);

      for (final ev in (eventsResp as List)) {
        events.add(UpcomingEvent(
          title: ev['title'] ?? '',
          date: DateTime.parse(ev['start_date']),
          type: ev['event_type'],
        ));
      }
    } catch (_) {}

    // 5. Generate content
    final highlightStrings =
        highlights.map((h) => h.description).toList();
    final eventStrings = events.map((e) => e.title).toList();

    final title = DigestTemplateEngine.generateTitle(
      studentName: studentName,
      weekStart: weekStart,
      weekEnd: weekEnd,
    );

    final templateSummary = DigestTemplateEngine.generateSummary(
      studentName: studentName,
      presentDays: present,
      totalDays: total,
      highlights: highlightStrings,
    );

    final aiResult = await _aiTextGenerator.generateDigestSummary(
      studentName: studentName,
      presentDays: present,
      totalDays: total,
      highlights: highlightStrings,
      fallback: templateSummary,
    );
    final summary = aiResult.text;

    final sections = DigestTemplateEngine.generateSections(
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      totalDays: total,
      highlights: highlightStrings,
      events: eventStrings,
    );

    // 6. Upsert digest
    await client.from('parent_digests').upsert({
      'tenant_id': tenantId,
      'student_id': studentId,
      'parent_id': parentId,
      'week_start': weekStartStr,
      'week_end': weekEndStr,
      'title': title,
      'summary': summary,
      'sections': sections.map((s) => s.toJson()).toList(),
      'attendance_present': present,
      'attendance_absent': absent,
      'attendance_late': late,
      'attendance_total': total,
      'highlights': highlights.map((h) => h.toJson()).toList(),
      'upcoming_events': events.map((e) => e.toJson()).toList(),
    }, onConflict: 'student_id,parent_id,week_start');
  }
}
