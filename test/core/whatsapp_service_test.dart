// Test: WhatsAppResult model + WhatsAppService result parsing.
//
// Phase 3.3 — critical flow test #3: WhatsApp notification flow.
// Verifies the result classification (success, plan-blocked, not-configured)
// that the notification helper depends on to decide whether to retry or
// silently skip.

import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/services/whatsapp_service.dart';

void main() {
  group('WhatsAppResult', () {
    test('success result has messageId', () {
      final r = WhatsAppResult(
        success: true,
        messageId: 'wamid.HBgL...',
        reason: 'ok',
        statusCode: 200,
      );
      expect(r.success, isTrue);
      expect(r.messageId, isNotNull);
      expect(r.isPlanBlocked, isFalse);
      expect(r.isNotConfigured, isFalse);
    });

    test('plan-blocked result is detected', () {
      final r = const WhatsAppResult(
        success: false,
        reason: 'whatsapp_not_in_plan',
        statusCode: 402,
      );
      expect(r.success, isFalse);
      expect(r.isPlanBlocked, isTrue);
      expect(r.isNotConfigured, isFalse);
    });

    test('not-configured result is detected', () {
      final r = const WhatsAppResult(
        success: false,
        reason: 'whatsapp_not_configured',
        statusCode: 404,
      );
      expect(r.success, isFalse);
      expect(r.isPlanBlocked, isFalse);
      expect(r.isNotConfigured, isTrue);
    });

    test('disabled result is detected as not-configured', () {
      final r = const WhatsAppResult(
        success: false,
        reason: 'whatsapp_disabled_or_incomplete',
        statusCode: 400,
      );
      expect(r.isNotConfigured, isTrue);
    });

    test('network error result is neither plan-blocked nor not-configured', () {
      final r = const WhatsAppResult(
        success: false,
        reason: 'network_error',
      );
      expect(r.isPlanBlocked, isFalse);
      expect(r.isNotConfigured, isFalse);
    });

    test('meta API error is neither plan-blocked nor not-configured', () {
      final r = const WhatsAppResult(
        success: false,
        reason: 'meta_api_error',
        statusCode: 400,
      );
      expect(r.isPlanBlocked, isFalse);
      expect(r.isNotConfigured, isFalse);
    });
  });
}
