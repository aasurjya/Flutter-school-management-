import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/hr_payroll.dart';
import '../../providers/hr_provider.dart';

class TaxDeclarationScreen extends ConsumerStatefulWidget {
  const TaxDeclarationScreen({super.key});

  @override
  ConsumerState<TaxDeclarationScreen> createState() =>
      _TaxDeclarationScreenState();
}

class _TaxDeclarationScreenState
    extends ConsumerState<TaxDeclarationScreen> {
  String _selectedYear = _currentFinancialYear();

  static String _currentFinancialYear() {
    final now = DateTime.now();
    final start = now.month >= 4 ? now.year : now.year - 1;
    return '$start-${start + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final declarationsAsync = ref.watch(taxDeclarationsProvider(
      TaxDeclarationFilter(financialYear: _selectedYear),
    ));
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Declarations'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedYear,
            onSelected: (year) => setState(() => _selectedYear = year),
            itemBuilder: (context) {
              final now = DateTime.now();
              final currentStart = now.month >= 4 ? now.year : now.year - 1;
              return [
                for (int i = 0; i < 4; i++)
                  PopupMenuItem(
                    value: '${currentStart - i}-${currentStart - i + 1}',
                    child: Text('FY ${currentStart - i}-${currentStart - i + 1}'),
                  ),
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('FY $_selectedYear',
                      style: theme.textTheme.titleSmall),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: declarationsAsync.when(
        data: (declarations) {
          if (declarations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No tax declarations for FY $_selectedYear'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Submit Declaration'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(taxDeclarationsProvider(
              TaxDeclarationFilter(financialYear: _selectedYear),
            )),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: declarations.length,
              itemBuilder: (context, index) {
                final dec = declarations[index];
                return _TaxDeclarationCard(
                  declaration: dec,
                  currencyFormat: currencyFormat,
                  onVerify: dec.status == TaxDeclarationStatus.submitted
                      ? () => _verifyDeclaration(dec.id)
                      : null,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Submit Declaration'),
      ),
    );
  }

  Future<void> _verifyDeclaration(String id) async {
    try {
      await ref
          .read(hrNotifierProvider.notifier)
          .verifyTaxDeclaration(id);
      ref.invalidate(taxDeclarationsProvider(
        TaxDeclarationFilter(financialYear: _selectedYear),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Declaration verified'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showCreateDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final section80cControllers = <String, TextEditingController>{
      'ppf': TextEditingController(),
      'elss': TextEditingController(),
      'life_insurance': TextEditingController(),
      'epf': TextEditingController(),
    };
    final section80dControllers = <String, TextEditingController>{
      'health_insurance_self': TextEditingController(),
      'health_insurance_parents': TextEditingController(),
    };
    final hraController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax Declaration - FY $_selectedYear',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Section 80C
                  Text('Section 80C (Max: 1,50,000)',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 12),
                  ...section80cControllers.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: e.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _formatLabel(e.key),
                            border: const OutlineInputBorder(),
                            prefixText: '\u20B9 ',
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),

                  // Section 80D
                  Text('Section 80D',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 12),
                  ...section80dControllers.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: e.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _formatLabel(e.key),
                            border: const OutlineInputBorder(),
                            prefixText: '\u20B9 ',
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),

                  // HRA
                  TextFormField(
                    controller: hraController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'HRA Exemption',
                      border: OutlineInputBorder(),
                      prefixText: '\u20B9 ',
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final section80c = <String, dynamic>{};
                          for (final e
                              in section80cControllers.entries) {
                            final val =
                                double.tryParse(e.value.text) ?? 0;
                            if (val > 0) section80c[e.key] = val;
                          }
                          final section80d = <String, dynamic>{};
                          for (final e
                              in section80dControllers.entries) {
                            final val =
                                double.tryParse(e.value.text) ?? 0;
                            if (val > 0) section80d[e.key] = val;
                          }

                          try {
                            await ref
                                .read(hrNotifierProvider.notifier)
                                .createTaxDeclaration({
                              'financial_year': _selectedYear,
                              'section_80c': section80c,
                              'section_80d': section80d,
                              'hra_exemption':
                                  double.tryParse(hraController.text) ??
                                      0,
                              'status': 'submitted',
                            });
                            ref.invalidate(taxDeclarationsProvider(
                              TaxDeclarationFilter(
                                  financialYear: _selectedYear),
                            ));
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Declaration submitted'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Submit Declaration'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatLabel(String key) {
    return key.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}

class _TaxDeclarationCard extends StatelessWidget {
  final TaxDeclaration declaration;
  final NumberFormat currencyFormat;
  final VoidCallback? onVerify;

  const _TaxDeclarationCard({
    required this.declaration,
    required this.currencyFormat,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.receipt, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      declaration.staffName ?? 'Staff',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'FY ${declaration.financialYear}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              _DeclarationStatusBadge(status: declaration.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AmountItem(
                  label: '80C',
                  amount: currencyFormat.format(declaration.total80c),
                ),
              ),
              Expanded(
                child: _AmountItem(
                  label: '80D',
                  amount: currencyFormat.format(declaration.total80d),
                ),
              ),
              Expanded(
                child: _AmountItem(
                  label: 'HRA',
                  amount: currencyFormat.format(declaration.hraExemption),
                ),
              ),
              Expanded(
                child: _AmountItem(
                  label: 'Total',
                  amount:
                      currencyFormat.format(declaration.totalDeclarations),
                  isBold: true,
                ),
              ),
            ],
          ),
          if (onVerify != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onVerify,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: const Text('Verify Declaration'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeclarationStatusBadge extends StatelessWidget {
  final TaxDeclarationStatus status;

  const _DeclarationStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case TaxDeclarationStatus.draft:
        color = AppColors.warning;
        label = 'Draft';
        break;
      case TaxDeclarationStatus.submitted:
        color = AppColors.info;
        label = 'Submitted';
        break;
      case TaxDeclarationStatus.verified:
        color = AppColors.success;
        label = 'Verified';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AmountItem extends StatelessWidget {
  final String label;
  final String amount;
  final bool isBold;

  const _AmountItem({
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
