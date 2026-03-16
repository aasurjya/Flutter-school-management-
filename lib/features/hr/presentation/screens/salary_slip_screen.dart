import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/hr_payroll.dart';
import '../../providers/hr_provider.dart';
import '../widgets/salary_breakdown_chart.dart';

class SalarySlipScreen extends ConsumerWidget {
  final String? staffId;

  const SalarySlipScreen({super.key, this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slipsAsync = ref.watch(salarySlipsProvider(staffId));
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Slips'),
      ),
      body: slipsAsync.when(
        data: (slips) {
          if (slips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('No salary slips available'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: slips.length,
            itemBuilder: (context, index) {
              final slip = slips[index];
              final item = slip.payrollItem;

              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                onTap: item != null
                    ? () => _showSlipDetail(context, ref, slip, item)
                    : null,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slip.slipNumber,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy')
                                .format(slip.generatedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item != null)
                      Text(
                        currencyFormat.format(item.netSalary),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Download',
                      onPressed: item != null
                          ? () => _downloadPdf(context, ref, item)
                          : null,
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showSlipDetail(
    BuildContext context,
    WidgetRef ref,
    SalarySlip slip,
    PayrollItem item,
  ) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salary Slip',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          slip.slipNumber,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _downloadPdf(context, ref, item),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Download PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Employee info
              _SlipSection(
                title: 'Employee Details',
                children: [
                  _SlipRow('Name', item.staffName ?? 'N/A'),
                  _SlipRow('Employee ID', item.staffEmployeeId ?? 'N/A'),
                  _SlipRow('Days Worked', '${item.daysWorked}'),
                  _SlipRow('Days Absent', '${item.daysAbsent}'),
                ],
              ),
              const SizedBox(height: 16),

              // Salary Breakdown Chart
              SalaryBreakdownChart(item: item, size: 180),
              const SizedBox(height: 16),

              // Earnings
              _SlipSection(
                title: 'Earnings',
                color: AppColors.successLight,
                children: [
                  ...item.earnings.entries.map((e) => _SlipRow(
                        _formatLabel(e.key),
                        currencyFormat.format(_toDouble(e.value)),
                      )),
                  if (item.overtimeAmount > 0)
                    _SlipRow(
                      'Overtime (${item.overtimeHours}h)',
                      currencyFormat.format(item.overtimeAmount),
                    ),
                  const Divider(),
                  _SlipRow(
                    'Gross Salary',
                    currencyFormat.format(item.grossSalary),
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deductions
              _SlipSection(
                title: 'Deductions',
                color: AppColors.errorLight,
                children: [
                  ...item.deductions.entries.map((e) => _SlipRow(
                        _formatLabel(e.key),
                        currencyFormat.format(_toDouble(e.value)),
                      )),
                  _SlipRow('Tax (TDS)', currencyFormat.format(item.taxAmount)),
                  const Divider(),
                  _SlipRow(
                    'Total Deductions',
                    currencyFormat.format(item.totalDeductions),
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Net Pay
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NET PAY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.netSalary),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf(
    BuildContext context,
    WidgetRef ref,
    PayrollItem item,
  ) async {
    try {
      final repository = ref.read(hrRepositoryProvider);
      final pdfBytes = await repository.generateSalarySlipPdf(
        item: item,
        month: DateTime.now().month,
        year: DateTime.now().year,
      );

      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static String _formatLabel(String key) {
    return key.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}

class _SlipSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color? color;

  const _SlipSection({
    required this.title,
    required this.children,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.inputFillLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SlipRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SlipRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: AppColors.textSecondaryLight,
              )),
          Text(value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
