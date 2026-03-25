import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/ai_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/fee_default_prediction.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/invoice.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../students/providers/students_provider.dart';
import '../../providers/fees_provider.dart';

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
            _InvoicesTab(isAdmin: isAdmin),
            if (isAdmin) _CollectionTab(),
            if (isAdmin) const _RiskTab(),
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

class _AdminOverview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    Expanded(child: Text('Failed to load stats: $e')),
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invoice generation coming soon')),
                  );
                },
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.send,
                label: 'Send\nReminders',
                color: AppColors.warning,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Send reminders coming soon')),
                  );
                },
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.download,
                label: 'Export\nReport',
                color: AppColors.success,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export report coming soon')),
                  );
                },
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.settings,
                label: 'Fee\nStructure',
                color: AppColors.info,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fee structure coming soon')),
                  );
                },
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
                'Failed to load payments: $e',
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
            Text('Failed to load student data: $e'),
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
                    child: Text('Failed to load fee summary: $e'),
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
                  'Failed to load invoices: $e',
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

class _InvoicesTab extends ConsumerStatefulWidget {
  final bool isAdmin;

  const _InvoicesTab({required this.isAdmin});

  @override
  ConsumerState<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends ConsumerState<_InvoicesTab> {
  static const int _pageSize = 20;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    // For admin: load all invoices; for student/parent: load by student
    final studentId =
        (currentUser?.isAdmin ?? false) ? null : currentUser?.id;

    final invoicesAsync = ref.watch(
      invoicesProvider(InvoicesFilter(studentId: studentId)),
    );

    return invoicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load invoices: $e'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(
                invoicesProvider(InvoicesFilter(studentId: studentId)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (invoices) {
        if (invoices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No invoices found'),
              ],
            ),
          );
        }

        // Client-side pagination
        final start = _page * _pageSize;
        final end = (start + _pageSize).clamp(0, invoices.length);
        final page = invoices.sublist(start, end);
        final hasMore = end < invoices.length;
        final hasPrev = _page > 0;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: page.length,
                itemBuilder: (context, index) {
                  final invoice = page[index];
                  final dueDateStr =
                      DateFormat('d MMM, yyyy').format(invoice.dueDate);
                  final amountStr =
                      '₹${invoice.pendingAmount.toStringAsFixed(0)}';
                  return _InvoiceCard(
                    invoiceNo: invoice.invoiceNumber,
                    invoiceId: invoice.id,
                    studentName: invoice.studentName ?? '—',
                    amount: amountStr,
                    dueDate: dueDateStr,
                    status: invoice.status,
                    isAdmin: widget.isAdmin,
                  );
                },
              ),
            ),
            if (hasPrev || hasMore)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: hasPrev
                          ? () => setState(() => _page--)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                    ),
                    Text(
                      'Page ${_page + 1}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    TextButton.icon(
                      onPressed: hasMore
                          ? () => setState(() => _page++)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CollectionTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    Expanded(child: Text('Failed to load stats: $e')),
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Export collection report coming soon')),
                            );
                          },
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
              'Failed to load class data: $e',
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

class _InvoiceCard extends StatelessWidget {
  final String invoiceNo;
  final String invoiceId;
  final String studentName;
  final String amount;
  final String dueDate;
  final String status;
  final bool isAdmin;

  const _InvoiceCard({
    required this.invoiceNo,
    required this.invoiceId,
    required this.studentName,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'paid'
        ? AppColors.success
        : status == 'overdue'
            ? AppColors.error
            : AppColors.warning;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoiceNo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isAdmin) ...[
            Text(studentName),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Due: $dueDate',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invoice $invoiceNo detail coming soon')),
                    );
                  },
                  child: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              if (status != 'paid')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(
                        AppRoutes.paymentCheckout.replaceFirst(':invoiceId', invoiceId),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      isAdmin ? 'Record Payment' : 'Pay Now',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

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

// =============================================================
// Risk Tab — Predictive Fee Collection Intelligence
// =============================================================

class _RiskTab extends ConsumerStatefulWidget {
  const _RiskTab();

  @override
  ConsumerState<_RiskTab> createState() => _RiskTabState();
}

class _RiskTabState extends ConsumerState<_RiskTab> {
  FeeRiskLevel? _filterLevel;

  @override
  Widget build(BuildContext context) {
    final predictionsAsync = ref.watch(feeDefaultPredictionsProvider);

    return predictionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Failed to load risk data'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(feeDefaultPredictionsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (predictions) {
        final summary = FeeDefaultSummary.from(predictions);
        final filtered = _filterLevel == null
            ? predictions
            : predictions
                .where((p) => p.riskLevel == _filterLevel)
                .toList();

        return Column(
          children: [
            _buildSummaryHeader(context, summary),
            _buildFilterChips(summary),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _PredictionCard(prediction: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(
      BuildContext context, FeeDefaultSummary summary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.8),
            Colors.orange.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Fee Collection Risk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${summary.totalAtRisk} accounts at risk',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${summary.formattedAmountAtRisk} at stake',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RiskCountBadge(
                  label: 'High',
                  count: summary.highRiskCount,
                  color: Colors.red[200]!),
              const SizedBox(width: 8),
              _RiskCountBadge(
                  label: 'Medium',
                  count: summary.mediumRiskCount,
                  color: Colors.orange[200]!),
              const SizedBox(width: 8),
              _RiskCountBadge(
                  label: 'Low',
                  count: summary.lowRiskCount,
                  color: Colors.green[200]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(FeeDefaultSummary summary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'All (${summary.totalAtRisk})',
            selected: _filterLevel == null,
            color: Colors.grey,
            onTap: () => setState(() => _filterLevel = null),
          ),
          const SizedBox(width: 8),
          ...FeeRiskLevel.values.map((level) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label:
                      '${level.label.split(" ").first} (${level == FeeRiskLevel.high ? summary.highRiskCount : level == FeeRiskLevel.medium ? summary.mediumRiskCount : summary.lowRiskCount})',
                  selected: _filterLevel == level,
                  color: level.color,
                  onTap: () =>
                      setState(() => _filterLevel = level),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle,
              size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          const Text(
            'No at-risk accounts!',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _filterLevel == null
                ? 'All fee accounts are in good standing.'
                : 'No ${_filterLevel!.label.toLowerCase()} accounts found.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// Prediction Card
// =============================================================

class _PredictionCard extends ConsumerStatefulWidget {
  final FeeDefaultPrediction prediction;

  const _PredictionCard({required this.prediction});

  @override
  ConsumerState<_PredictionCard> createState() =>
      _PredictionCardState();
}

class _PredictionCardState extends ConsumerState<_PredictionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prediction;
    final level = p.riskLevel;
    final dateStr = DateFormat('d MMM yyyy').format(p.dueDate);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // ===== Header row =====
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Risk score circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: level.bgColor,
                      border: Border.all(
                          color: level.borderColor, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${p.riskScore}',
                        style: TextStyle(
                          color: level.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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
                                p.studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: level.bgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: level.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(level.icon,
                                      size: 11, color: level.color),
                                  const SizedBox(width: 3),
                                  Text(
                                    level.label.split(' ').first,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: level.color,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${p.className} • ${p.invoiceNumber}',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₹${_formatAmount(p.amountDue)} due',
                              style: TextStyle(
                                color: level.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              p.isOverdue
                                  ? '${p.daysOverdue}d overdue'
                                  : 'Due $dateStr',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: p.isOverdue
                                      ? Colors.red
                                      : Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // ===== Risk score bar =====
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.riskScore / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(level.color),
                minHeight: 4,
              ),
            ),
          ),

          // ===== Expanded details =====
          if (_expanded) ...[
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Risk factors
                  if (p.riskFactors.isNotEmpty) ...[
                    const Text(
                      'Risk Factors',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    ...p.riskFactors.map((factor) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.arrow_right,
                                  size: 16, color: level.color),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(factor,
                                    style: const TextStyle(
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 10),
                  ],

                  // Recommended action
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 16, color: AppColors.info),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.recommendedAction,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (p.lastReminderAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last reminder: ${DateFormat("d MMM, hh:mm a").format(p.lastReminderAt!.toLocal())}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: p.reminderSentRecently
                              ? null
                              : () => _showReminderDialog(context),
                          icon: const Icon(Icons.message_outlined,
                              size: 16),
                          label: Text(p.reminderSentRecently
                              ? 'Sent Today'
                              : 'Send Reminder'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showInstallmentDialog(context),
                          icon: const Icon(Icons.payment, size: 16),
                          label: const Text('Create Plan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: level.color,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          _ReminderDialog(prediction: widget.prediction),
    );
  }

  void _showInstallmentDialog(BuildContext context) {
    final p = widget.prediction;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Installment Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${p.studentName}'),
            Text('Invoice: ${p.invoiceNumber}'),
            Text(
                'Amount: ₹${_formatAmount(p.amountDue)}'),
            const SizedBox(height: 12),
            const Text(
              'Split this amount into monthly installments and set a payment schedule for this family.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.feeManagement);
            },
            child: const Text('Create Plan'),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      final formatted =
          amount.toStringAsFixed(0).replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (m) => '${m[1]},',
              );
      return formatted;
    }
    return amount.toStringAsFixed(0);
  }
}

// =============================================================
// Reminder Dialog — AI-generated reminder message
// =============================================================

class _ReminderDialog extends ConsumerStatefulWidget {
  final FeeDefaultPrediction prediction;

  const _ReminderDialog({required this.prediction});

  @override
  ConsumerState<_ReminderDialog> createState() =>
      _ReminderDialogState();
}

class _ReminderDialogState extends ConsumerState<_ReminderDialog> {
  bool _loading = true;
  bool _sending = false;
  String _message = '';
  bool _isAiGenerated = false;

  @override
  void initState() {
    super.initState();
    _generateMessage();
  }

  Future<void> _generateMessage() async {
    final p = widget.prediction;
    final ai = ref.read(aiTextGeneratorProvider);

    final dueDateStr = DateFormat('d MMM yyyy').format(p.dueDate);
    final overdueText = p.isOverdue
        ? 'overdue by ${p.daysOverdue} day(s)'
        : 'due on $dueDateStr';
    final fallback =
        'Dear Parent,\n\nThis is a reminder that the fee payment of '
        '₹${p.amountDue.toStringAsFixed(0)} for ${p.studentName} '
        '(${p.className}) is $overdueText. '
        'Please arrange payment at the earliest to avoid inconvenience.\n\n'
        'Regards,\n[School Name]';

    final result = await ai.generateFeeReminderMessage(
      parentName: 'Parent',
      studentName: p.studentName,
      className: p.className,
      amountDue: p.amountDue,
      daysOverdue: p.daysOverdue,
      riskScore: p.riskScore,
      recommendedAction: p.recommendedAction,
      riskFactors: p.riskFactors,
      fallback: fallback,
    );

    if (mounted) {
      setState(() {
        _message = result.text;
        _isAiGenerated = result.isLLMGenerated;
        _loading = false;
      });
    }
  }

  Future<void> _sendReminder() async {
    setState(() => _sending = true);
    try {
      final repo = ref.read(feeRepositoryProvider);
      await repo.logReminderSent(
        invoiceId: widget.prediction.invoiceId,
        studentId: widget.prediction.studentId,
        messageText: _message,
        riskScore: widget.prediction.riskScore,
      );
      ref.invalidate(feeDefaultPredictionsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder logged successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log reminder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.message_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Fee Reminder Message')),
          if (_isAiGenerated && !_loading)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_fix_high,
                      size: 10, color: AppColors.accent),
                  SizedBox(width: 2),
                  Text('AI',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.accent)),
                ],
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For: ${widget.prediction.studentName} (${widget.prediction.className})',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      _message,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
      ),
      actions: _loading
          ? null
          : [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: _sending ? null : _sendReminder,
                icon: _sending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, size: 16),
                label: const Text('Log & Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
    );
  }
}

// =============================================================
// Small helper widgets
// =============================================================

class _RiskCountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RiskCountBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: selected ? 0 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
