import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/apple_list_section.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../students/providers/students_provider.dart';

/// Apple-style parent dashboard.
///
/// Mental model: a parent opening this at 7:50 AM wants to know
///   1. Is my child OK today? (NextUpCard)
///   2. What does my child need to do today? (Today list)
///   3. Anything I should respond to? (Needs attention)
///
/// Replaces the prior 1131-line gradient/glass/KPI-grid screen.
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
                  _ChildrenSection(),
                  _TodaySection(),
                  _NeedsAttentionSection(),
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
// Children section — one cell per child. Tap goes to child progress.
// ---------------------------------------------------------------------------

class _ChildrenSection extends ConsumerWidget {
  const _ChildrenSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final asyncChildren = ref.watch(parentChildrenProvider(user.id));
    return asyncChildren.when(
      loading: () => const _LoadingSection(),
      error: (_, __) => AppleListSection(
        header: 'Your child',
        children: [
          AppleListCell(title: WarmCopy.loadFailed('your child\'s details')),
        ],
      ),
      data: (children) {
        if (children.isEmpty) {
          return const AppleListSection(
            header: 'Your child',
            children: [
              AppleListCell(
                title: 'No child linked yet.',
                subtitle: 'Ask the school office to link your account.',
              ),
            ],
          );
        }

        final cells = <Widget>[];
        for (final c in children) {
          final id = c['id']?.toString() ?? '';
          final first = c['first_name']?.toString() ?? '';
          final last = c['last_name']?.toString() ?? '';
          final fullName = '$first $last'.trim();
          final section = c['student_enrollments']?[0]?['section']?['name']
                  ?.toString() ??
              '';
          cells.add(AppleListCell(
            title: fullName.isEmpty ? 'Student' : fullName,
            subtitle: section.isEmpty ? null : section,
            showChevron: true,
            onTap: () => context.push(
              AppRoutes.childProgress.replaceFirst(':childId', id),
            ),
          ));
        }
        return AppleListSection(
          header: children.length == 1 ? 'Your child' : 'Your children',
          children: cells,
        );
      },
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ---------------------------------------------------------------------------
// Today section — homework tracker entry. Single tap to the list.
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
          subtitle: 'See what is due',
          showChevron: true,
          onTap: () => context.push(AppRoutes.homeworkTracker),
        ),
        AppleListCell(
          leading: const Icon(Icons.calendar_today_outlined, size: 22),
          title: 'Today at school',
          subtitle: 'Attendance, timetable',
          showChevron: true,
          onTap: () => context.push(AppRoutes.attendance),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Needs attention — adaptive. Today the cells are stub-routes to Messages
// and Fees. As anomaly providers (e.g. unread teacher messages count) become
// surfaced server-side, they wire here.
// ---------------------------------------------------------------------------

class _NeedsAttentionSection extends StatelessWidget {
  const _NeedsAttentionSection();
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'Needs attention',
      children: [
        AppleListCell(
          leading: const Icon(Icons.mark_email_unread_outlined, size: 22),
          title: 'Messages from teachers',
          showChevron: true,
          onTap: () => context.push(AppRoutes.messages),
        ),
        AppleListCell(
          leading: const Icon(Icons.account_balance_wallet_outlined, size: 22),
          title: 'Fees',
          subtitle: 'Due dates and statements',
          showChevron: true,
          onTap: () => context.push(AppRoutes.fees),
        ),
      ],
    );
  }
}
