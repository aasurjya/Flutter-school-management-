import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/services/sync_queue_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/attendance/providers/offline_attendance_provider.dart';

/// Screen showing all pending sync operations with manual sync/clear controls.
///
/// Registered at [AppRoutes.syncStatus] (`/sync-status`).
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.when(
      data: (v) => v,
      loading: () => true,
      error: (_, __) => true,
    );

    final pendingAttendance =
        ref.watch(offlineAttendanceProvider).pendingCount;
    final isSyncing = ref.watch(offlineAttendanceProvider).isSyncing;
    final lastError = ref.watch(offlineAttendanceProvider).lastError;

    final queueService = ref.watch(syncQueueProvider);
    final generalOps = queueService.getPendingOps();

    final totalPending = pendingAttendance + generalOps.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Sync Status',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.grey900),
        actions: [
          if (totalPending > 0)
            TextButton.icon(
              onPressed: isOnline && !isSyncing
                  ? () => _confirmClearAll(context, ref)
                  : null,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (isOnline) {
            await ref
                .read(offlineAttendanceProvider.notifier)
                .syncNow();
          }
        },
        child: CustomScrollView(
          slivers: [
            // ── Status card ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _StatusCard(
                isOnline: isOnline,
                totalPending: totalPending,
                isSyncing: isSyncing,
                lastError: lastError,
              ),
            ),

            // ── Sync Now button ────────────────────────────────────────
            if (totalPending > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: FilledButton.icon(
                    onPressed: isOnline && !isSyncing
                        ? () => ref
                            .read(offlineAttendanceProvider.notifier)
                            .syncNow()
                        : null,
                    icon: isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label:
                        Text(isSyncing ? 'Syncing…' : 'Sync Now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ),

            // ── Attendance queue section ────────────────────────────────
            if (pendingAttendance > 0) ...[
              _SectionHeader(
                title: 'Attendance',
                count: pendingAttendance,
              ),
              SliverToBoxAdapter(
                child: _AttendancePendingTile(count: pendingAttendance),
              ),
            ],

            // ── General queue section ───────────────────────────────────
            if (generalOps.isNotEmpty) ...[
              _SectionHeader(
                title: 'Other Operations',
                count: generalOps.length,
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final op = generalOps[index];
                    return _OperationTile(
                      op: op,
                      onDelete: () =>
                          _confirmClearOp(context, ref, op.id),
                    );
                  },
                  childCount: generalOps.length,
                ),
              ),
            ],

            // ── Empty state ─────────────────────────────────────────────
            if (totalPending == 0)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all pending operations?'),
        content: const Text(
          'This will permanently discard all unsynced changes. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(syncQueueProvider).clearAll();
    }
  }

  Future<void> _confirmClearOp(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this operation?'),
        content: const Text(
          'This unsynced change will be discarded permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(syncQueueProvider).clearOp(id);
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final bool isOnline;
  final int totalPending;
  final bool isSyncing;
  final Object? lastError;

  const _StatusCard({
    required this.isOnline,
    required this.totalPending,
    required this.isSyncing,
    this.lastError,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? AppColors.success : AppColors.warning;
    final statusIcon =
        isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;
    final statusText = isOnline ? 'Online' : 'Offline';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.grey900,
                        ),
                      ),
                      Text(
                        totalPending == 0
                            ? 'All changes synced'
                            : '$totalPending change${totalPending == 1 ? '' : 's'} pending sync',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSyncing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  ),
              ],
            ),
            if (lastError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Last sync failed: $lastError',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.grey500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendancePendingTile extends StatelessWidget {
  final int count;

  const _AttendancePendingTile({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Records',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.grey900,
                    ),
                  ),
                  Text(
                    '$count record${count == 1 ? '' : 's'} queued',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  final PendingOperation op;
  final VoidCallback onDelete;

  const _OperationTile({required this.op, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMM d, h:mm a').format(op.enqueuedAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_opLabel(op.operation)} \u2022 ${op.table}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.grey900,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                  if (op.data.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _dataSummary(op.data),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey400,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.grey400,
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  String _opLabel(String op) {
    switch (op) {
      case 'insert':
        return 'INSERT';
      case 'upsert':
        return 'UPSERT';
      case 'update':
        return 'UPDATE';
      case 'delete':
        return 'DELETE';
      default:
        return op.toUpperCase();
    }
  }

  String _dataSummary(Map<String, dynamic> data) {
    final entries = data.entries.take(3).map((e) => '${e.key}: ${e.value}');
    final suffix = data.length > 3 ? ', …' : '';
    return '{${entries.join(', ')}$suffix}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_done_outlined,
                color: AppColors.success,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'All synced',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No pending operations. All your data is up to date.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
