import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/apple_list_section.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../messaging/providers/messages_provider.dart';
import '../../../students/providers/students_provider.dart';
import '../../providers/dashboard_kpis_provider.dart';

/// Overhauled, high-end Parent Dashboard.
///
/// Designed around **Emotional Reassurance** and parental peace of mind.
/// Parents opening this want to immediately answer in under 3 seconds:
///   1. Is my child safe and active at school today? (Daily Child Ledger card).
///   2. What homework/timetables are active? (Timetable & Task pulse).
///   3. Any urgent tasks or teacher notes requiring signature/fees? (Needs Attention ledger).
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final scaffoldBg = AppColors.groupedBackgroundFor(brightness);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          if (user != null) {
            ref.invalidate(parentChildrenProvider(user.id));
          }
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
                  _ChildrenReassuranceSection(),
                  SizedBox(height: AppSpacing.md),
                  _NeedsAttentionLedger(),
                  SizedBox(height: AppSpacing.lg),
                  _AcademicTrackingSection(),
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
// App Bar
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
        'Parent Portal',
        style: theme.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontFamily: '.SF Pro Display',
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
          '${_weekdayLong(now.weekday)} · ${_monthShort(now.month)} ${now.day}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.labelFor(brightness, tier: 2),
            fontWeight: FontWeight.w600,
          ),
        ),
        background: const SizedBox.shrink(),
        centerTitle: false,
      ),
    );
  }
}

String _weekdayLong(int weekday) {
  const w = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  return w[weekday];
}

String _monthShort(int month) {
  const m = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return m[month];
}

// ---------------------------------------------------------------------------
// Children Reassurance Section — High-Fidelity emotional pulse cards
// ---------------------------------------------------------------------------
class _ChildrenReassuranceSection extends ConsumerWidget {
  const _ChildrenReassuranceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final asyncChildren = ref.watch(parentChildrenProvider(user.id));

    return asyncChildren.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.groupedCellFor(brightness),
          borderRadius: AppRadius.card,
        ),
        child: Text(WarmCopy.loadFailed('your child\'s details')),
      ),
      data: (children) {
        if (children.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.groupedCellFor(brightness),
              borderRadius: AppRadius.card,
              border: Border.all(
                  color: AppColors.separatorFor(brightness), width: 0.5),
            ),
            child: const Column(
              children: [
                Text(
                  'No student linked to this account.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Please contact the school registrar to connect your profile with your child\'s records.',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.xs, bottom: AppSpacing.xs),
              child: Text(
                children.length == 1
                    ? 'YOUR CHILD\'S DAILY LEDGER'
                    : 'YOUR CHILDREN\'S DAILY LEDGERS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.labelFor(brightness, tier: 2),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...children.map(
                (c) => _ChildLedgerCard(childMap: c, brightness: brightness)),
          ],
        );
      },
    );
  }
}

class _ChildLedgerCard extends StatelessWidget {
  final Map<String, dynamic> childMap;
  final Brightness brightness;

  const _ChildLedgerCard({
    required this.childMap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = brightness == Brightness.dark;

    final id = childMap['id']?.toString() ?? '';
    final first = childMap['first_name']?.toString() ?? 'Student';
    final last = childMap['last_name']?.toString() ?? '';
    final fullName = '$first $last'.trim();
    final section =
        childMap['student_enrollments']?[0]?['section']?['name']?.toString() ??
            'Class';

    // Warm academic paper inspired palette
    final cardBg = isDark ? const Color(0xFF1E1E1C) : const Color(0xFFFAF9F5);
    final borderCol =
        isDark ? const Color(0xFF3A3A36) : const Color(0xFFE8E6DF);
    final secondaryText =
        isDark ? const Color(0xFFB5B3AD) : const Color(0xFF706E67);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    'Grade $section',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: secondaryText),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () => context.push(
                  AppRoutes.childProgress.replaceFirst(':childId', id),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderCol),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                child: Text('Performance',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.labelFor(brightness))),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          // Safety & Attendance row.
          // Today's attendance is not yet wired to a real per-child read, so we
          // must NOT derive presence from the enrollment is_active flag or show
          // a fabricated arrival time — that is false reassurance on the most
          // safety-critical line a parent reads. Show a neutral pending state
          // until a real today's-attendance lookup is wired in.
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryText,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  "Today's attendance hasn't synced yet",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attention Required Ledger — Structured payments & unread items
// ---------------------------------------------------------------------------
class _NeedsAttentionLedger extends ConsumerWidget {
  const _NeedsAttentionLedger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    final overview = ref.watch(parentChildOverviewProvider).valueOrNull ??
        const <ParentChildOverview>[];
    final outstanding =
        overview.fold<double>(0, (sum, c) => sum + c.outstandingAmount);
    final unreadMessages = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    final tiles = <Widget>[];
    if (outstanding > 0) {
      tiles.add(ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance_wallet_outlined,
              size: 18, color: AppColors.error),
        ),
        title: const Text('Fees due',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Text('Outstanding balance: ₹${outstanding.toStringAsFixed(0)}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(AppRoutes.fees),
      ));
    }
    if (unreadMessages > 0) {
      if (tiles.isNotEmpty) tiles.add(const Divider(height: 0.5));
      tiles.add(ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_unread_outlined,
              size: 18, color: AppColors.warning),
        ),
        title: Text(
          unreadMessages == 1
              ? '1 unread message'
              : '$unreadMessages unread messages',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(AppRoutes.messages),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Text(
            'PARENTAL ACTION REQUIRED',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.labelFor(brightness, tier: 2),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.groupedCellFor(brightness),
            borderRadius: AppRadius.card,
            border: Border.all(
                color: AppColors.separatorFor(brightness), width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          // Material ancestor below the colored decoration so ListTile ink/bg
          // paints correctly (Flutter 3.44+ asserts otherwise).
          child: Material(
            type: MaterialType.transparency,
            child: tiles.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'All caught up — nothing needs your attention.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.labelFor(brightness, tier: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(children: tiles),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Academic Tracking Section — Settings Group List
// ---------------------------------------------------------------------------
class _AcademicTrackingSection extends StatelessWidget {
  const _AcademicTrackingSection();

  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'ACADEMIC TRACKING',
      children: [
        AppleListCell(
          leading: const Icon(Icons.book_outlined, size: 20),
          title: 'Homework & Assignments',
          subtitle: 'Active due tasks ledger',
          showChevron: true,
          onTap: () => context.push(AppRoutes.homeworkTracker),
        ),
        AppleListCell(
          leading: const Icon(Icons.calendar_today_outlined, size: 20),
          title: 'Classes & Timetables',
          subtitle: 'Daily period logs and details',
          showChevron: true,
          onTap: () => context.push(AppRoutes.attendance),
        ),
      ],
    );
  }
}
