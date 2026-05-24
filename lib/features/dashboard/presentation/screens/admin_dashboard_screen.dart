import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/apple_list_section.dart';
import '../../../auth/providers/auth_provider.dart';

/// Apple-style admin / principal dashboard.
///
/// Admins use this screen as a launch surface — they're not "doing" a
/// task here, they're navigating to one. So the screen is grouped
/// links, not KPI cards. KPIs live where the data does (Reports tab,
/// Fees screen, etc.).
///
/// Four sections, Settings-style:
///   1. People       — Students, Staff, Admissions
///   2. Academic     — Classes, Timetable, Syllabus, Exams, Report cards
///   3. Operations   — Fees, Announcements, Reports, AI insights
///   4. School       — Branding, Payment gateways, ID card
///
/// Replaces the prior 1122-line gradient/glass/8-tile-grid/AI-narrative
/// screen. AI insights move to a single Operations entry that points
/// at the risk dashboard.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final scaffoldBg = AppColors.groupedBackgroundFor(brightness);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
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
                  _GreetingCard(),
                  _PeopleSection(),
                  _AcademicSection(),
                  _OperationsSection(),
                  _SchoolSection(),
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
// Greeting card
// ---------------------------------------------------------------------------

class _GreetingCard extends ConsumerWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final cellBg = AppColors.groupedCellFor(brightness);
    final secondary = AppColors.labelFor(brightness, tier: 2);
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.fullName ?? 'Administrator').split(' ').first;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Container(
          color: cellBg,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi $firstName.', style: theme.textTheme.displaySmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Manage your school from here.',
                style: theme.textTheme.bodySmall?.copyWith(color: secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// People — students, staff, admissions
// ---------------------------------------------------------------------------

class _PeopleSection extends StatelessWidget {
  const _PeopleSection();
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'People',
      children: [
        AppleListCell(
          leading: const Icon(Icons.school_outlined, size: 22),
          title: 'Students',
          showChevron: true,
          onTap: () => context.push(AppRoutes.studentManagement),
        ),
        AppleListCell(
          leading: const Icon(Icons.badge_outlined, size: 22),
          title: 'Staff',
          showChevron: true,
          onTap: () => context.push(AppRoutes.staffManagement),
        ),
        AppleListCell(
          leading: const Icon(Icons.how_to_reg_outlined, size: 22),
          title: 'Admissions',
          showChevron: true,
          onTap: () => context.push(AppRoutes.admissionDashboard),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Academic
// ---------------------------------------------------------------------------

class _AcademicSection extends StatelessWidget {
  const _AcademicSection();
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'Academic',
      children: [
        AppleListCell(
          leading: const Icon(Icons.class_outlined, size: 22),
          title: 'Classes',
          showChevron: true,
          onTap: () => context.push(AppRoutes.academicConfig),
        ),
        AppleListCell(
          leading: const Icon(Icons.calendar_view_week_outlined, size: 22),
          title: 'Timetable',
          showChevron: true,
          onTap: () => context.push(AppRoutes.timetable),
        ),
        AppleListCell(
          leading: const Icon(Icons.menu_book_outlined, size: 22),
          title: 'Syllabus coverage',
          showChevron: true,
          onTap: () => context.push(AppRoutes.coverageDashboard),
        ),
        AppleListCell(
          leading: const Icon(Icons.edit_document, size: 22),
          title: 'Exams',
          showChevron: true,
          onTap: () => context.push(AppRoutes.examManagement),
        ),
        AppleListCell(
          leading: const Icon(Icons.workspace_premium_outlined, size: 22),
          title: 'Report cards',
          showChevron: true,
          onTap: () => context.push(AppRoutes.reportCardDashboard),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Operations
// ---------------------------------------------------------------------------

class _OperationsSection extends StatelessWidget {
  const _OperationsSection();
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'Operations',
      children: [
        AppleListCell(
          leading: const Icon(Icons.account_balance_wallet_outlined, size: 22),
          title: 'Fees',
          showChevron: true,
          onTap: () => context.push(AppRoutes.feeManagement),
        ),
        AppleListCell(
          leading: const Icon(Icons.campaign_outlined, size: 22),
          title: 'Announcements',
          showChevron: true,
          onTap: () => context.push(AppRoutes.announcements),
        ),
        AppleListCell(
          leading: const Icon(Icons.assessment_outlined, size: 22),
          title: 'Reports',
          showChevron: true,
          onTap: () => context.push(AppRoutes.reports),
        ),
        AppleListCell(
          leading: const Icon(Icons.insights_outlined, size: 22),
          title: 'AI insights',
          subtitle: 'Risk, alerts, trends',
          showChevron: true,
          onTap: () => context.push(AppRoutes.riskDashboard),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// School — branding, payment gateway, ID card
// ---------------------------------------------------------------------------

class _SchoolSection extends StatelessWidget {
  const _SchoolSection();
  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      header: 'School',
      children: [
        AppleListCell(
          leading: const Icon(Icons.brush_outlined, size: 22),
          title: 'School branding',
          showChevron: true,
          onTap: () => context.push(AppRoutes.schoolBranding),
        ),
        AppleListCell(
          leading: const Icon(Icons.credit_card_outlined, size: 22),
          title: 'Payment gateways',
          showChevron: true,
          onTap: () => context.push(AppRoutes.paymentGateway),
        ),
        AppleListCell(
          leading: const Icon(Icons.qr_code_outlined, size: 22),
          title: 'My ID card',
          showChevron: true,
          onTap: () => context.push(AppRoutes.staffIdCard),
        ),
      ],
    );
  }
}
