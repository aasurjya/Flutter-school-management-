import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/hr_provider.dart';
import '../widgets/contract_status_badge.dart';

class HRDashboardScreen extends ConsumerWidget {
  const HRDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(hrStatsProvider);
    final expiringAsync = ref.watch(expiringContractsProvider);
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    return Scaffold(
      appBar: AppBar(
        title: const Text('HR & Payroll'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(hrStatsProvider);
              ref.invalidate(expiringContractsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(hrStatsProvider);
          ref.invalidate(expiringContractsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GlassStatCard(
                            title: 'Total Staff',
                            value: '${stats.activeStaff}',
                            icon: Icons.people,
                            iconColor: AppColors.primary,
                            gradient: AppColors.primaryGradient,
                            onTap: () => context.push('/hr/staff-directory'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassStatCard(
                            title: 'Departments',
                            value: '${stats.totalDepartments}',
                            icon: Icons.business,
                            iconColor: AppColors.info,
                            onTap: () => context.push('/hr/departments'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GlassStatCard(
                            title: 'Monthly Payroll',
                            value: currencyFormat
                                .format(stats.monthlyPayrollEstimate),
                            icon: Icons.account_balance_wallet,
                            iconColor: AppColors.secondary,
                            gradient: AppColors.secondaryGradient,
                            onTap: () => context.push('/hr/payroll'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassStatCard(
                            title: 'Expiring Contracts',
                            value: '${stats.expiringContracts}',
                            icon: Icons.warning_amber,
                            iconColor: AppColors.warning,
                            onTap: () => context.push('/hr/contracts'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Today's Attendance
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.fact_check,
                                  color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Staff Attendance Today',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () =>
                                    context.push('/hr/staff-attendance'),
                                child: const Text('Mark'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _AttendanceStat(
                                label: 'Present',
                                value: stats.presentToday,
                                color: AppColors.success,
                              ),
                              _AttendanceStat(
                                label: 'Absent',
                                value: stats.absentToday,
                                color: AppColors.error,
                              ),
                              _AttendanceStat(
                                label: 'On Leave',
                                value: stats.onLeaveToday,
                                color: AppColors.info,
                              ),
                              _AttendanceStat(
                                label: 'Not Marked',
                                value: stats.activeStaff -
                                    stats.presentToday -
                                    stats.absentToday -
                                    stats.onLeaveToday,
                                color: AppColors.textTertiaryLight,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('Error: $error'),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _QuickActionsGrid(),

              const SizedBox(height: 24),

              // Expiring Contracts
              Text(
                'Expiring Contracts (30 days)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              expiringAsync.when(
                data: (contracts) {
                  if (contracts.isEmpty) {
                    return GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 48, color: AppColors.success),
                            const SizedBox(height: 8),
                            Text(
                              'No contracts expiring soon',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: contracts.map((contract) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.warning.withAlpha(30),
                            child: const Icon(Icons.schedule,
                                color: AppColors.warning),
                          ),
                          title: Text(contract.staffName ?? 'Unknown Staff'),
                          subtitle: Text(
                            'Expires: ${DateFormat('dd MMM yyyy').format(contract.endDate!)} (${contract.daysUntilExpiry} days)',
                          ),
                          trailing: ContractTypeBadge(
                              type: contract.contractType),
                          onTap: () =>
                              context.push('/hr/contracts'),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Error: $error'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AttendanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      const _QuickAction(
        icon: Icons.people,
        label: 'Staff Directory',
        color: AppColors.primary,
        route: '/hr/staff-directory',
      ),
      const _QuickAction(
        icon: Icons.business,
        label: 'Departments',
        color: AppColors.info,
        route: '/hr/departments',
      ),
      const _QuickAction(
        icon: Icons.description,
        label: 'Contracts',
        color: Color(0xFFF97316),
        route: '/hr/contracts',
      ),
      const _QuickAction(
        icon: Icons.account_balance_wallet,
        label: 'Payroll',
        color: AppColors.secondary,
        route: '/hr/payroll',
      ),
      const _QuickAction(
        icon: Icons.fact_check,
        label: 'Attendance',
        color: AppColors.warning,
        route: '/hr/staff-attendance',
      ),
      const _QuickAction(
        icon: Icons.receipt,
        label: 'Tax',
        color: AppColors.error,
        route: '/hr/tax-declarations',
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.1,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: actions.map((action) {
        return GlassCard(
          onTap: () => context.push(action.route),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}
