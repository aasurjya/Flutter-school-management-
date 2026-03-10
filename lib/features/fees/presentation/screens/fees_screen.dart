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
import '../../../auth/providers/auth_provider.dart';
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

class _AdminOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          const Row(
            children: [
              Expanded(
                child: GlassStatCard(
                  title: 'Total Collection',
                  value: '₹45.2L',
                  icon: Icons.account_balance_wallet,
                  iconColor: AppColors.success,
                  subtitle: 'This month',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: GlassStatCard(
                  title: 'Pending',
                  value: '₹12.8L',
                  icon: Icons.pending_actions,
                  iconColor: AppColors.warning,
                  subtitle: '234 students',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: GlassStatCard(
                  title: 'Overdue',
                  value: '₹4.5L',
                  icon: Icons.warning_amber,
                  iconColor: AppColors.error,
                  subtitle: '56 students',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: GlassStatCard(
                  title: 'Today',
                  value: '₹1.2L',
                  icon: Icons.today,
                  iconColor: AppColors.info,
                  subtitle: '12 payments',
                ),
              ),
            ],
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
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.send,
                label: 'Send\nReminders',
                color: AppColors.warning,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.download,
                label: 'Export\nReport',
                color: AppColors.success,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.settings,
                label: 'Fee\nStructure',
                color: AppColors.info,
                onTap: () {},
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
          ..._mockRecentPayments.map((payment) => _PaymentItem(
                studentName: payment['student'] as String,
                amount: payment['amount'] as String,
                date: payment['date'] as String,
                method: payment['method'] as String,
              )),
        ],
      ),
    );
  }
}

class _ParentOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending Payment Card
          GlassCard(
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
                      style: TextStyle(color: Colors.white70, fontSize: 14),
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
                      child: const Text(
                        'Due in 5 days',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '₹25,000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Pay Now'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Fee Breakdown
          const Text(
            'Fee Breakdown',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          const GlassCard(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _FeeBreakdownItem(
                  label: 'Tuition Fee (Term 2)',
                  amount: '₹20,000',
                  status: 'pending',
                ),
                Divider(height: 24),
                _FeeBreakdownItem(
                  label: 'Transport Fee',
                  amount: '₹3,000',
                  status: 'pending',
                ),
                Divider(height: 24),
                _FeeBreakdownItem(
                  label: 'Activity Fee',
                  amount: '₹2,000',
                  status: 'pending',
                ),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹25,000',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payment History
          const Text(
            'Payment History',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ..._mockPaymentHistory.map((payment) => _PaymentHistoryItem(
                description: payment['description'] as String,
                amount: payment['amount'] as String,
                date: payment['date'] as String,
                status: payment['status'] as String,
              )),
        ],
      ),
    );
  }
}

class _InvoicesTab extends StatelessWidget {
  final bool isAdmin;

  const _InvoicesTab({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockInvoices.length,
      itemBuilder: (context, index) {
        final invoice = _mockInvoices[index];
        return _InvoiceCard(
          invoiceNo: invoice['invoiceNo'] as String,
          studentName: invoice['student'] as String,
          amount: invoice['amount'] as String,
          dueDate: invoice['dueDate'] as String,
          status: invoice['status'] as String,
          isAdmin: isAdmin,
        );
      },
    );
  }
}

class _CollectionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: 'This Month',
                  decoration: const InputDecoration(
                    labelText: 'Period',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Today', 'This Week', 'This Month', 'This Term']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: 'All Classes',
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['All Classes', 'Class 10', 'Class 9', 'Class 8']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Collection Summary
          GlassCard(
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
                      onPressed: () {},
                      child: const Text('Export'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _CollectionRow(
                  label: 'Total Expected',
                  amount: '₹62.5L',
                  color: AppColors.info,
                ),
                const SizedBox(height: 12),
                const _CollectionRow(
                  label: 'Collected',
                  amount: '₹45.2L',
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                const _CollectionRow(
                  label: 'Pending',
                  amount: '₹12.8L',
                  color: AppColors.warning,
                ),
                const SizedBox(height: 12),
                const _CollectionRow(
                  label: 'Overdue',
                  amount: '₹4.5L',
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: 0.72,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                const Text(
                  '72% collected',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Class-wise Collection
          const Text(
            'Class-wise Collection',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ..._mockClassCollection.map((item) => _ClassCollectionItem(
                className: item['class'] as String,
                collected: item['collected'] as String,
                pending: item['pending'] as String,
                percentage: item['percentage'] as int,
              )),
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
  final String studentName;
  final String amount;
  final String dueDate;
  final String status;
  final bool isAdmin;

  const _InvoiceCard({
    required this.invoiceNo,
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
                  onPressed: () {},
                  child: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              if (status != 'paid')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
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

// Mock Data
final _mockRecentPayments = [
  {'student': 'Arjun Kumar', 'amount': '₹25,000', 'date': 'Today', 'method': 'UPI'},
  {'student': 'Priya Sharma', 'amount': '₹22,000', 'date': 'Yesterday', 'method': 'Card'},
  {'student': 'Rahul Singh', 'amount': '₹25,000', 'date': '2 days ago', 'method': 'Cash'},
];

final _mockPaymentHistory = [
  {'description': 'Term 1 Fee Payment', 'amount': '₹25,000', 'date': 'Aug 15, 2024', 'status': 'success'},
  {'description': 'Activity Fee', 'amount': '₹2,000', 'date': 'Jul 10, 2024', 'status': 'success'},
  {'description': 'Admission Fee', 'amount': '₹15,000', 'date': 'Apr 1, 2024', 'status': 'success'},
];

final _mockInvoices = [
  {'invoiceNo': 'INV-2024-001234', 'student': 'Arjun Kumar', 'amount': '₹25,000', 'dueDate': 'Dec 15, 2024', 'status': 'pending'},
  {'invoiceNo': 'INV-2024-001235', 'student': 'Priya Sharma', 'amount': '₹22,000', 'dueDate': 'Dec 10, 2024', 'status': 'overdue'},
  {'invoiceNo': 'INV-2024-001236', 'student': 'Rahul Singh', 'amount': '₹25,000', 'dueDate': 'Nov 30, 2024', 'status': 'paid'},
];

final _mockClassCollection = [
  {'class': 'Class 10', 'collected': '₹12.5L', 'pending': '₹2.5L', 'percentage': 83},
  {'class': 'Class 9', 'collected': '₹10.2L', 'pending': '₹3.8L', 'percentage': 73},
  {'class': 'Class 8', 'collected': '₹8.5L', 'pending': '₹1.5L', 'percentage': 85},
];

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
                  borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
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
