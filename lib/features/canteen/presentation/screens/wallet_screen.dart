import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/canteen_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(currentUserWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: walletAsync.when(
        data: (wallet) {
          if (wallet == null) {
            return const Center(child: Text('Wallet not found'));
          }

          return Column(
            children: [
              // Balance card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Available Balance',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      wallet.balanceFormatted,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => _showAddMoneyDialog(context, ref, wallet.id),
                      child: const Text('Add Money'),
                    ),
                  ],
                ),
              ),
              // Transaction history header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaction History',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(walletTransactionsProvider(wallet.id)),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              // Transactions list
              Expanded(
                child: _TransactionsList(walletId: wallet.id),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, WidgetRef ref, String walletId) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\u20B9 ',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text);
                Navigator.pop(context);

                try {
                  await ref.read(canteenRepositoryProvider).addBalance(
                        walletId,
                        amount,
                        'Wallet top-up',
                      );
                  ref.invalidate(currentUserWalletProvider);
                  ref.invalidate(walletTransactionsProvider(walletId));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('\u20B9$amount added to wallet'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TransactionsList extends ConsumerWidget {
  final String walletId;

  const _TransactionsList({required this.walletId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(walletTransactionsProvider(walletId));

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                const Text('No transactions yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final txn = transactions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: txn.isCredit
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                child: Icon(
                  txn.isCredit
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: txn.isCredit ? Colors.green : Colors.red,
                ),
              ),
              title: Text(txn.description ?? 'Transaction'),
              subtitle: Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(txn.createdAt),
              ),
              trailing: Text(
                txn.amountFormatted,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: txn.isCredit ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}
