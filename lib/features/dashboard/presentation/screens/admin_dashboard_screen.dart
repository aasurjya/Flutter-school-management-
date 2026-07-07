import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/preferences/ai_minimal_mode_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../../core/widgets/apple_list_section.dart';
import '../../../../data/models/leave.dart';
import '../../../ai_insights/presentation/widgets/admin_ai_narrative_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../leave/providers/leave_provider.dart';
import '../../providers/dashboard_kpis_provider.dart';
import '../../widgets/mv_backed_kpi_strip.dart';

/// Overhauled, high-end Admin / Principal Dashboard.
///
/// Designed around **Institutional Operations** and high-end university aesthetics.
/// Admins use this as a Command Console. It replaces basic boring lists with:
///   1. **Institution Pulse Grid** (School health metrics: attendance rate, leaves, alerts).
///   2. **Principal's Approval Queue** (Active operational items needing sign-off).
///   3. **Structured Category Ledgers** (Dual-column or clean asymmetric groupings of functions).
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final scaffoldBg = AppColors.groupedBackgroundFor(brightness);
    // AI summary card respects the same minimal-mode toggle as the AI cells.
    final minimal = ref.watch(aiMinimalModeProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(adminKpisProvider);
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
                  const _GreetingCard(),
                  const MvBackedKpiStrip(),
                  if (!minimal) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const AdminAINarrativeCard(),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const _PrincipalApprovalQueue(),
                  const SizedBox(height: AppSpacing.lg),
                  const _CommandLedgerSection(),
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
        'Console',
        style: theme.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontFamily: '.SF Pro Display',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, size: 26),
          tooltip: 'Notifications',
          onPressed: () => context.push(AppRoutes.notifications),
        ),
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
  const w = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  return w[weekday];
}

String _monthShort(int month) {
  const m = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return m[month];
}

// ---------------------------------------------------------------------------
// Editorial Greeting Card
// ---------------------------------------------------------------------------
class _GreetingCard extends ConsumerWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    final user = ref.watch(currentUserProvider);
    final firstName =
        NameUtils.firstNameOf(user?.fullName, fallback: 'Administrator');

    // Academic ivory/parchment neutral theme
    final cardBg = isDark ? const Color(0xFF1E1E1C) : const Color(0xFFFAF9F5);
    final borderCol =
        isDark ? const Color(0xFF3A3A36) : const Color(0xFFE8E6DF);
    final secondaryText =
        isDark ? const Color(0xFFB5B3AD) : const Color(0xFF706E67);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppRadius.card,
          border: Border.all(color: borderCol, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $firstName.',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.labelFor(brightness, tier: 1),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Institution Operational Console · Active Session',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: secondaryText, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Principal's Approval Queue — Active operational actions
// ---------------------------------------------------------------------------
class _PrincipalApprovalQueue extends ConsumerWidget {
  const _PrincipalApprovalQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final pendingAsync = ref.watch(
      leaveApplicationsProvider(const LeaveFilter(pendingOnly: true)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Text(
            'PENDING SIGN-OFFS & APPROVALS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.labelFor(brightness, tier: 2),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.groupedCellFor(brightness),
            borderRadius: AppRadius.card,
            border: Border.all(
                color: AppColors.separatorFor(brightness), width: 0.5),
          ),
          child: pendingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Text(
                "Couldn't load approvals.",
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.grey500),
              ),
            ),
            data: (applications) {
              if (applications.isEmpty) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All caught up — no pending leave requests.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.labelFor(brightness, tier: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final shown = applications.take(3).toList();
              return Column(
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) const Divider(height: 0.5),
                    _LeaveApprovalTile(application: shown[i]),
                  ],
                  if (applications.length > shown.length) ...[
                    const Divider(height: 0.5),
                    ListTile(
                      dense: true,
                      title: Text(
                        'View all ${applications.length} pending requests',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.primary),
                      onTap: () => context.push(AppRoutes.leave),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A single pending leave request in the principal's approval queue.
class _LeaveApprovalTile extends StatelessWidget {
  final LeaveApplication application;
  const _LeaveApprovalTile({required this.application});

  @override
  Widget build(BuildContext context) {
    final hasName = application.applicantName?.trim().isNotEmpty ?? false;
    final name = hasName ? application.applicantName!.trim() : 'Leave request';
    final days = application.duration;
    final klass = application.className;
    final subtitle = [
      if (klass != null && klass.trim().isNotEmpty) klass.trim(),
      application.leaveTypeDisplay,
      '$days day${days == 1 ? '' : 's'}',
    ].join(' · ');

    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child:
            const Icon(Icons.badge_outlined, size: 18, color: AppColors.info),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: TextButton(
        onPressed: () => context.push(AppRoutes.leave),
        child:
            const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Command Ledger Section — Structured grouped launch sections
// ---------------------------------------------------------------------------
class _CommandLedgerSection extends ConsumerWidget {
  const _CommandLedgerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minimal = ref.watch(aiMinimalModeProvider);

    return Column(
      children: [
        AppleListSection(
          header: 'PEOPLE MANAGEMENT',
          children: [
            AppleListCell(
              leading: const Icon(Icons.school_outlined, size: 20),
              title: 'Student Registrar',
              showChevron: true,
              onTap: () => context.push(AppRoutes.studentManagement),
            ),
            AppleListCell(
              leading: const Icon(Icons.badge_outlined, size: 20),
              title: 'Faculty & Staff Registry',
              showChevron: true,
              onTap: () => context.push(AppRoutes.staffManagement),
            ),
            AppleListCell(
              leading: const Icon(Icons.how_to_reg_outlined, size: 20),
              title: 'Admissions Panel',
              showChevron: true,
              onTap: () => context.push(AppRoutes.admissionDashboard),
            ),
          ],
        ),
        AppleListSection(
          header: 'ACADEMIC OPERATIONS',
          children: [
            AppleListCell(
              leading: const Icon(Icons.class_outlined, size: 20),
              title: 'Class & Section Structure',
              showChevron: true,
              onTap: () => context.push(AppRoutes.academicConfig),
            ),
            AppleListCell(
              leading: const Icon(Icons.calendar_view_week_outlined, size: 20),
              title: 'Master Timetable Grid',
              showChevron: true,
              onTap: () => context.push(AppRoutes.timetable),
            ),
            AppleListCell(
              leading: const Icon(Icons.menu_book_outlined, size: 20),
              title: 'Curriculum & Syllabus Status',
              showChevron: true,
              onTap: () => context.push(AppRoutes.coverageDashboard),
            ),
            AppleListCell(
              leading: const Icon(Icons.edit_document, size: 20),
              title: 'Examination Scheduling',
              showChevron: true,
              onTap: () => context.push(AppRoutes.examManagement),
            ),
            AppleListCell(
              leading: const Icon(Icons.workspace_premium_outlined, size: 20),
              title: 'Term Report Cards',
              showChevron: true,
              onTap: () => context.push(AppRoutes.reportCardDashboard),
            ),
          ],
        ),
        AppleListSection(
          header: 'OPERATIONS & STATS',
          children: [
            AppleListCell(
              leading:
                  const Icon(Icons.account_balance_wallet_outlined, size: 20),
              title: 'Financial Fee Accounts',
              showChevron: true,
              onTap: () => context.push(AppRoutes.feeManagement),
            ),
            AppleListCell(
              leading: const Icon(Icons.campaign_outlined, size: 20),
              title: 'School-Wide Announcements',
              showChevron: true,
              onTap: () => context.push(AppRoutes.announcements),
            ),
            AppleListCell(
              leading: const Icon(Icons.assessment_outlined, size: 20),
              title: 'Institutional Analytics',
              showChevron: true,
              onTap: () => context.push(AppRoutes.reports),
            ),
            if (!minimal)
              AppleListCell(
                leading: const Icon(Icons.insights_outlined, size: 20),
                title: 'Early Warning AI Insights',
                subtitle: 'Risk anomalies & indicators',
                showChevron: true,
                onTap: () => context.push(AppRoutes.riskDashboard),
              ),
          ],
        ),
        AppleListSection(
          header: 'INFRASTRUCTURE CONFIG',
          children: [
            AppleListCell(
              leading: const Icon(Icons.brush_outlined, size: 20),
              title: 'Portal Custom Branding',
              showChevron: true,
              onTap: () => context.push(AppRoutes.schoolBranding),
            ),
            AppleListCell(
              leading: const Icon(Icons.credit_card_outlined, size: 20),
              title: 'Merchant Gateways',
              showChevron: true,
              onTap: () => context.push(AppRoutes.paymentGateway),
            ),
            AppleListCell(
              leading: const Icon(Icons.qr_code_outlined, size: 20),
              title: 'Faculty ID Cards',
              showChevron: true,
              onTap: () => context.push(AppRoutes.staffIdCard),
            ),
          ],
        ),
      ],
    );
  }
}
