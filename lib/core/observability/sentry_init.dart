import 'dart:async';
import 'dart:developer' as developer;

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_environment.dart';

/// Sentry bootstrap. Use as the outer wrapper around `runApp` in `main.dart`:
///
/// ```dart
/// await runWithSentry(() async {
///   // existing app boot
///   runApp(const MyApp());
/// });
/// ```
///
/// If `SENTRY_DSN` is not set in the active `.env`, this is a pure no-op —
/// the callback is awaited normally and the app runs without instrumentation.
/// That lets developers work locally without needing a DSN, and lets the
/// app run if Sentry the service itself is down.
Future<void> runWithSentry(Future<void> Function() bootstrap) async {
  final dsn = AppEnvironment.sentryDsn;
  if (dsn == null) {
    developer.log(
      'SENTRY_DSN not set — Sentry disabled (errors will not be reported)',
      name: 'Sentry',
    );
    await bootstrap();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = AppEnvironment.environmentName;
      options.tracesSampleRate = AppEnvironment.sentryTracesSampleRate;
      // Tag every event with the active Supabase auth state so we can
      // immediately filter by tenant in the Sentry UI.
      options.beforeSend = _attachAuthContext;
      // Don't ship breadcrumbs from `developer.log` (noise) but keep HTTP
      // breadcrumbs (the most useful ones for debugging).
      options.enablePrintBreadcrumbs = false;
      // Avoid swallowing screenshots in the SDK on slow Android devices.
      options.attachScreenshot = false;
    },
    appRunner: bootstrap,
  );
}

/// Hook applied to every event before it leaves the device.
///
/// Reads the current Supabase session and tags the event with:
///   • `tenant_id` (from JWT `app_metadata`)
///   • `role`      (from JWT `app_metadata.role` or `user_metadata.role`)
///   • `user_id`   (Supabase auth id — already PII-safe, no email/name)
/// without these tags, errors are unsorted noise; with them, a Sentry filter
/// like `tenant_id:demo-school` instantly scopes to one customer.
FutureOr<SentryEvent?> _attachAuthContext(SentryEvent event, Hint hint) {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    final mergedTags = {...?event.tags};

    if (user == null) {
      mergedTags['tenant_id'] = 'anon';
      mergedTags['role'] = 'anon';
      return event.copyWith(tags: mergedTags);
    }

    final claims = user.appMetadata;
    final tenantId = (claims['tenant_id'] as String?) ?? 'unknown';
    final role = (claims['role'] as String?) ??
        (user.userMetadata?['role'] as String?) ??
        'unknown';

    mergedTags['tenant_id'] = tenantId;
    mergedTags['role'] = role;

    return event.copyWith(
      tags: mergedTags,
      user: SentryUser(id: user.id),
    );
  } catch (e) {
    // Never let instrumentation throw and lose the original event.
    developer.log('sentry beforeSend tag attach failed',
        name: 'Sentry', error: e);
    return event;
  }
}

/// Captures an exception with full context. Use from `describeAppError` and
/// from any place that handles an error silently (e.g. catch-and-fallback
/// paths in providers). Safe to call when Sentry isn't initialized — it's
/// a no-op.
Future<void> captureAppException(
  Object error, {
  StackTrace? stackTrace,
  String? hint,
  Map<String, dynamic> extra = const {},
}) async {
  if (AppEnvironment.sentryDsn == null) return;
  await Sentry.captureException(
    error,
    stackTrace: stackTrace,
    withScope: (scope) {
      if (hint != null) scope.setTag('hint', hint);
      if (extra.isNotEmpty) {
        scope.setContexts('extra', extra);
      }
    },
  );
}
