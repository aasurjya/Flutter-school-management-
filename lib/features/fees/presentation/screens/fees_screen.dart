import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.isAdmin ?? false;

    return DefaultTabController(
      length: isAdmin ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fees & Payments'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Overview'),
              const Tab(text: 'Invoices'),
              if (isAdmin) const Tab(text: 'Collection'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(isAdmin: isAdmin),
            _InvoicesTab(isAdmin: isAdmin),
            if (isAdmin) _CollectionTab(),
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
          Row(
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
              const SizedBox(width: 12),
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
          Row(
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
              const SizedBox(width: 12),
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
            gradient: AppColors.sunriseGradient,
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
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _FeeBreakdownItem(
                  label: 'Tuition Fee (Term 2)',
                  amount: '₹20,000',
                  status: 'pending',
                ),
                const Divider(height: 24),
                _FeeBreakdownItem(
                  label: 'Transport Fee',
                  amount: '₹3,000',
                  status: 'pending',
                ),
                const Divider(height: 24),
                _FeeBreakdownItem(
                  label: 'Activity Fee',
                  amount: '₹2,000',
                  status: 'pending',
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
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
                  value: 'This Month',
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
                  value: 'All Classes',
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
                _CollectionRow(
                  label: 'Total Expected',
                  amount: '₹62.5L',
                  color: AppColors.info,
                ),
                const SizedBox(height: 12),
                _CollectionRow(
                  label: 'Collected',
                  amount: '₹45.2L',
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                _CollectionRow(
                  label: 'Pending',
                  amount: '₹12.8L',
                  color: AppColors.warning,
                ),
                const SizedBox(height: 12),
                _CollectionRow(
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
