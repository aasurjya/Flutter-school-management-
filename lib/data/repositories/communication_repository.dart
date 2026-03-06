import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/communication.dart';
import 'base_repository.dart';

class CommunicationRepository extends BaseRepository {
  CommunicationRepository(super.client);

  // ============================================================
  // Templates
  // ============================================================

  Future<List<CommunicationTemplate>> getTemplates({
    TemplateCategory? category,
    bool? activeOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('communication_templates')
        .select()
        .eq('tenant_id', requireTenantId);

    if (category != null) {
      query = query.eq('category', category.value);
    }
    if (activeOnly == true) {
      query = query.eq('is_active', true);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => CommunicationTemplate.fromJson(json))
        .toList();
  }

  Future<CommunicationTemplate?> getTemplateById(String id) async {
    final response = await client
        .from('communication_templates')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return CommunicationTemplate.fromJson(response);
  }

  Future<CommunicationTemplate> createTemplate(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['created_by'] = requireUserId;

    final response = await client
        .from('communication_templates')
        .insert(data)
        .select()
        .single();

    return CommunicationTemplate.fromJson(response);
  }

  Future<CommunicationTemplate> updateTemplate(
      String id, Map<String, dynamic> data) async {
    final response = await client
        .from('communication_templates')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return CommunicationTemplate.fromJson(response);
  }

  Future<void> deleteTemplate(String id) async {
    await client.from('communication_templates').delete().eq('id', id);
  }

  Future<void> toggleTemplate(String id, bool active) async {
    await client
        .from('communication_templates')
        .update({'is_active': active}).eq('id', id);
  }

  // ============================================================
  // Campaigns
  // ============================================================

  Future<List<CommunicationCampaign>> getCampaigns({
    CampaignStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('communication_campaigns')
        .select('*, users!created_by(id, full_name)')
        .eq('tenant_id', requireTenantId);

    if (status != null) {
      query = query.eq('status', status.value);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => CommunicationCampaign.fromJson(json))
        .toList();
  }

  Future<CommunicationCampaign?> getCampaignById(String id) async {
    final response = await client
        .from('communication_campaigns')
        .select('*, users!created_by(id, full_name)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return CommunicationCampaign.fromJson(response);
  }

  Future<CommunicationCampaign> createCampaign(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['created_by'] = requireUserId;

    final response = await client
        .from('communication_campaigns')
        .insert(data)
        .select('*, users!created_by(id, full_name)')
        .single();

    return CommunicationCampaign.fromJson(response);
  }

  Future<CommunicationCampaign> updateCampaign(
      String id, Map<String, dynamic> data) async {
    final response = await client
        .from('communication_campaigns')
        .update(data)
        .eq('id', id)
        .select('*, users!created_by(id, full_name)')
        .single();

    return CommunicationCampaign.fromJson(response);
  }

  Future<void> deleteCampaign(String id) async {
    await client.from('communication_campaigns').delete().eq('id', id);
  }

  /// Send a campaign by changing its status and creating recipient records
  Future<CommunicationCampaign> sendCampaign(String campaignId) async {
    // Update campaign status
    final campaign = await updateCampaign(campaignId, {
      'status': CampaignStatus.sending.value,
      'sent_at': DateTime.now().toIso8601String(),
    });

    // Resolve target users based on target_type and target_filter
    final userIds = await _resolveTargetUsers(
      campaign.targetType,
      campaign.targetFilter,
    );

    // Create recipient records for each user and channel
    final recipientRecords = <Map<String, dynamic>>[];
    for (final userId in userIds) {
      for (final channel in campaign.channels) {
        recipientRecords.add({
          'campaign_id': campaignId,
          'user_id': userId,
          'channel': channel.value,
          'status': RecipientStatus.pending.value,
        });
      }
    }

    if (recipientRecords.isNotEmpty) {
      // Insert in batches of 100
      for (var i = 0; i < recipientRecords.length; i += 100) {
        final batch = recipientRecords.sublist(
          i,
          i + 100 > recipientRecords.length
              ? recipientRecords.length
              : i + 100,
        );
        await client.from('campaign_recipients').upsert(
          batch,
          onConflict: 'campaign_id,user_id,channel',
        );
      }
    }

    // Mark recipients as sent (simulating actual send)
    await client
        .from('campaign_recipients')
        .update({
          'status': RecipientStatus.sent.value,
          'sent_at': DateTime.now().toIso8601String(),
        })
        .eq('campaign_id', campaignId)
        .eq('status', RecipientStatus.pending.value);

    // Log the communication
    for (final userId in userIds) {
      await client.from('communication_log').insert({
        'tenant_id': requireTenantId,
        'user_id': userId,
        'campaign_id': campaignId,
        'channel': campaign.channels.first.value,
        'direction': CommunicationDirection.outbound.value,
        'content_preview': campaign.body.length > 200
            ? '${campaign.body.substring(0, 200)}...'
            : campaign.body,
        'status': RecipientStatus.sent.value,
      });
    }

    // Update campaign to sent
    return updateCampaign(campaignId, {
      'status': CampaignStatus.sent.value,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  /// Schedule a campaign for later sending
  Future<CommunicationCampaign> scheduleCampaign(
    String campaignId,
    DateTime scheduledAt,
  ) async {
    return updateCampaign(campaignId, {
      'status': CampaignStatus.scheduled.value,
      'scheduled_at': scheduledAt.toIso8601String(),
    });
  }

  /// Cancel a scheduled or draft campaign
  Future<CommunicationCampaign> cancelCampaign(String campaignId) async {
    return updateCampaign(campaignId, {
      'status': CampaignStatus.cancelled.value,
    });
  }

  /// Retry failed recipients in a campaign
  Future<void> retryFailedRecipients(String campaignId) async {
    await client
        .from('campaign_recipients')
        .update({
          'status': RecipientStatus.pending.value,
          'error_message': null,
        })
        .eq('campaign_id', campaignId)
        .eq('status', RecipientStatus.failed.value);

    // Re-send: mark as sent
    await client
        .from('campaign_recipients')
        .update({
          'status': RecipientStatus.sent.value,
          'sent_at': DateTime.now().toIso8601String(),
        })
        .eq('campaign_id', campaignId)
        .eq('status', RecipientStatus.pending.value);
  }

  Future<List<String>> _resolveTargetUsers(
    CampaignTargetType targetType,
    Map<String, dynamic> filter,
  ) async {
    switch (targetType) {
      case CampaignTargetType.all:
        final response = await client
            .from('users')
            .select('id')
            .eq('tenant_id', requireTenantId);
        return (response as List).map((r) => r['id'] as String).toList();

      case CampaignTargetType.parents:
        final response = await client
            .from('user_roles')
            .select('user_id')
            .eq('tenant_id', requireTenantId)
            .eq('role', 'parent');
        return (response as List).map((r) => r['user_id'] as String).toList();

      case CampaignTargetType.teachers:
        final response = await client
            .from('user_roles')
            .select('user_id')
            .eq('tenant_id', requireTenantId)
            .eq('role', 'teacher');
        return (response as List).map((r) => r['user_id'] as String).toList();

      case CampaignTargetType.staff:
        final response = await client
            .from('user_roles')
            .select('user_id')
            .eq('tenant_id', requireTenantId)
            .inFilter('role', [
          'accountant',
          'librarian',
          'transport_manager',
          'hostel_warden',
          'canteen_staff',
          'receptionist'
        ]);
        return (response as List).map((r) => r['user_id'] as String).toList();

      case CampaignTargetType.classTarget:
        final classIds = filter['class_ids'] as List? ?? [];
        if (classIds.isEmpty) return [];
        final response = await client
            .from('student_enrollments')
            .select('students!inner(user_id), sections!inner(class_id)')
            .inFilter('sections.class_id', classIds);
        return (response as List)
            .map((r) => (r['students'] as Map?)?['user_id'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toSet()
            .toList();

      case CampaignTargetType.section:
        final sectionIds = filter['section_ids'] as List? ?? [];
        if (sectionIds.isEmpty) return [];
        final response = await client
            .from('student_enrollments')
            .select('students!inner(user_id)')
            .inFilter('section_id', sectionIds);
        return (response as List)
            .map((r) => (r['students'] as Map?)?['user_id'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toSet()
            .toList();

      case CampaignTargetType.individual:
        return (filter['user_ids'] as List? ?? []).cast<String>();

      case CampaignTargetType.custom:
        // Custom filter: combine role + class criteria
        final roles = filter['roles'] as List? ?? [];
        if (roles.isEmpty) return [];
        final response = await client
            .from('user_roles')
            .select('user_id')
            .eq('tenant_id', requireTenantId)
            .inFilter('role', roles);
        return (response as List)
            .map((r) => r['user_id'] as String)
            .toSet()
            .toList();
    }
  }

  // ============================================================
  // Campaign Recipients / Delivery Report
  // ============================================================

  Future<List<CampaignRecipient>> getCampaignRecipients(
    String campaignId, {
    RecipientStatus? status,
    int limit = 100,
    int offset = 0,
  }) async {
    var query = client
        .from('campaign_recipients')
        .select('*, users(id, full_name, email)')
        .eq('campaign_id', campaignId);

    if (status != null) {
      query = query.eq('status', status.value);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => CampaignRecipient.fromJson(json))
        .toList();
  }

  Future<CampaignStats> getCampaignStats(String campaignId) async {
    final response = await client
        .from('communication_campaigns')
        .select('stats')
        .eq('id', campaignId)
        .single();

    return CampaignStats.fromJson(
        (response['stats'] as Map<String, dynamic>?) ?? {});
  }

  // ============================================================
  // Communication Log
  // ============================================================

  Future<List<CommunicationLog>> getCommunicationLog(
      CommunicationLogFilter filter) async {
    var query = client
        .from('communication_log')
        .select('*, users(id, full_name)')
        .eq('tenant_id', requireTenantId);

    if (filter.channel != null) {
      query = query.eq('channel', filter.channel!.value);
    }
    if (filter.direction != null) {
      query = query.eq('direction', filter.direction!.value);
    }
    if (filter.status != null) {
      query = query.eq('status', filter.status!.value);
    }
    if (filter.userId != null) {
      query = query.eq('user_id', filter.userId!);
    }
    if (filter.campaignId != null) {
      query = query.eq('campaign_id', filter.campaignId!);
    }
    if (filter.fromDate != null) {
      query = query.gte('created_at', filter.fromDate!.toIso8601String());
    }
    if (filter.toDate != null) {
      query = query.lte('created_at', filter.toDate!.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(filter.offset, filter.offset + filter.limit - 1);

    return (response as List)
        .map((json) => CommunicationLog.fromJson(json))
        .toList();
  }

  Future<int> getCommunicationLogCount({
    CommunicationChannel? channel,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = client
        .from('communication_log')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .eq('direction', CommunicationDirection.outbound.value);

    if (channel != null) {
      query = query.eq('channel', channel.value);
    }
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }

    final response = await query;
    return (response as List).length;
  }

  // ============================================================
  // Auto Notification Rules
  // ============================================================

  Future<List<AutoNotificationRule>> getAutoRules({
    bool? activeOnly,
  }) async {
    var query = client
        .from('auto_notification_rules')
        .select()
        .eq('tenant_id', requireTenantId);

    if (activeOnly == true) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('trigger_event');

    return (response as List)
        .map((json) => AutoNotificationRule.fromJson(json))
        .toList();
  }

  Future<AutoNotificationRule?> getAutoRuleById(String id) async {
    final response = await client
        .from('auto_notification_rules')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return AutoNotificationRule.fromJson(response);
  }

  Future<AutoNotificationRule> createAutoRule(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['created_by'] = requireUserId;

    final response = await client
        .from('auto_notification_rules')
        .insert(data)
        .select()
        .single();

    return AutoNotificationRule.fromJson(response);
  }

  Future<AutoNotificationRule> updateAutoRule(
      String id, Map<String, dynamic> data) async {
    final response = await client
        .from('auto_notification_rules')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return AutoNotificationRule.fromJson(response);
  }

  Future<void> deleteAutoRule(String id) async {
    await client.from('auto_notification_rules').delete().eq('id', id);
  }

  Future<void> toggleAutoRule(String id, bool active) async {
    await client
        .from('auto_notification_rules')
        .update({'is_active': active}).eq('id', id);
  }

  // ============================================================
  // SMS Gateway Config
  // ============================================================

  Future<SmsConfig?> getSmsConfig() async {
    final response = await client
        .from('sms_gateway_config')
        .select()
        .eq('tenant_id', requireTenantId)
        .maybeSingle();

    if (response == null) return null;
    return SmsConfig.fromJson(response);
  }

  Future<SmsConfig> upsertSmsConfig(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final existing = await getSmsConfig();
    if (existing != null) {
      final response = await client
          .from('sms_gateway_config')
          .update(data)
          .eq('id', existing.id)
          .select()
          .single();
      return SmsConfig.fromJson(response);
    } else {
      final response = await client
          .from('sms_gateway_config')
          .insert(data)
          .select()
          .single();
      return SmsConfig.fromJson(response);
    }
  }

  // ============================================================
  // Email Config
  // ============================================================

  Future<EmailConfig?> getEmailConfig() async {
    final response = await client
        .from('email_config')
        .select()
        .eq('tenant_id', requireTenantId)
        .maybeSingle();

    if (response == null) return null;
    return EmailConfig.fromJson(response);
  }

  Future<EmailConfig> upsertEmailConfig(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final existing = await getEmailConfig();
    if (existing != null) {
      final response = await client
          .from('email_config')
          .update(data)
          .eq('id', existing.id)
          .select()
          .single();
      return EmailConfig.fromJson(response);
    } else {
      final response = await client
          .from('email_config')
          .insert(data)
          .select()
          .single();
      return EmailConfig.fromJson(response);
    }
  }

  // ============================================================
  // Dashboard Stats
  // ============================================================

  Future<CommunicationDashboardStats> getDashboardStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    // Fetch counts in parallel using separate queries
    final countResults = await Future.wait([
      getCommunicationLogCount(fromDate: todayStart),
      getCommunicationLogCount(fromDate: weekStart),
      getCommunicationLogCount(fromDate: monthStart),
    ]);

    final sentToday = countResults[0];
    final sentWeek = countResults[1];
    final sentMonth = countResults[2];

    final activeCampaignsList = await client
        .from('communication_campaigns')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .inFilter('status', ['sending', 'sent']);

    final scheduledCampaignsList = await client
        .from('communication_campaigns')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .eq('status', CampaignStatus.scheduled.value);

    final activeRulesList = await client
        .from('auto_notification_rules')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .eq('is_active', true);

    final activeCampaigns = (activeCampaignsList as List).length;
    final scheduledCampaigns = (scheduledCampaignsList as List).length;
    final activeRules = (activeRulesList as List).length;

    // Channel breakdown for this month
    final channelBreakdown = <String, int>{};
    for (final channel in CommunicationChannel.values) {
      final count = await getCommunicationLogCount(
        channel: channel,
        fromDate: monthStart,
      );
      if (count > 0) {
        channelBreakdown[channel.label] = count;
      }
    }

    // Delivery rate from recent campaigns
    double deliveryRate = 0;
    double readRate = 0;
    final recentCampaigns = await getCampaigns(
      status: CampaignStatus.sent,
      limit: 10,
    );
    if (recentCampaigns.isNotEmpty) {
      final totalDeliveryRates = recentCampaigns
          .map((c) => c.stats.deliveryRate)
          .reduce((a, b) => a + b);
      deliveryRate = totalDeliveryRates / recentCampaigns.length;

      final totalReadRates = recentCampaigns
          .map((c) => c.stats.readRate)
          .reduce((a, b) => a + b);
      readRate = totalReadRates / recentCampaigns.length;
    }

    return CommunicationDashboardStats(
      sentToday: sentToday,
      sentThisWeek: sentWeek,
      sentThisMonth: sentMonth,
      deliveryRate: deliveryRate,
      readRate: readRate,
      channelBreakdown: channelBreakdown,
      activeCampaigns: activeCampaigns,
      scheduledCampaigns: scheduledCampaigns,
      activeRules: activeRules,
    );
  }

  // ============================================================
  // Realtime
  // ============================================================

  RealtimeChannel subscribeToCampaigns({
    required void Function(PostgresChangePayload) onUpdate,
  }) {
    return subscribeToTable(
      'communication_campaigns',
      filter: (column: 'tenant_id', value: requireTenantId),
      onInsert: onUpdate,
      onUpdate: onUpdate,
    );
  }
}
