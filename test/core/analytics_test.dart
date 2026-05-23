import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/core/observability/analytics.dart';

void main() {
  group('AnalyticsEvent constants', () {
    test('event names are stable and snake_case', () {
      // Renaming any of these splits the PostHog funnel. Pin them.
      expect(AnalyticsEvent.login, 'login');
      expect(AnalyticsEvent.dashboardOpenRole, 'dashboard_open_role');
      expect(AnalyticsEvent.featureUsed, 'feature_used');
      expect(AnalyticsEvent.errorShown, 'error_shown');
      expect(AnalyticsEvent.aiCallMade, 'ai_call_made');
    });
  });

  group('Analytics.capture (uninitialized)', () {
    test('is a no-op and does not throw when SDK is not initialized',
        () async {
      // Initialize was never called → _initialized stays false.
      // capture() must NOT throw and must NOT block the test.
      await expectLater(
        Analytics.capture(AnalyticsEvent.login),
        completes,
      );
      await expectLater(
        Analytics.capture(
          AnalyticsEvent.featureUsed,
          properties: const {'feature': 'unit_test'},
        ),
        completes,
      );
    });

    test('identify and reset are no-ops when uninitialized', () async {
      await expectLater(Analytics.identify('user-1'), completes);
      await expectLater(Analytics.reset(), completes);
    });
  });
}
