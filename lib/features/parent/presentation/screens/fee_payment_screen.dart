import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/payment_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/invoice.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../fees/providers/fees_provider.dart';

class FeePaymentScreen extends ConsumerStatefulWidget {
  final String childId;
  final String? childName;

  const FeePaymentScreen({
    super.key,
    required this.childId,
    this.childName,
  });

  @override
  ConsumerState<FeePaymentScreen> createState() => _FeePaymentScreenState();
}

class _FeePaymentScreenState extends ConsumerState<FeePaymentScreen> {
  String _selectedPaymentMethod = 'upi';
  Invoice? _selectedInvoice;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(
      invoicesProvider(InvoicesFilter(studentId: widget.childId)),
    );
    final paymentsAsync = ref.watch(
      paymentsProvider(PaymentsFilter(studentId: widget.childId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.childName != null
            ? "${widget.childName}'s Fees"
            : 'Fee Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load invoices: $e')),
        data: (invoices) {
          final pending = invoices
              .where((inv) => !inv.isPaid && !inv.isCancelled)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pending.isEmpty)
                  _buildNoPendingPayments()
                else
                  ...pending.map((inv) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildInvoiceCard(inv),
                      )),
                const SizedBox(height: 8),
                _buildPaymentMethods(),
                const SizedBox(height: 24),
                _buildPaymentHistory(paymentsAsync),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoPendingPayments() {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: AppColors.success.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            const Text(
              'All fees are paid!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'No pending invoices',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final isOverdue = invoice.isOverdueNow;
    final dueAmount = invoice.pendingAmount;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OVERDUE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: invoice.isPartial
                        ? AppColors.warning
                        : AppColors.info,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    invoice.statusDisplay,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (invoice.termName != null)
            Text(
              invoice.termName!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          const SizedBox(height: 12),

          // Fee breakdown from invoice items
          if (invoice.items != null)
            ...invoice.items!.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.feeHeadName ?? item.description ?? 'Fee',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      Text(
                          '₹${(item.amount - item.discount).toStringAsFixed(0)}'),
                    ],
                  ),
                )),

          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              Text('₹${invoice.netAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          if (invoice.paidAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Already Paid',
                    style: TextStyle(color: AppColors.success)),
                Text('- ₹${invoice.paidAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.success)),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount Due',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₹${dueAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 14,
                  color: isOverdue
                      ? AppColors.error
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Due: ${DateFormat('MMM d, yyyy').format(invoice.dueDate)}',
                style: TextStyle(
                    color: isOverdue
                        ? AppColors.error
                        : Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _isProcessing ? null : () => _processPayment(invoice),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing && _selectedInvoice?.id == invoice.id
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Pay Now',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final gatewayService = ref.read(paymentGatewayServiceProvider);
    final hasGateway = gatewayService != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (hasGateway) ...[
          _PaymentMethodTile(
            icon: Icons.account_balance_wallet,
            title: 'UPI Payment',
            subtitle: 'Pay using any UPI app',
            value: 'upi',
            groupValue: _selectedPaymentMethod,
            onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
          ),
          _PaymentMethodTile(
            icon: Icons.credit_card,
            title: 'Card Payment',
            subtitle: 'Credit/Debit Card',
            value: 'card',
            groupValue: _selectedPaymentMethod,
            onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
          ),
          _PaymentMethodTile(
            icon: Icons.account_balance,
            title: 'Net Banking',
            subtitle: 'Pay through bank',
            value: 'netbanking',
            groupValue: _selectedPaymentMethod,
            onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
          ),
        ],
        _PaymentMethodTile(
          icon: Icons.store,
          title: 'Pay at School',
          subtitle: 'Visit the fee counter',
          value: 'offline',
          groupValue: _selectedPaymentMethod,
          onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory(AsyncValue<List<Payment>> paymentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        paymentsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load payments: $e'),
          data: (payments) {
            if (payments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No payments yet',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }

            return Column(
              children: payments.map((payment) {
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (payment.isCompleted
                                  ? AppColors.success
                                  : AppColors.warning)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          payment.isCompleted
                              ? Icons.check_circle
                              : Icons.pending,
                          color: payment.isCompleted
                              ? AppColors.success
                              : AppColors.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(payment.paymentNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            Text(
                              '${payment.paymentMethodDisplay} • ${payment.paidAt != null ? DateFormat('MMM d, yyyy').format(payment.paidAt!) : 'Pending'}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                            if (payment.transactionId != null)
                              Text(
                                'Txn: ${payment.transactionId}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${payment.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _processPayment(Invoice invoice) async {
    if (_selectedPaymentMethod == 'offline') {
      _showOfflinePaymentInfo();
      return;
    }

    final gatewayService = ref.read(paymentGatewayServiceProvider);
    if (gatewayService == null) {
      _showOfflinePaymentInfo();
      return;
    }

    setState(() {
      _isProcessing = true;
      _selectedInvoice = invoice;
    });

    try {
      final dueAmount = invoice.pendingAmount;
      final amountInPaise = (dueAmount * 100).round();

      final result = await gatewayService.openCheckout(
        amountInPaise: amountInPaise,
        invoiceId: invoice.id,
        studentName: invoice.studentName ?? widget.childName ?? '',
        description: '${invoice.invoiceNumber} — ${invoice.termName ?? 'Fee Payment'}',
      );

      if (!mounted) return;

      if (result.success) {
        // Record payment in database
        final feeRepo = ref.read(feeRepositoryProvider);
        await feeRepo.recordPayment(
          invoiceId: invoice.id,
          amount: dueAmount,
          paymentMethod: _selectedPaymentMethod,
          gatewayPaymentId: result.paymentId,
          gatewayOrderId: result.orderId,
          gatewaySignature: result.signature,
        );

        // Refresh invoices and payments
        ref.invalidate(
            invoicesProvider(InvoicesFilter(studentId: widget.childId)));
        ref.invalidate(
            paymentsProvider(PaymentsFilter(studentId: widget.childId)));

        if (mounted) {
          context.showSuccessSnackBar(
            'Payment of ₹${dueAmount.toStringAsFixed(0)} successful!',
          );
        }
      } else {
        if (mounted) {
          context.showErrorSnackBar(result.errorMessage ?? 'Payment failed');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Payment error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedInvoice = null;
        });
      }
    }
  }

  void _showOfflinePaymentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pay at School'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Visit the school fee counter during working hours:'),
            SizedBox(height: 12),
            Text('Monday - Friday: 9:00 AM - 3:00 PM'),
            Text('Saturday: 9:00 AM - 12:00 PM'),
            SizedBox(height: 12),
            Text('Accepted: Cash, Cheque, Demand Draft'),
            SizedBox(height: 8),
            Text(
              'Please carry the fee receipt for reference.',
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

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : Colors.grey),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
