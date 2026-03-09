import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../data/models/payment_gateway.dart';
import '../../providers/payment_gateway_provider.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState
    extends ConsumerState<PaymentHistoryScreen> {
  String? _statusFilter; // null = all

  static const _statusOptions = [
    _FilterOption(label: 'All', value: null),
    _FilterOption(label: 'Success', value: 'success'),
    _FilterOption(label: 'Pending', value: 'pending'),
    _FilterOption(label: 'Failed', value: 'failed'),
  ];

  TransactionsFilter get _currentFilter =>
      TransactionsFilter(status: _statusFilter);

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider(_currentFilter));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          _FilterBar(
            options: _statusOptions,
            selected: _statusFilter,
            onSelected: (val) => setState(() => _statusFilter = val),
          ),
          // List
          Expanded(
            child: txAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(
                    transactionsProvider(_currentFilter)),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return AppEmptyWidget(
                    message: _statusFilter != null
                        ? 'No $_statusFilter transactions found'
                        : 'No transactions yet',
                    subtitle: 'Payments made through the portal appear here.',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(
                      transactionsProvider(_currentFilter)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _TransactionTile(tx: transactions[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final String? value;

  const _FilterOption({required this.label, required this.value});
}

class _FilterBar extends StatelessWidget {
  final List<_FilterOption> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _FilterBar({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((opt) {
            final isSelected = opt.value == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(opt.label),
                selected: isSelected,
                onSelected: (_) => onSelected(opt.value),
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.grey700,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                ),
                backgroundColor: AppColors.background,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PaymentTransaction tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(symbol: '\$');
    final dateStr = DateFormat.yMMMd().add_jm().format(tx.createdAt);
    final gatewayName = GatewayNameX.fromString(tx.gatewayName);
    final brandColor = gatewayName.brandColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gateway icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(gatewayName.icon, color: brandColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.gatewayName.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.grey500,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 2),
                if (tx.gatewayTransactionId != null)
                  Text(
                    tx.gatewayTransactionId!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey400,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount & status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currFmt.format(tx.amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
              ),
              const SizedBox(height: 4),
              _StatusChip(tx: tx),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PaymentTransaction tx;

  const _StatusChip({required this.tx});

  @override
  Widget build(BuildContext context) {
    final color = tx.statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tx.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
