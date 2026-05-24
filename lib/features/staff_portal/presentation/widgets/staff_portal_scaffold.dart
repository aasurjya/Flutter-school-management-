import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/apple_list_section.dart';
import '../../../auth/providers/auth_provider.dart';

/// Shared Apple-style scaffold for the six staff-portal dashboards.
///
/// Each portal (receptionist, accountant, canteen, hostel, librarian,
/// transport) was previously a ~330-line file with a gradient app bar,
/// a StaffAIInsightCard, and a 4-tile action grid. They are
/// structurally identical — only the cells differ — so the layout
/// lives here and the role-specific screens just declare their cells.
class StaffPortalScaffold extends ConsumerWidget {
  const StaffPortalScaffold({
    super.key,
    required this.greetingSubtitle,
    required this.sections,
  });

  /// Single line below the "Hi {firstName}." greeting.
  /// E.g. "Manage front-desk visitors." or "Track fees and collections."
  final String greetingSubtitle;

  /// One or more grouped list sections of cells. Limit to 3 in practice
  /// to keep cognitive load down.
  final List<StaffPortalSection> sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final scaffoldBg = AppColors.groupedBackgroundFor(brightness);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
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
              children: [
                _GreetingCard(subtitle: greetingSubtitle),
                for (final s in sections)
                  AppleListSection(
                    header: s.header,
                    children: [
                      for (final cell in s.cells)
                        AppleListCell(
                          leading: cell.icon == null
                              ? null
                              : Icon(cell.icon, size: 22),
                          title: cell.title,
                          subtitle: cell.subtitle,
                          showChevron: true,
                          onTap: () => context.push(cell.route),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StaffPortalSection {
  const StaffPortalSection({required this.header, required this.cells});
  final String header;
  final List<StaffPortalCell> cells;
}

class StaffPortalCell {
  const StaffPortalCell({
    required this.title,
    required this.route,
    this.icon,
    this.subtitle,
  });
  final String title;
  final String route;
  final IconData? icon;
  final String? subtitle;
}

// ---------------------------------------------------------------------------
// App bar (shared)
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
        'Today',
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
  const _GreetingCard({required this.subtitle});
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final cellBg = AppColors.groupedCellFor(brightness);
    final secondary = AppColors.labelFor(brightness, tier: 2);
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;

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
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
