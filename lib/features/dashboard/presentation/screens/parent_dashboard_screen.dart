import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logout_helper.dart';
import '../../../ai_insights/presentation/widgets/parent_ai_insights_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../ai_insights/providers/parent_digest_provider.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../students/providers/students_provider.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) => confirmLogout(context, ref);

  void _showSettingsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout'),
              subtitle: const Text('Sign out from your account'),
              onTap: () {
                Navigator.of(context).pop();
                _logout(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.primary),
              title: const Text('Profile'),
              subtitle: const Text('View and edit your profile'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.secondary),
              title: const Text('Settings'),
              subtitle: const Text('App preferences'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.settings);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Hello,',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser?.fullName ?? 'Parent',
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
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  tooltip: 'Settings',
                  onPressed: () => _showSettingsMenu(context, ref),
                ),
              ),
            ],
          ),

          // Main Dashboard Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Weekly Digest Banner - Elevated
                _buildDigestBanner(context, ref),

                // Children Selector - Wired to real data
                _ChildrenSelector(parentUserId: currentUser?.id),
                const SizedBox(height: 32),

                // Active Child Overview - Wired to real data
                _ChildOverviewCard(parentUserId: currentUser?.id),
                const SizedBox(height: 16),

                // AI Insights for selected child
                const _ParentAISection(),
                const SizedBox(height: 32),

                // Academic Quick Stats Grid
                _buildQuickStats(context),
                const SizedBox(height: 32),

                // Weekly Performance Section
                _buildSectionHeader(context, "Attendance Insights", "View Details"),
                const SizedBox(height: 16),
                _buildAttendanceOverview(context),
                const SizedBox(height: 32),

                // Curriculum Tracker
                _buildSectionHeader(context, 'Academic Progress', 'See All'),
                const SizedBox(height: 16),
                _buildSyllabusProgress(context),
                const SizedBox(height: 32),

                // Exam Performance
                _buildSectionHeader(context, 'Latest Assessment', 'History'),
                const SizedBox(height: 16),
                _buildPerformanceComparison(context),
                const SizedBox(height: 32),

                // Financial Health
                _buildSectionHeader(context, 'Financial Summary', 'Invoices'),
                const SizedBox(height: 16),
                _buildFeeSummary(context),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDigestBanner(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final parentId = currentUser?.id;
    if (parentId == null) return const SizedBox.shrink();

    final unreadCount = ref.watch(unreadDigestCountProvider(parentId));

    return unreadCount.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: GestureDetector(
            onTap: () => context.push(
              '${AppRoutes.parentDigests}?parentId=$parentId',
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly Insight Digest',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count new personalized update${count > 1 ? 's' : ''} available',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
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
                Text(action),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        _ParentStatTile(
          label: 'Attendance',
          value: '94%',
          icon: Icons.calendar_today_rounded,
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _ParentStatTile(
          label: 'Class Rank',
          value: '#05',
          icon: Icons.leaderboard_rounded,
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildAttendanceOverview(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final attendance = ['P', 'P', 'P', 'A', 'P', 'P'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(days.length, (index) {
          final isPresent = attendance[index] == 'P';
          final isToday = index == 4;

          return Column(
            children: [
              Text(
                days[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPresent ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
                ),
                child: Icon(
                  isPresent ? Icons.check_rounded : Icons.close_rounded,
                  color: isPresent ? AppColors.success : AppColors.error,
                  size: 20,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSyllabusProgress(BuildContext context) {
    final subjects = [
      {'name': 'Mathematics', 'completed': 18, 'total': 24, 'percentage': 75},
      {'name': 'Physics', 'completed': 14, 'total': 20, 'percentage': 70},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: subjects.asMap().entries.map((entry) {
          final isLast = entry.key == subjects.length - 1;
          final s = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          '${s['completed']}/${s['total']} Units',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (s['percentage'] as int) / 100,
                        backgroundColor: AppColors.grey100,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withValues(alpha: 0.8)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 24, endIndent: 24, color: AppColors.borderLight),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerformanceComparison(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const _ComparisonBar(label: 'Your Child', value: 87, color: AppColors.primary),
          const SizedBox(height: 16),
          _ComparisonBar(label: 'Class Avg', value: 72, color: AppColors.grey400),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_graph_rounded, color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Arjun is performing 15% better than the class average this term.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outstanding Balance',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '₹25,000',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Overdue',
                  style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _FeeItem(label: 'Tuition Fee (Term 2)', amount: '₹20,000'),
          const SizedBox(height: 12),
          const _FeeItem(label: 'Transport & Activity', amount: '₹5,000'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Proceed to Payment'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Children Selector — wired to parentChildrenProvider ──────────────────────
class _ChildrenSelector extends ConsumerWidget {
  final String? parentUserId;

  const _ChildrenSelector({this.parentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (parentUserId == null) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }

    final childrenAsync = ref.watch(parentChildrenProvider(parentUserId!));
    final selectedChild = ref.watch(selectedChildProvider);

    return childrenAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
      error: (_, __) => Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Could not load children', style: TextStyle(color: AppColors.error, fontSize: 12)),
          ],
        ),
      ),
      data: (children) {
        if (children.isEmpty) {
          return Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Center(
              child: Text(
                'No children linked to your account.',
                style: TextStyle(color: AppColors.grey500, fontSize: 12),
              ),
            ),
          );
        }

        // Auto-select first child if nothing is selected
        if (selectedChild == null && children.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedChildProvider.notifier).state = children.first;
          });
        }

        return SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final child = children[index];
              final studentId = child['student_id'] as String?;
              final name = child['student_name'] as String? ??
                  '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}'.trim();
              final className = child['class_name'] as String? ?? '';
              final sectionName = child['section_name'] as String? ?? '';
              final displayClass = [className, sectionName]
                  .where((s) => s.isNotEmpty)
                  .join('-');
              final isSelected = selectedChild != null &&
                  selectedChild['student_id'] == studentId;

              return _ChildCard(
                name: name.isNotEmpty ? name : 'Child',
                className: displayClass,
                isSelected: isSelected,
                onTap: () {
                  ref.read(selectedChildProvider.notifier).state = child;
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Child Overview Card — shows selected child's details & attendance ─────────
class _ChildOverviewCard extends ConsumerWidget {
  final String? parentUserId;

  const _ChildOverviewCard({this.parentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);

    if (selectedChild == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Center(
          child: Text(
            'Select a child to view details.',
            style: TextStyle(color: AppColors.grey500, fontSize: 12),
          ),
        ),
      );
    }

    final studentId = selectedChild['student_id'] as String?;
    final name = selectedChild['student_name'] as String? ??
        '${selectedChild['first_name'] ?? ''} ${selectedChild['last_name'] ?? ''}'.trim();
    final className = selectedChild['class_name'] as String? ?? '';
    final sectionName = selectedChild['section_name'] as String? ?? '';
    final rollNumber = selectedChild['roll_number'] as String? ?? '';
    final displayClass = [className, sectionName]
        .where((s) => s.isNotEmpty)
        .join('-');

    final initials = name.split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    // Load attendance for selected student
    final attendanceLabel = _AttendanceBadge(studentId: studentId);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initials.isNotEmpty ? initials : 'S',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Student',
                  style: const TextStyle(
                    color: AppColors.grey900,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (displayClass.isNotEmpty) displayClass,
                    if (rollNumber.isNotEmpty) 'Roll No: $rollNumber',
                  ].join(' • '),
                  style: const TextStyle(
                    color: AppColors.grey500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                attendanceLabel,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Attendance badge for child overview ──────────────────────────────────────
class _AttendanceBadge extends ConsumerWidget {
  final String? studentId;

  const _AttendanceBadge({this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (studentId == null) {
      return const _StatusBadge(
        icon: Icons.info_outline,
        label: 'No ID',
        color: AppColors.grey400,
      );
    }

    final statsAsync = ref.watch(attendanceStatsProvider(studentId!));
    return statsAsync.when(
      loading: () => const _StatusBadge(
        icon: Icons.hourglass_empty,
        label: 'Loading...',
        color: AppColors.grey400,
      ),
      error: (_, __) => const _StatusBadge(
        icon: Icons.error_outline,
        label: 'Attendance unavailable',
        color: AppColors.error,
      ),
      data: (stats) {
        final present = stats['present'] ?? 0;
        final total = (stats['present'] ?? 0) + (stats['absent'] ?? 0) + (stats['late'] ?? 0);
        final pct = total > 0 ? (present / total * 100).round() : null;
        final label = pct != null ? '$pct% attendance' : 'No records';
        final color = pct == null
            ? AppColors.grey400
            : pct >= 90
                ? AppColors.success
                : pct >= 75
                    ? AppColors.info
                    : AppColors.error;
        return _StatusBadge(
          icon: Icons.check_circle_rounded,
          label: label,
          color: color,
        );
      },
    );
  }
}

class _ParentStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ParentStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.grey900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value%',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FeeItem extends StatelessWidget {
  final String label;
  final String amount;

  const _FeeItem({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ChildCard extends StatelessWidget {
  final String name;
  final String className;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ChildCard({
    required this.name,
    required this.className,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.grey900,
              ),
            ),
            Text(
              className,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.grey500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Parent AI Insights Section ───────────────────────────────────────────────
class _ParentAISection extends ConsumerWidget {
  const _ParentAISection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);
    if (selectedChild == null) return const SizedBox.shrink();

    final studentId = selectedChild['student_id'] as String? ??
        selectedChild['user_id'] as String? ??
        '';
    final name = selectedChild['student_name'] as String? ??
        '${selectedChild['first_name'] ?? ''} ${selectedChild['last_name'] ?? ''}'
            .trim();

    if (studentId.isEmpty) return const SizedBox.shrink();

    return ParentAIInsightsCard(
      childUserId: studentId,
      childName: name,
    );
  }
}
