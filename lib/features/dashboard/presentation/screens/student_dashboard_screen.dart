import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/apple_list_section.dart';
import '../../../../data/models/student.dart';
import '../../../../data/models/timetable.dart';
import '../../../assignments/providers/assignments_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../students/providers/students_provider.dart';
import '../../../timetable/providers/timetable_provider.dart';

/// Overhauled, high-end Academic Student Dashboard.
///
/// Designed around:
///   1. Emotional reassurance (Calm, serif-toned parchment header & clear workflow status).
///   2. Spatial & Timetable Rhythm (Horizontal timeline grid of today's periods with live active indicators).
///   3. Glanceability & Progressive Disclosure (Urgent today's tasks vs. weekly ledger).
class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final scaffoldBg = AppColors.groupedBackgroundFor(brightness);
    final studentAsync = ref.watch(currentStudentProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(currentStudentProvider);
          ref.invalidate(currentUserProvider);
        },
        child: studentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error loading dashboard: $err')),
          data: (student) {
            if (student == null) {
              return const Center(child: Text('Student profile not found.'));
            }

            final sectionId = student.currentEnrollment?.sectionId;
            final academicYearId = student.currentEnrollment?.academicYearId;

            return CustomScrollView(
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
                      _GreetingBanner(student: student),
                      if (sectionId != null) ...[
                        _TimetableTimelineSection(
                          sectionId: sectionId,
                          academicYearId: academicYearId,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AssignmentsSection(sectionId: sectionId),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      _AcademicRecordSection(),
                    ],
                  ),
                ),
              ],
            );
          },
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
        'Academy',
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
  const w = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return w[weekday];
}

String _monthShort(int month) {
  const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return m[month];
}

// ---------------------------------------------------------------------------
// Greeting Banner — Parchment/Warm, understated style, editorial quote
// ---------------------------------------------------------------------------
class _GreetingBanner extends StatelessWidget {
  final Student student;
  const _GreetingBanner({required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    // Academic neutral, parchment inspired coloring
    final bgColor = isDark ? const Color(0xFF1E1E1C) : const Color(0xFFFAF9F5);
    final borderColor = isDark ? const Color(0xFF3A3A36) : const Color(0xFFE8E6DF);
    final secondaryText = isDark ? const Color(0xFFB5B3AD) : const Color(0xFF706E67);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.card,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, ${student.firstName}.',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.labelFor(brightness, tier: 1),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              student.currentEnrollment != null
                  ? 'Class ${student.currentClass} · Ready for today\'s studies'
                  : 'Enrollment active · Welcome to class',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryText,
                fontWeight: FontWeight.w500,
              ),
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
                  Icon(Icons.menu_book_rounded, size: 16, color: secondaryText),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '“The roots of education are bitter, but the fruit is sweet.” — Aristotle',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: secondaryText,
                      ),
                    ),
                  ),
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
// Timetable Rhythm timeline (Asymmetric & Horizontal scrollable)
// ---------------------------------------------------------------------------
class _TimetableTimelineSection extends ConsumerWidget {
  final String sectionId;
  final String? academicYearId;

  const _TimetableTimelineSection({
    required this.sectionId,
    this.academicYearId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final timetableAsync = ref.watch(todayTimetableProvider(TodayTimetableFilter(
      sectionId: sectionId,
      academicYearId: academicYearId,
    )));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Text(
            'TODAY\'S TIMETABLE RHYTHM',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.labelFor(brightness, tier: 2),
              letterSpacing: 0.5,
            ),
          ),
        ),
        timetableAsync.when(
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
            child: const Text('Could not load today\'s timetable slots.'),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.groupedCellFor(brightness),
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.separatorFor(brightness), width: 0.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'No classes scheduled today.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.labelFor(brightness, tier: 2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enjoy your quiet study day or check assignments below.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 124,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isCurrent = _isCurrentSlot(entry.startTime, entry.endTime);

                  return _TimelineCard(
                    entry: entry,
                    isCurrent: isCurrent,
                    brightness: brightness,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isCurrentSlot(String startStr, String endStr) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startParts = startStr.split(':');
      final endParts = endStr.split(':');
      final start = today.add(Duration(hours: int.parse(startParts[0]), minutes: int.parse(startParts[1])));
      final end = today.add(Duration(hours: int.parse(endParts[0]), minutes: int.parse(endParts[1])));
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }
}

class _TimelineCard extends StatelessWidget {
  final TimetableEntry entry;
  final bool isCurrent;
  final Brightness brightness;

  const _TimelineCard({
    required this.entry,
    required this.isCurrent,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = brightness == Brightness.dark;

    final baseBg = AppColors.groupedCellFor(brightness);
    final cardBg = isCurrent
        ? (isDark ? const Color(0xFF152A1E) : const Color(0xFFECFDF5))
        : baseBg;
    final activeBorderColor = isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
    final borderColor = isCurrent
        ? activeBorderColor
        : AppColors.separatorFor(brightness);

    return Container(
      width: 172,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERIOD ${entry.sequenceOrder}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: isCurrent
                      ? activeBorderColor
                      : AppColors.labelFor(brightness, tier: 2),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: activeBorderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NOW',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            entry.subjectName ?? entry.slotName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${entry.startTime} – ${entry.endTime}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: AppColors.labelFor(brightness, tier: 2),
            ),
          ),
          const Spacer(),
          if (entry.roomNumber != null)
            Text(
              'Room ${entry.roomNumber}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: isCurrent
                    ? activeBorderColor
                    : AppColors.labelFor(brightness, tier: 2),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assignments Section — Prioritized by Deadline Urgency
// ---------------------------------------------------------------------------
class _AssignmentsSection extends ConsumerWidget {
  final String sectionId;
  const _AssignmentsSection({required this.sectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final assignmentsAsync = ref.watch(studentAssignmentsProvider(StudentAssignmentsFilter(
      sectionId: sectionId,
      pendingOnly: true,
    )));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Text(
            'ACTIVE TASKS & ASSIGNMENTS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.labelFor(brightness, tier: 2),
              letterSpacing: 0.5,
            ),
          ),
        ),
        assignmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.groupedCellFor(brightness),
              borderRadius: AppRadius.card,
            ),
            child: const Text('Could not load assignments ledger.'),
          ),
          data: (assignments) {
            if (assignments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.groupedCellFor(brightness),
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.separatorFor(brightness), width: 0.5),
                ),
                child: const Text(
                  'No pending tasks. You\'re fully caught up!',
                  style: TextStyle(fontSize: 14),
                ),
              );
            }

            // Prioritize: Due today / tomorrow vs due later
            final now = DateTime.now();
            final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
            final tomorrowEnd = todayEnd.add(const Duration(days: 1));

            final dueUrgent = <dynamic>[];
            final dueLater = <dynamic>[];

            for (final a in assignments) {
              final due = a.dueDate;
              if (due.isBefore(tomorrowEnd)) {
                dueUrgent.add(a);
              } else {
                dueLater.add(a);
              }
            }

            return Column(
              children: [
                if (dueUrgent.isNotEmpty) ...[
                  _AssignmentSubGroup(
                    label: 'URGENT · DUE SOON',
                    assignments: dueUrgent,
                    isUrgent: true,
                    brightness: brightness,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (dueLater.isNotEmpty)
                  _AssignmentSubGroup(
                    label: 'SUBMIT THIS WEEK',
                    assignments: dueLater,
                    isUrgent: false,
                    brightness: brightness,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AssignmentSubGroup extends StatelessWidget {
  final String label;
  final List<dynamic> assignments;
  final bool isUrgent;
  final Brightness brightness;

  const _AssignmentSubGroup({
    required this.label,
    required this.assignments,
    required this.isUrgent,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = isUrgent
        ? AppColors.error
        : AppColors.labelFor(brightness, tier: 2);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.groupedCellFor(brightness),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isUrgent
              ? AppColors.error.withOpacity(0.3)
              : AppColors.separatorFor(brightness),
          width: isUrgent ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                if (isUrgent) ...[
                  Icon(Icons.alarm_on, size: 14, color: AppColors.error),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assignments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = assignments[index];
              return ListTile(
                dense: true,
                title: Text(
                  a.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  a.subjectName ?? 'Subject',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.labelFor(brightness, tier: 2),
                  ),
                ),
                trailing: Text(
                  _formatDue(a.dueDate),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isUrgent ? AppColors.error : AppColors.success,
                  ),
                ),
                onTap: () => context.push(AppRoutes.studentAssignments),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDue(DateTime due) {
    final now = DateTime.now();
    if (due.year == now.year && due.month == now.month && due.day == now.day) {
      return 'Today';
    }
    if (due.year == now.year && due.month == now.month && due.day == now.day + 1) {
      return 'Tomorrow';
    }
    return '${due.day} ${_monthShort(due.month)}';
  }
}

// ---------------------------------------------------------------------------
// Academic Record Section — Settings Group List
// ---------------------------------------------------------------------------
class _AcademicRecordSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'ACADEMIC RECORD',
      children: [
        AppleListCell(
          leading: const Icon(Icons.check_circle_outline, size: 20),
          title: 'Attendance Ledger',
          showChevron: true,
          onTap: () => context.push(AppRoutes.studentAttendance),
        ),
        AppleListCell(
          leading: const Icon(Icons.bar_chart_outlined, size: 20),
          title: 'Academic Results',
          showChevron: true,
          onTap: () => context.push(AppRoutes.studentResults),
        ),
        AppleListCell(
          leading: const Icon(Icons.account_balance_wallet_outlined, size: 20),
          title: 'Financial Statements',
          showChevron: true,
          onTap: () => context.push(AppRoutes.studentFees),
        ),
      ],
    );
  }
}
