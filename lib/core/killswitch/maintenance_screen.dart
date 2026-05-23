import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'killswitch.dart';

/// Minimal `MaterialApp` that runs when the killswitch is engaged.
///
/// Deliberately self-contained: no providers, no router, no Supabase usage —
/// must render even if every other init failed. Localized via the same
/// AppLocalizations delegate the main app uses.
class MaintenanceApp extends StatelessWidget {
  final KillswitchState state;

  const MaintenanceApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maintenance',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: _MaintenanceScreen(state: state),
    );
  }
}

class _MaintenanceScreen extends StatelessWidget {
  final KillswitchState state;
  const _MaintenanceScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMessage = state.message.isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.build_outlined,
                    size: 40,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'We’re updating',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  hasMessage
                      ? state.message
                      : 'The app is briefly offline for maintenance. '
                          'Please check back in a few minutes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
