import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/discipline.dart';
import 'base_repository.dart';

class DisciplineRepository extends BaseRepository {
  DisciplineRepository(SupabaseClient client) : super(client);

  // ─── BEHAVIOR CATEGORIES ──────────────────────────────────

  Future<List<BehaviorCategory>> getCategories({
    BehaviorCategoryType? type,
    bool activeOnly = true,
  }) async {
    var query = client
        .from('behavior_categories')
        .select()
        .eq('tenant_id', requireTenantId);

    if (type != null) {
      query = query.eq('type', type.value);
    }
    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final data = await query.order('name');
    return data.map((e) => BehaviorCategory.fromJson(e)).toList();
  }

  Future<BehaviorCategory> createCategory(BehaviorCategory category) async {
    final data = await client
        .from('behavior_categories')
        .insert(category.toJson())
        .select()
        .single();
    return BehaviorCategory.fromJson(data);
  }

  Future<BehaviorCategory> updateCategory(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await client
        .from('behavior_categories')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return BehaviorCategory.fromJson(data);
  }

  Future<void> deleteCategory(String id) async {
    await client.from('behavior_categories').delete().eq('id', id);
  }

  // ─── BEHAVIOR INCIDENTS ───────────────────────────────────

  static const _incidentSelect = '''
    *,
    student:students!student_id(id, first_name, last_name, photo_url),
    reporter:users!reported_by(id, full_name),
    category:behavior_categories!category_id(id, name, type, points, color),
    behavior_actions(
      *,
      assigner:users!assigned_by(id, full_name),
      assignee:users!assigned_to(id, full_name)
    )
  ''';

  Future<List<BehaviorIncident>> getIncidents({
    IncidentFilter filter = const IncidentFilter(),
  }) async {
    var query = client
        .from('behavior_incidents')
        .select(_incidentSelect)
        .eq('tenant_id', requireTenantId);

    if (filter.severity != null) {
      query = query.eq('severity', filter.severity!.value);
    }
    if (filter.status != null) {
      query = query.eq('status', filter.status!.value);
    }
    if (filter.studentId != null) {
      query = query.eq('student_id', filter.studentId!);
    }
    if (filter.startDate != null) {
      query = query.gte(
        'incident_date',
        filter.startDate!.toIso8601String().split('T')[0],
      );
    }
    if (filter.endDate != null) {
      query = query.lte(
        'incident_date',
        filter.endDate!.toIso8601String().split('T')[0],
      );
    }

    final data = await query
        .order('incident_date', ascending: false)
        .order('created_at', ascending: false)
        .range(filter.offset, filter.offset + filter.limit - 1);
    return data.map((e) => BehaviorIncident.fromJson(e)).toList();
  }

  Future<BehaviorIncident> getIncidentById(String id) async {
    final data = await client
        .from('behavior_incidents')
        .select(_incidentSelect)
        .eq('id', id)
        .single();
    return BehaviorIncident.fromJson(data);
  }

  Future<BehaviorIncident> createIncident(BehaviorIncident incident) async {
    final data = await client
        .from('behavior_incidents')
        .insert(incident.toJson())
        .select(_incidentSelect)
        .single();
    return BehaviorIncident.fromJson(data);
  }

  Future<BehaviorIncident> updateIncident(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await client
        .from('behavior_incidents')
        .update(updates)
        .eq('id', id)
        .select(_incidentSelect)
        .single();
    return BehaviorIncident.fromJson(data);
  }

  Future<void> deleteIncident(String id) async {
    await client.from('behavior_incidents').delete().eq('id', id);
  }

  Future<List<BehaviorIncident>> getStudentBehaviorHistory(
    String studentId,
  ) async {
    final data = await client
        .from('behavior_incidents')
        .select(_incidentSelect)
        .eq('student_id', studentId)
        .order('incident_date', ascending: false)
        .limit(100);
    return data.map((e) => BehaviorIncident.fromJson(e)).toList();
  }

  // ─── BEHAVIOR ACTIONS ─────────────────────────────────────

  Future<BehaviorAction> createAction(BehaviorAction action) async {
    final data = await client
        .from('behavior_actions')
        .insert(action.toJson())
        .select('*, assigner:users!assigned_by(id, full_name), assignee:users!assigned_to(id, full_name)')
        .single();
    return BehaviorAction.fromJson(data);
  }

  Future<BehaviorAction> updateAction(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await client
        .from('behavior_actions')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return BehaviorAction.fromJson(data);
  }

  Future<void> completeAction(String id) async {
    await client.from('behavior_actions').update({
      'completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ─── BEHAVIOR PLANS ───────────────────────────────────────

  static const _planSelect = '''
    *,
    student:students!student_id(id, first_name, last_name, photo_url),
    creator:users!created_by(id, full_name),
    behavior_plan_reviews(
      *,
      reviewer:users!reviewed_by(id, full_name)
    )
  ''';

  Future<List<BehaviorPlan>> getPlans({
    String? studentId,
    BehaviorPlanStatus? status,
  }) async {
    var query = client
        .from('behavior_plans')
        .select(_planSelect)
        .eq('tenant_id', requireTenantId);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status.value);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((e) => BehaviorPlan.fromJson(e)).toList();
  }

  Future<BehaviorPlan> getPlanById(String id) async {
    final data = await client
        .from('behavior_plans')
        .select(_planSelect)
        .eq('id', id)
        .single();
    return BehaviorPlan.fromJson(data);
  }

  Future<BehaviorPlan> createPlan(BehaviorPlan plan) async {
    final data = await client
        .from('behavior_plans')
        .insert(plan.toJson())
        .select(_planSelect)
        .single();
    return BehaviorPlan.fromJson(data);
  }

  Future<BehaviorPlan> updatePlan(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await client
        .from('behavior_plans')
        .update(updates)
        .eq('id', id)
        .select(_planSelect)
        .single();
    return BehaviorPlan.fromJson(data);
  }

  Future<BehaviorPlanReview> createPlanReview(
    BehaviorPlanReview review,
  ) async {
    final data = await client
        .from('behavior_plan_reviews')
        .insert(review.toJson())
        .select('*, reviewer:users!reviewed_by(id, full_name)')
        .single();
    return BehaviorPlanReview.fromJson(data);
  }

  // ─── POSITIVE RECOGNITIONS ────────────────────────────────

  static const _recognitionSelect = '''
    *,
    student:students!student_id(id, first_name, last_name, photo_url),
    recognizer:users!recognized_by(id, full_name),
    category:behavior_categories!category_id(id, name)
  ''';

  Future<List<PositiveRecognition>> getRecognitions({
    String? studentId,
    bool publicOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('positive_recognitions')
        .select(_recognitionSelect)
        .eq('tenant_id', requireTenantId);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (publicOnly) {
      query = query.eq('is_public', true);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return data.map((e) => PositiveRecognition.fromJson(e)).toList();
  }

  Future<PositiveRecognition> createRecognition(
    PositiveRecognition recognition,
  ) async {
    final data = await client
        .from('positive_recognitions')
        .insert(recognition.toJson())
        .select(_recognitionSelect)
        .single();
    return PositiveRecognition.fromJson(data);
  }

  // ─── DETENTION SCHEDULES ──────────────────────────────────

  Future<List<DetentionSchedule>> getDetentionSchedules({
    bool activeOnly = true,
  }) async {
    var query = client
        .from('detention_schedules')
        .select('*, supervisor:users!supervisor_id(id, full_name)')
        .eq('tenant_id', requireTenantId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final data = await query.order('day_of_week').order('start_time');
    return data.map((e) => DetentionSchedule.fromJson(e)).toList();
  }

  Future<DetentionSchedule> createDetentionSchedule(
    DetentionSchedule schedule,
  ) async {
    final data = await client
        .from('detention_schedules')
        .insert(schedule.toJson())
        .select('*, supervisor:users!supervisor_id(id, full_name)')
        .single();
    return DetentionSchedule.fromJson(data);
  }

  Future<DetentionSchedule> updateDetentionSchedule(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await client
        .from('detention_schedules')
        .update(updates)
        .eq('id', id)
        .select('*, supervisor:users!supervisor_id(id, full_name)')
        .single();
    return DetentionSchedule.fromJson(data);
  }

  Future<void> deleteDetentionSchedule(String id) async {
    await client.from('detention_schedules').delete().eq('id', id);
  }

  // ─── DETENTION ASSIGNMENTS ────────────────────────────────

  Future<List<DetentionAssignment>> getDetentionAssignments({
    DateTime? date,
    String? studentId,
    String? scheduleId,
  }) async {
    var query = client
        .from('detention_assignments')
        .select(
          '*, student:students!student_id(id, first_name, last_name), assigner:users!assigned_by(id, full_name)',
        )
        .eq('tenant_id', requireTenantId);

    if (date != null) {
      query = query.eq(
        'detention_date',
        date.toIso8601String().split('T')[0],
      );
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (scheduleId != null) {
      query = query.eq('schedule_id', scheduleId);
    }

    final data =
        await query.order('detention_date', ascending: false);
    return data.map((e) => DetentionAssignment.fromJson(e)).toList();
  }

  Future<DetentionAssignment> createDetentionAssignment(
    DetentionAssignment assignment,
  ) async {
    final data = await client
        .from('detention_assignments')
        .insert(assignment.toJson())
        .select()
        .single();
    return DetentionAssignment.fromJson(data);
  }

  Future<DetentionAssignment> updateDetentionAssignment(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await client
        .from('detention_assignments')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return DetentionAssignment.fromJson(data);
  }

  // ─── BEHAVIOR SCORE ───────────────────────────────────────

  Future<BehaviorScore> getStudentBehaviorScore(String studentId) async {
    final data = await client
        .from('v_student_behavior_score')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();

    if (data == null) {
      return BehaviorScore(studentId: studentId);
    }
    return BehaviorScore.fromJson(data);
  }

  // ─── STATS / ANALYTICS ───────────────────────────────────

  Future<BehaviorStats> getBehaviorStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final tid = requireTenantId;
    final start = startDate ??
        DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    // Fetch all incidents in date range
    final incidents = await client
        .from('behavior_incidents')
        .select('id, severity, status, category_id, incident_date, behavior_categories!category_id(name)')
        .eq('tenant_id', tid)
        .gte('incident_date', startStr)
        .lte('incident_date', endStr);

    // Fetch recognitions count
    final recognitions = await client
        .from('positive_recognitions')
        .select('id')
        .eq('tenant_id', tid)
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());

    // Aggregate
    int totalIncidents = incidents.length;
    int openIncidents = 0;
    int resolvedIncidents = 0;
    final Map<String, int> bySeverity = {};
    final Map<String, int> byCategory = {};
    final Map<String, int> dailyMap = {};

    for (final inc in incidents) {
      final status = inc['status'] as String;
      if (status == 'reported' || status == 'investigating') {
        openIncidents++;
      }
      if (status == 'resolved') {
        resolvedIncidents++;
      }

      final sev = inc['severity'] as String;
      bySeverity[sev] = (bySeverity[sev] ?? 0) + 1;

      final catName =
          (inc['behavior_categories'] as Map?)?['name'] as String? ??
              'Uncategorized';
      byCategory[catName] = (byCategory[catName] ?? 0) + 1;

      final dateStr = inc['incident_date'] as String;
      dailyMap[dateStr] = (dailyMap[dateStr] ?? 0) + 1;
    }

    // Build daily trend
    final List<DailyIncidentCount> dailyTrend = [];
    var current = start;
    while (!current.isAfter(end)) {
      final key = current.toIso8601String().split('T')[0];
      dailyTrend.add(DailyIncidentCount(
        date: current,
        count: dailyMap[key] ?? 0,
      ));
      current = current.add(const Duration(days: 1));
    }

    return BehaviorStats(
      totalIncidents: totalIncidents,
      openIncidents: openIncidents,
      resolvedIncidents: resolvedIncidents,
      totalRecognitions: recognitions.length,
      incidentsBySeverity: bySeverity,
      incidentsByCategory: byCategory,
      dailyTrend: dailyTrend,
    );
  }

  /// Top students by positive recognition points
  Future<List<Map<String, dynamic>>> getTopPositiveStudents({
    int limit = 10,
  }) async {
    final data = await client
        .from('v_student_behavior_score')
        .select('*, students!student_id(first_name, last_name, photo_url)')
        .eq('tenant_id', requireTenantId)
        .order('positive_points', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }
}
