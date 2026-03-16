import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logout_helper.dart';
import '../../../ai_insights/presentation/widgets/admin_ai_narrative_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../id_card/providers/id_card_provider.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../ai_insights/providers/risk_score_provider.dart';
import '../../../ai_insights/providers/early_warning_provider.dart';
import '../../../fees/providers/fees_provider.dart';
import '../../../students/providers/students_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg    = AppColors.background;
const _ink   = AppColors.grey900;
const _border = AppColors.grey200;

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) => confirmLogout(context, ref);

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
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = _formatDate(now);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentCountProvider(null));
          ref.invalidate(feeCollectionStatsProvider(null));
          ref.invalidate(currentAcademicYearProvider);
          ref.invalidate(currentTenantProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Professional Header
            SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
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
                    top: -40,
                    right: -40,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Administrative Command Center',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ref.watch(currentTenantProvider).valueOrNull?.name ?? 'Dashboard',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dateStr,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
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
              _HeaderActionBtn(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push(AppRoutes.notifications),
                tooltip: 'Notifications',
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _HeaderActionBtn(
                  icon: Icons.settings_outlined,
                  onTap: () => _showSettingsMenu(context, ref),
                  tooltip: 'Settings',
                ),
              ),
            ],
          ),

          // Main Metrics Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverToBoxAdapter(
              child: _buildMainMetricsGrid(ref),
            ),
          ),

          // Critical Alerts
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  _buildAtRiskCard(context, ref),
                  const SizedBox(height: 12),
                  _buildEarlyWarningCard(context, ref),
                  const SizedBox(height: 12),
                  _buildSyllabusCoverageCard(context),
                ],
              ),
            ),
          ),

          // AI School Health Summary
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: AdminAINarrativeCard(),
            ),
          ),

          // Quick Actions Section
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _AdminSectionHeader(label: 'Management Tools'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _QuickActionsGrid(context: context),
          ),

          // Academic Setup Section
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _AdminSectionHeader(label: 'Academic Setup'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _AcademicActionsGrid(context: context),
          ),

          // School Operations Section
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _AdminSectionHeader(label: 'School Operations'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _OperationsActionsGrid(context: context),
          ),

          // Operations Summary
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _AdminSectionHeader(label: "Operational Health"),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTodaySummary(context),
            ),
          ),

          // Activity & Notices
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _AdminSectionHeader(label: 'Security & Activity'),
                  _ViewAllBtn(onTap: () {}),
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

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      ),
    );
  }

  static String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '\u20B9${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '\u20B9${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\u20B9${amount.toStringAsFixed(0)}';
  }

  Widget _buildMainMetricsGrid(WidgetRef ref) {
    final studentCountAsync = ref.watch(studentCountProvider(null));
    final feeStatsAsync = ref.watch(feeCollectionStatsProvider(null));

    final enrollmentValue = studentCountAsync.when(
      loading: () => '--',
      error: (_, __) => '--',
      data: (count) => _formatNumber(count),
    );

    final revenueValue = feeStatsAsync.when(
      loading: () => '--',
      error: (_, __) => '--',
      data: (stats) => _formatCurrency(stats['total_paid'] ?? 0.0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enrollment Strength',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                enrollmentValue,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.grey900,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total students active this term',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Attendance',
                value: '94.2%',
                icon: Icons.how_to_reg_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Revenue',
                value: revenueValue,
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return '$n';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _SummaryItem(
            icon: Icons.people_outline_rounded,
            label: 'Students present',
            value: '2,312 / 2,456',
            color: AppColors.success,
          ),
          const Divider(height: 1, indent: 24, endIndent: 24, color: AppColors.borderLight),
          _SummaryItem(
            icon: Icons.school_outlined,
            label: 'Teachers present',
            value: '121 / 124',
            color: AppColors.success,
          ),
          const Divider(height: 1, indent: 24, endIndent: 24, color: AppColors.borderLight),
          _SummaryItem(
            icon: Icons.pending_actions_rounded,
            label: 'Outstanding Invoices',
            value: '₹4.2L',
            color: AppColors.warning,
          ),
          const Divider(height: 1, indent: 24, endIndent: 24, color: AppColors.borderLight),
          _SummaryItem(
            icon: Icons.calendar_today_rounded,
            label: 'Scheduled Events',
            value: '03',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      const _ActivityData(
        title: 'Fee Payment Received',
        subtitle: 'Reference #PAY-9021 • John Doe',
        time: '5m ago',
        icon: Icons.payment_rounded,
        color: AppColors.success,
      ),
      const _ActivityData(
        title: 'New Admission',
        subtitle: 'Class 10-A • Sarah Smith',
        time: '1h ago',
        icon: Icons.person_add_rounded,
        color: AppColors.primary,
      ),
      const _ActivityData(
        title: 'Exam Results Published',
        subtitle: 'Mid-term • Class 12 Science',
        time: '2h ago',
        icon: Icons.assignment_turned_in_rounded,
        color: AppColors.info,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: activities.asMap().entries.map((e) {
          final i = e.key;
          final a = e.value;
          return Column(
            children: [
              _ActivityTile(data: a),
              if (i < activities.length - 1)
                const Divider(height: 1, indent: 64, endIndent: 20, color: AppColors.borderLight),
            ],
          );
        }).toList(),
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

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  final String? tooltip;

  const _HeaderActionBtn({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
        tooltip: tooltip,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final BuildContext context;

  const _QuickActionsGrid({required this.context});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (label: 'Students',    icon: Icons.person_add_rounded,        color: AppColors.primary,       route: AppRoutes.studentManagement),
      (label: 'Staff',       icon: Icons.badge_rounded,              color: const Color(0xFF8B5CF6), route: AppRoutes.staffManagement),
      (label: 'Classes',     icon: Icons.class_rounded,              color: AppColors.info,          route: AppRoutes.academicConfig),
      (label: 'Attendance',  icon: Icons.fact_check_rounded,         color: AppColors.success,       route: AppRoutes.attendance),
      (label: 'Fee Invoice', icon: Icons.receipt_long_rounded,       color: AppColors.warning,       route: AppRoutes.fees),
      (label: 'Exams',       icon: Icons.edit_document,              color: AppColors.error,         route: AppRoutes.examManagement),
      (label: 'Broadcast',   icon: Icons.campaign_rounded,           color: AppColors.secondary,     route: AppRoutes.noticeBoard),
      (label: 'Timetable',   icon: Icons.calendar_view_week_rounded, color: const Color(0xFF059669), route: AppRoutes.timetable),
      (label: 'Admissions',  icon: Icons.how_to_reg_rounded,         color: const Color(0xFFD97706), route: AppRoutes.admissionDashboard),
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(a.route),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(a.icon, color: a.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ViewAllBtn extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewAllBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('View All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 16),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
              fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            data.time,
            style: TextStyle(
              color: AppColors.grey400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
            leading: const Icon(Icons.badge_rounded,
                color: AppColors.primary, size: 20),
            title: const Text('My ID Card',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View your staff identity card'),
            onTap: () {
              Navigator.of(context).pop();
              GoRouter.of(context).push(AppRoutes.staffIdCard);
            },
          ),
          const Divider(height: 1, color: _border),
          ListTile(
            leading: const Icon(Icons.brush_rounded,
                color: AppColors.grey700, size: 20),
            title: const Text('School Branding',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Upload logo & manage identity'),
            onTap: () {
              Navigator.of(context).pop();
              GoRouter.of(context).push(AppRoutes.schoolBranding);
            },
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

// ─── Academic Setup grid ───────────────────────────────────────────────────────
class _AcademicActionsGrid extends StatelessWidget {
  final BuildContext context;
  const _AcademicActionsGrid({required this.context});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (label: 'Classes',      icon: Icons.class_rounded,             color: AppColors.primary,        route: AppRoutes.academicConfig),
      (label: 'Timetable',    icon: Icons.calendar_view_week_rounded, color: const Color(0xFF8B5CF6), route: AppRoutes.timetable),
      (label: 'Syllabus',     icon: Icons.menu_book_rounded,          color: AppColors.info,           route: AppRoutes.coverageDashboard),
      (label: 'Report Cards', icon: Icons.workspace_premium_rounded,  color: AppColors.success,        route: AppRoutes.reportCardDashboard),
      (label: 'Assignments',  icon: Icons.assignment_rounded,         color: AppColors.warning,        route: AppRoutes.assignments),
      (label: 'Q. Papers',    icon: Icons.quiz_rounded,               color: AppColors.error,          route: AppRoutes.questionPaperList),
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(a.route),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(a.icon, color: a.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── School Operations grid ────────────────────────────────────────────────────
class _OperationsActionsGrid extends StatelessWidget {
  final BuildContext context;
  const _OperationsActionsGrid({required this.context});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (label: 'Admissions',  icon: Icons.how_to_reg_rounded,         color: AppColors.primary,        route: AppRoutes.admissionDashboard),
      (label: 'Calendar',    icon: Icons.event_rounded,               color: const Color(0xFF8B5CF6), route: AppRoutes.calendar),
      (label: 'Discipline',  icon: Icons.gavel_rounded,               color: AppColors.error,          route: AppRoutes.disciplineDashboard),
      (label: 'AI Insights', icon: Icons.psychology_rounded,          color: AppColors.info,           route: AppRoutes.riskDashboard),
      (label: 'Bulk Notify', icon: Icons.send_rounded,                color: AppColors.warning,        route: AppRoutes.bulkNotify),
      (label: 'Visitors',    icon: Icons.badge_outlined,              color: AppColors.success,        route: AppRoutes.visitorDashboard),
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(a.route),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(a.icon, color: a.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final String? badge;

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: accentColor),
          ],
        ),
      ),
    );
  }
}
