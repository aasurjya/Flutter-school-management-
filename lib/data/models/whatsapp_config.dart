// ============================================================
// WhatsApp & SMS Integration Models
// ============================================================

enum SmsProvider {
  twilio('twilio', 'Twilio'),
  africasTalking('africas_talking', "Africa's Talking"),
  vonage('vonage', 'Vonage'),
  awsSns('aws_sns', 'AWS SNS');

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

enum NotificationChannel {
  whatsapp('whatsapp', 'WhatsApp'),
  sms('sms', 'SMS'),
  email('email', 'Email'),
  push('push', 'Push');

  final String value;
  final String label;
  const NotificationChannel(this.value, this.label);

  static NotificationChannel fromString(String value) {
    return NotificationChannel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationChannel.sms,
    );
  }
}

enum NotificationStatus {
  sent('sent', 'Sent'),
  delivered('delivered', 'Delivered'),
  failed('failed', 'Failed'),
  pending('pending', 'Pending');

  final String value;
  final String label;
  const NotificationStatus(this.value, this.label);

  static NotificationStatus fromString(String value) {
    return NotificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationStatus.pending,
    );
  }
}

// ============================================================
// WhatsAppConfig — tenant-level WhatsApp + SMS gateway config
// ============================================================

class WhatsAppConfig {
  final String? id;
  final String tenantId;
  final bool whatsappEnabled;
  final String? whatsappApiKey;
  final String? whatsappPhoneNumberId;
  final String? whatsappBusinessAccountId;
  final bool smsEnabled;
  final SmsProvider? smsProvider;
  final String? smsApiKey;
  final String? smsSenderId;
  final bool autoAttendanceNotify;
  final bool autoFeeNotify;
  final bool autoResultNotify;
  final bool autoAbsenceNotify;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WhatsAppConfig({
    this.id,
    required this.tenantId,
    this.whatsappEnabled = false,
    this.whatsappApiKey,
    this.whatsappPhoneNumberId,
    this.whatsappBusinessAccountId,
    this.smsEnabled = false,
    this.smsProvider,
    this.smsApiKey,
    this.smsSenderId,
    this.autoAttendanceNotify = true,
    this.autoFeeNotify = true,
    this.autoResultNotify = true,
    this.autoAbsenceNotify = true,
    this.createdAt,
    this.updatedAt,
  });

  factory WhatsAppConfig.fromJson(Map<String, dynamic> json) {
    return WhatsAppConfig(
      id: json['id'] as String?,
      tenantId: json['tenant_id'] as String,
      whatsappEnabled: json['whatsapp_enabled'] as bool? ?? false,
      whatsappApiKey: json['whatsapp_api_key'] as String?,
      whatsappPhoneNumberId: json['whatsapp_phone_number_id'] as String?,
      whatsappBusinessAccountId:
          json['whatsapp_business_account_id'] as String?,
      smsEnabled: json['sms_enabled'] as bool? ?? false,
      smsProvider: json['sms_provider'] != null
          ? SmsProvider.fromString(json['sms_provider'] as String)
          : null,
      smsApiKey: json['sms_api_key'] as String?,
      smsSenderId: json['sms_sender_id'] as String?,
      autoAttendanceNotify:
          json['auto_attendance_notify'] as bool? ?? true,
      autoFeeNotify: json['auto_fee_notify'] as bool? ?? true,
      autoResultNotify: json['auto_result_notify'] as bool? ?? true,
      autoAbsenceNotify: json['auto_absence_notify'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tenant_id': tenantId,
      'whatsapp_enabled': whatsappEnabled,
      'whatsapp_api_key': whatsappApiKey,
      'whatsapp_phone_number_id': whatsappPhoneNumberId,
      'whatsapp_business_account_id': whatsappBusinessAccountId,
      'sms_enabled': smsEnabled,
      'sms_provider': smsProvider?.value,
      'sms_api_key': smsApiKey,
      'sms_sender_id': smsSenderId,
      'auto_attendance_notify': autoAttendanceNotify,
      'auto_fee_notify': autoFeeNotify,
      'auto_result_notify': autoResultNotify,
      'auto_absence_notify': autoAbsenceNotify,
    };
  }

  WhatsAppConfig copyWith({
    String? id,
    String? tenantId,
    bool? whatsappEnabled,
    String? whatsappApiKey,
    String? whatsappPhoneNumberId,
    String? whatsappBusinessAccountId,
    bool? smsEnabled,
    SmsProvider? smsProvider,
    String? smsApiKey,
    String? smsSenderId,
    bool? autoAttendanceNotify,
    bool? autoFeeNotify,
    bool? autoResultNotify,
    bool? autoAbsenceNotify,
  }) {
    return WhatsAppConfig(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      whatsappApiKey: whatsappApiKey ?? this.whatsappApiKey,
      whatsappPhoneNumberId:
          whatsappPhoneNumberId ?? this.whatsappPhoneNumberId,
      whatsappBusinessAccountId:
          whatsappBusinessAccountId ?? this.whatsappBusinessAccountId,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      smsProvider: smsProvider ?? this.smsProvider,
      smsApiKey: smsApiKey ?? this.smsApiKey,
      smsSenderId: smsSenderId ?? this.smsSenderId,
      autoAttendanceNotify: autoAttendanceNotify ?? this.autoAttendanceNotify,
      autoFeeNotify: autoFeeNotify ?? this.autoFeeNotify,
      autoResultNotify: autoResultNotify ?? this.autoResultNotify,
      autoAbsenceNotify: autoAbsenceNotify ?? this.autoAbsenceNotify,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isConfigured =>
      (whatsappEnabled &&
          whatsappApiKey != null &&
          whatsappApiKey!.isNotEmpty) ||
      (smsEnabled && smsApiKey != null && smsApiKey!.isNotEmpty);
}

// ============================================================
// NotificationLog — delivery audit record
// ============================================================

class NotificationLog {
  final String id;
  final String tenantId;
  final NotificationChannel channel;
  final String? recipientPhone;
  final String? recipientName;
  final String? messageTemplate;
  final String? messageBody;
  final NotificationStatus status;
  final String? errorMessage;
  final String? triggeredBy;
  final DateTime? sentAt;

  const NotificationLog({
    required this.id,
    required this.tenantId,
    required this.channel,
    this.recipientPhone,
    this.recipientName,
    this.messageTemplate,
    this.messageBody,
    this.status = NotificationStatus.sent,
    this.errorMessage,
    this.triggeredBy,
    this.sentAt,
  });

  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    return NotificationLog(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      channel: NotificationChannel.fromString(json['channel'] as String),
      recipientPhone: json['recipient_phone'] as String?,
      recipientName: json['recipient_name'] as String?,
      messageTemplate: json['message_template'] as String?,
      messageBody: json['message_body'] as String?,
      status: NotificationStatus.fromString(
        json['status'] as String? ?? 'sent',
      ),
      errorMessage: json['error_message'] as String?,
      triggeredBy: json['triggered_by'] as String?,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'channel': channel.value,
      'recipient_phone': recipientPhone,
      'recipient_name': recipientName,
      'message_template': messageTemplate,
      'message_body': messageBody,
      'status': status.value,
      'error_message': errorMessage,
      'triggered_by': triggeredBy,
      'sent_at': sentAt?.toIso8601String(),
    };
  }
}
