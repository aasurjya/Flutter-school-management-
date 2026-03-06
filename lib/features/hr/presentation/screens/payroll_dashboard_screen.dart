import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/hr_provider.dart';
import '../widgets/payroll_summary_card.dart';

class PayrollDashboardScreen extends ConsumerStatefulWidget {
  const PayrollDashboardScreen({super.key});

  @override
  ConsumerState<PayrollDashboardScreen> createState() =>
      _PayrollDashboardScreenState();
}

class _PayrollDashboardScreenState
    extends ConsumerState<PayrollDashboardScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final payrollRunsAsync =
        ref.watch(payrollRunsProvider(_selectedYear));
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        actions: [
          // Year selector
          PopupMenuButton<int>(
            initialValue: _selectedYear,
            onSelected: (year) => setState(() => _selectedYear = year),
            itemBuilder: (context) {
              final currentYear = DateTime.now().year;
              return [
                for (int y = currentYear; y >= currentYear - 3; y--)
                  PopupMenuItem(value: y, child: Text('$y')),
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '$_selectedYear',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: payrollRunsAsync.when(
        data: (runs) {
          // Calculate year totals
          double yearGross = 0, yearDeductions = 0, yearNet = 0;
          for (final run in runs) {
            yearGross += run.totalGross;
            yearDeductions += run.totalDeductions;
            yearNet += run.totalNet;
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(payrollRunsProvider(_selectedYear)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Year Summary
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    gradient: AppColors.primaryGradient,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Year $_selectedYear Summary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _YearStat(
                                label: 'Total Gross',
                                value: currencyFormat.format(yearGross),
                              ),
                            ),
                            Expanded(
                              child: _YearStat(
                                label: 'Total Deductions',
                                value: currencyFormat.format(yearDeductions),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _YearStat(
                                label: 'Total Net Paid',
                                value: currencyFormat.format(yearNet),
                              ),
                            ),
                            Expanded(
                              child: _YearStat(
                                label: 'Payroll Runs',
                                value: '${runs.length}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payroll Runs
                  Text(
                    'Monthly Payroll Runs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (runs.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long,
                                size: 48,
                                color:
                                    theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            const Text('No payroll runs for this year'),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () =>
                                  context.push('/hr/payroll/run'),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Run Payroll'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...runs.map((run) => PayrollSummaryCard(
                          payrollRun: run,
                          onTap: () =>
                              context.push('/hr/payroll/run/${run.id}'),
                        )),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hr/payroll/run'),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Run Payroll'),
      ),
    );
  }
}

class _YearStat extends StatelessWidget {
  final String label;
  final String value;

  const _YearStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
