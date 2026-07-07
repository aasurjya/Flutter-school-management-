// Test: Subscription plan model + verdict parsing.
//
// Phase 3.3 — critical flow test #1: subscription enforcement.
// Verifies that the plan catalog model + verdict from the edge function
// parse correctly, since the SubscriptionGuard depends on these to decide
// whether to show the upgrade prompt.

import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/data/models/subscription_plan.dart';

void main() {
  group('SubscriptionPlan', () {
    test('parses free plan from JSON', () {
      final json = {
        'id': 'free',
        'display_name': 'Free',
        'price_inr_paise': 0,
        'billing_period': 'yearly',
        'max_students': 100,
        'ai_credits_usd': 0.5,
        'feature_flags': {
          'ai_basic': true,
          'whatsapp': false,
          'advanced_reports': false,
        },
        'is_active': true,
        'sort_order': 0,
      };
      final plan = SubscriptionPlan.fromJson(json);

      expect(plan.id, 'free');
      expect(plan.displayName, 'Free');
      expect(plan.priceInrPaise, 0);
      expect(plan.priceInr, 0);
      expect(plan.billingPeriod, 'yearly');
      expect(plan.maxStudents, 100);
      expect(plan.aiCreditsUsd, 0.5);
      expect(plan.hasFeature('ai_basic'), isTrue);
      expect(plan.hasFeature('whatsapp'), isFalse);
      expect(plan.hasFeature('advanced_reports'), isFalse);
      expect(plan.isActive, isTrue);
    });

    test('parses pro plan with all features enabled', () {
      final json = {
        'id': 'pro',
        'display_name': 'Pro',
        'price_inr_paise': 120000,
        'billing_period': 'yearly',
        'max_students': 2000,
        'ai_credits_usd': 5.0,
        'feature_flags': {
          'ai_basic': true,
          'ai_advanced': true,
          'whatsapp': true,
          'advanced_reports': true,
          'lms': true,
        },
        'is_active': true,
        'sort_order': 10,
      };
      final plan = SubscriptionPlan.fromJson(json);

      expect(plan.id, 'pro');
      expect(plan.priceInr, 1200); // 120000 paise = ₹1200
      expect(plan.maxStudents, 2000);
      expect(plan.hasFeature('whatsapp'), isTrue);
      expect(plan.hasFeature('lms'), isTrue);
      expect(plan.hasFeature('white_label'), isFalse); // elite only
    });

    test('round-trips through toJson/fromJson', () {
      final original = SubscriptionPlan(
        id: 'elite',
        displayName: 'Elite',
        priceInrPaise: 360000,
        billingPeriod: 'yearly',
        maxStudents: 100000,
        aiCreditsUsd: 25.0,
        featureFlags: {'white_label': true, 'priority_support': true},
      );
      final json = original.toJson();
      final restored = SubscriptionPlan.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.displayName, original.displayName);
      expect(restored.priceInrPaise, original.priceInrPaise);
      expect(restored.maxStudents, original.maxStudents);
      expect(restored.aiCreditsUsd, original.aiCreditsUsd);
      expect(restored.hasFeature('white_label'), isTrue);
      expect(restored.hasFeature('priority_support'), isTrue);
    });
  });

  group('SubscriptionVerdict', () {
    test('parses allowed feature response', () {
      final json = {
        'allowed': true,
        'reason': 'ok',
        'plan': 'pro',
        'is_paid': true,
      };
      final v = SubscriptionVerdict.fromJson(json);

      expect(v.allowed, isTrue);
      expect(v.reason, 'ok');
      expect(v.planId, 'pro');
      expect(v.isPaid, isTrue);
    });

    test('parses blocked feature response', () {
      final json = {
        'allowed': false,
        'reason': 'feature_not_in_plan',
        'plan': 'free',
        'is_paid': false,
      };
      final v = SubscriptionVerdict.fromJson(json);

      expect(v.allowed, isFalse);
      expect(v.reason, 'feature_not_in_plan');
      expect(v.planId, 'free');
      expect(v.isPaid, isFalse);
    });

    test('parses student_count check response', () {
      final json = {
        'allowed': false,
        'reason': 'student_cap_reached',
        'current': 100,
        'max': 100,
        'plan': 'free',
      };
      final v = SubscriptionVerdict.fromJson(json);

      expect(v.allowed, isFalse);
      expect(v.reason, 'student_cap_reached');
      expect(v.current, 100);
      // Note: the edge function returns 'max' not 'max_students' for the
      // student_count check. The full plan summary (GET with no feature param)
      // returns 'max_students'. Both are valid; the consumer reads the
      // appropriate field based on which check they called.
    });

    test('parses ai_budget check response', () {
      final json = {
        'allowed': true,
        'used_today': 3,
        'budget': 20,
        'plan': 'pro',
      };
      final v = SubscriptionVerdict.fromJson(json);

      expect(v.allowed, isTrue);
      expect(v.usedToday, 3);
      expect(v.budget, 20);
    });

    test('handles missing fields gracefully', () {
      final v = SubscriptionVerdict.fromJson({});
      expect(v.allowed, isFalse);
      expect(v.reason, 'unknown');
    });
  });
}
