import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/apple_list_section.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../ai_insights/providers/early_warning_provider.dart';
import '../../../attendance/presentation/widgets/quick_mark_sheet.dart';
import '../../../attendance/providers/quick_mark_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../timetable/providers/timetable_provider.dart';

/// Apple-style teacher dashboard.
///
/// Three regions, top-to-bottom:
///   1. NextUpCard       — the single primary CTA: "Mark all N present"
///   2. Today list       — remaining periods today
///   3. Needs attention  — adaptive; hidden when nothing's wrong
///
/// Replaces the prior 1069-line gradient/glass/AI-tools-grid screen.
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

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
          ref.invalidate(quickMarkTargetProvider);
          if (user != null) {
            ref.invalidate(teacherTimetableProvider(TeacherTimetableFilter(
              teacherId: user.id,
              dayOfWeek: DateTime.now().weekday,
            )));
            ref.invalidate(classTeacherSectionsProvider(user.id));
          }
          ref.invalidate(alertsProvider(const AlertsFilter(status: 'new')));
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
                  _NextUpCard(),
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
// App bar — Apple "Today" pattern. Large title, no gradient, no decoration.
// ---------------------------------------------------------------------------

class _AppBar extends StatelessWidget {
  const _AppBar({required this.brightness});
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = AppColors.groupedBackgroundFor(brightness);

    return SliverAppBar(
      backgroundColor: bg,
      surfaceTintColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      floating: false,
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
        title: _DateSubtitle(brightness: brightness),
        background: const SizedBox.shrink(),
        centerTitle: false,
      ),
    );
  }
}

class _DateSubtitle extends ConsumerWidget {
  const _DateSubtitle({required this.brightness});
  final Brightness brightness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncTarget = ref.watch(quickMarkTargetProvider);
    final now = DateTime.now();
    final base = _weekdayShort(now.weekday);
    final date = '$base · ${_monthShort(now.month)} ${now.day}';
    final tail = asyncTarget.maybeWhen(
      data: (t) {
        if (t == null) return 'No more classes today';
        if (t.isNow) return 'In class now';
        final mins = t.minutesUntilStart ?? 0;
        return 'Next in ${mins}m';
      },
      orElse: () => '',
    );
    return Text(
      tail.isEmpty ? date : '$date · $tail',
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.labelFor(brightness, tier: 2),
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
// NextUpCard — the single primary action. Card surface, no shadow, no blur.
// ---------------------------------------------------------------------------

class _NextUpCard extends ConsumerWidget {
  const _NextUpCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final cellBg = AppColors.groupedCellFor(brightness);
    final secondary = AppColors.labelFor(brightness, tier: 2);

    final asyncTarget = ref.watch(quickMarkTargetProvider);
    return asyncTarget.when(
      loading: () => _CardSurface(
        color: cellBg,
        child: const SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => _CardSurface(
        color: cellBg,
        child: _EmptyCardContent(
          theme: theme,
          secondary: secondary,
          title: WarmCopy.loadFailed('today\'s schedule'),
          subtitle: 'Pull down to retry.',
        ),
      ),
      data: (target) {
        if (target == null) {
          return _CardSurface(
            color: cellBg,
            child: _EmptyCardContent(
              theme: theme,
              secondary: secondary,
              title: 'No classes scheduled.',
              subtitle: 'Take the day, or open Classes to plan ahead.',
            ),
          );
        }
        final mins = target.minutesUntilStart;
        final tag = target.isNow
            ? 'NOW'
            : (mins == null ? 'NEXT' : 'NEXT · IN ${mins}M');
        return _CardSurface(
          color: cellBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: secondary,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(target.sectionLabel, style: theme.textTheme.displaySmall),
              const SizedBox(height: 2),
              Text(
                target.roomNumber == null
                    ? '${target.startTime}–${target.endTime}'
                    : 'Room ${target.roomNumber} · ${target.startTime}',
                style: theme.textTheme.bodySmall?.copyWith(color: secondary),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => showQuickMarkSheet(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.label,
                    foregroundColor: AppColors.labelDark,
                  ),
                  child: Text(
                    'Mark all ${target.roster.length} present',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Container(
          color: color,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

class _EmptyCardContent extends StatelessWidget {
  const _EmptyCardContent({
    required this.theme,
    required this.secondary,
    required this.title,
    required this.subtitle,
  });
  final ThemeData theme;
  final Color secondary;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: secondary)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Today" section — list of remaining periods. Settings-style grouped list.
// ---------------------------------------------------------------------------

class _TodaySection extends ConsumerWidget {
  const _TodaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final filter = TeacherTimetableFilter(
      teacherId: user.id,
      dayOfWeek: DateTime.now().weekday,
    );
    final asyncSlots = ref.watch(teacherTimetableProvider(filter));

    return asyncSlots.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => AppleListSection(
        header: 'Today',
        children: [
          AppleListCell(title: WarmCopy.loadFailed('today\'s timetable')),
        ],
      ),
      data: (slots) {
        if (slots.isEmpty) return const SizedBox.shrink();
        final cells = <Widget>[];
        for (final t in slots) {
          final start = t.slot?.startTime ?? '--:--';
          final subject = t.subjectName ?? 'Period';
          final section = t.sectionName ?? t.className ?? '';
          cells.add(AppleListCell(
            title: '$section · $subject',
            subtitle: start,
            showChevron: true,
            onTap: () => context.push(AppRoutes.teacherTimetable),
          ));
          if (cells.length >= 6) break;
        }
        return AppleListSection(header: 'Today', children: cells);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// "Needs attention" — only rendered when there's actually something to do.
// ---------------------------------------------------------------------------

class _NeedsAttentionSection extends ConsumerWidget {
  const _NeedsAttentionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final alertsAsync = ref.watch(
      alertsProvider(const AlertsFilter(status: 'new', limit: 5)),
    );
    final sectionsAsync = ref.watch(classTeacherSectionsProvider(user.id));

    final children = <Widget>[];

    sectionsAsync.whenData((sections) {
      if (sections.isNotEmpty) {
        children.add(AppleListCell(
          title: 'My classes',
          value: '${sections.length}',
          showChevron: true,
          onTap: () => context.push(AppRoutes.teacherClasses),
        ));
      }
    });

    alertsAsync.whenData((alerts) {
      if (alerts.isNotEmpty) {
        children.add(AppleListCell(
          title: '${alerts.length} unresolved alert${alerts.length == 1 ? '' : 's'}',
          showChevron: true,
          onTap: () => context.push(AppRoutes.earlyWarningAlerts),
        ));
      }
    });

    if (children.isEmpty) return const SizedBox.shrink();

    return AppleListSection(
      header: 'Needs attention',
      children: children,
    );
  }
}
