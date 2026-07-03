import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';
import 'whatsapp_service.dart';

/// Helper that wires WhatsApp notifications into domain events.
///
/// Phase 3.1 — called by providers/screens after a domain action completes
/// (attendance marked absent, fee invoice generated, result published, PTM
/// scheduled). It checks the tenant's `sms_whatsapp_configs.auto_*` flags
/// before sending, so schools that haven't enabled WhatsApp are silently
/// skipped.
///
/// This is intentionally a separate class from the domain providers so the
/// notification path can evolve (add SMS, email, batching) without touching
/// the attendance/fee/exam code.
class WhatsAppNotificationHelper {
  final SupabaseClient _client;
  final WhatsAppService _whatsapp;

  WhatsAppNotificationHelper(this._client, this._whatsapp);

  /// Check if a given auto-notify flag is enabled for the tenant.
  /// Returns false if WhatsApp isn't configured or the flag is off.
  Future<bool> _isAutoNotifyEnabled(String flagColumn) async {
    try {
      final tid = _client.auth.currentUser?.appMetadata['tenant_id'] as String?;
      if (tid == null) return false;
      final res = await _client
          .from('sms_whatsapp_configs')
          .select('whatsapp_enabled, $flagColumn')
          .eq('tenant_id', tid)
          .maybeSingle();
      if (res == null) return false;
      return res['whatsapp_enabled'] == true && res[flagColumn] == true;
    } catch (_) {
      return false;
    }
  }

  /// Send absence notifications to the parents of [studentId] for [date].
  /// Called after attendance is marked absent. Silently skips if:
  ///   - auto_absence_notify is disabled
  ///   - WhatsApp isn't configured
  ///   - The plan doesn't include WhatsApp
  ///   - No parent phone number found
  Future<void> notifyAbsence({
    required String studentId,
    required String studentName,
    required String date,
  }) async {
    if (!await _isAutoNotifyEnabled('auto_absence_notify')) return;

    final phones = await _getParentPhones(studentId);
    if (phones.isEmpty) return;

    for (final phone in phones) {
      await _whatsapp.sendAbsenceNotification(
        parentPhone: phone,
        studentName: studentName,
        date: date,
      );
    }
  }

  /// Send fee-due notifications to the parents of [studentId].
  Future<void> notifyFeeDue({
    required String studentId,
    required String studentName,
    required String amount,
    required String dueDate,
  }) async {
    if (!await _isAutoNotifyEnabled('auto_fee_notify')) return;

    final phones = await _getParentPhones(studentId);
    if (phones.isEmpty) return;

    for (final phone in phones) {
      await _whatsapp.sendFeeDueNotification(
        parentPhone: phone,
        studentName: studentName,
        amount: amount,
        dueDate: dueDate,
      );
    }
  }

  /// Send result-published notifications to the parents of [studentId].
  Future<void> notifyResultPublished({
    required String studentId,
    required String studentName,
    required String examName,
  }) async {
    if (!await _isAutoNotifyEnabled('auto_result_notify')) return;

    final phones = await _getParentPhones(studentId);
    if (phones.isEmpty) return;

    for (final phone in phones) {
      await _whatsapp.sendResultNotification(
        parentPhone: phone,
        studentName: studentName,
        examName: examName,
      );
    }
  }

  /// Fetch the primary parent phone numbers for a student.
  /// Returns E.164-formatted numbers (strips leading +).
  Future<List<String>> _getParentPhones(String studentId) async {
    try {
      final res = await _client
          .from('student_parents')
          .select('is_primary, parents(phone)')
          .eq('student_id', studentId)
          .eq('is_primary', true);
      final phones = <String>[];
      for (final row in res as List) {
        final parents = (row as Map<String, dynamic>)['parents'];
        final phone = (parents as Map<String, dynamic>?)?['phone'] as String?;
        if (phone != null && phone.isNotEmpty) {
          phones.add(phone.replaceAll(RegExp(r'[^\d]'), ''));
        }
      }
      return phones;
    } catch (_) {
      return const [];
    }
  }
}

final whatsappNotificationHelperProvider = Provider<WhatsAppNotificationHelper>(
  (ref) {
    return WhatsAppNotificationHelper(
      ref.watch(supabaseProvider),
      ref.watch(whatsappServiceProvider),
    );
  },
);
