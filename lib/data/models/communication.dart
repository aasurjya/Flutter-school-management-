// ============================================================
// Communication Hub Models
// ============================================================

// --- Enums ---

enum TemplateCategory {
  feeReminder('fee_reminder', 'Fee Reminder'),
  attendanceAlert('attendance_alert', 'Attendance Alert'),
  examNotice('exam_notice', 'Exam Notice'),
  eventInvite('event_invite', 'Event Invite'),
  general('general', 'General'),
  emergency('emergency', 'Emergency');

  final String value;
  final String label;
  const TemplateCategory(this.value, this.label);

  static TemplateCategory fromString(String value) {
    return TemplateCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TemplateCategory.general,
    );
  }
}

enum CommunicationChannel {
  sms('sms', 'SMS', 'Short message service'),
  email('email', 'Email', 'Electronic mail'),
  push('push', 'Push', 'Push notification'),
  inApp('in_app', 'In-App', 'In-app notification'),
  whatsapp('whatsapp', 'WhatsApp', 'WhatsApp message');

  final String value;
  final String label;
  final String description;
  const CommunicationChannel(this.value, this.label, this.description);

  static CommunicationChannel fromString(String value) {
    return CommunicationChannel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CommunicationChannel.inApp,
    );
  }
}

enum CampaignStatus {
  draft('draft', 'Draft'),
  scheduled('scheduled', 'Scheduled'),
  sending('sending', 'Sending'),
  sent('sent', 'Sent'),
  failed('failed', 'Failed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;
  const CampaignStatus(this.value, this.label);

  static CampaignStatus fromString(String value) {
    return CampaignStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CampaignStatus.draft,
    );
  }
}

enum RecipientStatus {
  pending('pending', 'Pending'),
  sent('sent', 'Sent'),
  delivered('delivered', 'Delivered'),
  read('read', 'Read'),
  failed('failed', 'Failed');

  final String value;
  final String label;
  const RecipientStatus(this.value, this.label);

  static RecipientStatus fromString(String value) {
    return RecipientStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RecipientStatus.pending,
    );
  }
}

enum CampaignTargetType {
  all('all', 'All Users'),
  classTarget('class', 'By Class'),
  section('section', 'By Section'),
  individual('individual', 'Individual'),
  parents('parents', 'All Parents'),
  teachers('teachers', 'All Teachers'),
  staff('staff', 'All Staff'),
  custom('custom', 'Custom');

  final String value;
  final String label;
  const CampaignTargetType(this.value, this.label);

  static CampaignTargetType fromString(String value) {
    return CampaignTargetType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CampaignTargetType.all,
    );
  }
}

enum SmsProvider {
  twilio('twilio', 'Twilio'),
  africastalking('africastalking', 'Africa\'s Talking'),
  msg91('msg91', 'MSG91'),
  textlocal('textlocal', 'TextLocal');

  final String value;
  final String label;
  const SmsProvider(this.value, this.label);

  static SmsProvider fromString(String value) {
    return SmsProvider.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SmsProvider.twilio,
    );
  }
}

enum EmailProvider {
  sendgrid('sendgrid', 'SendGrid'),
  ses('ses', 'Amazon SES'),
  smtp('smtp', 'SMTP'),
  mailgun('mailgun', 'Mailgun');

  final String value;
  final String label;
  const EmailProvider(this.value, this.label);

  static EmailProvider fromString(String value) {
    return EmailProvider.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EmailProvider.smtp,
    );
  }
}

enum CommunicationDirection {
  inbound('inbound', 'Inbound'),
  outbound('outbound', 'Outbound');

  final String value;
  final String label;
  const CommunicationDirection(this.value, this.label);

  static CommunicationDirection fromString(String value) {
    return CommunicationDirection.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CommunicationDirection.outbound,
    );
  }
}

enum TriggerEvent {
  absentMarked('absent_marked', 'Absent Marked'),
  feeOverdue('fee_overdue', 'Fee Overdue'),
  examPublished('exam_published', 'Exam Published'),
  assignmentDue('assignment_due', 'Assignment Due'),
  lowGrade('low_grade', 'Low Grade'),
  birthday('birthday', 'Birthday'),
  feePaymentReceived('fee_payment_received', 'Fee Payment Received'),
  reportCardPublished('report_card_published', 'Report Card Published'),
  ptmScheduled('ptm_scheduled', 'PTM Scheduled'),
  emergencyAlert('emergency_alert', 'Emergency Alert');

  final String value;
  final String label;
  const TriggerEvent(this.value, this.label);

  static TriggerEvent fromString(String value) {
    return TriggerEvent.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TriggerEvent.absentMarked,
    );
  }
}

// --- Models ---

class CommunicationTemplate {
  final String id;
  final String tenantId;
  final String name;
  final TemplateCategory category;
  final String? subject;
  final String bodyTemplate;
  final List<String> variables;
  final CommunicationChannel channel;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CommunicationTemplate({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.category,
    this.subject,
    required this.bodyTemplate,
    this.variables = const [],
    required this.channel,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory CommunicationTemplate.fromJson(Map<String, dynamic> json) {
    final rawVars = json['variables'];
    List<String> parsedVars = [];
    if (rawVars is List) {
      parsedVars = rawVars.map((e) => e.toString()).toList();
    }

    return CommunicationTemplate(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      category: TemplateCategory.fromString(json['category'] as String? ?? 'general'),
      subject: json['subject'] as String?,
      bodyTemplate: json['body_template'] as String,
      variables: parsedVars,
      channel: CommunicationChannel.fromString(json['channel'] as String? ?? 'in_app'),
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'category': category.value,
      'subject': subject,
      'body_template': bodyTemplate,
      'variables': variables,
      'channel': channel.value,
      'is_active': isActive,
      'created_by': createdBy,
    };
  }

  CommunicationTemplate copyWith({
    String? id,
    String? tenantId,
    String? name,
    TemplateCategory? category,
    String? subject,
    String? bodyTemplate,
    List<String>? variables,
    CommunicationChannel? channel,
    bool? isActive,
    String? createdBy,
  }) {
    return CommunicationTemplate(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      variables: variables ?? this.variables,
      channel: channel ?? this.channel,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Render template body replacing {{variable}} placeholders with values
  String renderBody(Map<String, String> values) {
    String rendered = bodyTemplate;
    for (final entry in values.entries) {
      rendered = rendered.replaceAll('{{${entry.key}}}', entry.value);
    }
    return rendered;
  }

  /// Render template subject replacing {{variable}} placeholders with values
  String? renderSubject(Map<String, String> values) {
    if (subject == null) return null;
    String rendered = subject!;
    for (final entry in values.entries) {
      rendered = rendered.replaceAll('{{${entry.key}}}', entry.value);
    }
    return rendered;
  }
}

class CampaignStats {
  final int total;
  final int sent;
  final int delivered;
  final int read;
  final int failed;

  const CampaignStats({
    this.total = 0,
    this.sent = 0,
    this.delivered = 0,
    this.read = 0,
    this.failed = 0,
  });

  factory CampaignStats.fromJson(Map<String, dynamic> json) {
    return CampaignStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      sent: (json['sent'] as num?)?.toInt() ?? 0,
      delivered: (json['delivered'] as num?)?.toInt() ?? 0,
      read: (json['read'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'sent': sent,
        'delivered': delivered,
        'read': read,
        'failed': failed,
      };

  double get deliveryRate => total > 0 ? (delivered / total) * 100 : 0;
  double get readRate => delivered > 0 ? (read / delivered) * 100 : 0;
  int get pending => total - sent - failed;
}

class CommunicationCampaign {
  final String id;
  final String tenantId;
  final String name;
  final String? templateId;
  final String? subject;
  final String body;
  final CampaignTargetType targetType;
  final Map<String, dynamic> targetFilter;
  final List<CommunicationChannel> channels;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? completedAt;
  final CampaignStatus status;
  final CampaignStats stats;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined data
  final String? createdByName;
  final CommunicationTemplate? template;

  const CommunicationCampaign({
    required this.id,
    required this.tenantId,
    required this.name,
    this.templateId,
    this.subject,
    required this.body,
    required this.targetType,
    this.targetFilter = const {},
    this.channels = const [CommunicationChannel.inApp],
    this.scheduledAt,
    this.sentAt,
    this.completedAt,
    required this.status,
    this.stats = const CampaignStats(),
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.createdByName,
    this.template,
  });

  factory CommunicationCampaign.fromJson(Map<String, dynamic> json) {
    // Parse channels
    final rawChannels = json['channels'];
    List<CommunicationChannel> parsedChannels = [CommunicationChannel.inApp];
    if (rawChannels is List) {
      parsedChannels = rawChannels
          .map((e) => CommunicationChannel.fromString(e.toString()))
          .toList();
    }

    // Parse stats
    CampaignStats parsedStats = const CampaignStats();
    if (json['stats'] is Map<String, dynamic>) {
      parsedStats = CampaignStats.fromJson(json['stats'] as Map<String, dynamic>);
    }

    // Parse joined user name
    String? createdByName;
    if (json['users'] is Map<String, dynamic>) {
      createdByName = (json['users'] as Map<String, dynamic>)['full_name'] as String?;
    }

    return CommunicationCampaign(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      templateId: json['template_id'] as String?,
      subject: json['subject'] as String?,
      body: json['body'] as String? ?? '',
      targetType: CampaignTargetType.fromString(json['target_type'] as String? ?? 'all'),
      targetFilter: (json['target_filter'] as Map<String, dynamic>?) ?? {},
      channels: parsedChannels,
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String) : null,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      status: CampaignStatus.fromString(json['status'] as String? ?? 'draft'),
      stats: parsedStats,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      createdByName: createdByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'template_id': templateId,
      'subject': subject,
      'body': body,
      'target_type': targetType.value,
      'target_filter': targetFilter,
      'channels': channels.map((c) => c.value).toList(),
      'scheduled_at': scheduledAt?.toIso8601String(),
      'status': status.value,
      'created_by': createdBy,
    };
  }

  CommunicationCampaign copyWith({
    String? name,
    String? templateId,
    String? subject,
    String? body,
    CampaignTargetType? targetType,
    Map<String, dynamic>? targetFilter,
    List<CommunicationChannel>? channels,
    DateTime? scheduledAt,
    CampaignStatus? status,
  }) {
    return CommunicationCampaign(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      targetType: targetType ?? this.targetType,
      targetFilter: targetFilter ?? this.targetFilter,
      channels: channels ?? this.channels,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt,
      completedAt: completedAt,
      status: status ?? this.status,
      stats: stats,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdByName: createdByName,
      template: template,
    );
  }
}

class CampaignRecipient {
  final String id;
  final String campaignId;
  final String userId;
  final CommunicationChannel channel;
  final RecipientStatus status;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  // Joined data
  final String? userName;
  final String? userEmail;

  const CampaignRecipient({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.channel,
    required this.status,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.errorMessage,
    this.metadata = const {},
    this.createdAt,
    this.userName,
    this.userEmail,
  });

  factory CampaignRecipient.fromJson(Map<String, dynamic> json) {
    String? userName;
    String? userEmail;
    if (json['users'] is Map<String, dynamic>) {
      final user = json['users'] as Map<String, dynamic>;
      userName = user['full_name'] as String?;
      userEmail = user['email'] as String?;
    }

    return CampaignRecipient(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      userId: json['user_id'] as String,
      channel: CommunicationChannel.fromString(json['channel'] as String? ?? 'in_app'),
      status: RecipientStatus.fromString(json['status'] as String? ?? 'pending'),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      errorMessage: json['error_message'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      userName: userName,
      userEmail: userEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaign_id': campaignId,
      'user_id': userId,
      'channel': channel.value,
      'status': status.value,
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }
}

class SmsConfig {
  final String id;
  final String tenantId;
  final SmsProvider provider;
  final String? apiKeyEncrypted;
  final String? apiSecretEncrypted;
  final String? senderId;
  final bool isActive;
  final double balanceCredits;
  final Map<String, dynamic> config;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SmsConfig({
    required this.id,
    required this.tenantId,
    required this.provider,
    this.apiKeyEncrypted,
    this.apiSecretEncrypted,
    this.senderId,
    this.isActive = false,
    this.balanceCredits = 0,
    this.config = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory SmsConfig.fromJson(Map<String, dynamic> json) {
    return SmsConfig(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      provider: SmsProvider.fromString(json['provider'] as String? ?? 'twilio'),
      apiKeyEncrypted: json['api_key_encrypted'] as String?,
      apiSecretEncrypted: json['api_secret_encrypted'] as String?,
      senderId: json['sender_id'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      balanceCredits: (json['balance_credits'] as num?)?.toDouble() ?? 0,
      config: (json['config'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'provider': provider.value,
      'api_key_encrypted': apiKeyEncrypted,
      'api_secret_encrypted': apiSecretEncrypted,
      'sender_id': senderId,
      'is_active': isActive,
      'config': config,
    };
  }

  SmsConfig copyWith({
    SmsProvider? provider,
    String? apiKeyEncrypted,
    String? apiSecretEncrypted,
    String? senderId,
    bool? isActive,
    Map<String, dynamic>? config,
  }) {
    return SmsConfig(
      id: id,
      tenantId: tenantId,
      provider: provider ?? this.provider,
      apiKeyEncrypted: apiKeyEncrypted ?? this.apiKeyEncrypted,
      apiSecretEncrypted: apiSecretEncrypted ?? this.apiSecretEncrypted,
      senderId: senderId ?? this.senderId,
      isActive: isActive ?? this.isActive,
      balanceCredits: balanceCredits,
      config: config ?? this.config,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class EmailConfig {
  final String id;
  final String tenantId;
  final EmailProvider provider;
  final Map<String, dynamic> config;
  final String? fromEmail;
  final String? fromName;
  final bool isActive;
  final int dailyLimit;
  final int sentToday;
  final DateTime? lastResetAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EmailConfig({
    required this.id,
    required this.tenantId,
    required this.provider,
    this.config = const {},
    this.fromEmail,
    this.fromName,
    this.isActive = false,
    this.dailyLimit = 500,
    this.sentToday = 0,
    this.lastResetAt,
    this.createdAt,
    this.updatedAt,
  });

  factory EmailConfig.fromJson(Map<String, dynamic> json) {
    return EmailConfig(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      provider: EmailProvider.fromString(json['provider'] as String? ?? 'smtp'),
      config: (json['config'] as Map<String, dynamic>?) ?? {},
      fromEmail: json['from_email'] as String?,
      fromName: json['from_name'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? 500,
      sentToday: (json['sent_today'] as num?)?.toInt() ?? 0,
      lastResetAt: json['last_reset_at'] != null ? DateTime.parse(json['last_reset_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'provider': provider.value,
      'config': config,
      'from_email': fromEmail,
      'from_name': fromName,
      'is_active': isActive,
      'daily_limit': dailyLimit,
    };
  }

  EmailConfig copyWith({
    EmailProvider? provider,
    Map<String, dynamic>? config,
    String? fromEmail,
    String? fromName,
    bool? isActive,
    int? dailyLimit,
  }) {
    return EmailConfig(
      id: id,
      tenantId: tenantId,
      provider: provider ?? this.provider,
      config: config ?? this.config,
      fromEmail: fromEmail ?? this.fromEmail,
      fromName: fromName ?? this.fromName,
      isActive: isActive ?? this.isActive,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      sentToday: sentToday,
      lastResetAt: lastResetAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  int get remainingToday => dailyLimit - sentToday;
}

class CommunicationLog {
  final String id;
  final String tenantId;
  final String? userId;
  final String? campaignId;
  final CommunicationChannel channel;
  final CommunicationDirection direction;
  final String? recipientInfo;
  final String? contentPreview;
  final RecipientStatus status;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  // Joined data
  final String? userName;

  const CommunicationLog({
    required this.id,
    required this.tenantId,
    this.userId,
    this.campaignId,
    required this.channel,
    required this.direction,
    this.recipientInfo,
    this.contentPreview,
    required this.status,
    this.errorMessage,
    this.metadata = const {},
    this.createdAt,
    this.userName,
  });

  factory CommunicationLog.fromJson(Map<String, dynamic> json) {
    String? userName;
    if (json['users'] is Map<String, dynamic>) {
      userName = (json['users'] as Map<String, dynamic>)['full_name'] as String?;
    }

    return CommunicationLog(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      userId: json['user_id'] as String?,
      campaignId: json['campaign_id'] as String?,
      channel: CommunicationChannel.fromString(json['channel'] as String? ?? 'in_app'),
      direction: CommunicationDirection.fromString(json['direction'] as String? ?? 'outbound'),
      recipientInfo: json['recipient_info'] as String?,
      contentPreview: json['content_preview'] as String?,
      status: RecipientStatus.fromString(json['status'] as String? ?? 'pending'),
      errorMessage: json['error_message'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      userName: userName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'user_id': userId,
      'campaign_id': campaignId,
      'channel': channel.value,
      'direction': direction.value,
      'recipient_info': recipientInfo,
      'content_preview': contentPreview,
      'status': status.value,
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }
}

class AutoNotificationRule {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final TriggerEvent triggerEvent;
  final String? templateId;
  final List<CommunicationChannel> channels;
  final List<String> targetRoles;
  final Map<String, dynamic> conditions;
  final bool isActive;
  final int delayMinutes;
  final DateTime? lastTriggeredAt;
  final int triggerCount;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined data
  final CommunicationTemplate? template;

  const AutoNotificationRule({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.triggerEvent,
    this.templateId,
    this.channels = const [CommunicationChannel.push, CommunicationChannel.inApp],
    this.targetRoles = const ['parent'],
    this.conditions = const {},
    this.isActive = true,
    this.delayMinutes = 0,
    this.lastTriggeredAt,
    this.triggerCount = 0,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.template,
  });

  factory AutoNotificationRule.fromJson(Map<String, dynamic> json) {
    final rawChannels = json['channels'];
    List<CommunicationChannel> parsedChannels = [CommunicationChannel.push, CommunicationChannel.inApp];
    if (rawChannels is List) {
      parsedChannels = rawChannels
          .map((e) => CommunicationChannel.fromString(e.toString()))
          .toList();
    }

    final rawRoles = json['target_roles'];
    List<String> parsedRoles = ['parent'];
    if (rawRoles is List) {
      parsedRoles = rawRoles.map((e) => e.toString()).toList();
    }

    return AutoNotificationRule(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      triggerEvent: TriggerEvent.fromString(json['trigger_event'] as String? ?? 'absent_marked'),
      templateId: json['template_id'] as String?,
      channels: parsedChannels,
      targetRoles: parsedRoles,
      conditions: (json['conditions'] as Map<String, dynamic>?) ?? {},
      isActive: json['is_active'] as bool? ?? true,
      delayMinutes: (json['delay_minutes'] as num?)?.toInt() ?? 0,
      lastTriggeredAt: json['last_triggered_at'] != null
          ? DateTime.parse(json['last_triggered_at'] as String)
          : null,
      triggerCount: (json['trigger_count'] as num?)?.toInt() ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'trigger_event': triggerEvent.value,
      'template_id': templateId,
      'channels': channels.map((c) => c.value).toList(),
      'target_roles': targetRoles,
      'conditions': conditions,
      'is_active': isActive,
      'delay_minutes': delayMinutes,
      'created_by': createdBy,
    };
  }

  AutoNotificationRule copyWith({
    String? name,
    String? description,
    TriggerEvent? triggerEvent,
    String? templateId,
    List<CommunicationChannel>? channels,
    List<String>? targetRoles,
    Map<String, dynamic>? conditions,
    bool? isActive,
    int? delayMinutes,
  }) {
    return AutoNotificationRule(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      triggerEvent: triggerEvent ?? this.triggerEvent,
      templateId: templateId ?? this.templateId,
      channels: channels ?? this.channels,
      targetRoles: targetRoles ?? this.targetRoles,
      conditions: conditions ?? this.conditions,
      isActive: isActive ?? this.isActive,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      lastTriggeredAt: lastTriggeredAt,
      triggerCount: triggerCount,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      template: template,
    );
  }
}

/// Filter for communication log queries
class CommunicationLogFilter {
  final CommunicationChannel? channel;
  final CommunicationDirection? direction;
  final RecipientStatus? status;
  final String? userId;
  final String? campaignId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? searchQuery;
  final int limit;
  final int offset;

  const CommunicationLogFilter({
    this.channel,
    this.direction,
    this.status,
    this.userId,
    this.campaignId,
    this.fromDate,
    this.toDate,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunicationLogFilter &&
          other.channel == channel &&
          other.direction == direction &&
          other.status == status &&
          other.userId == userId &&
          other.campaignId == campaignId &&
          other.fromDate == fromDate &&
          other.toDate == toDate &&
          other.searchQuery == searchQuery &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(
        channel, direction, status, userId, campaignId,
        fromDate, toDate, searchQuery, limit, offset,
      );
}

/// Aggregated communication stats for the dashboard
class CommunicationDashboardStats {
  final int sentToday;
  final int sentThisWeek;
  final int sentThisMonth;
  final double deliveryRate;
  final double readRate;
  final Map<String, int> channelBreakdown;
  final int activeCampaigns;
  final int scheduledCampaigns;
  final int activeRules;

  const CommunicationDashboardStats({
    this.sentToday = 0,
    this.sentThisWeek = 0,
    this.sentThisMonth = 0,
    this.deliveryRate = 0,
    this.readRate = 0,
    this.channelBreakdown = const {},
    this.activeCampaigns = 0,
    this.scheduledCampaigns = 0,
    this.activeRules = 0,
  });
}
