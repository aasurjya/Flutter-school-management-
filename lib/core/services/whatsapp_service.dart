import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';

/// Talks to the `send-whatsapp` edge function (Meta WhatsApp Business Cloud API).
///
/// Phase 3.1 — competitive gap closer. Parents expect WhatsApp, not push.
/// This service sends template messages via the edge function, which:
///   1. Checks the tenant's plan has the `whatsapp` feature flag
///   2. Loads the tenant's Meta config from `sms_whatsapp_configs`
///   3. Calls Meta Cloud API
///   4. Logs the outcome to `notification_logs`
///
/// Template messages must be pre-approved in Meta Business Manager.
/// Common templates for school management:
///   - attendance_absence: "Dear parent, {{1}} was absent on {{2}}."
///   - fee_due: "Fee of ₹{{1}} is due on {{2}} for {{3}}."
///   - result_published: "{{1}}'s result for {{2}} is now available."
///   - ptm_reminder: "PTM scheduled on {{1}} at {{2}}."
class WhatsAppService {
  final SupabaseClient _client;

  WhatsAppService(this._client);

  /// Send a WhatsApp template message.
  ///
  /// [to] — E.164 phone number (e.g. "919876543210", no + prefix).
  /// [templateName] — pre-approved Meta template name.
  /// [languageCode] — template language (default "en").
  /// [components] — template variable components (per Meta API spec).
  /// [recipientName] — for logging in notification_logs.
  /// [triggeredBy] — event that triggered this (e.g. 'attendance_absence').
  Future<WhatsAppResult> send({
    required String to,
    required String templateName,
    String languageCode = 'en',
    List<Map<String, dynamic>>? components,
    String? recipientName,
    String? triggeredBy,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'send-whatsapp',
        method: HttpMethod.post,
        headers: {'Content-Type': 'application/json'},
        body: {
          'to': to,
          'templateName': templateName,
          'languageCode': languageCode,
          if (components != null) 'components': components,
          if (recipientName != null) 'recipientName': recipientName,
          if (triggeredBy != null) 'triggeredBy': triggeredBy,
        },
      );
      final data = res.data is String
          ? jsonDecode(res.data as String) as Map<String, dynamic>
          : res.data is Map
              ? Map<String, dynamic>.from(res.data as Map)
              : <String, dynamic>{};
      final ok = data['ok'] == true;
      return WhatsAppResult(
        success: ok,
        messageId: data['message_id'] as String?,
        reason: data['reason'] as String? ?? (ok ? 'ok' : 'unknown'),
        detail: data['detail'],
        statusCode: res.status,
      );
    } catch (e) {
      return WhatsAppResult(
        success: false,
        reason: 'network_error',
        detail: e.toString(),
      );
    }
  }

  /// Convenience: send an absence notification.
  Future<WhatsAppResult> sendAbsenceNotification({
    required String parentPhone,
    required String studentName,
    required String date,
  }) {
    return send(
      to: parentPhone,
      templateName: 'attendance_absence',
      triggeredBy: 'attendance_absence',
      recipientName: studentName,
      components: [
        {
          'type': 'body',
          'parameters': [
            {'type': 'text', 'text': studentName},
            {'type': 'text', 'text': date},
          ],
        },
      ],
    );
  }

  /// Convenience: send a fee-due notification.
  Future<WhatsAppResult> sendFeeDueNotification({
    required String parentPhone,
    required String studentName,
    required String amount,
    required String dueDate,
  }) {
    return send(
      to: parentPhone,
      templateName: 'fee_due',
      triggeredBy: 'fee_due',
      recipientName: studentName,
      components: [
        {
          'type': 'body',
          'parameters': [
            {'type': 'text', 'text': amount},
            {'type': 'text', 'text': dueDate},
            {'type': 'text', 'text': studentName},
          ],
        },
      ],
    );
  }

  /// Convenience: send a result-published notification.
  Future<WhatsAppResult> sendResultNotification({
    required String parentPhone,
    required String studentName,
    required String examName,
  }) {
    return send(
      to: parentPhone,
      templateName: 'result_published',
      triggeredBy: 'result_published',
      recipientName: studentName,
      components: [
        {
          'type': 'body',
          'parameters': [
            {'type': 'text', 'text': studentName},
            {'type': 'text', 'text': examName},
          ],
        },
      ],
    );
  }

  /// Convenience: send a PTM reminder.
  Future<WhatsAppResult> sendPtmReminder({
    required String parentPhone,
    required String studentName,
    required String date,
    required String time,
  }) {
    return send(
      to: parentPhone,
      templateName: 'ptm_reminder',
      triggeredBy: 'ptm_reminder',
      recipientName: studentName,
      components: [
        {
          'type': 'body',
          'parameters': [
            {'type': 'text', 'text': date},
            {'type': 'text', 'text': time},
          ],
        },
      ],
    );
  }
}

/// Result of a WhatsApp send attempt.
class WhatsAppResult {
  final bool success;
  final String? messageId;
  final String reason;
  final dynamic detail;
  final int? statusCode;

  const WhatsAppResult({
    required this.success,
    this.messageId,
    required this.reason,
    this.detail,
    this.statusCode,
  });

  /// True when the failure is due to plan limits (not a config/network issue).
  bool get isPlanBlocked => reason == 'whatsapp_not_in_plan';

  /// True when WhatsApp isn't configured for the tenant.
  bool get isNotConfigured =>
      reason == 'whatsapp_not_configured' ||
      reason == 'whatsapp_disabled_or_incomplete';
}

final whatsappServiceProvider = Provider<WhatsAppService>((ref) {
  return WhatsAppService(ref.watch(supabaseProvider));
});
