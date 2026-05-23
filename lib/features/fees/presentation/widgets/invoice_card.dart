import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

/// One row in the invoices list.
///
/// Extracted from `fees_screen.dart` (Stage 3 / fees-screen split). Made
/// public (`InvoiceCard`) so both the InvoicesTab and AdminOverview can
/// reference it without duplicating its body.
class InvoiceCard extends StatelessWidget {
  final String invoiceNo;
  final String invoiceId;
  final String studentName;
  final String amount;
  final String dueDate;
  final String status;
  final bool isAdmin;

  const InvoiceCard({
    super.key,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    showModalBottomSheet<void>(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => _InvoiceDetailSheet(
                        invoiceNo: invoiceNo,
                        invoiceId: invoiceId,
                        studentName: studentName,
                        amount: amount,
                        dueDate: dueDate,
                        status: status,
                        isAdmin: isAdmin,
                      ),
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
                        AppRoutes.paymentCheckout
                            .replaceFirst(':invoiceId', invoiceId),
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

class _InvoiceDetailSheet extends StatelessWidget {
  final String invoiceNo;
  final String invoiceId;
  final String studentName;
  final String amount;
  final String dueDate;
  final String status;
  final bool isAdmin;

  const _InvoiceDetailSheet({
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invoice Detail',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Invoice No.', value: invoiceNo),
            if (isAdmin) _DetailRow(label: 'Student', value: studentName),
            _DetailRow(label: 'Amount Due', value: amount),
            _DetailRow(label: 'Due Date', value: dueDate),
            _DetailRow(label: 'Invoice ID', value: invoiceId),
            const SizedBox(height: 16),
            Row(
              children: [
                if (status != 'paid')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(
                          AppRoutes.paymentCheckout
                              .replaceFirst(':invoiceId', invoiceId),
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
                if (status != 'paid') const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
