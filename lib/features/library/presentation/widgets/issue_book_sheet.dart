import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../data/models/library.dart';
import '../../../../data/models/student.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../students/providers/students_provider.dart';
import '../../providers/library_provider.dart';

/// Bottom sheet to issue a book to a student.
///
/// Flow: search/pick student → optionally pick a different book → set due
/// date (default +14 days) → submit. Used by the librarian FAB on the
/// catalogue and the book detail screen.
class IssueBookSheet extends ConsumerStatefulWidget {
  final LibraryBook? initialBook;

  const IssueBookSheet({super.key, this.initialBook});

  @override
  ConsumerState<IssueBookSheet> createState() => _IssueBookSheetState();
}

class _IssueBookSheetState extends ConsumerState<IssueBookSheet> {
  final TextEditingController _studentQueryController = TextEditingController();
  final TextEditingController _bookQueryController = TextEditingController();

  Student? _selectedStudent;
  LibraryBook? _selectedBook;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  bool _submitting = false;
  Timer? _studentDebounce;
  Timer? _bookDebounce;
  String _studentQuery = '';
  String _bookQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.initialBook;
  }

  @override
  void dispose() {
    _studentQueryController.dispose();
    _bookQueryController.dispose();
    _studentDebounce?.cancel();
    _bookDebounce?.cancel();
    super.dispose();
  }

  void _onStudentQueryChanged(String value) {
    _studentDebounce?.cancel();
    _studentDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _studentQuery = value.trim());
    });
  }

  void _onBookQueryChanged(String value) {
    _bookDebounce?.cancel();
    _bookDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _bookQuery = value.trim());
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    final book = _selectedBook;
    final student = _selectedStudent;

    if (book == null) {
      context.showErrorSnackBar('Pick a book to issue.');
      return;
    }
    if (student == null) {
      context.showErrorSnackBar('Pick a student first.');
      return;
    }
    if (!book.isAvailable) {
      context.showErrorSnackBar('No copies of this book are available.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.issueBook(
        bookId: book.id,
        borrowerType: 'student',
        studentId: student.id,
        dueDate: _dueDate,
      );

      // Refresh the relevant providers so the new loan shows immediately.
      ref.invalidate(activeLoansProvider);
      ref.invalidate(overdueBookssProvider);
      ref.invalidate(libraryStatsProvider);
      ref.invalidate(activeLoansForBookProvider(book.id));
      ref.invalidate(bookByIdProvider(book.id));
      ref.invalidate(booksProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      context.showSuccessSnackBar('Book issued to ${student.fullName}.');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Could not issue book. $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md + viewInsets,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.separator,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.gapSm,
              Text(
                'Issue book',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              AppSpacing.gapSm,

              // ----- Book picker -----
              if (_selectedBook == null) ...[
                Text('Book', style: Theme.of(context).textTheme.titleSmall),
                AppSpacing.gapXs,
                TextField(
                  controller: _bookQueryController,
                  decoration: InputDecoration(
                    hintText: 'Search by title, author or ISBN',
                    prefixIcon: const Icon(Icons.menu_book_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onBookQueryChanged,
                ),
                AppSpacing.gapXs,
                _BookResults(
                  query: _bookQuery,
                  onSelect: (book) => setState(() => _selectedBook = book),
                ),
                AppSpacing.gapMd,
              ] else ...[
                _SelectedBookTile(
                  book: _selectedBook!,
                  onChange: widget.initialBook != null
                      ? null
                      : () => setState(() => _selectedBook = null),
                ),
                AppSpacing.gapMd,
              ],

              // ----- Student picker -----
              Text('Borrower', style: Theme.of(context).textTheme.titleSmall),
              AppSpacing.gapXs,
              if (_selectedStudent == null) ...[
                TextField(
                  controller: _studentQueryController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or admission number',
                    prefixIcon: const Icon(Icons.person_search_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onStudentQueryChanged,
                ),
                AppSpacing.gapXs,
                _StudentResults(
                  query: _studentQuery,
                  onSelect: (student) =>
                      setState(() => _selectedStudent = student),
                ),
              ] else
                _SelectedStudentTile(
                  student: _selectedStudent!,
                  onChange: () => setState(() => _selectedStudent = null),
                ),
              AppSpacing.gapMd,

              // ----- Due date -----
              Text('Due date', style: Theme.of(context).textTheme.titleSmall),
              AppSpacing.gapXs,
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDueDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.separator),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined),
                      AppSpacing.gapSm,
                      Text(DateFormat('EEE, dd MMM yyyy').format(_dueDate)),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_outlined, size: 18),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapLg,

              // ----- Submit -----
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_submitting ? 'Issuing...' : 'Issue book'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookResults extends ConsumerWidget {
  final String query;
  final ValueChanged<LibraryBook> onSelect;

  const _BookResults({required this.query, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const SizedBox.shrink();
    }
    final booksAsync = ref.watch(
      booksProvider(BooksFilter(searchQuery: query, availableOnly: true)),
    );
    return booksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) =>
          const Text('Could not load books.', style: TextStyle(color: AppColors.error)),
      data: (books) {
        if (books.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text('No matching books.'),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.book_outlined),
                title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${book.author ?? 'Unknown'} · ${book.availabilityText}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onSelect(book),
              );
            },
          ),
        );
      },
    );
  }
}

class _SelectedBookTile extends StatelessWidget {
  final LibraryBook book;
  final VoidCallback? onChange;

  const _SelectedBookTile({required this.book, this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.separator),
      ),
      child: Row(
        children: [
          const Icon(Icons.book_outlined),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${book.author ?? 'Unknown author'} · ${book.availabilityText}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onChange != null)
            TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _StudentResults extends ConsumerWidget {
  final String query;
  final ValueChanged<Student> onSelect;

  const _StudentResults({required this.query, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const SizedBox.shrink();
    }
    final repo = ref.watch(studentRepositoryProvider);
    return FutureBuilder<List<Student>>(
      future: repo.getStudents(searchQuery: query, limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Text(
            'Could not load students.',
            style: TextStyle(color: AppColors.error),
          );
        }
        final students = snapshot.data ?? const <Student>[];
        if (students.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text('No matching students.'),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                  child: Text(
                    student.initials.isEmpty ? '?' : student.initials,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(student.fullName),
                subtitle: Text('Admn #${student.admissionNumber}'),
                onTap: () => onSelect(student),
              );
            },
          ),
        );
      },
    );
  }
}

class _SelectedStudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onChange;

  const _SelectedStudentTile({required this.student, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.separator),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primary,
            child: Text(
              student.initials.isEmpty ? '?' : student.initials,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  'Admn #${student.admissionNumber}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}
