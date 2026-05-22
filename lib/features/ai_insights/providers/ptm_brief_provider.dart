import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/services/ai_text_generator.dart';

/// Sprint 1.1 — aggregates the structured context needed for an AI-generated
/// Pre-PTM brief (Parent-Teacher Meeting talking points).
///
/// The provider pulls only what the prompt needs (student basics, attendance
/// summary, recent marks, risk level, behavior incidents, achievements) so
/// the prompt stays small and the LLM cost stays low. Every field is optional
/// — the system prompt tells the LLM to use "n/a" if a field is missing.
class PtmBriefContext {
  final String studentName;
  final String className;
  final int? attendancePercent;
  final List<String> recentMarks;
  final String? riskLevel;
  final int? recentIncidentCount;
  final String? mostSevereRecentIncident;
  final List<String> achievements;

  const PtmBriefContext({
    required this.studentName,
    required this.className,
    this.attendancePercent,
    this.recentMarks = const [],
    this.riskLevel,
    this.recentIncidentCount,
    this.mostSevereRecentIncident,
    this.achievements = const [],
  });

  String get fallbackBrief =>
      '- Academic summary not available for $studentName at this time.\n'
      '- Attendance & engagement data pending.\n'
      '- Behavior record clear in the last 30 days.\n'
      '- Please share specific praise from your direct observation.\n'
      '- Please share your top concern from your direct observation.\n'
      '- Recommend a 1:1 follow-up to discuss progress next week.';
}

class PtmBriefArgs {
  final String studentId;
  final String tenantId;
  const PtmBriefArgs({required this.studentId, required this.tenantId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PtmBriefArgs &&
          other.studentId == studentId &&
          other.tenantId == tenantId;

  @override
  int get hashCode => Object.hash(studentId, tenantId);
}

// ---------------------------------------------------------------------------
// Context loader — fans out 4 lightweight queries in parallel
// ---------------------------------------------------------------------------

Future<PtmBriefContext> _loadContext(
  SupabaseClient client,
  PtmBriefArgs args,
) async {
  final results = await Future.wait<dynamic>([
    _fetchStudent(client, args),
    _fetchAttendance(client, args),
    _fetchRecentMarks(client, args),
    _fetchRiskAndBehavior(client, args),
    _fetchAchievements(client, args),
  ]);

  final student = results[0] as Map<String, dynamic>?;
  final attendancePercent = results[1] as int?;
  final marks = results[2] as List<String>;
  final risk = results[3] as Map<String, dynamic>;
  final achievements = results[4] as List<String>;

  final firstName = student?['first_name'] as String? ?? 'this student';
  final lastName = student?['last_name'] as String? ?? '';
  final className = _formatClassName(student) ?? 'n/a';

  return PtmBriefContext(
    studentName: '$firstName $lastName'.trim(),
    className: className,
    attendancePercent: attendancePercent,
    recentMarks: marks,
    riskLevel: risk['risk_level'] as String?,
    recentIncidentCount: risk['incident_count'] as int?,
    mostSevereRecentIncident: risk['most_severe'] as String?,
    achievements: achievements,
  );
}

Future<Map<String, dynamic>?> _fetchStudent(
    SupabaseClient client, PtmBriefArgs a) async {
  try {
    return await client
        .from('students')
        .select(
            'first_name, last_name, '
            'enrollment:student_enrollments(section:sections(name, class:classes(name)))')
        .eq('id', a.studentId)
        .eq('tenant_id', a.tenantId)
        .maybeSingle();
  } catch (_) {
    return null;
  }
}

Future<int?> _fetchAttendance(SupabaseClient client, PtmBriefArgs a) async {
  try {
    final since = DateTime.now().subtract(const Duration(days: 90));
    final rows = await client
        .from('attendance')
        .select('status')
        .eq('student_id', a.studentId)
        .eq('tenant_id', a.tenantId)
        .gte('date', since.toIso8601String().substring(0, 10));
    if (rows.isEmpty) return null;
    final total = rows.length;
    final present = rows.where((r) {
      final s = r['status'];
      return s == 'present' || s == 'late';
    }).length;
    return ((present / total) * 100).round();
  } catch (_) {
    return null;
  }
}

Future<List<String>> _fetchRecentMarks(
    SupabaseClient client, PtmBriefArgs a) async {
  try {
    final rows = await client
        .from('marks')
        .select(
            'marks_obtained, exam_subject:exam_subjects(max_marks, subject:subjects(name), exam:exams(name))')
        .eq('student_id', a.studentId)
        .eq('tenant_id', a.tenantId)
        .order('created_at', ascending: false)
        .limit(3);
    return rows.whereType<Map>().map((r) {
      final examSub = r['exam_subject'] as Map?;
      final subject =
          (examSub?['subject'] as Map?)?['name'] as String? ?? 'Subject';
      final max = examSub?['max_marks'] as num? ?? 0;
      final obtained = r['marks_obtained'] as num? ?? 0;
      return '$subject ${obtained.round()}/${max.round()}';
    }).toList();
  } catch (_) {
    return const [];
  }
}

Future<Map<String, dynamic>> _fetchRiskAndBehavior(
    SupabaseClient client, PtmBriefArgs a) async {
  final result = <String, dynamic>{};
  try {
    final risk = await client
        .from('student_risk_scores')
        .select('risk_level')
        .eq('student_id', a.studentId)
        .eq('tenant_id', a.tenantId)
        .order('computed_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (risk != null) result['risk_level'] = risk['risk_level'];
  } catch (_) {}

  try {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final incidents = await client
        .from('behavior_incidents')
        .select('severity, incident_date')
        .eq('student_id', a.studentId)
        .eq('tenant_id', a.tenantId)
        .gte('incident_date', since.toIso8601String().substring(0, 10))
        .order('incident_date', ascending: false);
    if (incidents.isNotEmpty) {
      result['incident_count'] = incidents.length;
      const sevOrder = {'critical': 4, 'major': 3, 'moderate': 2, 'minor': 1};
      String? worst;
      int worstRank = 0;
      for (final raw in incidents.whereType<Map>()) {
        final sev = (raw['severity'] as String?) ?? 'minor';
        final rank = sevOrder[sev] ?? 0;
        if (rank > worstRank) {
          worst = sev;
          worstRank = rank;
        }
      }
      result['most_severe'] = worst;
    } else {
      result['incident_count'] = 0;
    }
  } catch (_) {}
  return result;
}

Future<List<String>> _fetchAchievements(
    SupabaseClient client, PtmBriefArgs a) async {
  try {
    final since = DateTime.now().subtract(const Duration(days: 60));
    final rows = await client
        .from('positive_recognitions')
        .select('title')
        .eq('student_id', a.studentId)
        .eq('tenant_id', a.tenantId)
        .gte('created_at', since.toIso8601String())
        .order('created_at', ascending: false)
        .limit(3);
    return rows
        .whereType<Map>()
        .map((r) => (r['title'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
}

String? _formatClassName(Map<String, dynamic>? student) {
  if (student == null) return null;
  final enrollments = student['enrollment'];
  Map? first;
  if (enrollments is List && enrollments.isNotEmpty) {
    first = enrollments.first as Map?;
  } else if (enrollments is Map) {
    first = enrollments;
  }
  final section = first?['section'] as Map?;
  final cls = section?['class'] as Map?;
  final clsName = cls?['name'] as String?;
  final sectName = section?['name'] as String?;
  if (clsName == null && sectName == null) return null;
  return [clsName, sectName].whereType<String>().join(' ').trim();
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final ptmBriefContextProvider =
    FutureProvider.autoDispose.family<PtmBriefContext, PtmBriefArgs>(
        (ref, args) {
  return _loadContext(ref.watch(supabaseProvider), args);
});

/// The user-facing provider — call this from the UI to get the rendered brief.
/// `keepAlive` is intentionally NOT set so the result auto-disposes when the
/// bottom sheet closes (cost-conscious).
final ptmBriefProvider =
    FutureProvider.autoDispose.family<AITextResult, PtmBriefArgs>(
        (ref, args) async {
  final ctx = await ref.watch(ptmBriefContextProvider(args).future);
  final gen = ref.watch(aiTextGeneratorProvider);
  return gen.generatePtmBrief(
    studentName: ctx.studentName,
    className: ctx.className,
    attendancePercent: ctx.attendancePercent,
    recentMarks: ctx.recentMarks,
    riskLevel: ctx.riskLevel,
    recentIncidentCount: ctx.recentIncidentCount,
    mostSevereRecentIncident: ctx.mostSevereRecentIncident,
    achievements: ctx.achievements,
    fallback: ctx.fallbackBrief,
  );
});
