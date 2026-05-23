import 'dart:async';
import 'dart:developer' as developer;

import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_environment.dart';

/// Five well-named events beat 50 noisy ones. Start with these; resist adding
/// a sixth until one of these isn't answering a real product question.
///
/// Keep names stable — renaming an event splits the funnel. Add new ones
/// instead.
class AnalyticsEvent {
  static const login = 'login';
  static const dashboardOpenRole = 'dashboard_open_role'; // props: role
  static const featureUsed = 'feature_used';              // props: feature
  static const errorShown = 'error_shown';                // props: type
  static const aiCallMade = 'ai_call_made';               // props: feature, cached
}

/// Thin wrapper around the PostHog SDK that:
///   • Auto-skips when POSTHOG_API_KEY is missing (no-op for local dev).
///   • Tags every event with `tenant_id` + `role` from the Supabase JWT.
///   • Catches and logs SDK errors so analytics can never crash the app.
class Analytics {
  Analytics._();

  static bool _initialized = false;

  /// Called once from `main()` after Supabase is initialized. Cheap if no key.
  static Future<void> initialize() async {
    if (AppEnvironment.posthogApiKey == null) {
      developer.log(
        'POSTHOG_API_KEY not set — analytics disabled',
        name: 'Analytics',
      );
      return;
    }
    try {
      final config = PostHogConfig(AppEnvironment.posthogApiKey!)
        ..host = AppEnvironment.posthogHost
        ..debug = !AppEnvironment.isProduction
        ..captureApplicationLifecycleEvents = true;
      await Posthog().setup(config);
      _initialized = true;
    } catch (e) {
      developer.log('PostHog init failed', name: 'Analytics', error: e);
    }
  }

  /// Capture an event. Safe to call before `initialize()` — becomes a no-op.
  static Future<void> capture(
    String event, {
    Map<String, Object>? properties,
  }) async {
    if (!_initialized) return;
    try {
      final merged = <String, Object>{...?properties, ..._authContext()};
      await Posthog().capture(eventName: event, properties: merged);
    } catch (e) {
      developer.log('PostHog capture failed: $event',
          name: 'Analytics', error: e);
    }
  }

  /// Tie subsequent events to the signed-in user. Call on login / on
  /// session-restore.
  static Future<void> identify(String userId) async {
    if (!_initialized) return;
    try {
      await Posthog().identify(userId: userId);
    } catch (e) {
      developer.log('PostHog identify failed', name: 'Analytics', error: e);
    }
  }

  /// Clear the identified user. Call on logout.
  static Future<void> reset() async {
    if (!_initialized) return;
    try {
      await Posthog().reset();
    } catch (e) {
      developer.log('PostHog reset failed', name: 'Analytics', error: e);
    }
  }

  static Map<String, Object> _authContext() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return const {'tenant_id': 'anon', 'role': 'anon'};
      }
      final meta = user.appMetadata;
      return {
        'tenant_id': (meta['tenant_id'] as String?) ?? 'unknown',
        'role': (meta['role'] as String?) ??
            (user.userMetadata?['role'] as String?) ??
            'unknown',
      };
    } catch (_) {
      return const {};
    }
  }
}
