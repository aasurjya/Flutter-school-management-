import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logout_helper.dart';
import '../../../../data/models/invoice.dart';
import '../../../ai_insights/presentation/widgets/parent_ai_insights_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../ai_insights/providers/parent_digest_provider.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../fees/providers/fees_provider.dart';
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
          ref.invalidate(parentChildrenProvider);
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

                // Academic Quick Stats Grid (real data)
                const _QuickStatsSection(),
                const SizedBox(height: 32),

                // Weekly Attendance (real data)
                _buildSectionHeader(context, "Attendance Insights", "View Details",
                    () => context.push(AppRoutes.attendance)),
                const SizedBox(height: 16),
                const _WeeklyAttendanceSection(),
                const SizedBox(height: 32),

                // Fee Summary (real data)
                _buildSectionHeader(context, 'Financial Summary', 'Invoices',
                    () => context.push(AppRoutes.fees)),
                const SizedBox(height: 16),
                const _FeeSummarySection(),
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String? action,
    VoidCallback? onAction,
  ) {
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
            onPressed: onAction,
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
}

// ─── Quick Stats — reads attendance + rank from providers ────────────────────
class _QuickStatsSection extends ConsumerWidget {
  const _QuickStatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);
    final studentId = selectedChild?['student_id'] as String?;

    if (studentId == null) {
      return Row(
        children: [
          _ParentStatTile(label: 'Attendance', value: '--', icon: Icons.calendar_today_rounded, color: AppColors.grey400),
          const SizedBox(width: 12),
          _ParentStatTile(label: 'Class Rank', value: '--', icon: Icons.leaderboard_rounded, color: AppColors.grey400),
        ],
      );
    }

    final statsAsync = ref.watch(attendanceStatsProvider(studentId));

    return statsAsync.when(
      loading: () => Row(
        children: [
          _ParentStatTile(label: 'Attendance', value: '...', icon: Icons.calendar_today_rounded, color: AppColors.grey400),
          const SizedBox(width: 12),
          _ParentStatTile(label: 'Class Rank', value: '...', icon: Icons.leaderboard_rounded, color: AppColors.grey400),
        ],
      ),
      error: (_, __) => Row(
        children: [
          _ParentStatTile(label: 'Attendance', value: '--', icon: Icons.calendar_today_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          _ParentStatTile(label: 'Class Rank', value: '--', icon: Icons.leaderboard_rounded, color: AppColors.grey400),
        ],
      ),
      data: (stats) {
        final present = stats['present'] ?? 0;
        final total = present + (stats['absent'] ?? 0) + (stats['late'] ?? 0);
        final pct = total > 0 ? (present / total * 100).round() : 0;

        return Row(
          children: [
            _ParentStatTile(
              label: 'Attendance',
              value: '$pct%',
              icon: Icons.calendar_today_rounded,
              color: pct >= 90
                  ? AppColors.success
                  : pct >= 75
                      ? AppColors.info
                      : AppColors.error,
            ),
            const SizedBox(width: 12),
            _ParentStatTile(
              label: 'Class Rank',
              value: '--',
              icon: Icons.leaderboard_rounded,
              color: AppColors.info,
            ),
          ],
        );
      },
    );
  }
}

// ─── Weekly Attendance — reads real attendance data for current week ──────────
class _WeeklyAttendanceSection extends ConsumerWidget {
  const _WeeklyAttendanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);
    final studentId = selectedChild?['student_id'] as String?;

    if (studentId == null) {
      return _buildGrid(context, List.filled(6, null));
    }

    // Get this week's Mon-Sat
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final saturday = monday.add(const Duration(days: 5));

    final filter = StudentAttendanceFilter(
      studentId: studentId,
      startDate: monday,
      endDate: saturday,
    );

    final attendanceAsync = ref.watch(studentAttendanceProvider(filter));

    return attendanceAsync.when(
      loading: () => _buildGrid(context, List.filled(6, null)),
      error: (_, __) => _buildGrid(context, List.filled(6, null)),
      data: (records) {
        final dayStatus = <String?>[null, null, null, null, null, null];
        for (final record in records) {
          final date = record.date;
          final weekday = date.weekday; // 1=Mon, 6=Sat
          if (weekday >= 1 && weekday <= 6) {
            dayStatus[weekday - 1] = record.status.name;
          }
        }
        return _buildGrid(context, dayStatus);
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<String?> dayStatuses) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final todayIndex = DateTime.now().weekday - 1; // 0-based Mon

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
          final status = dayStatuses[index];
          final isPresent = status == 'present' || status == 'late';
          final isAbsent = status == 'absent';
          final hasData = status != null;
          final isToday = index == todayIndex;

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
                  color: hasData
                      ? (isPresent
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1))
                      : AppColors.grey100,
                  shape: BoxShape.circle,
                  border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
                ),
                child: hasData
                    ? Icon(
                        isAbsent ? Icons.close_rounded : Icons.check_rounded,
                        color: isPresent ? AppColors.success : AppColors.error,
                        size: 20,
                      )
                    : const Icon(Icons.remove, color: AppColors.grey300, size: 16),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Fee Summary — reads real invoices from provider ─────────────────────────
class _FeeSummarySection extends ConsumerWidget {
  const _FeeSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);
    final studentId = selectedChild?['student_id'] as String?;

    if (studentId == null) {
      return _buildEmpty();
    }

    final invoicesAsync = ref.watch(
      invoicesProvider(InvoicesFilter(studentId: studentId)),
    );

    return invoicesAsync.when(
      loading: () => _buildLoading(),
      error: (_, __) => _buildEmpty(),
      data: (invoices) {
        if (invoices.isEmpty) return _buildEmpty();

        final totalPending = invoices
            .where((inv) => !inv.isPaid && !inv.isCancelled)
            .fold<double>(0, (sum, inv) => sum + inv.pendingAmount);

        final pendingInvoices = invoices
            .where((inv) => !inv.isPaid && !inv.isCancelled)
            .toList();

        final hasOverdue = pendingInvoices.any((inv) => inv.isOverdueNow);
        final formatter = NumberFormat('#,##0', 'en_IN');

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
                      Text(
                        '₹${formatter.format(totalPending)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -1),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasOverdue
                          ? AppColors.error.withValues(alpha: 0.1)
                          : totalPending > 0
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasOverdue
                          ? 'Overdue'
                          : totalPending > 0
                              ? 'Pending'
                              : 'Paid',
                      style: TextStyle(
                        color: hasOverdue
                            ? AppColors.error
                            : totalPending > 0
                                ? AppColors.warning
                                : AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Show up to 3 pending invoices
              ...pendingInvoices.take(3).map((inv) {
                final label = (inv.notes?.isNotEmpty == true)
                    ? inv.notes!
                    : 'Invoice #${inv.invoiceNumber}';
                final pending = inv.totalAmount - inv.discountAmount - inv.paidAmount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeeItem(
                    label: label,
                    amount: '₹${formatter.format(pending)}',
                  ),
                );
              }),
              if (pendingInvoices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('All fees paid!', style: TextStyle(color: AppColors.success, fontSize: 12)),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.push(
                      AppRoutes.feePayment.replaceFirst(':childId', studentId),
                    );
                  },
                  child: Text(totalPending > 0 ? 'Proceed to Payment' : 'View Payment History'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Center(
        child: Text('No fee data available', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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

class _FeeItem extends StatelessWidget {
  final String label;
  final String amount;

  const _FeeItem({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
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
