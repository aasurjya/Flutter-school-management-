import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/preferences/ai_minimal_mode_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/apple_list_section.dart';

/// Apple-style settings screen.
///
/// Two sections:
///   1. Preferences — Language, AI minimal mode
///   2. About       — Version, support
///
/// Replaces the previously-unwired /settings route that dashboards
/// have been linking to (it 404'd).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final scaffoldBg = AppColors.groupedBackgroundFor(brightness);
    final minimal = ref.watch(aiMinimalModeProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        surfaceTintColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Settings'),
        titleTextStyle: theme.textTheme.displaySmall,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          AppleListSection(
            header: 'Preferences',
            children: [
              AppleListCell(
                leading: const Icon(Icons.language_outlined, size: 22),
                title: 'Language',
                showChevron: true,
                onTap: () => context.push(AppRoutes.languageSettings),
              ),
              AppleListSwitchCell(
                leading: const Icon(Icons.auto_awesome_outlined, size: 22),
                title: 'AI minimal mode',
                subtitle: minimal
                    ? 'AI cards are hidden across the app.'
                    : 'Hide AI cards across the app.',
                value: minimal,
                onChanged: (v) => ref.read(aiMinimalModeProvider.notifier).set(v),
              ),
            ],
          ),
          const AppleListSection(
            header: 'About',
            children: [
              AppleListCell(
                leading: Icon(Icons.info_outline, size: 22),
                title: 'Version',
                value: '1.0.0',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
