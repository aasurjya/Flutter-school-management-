import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/apple_list_section.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../students/providers/students_provider.dart';

/// Apple-style student dashboard.
///
/// What a student opening this at 8:00 AM actually needs:
///   1. What's due today? (homework, attendance check-in)
///   2. Where am I going? (timetable, today's classes)
///   3. What's coming this week? (assignments, exams)
///
/// Replaces the prior 1220-line gradient + AI-summary-card + KPI-grid
/// screen. No AI cards on the home tab; insights live one tap away.
class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final scaffoldBg = AppColors.groupedBackgroundFor(brightness);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(currentStudentProvider);
          ref.invalidate(currentUserProvider);
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
                  _TodaySection(),
                  _SchoolSection(),
                  _ComingUpSection(),
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
// Greeting card — calm, no gradient, no AI narrative.
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
                'Here is what your day looks like.',
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
// Today section
// ---------------------------------------------------------------------------

class _TodaySection extends StatelessWidget {
  const _TodaySection();
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'Today',
      children: [
        AppleListCell(
          leading: const Icon(Icons.book_outlined, size: 22),
          title: 'Homework',
          subtitle: 'Open assignments',
          showChevron: true,
          onTap: () => context.push(AppRoutes.homeworkDashboard),
        ),
        AppleListCell(
          leading: const Icon(Icons.schedule_outlined, size: 22),
          title: 'My timetable',
          showChevron: true,
          onTap: () => context.push(AppRoutes.studentTimetable),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// School section — the academic-record links.
// ---------------------------------------------------------------------------

class _SchoolSection extends StatelessWidget {
  const _SchoolSection();
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'School',
      children: [
        AppleListCell(
          leading: const Icon(Icons.check_circle_outline, size: 22),
          title: 'Attendance',
          showChevron: true,
          onTap: () => context.push(AppRoutes.studentAttendance),
        ),
        AppleListCell(
          leading: const Icon(Icons.bar_chart_outlined, size: 22),
          title: 'Results',
          showChevron: true,
          onTap: () => context.push(AppRoutes.studentResults),
        ),
        AppleListCell(
          leading: const Icon(Icons.account_balance_wallet_outlined, size: 22),
          title: 'Fees',
          showChevron: true,
          onTap: () => context.push(AppRoutes.studentFees),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Coming up — assignments and exams. Always shown; entries are tap-throughs.
// ---------------------------------------------------------------------------

class _ComingUpSection extends StatelessWidget {
  const _ComingUpSection();
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'Coming up',
      children: [
        AppleListCell(
          leading: const Icon(Icons.assignment_outlined, size: 22),
          title: 'Assignments',
          subtitle: 'Due dates and submissions',
          showChevron: true,
          onTap: () => context.push(AppRoutes.studentAssignments),
        ),
        AppleListCell(
          leading: const Icon(Icons.event_note_outlined, size: 22),
          title: 'Exams',
          showChevron: true,
          onTap: () => context.push(AppRoutes.exams),
        ),
      ],
    );
  }
}
