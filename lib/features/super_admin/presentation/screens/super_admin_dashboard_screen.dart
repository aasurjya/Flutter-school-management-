import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/apple_list_section.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/tenant_provider.dart';

/// Apple-style super-admin dashboard.
///
/// Super-admins operate the platform, not a school. Their two jobs:
///   1. Manage tenants (schools) — list, create, drill in
///   2. Watch platform health — tenant count, user count, AI status
///
/// Replaces the prior 657-line gradient/glass screen.
class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final scaffoldBg = AppColors.groupedBackgroundFor(brightness);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(platformStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            _AppBar(brightness: brightness),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              sliver: SliverList.list(
                children: const [
                  _GreetingCard(),
                  _PlatformStatsCard(),
                  _TenantsSection(),
                  _PlatformSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _AppBar extends StatelessWidget {
  const _AppBar({required this.brightness});
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.groupedBackgroundFor(brightness);
    final now = DateTime.now();

    return SliverAppBar(
      backgroundColor: bg,
      surfaceTintColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      expandedHeight: 92,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.md,
      title: Text(
        'Platform',
        style: theme.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle_outlined, size: 28),
          tooltip: 'Account',
          onPressed: () => context.go(AppRoutes.account),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        title: Text(
          '${_weekdayShort(now.weekday)} · ${_monthShort(now.month)} ${now.day}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.labelFor(brightness, tier: 2),
          ),
        ),
        background: const SizedBox.shrink(),
        centerTitle: false,
      ),
    );
  }
}

String _weekdayShort(int weekday) {
  const w = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return w[weekday];
}

String _monthShort(int month) {
  const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return m[month];
}

// ---------------------------------------------------------------------------
// Greeting card
// ---------------------------------------------------------------------------

class _GreetingCard extends ConsumerWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final cellBg = AppColors.groupedCellFor(brightness);
    final secondary = AppColors.labelFor(brightness, tier: 2);
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'Operator').split(' ').first;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Container(
          color: cellBg,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi $firstName.', style: theme.textTheme.displaySmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Platform overview.',
                style: theme.textTheme.bodySmall?.copyWith(color: secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Platform stats card — calm two-number summary. No 8 KPI tiles.
// ---------------------------------------------------------------------------

class _PlatformStatsCard extends ConsumerWidget {
  const _PlatformStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final cellBg = AppColors.groupedCellFor(brightness);
    final secondary = AppColors.labelFor(brightness, tier: 2);
    final asyncStats = ref.watch(platformStatsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Container(
          color: cellBg,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: asyncStats.when(
            loading: () => const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text(
              WarmCopy.loadFailed('platform stats'),
              style: theme.textTheme.bodySmall?.copyWith(color: secondary),
            ),
            data: (stats) {
              final tenants = stats['tenants']?.toString() ?? '—';
              final users = stats['users']?.toString() ?? '—';
              return Row(
                children: [
                  Expanded(child: _StatBlock(label: 'Schools', value: tenants, theme: theme, secondary: secondary)),
                  Container(
                    width: 0.5,
                    height: 36,
                    color: AppColors.separatorFor(brightness),
                  ),
                  Expanded(child: _StatBlock(label: 'Users', value: users, theme: theme, secondary: secondary)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.theme,
    required this.secondary,
  });
  final String label;
  final String value;
  final ThemeData theme;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: theme.textTheme.displaySmall),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: secondary)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tenants section
// ---------------------------------------------------------------------------

class _TenantsSection extends StatelessWidget {
  const _TenantsSection();
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'Tenants',
      children: [
        AppleListCell(
          leading: const Icon(Icons.apartment_outlined, size: 22),
          title: 'All schools',
          showChevron: true,
          onTap: () => context.push(AppRoutes.tenantsList),
        ),
        AppleListCell(
          leading: const Icon(Icons.add_business_outlined, size: 22),
          title: 'New school',
          showChevron: true,
          onTap: () => context.push(AppRoutes.createTenant),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Platform section
// ---------------------------------------------------------------------------

class _PlatformSection extends StatelessWidget {
  const _PlatformSection();
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'Platform',
      children: [
        AppleListCell(
          leading: const Icon(Icons.settings_outlined, size: 22),
          title: 'Settings',
          showChevron: true,
          onTap: () => context.push(AppRoutes.settings),
        ),
        AppleListCell(
          leading: const Icon(Icons.notifications_none, size: 22),
          title: 'Notifications',
          showChevron: true,
          onTap: () => context.push(AppRoutes.notifications),
        ),
      ],
    );
  }
}
