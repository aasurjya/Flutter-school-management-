import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../homework/providers/homework_provider.dart';
import '../../../../data/models/homework.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg   = AppColors.background;
const _surf = Color(0xFFF8F9FA);
const _ink  = AppColors.grey900;
const _muted = AppColors.grey500;
const _border = AppColors.grey200;

// ─── Screen ───────────────────────────────────────────────────────────────────
class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'Student').split(' ').first;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Greeting header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _muted,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            firstName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar circle — tap to open menu
                    GestureDetector(
                      onTap: () => _showMenu(context, ref),
                      child: _AvatarCircle(initials: user?.initials ?? 'S'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hero attendance card ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: _HeroAttendanceCard(),
              ),
            ),

            // ── Stat pills row ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _StatPillsRow(),
              ),
            ),

            // ── Section: Today's Classes ─────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SectionHeader(label: "Today"),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _TodayScheduleCard(),
              ),
            ),

            // ── Section: Upcoming ────────────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SectionHeader(label: "Upcoming"),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _UpcomingCard(),
              ),
            ),

            // ── Section: Homework ────────────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SectionHeader(label: "Homework"),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _HomeworkWidget(),
              ),
            ),

            // ── AI Study Tips entry ──────────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.studyRecommendations),
                  child: const _StudyTipsEntry(),
                ),
              ),
            ),

            // ── Section: Upcoming Exam ───────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SectionHeader(label: "Next Exam"),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const _UpcomingExamCard(),
              ),
            ),

            // ── Quick Actions ────────────────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SectionHeader(label: "Quick Actions"),
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
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ─── Hero Attendance Card ──────────────────────────────────────────────────────
// ─── Hero: floating attendance number (no card, no color box) ─────────────────
// Design principle: the NUMBER is the hero. White space IS the design.
// Inspired by Stripe dashboard revenue number — confidence through scale.
class _HeroAttendanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thin progress bar — understated, not a big colored block
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: 0.94,
            backgroundColor: AppColors.grey100,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '94',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                color: AppColors.grey900,
                letterSpacing: -4,
                height: 1,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10, left: 2),
              child: Text(
                '%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey400,
                  letterSpacing: -1,
                ),
              ),
            ),
            const Spacer(),
            // Status pill — single accent, used once
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'On track',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'attendance this term',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.grey500,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Stat strip — numbers only, no containers, no icons
// Design principle: let the data breathe. Stripe uses this exact pattern.
class _StatPillsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatNum(value: '3', label: 'due')),
        _StatDivider(),
        Expanded(child: _StatNum(value: '2', label: 'exams')),
        _StatDivider(),
        Expanded(child: _StatNum(value: '#5', label: 'rank')),
      ],
    );
  }
}

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
            fontSize: 22,
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

// ─── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _ink,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ─── Today's schedule card ─────────────────────────────────────────────────────
class _TodayScheduleCard extends StatelessWidget {
  static const _classes = [
    ('08:30', 'Mathematics', 'Mr. Kumar · Room 101', true),
    ('09:30', 'Physics', 'Mrs. Sharma · Room 102', false),
    ('10:30', 'Chemistry', 'Dr. Patel · Lab 1', false),
    ('11:30', 'English', 'Ms. Wilson · Room 103', false),
    ('12:30', 'History', 'Mr. Singh · Room 104', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surf,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: _classes.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: _ClassRow(
                  time: c.$1,
                  subject: c.$2,
                  detail: c.$3,
                  isCurrent: c.$4,
                ),
              ),
              if (i < _classes.length - 1)
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: _border,
                    indent: 16,
                    endIndent: 16),
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
        // Time column
        SizedBox(
          width: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? _ink : _muted,
                ),
              ),
              if (isCurrent)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NOW',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Left accent line
        Container(
          width: 2,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.primary : _border,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        // Subject info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Upcoming card ─────────────────────────────────────────────────────────────
class _UpcomingCard extends StatelessWidget {
  static const _items = [
    ('Physics Assignment Due', 'Chapter 5 — Wave Optics', 'Tomorrow'),
    ('Chemistry Quiz', 'Organic Chemistry', 'In 3 days'),
    ('Parent-Teacher Meeting', 'Annual Review', 'Next week'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surf,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: _items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$2,
                            style: const TextStyle(
                                fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.$3,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < _items.length - 1)
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: _border,
                    indent: 16,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
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
        height: 48,
        child: Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surf,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 18, color: AppColors.success),
                SizedBox(width: 10),
                Text(
                  'No pending homework — nice work!',
                  style: TextStyle(fontSize: 13, color: _muted),
                ),
              ],
            ),
          );
        }

        final pending = items.take(3).toList();
        return Container(
          decoration: BoxDecoration(
            color: _surf,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: pending.asMap().entries.map((entry) {
              final i = entry.key;
              final hw = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: _HomeworkRow(homework: hw),
                  ),
                  if (i < pending.length - 1)
                    const Divider(
                        height: 1,
                        thickness: 1,
                        color: _border,
                        indent: 16,
                        endIndent: 16),
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
    final dotColor = isHigh ? AppColors.error : AppColors.grey300;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                homework.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                homework.subjectName ?? 'Subject',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Due tomorrow',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── AI Study Tips entry ───────────────────────────────────────────────────────
class _StudyTipsEntry extends StatelessWidget {
  const _StudyTipsEntry();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: const [
          Icon(Icons.auto_awesome_outlined,
              size: 18, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Study Tips',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Personalized recommendations just for you',
                  style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}

// ─── Upcoming Exam Card ────────────────────────────────────────────────────────
class _UpcomingExamCard extends StatelessWidget {
  const _UpcomingExamCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.quiz_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mathematics — Mid Term',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chapters 1–5  ·  80 marks',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'In 5 days',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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

    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.collections_bookmark_outlined,
            label: 'Portfolio',
            onTap: () => context.push(
              AppRoutes.studentPortfolio
                  .replaceFirst(':studentId', studentId),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.badge_outlined,
            label: 'ID Card',
            onTap: () => context.push(
              AppRoutes.digitalIdCard
                  .replaceFirst(':studentId', studentId),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.fact_check_outlined,
            label: 'Attendance',
            onTap: () => context.push(AppRoutes.studentAttendance),
          ),
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
      color: _surf,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  letterSpacing: -0.1,
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
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
