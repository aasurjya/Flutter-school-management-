import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../data/models/invoice.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../fees/providers/fees_provider.dart';

class FeeManagementScreen extends ConsumerStatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  ConsumerState<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends ConsumerState<FeeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load data on init
    Future.microtask(() {
      ref.read(feesNotifierProvider.notifier).loadInvoices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Fee Structure'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverview(),
          _buildFeeStructure(),
          _buildPendingPayments(),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final statsAsync = ref.watch(feeCollectionStatsProvider(null));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Collected',
                    value: '₹${_formatAmount(stats['total_paid'] ?? 0)}',
                    icon: Icons.account_balance_wallet,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Pending',
                    value: '₹${_formatAmount(stats['total_pending'] ?? 0)}',
                    icon: Icons.pending_actions,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Fee',
                    value: '₹${_formatAmount(stats['total_fee'] ?? 0)}',
                    icon: Icons.account_balance,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Collection Rate',
                    value: '${(stats['collection_percentage'] ?? 0).toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionButton(icon: Icons.receipt_long, label: 'Generate Invoices', onTap: _generateInvoices),
                _ActionButton(icon: Icons.notifications, label: 'Send Reminders', onTap: _sendReminders),
                _ActionButton(icon: Icons.add_card, label: 'Record Payment', onTap: _recordPayment),
                _ActionButton(icon: Icons.discount, label: 'Apply Discount', onTap: _applyDiscount),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentTransactions() {
    final transactions = [
      {'student': 'Aditi Patel', 'amount': 45000.0, 'date': DateTime.now().subtract(const Duration(hours: 2)), 'method': 'UPI'},
      {'student': 'Arjun Kumar', 'amount': 40000.0, 'date': DateTime.now().subtract(const Duration(hours: 5)), 'method': 'Bank Transfer'},
      {'student': 'Kavya Reddy', 'amount': 35000.0, 'date': DateTime.now().subtract(const Duration(days: 1)), 'method': 'Cash'},
    ];

    return transactions.map((t) => GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['student'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('${t['method']} • ${_formatDateTime(t['date'] as DateTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text('+₹${(t['amount'] as double).toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
        ],
      ),
    )).toList();
  }

  Widget _buildFeeStructure() {
    final feeHeadsAsync = ref.watch(feeHeadsProvider);

    return feeHeadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (feeHeads) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(child: Text('Fee Heads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ElevatedButton.icon(
                onPressed: _addFeeStructure,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (feeHeads.isEmpty)
            const Center(child: Text('No fee heads configured yet'))
          else
            ...feeHeads.map((fh) => GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(fh.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      if (fh.code != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(fh.code!, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                        ),
                      IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {}),
                    ],
                  ),
                  if (fh.description != null)
                    Text(fh.description!, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (fh.isRecurring)
                        _buildFeeChip('Recurring', color: AppColors.info),
                    ],
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildFeeChip(String label, {Color color = AppColors.primary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _buildPendingPayments() {
    final invoicesAsync = ref.watch(overdueInvoicesProvider);

    return invoicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (invoices) {
        if (invoices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                SizedBox(height: 16),
                Text('No pending payments!', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            final dueDate = invoice.dueDate;
            final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());
            final pendingAmount = invoice.totalAmount - invoice.paidAmount;

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(invoice.studentName ?? 'Unknown Student', 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Invoice: ${invoice.invoiceNumber}', 
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${pendingAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOverdue ? AppColors.error.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOverdue 
                                  ? 'Overdue' 
                                  : dueDate != null 
                                      ? 'Due ${DateFormat('MMM d').format(dueDate)}'
                                      : 'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                color: isOverdue ? AppColors.error : AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('Remind'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _recordPaymentForInvoice(invoice),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          child: const Text('Record Payment'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _recordPaymentForInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Record Payment - ${invoice.invoiceNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${invoice.studentName ?? 'Unknown'}'),
            Text('Pending: ₹${(invoice.totalAmount - invoice.paidAmount).toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment recording coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating report...')));
  }

  void _generateInvoices() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Invoices'),
        content: const Text('Generate invoices for all students for the current term?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.showSuccessSnackBar('Invoices generated');
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _sendReminders() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sending reminders...')));
  }

  void _recordPayment() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => const _RecordPaymentSheet(),
    );
  }

  void _applyDiscount() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Discount feature coming soon')));
  }

  void _addFeeStructure() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add fee structure coming soon')));
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet();

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _paymentMethod = 'cash';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Record Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Student Name/ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.showSuccessSnackBar('Payment recorded');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
