import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../data/models/library.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/library_provider.dart';
import '../widgets/issue_book_sheet.dart';
import '../widgets/loan_actions.dart';

/// Librarian-only loans dashboard.
///
/// Tabs:
///   - Active loans: every non-returned loan, sorted by due date.
///   - Overdue: subset where due_date < today.
///
/// FAB issues a new book. Each row supports a one-tap "Return" action.
class LibrarianLoansScreen extends ConsumerStatefulWidget {
  const LibrarianLoansScreen({super.key});

  @override
  ConsumerState<LibrarianLoansScreen> createState() =>
      _LibrarianLoansScreenState();
}

class _LibrarianLoansScreenState extends ConsumerState<LibrarianLoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showIssueSheet() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const IssueBookSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library loans'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(activeLoansProvider);
              ref.invalidate(overdueBookssProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active loans'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ActiveLoansTab(),
          _OverdueLoansTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIssueSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Issue book'),
      ),
    );
  }
}

class _ActiveLoansTab extends ConsumerWidget {
  const _ActiveLoansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(activeLoansProvider);
    return loansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load loans. $e',
        onRetry: () => ref.invalidate(activeLoansProvider),
      ),
      data: (loans) {
        if (loans.isEmpty) {
          return const _EmptyState(
            icon: Icons.menu_book_outlined,
            message: 'No active loans right now.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(activeLoansProvider),
          child: ListView.builder(
            padding: AppSpacing.pageHV,
            itemCount: loans.length,
            itemBuilder: (context, index) => _LoanRow(loan: loans[index]),
          ),
        );
      },
    );
  }
}

class _OverdueLoansTab extends ConsumerWidget {
  const _OverdueLoansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(overdueBookssProvider);
    return loansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load overdue loans. $e',
        onRetry: () => ref.invalidate(overdueBookssProvider),
      ),
      data: (loans) {
        if (loans.isEmpty) {
          return const _EmptyState(
            icon: Icons.check_circle_outline,
            message: 'No overdue loans. Nice work.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(overdueBookssProvider),
          child: ListView.builder(
            padding: AppSpacing.pageHV,
            itemCount: loans.length,
            itemBuilder: (context, index) =>
                _LoanRow(loan: loans[index], showFine: true),
          ),
        );
      },
    );
  }
}

class _LoanRow extends ConsumerWidget {
  final BookIssue loan;
  final bool showFine;

  const _LoanRow({required this.loan, this.showFine = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dueLabel = DateFormat('dd MMM yyyy').format(loan.dueDate);
    final overdue = loan.isOverdue;
    final daysOverdue = loan.daysOverdue;
    final daysRemaining = loan.daysRemaining;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.menu_book_outlined),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.book?.title ?? 'Unknown book',
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      loan.borrowerName ?? 'Unknown borrower',
                      style: theme.textTheme.bodyMedium,
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      'Due $dueLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: overdue ? AppColors.error : null,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                overdue: overdue,
                daysOverdue: daysOverdue,
                daysRemaining: daysRemaining,
              ),
            ],
          ),
          if (showFine) ...[
            AppSpacing.gapXs,
            _FineLine(daysOverdue: daysOverdue),
          ],
          AppSpacing.gapXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.assignment_return_outlined),
                label: const Text('Return'),
                onPressed: () => LoanActions.confirmReturn(context, ref, loan),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool overdue;
  final int daysOverdue;
  final int daysRemaining;

  const _StatusPill({
    required this.overdue,
    required this.daysOverdue,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;
    if (overdue) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
      text = '$daysOverdue d overdue';
    } else if (daysRemaining <= 3) {
      bg = AppColors.warningLight;
      fg = AppColors.warning;
      text = '$daysRemaining d left';
    } else {
      bg = AppColors.successLight;
      fg = AppColors.success;
      text = '$daysRemaining d left';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FineLine extends ConsumerWidget {
  final int daysOverdue;

  const _FineLine({required this.daysOverdue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fine calc is intentionally simple: per-day-rate lookup off the
    // tenants table (if column ever ships); otherwise display "₹ —".
    final rateAsync = ref.watch(libraryFinePerDayProvider);
    return rateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const _FineText(label: 'Fine', value: '₹ —'),
      data: (rate) {
        if (rate == null || rate <= 0) {
          return const _FineText(label: 'Fine', value: '₹ —');
        }
        final amount = (rate * daysOverdue).toStringAsFixed(2);
        return _FineText(label: 'Fine', value: '₹ $amount');
      },
    );
  }
}

class _FineText extends StatelessWidget {
  final String label;
  final String value;

  const _FineText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.currency_rupee, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
          AppSpacing.gapSm,
          Text(message, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            AppSpacing.gapSm,
            Text(message, textAlign: TextAlign.center),
            AppSpacing.gapSm,
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
