import '../models/early_warning_alert.dart';
import 'base_repository.dart';

class EarlyWarningRepository extends BaseRepository {
  EarlyWarningRepository(super.client);

  // ---------------------------------------------------------------------------
  // Alerts
  // ---------------------------------------------------------------------------

  /// Fetches alerts with joined student info.
  ///
  /// The `early_warning_alerts` table has no `tenant_id` column; tenant
  /// isolation is handled by RLS policies on the table and the `!inner` join
  /// on `students` (which is tenant-scoped via RLS).
  Future<List<EarlyWarningAlert>> getAlerts({
    String? status,
    String? severity,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = client
          .from('early_warning_alerts')
          .select(
              '*, students!inner(id, first_name, last_name, admission_number)');

      if (status != null) {
        query = query.eq('status', status);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => EarlyWarningAlert.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches a single alert by ID with student join.
  Future<EarlyWarningAlert?> getAlertById(String alertId) async {
    try {
      final response = await client
          .from('early_warning_alerts')
          .select(
              '*, students!inner(id, first_name, last_name, admission_number)')
          .eq('id', alertId)
          .maybeSingle();

      if (response == null) return null;
      return EarlyWarningAlert.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Returns the count of unresolved alerts (new, acknowledged, in_progress).
  Future<int> getUnresolvedCount() async {
    try {
      final response = await client
          .from('early_warning_alerts')
          .select('id')
          .inFilter('status', ['new', 'acknowledged', 'in_progress']);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Updates the status of an alert. Sets `resolved_at` when status is
  /// 'resolved'.
  Future<void> updateAlertStatus({
    required String alertId,
    required String status,
    String? resolutionNotes,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (resolutionNotes != null) {
      data['resolution_notes'] = resolutionNotes;
    }

    if (status == 'resolved') {
      data['resolved_at'] = DateTime.now().toUtc().toIso8601String();
    }

    await client
        .from('early_warning_alerts')
        .update(data)
        .eq('id', alertId);
  }

  /// Creates a new early warning alert.
  Future<void> createAlert({
    required String studentId,
    required String category,
    required String severity,
    required String title,
    String? description,
    Map<String, dynamic>? triggerConditions,
    double? confidenceScore,
  }) async {
    final data = <String, dynamic>{
      'student_id': studentId,
      'alert_category': category,
      'severity': severity,
      'title': title,
    };

    if (description != null) {
      data['description'] = description;
    }
    if (triggerConditions != null) {
      data['trigger_conditions'] = triggerConditions;
    }
    if (confidenceScore != null) {
      data['confidence_score'] = confidenceScore;
    }

    await client.from('early_warning_alerts').insert(data);
  }

  // ---------------------------------------------------------------------------
  // Alert Rules
  // ---------------------------------------------------------------------------

  /// Fetches all alert rules for the current tenant.
  Future<List<AlertRule>> getAlertRules() async {
    try {
      final response = await client
          .from('alert_rules')
          .select()
          .eq('tenant_id', requireTenantId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AlertRule.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Creates a new alert rule. Automatically sets `tenant_id`.
  Future<void> createAlertRule(Map<String, dynamic> data) async {
    await client.from('alert_rules').insert({
      ...data,
      'tenant_id': requireTenantId,
    });
  }

  /// Updates an existing alert rule.
  Future<void> updateAlertRule(
    String ruleId,
    Map<String, dynamic> data,
  ) async {
    await client
        .from('alert_rules')
        .update({
          ...data,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', ruleId);
  }

  /// Toggles the `is_active` flag on an alert rule.
  Future<void> toggleAlertRule(String ruleId, bool isActive) async {
    await client
        .from('alert_rules')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', ruleId);
  }
}
