import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/invoice.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../fees/providers/fees_provider.dart';
import '../../../students/providers/students_provider.dart';

class StudentFeesScreen extends ConsumerWidget {
  final String? studentId;

  const StudentFeesScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStudentAsync = ref.watch(currentStudentProvider);

    return currentStudentAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (student) {
        if (student == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Fee Status'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('Student not found')),
          );
        }

        final effectiveStudentId = studentId ?? student.id;
        final statsAsync = ref.watch(feeCollectionStatsProvider(null)); // Get tenant-wide stats
        final invoicesAsync = ref.watch(invoicesProvider(InvoicesFilter(studentId: effectiveStudentId)));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Fee Status'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(feeCollectionStatsProvider(null));
                  ref.invalidate(invoicesProvider(InvoicesFilter(studentId: effectiveStudentId)));
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(feeCollectionStatsProvider(null));
              ref.invalidate(invoicesProvider(InvoicesFilter(studentId: effectiveStudentId)));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  statsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (stats) => _buildSummaryCard(stats),
                  ),
                  const SizedBox(height: 24),

                  // Invoices
                  const Text(
                    'Fee Invoices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  invoicesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading invoices: $e'),
                    data: (invoices) {
                      if (invoices.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No invoices found'),
                          ),
                        );
                      }
                      return Column(
                        children: invoices.map((invoice) => _InvoiceCard(invoice: invoice)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic>? summary) {
    final totalFee = (summary?['total_fee'] ?? 0).toDouble();
    final totalPaid = (summary?['total_paid'] ?? 0).toDouble();
    final totalDue = (summary?['total_due'] ?? 0).toDouble();
    final overdueAmount = (summary?['overdue_amount'] ?? 0).toDouble();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Total Fee',
                  value: '₹${_formatAmount(totalFee)}',
                  color: AppColors.info,
                  icon: Icons.account_balance_wallet,
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey.withOpacity(0.2)),
              Expanded(
                child: _SummaryItem(
                  label: 'Paid',
                  value: '₹${_formatAmount(totalPaid)}',
                  color: AppColors.success,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Due',
                  value: '₹${_formatAmount(totalDue)}',
                  color: AppColors.warning,
                  icon: Icons.pending_actions,
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey.withOpacity(0.2)),
              Expanded(
                child: _SummaryItem(
                  label: 'Overdue',
                  value: '₹${_formatAmount(overdueAmount)}',
                  color: AppColors.error,
                  icon: Icons.warning,
                ),
              ),
            ],
          ),
          if (overdueAmount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have overdue payments. Please clear them to avoid late fees.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final status = invoice.status;
    final dueDate = invoice.dueDate;
    final dueAmount = invoice.totalAmount - invoice.paidAmount;
    final isOverdue = status == 'pending' && dueDate.isBefore(DateTime.now());

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status, isOverdue).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber ?? 'Invoice',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.termName ?? 'Term',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status, isOverdue),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOverdue ? 'OVERDUE' : status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Total Amount', '₹${invoice.totalAmount.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildDetailRow('Paid Amount', '₹${invoice.paidAmount.toStringAsFixed(0)}', 
                    color: AppColors.success),
                const SizedBox(height: 8),
                _buildDetailRow('Due Amount', '₹${dueAmount.toStringAsFixed(0)}',
                    color: dueAmount > 0 ? AppColors.warning : null),
                const SizedBox(height: 8),
                _buildDetailRow('Due Date', DateFormat('MMM d, yyyy').format(dueDate),
                    color: isOverdue ? AppColors.error : null),
              ],
            ),
          ),
          
          // Action button for pending invoices
          if (status == 'pending' || status == 'partial') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: OutlinedButton.icon(
                onPressed: () => _showPaymentInfo(context),
                icon: const Icon(Icons.payment),
                label: const Text('View Payment Options'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status, bool isOverdue) {
    if (isOverdue) return AppColors.error;
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'partial':
        return AppColors.warning;
      case 'pending':
        return AppColors.info;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showPaymentInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance, color: AppColors.primary),
              ),
              title: const Text('Bank Transfer'),
              subtitle: const Text('Transfer to school bank account'),
              onTap: () {
                Navigator.pop(context);
                _showBankDetails(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code, color: AppColors.secondary),
              ),
              title: const Text('UPI Payment'),
              subtitle: const Text('Pay using any UPI app'),
              onTap: () {
                Navigator.pop(context);
                // Show UPI QR code
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront, color: AppColors.accent),
              ),
              title: const Text('Pay at School'),
              subtitle: const Text('Visit the fee counter'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showBankDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bank Details'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Name: School Trust Account'),
            SizedBox(height: 8),
            Text('Account Number: XXXX XXXX XXXX 1234'),
            SizedBox(height: 8),
            Text('IFSC Code: SBIN0001234'),
            SizedBox(height: 8),
            Text('Bank: State Bank of India'),
            SizedBox(height: 16),
            Text(
              'Note: Please mention student admission number in remarks.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCardMap extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const _InvoiceCardMap({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final status = (invoice['status'] as String?) ?? 'pending';
    final dueDate = invoice['dueDate'] as DateTime?;
    final isOverdue = status == 'pending' && dueDate != null && dueDate.isBefore(DateTime.now());

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status, isOverdue).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (invoice['invoiceNumber'] as String?) ?? 'Invoice',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (invoice['termName'] as String?) ?? 'Term',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status, isOverdue),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOverdue ? 'OVERDUE' : status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Total Amount', '₹${((invoice['totalAmount'] as num?) ?? 0).toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildDetailRow('Paid Amount', '₹${((invoice['paidAmount'] as num?) ?? 0).toStringAsFixed(0)}', color: AppColors.success),
                const SizedBox(height: 8),
                _buildDetailRow('Due Amount', '₹${((invoice['dueAmount'] as num?) ?? 0).toStringAsFixed(0)}',
                    color: ((invoice['dueAmount'] as num?) ?? 0) > 0 ? AppColors.warning : null),
                if (dueDate != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Due Date', DateFormat('MMM d, yyyy').format(dueDate),
                      color: isOverdue ? AppColors.error : null),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }

  Color _getStatusColor(String status, bool isOverdue) {
    if (isOverdue) return AppColors.error;
    switch (status) {
      case 'paid': return AppColors.success;
      case 'partial': return AppColors.warning;
      case 'pending': return AppColors.info;
      default: return Colors.grey;
    }
  }
}
