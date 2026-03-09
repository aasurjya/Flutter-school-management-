import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../ai_insights/providers/risk_score_provider.dart';
import '../../../ai_insights/providers/early_warning_provider.dart';
import '../../../notice_board/providers/notice_board_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg    = AppColors.background;
const _surf  = Color(0xFFF8F9FA);
const _ink   = AppColors.grey900;
const _muted = AppColors.grey500;
const _border = AppColors.grey200;

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSettingsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettingsSheet(
        onLogout: () {
          Navigator.of(context).pop();
          _logout(context, ref);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentUserProvider);
    final now = DateTime.now();
    final dateStr = _formatDate(now);

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Top bar ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'School Dashboard',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _IconBtn(
                          icon: Icons.notifications_outlined,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _IconBtn(
                          icon: Icons.settings_outlined,
                          onTap: () => _showSettingsMenu(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Hero metric ────────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2,456',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'students enrolled',
                    style: TextStyle(
                      fontSize: 16,
                      color: _muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Row metrics ────────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _RowMetric(
                      value: '94.2%',
                      label: 'Attendance today',
                      accentColor: AppColors.success,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _RowMetric(
                      value: '+12',
                      label: 'New this week',
                      accentColor: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _RowMetric(
                      value: '₹4.2L',
                      label: 'Pending fees',
                      accentColor: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── At-Risk alert card ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildAtRiskCard(context, ref),
            ),
          ),

          // ── Early Warning card ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: _buildEarlyWarningCard(context, ref),
            ),
          ),

          // ── Syllabus coverage ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: _buildSyllabusCoverageCard(context),
            ),
          ),

          // ── Quick Actions ──────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _AdminSectionHeader(label: 'Quick Actions'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _QuickActionsScroll(context: context),
          ),

          // ── Today's Summary ────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _AdminSectionHeader(label: "Today's Summary"),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTodaySummary(context),
            ),
          ),

          // ── Recent Activity ────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _AdminSectionHeader(label: 'Recent Activity'),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        )),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildRecentActivity(context),
            ),
          ),

          // ── Recent Notices ─────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _AdminSectionHeader(label: 'Notices'),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.noticeBoard),
                    child: const Text('View all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        )),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildRecentNotices(context, ref),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ── Alert cards ─────────────────────────────────────────────────────────────

  Widget _buildAtRiskCard(BuildContext context, WidgetRef ref) {
    final academicYear = ref.watch(currentAcademicYearProvider);

    return academicYear.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (year) {
        if (year == null) return const SizedBox.shrink();

        final distribution = ref.watch(
          riskDistributionProvider(
            RiskDistributionFilter(academicYearId: year.id),
          ),
        );

        return distribution.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (dist) {
            final highCount = (dist['high'] ?? 0) + (dist['critical'] ?? 0);
            if (highCount == 0) return const SizedBox.shrink();

            return _AlertBanner(
              icon: Icons.warning_amber_rounded,
              title: '$highCount At-Risk Students',
              subtitle: 'Requires immediate attention',
              accentColor: AppColors.error,
              onTap: () => context.push(AppRoutes.riskDashboard),
            );
          },
        );
      },
    );
  }

  Widget _buildEarlyWarningCard(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unresolvedAlertCountProvider);

    return countAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return _AlertBanner(
          icon: Icons.notification_important_rounded,
          title: '$count Early Warning Alert${count == 1 ? '' : 's'}',
          subtitle: 'Unresolved alerts need review',
          accentColor: AppColors.warning,
          badge: count > 99 ? '99+' : '$count',
          onTap: () => context.push(AppRoutes.earlyWarningAlerts),
        );
      },
    );
  }

  Widget _buildSyllabusCoverageCard(BuildContext context) {
    return _AlertBanner(
      icon: Icons.menu_book,
      title: 'Syllabus Coverage',
      subtitle: 'Track topic coverage across classes',
      accentColor: AppColors.success,
      onTap: () => context.push(AppRoutes.coverageDashboard),
    );
  }

  // ── Today's summary ─────────────────────────────────────────────────────────

  Widget _buildTodaySummary(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surf,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          _SummaryItem(
            icon: Icons.people_outline,
            label: 'Students present',
            value: '2,312 / 2,456',
            color: AppColors.success,
          ),
          Divider(height: 1, color: _border, indent: 16, endIndent: 16),
          _SummaryItem(
            icon: Icons.school_outlined,
            label: 'Teachers present',
            value: '121 / 124',
            color: AppColors.success,
          ),
          Divider(height: 1, color: _border, indent: 16, endIndent: 16),
          _SummaryItem(
            icon: Icons.pending_actions,
            label: 'Pending fees',
            value: '₹4.2L',
            color: AppColors.warning,
          ),
          Divider(height: 1, color: _border, indent: 16, endIndent: 16),
          _SummaryItem(
            icon: Icons.calendar_today,
            label: 'Events today',
            value: '3',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  // ── Recent activity ──────────────────────────────────────────────────────────

  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      const _ActivityData(
        title: 'Fee Payment Received',
        subtitle: 'John Doe paid ₹25,000',
        time: '5 min ago',
        icon: Icons.payment,
        color: AppColors.success,
      ),
      const _ActivityData(
        title: 'New Admission',
        subtitle: 'Sarah Smith enrolled in Class 10-A',
        time: '1 hr ago',
        icon: Icons.person_add,
        color: AppColors.primary,
      ),
      const _ActivityData(
        title: 'Exam Results Published',
        subtitle: 'Mid-term results for Class 12',
        time: '2 hr ago',
        icon: Icons.assignment_turned_in,
        color: AppColors.info,
      ),
      const _ActivityData(
        title: 'Leave Request',
        subtitle: 'Mr. Kumar requested leave for tomorrow',
        time: '3 hr ago',
        icon: Icons.event_busy,
        color: AppColors.warning,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surf,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: activities.asMap().entries.map((e) {
          final i = e.key;
          final a = e.value;
          return Column(
            children: [
              _ActivityTile(data: a),
              if (i < activities.length - 1)
                const Divider(
                    height: 1,
                    color: _border,
                    indent: 56,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Recent notices ───────────────────────────────────────────────────────────

  Widget _buildRecentNotices(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(pinnedNoticesProvider);

    return noticesAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (notices) {
        if (notices.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surf,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications_none,
                    color: AppColors.grey400, size: 20),
                SizedBox(width: 12),
                Text(
                  'No pinned notices at the moment',
                  style: TextStyle(color: AppColors.grey500, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final displayed = notices.take(3).toList();
        return Container(
          decoration: BoxDecoration(
            color: _surf,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: displayed.asMap().entries.map((entry) {
              final i = entry.key;
              final notice = entry.value;
              return Column(
                children: [
                  _buildNoticeTile(context, notice),
                  if (i < displayed.length - 1)
                    const Divider(
                        height: 1,
                        color: _border,
                        indent: 56,
                        endIndent: 16),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildNoticeTile(BuildContext context, dynamic notice) {
    Color categoryColor;
    IconData categoryIcon;

    switch (notice.category.name) {
      case 'emergency':
        categoryColor = AppColors.error;
        categoryIcon = Icons.warning_amber_rounded;
        break;
      case 'examination':
        categoryColor = AppColors.info;
        categoryIcon = Icons.quiz_outlined;
        break;
      case 'fee':
        categoryColor = AppColors.accent;
        categoryIcon = Icons.currency_rupee;
        break;
      case 'holiday':
        categoryColor = AppColors.success;
        categoryIcon = Icons.beach_access_outlined;
        break;
      case 'academic':
        categoryColor = AppColors.primary;
        categoryIcon = Icons.school_outlined;
        break;
      default:
        categoryColor = AppColors.secondary;
        categoryIcon = Icons.campaign_outlined;
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(categoryIcon, color: categoryColor, size: 18),
      ),
      title: Text(
        notice.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        notice.body,
        style: const TextStyle(fontSize: 11, color: _muted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: notice.isPinned
          ? Icon(Icons.push_pin, size: 14, color: categoryColor)
          : null,
      onTap: () => context.push(
        AppRoutes.noticeBoardDetail.replaceFirst(':noticeId', notice.id),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

// ─── Alert Banner ──────────────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String? badge;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: _bg, width: 1.5),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: accentColor),
          ],
        ),
      ),
    );
  }
}

// ─── Row metric pill ───────────────────────────────────────────────────────────
class _RowMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color accentColor;

  const _RowMetric({
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: accentColor,
            letterSpacing: -0.8,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _muted,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────────
class _AdminSectionHeader extends StatelessWidget {
  final String label;

  const _AdminSectionHeader({required this.label});

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

// ─── Icon button ───────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surf,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.grey700),
        ),
      ),
    );
  }
}

// ─── Quick Actions scrollable row ─────────────────────────────────────────────
class _QuickActionsScroll extends StatelessWidget {
  final BuildContext context;

  const _QuickActionsScroll({required this.context});

  @override
  Widget build(BuildContext outerContext) {
    final actions = [
      _QuickAction(
        icon: Icons.person_add_outlined,
        label: 'Add Student',
        color: AppColors.primary,
        onTap: () => context.push(AppRoutes.studentManagement),
      ),
      _QuickAction(
        icon: Icons.fact_check_outlined,
        label: 'Mark Attendance',
        color: AppColors.secondary,
        onTap: () => context.push(AppRoutes.attendance),
      ),
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        label: 'Generate Invoice',
        color: AppColors.warning,
        onTap: () => context.push(AppRoutes.fees),
      ),
      _QuickAction(
        icon: Icons.campaign_outlined,
        label: 'Post Announcement',
        color: AppColors.info,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.trending_up,
        label: 'View Analytics',
        color: AppColors.success,
        onTap: () => context.push(AppRoutes.trendDashboard),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: _surf,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: actions.asMap().entries.map((e) {
            final i = e.key;
            return Column(
              children: [
                _QuickActionChip(data: e.value),
                if (i < actions.length - 1)
                  const Divider(height: 1, color: _border, indent: 24, endIndent: 24),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// Design principle: iOS Settings style — text-first, no colored boxes.
// Every icon box looks like every other icon box. Text differentiates.
class _QuickActionChip extends StatelessWidget {
  final _QuickAction data;

  const _QuickActionChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward,
                  size: 14, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Summary item ──────────────────────────────────────────────────────────────
// Design principle: numbers are the content, labels are context.
// No icons competing with the data.
class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: _muted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 15,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Activity tile ─────────────────────────────────────────────────────────────
class _ActivityData {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });
}

// Design principle: Linear.app activity feed — dot category indicator,
// text leads, timestamp trails. No icon boxes competing for attention.
class _ActivityTile extends StatelessWidget {
  final _ActivityData data;

  const _ActivityTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category dot — 6px, sits at text baseline
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 10),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: _ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            data.time,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings bottom sheet ─────────────────────────────────────────────────────
class _SettingsSheet extends StatelessWidget {
  final VoidCallback onLogout;

  const _SettingsSheet({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline,
                color: AppColors.primary, size: 20),
            title: const Text('Profile',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View and edit your profile'),
            onTap: () => Navigator.of(context).pop(),
          ),
          const Divider(height: 1, color: _border),
          ListTile(
            leading: const Icon(Icons.settings_outlined,
                color: AppColors.grey700, size: 20),
            title: const Text('Settings',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('App preferences'),
            onTap: () => Navigator.of(context).pop(),
          ),
          const Divider(height: 1, color: _border),
          ListTile(
            leading: const Icon(Icons.logout,
                color: AppColors.error, size: 20),
            title: const Text('Logout',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.error)),
            subtitle: const Text('Sign out from your account'),
            onTap: onLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
