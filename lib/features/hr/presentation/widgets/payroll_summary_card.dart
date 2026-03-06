import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/hr_payroll.dart';

/// Card showing monthly payroll totals
class PayrollSummaryCard extends StatelessWidget {
  final PayrollRun payrollRun;
  final VoidCallback? onTap;

  const PayrollSummaryCard({
    super.key,
    required this.payrollRun,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusColor(payrollRun.status).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: _statusColor(payrollRun.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payrollRun.periodDisplay,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${payrollRun.staffCount ?? payrollRun.items?.length ?? 0} staff members',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: payrollRun.statusDisplay),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AmountColumn(
                  label: 'Gross',
                  amount: currencyFormat.format(payrollRun.totalGross),
                  color: AppColors.info,
                ),
              ),
              Expanded(
                child: _AmountColumn(
                  label: 'Deductions',
                  amount: currencyFormat.format(payrollRun.totalDeductions),
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: _AmountColumn(
                  label: 'Net Pay',
                  amount: currencyFormat.format(payrollRun.totalNet),
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(PayrollRunStatus status) {
    switch (status) {
      case PayrollRunStatus.draft:
        return AppColors.warning;
      case PayrollRunStatus.processing:
        return AppColors.info;
      case PayrollRunStatus.completed:
        return AppColors.primary;
      case PayrollRunStatus.approved:
        return AppColors.success;
    }
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'draft':
        color = AppColors.warning;
        break;
      case 'processing':
        color = AppColors.info;
        break;
      case 'completed':
        color = AppColors.primary;
        break;
      case 'approved':
        color = AppColors.success;
        break;
      default:
        color = AppColors.textSecondaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
