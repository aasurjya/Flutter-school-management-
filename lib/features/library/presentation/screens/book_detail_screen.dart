import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../data/models/library.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/library_provider.dart';
import '../../../../core/copy/warm_strings.dart';
import '../widgets/issue_book_sheet.dart';
import '../widgets/loan_actions.dart';

class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(bookId));
    final user = ref.watch(currentUserProvider);
    final canManage = user != null && (user.isLibrarian || user.isAdmin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
      ),
      body: bookAsync.when(
        data: (book) {
          if (book == null) {
            return const Center(child: Text('Book not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover and basic info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover
                    Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: book.coverUrl != null
                          ? CachedNetworkImage(
              imageUrl: book.coverUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.book,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Icon(
                              Icons.book,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          if (book.author != null)
                            Text(
                              'by ${book.author}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: book.isAvailable
                                  ? AppColors.successLight
                                  : AppColors.errorLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              book.isAvailable ? 'Available' : 'Not Available',
                              style: TextStyle(
                                color: book.isAvailable
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.availabilityText,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (canManage) ...[
                  AppSpacing.gapMd,
                  _LibrarianBookActions(book: book),
                ],
                const SizedBox(height: 24),
                // Details section
                Text(
                  'Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'ISBN', value: book.isbn ?? 'N/A'),
                _DetailRow(label: 'Publisher', value: book.publisher ?? 'N/A'),
                _DetailRow(label: 'Edition', value: book.edition ?? 'N/A'),
                _DetailRow(
                  label: 'Publication Year',
                  value: book.publicationYear?.toString() ?? 'N/A',
                ),
                _DetailRow(label: 'Category', value: book.category ?? 'N/A'),
                _DetailRow(
                  label: 'Shelf Location',
                  value: book.shelfLocation ?? 'N/A',
                ),
                if (book.description != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(book.description!),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(WarmCopy.genericError)),
      ),
    );
  }
}

/// Librarian-only block on the book detail screen.
/// - "Issue this book" if at least one copy is available.
/// - One "Return" tile per active loan against this book.
class _LibrarianBookActions extends ConsumerWidget {
  final LibraryBook book;

  const _LibrarianBookActions({required this.book});

  Future<void> _openIssueSheet(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => IssueBookSheet(initialBook: book),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLoansAsync = ref.watch(activeLoansForBookProvider(book.id));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (book.isAvailable)
          FilledButton.icon(
            onPressed: () => _openIssueSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Issue this book'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        AppSpacing.gapSm,
        activeLoansAsync.when(
          loading: () => const SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const Text(
            'Could not load loans for this book.',
            style: TextStyle(color: AppColors.error),
          ),
          data: (loans) {
            if (loans.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    'Currently issued',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                for (final loan in loans) _ActiveLoanTile(loan: loan),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActiveLoanTile extends ConsumerWidget {
  final BookIssue loan;

  const _ActiveLoanTile({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overdue = loan.isOverdue;
    final dueLabel = DateFormat('dd MMM yyyy').format(loan.dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: AppSpacing.cellPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            overdue ? Icons.warning_amber_rounded : Icons.person_outline,
            color: overdue ? AppColors.error : theme.colorScheme.onSurfaceVariant,
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.borrowerName ?? 'Unknown borrower',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  overdue
                      ? 'Overdue by ${loan.daysOverdue} day(s) · due $dueLabel'
                      : 'Due $dueLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: overdue ? AppColors.error : null,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.assignment_return_outlined),
            label: const Text('Return'),
            onPressed: () => LoanActions.confirmReturn(context, ref, loan),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
