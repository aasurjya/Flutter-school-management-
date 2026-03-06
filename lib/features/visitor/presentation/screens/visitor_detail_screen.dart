import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/visitor.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/visitor_provider.dart';

class VisitorDetailScreen extends ConsumerWidget {
  final String visitorId;

  const VisitorDetailScreen({super.key, required this.visitorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final visitorAsync = ref.watch(visitorByIdProvider(visitorId));
    final logsAsync = ref.watch(visitorLogsProvider(
        VisitorLogFilter(visitorId: visitorId, limit: 50)));
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat.jm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Details'),
        actions: [
          visitorAsync.whenOrNull(
                data: (visitor) {
                  if (visitor == null) return const SizedBox.shrink();
                  return PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'blacklist') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(visitor.isBlacklisted
                                ? 'Remove from Blacklist?'
                                : 'Blacklist Visitor?'),
                            content: Text(visitor.isBlacklisted
                                ? 'This will allow the visitor to check in again.'
                                : 'This visitor will be prevented from checking in.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      visitor.isBlacklisted
                                          ? AppColors.success
                                          : AppColors.error,
                                ),
                                child: Text(visitor.isBlacklisted
                                    ? 'Remove'
                                    : 'Blacklist'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(visitorNotifierProvider.notifier)
                              .toggleBlacklist(
                                  visitorId, !visitor.isBlacklisted);
                          ref.invalidate(
                              visitorByIdProvider(visitorId));
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'blacklist',
                        child: Row(
                          children: [
                            Icon(
                              visitor.isBlacklisted
                                  ? Icons.check_circle
                                  : Icons.block,
                              color: visitor.isBlacklisted
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(visitor.isBlacklisted
                                ? 'Remove Blacklist'
                                : 'Blacklist'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: visitorAsync.when(
        data: (visitor) {
          if (visitor == null) {
            return const Center(child: Text('Visitor not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: visitor.isBlacklisted
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: visitor.photoUrl != null
                          ? NetworkImage(visitor.photoUrl!)
                          : null,
                      child: visitor.photoUrl == null
                          ? Text(
                              visitor.initials,
                              style: TextStyle(
                                fontSize: 24,
                                color: visitor.isBlacklisted
                                    ? AppColors.error
                                    : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      visitor.fullName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (visitor.isBlacklisted) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'BLACKLISTED',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _InfoColumn(
                          label: 'Total Visits',
                          value: '${visitor.visitCount}',
                        ),
                        _InfoColumn(
                          label: 'Member Since',
                          value: dateFormat.format(visitor.createdAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact info
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (visitor.phone != null)
                      _InfoRow(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: visitor.phone!),
                    if (visitor.email != null)
                      _InfoRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: visitor.email!),
                    if (visitor.company != null)
                      _InfoRow(
                          icon: Icons.business,
                          label: 'Company',
                          value: visitor.company!),
                    if (visitor.idType != null)
                      _InfoRow(
                          icon: Icons.badge,
                          label: 'ID Type',
                          value: visitor.idType!.label),
                    if (visitor.idNumber != null)
                      _InfoRow(
                          icon: Icons.numbers,
                          label: 'ID Number',
                          value: visitor.idNumber!),
                    if (visitor.phone == null &&
                        visitor.email == null &&
                        visitor.company == null)
                      Text(
                        'No contact information available',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Visit history
              Text(
                'Visit History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No visit history',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  _statusColor(log.status)
                                      .withValues(alpha: 0.1),
                              child: Icon(
                                _statusIcon(log.status),
                                color: _statusColor(log.status),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.purpose.label,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${dateFormat.format(log.checkInTime)} ${timeFormat.format(log.checkInTime)}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                      color:
                                          AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              log.durationString,
                              style:
                                  theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;

  const _InfoColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiaryLight),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
