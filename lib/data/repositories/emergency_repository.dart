import '../models/emergency.dart';
import 'base_repository.dart';

class EmergencyRepository extends BaseRepository {
  EmergencyRepository(super.client);

  // ==================== ALERTS ====================

  Future<List<EmergencyAlert>> getAlerts({
    String? status,
    String? alertType,
    int limit = 50,
  }) async {
    var query = client
        .from('emergency_alerts')
        .select('''
          *,
          initiator:users!initiated_by(full_name),
          resolver:users!resolved_by(full_name)
        ''')
        .eq('tenant_id', tenantId!);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (alertType != null) {
      query = query.eq('alert_type', alertType);
    }

    final response = await query
        .order('initiated_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => EmergencyAlert.fromJson(json))
        .toList();
  }

  Future<EmergencyAlert?> getAlertById(String alertId) async {
    final response = await client
        .from('emergency_alerts')
        .select('''
          *,
          initiator:users!initiated_by(full_name),
          resolver:users!resolved_by(full_name)
        ''')
        .eq('id', alertId)
        .maybeSingle();

    if (response == null) return null;
    return EmergencyAlert.fromJson(response);
  }

  Future<EmergencyAlert?> getActiveAlert() async {
    final response = await client
        .from('emergency_alerts')
        .select('''
          *,
          initiator:users!initiated_by(full_name)
        ''')
        .eq('tenant_id', tenantId!)
        .eq('status', 'active')
        .order('initiated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return EmergencyAlert.fromJson(response);
  }

  Future<EmergencyAlert> initiateAlert({
    required String alertType,
    required String title,
    required String message,
    required String severity,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await client
        .from('emergency_alerts')
        .insert({
          'tenant_id': tenantId,
          'alert_type': alertType,
          'title': title,
          'message': message,
          'severity': severity,
          'status': 'active',
          'initiated_by': currentUserId,
          'initiated_at': DateTime.now().toIso8601String(),
          'metadata': metadata,
        })
        .select()
        .single();

    return EmergencyAlert.fromJson(response);
  }

  Future<void> resolveAlert(String alertId, {String? notes}) async {
    await client.from('emergency_alerts').update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toIso8601String(),
      'resolved_by': currentUserId,
      'resolution_notes': notes,
    }).eq('id', alertId);
  }

  // ==================== RESPONSES ====================

  Future<List<EmergencyResponse>> getAlertResponses(String alertId) async {
    final response = await client
        .from('emergency_responses')
        .select('''
          *,
          responder:users(full_name)
        ''')
        .eq('alert_id', alertId)
        .order('responded_at');

    return (response as List)
        .map((json) => EmergencyResponse.fromJson(json))
        .toList();
  }

  Future<EmergencyResponse?> getMyResponse(String alertId) async {
    final response = await client
        .from('emergency_responses')
        .select()
        .eq('alert_id', alertId)
        .eq('responder_id', currentUserId!)
        .maybeSingle();

    if (response == null) return null;
    return EmergencyResponse.fromJson(response);
  }

  Future<EmergencyResponse> submitResponse({
    required String alertId,
    required String status,
    String? location,
    String? notes,
    int? studentCount,
  }) async {
    // Check for existing response
    final existing = await getMyResponse(alertId);

    if (existing != null) {
      final response = await client
          .from('emergency_responses')
          .update({
            'status': status,
            'location': location,
            'notes': notes,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing.id)
          .select()
          .single();
      return EmergencyResponse.fromJson(response);
    }

    final response = await client
        .from('emergency_responses')
        .insert({
          'alert_id': alertId,
          'responder_id': currentUserId,
          'responder_type': 'staff', // Determine from user role
          'status': status,
          'location': location,
          'notes': notes,
          'responded_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return EmergencyResponse.fromJson(response);
  }

  Future<Map<String, int>> getResponseStats(String alertId) async {
    final responses = await getAlertResponses(alertId);

    return {
      'total': responses.length,
      'safe': responses.where((r) => r.status == 'safe').length,
      'needs_help': responses.where((r) => r.status == 'needs_help').length,
      'not_responded': responses.where((r) => r.status == 'not_responded').length,
    };
  }

  // ==================== EMERGENCY CONTACTS ====================

  Future<List<EmergencyContact>> getEmergencyContacts({
    String? contactType,
    bool activeOnly = true,
  }) async {
    var query = client
        .from('emergency_contacts')
        .select()
        .eq('tenant_id', tenantId!);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }
    if (contactType != null) {
      query = query.eq('contact_type', contactType);
    }

    final response = await query.order('priority');

    return (response as List)
        .map((json) => EmergencyContact.fromJson(json))
        .toList();
  }

  Future<EmergencyContact> createEmergencyContact(
    Map<String, dynamic> data,
  ) async {
    data['tenant_id'] = tenantId;

    final response = await client
        .from('emergency_contacts')
        .insert(data)
        .select()
        .single();

    return EmergencyContact.fromJson(response);
  }

  Future<void> updateEmergencyContact(
    String contactId,
    Map<String, dynamic> data,
  ) async {
    await client
        .from('emergency_contacts')
        .update(data)
        .eq('id', contactId);
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    await client.from('emergency_contacts').delete().eq('id', contactId);
  }

  // ==================== DRILL MANAGEMENT ====================

  Future<void> startDrill({
    required String alertType,
    required String title,
  }) async {
    await initiateAlert(
      alertType: alertType,
      title: '[DRILL] $title',
      message: 'This is a drill. Please follow emergency procedures.',
      severity: 'low',
      metadata: {'is_drill': true},
    );
  }
}
