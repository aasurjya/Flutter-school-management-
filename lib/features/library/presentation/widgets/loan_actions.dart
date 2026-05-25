import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/library.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../providers/library_provider.dart';

/// Shared helpers for librarian loan actions so the same confirmation
/// dialog + invalidation logic is used from every entry point.
class LoanActions {
  LoanActions._();

  /// Confirm + mark the given loan as returned. Returns true on success.
  static Future<bool> confirmReturn(
    BuildContext context,
    WidgetRef ref,
    BookIssue issue,
  ) async {
    final borrower = issue.borrowerName ?? 'this borrower';
    final bookTitle = issue.book?.title ?? 'this book';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as returned?'),
        content: Text('$bookTitle will be returned by $borrower.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm return'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    try {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.returnBook(issue.id);

      ref.invalidate(activeLoansProvider);
      ref.invalidate(overdueBookssProvider);
      ref.invalidate(libraryStatsProvider);
      ref.invalidate(activeLoansForBookProvider(issue.bookId));
      ref.invalidate(bookByIdProvider(issue.bookId));
      ref.invalidate(booksProvider);
      ref.invalidate(myBooksProvider);

      if (context.mounted) {
        context.showSuccessSnackBar('Book marked as returned.');
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Could not return book. $e');
      }
      return false;
    }
  }
}
