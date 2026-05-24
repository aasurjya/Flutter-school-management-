import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/pagination/paginated_notifier.dart';
import '../../../../core/theme/app_colors.dart';
// Imported for the `pendingAmount` extension on Invoice.
import '../../../../data/models/invoice.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/fees_provider.dart';
import '../widgets/invoice_card.dart';

/// Invoices tab on the Fees screen — server-side paginated infinite scroll.
///
/// Extracted from `fees_screen.dart` (Stage 3 / fees-screen split). The
/// previous implementation loaded **all** invoices then sliced them
/// client-side with prev/next page buttons, which defeated the purpose —
/// the network round-trip still fetched everything. This version uses
/// [paginatedInvoicesProvider] (added in Stage 3 / PR #10) for proper
/// server-side range pagination + scroll-to-load-more.
class InvoicesTab extends ConsumerStatefulWidget {
  final bool isAdmin;

  const InvoicesTab({super.key, required this.isAdmin});

  @override
  ConsumerState<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends ConsumerState<InvoicesTab> {
  final _scrollController = ScrollController();
  PaginationScrollListener? _scrollListener;
  late InvoicesFilter _filter;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    // Admin sees all invoices; student/parent see only their own.
    final studentId =
        (currentUser?.isAdmin ?? false) ? null : currentUser?.id;
    _filter = InvoicesFilter(studentId: studentId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedInvoicesProvider(_filter).notifier).loadInitial();
    });
    _scrollListener = PaginationScrollListener(
      controller: _scrollController,
      onLoadMore: () =>
          ref.read(paginatedInvoicesProvider(_filter).notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollListener?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paginatedInvoicesProvider(_filter));

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(WarmCopy.loadFailed('invoices')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(paginatedInvoicesProvider(_filter).notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No invoices found'),
          ],
        ),
      );
    }

    final invoices = state.items;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(paginatedInvoicesProvider(_filter).notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= invoices.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final invoice = invoices[index];
          final dueDateStr = DateFormat('d MMM, yyyy').format(invoice.dueDate);
          final amountStr = '₹${invoice.pendingAmount.toStringAsFixed(0)}';
          return InvoiceCard(
            invoiceNo: invoice.invoiceNumber,
            invoiceId: invoice.id,
            studentName: invoice.studentName ?? '—',
            amount: amountStr,
            dueDate: dueDateStr,
            status: invoice.status,
            isAdmin: widget.isAdmin,
          );
        },
      ),
    );
  }
}
