import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/hr_provider.dart';
import '../widgets/contract_status_badge.dart';

class ContractManagementScreen extends ConsumerStatefulWidget {
  const ContractManagementScreen({super.key});

  @override
  ConsumerState<ContractManagementScreen> createState() =>
      _ContractManagementScreenState();
}

class _ContractManagementScreenState
    extends ConsumerState<ContractManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Contract Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Expiring'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ContractList(filter: const StaffContractFilter(status: 'active')),
          _ContractList(
              filter: const StaffContractFilter(expiringOnly: true)),
          _ContractList(filter: const StaffContractFilter()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateContractDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Contract'),
      ),
    );
  }

  void _showCreateContractDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final basicController = TextEditingController();
    final hraController = TextEditingController(text: '0');
    final daController = TextEditingController(text: '0');
    final taController = TextEditingController(text: '0');
    String contractType = 'permanent';
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Staff Contract',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: contractType,
                    decoration: const InputDecoration(
                      labelText: 'Contract Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'permanent', child: Text('Permanent')),
                      DropdownMenuItem(
                          value: 'temporary', child: Text('Temporary')),
                      DropdownMenuItem(
                          value: 'contract', child: Text('Contract')),
                      DropdownMenuItem(
                          value: 'probation', child: Text('Probation')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => contractType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: basicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Basic Salary',
                      border: OutlineInputBorder(),
                      prefixText: '\u20B9 ',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: hraController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'HRA',
                            border: OutlineInputBorder(),
                            prefixText: '\u20B9 ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: daController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'DA',
                            border: OutlineInputBorder(),
                            prefixText: '\u20B9 ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: taController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'TA',
                            border: OutlineInputBorder(),
                            prefixText: '\u20B9 ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Start Date'),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(startDate),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setDialogState(() => startDate = date);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('End Date'),
                          subtitle: Text(
                            endDate != null
                                ? DateFormat('dd/MM/yyyy').format(endDate!)
                                : 'Not set',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: ctx,
                              initialDate:
                                  endDate ?? startDate.add(const Duration(days: 365)),
                              firstDate: startDate,
                              lastDate: DateTime(2035),
                            );
                            if (date != null) {
                              setDialogState(() => endDate = date);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          // In production, you'd also select the staff member
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Select a staff member first to create a contract'),
                              backgroundColor: AppColors.info,
                            ),
                          );
                        }
                      },
                      child: const Text('Create Contract'),
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
}

class _ContractList extends ConsumerWidget {
  final StaffContractFilter filter;

  const _ContractList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(staffContractsProvider(filter));
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    return contractsAsync.when(
      data: (contracts) {
        if (contracts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description,
                    size: 64, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                const Text('No contracts found'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(staffContractsProvider(filter)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contracts.length,
            itemBuilder: (context, index) {
              final c = contracts[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withAlpha(20),
                          child: Text(
                            _getInitials(c.staffName ?? '?'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.staffName ?? 'Unknown',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                c.staffEmployeeId ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ContractStatusBadge(
                            status: c.status, showIcon: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ContractTypeBadge(type: c.contractType),
                        const Spacer(),
                        Text(
                          currencyFormat.format(c.netSalary),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '/month',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(c.startDate)} - ${c.endDate != null ? DateFormat('dd MMM yyyy').format(c.endDate!) : 'Ongoing'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    if (c.isExpiringSoon) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Expires in ${c.daysUntilExpiry} days',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
