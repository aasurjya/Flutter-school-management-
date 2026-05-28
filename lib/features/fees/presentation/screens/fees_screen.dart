import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/invoice.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../students/providers/students_provider.dart';
import '../../providers/fees_provider.dart';
import '../../utils/fees_pdf_builder.dart';
import '../tabs/invoices_tab.dart';
import '../tabs/risk_tab.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.isAdmin ?? false;

    return DefaultTabController(
      length: isAdmin ? 4 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fees & Payments'),
          bottom: TabBar(
            isScrollable: isAdmin,
            tabAlignment: isAdmin ? TabAlignment.start : TabAlignment.fill,
            tabs: [
              const Tab(text: 'Overview'),
              const Tab(text: 'Invoices'),
              if (isAdmin) const Tab(text: 'Collection'),
              if (isAdmin) const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_graph, size: 14),
                    SizedBox(width: 4),
                    Text('Risk'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(isAdmin: isAdmin),
            InvoicesTab(isAdmin: isAdmin),
            if (isAdmin) _CollectionTab(),
            if (isAdmin) const RiskTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final bool isAdmin;

  const _OverviewTab({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    if (isAdmin) {
      return _AdminOverview();
    }
    return _ParentOverview();
  }
}

class _AdminOverview extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends ConsumerState<_AdminOverview> {
  bool _exportingReport = false;

  Future<void> _sendBulkReminders() async {
    final repo = ref.read(feeRepositoryProvider);
    List<Invoice> overdueList;
    try {
      overdueList = await repo.getOverdueInvoices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(WarmCopy.loadFailed('the latest invoices'))),
        );
      }
      return;
    }

    if (!mounted) return;

    if (overdueList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No overdue invoices found')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Bulk Reminders'),
        content: Text(
          'Send reminders to ${overdueList.length} parent(s) with overdue fees?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    int sent = 0;
    for (final inv in overdueList) {
      try {
        await repo.logReminderSent(
          invoiceId: inv.id,
          studentId: inv.studentId,
          messageText:
              'Dear Parent, your fee of ₹${inv.pendingAmount.toStringAsFixed(0)} '
              'for invoice ${inv.invoiceNumber} is overdue. '
              'Please arrange payment at the earliest.',
          riskScore: 0,
          channel: 'bulk_app',
        );
        sent++;
      } catch (_) {
        // Continue sending remaining even if one fails
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminders sent to $sent parent(s)'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _exportReport() async {
    if (_exportingReport) return;
    setState(() => _exportingReport = true);
    try {
      final repo = ref.read(feeRepositoryProvider);
      final invoices = await repo.getInvoices();
      await FeesPdfBuilder.buildAndShare(invoices);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(feeCollectionStatsProvider(null));
    final recentPaymentsAsync = ref.watch(
      paymentsProvider(const PaymentsFilter()),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards from real stats
          statsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(WarmCopy.loadFailed('the stats'))),
                    TextButton(
                      onPressed: () => ref.invalidate(feeCollectionStatsProvider(null)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (stats) {
              final collected = stats['total_collected'] ?? 0.0;
              final pending = stats['total_pending'] ?? 0.0;
              final overdue = stats['total_overdue'] ?? 0.0;
              final todayCollected = stats['today_collected'] ?? 0.0;

              String fmtAmount(double v) {
                if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
                if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
                return '₹${v.toStringAsFixed(0)}';
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassStatCard(
                          title: 'Total Collection',
                          value: fmtAmount(collected),
                          icon: Icons.account_balance_wallet,
                          iconColor: AppColors.success,
                          subtitle: 'All time',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassStatCard(
                          title: 'Pending',
                          value: fmtAmount(pending),
                          icon: Icons.pending_actions,
                          iconColor: AppColors.warning,
                          subtitle: 'Outstanding',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassStatCard(
                          title: 'Overdue',
                          value: fmtAmount(overdue),
                          icon: Icons.warning_amber,
                          iconColor: AppColors.error,
                          subtitle: 'Past due date',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassStatCard(
                          title: 'Today',
                          value: fmtAmount(todayCollected),
                          icon: Icons.today,
                          iconColor: AppColors.info,
                          subtitle: "Today's collection",
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickAction(
                icon: Icons.receipt_long,
                label: 'Generate\nInvoices',
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.feeManagement),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.send,
                label: 'Send\nReminders',
                color: AppColors.warning,
                onTap: _sendBulkReminders,
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.download,
                label: 'Export\nReport',
                color: AppColors.success,
                onTap: _exportingReport ? () {} : _exportReport,
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.settings,
                label: 'Fee\nStructure',
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.feeStructures),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Payments
          const Text(
            'Recent Payments',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          recentPaymentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                WarmCopy.loadFailed('payments'),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            data: (payments) {
              if (payments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No recent payments')),
                );
              }
              // Show up to 10 most recent
              final recent = payments.take(10).toList();
              return Column(
                children: recent.map((payment) {
                  final dateStr = payment.paidAt != null
                      ? DateFormat('d MMM').format(payment.paidAt!)
                      : '—';
                  final amountStr = '₹${payment.amount.toStringAsFixed(0)}';
                  return _PaymentItem(
                    studentName: payment.studentName ?? 'Unknown',
                    amount: amountStr,
                    date: dateStr,
                    method: payment.paymentMethodDisplay,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ParentOverview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(currentStudentProvider);

    return studentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(WarmCopy.loadFailed('student data')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(currentStudentProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (student) {
        final studentId = student?.id;
        if (studentId == null) {
          return const Center(child: Text('No student profile found'));
        }

        final summaryAsync = ref.watch(
          studentFeeSummaryProvider(StudentFeeFilter(studentId: studentId)),
        );
        final invoicesAsync = ref.watch(
          invoicesProvider(InvoicesFilter(studentId: studentId)),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Payment Card
              summaryAsync.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(WarmCopy.loadFailed('the fee summary')),
                  ),
                ),
                data: (summary) {
                  final totalPending = summary?.totalPending ?? 0.0;
                  final pendingInvoices = summary?.pendingInvoices ?? 0;
                  final overdueCount = summary?.overdueInvoices ?? 0;

                  String dueLabel = 'No amount due';
                  if (overdueCount > 0) {
                    dueLabel = '$overdueCount invoice(s) overdue';
                  } else if (pendingInvoices > 0) {
                    dueLabel = '$pendingInvoices pending invoice(s)';
                  }

                  return GlassCard(
                    padding: const EdgeInsets.all(20),
                    gradient: AppColors.primaryGradient,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Due',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                dueLabel,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${totalPending.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (totalPending > 0) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.push(AppRoutes.fees),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.error,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Pay Now'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Fee Breakdown from invoices
              const Text(
                'Fee Breakdown',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              invoicesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  WarmCopy.loadFailed('invoices'),
                  style: const TextStyle(color: AppColors.error),
                ),
                data: (invoices) {
                  if (invoices.isEmpty) {
                    return const GlassCard(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No invoices found')),
                    );
                  }
                  // Show pending/overdue invoices in breakdown, up to 5
                  final pending = invoices
                      .where((inv) => !inv.isPaid && !inv.isCancelled)
                      .take(5)
                      .toList();
                  final totalPending = pending.fold<double>(
                      0, (sum, inv) => sum + inv.pendingAmount);

                  if (pending.isEmpty) {
                    return const GlassCard(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppColors.success, size: 32),
                          SizedBox(height: 8),
                          Text('All fees paid!',
                              style: TextStyle(color: AppColors.success)),
                        ],
                      ),
                    );
                  }

                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ...pending.expand((inv) => [
                              _FeeBreakdownItem(
                                label:
                                    '${inv.invoiceNumber}${inv.termName != null ? ' (${inv.termName})' : ''}',
                                amount:
                                    '₹${inv.pendingAmount.toStringAsFixed(0)}',
                                status: inv.status,
                              ),
                              const Divider(height: 24),
                            ]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${totalPending.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Payment History from paid invoices
              const Text(
                'Payment History',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              invoicesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox.shrink(),
                data: (invoices) {
                  final paid = invoices
                      .where((inv) => inv.isPaid)
                      .take(10)
                      .toList();
                  if (paid.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: Text('No payment history yet')),
                    );
                  }
                  return Column(
                    children: paid.map((inv) {
                      final dateStr = inv.updatedAt != null
                          ? DateFormat('d MMM, yyyy').format(inv.updatedAt!)
                          : '—';
                      return _PaymentHistoryItem(
                        description:
                            'Invoice ${inv.invoiceNumber}${inv.termName != null ? ' — ${inv.termName}' : ''}',
                        amount: '₹${inv.paidAmount.toStringAsFixed(0)}',
                        date: dateStr,
                        status: 'success',
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CollectionTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends ConsumerState<_CollectionTab> {
  bool _exportingCollection = false;

  Future<void> _exportCollectionReport() async {
    if (_exportingCollection) return;
    setState(() => _exportingCollection = true);
    try {
      final repo = ref.read(feeRepositoryProvider);
      final invoices = await repo.getInvoices();
      await FeesPdfBuilder.buildAndShare(invoices);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingCollection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(feeCollectionStatsProvider(null));
    final summariesAsync = ref.watch(
      feeSummariesProvider(const FeeSummaryFilter()),
    );

    String fmtAmount(double v) {
      if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
      if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
      return '₹${v.toStringAsFixed(0)}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Collection Summary from real stats
          statsAsync.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(WarmCopy.loadFailed('the stats'))),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(feeCollectionStatsProvider(null)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (stats) {
              final collected = stats['total_collected'] ?? 0.0;
              final pending = stats['total_pending'] ?? 0.0;
              final overdue = stats['total_overdue'] ?? 0.0;
              final total = collected + pending;
              final pct = total > 0 ? collected / total : 0.0;

              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Collection Summary',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: _exportingCollection
                              ? null
                              : _exportCollectionReport,
                          child: const Text('Export'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _CollectionRow(
                      label: 'Total Expected',
                      amount: fmtAmount(total),
                      color: AppColors.info,
                    ),
                    const SizedBox(height: 12),
                    _CollectionRow(
                      label: 'Collected',
                      amount: fmtAmount(collected),
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    _CollectionRow(
                      label: 'Pending',
                      amount: fmtAmount(pending - overdue),
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 12),
                    _CollectionRow(
                      label: 'Overdue',
                      amount: fmtAmount(overdue),
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.success),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}% collected',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Class-wise Collection from fee summaries grouped by class
          const Text(
            'Class-wise Collection',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          summariesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              WarmCopy.loadFailed('class data'),
              style: const TextStyle(color: AppColors.error),
            ),
            data: (summaries) {
              if (summaries.isEmpty) {
                return const Center(
                    child: Text('No class collection data available'));
              }

              // Group by className
              final byClass = <String, List<FeeSummary>>{};
              for (final s in summaries) {
                byClass.putIfAbsent(s.className, () => []).add(s);
              }

              return Column(
                children: byClass.entries.map((entry) {
                  final className = entry.key;
                  final items = entry.value;
                  final totalPaid = items.fold<double>(
                      0, (sum, s) => sum + s.totalPaid);
                  final totalFee = items.fold<double>(
                      0, (sum, s) => sum + s.totalFee);
                  final totalPending = items.fold<double>(
                      0, (sum, s) => sum + s.totalPending);
                  final pct =
                      totalFee > 0 ? (totalPaid / totalFee * 100).round() : 0;

                  return _ClassCollectionItem(
                    className: className,
                    collected: fmtAmount(totalPaid),
                    pending: fmtAmount(totalPending),
                    percentage: pct,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Widget Components
class _QuickAction extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final String studentName;
  final String amount;
  final String date;
  final String method;

  const _PaymentItem({
    required this.studentName,
    required this.amount,
    required this.date,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '$method • $date',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeBreakdownItem extends StatelessWidget {
  final String label;
  final String amount;
  final String status;

  const _FeeBreakdownItem({
    required this.label,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: status == 'pending'
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status == 'pending' ? 'Pending' : 'Paid',
                style: TextStyle(
                  fontSize: 10,
                  color: status == 'pending' ? AppColors.warning : AppColors.success,
                ),
              ),
            ),
          ],
        ),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PaymentHistoryItem extends StatelessWidget {
  final String description;
  final String amount;
  final String date;
  final String status;

  const _PaymentHistoryItem({
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            status == 'success' ? Icons.check_circle : Icons.receipt,
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}


// ──────────────────────────────────────────────
// Collection Row
// ──────────────────────────────────────────────

class _CollectionRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _CollectionRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        Text(
          amount,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _ClassCollectionItem extends StatelessWidget {
  final String className;
  final String collected;
  final String pending;
  final int percentage;

  const _ClassCollectionItem({
    required this.className,
    required this.collected,
    required this.pending,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(className, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: percentage >= 80 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(
              percentage >= 80 ? AppColors.success : AppColors.warning,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collected: $collected',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Pending: $pending',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

