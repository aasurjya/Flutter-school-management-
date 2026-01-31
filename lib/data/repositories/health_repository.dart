import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_record.dart';
import 'base_repository.dart';

class HealthRepository extends BaseRepository {
  HealthRepository(super.client);

  // ==================== HEALTH RECORDS ====================

  Future<StudentHealthRecord?> getHealthRecord(String studentId) async {
    final response = await client
        .from('student_health_records')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();

    if (response == null) return null;
    return StudentHealthRecord.fromJson(response);
  }

  Future<StudentHealthRecord> createOrUpdateHealthRecord(
    String studentId,
    Map<String, dynamic> data,
  ) async {
    data['tenant_id'] = tenantId;
    data['student_id'] = studentId;
    data['updated_at'] = DateTime.now().toIso8601String();

    final existing = await getHealthRecord(studentId);

    if (existing != null) {
      final response = await client
          .from('student_health_records')
          .update(data)
          .eq('student_id', studentId)
          .select()
          .single();
      return StudentHealthRecord.fromJson(response);
    } else {
      final response = await client
          .from('student_health_records')
          .insert(data)
          .select()
          .single();
      return StudentHealthRecord.fromJson(response);
    }
  }

  Future<List<StudentHealthRecord>> getHealthRecordsWithAllergies() async {
    final response = await client
        .from('student_health_records')
        .select()
        .eq('tenant_id', tenantId!)
        .not('allergies', 'eq', '{}');

    return (response as List)
        .map((json) => StudentHealthRecord.fromJson(json))
        .toList();
  }

  Future<List<StudentHealthRecord>> getHealthRecordsWithConditions() async {
    final response = await client
        .from('student_health_records')
        .select()
        .eq('tenant_id', tenantId!)
        .not('chronic_conditions', 'eq', '{}');

    return (response as List)
        .map((json) => StudentHealthRecord.fromJson(json))
        .toList();
  }

  // ==================== HEALTH INCIDENTS ====================

  Future<List<HealthIncident>> getIncidents({
    String? studentId,
    String? severity,
    DateTime? fromDate,
    DateTime? toDate,
    bool pendingFollowUp = false,
  }) async {
    var query = client
        .from('health_incidents')
        .select()
        .eq('tenant_id', tenantId!);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    if (severity != null) {
      query = query.eq('severity', severity);
    }

    if (fromDate != null) {
      query = query.gte('incident_date', fromDate.toIso8601String().split('T')[0]);
    }

    if (toDate != null) {
      query = query.lte('incident_date', toDate.toIso8601String().split('T')[0]);
    }

    if (pendingFollowUp) {
      query = query.eq('follow_up_required', true);
      final today = DateTime.now().toIso8601String().split('T')[0];
      query = query.lte('follow_up_date', today);
    }

    final response = await query.order('incident_date', ascending: false);

    return (response as List)
        .map((json) => HealthIncident.fromJson(json))
        .toList();
  }

  Future<HealthIncident?> getIncidentById(String incidentId) async {
    final response = await client
        .from('health_incidents')
        .select()
        .eq('id', incidentId)
        .maybeSingle();

    if (response == null) return null;
    return HealthIncident.fromJson(response);
  }

  Future<HealthIncident> createIncident(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['reported_by'] = currentUserId;

    final response = await client
        .from('health_incidents')
        .insert(data)
        .select()
        .single();

    return HealthIncident.fromJson(response);
  }

  Future<HealthIncident> updateIncident(
    String incidentId,
    Map<String, dynamic> data,
  ) async {
    final response = await client
        .from('health_incidents')
        .update(data)
        .eq('id', incidentId)
        .select()
        .single();

    return HealthIncident.fromJson(response);
  }

  Future<void> markParentNotified(String incidentId) async {
    await client
        .from('health_incidents')
        .update({
          'parent_notified': true,
          'parent_notified_at': DateTime.now().toIso8601String(),
        })
        .eq('id', incidentId);
  }

  Future<void> completeFollowUp(String incidentId, String notes) async {
    await client
        .from('health_incidents')
        .update({
          'follow_up_required': false,
          'follow_up_notes': notes,
        })
        .eq('id', incidentId);
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getHealthStats() async {
    // Get students with allergies count
    final allergiesResponse = await client
        .from('student_health_records')
        .select('id')
        .eq('tenant_id', tenantId!)
        .not('allergies', 'eq', '{}');

    // Get students with chronic conditions count
    final conditionsResponse = await client
        .from('student_health_records')
        .select('id')
        .eq('tenant_id', tenantId!)
        .not('chronic_conditions', 'eq', '{}');

    // Get recent incidents (last 30 days)
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
    final incidentsResponse = await client
        .from('health_incidents')
        .select('id, severity')
        .eq('tenant_id', tenantId!)
        .gte('incident_date', thirtyDaysAgo);

    final incidents = incidentsResponse as List;
    final criticalCount =
        incidents.where((i) => i['severity'] == 'critical' || i['severity'] == 'serious').length;

    // Get pending follow-ups
    final today = DateTime.now().toIso8601String().split('T')[0];
    final followUpResponse = await client
        .from('health_incidents')
        .select('id')
        .eq('tenant_id', tenantId!)
        .eq('follow_up_required', true)
        .lte('follow_up_date', today);

    return {
      'students_with_allergies': (allergiesResponse as List).length,
      'students_with_conditions': (conditionsResponse as List).length,
      'incidents_last_30_days': incidents.length,
      'critical_incidents': criticalCount,
      'pending_follow_ups': (followUpResponse as List).length,
    };
  }
}
