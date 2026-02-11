import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

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

  // Mock data
  final Map<String, dynamic> _pendingInvoice = {
    'id': '1',
    'invoiceNumber': 'INV-2024-003',
    'termName': 'Term 3 (Dec-Mar)',
    'totalAmount': 40000.0,
    'paidAmount': 10000.0,
    'dueAmount': 30000.0,
    'dueDate': DateTime(2025, 1, 15),
    'items': [
      {'name': 'Tuition Fee', 'amount': 25000.0},
      {'name': 'Lab Fee', 'amount': 5000.0},
      {'name': 'Library Fee', 'amount': 2000.0},
      {'name': 'Sports Fee', 'amount': 3000.0},
      {'name': 'Activity Fee', 'amount': 5000.0},
    ],
  };

  final List<Map<String, dynamic>> _paymentHistory = [
    {'date': DateTime(2024, 9, 10), 'amount': 40000.0, 'method': 'UPI', 'transactionId': 'TXN123456789', 'term': 'Term 2'},
    {'date': DateTime(2024, 5, 5), 'amount': 45000.0, 'method': 'Bank Transfer', 'transactionId': 'TXN987654321', 'term': 'Term 1'},
    {'date': DateTime(2024, 12, 1), 'amount': 10000.0, 'method': 'UPI', 'transactionId': 'TXN456789123', 'term': 'Term 3 (Partial)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.childName != null ? "${widget.childName}'s Fees" : 'Fee Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPendingPayment(),
            const SizedBox(height: 24),
            _buildPaymentMethods(),
            const SizedBox(height: 24),
            _buildPaymentHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPayment() {
    final dueDate = _pendingInvoice['dueDate'] as DateTime;
    final isOverdue = dueDate.isBefore(DateTime.now());

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text(
                'Pending Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OVERDUE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_pendingInvoice['invoiceNumber'], style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(_pendingInvoice['termName'], style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Fee breakdown
          ...(_pendingInvoice['items'] as List).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['name'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                Text('₹${(item['amount'] as double).toStringAsFixed(0)}'),
              ],
            ),
          )),
          
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('₹${(_pendingInvoice['totalAmount'] as double).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Already Paid', style: TextStyle(color: AppColors.success)),
              Text('- ₹${(_pendingInvoice['paidAmount'] as double).toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.success)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₹${(_pendingInvoice['dueAmount'] as double).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: isOverdue ? AppColors.error : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}',
                style: TextStyle(color: isOverdue ? AppColors.error : Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Pay Now', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
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

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._paymentHistory.map((payment) => GlassCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
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
                    Text(payment['term'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '${payment['method']} • ${DateFormat('MMM d, yyyy').format(payment['date'])}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      'Txn: ${payment['transactionId']}',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${(payment['amount'] as double).toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _processPayment() {
    if (_selectedPaymentMethod == 'offline') {
      _showOfflinePaymentInfo();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentProcessSheet(
        amount: _pendingInvoice['dueAmount'] as double,
        method: _selectedPaymentMethod,
      ),
    );
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
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: isSelected ? AppColors.primary : Colors.grey),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentProcessSheet extends StatefulWidget {
  final double amount;
  final String method;

  const _PaymentProcessSheet({required this.amount, required this.method});

  @override
  State<_PaymentProcessSheet> createState() => _PaymentProcessSheetState();
}

class _PaymentProcessSheetState extends State<_PaymentProcessSheet> {
  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: _isSuccess ? _buildSuccess() : _buildPaymentForm(),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      children: [
        const Text(
          'Complete Payment',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Text(
          '₹${widget.amount.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text('Via ${_getMethodName()}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const Spacer(),
        if (widget.method == 'upi')
          const Text(
            'You will be redirected to your UPI app',
            style: TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _simulatePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Confirm Payment', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: AppColors.success, size: 64),
        ),
        const SizedBox(height: 24),
        const Text(
          'Payment Successful!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${widget.amount.toStringAsFixed(0)} paid successfully',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          'Transaction ID: TXN${DateTime.now().millisecondsSinceEpoch}',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  String _getMethodName() {
    switch (widget.method) {
      case 'upi': return 'UPI';
      case 'card': return 'Card';
      case 'netbanking': return 'Net Banking';
      default: return widget.method;
    }
  }

  Future<void> _simulatePayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });
  }
}
