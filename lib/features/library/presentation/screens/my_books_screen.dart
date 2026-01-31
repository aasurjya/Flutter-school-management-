import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/library.dart';
import '../../providers/library_provider.dart';

class MyBooksScreen extends ConsumerWidget {
  const MyBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myBooksAsync = ref.watch(myBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books'),
      ),
      body: myBooksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('No books borrowed'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/library'),
                    child: const Text('Browse Library'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myBooksProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                return _BorrowedBookCard(issue: books[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _BorrowedBookCard extends StatelessWidget {
  final BookIssue issue;

  const _BorrowedBookCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = issue.book;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: book != null ? () => context.push('/library/book/${book.id}') : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              Container(
                width: 60,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.antiAlias,
                child: book?.coverUrl != null
                    ? Image.network(
                        book!.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.book,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.book,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book?.title ?? 'Unknown Book',
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book?.author != null)
                      Text(
                        book!.author!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Issue: ${DateFormat('dd MMM yyyy').format(issue.issueDate)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 14,
                          color: issue.isOverdue ? Colors.red : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat('dd MMM yyyy').format(issue.dueDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: issue.isOverdue ? Colors.red : null,
                            fontWeight: issue.isOverdue ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _StatusBadge(issue: issue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookIssue issue;

  const _StatusBadge({required this.issue});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (issue.isOverdue) {
      backgroundColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      text = 'Overdue by ${issue.daysOverdue} days';
    } else if (issue.daysRemaining <= 3) {
      backgroundColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
      text = '${issue.daysRemaining} days remaining';
    } else {
      backgroundColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      text = '${issue.daysRemaining} days remaining';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
