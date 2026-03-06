import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/visitor.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/visitor_provider.dart';
import '../widgets/visitor_stats_card.dart';

class VisitorDashboardScreen extends ConsumerStatefulWidget {
  const VisitorDashboardScreen({super.key});

  @override
  ConsumerState<VisitorDashboardScreen> createState() =>
      _VisitorDashboardScreenState();
}

class _VisitorDashboardScreenState
    extends ConsumerState<VisitorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(visitorLogNotifierProvider.notifier).loadTodayLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(visitorStatsProvider);
    final todayLogsAsync = ref.watch(visitorLogNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(visitorStatsProvider);
              ref.read(visitorLogNotifierProvider.notifier).loadTodayLogs();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(visitorStatsProvider);
          await ref
              .read(visitorLogNotifierProvider.notifier)
              .loadTodayLogs();
        },
        child: ListView(
          children: [
            const SizedBox(height: 8),
            // Stats
            statsAsync.when(
              data: (stats) => VisitorStatsCard(stats: stats),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading stats: $e'),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.login,
                      label: 'Check In',
                      color: AppColors.success,
                      onTap: () => context.push(AppRoutes.visitorCheckIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.logout,
                      label: 'Check Out',
                      color: AppColors.info,
                      onTap: () =>
                          context.push(AppRoutes.visitorCheckOut),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.event,
                      label: 'Pre-Register',
                      color: AppColors.accent,
                      onTap: () =>
                          context.push(AppRoutes.visitorPreRegister),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.list_alt,
                      label: 'Full Log',
                      color: AppColors.primary,
                      onTap: () => context.push(AppRoutes.visitorLog),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent log
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Visitor Log",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.visitorLog),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            todayLogsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.people_outline,
                              size: 48,
                              color: AppColors.textTertiaryLight),
                          const SizedBox(height: 8),
                          Text(
                            'No visitors today',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length > 10 ? 10 : logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _VisitorLogTile(log: log);
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VisitorLogTile extends StatelessWidget {
  final VisitorLog log;

  const _VisitorLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      onTap: () {
        if (log.visitor != null) {
          context.push(
            AppRoutes.visitorDetail
                .replaceFirst(':visitorId', log.visitor!.id),
          );
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _statusColor(log.status).withValues(alpha: 0.1),
            child: Icon(
              _statusIcon(log.status),
              color: _statusColor(log.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.visitor?.fullName ?? 'Visitor',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${log.purpose.label}${log.personToMeetName != null ? ' - ${log.personToMeetName}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(log.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _statusColor(log.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeFormat.format(log.checkInTime),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(VisitorLogStatus status) {
    switch (status) {
      case VisitorLogStatus.checkedIn:
        return AppColors.success;
      case VisitorLogStatus.checkedOut:
        return AppColors.info;
      case VisitorLogStatus.denied:
        return AppColors.error;
      case VisitorLogStatus.preRegistered:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(VisitorLogStatus status) {
    switch (status) {
      case VisitorLogStatus.checkedIn:
        return Icons.login;
      case VisitorLogStatus.checkedOut:
        return Icons.logout;
      case VisitorLogStatus.denied:
        return Icons.block;
      case VisitorLogStatus.preRegistered:
        return Icons.event;
    }
  }
}
