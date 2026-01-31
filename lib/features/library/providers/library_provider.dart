import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/library.dart';
import '../../../data/repositories/library_repository.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(Supabase.instance.client);
});

// Books providers
final booksProvider = FutureProvider.family<List<LibraryBook>, BooksFilter>(
  (ref, filter) async {
    final repository = ref.watch(libraryRepositoryProvider);
    return repository.getBooks(
      category: filter.category,
      searchQuery: filter.searchQuery,
      availableOnly: filter.availableOnly,
    );
  },
);

final bookByIdProvider = FutureProvider.family<LibraryBook?, String>(
  (ref, bookId) async {
    final repository = ref.watch(libraryRepositoryProvider);
    return repository.getBookById(bookId);
  },
);

final bookCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.getCategories();
});

// Issues providers
final bookIssuesProvider = FutureProvider.family<List<BookIssue>, IssuesFilter>(
  (ref, filter) async {
    final repository = ref.watch(libraryRepositoryProvider);
    return repository.getIssues(
      studentId: filter.studentId,
      staffId: filter.staffId,
      bookId: filter.bookId,
      status: filter.status,
      activeOnly: filter.activeOnly,
    );
  },
);

final myBooksProvider = FutureProvider<List<BookIssue>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return repository.getMyBooks(userId);
});

final overdueBookssProvider = FutureProvider<List<BookIssue>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.getOverdueBooks();
});

// Stats provider
final libraryStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.getLibraryStats();
});

// Filter classes
class BooksFilter {
  final String? category;
  final String? searchQuery;
  final bool availableOnly;

  const BooksFilter({
    this.category,
    this.searchQuery,
    this.availableOnly = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BooksFilter &&
        other.category == category &&
        other.searchQuery == searchQuery &&
        other.availableOnly == availableOnly;
  }

  @override
  int get hashCode => Object.hash(category, searchQuery, availableOnly);
}

class IssuesFilter {
  final String? studentId;
  final String? staffId;
  final String? bookId;
  final String? status;
  final bool activeOnly;

  const IssuesFilter({
    this.studentId,
    this.staffId,
    this.bookId,
    this.status,
    this.activeOnly = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IssuesFilter &&
        other.studentId == studentId &&
        other.staffId == staffId &&
        other.bookId == bookId &&
        other.status == status &&
        other.activeOnly == activeOnly;
  }

  @override
  int get hashCode =>
      Object.hash(studentId, staffId, bookId, status, activeOnly);
}
