
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ai_insights/presentation/widgets/student_ai_summary_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../homework/providers/homework_provider.dart';
import '../../../exams/providers/exams_provider.dart';
import '../../../../data/models/homework.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg   = AppColors.background;
const _ink  = AppColors.grey900;
const _muted = AppColors.grey500;
const _border = AppColors.grey200;

// ─── Screen ───────────────────────────────────────────────────────────────────
class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final firstName = (user?.fullName ?? 'Student').split(' ').first;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Professional Header
            SliverAppBar(
              expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.grey800],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -30,
                    right: -30,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _greeting(),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      firstName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showMenu(context, ref),
                                child: _AvatarCircle(initials: user?.initials ?? 'S'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                tooltip: 'Notifications',
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Main Analytics Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AttendanceMetricCard(userId: user?.id),
                  const SizedBox(height: 24),
                  _StudentStatPillsRow(userId: user?.id),
                ],
              ),
            ),
          ),

          // Today's Schedule Section
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _SectionHeader(label: 'Academic Timeline', action: 'Full View'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _TodayScheduleCard(),
            ),
          ),

          // Academic Performance & AI
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: StudentAISummaryCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _UpcomingExamCard(),
            ),
          ),

          // Homework & Tasks
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _SectionHeader(label: 'Coursework', action: 'Planner'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _HomeworkWidget(),
            ),
          ),

          // Tools & Resources
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _SectionHeader(label: 'Quick Tools', action: null),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _QuickActionsRow(user: user),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuSheet(ref: ref),
    );
  }
}

// ─── Avatar circle ─────────────────────────────────────────────────────────────
class _AvatarCircle extends StatelessWidget {
  final String initials;

  const _AvatarCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.grey200, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Attendance Metric Card — backed by real provider ─────────────────────────
class _AttendanceMetricCard extends ConsumerWidget {
  final String? userId;

  const _AttendanceMetricCard({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return _AttendanceMetricDisplay(percentage: null);
    }
    final statsAsync = ref.watch(attendanceStatsProvider(userId!));
    return statsAsync.when(
      loading: () => _AttendanceMetricDisplay(percentage: null, loading: true),
      error: (_, __) => _AttendanceMetricDisplay(percentage: null),
      data: (stats) {
        final present = stats['present'] ?? 0;
        final total = (stats['present'] ?? 0) + (stats['absent'] ?? 0) + (stats['late'] ?? 0);
        final pct = total > 0 ? (present / total * 100).round() : null;
        return _AttendanceMetricDisplay(percentage: pct);
      },
    );
  }
}

class _AttendanceMetricDisplay extends StatelessWidget {
  final int? percentage;
  final bool loading;

  const _AttendanceMetricDisplay({this.percentage, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final pct = percentage;
    final displayValue = loading ? '--' : (pct != null ? '$pct' : '--');
    final progressValue = pct != null ? (pct / 100.0).clamp(0.0, 1.0) : 0.0;
    final statusLabel = pct == null
        ? 'Loading'
        : pct >= 90
            ? 'Excellent'
            : pct >= 75
                ? 'Good'
                : 'Needs Attention';
    final statusColor = pct == null
        ? AppColors.grey400
        : pct >= 90
            ? AppColors.success
            : pct >= 75
                ? AppColors.info
                : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Health',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey500,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: AppColors.grey900,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: AppColors.grey100,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Student Stat Pills — due tasks + upcoming exams from real providers ───────
class _StudentStatPillsRow extends ConsumerWidget {
  final String? userId;

  const _StudentStatPillsRow({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Due tasks: student's homework not yet submitted, due in future
    final homeworkAsync = userId != null
        ? ref.watch(studentHomeworkProvider(userId!))
        : const AsyncValue<List<Homework>>.data([]);

    // Upcoming exams: published exams (no filter needed for student)
    final examsAsync = ref.watch(
      examsProvider(const ExamsFilter(publishedOnly: true)),
    );

    final dueCount = homeworkAsync.when(
      loading: () => null,
      error: (_, __) => 0,
      data: (items) {
        final now = DateTime.now();
        return items
            .where((hw) =>
                hw.status == HomeworkStatus.published &&
                hw.dueDate.isAfter(now))
            .length;
      },
    );

    final examCount = examsAsync.when(
      loading: () => null,
      error: (_, __) => 0,
      data: (exams) {
        final now = DateTime.now();
        return exams
            .where((e) =>
                e.isPublished &&
                e.startDate != null &&
                e.startDate!.isAfter(now))
            .length;
      },
    );

    return Row(
      children: [
        Expanded(
          child: _StatNum(
            value: dueCount != null ? '$dueCount' : '--',
            label: 'due',
          ),
        ),
        const _StatDivider(),
        Expanded(
          child: _StatNum(
            value: examCount != null ? '$examCount' : '--',
            label: 'exams',
          ),
        ),
        const _StatDivider(),
        const Expanded(
          child: _StatNum(value: '--', label: 'rank'),
        ),
      ],
    );
  }
}

// ─── Stat strip backing widgets ────────────────────────────────────────────────

class _StatNum extends StatelessWidget {
  final String value;
  final String label;

  const _StatNum({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: -0.8,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _muted,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.grey200,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? action;

  const _SectionHeader({required this.label, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                fontSize: 18,
              ),
        ),
        if (action != null)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            child: Row(
              children: [
                Text(action!),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

class _TodayScheduleCard extends StatelessWidget {
  static const _classes = [
    ('08:30', 'Mathematics', 'Mr. Kumar • Room 101', true),
    ('09:30', 'Physics', 'Mrs. Sharma • Room 102', false),
    ('10:30', 'Chemistry', 'Dr. Patel • Lab 1', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: _classes.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _ClassRow(
                  time: c.$1,
                  subject: c.$2,
                  detail: c.$3,
                  isCurrent: c.$4,
                ),
              ),
              if (i < _classes.length - 1)
                const Divider(height: 1, indent: 24, endIndent: 24, color: AppColors.borderLight),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  final String time;
  final String subject;
  final String detail;
  final bool isCurrent;

  const _ClassRow({
    required this.time,
    required this.subject,
    required this.detail,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isCurrent ? AppColors.primary : AppColors.grey400,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? AppColors.primary : AppColors.grey900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(fontSize: 12, color: AppColors.grey500),
              ),
            ],
          ),
        ),
        if (isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Homework widget ───────────────────────────────────────────────────────────
class _HomeworkWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkAsync = ref.watch(
      homeworkListProvider(
        const HomeworkListFilter(status: HomeworkStatus.published),
      ),
    );

    return homeworkAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_rounded, size: 32, color: AppColors.success.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'All caught up!',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey900),
                ),
                Text(
                  'No pending assignments for today.',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
              ],
            ),
          );
        }

        final pending = items.take(3).toList();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: pending.asMap().entries.map((entry) {
              final i = entry.key;
              final hw = entry.value;
              return Column(
                children: [
                  _HomeworkRow(homework: hw),
                  if (i < pending.length - 1)
                    const Divider(height: 1, indent: 24, endIndent: 24, color: AppColors.borderLight),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _HomeworkRow extends StatelessWidget {
  final dynamic homework;

  const _HomeworkRow({required this.homework});

  @override
  Widget build(BuildContext context) {
    final bool isHigh = homework.priority.name == 'high';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isHigh ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.assignment_outlined,
          color: isHigh ? AppColors.error : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        homework.title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.grey900),
      ),
      subtitle: Text(
        homework.subjectName ?? 'Curriculum Task',
        style: TextStyle(fontSize: 12, color: AppColors.grey500),
      ),
      trailing: isHigh
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Urgent',
                style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, color: AppColors.grey400, size: 20),
    );
  }
}

// ─── Upcoming Exam Card ────────────────────────────────────────────────────────
class _UpcomingExamCard extends StatelessWidget {
  const _UpcomingExamCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.quiz_outlined, color: AppColors.info, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mid-Term Assessment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mathematics • Units 1–5',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Text(
              'In 5 Days',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.grey700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions row ─────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final dynamic user;

  const _QuickActionsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final studentId = user?.id ?? 'me';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        _QuickActionTile(
          icon: Icons.collections_bookmark_rounded,
          label: 'Portfolio',
          onTap: () => context.push(
            AppRoutes.studentPortfolio.replaceFirst(':studentId', studentId),
          ),
        ),
        _QuickActionTile(
          icon: Icons.badge_rounded,
          label: 'ID Card',
          onTap: () => context.push(
            AppRoutes.digitalIdCard.replaceFirst(':studentId', studentId),
          ),
        ),
        _QuickActionTile(
          icon: Icons.fact_check_rounded,
          label: 'Attendance',
          onTap: () => context.push(AppRoutes.studentAttendance),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom menu sheet ─────────────────────────────────────────────────────────
class _MenuSheet extends StatelessWidget {
  final WidgetRef ref;

  const _MenuSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          _MenuRow(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () => Navigator.pop(context),
          ),
          const Divider(height: 1, color: _border),
          _MenuRow(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.pop(context),
          ),
          const Divider(height: 1, color: _border),
          _MenuRow(
            icon: Icons.logout,
            label: 'Sign out',
            color: AppColors.error,
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.grey700,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
