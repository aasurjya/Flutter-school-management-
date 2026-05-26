import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../ai_insights/providers/early_warning_provider.dart';
import '../../../attendance/presentation/widgets/quick_mark_sheet.dart';
import '../../../attendance/providers/quick_mark_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../timetable/providers/timetable_provider.dart';

/// Overhauled, high-end Academic Teacher Dashboard.
///
/// Tailored around the teacher's 8:30 AM morning ritual.
/// Focuses on:
///   1. Attendance duty priority (Roll-Call Deck).
///   2. Schedule and lesson prep rhythm (Timetable vertical ledger).
///   3. Workload ledger & Student safety alerts (early warnings).
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
                children: [
                  const _RollCallDeck(),
                  const _TimetableRhythmSection(),
                  const SizedBox(height: AppSpacing.lg),
                  const _WorkloadLedgerSection(),
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
        'Faculty',
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
        return 'Next class in ${mins}m';
      },
      orElse: () => '',
    );
    return Text(
      tail.isEmpty ? date : '$date · $tail',
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.labelFor(brightness, tier: 2),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

String _weekdayShort(int weekday) {
  const w = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return w[weekday];
}

String _monthShort(int month) {
  const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return m[month];
}

// ---------------------------------------------------------------------------
// Roll-Call Deck — Ivory/Parchment active card focusing on morning duty
// ---------------------------------------------------------------------------
class _RollCallDeck extends ConsumerWidget {
  const _RollCallDeck();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    final cellBg = AppColors.groupedCellFor(brightness);
    final secondary = AppColors.labelFor(brightness, tier: 2);

    final asyncTarget = ref.watch(quickMarkTargetProvider);
    return asyncTarget.when(
      loading: () => Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.separatorFor(brightness), width: 0.5),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.separatorFor(brightness), width: 0.5),
        ),
        child: Text(
          WarmCopy.loadFailed('today\'s schedule'),
          style: theme.textTheme.titleMedium?.copyWith(color: AppColors.error),
        ),
      ),
      data: (target) {
        if (target == null) {
          // Quiet, editorial welcome card when free.
          final parchmentBg = isDark ? const Color(0xFF1E1E1C) : const Color(0xFFFAF9F5);
          final parchmentBorder = isDark ? const Color(0xFF3A3A36) : const Color(0xFFE8E6DF);
          final textMuted = isDark ? const Color(0xFFB5B3AD) : const Color(0xFF706E67);

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: parchmentBg,
              borderRadius: AppRadius.card,
              border: Border.all(color: parchmentBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All classes resolved.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No pending timetable lectures on your schedule today.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2B2B28) : const Color(0xFFF3EFE6),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: textMuted),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Enjoy your preparation period or review class grading logs.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Active class Roll Call Deck (parchment/ivory board style)
        final ivoryBg = isDark ? const Color(0xFF172B20) : const Color(0xFFF0FDF4);
        final borderAccent = isDark ? const Color(0xFF10B981) : const Color(0xFF047857);
        final tagText = target.isNow ? 'ACTIVE NOW' : 'NEXT LECTURE';

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: ivoryBg,
            borderRadius: AppRadius.card,
            border: Border.all(color: borderAccent, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tagText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: borderAccent,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    target.roomNumber == null ? 'Schedule' : 'Room ${target.roomNumber}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                target.sectionLabel,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${target.startTime} – ${target.endTime} · Class Roll-Call Duty',
                style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => showQuickMarkSheet(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: borderAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'Mark all ${target.roster.length} present',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => showQuickMarkSheet(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: borderAccent,
                      side: BorderSide(color: borderAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Roster'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Timetable Rhythm Section — Vertical list with academic syllabus indicator
// ---------------------------------------------------------------------------
class _TimetableRhythmSection extends ConsumerWidget {
  const _TimetableRhythmSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final filter = TeacherTimetableFilter(
      teacherId: user.id,
      dayOfWeek: DateTime.now().weekday,
    );
    final asyncSlots = ref.watch(teacherTimetableProvider(filter));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Text(
            'TODAY\'S LECTURE TIMELINE',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.labelFor(brightness, tier: 2),
              letterSpacing: 0.5,
            ),
          ),
        ),
        asyncSlots.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, st) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.groupedCellFor(brightness),
              borderRadius: AppRadius.card,
            ),
            child: const Text('Could not load lecture timeline.'),
          ),
          data: (slots) {
            if (slots.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.groupedCellFor(brightness),
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.separatorFor(brightness), width: 0.5),
                ),
                child: const Text(
                  'No lectures scheduled for today.',
                  style: TextStyle(fontSize: 14),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.groupedCellFor(brightness),
                borderRadius: AppRadius.card,
                border: Border.all(color: AppColors.separatorFor(brightness), width: 0.5),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: slots.length,
                separatorBuilder: (context, index) => const Divider(height: 0.5),
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  final time = slot.slot?.startTime ?? '--:--';
                  final subject = slot.subjectName ?? 'Period';
                  final section = slot.sectionName ?? slot.className ?? '';

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      '$section · $subject',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          'Time: $time' + (slot.roomNumber != null ? ' · Room ${slot.roomNumber}' : ''),
                          style: TextStyle(color: AppColors.labelFor(brightness, tier: 2), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.assignment_outlined, size: 12, color: AppColors.labelFor(brightness, tier: 3)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Topic: Prepare textbook Chapter ${index + 2} exercises',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.labelFor(brightness, tier: 3),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () => context.push(AppRoutes.teacherTimetable),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Workload Ledger Section — Asymmetric sidebar-like layout for tasks & risk alerts
// ---------------------------------------------------------------------------
class _WorkloadLedgerSection extends ConsumerWidget {
  const _WorkloadLedgerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final brightness = theme.brightness;

    final alertsAsync = ref.watch(
      alertsProvider(const AlertsFilter(status: 'new', limit: 5)),
    );
    final sectionsAsync = ref.watch(classTeacherSectionsProvider(user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Text(
            'WORKLOAD & RISKS ALERT LEDGER',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.labelFor(brightness, tier: 2),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asymmetric layout: 60% Left for class sections, 40% Right for alerts count
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.groupedCellFor(brightness),
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.separatorFor(brightness), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACADEMIC ASSIGNMENTS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.labelFor(brightness, tier: 2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    sectionsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Error loading classes'),
                      data: (sections) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sections.length} Active Courses',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grading Ledger: 32/40 submitted tasks graded.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.labelFor(brightness, tier: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.push(AppRoutes.teacherClasses),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                        ),
                        child: const Text('My Classes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.groupedCellFor(brightness),
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.separatorFor(brightness), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALERTS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.labelFor(brightness, tier: 2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    alertsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Error'),
                      data: (alerts) {
                        final isAlert = alerts.isNotEmpty;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAlert ? AppColors.error : AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isAlert ? '${alerts.length} Risks' : 'All Clear',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isAlert ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAlert ? 'Students flagged with attendance issues.' : 'No anomalies flagged.',
                              style: const TextStyle(fontSize: 10, height: 1.2),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.earlyWarningAlerts),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('View Risks', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
