import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../data/models/whatsapp_config.dart';
import '../../providers/whatsapp_provider.dart';

class NotificationLogScreen extends ConsumerStatefulWidget {
  const NotificationLogScreen({super.key});

  @override
  ConsumerState<NotificationLogScreen> createState() =>
      _NotificationLogScreenState();
}

class _NotificationLogScreenState
    extends ConsumerState<NotificationLogScreen> {
  NotificationChannel? _channelFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(notificationLogsProvider);
    final statsAsync = ref.watch(deliveryStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(notificationLogsProvider);
              ref.invalidate(deliveryStatsProvider);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats row (Stripe-style) ──────────────────────────
          statsAsync.when(
            data: (stats) => _StatsRow(stats: stats),
            loading: () => const SizedBox(height: 72),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Filter chips ──────────────────────────────────────
          _buildFilterChips(theme),

          // ── Log list ─────────────────────────────────────────
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                final filtered = _channelFilter == null
                    ? logs
                    : logs
                        .where((l) => l.channel == _channelFilter)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _channelFilter != null
                              ? 'No ${_channelFilter!.label} logs found'
                              : 'No notification logs yet',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notificationLogsProvider);
                    ref.invalidate(deliveryStatsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _LogTile(log: filtered[i]),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, st) => AppErrorWidget(
                message: 'Failed to load logs',
                onRetry: () => ref.invalidate(notificationLogsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    const channels = NotificationChannel.values;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _channelFilter == null,
              onSelected: (_) => setState(() => _channelFilter = null),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
            ),
          ),
          ...channels.map(
            (ch) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(ch.label),
                avatar: Icon(
                  _iconForChannel(ch),
                  size: 16,
                  color: _colorForChannel(ch),
                ),
                selected: _channelFilter == ch,
                onSelected: (_) =>
                    setState(() => _channelFilter = ch),
                selectedColor:
                    _colorForChannel(ch).withValues(alpha: 0.15),
                checkmarkColor: _colorForChannel(ch),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForChannel(NotificationChannel ch) {
    switch (ch) {
      case NotificationChannel.whatsapp:
        return Icons.chat_outlined;
      case NotificationChannel.sms:
        return Icons.sms_outlined;
      case NotificationChannel.email:
        return Icons.email_outlined;
      case NotificationChannel.push:
        return Icons.notifications_outlined;
    }
  }

  static Color _colorForChannel(NotificationChannel ch) {
    switch (ch) {
      case NotificationChannel.whatsapp:
        return const Color(0xFF25D366);
      case NotificationChannel.sms:
        return AppColors.info;
      case NotificationChannel.email:
        return AppColors.accent;
      case NotificationChannel.push:
        return AppColors.primary;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Stats Row — Stripe style: big numbers, no containers
// ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final sent = stats['sent'] ?? 0;
    final delivered = stats['delivered'] ?? 0;
    final failed = stats['failed'] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Sent',
            value: '$sent',
            color: AppColors.info,
          ),
          const _StatDivider(),
          _StatItem(
            label: 'Delivered',
            value: '$delivered',
            color: AppColors.success,
          ),
          const _StatDivider(),
          _StatItem(
            label: 'Failed',
            value: '$failed',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.borderLight,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Log Tile
// ─────────────────────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  final NotificationLog log;

  const _LogTile({required this.log});

  static IconData _iconFor(NotificationChannel ch) {
    switch (ch) {
      case NotificationChannel.whatsapp:
        return Icons.chat_outlined;
      case NotificationChannel.sms:
        return Icons.sms_outlined;
      case NotificationChannel.email:
        return Icons.email_outlined;
      case NotificationChannel.push:
        return Icons.notifications_outlined;
    }
  }

  static Color _colorFor(NotificationChannel ch) {
    switch (ch) {
      case NotificationChannel.whatsapp:
        return const Color(0xFF25D366);
      case NotificationChannel.sms:
        return AppColors.info;
      case NotificationChannel.email:
        return AppColors.accent;
      case NotificationChannel.push:
        return AppColors.primary;
    }
  }

  StatusChip _statusChip() {
    switch (log.status) {
      case NotificationStatus.delivered:
        return const StatusChip(
            label: 'Delivered', type: StatusType.success);
      case NotificationStatus.failed:
        return const StatusChip(
            label: 'Failed', type: StatusType.error);
      case NotificationStatus.pending:
        return const StatusChip(
            label: 'Pending', type: StatusType.warning);
      case NotificationStatus.sent:
        return const StatusChip(label: 'Sent', type: StatusType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channelColor = _colorFor(log.channel);
    final fmt = DateFormat('MMM d, h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: channelColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconFor(log.channel),
              size: 18,
              color: channelColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.recipientName ?? log.recipientPhone ?? 'Unknown',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _statusChip(),
                  ],
                ),
                if (log.recipientPhone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.recipientPhone!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
                if (log.messageBody != null &&
                    log.messageBody!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.messageBody!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (log.errorMessage != null &&
                    log.errorMessage!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${log.errorMessage}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  log.sentAt != null ? fmt.format(log.sentAt!) : '',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
