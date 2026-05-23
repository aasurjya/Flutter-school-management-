import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/config/app_environment.dart';
import 'core/config/supabase_config.dart';
import 'core/killswitch/killswitch.dart';
import 'core/killswitch/maintenance_screen.dart';
import 'core/observability/analytics.dart';
import 'core/observability/sentry_init.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/local_storage_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cold-start init dependency graph (Stage 2 / S2.10).
  //
  //   Binding ──► AppEnvironment ──► Supabase ──► Killswitch ──► runApp
  //         ╲                   ╲                            ╱
  //          ╲                   ╠══► Isar  ─────────────►──╣
  //           ╲                  ╠══► SharedPreferences ─►──╣
  //            ╠══► Orientation ─►─────────────────────────►╝
  //
  // What was sequential (Env → Supabase → Isar → Prefs ≈ 2-3 s on Moto G7
  // class device) is now: Env first (everything depends on it), then a
  // fan-out where Supabase / Isar / Prefs / Orientation run in parallel.
  // Wall time drops to ≈ max(Supabase, Isar) ≈ 1 s.
  //
  // Killswitch still gates the rest — it only awaits Supabase, not Isar/Prefs.

  // Orientation lock is fire-and-forget; the first frame may render briefly
  // in any orientation but Android/iOS apply the lock within the first
  // event loop turn, well before any meaningful UI is on screen.
  final orientationFuture = SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Env MUST be first — Sentry, Supabase and feature flags all read from it.
  await AppEnvironment.initialize();

  // Sentry wraps the entire app lifecycle. If SENTRY_DSN is absent the
  // wrapper degrades to a plain `await bootstrap()` — no behaviour change.
  await runWithSentry(() async {
    // Fan out Supabase + Isar + SharedPreferences. These have no
    // inter-dependencies; running them in parallel cuts ~1 s off cold start.
    final supabaseFuture = Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    final isarFuture = LocalStorageService.initialize();
    final sharedPrefsFuture = SharedPreferences.getInstance();

    // Killswitch needs Supabase ready; chain it specifically.
    await supabaseFuture;
    final killswitchFuture = readKillswitchAtBoot(Supabase.instance.client);
    // PostHog init is fire-and-forget — it shouldn't block boot.
    unawaited(Analytics.initialize());

    // Now await everything else in parallel.
    final results = await Future.wait<dynamic>([
      isarFuture,
      sharedPrefsFuture,
      killswitchFuture,
      orientationFuture,
    ]);
    final sharedPrefs = results[1] as SharedPreferences;
    final killswitch = results[2] as KillswitchState;

    if (killswitch.maintenance) {
      runApp(MaintenanceApp(state: killswitch));
      return;
    }

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const SchoolManagementApp(),
      ),
    );
  });
}

class SchoolManagementApp extends ConsumerWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: !AppEnvironment.isProduction,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleNotifier.supportedLocales,
    );
  }
}
