import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/library.dart';
import 'base_repository.dart';

class LibraryRepository extends BaseRepository {
  LibraryRepository(super.client);

  // ==================== BOOKS ====================

  Future<List<LibraryBook>> getBooks({
    String? category,
    String? searchQuery,
    bool availableOnly = false,
  }) async {
    var query = client
        .from('library_books')
        .select()
        .eq('tenant_id', tenantId!);

    if (availableOnly) {
      query = query.gt('available_copies', 0);
    }

    if (category != null) {
      query = query.eq('category', category);
    }

    final response = await query.order('title');

    var books = (response as List).map((json) => LibraryBook.fromJson(json)).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      books = books.where((book) {
        return book.title.toLowerCase().contains(searchLower) ||
            (book.author?.toLowerCase().contains(searchLower) ?? false) ||
            (book.isbn?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    return books;
  }

  Future<LibraryBook?> getBookById(String bookId) async {
    final response = await client
        .from('library_books')
        .select()
        .eq('id', bookId)
        .maybeSingle();

    if (response == null) return null;
    return LibraryBook.fromJson(response);
  }

  Future<List<String>> getCategories() async {
    final response = await client
        .from('library_books')
        .select('category')
        .eq('tenant_id', tenantId!)
        .order('category');

    final categories = <String>{};
    for (final item in response as List) {
      if (item['category'] != null) {
        categories.add(item['category'] as String);
      }
    }
    return categories.toList();
  }

  Future<LibraryBook> createBook(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    final response = await client
        .from('library_books')
        .insert(data)
        .select()
        .single();
    return LibraryBook.fromJson(response);
  }

  Future<LibraryBook> updateBook(String bookId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('library_books')
        .update(data)
        .eq('id', bookId)
        .select()
        .single();
    return LibraryBook.fromJson(response);
  }

  Future<void> deleteBook(String bookId) async {
    await client.from('library_books').delete().eq('id', bookId);
  }

  // ==================== BOOK ISSUES ====================

  Future<BookIssue> issueBook({
    required String bookId,
    required String borrowerType,
    String? studentId,
    String? staffId,
    required DateTime dueDate,
  }) async {
    // Check availability
    final book = await getBookById(bookId);
    if (book == null || !book.isAvailable) {
      throw Exception('Book is not available');
    }

    // Create issue record
    final issueResponse = await client
        .from('book_issues')
        .insert({
          'tenant_id': tenantId,
          'book_id': bookId,
          'borrower_type': borrowerType,
          'student_id': studentId,
          'staff_id': staffId,
          'issued_by': currentUserId,
          'due_date': dueDate.toIso8601String().split('T')[0],
        })
        .select()
        .single();

    // Update available copies
    await client
        .from('library_books')
        .update({
          'available_copies': book.availableCopies - 1,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookId);

    return BookIssue.fromJson(issueResponse);
  }

  Future<BookIssue> returnBook(String issueId, {double? fineAmount}) async {
    // Get issue details
    final issue = await getIssueById(issueId);
    if (issue == null) throw Exception('Issue record not found');
    if (issue.status == 'returned') throw Exception('Book already returned');

    // Update issue record
    final updateData = <String, dynamic>{
      'status': 'returned',
      'return_date': DateTime.now().toIso8601String().split('T')[0],
    };

    if (fineAmount != null && fineAmount > 0) {
      updateData['fine_amount'] = fineAmount;
    }

    final response = await client
        .from('book_issues')
        .update(updateData)
        .eq('id', issueId)
        .select()
        .single();

    // Update available copies
    final book = await getBookById(issue.bookId);
    if (book != null) {
      await client
          .from('library_books')
          .update({
            'available_copies': book.availableCopies + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', issue.bookId);
    }

    return BookIssue.fromJson(response);
  }

  Future<BookIssue?> getIssueById(String issueId) async {
    final response = await client
        .from('book_issues')
        .select('''
          *,
          library_books(*)
        ''')
        .eq('id', issueId)
        .maybeSingle();

    if (response == null) return null;
    return BookIssue.fromJson(response);
  }

  Future<List<BookIssue>> getIssues({
    String? studentId,
    String? staffId,
    String? bookId,
    String? status,
    bool activeOnly = false,
  }) async {
    var query = client
        .from('book_issues')
        .select('''
          *,
          library_books(*),
          students(first_name, last_name),
          staff(first_name, last_name)
        ''')
        .eq('tenant_id', tenantId!);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }

    if (bookId != null) {
      query = query.eq('book_id', bookId);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    if (activeOnly) {
      query = query.neq('status', 'returned');
    }

    final response = await query.order('issue_date', ascending: false);

    return (response as List).map((json) => BookIssue.fromJson(json)).toList();
  }

  Future<List<BookIssue>> getMyBooks(String userId) async {
    // First check if user is a student
    final studentResponse = await client
        .from('students')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (studentResponse != null) {
      return getIssues(studentId: studentResponse['id'], activeOnly: true);
    }

    // Check if user is staff
    final staffResponse = await client
        .from('staff')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (staffResponse != null) {
      return getIssues(staffId: staffResponse['id'], activeOnly: true);
    }

    return [];
  }

  Future<List<BookIssue>> getOverdueBooks() async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await client
        .from('book_issues')
        .select('''
          *,
          library_books(*),
          students(first_name, last_name),
          staff(first_name, last_name)
        ''')
        .eq('tenant_id', tenantId!)
        .neq('status', 'returned')
        .lt('due_date', today)
        .order('due_date');

    return (response as List).map((json) => BookIssue.fromJson(json)).toList();
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getLibraryStats() async {
    final booksResponse = await client
        .from('library_books')
        .select('total_copies, available_copies')
        .eq('tenant_id', tenantId!);

    final books = booksResponse as List;
    final totalBooks = books.fold<int>(0, (sum, b) => sum + (b['total_copies'] as int));
    final availableBooks =
        books.fold<int>(0, (sum, b) => sum + (b['available_copies'] as int));

    final overdueBooks = await getOverdueBooks();

    final today = DateTime.now().toIso8601String().split('T')[0];
    final issuesTodayResponse = await client
        .from('book_issues')
        .select('id')
        .eq('tenant_id', tenantId!)
        .eq('issue_date', today);

    return {
      'total_books': totalBooks,
      'available_books': availableBooks,
      'issued_books': totalBooks - availableBooks,
      'overdue_books': overdueBooks.length,
      'issues_today': (issuesTodayResponse as List).length,
    };
  }

  Future<void> renewBook(String issueId, DateTime newDueDate) async {
    await client
        .from('book_issues')
        .update({
          'due_date': newDueDate.toIso8601String().split('T')[0],
        })
        .eq('id', issueId);
  }

  Future<void> markAsLost(String issueId) async {
    final issue = await getIssueById(issueId);
    if (issue == null) throw Exception('Issue record not found');

    await client
        .from('book_issues')
        .update({
          'status': 'lost',
          'return_date': DateTime.now().toIso8601String().split('T')[0],
        })
        .eq('id', issueId);
  }

  Future<void> payFine(String issueId) async {
    await client
        .from('book_issues')
        .update({'fine_paid': true})
        .eq('id', issueId);
  }
}
