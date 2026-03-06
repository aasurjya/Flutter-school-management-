import '../models/visitor.dart';
import 'base_repository.dart';

class VisitorRepository extends BaseRepository {
  VisitorRepository(super.client);

  // ============================================
  // VISITORS
  // ============================================

  Future<List<Visitor>> getVisitors({
    String? search,
    bool? isBlacklisted,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('visitors')
        .select('*')
        .eq('tenant_id', requireTenantId);

    if (isBlacklisted != null) {
      query = query.eq('is_blacklisted', isBlacklisted);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('full_name.ilike.%$search%,phone.ilike.%$search%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => Visitor.fromJson(json))
        .toList();
  }

  Future<Visitor?> getVisitorById(String visitorId) async {
    final response = await client
        .from('visitors')
        .select('*')
        .eq('id', visitorId)
        .maybeSingle();

    if (response == null) return null;
    return Visitor.fromJson(response);
  }

  Future<Visitor?> getVisitorByPhone(String phone) async {
    final response = await client
        .from('visitors')
        .select('*')
        .eq('tenant_id', requireTenantId)
        .eq('phone', phone)
        .maybeSingle();

    if (response == null) return null;
    return Visitor.fromJson(response);
  }

  Future<Visitor> createVisitor(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('visitors')
        .insert(data)
        .select()
        .single();

    return Visitor.fromJson(response);
  }

  Future<Visitor> updateVisitor(
      String visitorId, Map<String, dynamic> data) async {
    final response = await client
        .from('visitors')
        .update(data)
        .eq('id', visitorId)
        .select()
        .single();

    return Visitor.fromJson(response);
  }

  Future<Visitor> toggleBlacklist(String visitorId, bool blacklist) async {
    return updateVisitor(visitorId, {'is_blacklisted': blacklist});
  }

  Future<void> deleteVisitor(String visitorId) async {
    await client.from('visitors').delete().eq('id', visitorId);
  }

  // ============================================
  // VISITOR LOGS
  // ============================================

  static const _logSelect = '''
    *,
    visitors(*),
    person_to_meet_user:person_to_meet(id, full_name),
    approved_by_user:approved_by(id, full_name)
  ''';

  Future<List<VisitorLog>> getVisitorLogs({
    String? visitorId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('visitor_logs')
        .select(_logSelect)
        .eq('tenant_id', requireTenantId);

    if (visitorId != null) {
      query = query.eq('visitor_id', visitorId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (fromDate != null) {
      query = query.gte('check_in_time', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('check_in_time', toDate.toIso8601String());
    }

    final response = await query
        .order('check_in_time', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => VisitorLog.fromJson(json))
        .toList();
  }

  Future<List<VisitorLog>> getTodayLogs() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getVisitorLogs(
      fromDate: startOfDay,
      toDate: endOfDay,
      limit: 200,
    );
  }

  Future<VisitorLog?> getLogById(String logId) async {
    final response = await client
        .from('visitor_logs')
        .select(_logSelect)
        .eq('id', logId)
        .maybeSingle();

    if (response == null) return null;
    return VisitorLog.fromJson(response);
  }

  Future<VisitorLog> checkInVisitor(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['status'] = 'checked_in';
    data['check_in_time'] = DateTime.now().toIso8601String();
    data['approved_by'] = currentUserId;

    final response = await client
        .from('visitor_logs')
        .insert(data)
        .select(_logSelect)
        .single();

    return VisitorLog.fromJson(response);
  }

  Future<VisitorLog> checkOutVisitor(String logId) async {
    final response = await client
        .from('visitor_logs')
        .update({
          'status': 'checked_out',
          'check_out_time': DateTime.now().toIso8601String(),
        })
        .eq('id', logId)
        .select(_logSelect)
        .single();

    return VisitorLog.fromJson(response);
  }

  Future<VisitorLog> denyVisitor(String logId, {String? notes}) async {
    final data = <String, dynamic>{
      'status': 'denied',
      'approved_by': currentUserId,
    };
    if (notes != null) data['notes'] = notes;

    final response = await client
        .from('visitor_logs')
        .update(data)
        .eq('id', logId)
        .select(_logSelect)
        .single();

    return VisitorLog.fromJson(response);
  }

  Future<VisitorLog?> findLogByBadge(String badgeNumber) async {
    final response = await client
        .from('visitor_logs')
        .select(_logSelect)
        .eq('tenant_id', requireTenantId)
        .eq('badge_number', badgeNumber)
        .eq('status', 'checked_in')
        .order('check_in_time', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return VisitorLog.fromJson(response);
  }

  Future<void> deleteLog(String logId) async {
    await client.from('visitor_logs').delete().eq('id', logId);
  }

  // ============================================
  // PRE-REGISTRATIONS
  // ============================================

  static const _preRegSelect = '''
    *,
    users:host_id(id, full_name)
  ''';

  Future<List<VisitorPreRegistration>> getPreRegistrations({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('visitor_pre_registrations')
        .select(_preRegSelect)
        .eq('tenant_id', requireTenantId);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (fromDate != null) {
      query = query.gte(
          'expected_date', fromDate.toIso8601String().split('T')[0]);
    }
    if (toDate != null) {
      query = query.lte(
          'expected_date', toDate.toIso8601String().split('T')[0]);
    }

    final response = await query
        .order('expected_date', ascending: true)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => VisitorPreRegistration.fromJson(json))
        .toList();
  }

  Future<List<VisitorPreRegistration>> getTodayPreRegistrations() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('visitor_pre_registrations')
        .select(_preRegSelect)
        .eq('tenant_id', requireTenantId)
        .eq('expected_date', dateStr)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => VisitorPreRegistration.fromJson(json))
        .toList();
  }

  Future<VisitorPreRegistration?> getPreRegistrationByQr(
      String qrData) async {
    final response = await client
        .from('visitor_pre_registrations')
        .select(_preRegSelect)
        .eq('qr_code_data', qrData)
        .maybeSingle();

    if (response == null) return null;
    return VisitorPreRegistration.fromJson(response);
  }

  Future<VisitorPreRegistration> createPreRegistration(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    // Generate QR data if not provided
    if (data['qr_code_data'] == null) {
      data['qr_code_data'] =
          'VPR-${DateTime.now().millisecondsSinceEpoch}-${data['visitor_name']?.hashCode.abs()}';
    }

    final response = await client
        .from('visitor_pre_registrations')
        .insert(data)
        .select(_preRegSelect)
        .single();

    return VisitorPreRegistration.fromJson(response);
  }

  Future<VisitorPreRegistration> updatePreRegistration(
      String id, Map<String, dynamic> data) async {
    final response = await client
        .from('visitor_pre_registrations')
        .update(data)
        .eq('id', id)
        .select(_preRegSelect)
        .single();

    return VisitorPreRegistration.fromJson(response);
  }

  Future<VisitorPreRegistration> approvePreRegistration(String id) async {
    return updatePreRegistration(id, {'status': 'approved'});
  }

  Future<VisitorPreRegistration> denyPreRegistration(String id) async {
    return updatePreRegistration(id, {'status': 'denied'});
  }

  Future<VisitorPreRegistration> completePreRegistration(
      String id) async {
    return updatePreRegistration(id, {'status': 'completed'});
  }

  Future<void> deletePreRegistration(String id) async {
    await client.from('visitor_pre_registrations').delete().eq('id', id);
  }

  // ============================================
  // STATS
  // ============================================

  Future<VisitorStats> getVisitorStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Today's logs
    final logsResponse = await client
        .from('visitor_logs')
        .select('status')
        .eq('tenant_id', requireTenantId)
        .gte('check_in_time', startOfDay.toIso8601String())
        .lte('check_in_time', endOfDay.toIso8601String());

    final logs = logsResponse as List;
    int checkedIn = 0;
    int checkedOut = 0;
    int denied = 0;

    for (final log in logs) {
      switch (log['status']) {
        case 'checked_in':
          checkedIn++;
          break;
        case 'checked_out':
          checkedOut++;
          break;
        case 'denied':
          denied++;
          break;
      }
    }

    // Today's pre-registrations
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final preRegResponse = await client
        .from('visitor_pre_registrations')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .eq('expected_date', dateStr);
    final preRegCount = (preRegResponse as List).length;

    // Blacklisted count
    final blacklistedResponse = await client
        .from('visitors')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .eq('is_blacklisted', true);
    final blacklistedCount = (blacklistedResponse as List).length;

    return VisitorStats(
      todayTotal: logs.length,
      currentlyCheckedIn: checkedIn,
      preRegisteredToday: preRegCount,
      checkedOutToday: checkedOut,
      deniedToday: denied,
      blacklisted: blacklistedCount,
    );
  }
}
