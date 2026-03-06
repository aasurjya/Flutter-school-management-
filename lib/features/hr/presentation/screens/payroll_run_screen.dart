import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/hr_payroll.dart';
import '../../providers/hr_provider.dart';
import '../widgets/salary_breakdown_chart.dart';

class PayrollRunScreen extends ConsumerStatefulWidget {
  final String? payrollRunId;

  const PayrollRunScreen({super.key, this.payrollRunId});

  @override
  ConsumerState<PayrollRunScreen> createState() => _PayrollRunScreenState();
}

class _PayrollRunScreenState extends ConsumerState<PayrollRunScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isGenerating = false;
  PayrollRun? _generatedRun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    // If viewing existing run
    if (widget.payrollRunId != null) {
      return _ExistingRunView(payrollRunId: widget.payrollRunId!);
    }

    // New payroll run
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Payroll'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month/Year selector
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Period',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedMonth,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(12, (i) {
                            final m = i + 1;
                            return DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat('MMMM')
                                  .format(DateTime(2024, m))),
                            );
                          }),
                          onChanged: (v) =>
                              setState(() => _selectedMonth = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedYear,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(5, (i) {
                            final y = DateTime.now().year - 2 + i;
                            return DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            );
                          }),
                          onChanged: (v) =>
                              setState(() => _selectedYear = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isGenerating ? null : _generatePayroll,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                          _isGenerating ? 'Generating...' : 'Generate Payroll'),
                    ),
                  ),
                ],
              ),
            ),

            // Results
            if (_generatedRun != null) ...[
              const SizedBox(height: 24),
              _PayrollRunResults(
                run: _generatedRun!,
                currencyFormat: currencyFormat,
                onApprove: _approvePayroll,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generatePayroll() async {
    setState(() => _isGenerating = true);
    try {
      final runId = await ref.read(hrNotifierProvider.notifier).generatePayroll(
            month: _selectedMonth,
            year: _selectedYear,
          );

      // Fetch the generated run
      ref.invalidate(payrollRunsProvider(null));
      final run = await ref
          .read(hrRepositoryProvider)
          .getPayrollRunById(runId);

      if (mounted) {
        setState(() {
          _generatedRun = run;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payroll generated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _approvePayroll() async {
    if (_generatedRun == null) return;
    try {
      await ref
          .read(hrNotifierProvider.notifier)
          .approvePayroll(_generatedRun!.id);
      ref.invalidate(payrollRunsProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payroll approved'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _ExistingRunView extends ConsumerWidget {
  final String payrollRunId;

  const _ExistingRunView({required this.payrollRunId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runAsync = ref.watch(payrollRunByIdProvider(payrollRunId));
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Details'),
      ),
      body: runAsync.when(
        data: (run) {
          if (run == null) {
            return const Center(child: Text('Payroll run not found'));
          }

          return _PayrollRunResults(
            run: run,
            currencyFormat: currencyFormat,
            onApprove: run.isCompleted
                ? () async {
                    try {
                      await ref
                          .read(hrNotifierProvider.notifier)
                          .approvePayroll(run.id);
                      ref.invalidate(payrollRunByIdProvider(payrollRunId));
                      ref.invalidate(payrollRunsProvider(null));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payroll approved'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error),
                        );
                      }
                    }
                  }
                : null,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _PayrollRunResults extends StatelessWidget {
  final PayrollRun run;
  final NumberFormat currencyFormat;
  final VoidCallback? onApprove;

  const _PayrollRunResults({
    required this.run,
    required this.currencyFormat,
    this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = run.items ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          GlassCard(
            padding: const EdgeInsets.all(20),
            gradient: AppColors.secondaryGradient,
            child: Column(
              children: [
                Text(
                  run.periodDisplay,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${items.length} staff members',
                  style: TextStyle(color: Colors.white.withAlpha(200)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      label: 'Gross',
                      value: currencyFormat.format(run.totalGross),
                    ),
                    _SummaryItem(
                      label: 'Deductions',
                      value: currencyFormat.format(run.totalDeductions),
                    ),
                    _SummaryItem(
                      label: 'Net Pay',
                      value: currencyFormat.format(run.totalNet),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Approve button
          if (onApprove != null && !run.isApproved)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check),
                label: const Text('Approve Payroll'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
          if (run.isApproved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 8),
                  Text(
                    'Payroll Approved',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Individual staff payroll
          Text(
            'Staff Payroll Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...items.map((item) => _PayrollItemCard(
                item: item,
                currencyFormat: currencyFormat,
              )),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withAlpha(180),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PayrollItemCard extends StatefulWidget {
  final PayrollItem item;
  final NumberFormat currencyFormat;

  const _PayrollItemCard({
    required this.item,
    required this.currencyFormat,
  });

  @override
  State<_PayrollItemCard> createState() => _PayrollItemCardState();
}

class _PayrollItemCardState extends State<_PayrollItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withAlpha(20),
                child: Text(
                  _getInitials(item.staffName ?? '?'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.staffName ?? 'Unknown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${item.daysWorked}d worked | ${item.daysAbsent}d absent',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.currencyFormat.format(item.netSalary),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  _PaymentStatusBadge(status: item.paymentStatusDisplay),
                ],
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textTertiaryLight,
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            SalaryBreakdownChart(item: item, size: 160),
            const SizedBox(height: 12),
            _DetailRow(
              'Basic Salary',
              widget.currencyFormat.format(item.basicSalary),
            ),
            _DetailRow(
              'Gross Salary',
              widget.currencyFormat.format(item.grossSalary),
              color: AppColors.info,
            ),
            _DetailRow(
              'Tax (TDS)',
              '- ${widget.currencyFormat.format(item.taxAmount)}',
              color: AppColors.error,
            ),
            _DetailRow(
              'Net Salary',
              widget.currencyFormat.format(item.netSalary),
              color: AppColors.success,
              isBold: true,
            ),
            if (item.overtimeHours > 0)
              _DetailRow(
                'Overtime (${item.overtimeHours}h)',
                widget.currencyFormat.format(item.overtimeAmount),
              ),
          ],
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isBold;

  const _DetailRow(this.label, this.value, {this.color, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final String status;

  const _PaymentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = AppColors.success;
        break;
      case 'failed':
        color = AppColors.error;
        break;
      default:
        color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
