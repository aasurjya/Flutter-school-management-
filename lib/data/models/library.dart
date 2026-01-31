/// Library book model
class LibraryBook {
  final String id;
  final String tenantId;
  final String? isbn;
  final String title;
  final String? author;
  final String? publisher;
  final String? category;
  final String? edition;
  final int? publicationYear;
  final int totalCopies;
  final int availableCopies;
  final String? shelfLocation;
  final String? coverUrl;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LibraryBook({
    required this.id,
    required this.tenantId,
    this.isbn,
    required this.title,
    this.author,
    this.publisher,
    this.category,
    this.edition,
    this.publicationYear,
    this.totalCopies = 1,
    this.availableCopies = 1,
    this.shelfLocation,
    this.coverUrl,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    return LibraryBook(
      id: json['id'],
      tenantId: json['tenant_id'],
      isbn: json['isbn'],
      title: json['title'],
      author: json['author'],
      publisher: json['publisher'],
      category: json['category'],
      edition: json['edition'],
      publicationYear: json['publication_year'],
      totalCopies: json['total_copies'] ?? 1,
      availableCopies: json['available_copies'] ?? 1,
      shelfLocation: json['shelf_location'],
      coverUrl: json['cover_url'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'isbn': isbn,
      'title': title,
      'author': author,
      'publisher': publisher,
      'category': category,
      'edition': edition,
      'publication_year': publicationYear,
      'total_copies': totalCopies,
      'available_copies': availableCopies,
      'shelf_location': shelfLocation,
      'cover_url': coverUrl,
      'description': description,
    };
  }

  bool get isAvailable => availableCopies > 0;

  String get availabilityText =>
      '$availableCopies of $totalCopies copies available';
}

/// Book issue model
class BookIssue {
  final String id;
  final String tenantId;
  final String bookId;
  final String borrowerType;
  final String? studentId;
  final String? staffId;
  final String issuedBy;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String status;
  final double fineAmount;
  final bool finePaid;
  final String? remarks;
  final DateTime createdAt;

  // Related data
  final LibraryBook? book;
  final String? borrowerName;

  const BookIssue({
    required this.id,
    required this.tenantId,
    required this.bookId,
    required this.borrowerType,
    this.studentId,
    this.staffId,
    required this.issuedBy,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    this.status = 'issued',
    this.fineAmount = 0,
    this.finePaid = false,
    this.remarks,
    required this.createdAt,
    this.book,
    this.borrowerName,
  });

  factory BookIssue.fromJson(Map<String, dynamic> json) {
    LibraryBook? book;
    if (json['library_books'] != null) {
      book = LibraryBook.fromJson(json['library_books']);
    }

    String? borrowerName;
    if (json['students'] != null) {
      borrowerName =
          '${json['students']['first_name']} ${json['students']['last_name'] ?? ''}'.trim();
    } else if (json['staff'] != null) {
      borrowerName =
          '${json['staff']['first_name']} ${json['staff']['last_name'] ?? ''}'.trim();
    }

    return BookIssue(
      id: json['id'],
      tenantId: json['tenant_id'],
      bookId: json['book_id'],
      borrowerType: json['borrower_type'],
      studentId: json['student_id'],
      staffId: json['staff_id'],
      issuedBy: json['issued_by'],
      issueDate: DateTime.parse(json['issue_date']),
      dueDate: DateTime.parse(json['due_date']),
      returnDate: json['return_date'] != null
          ? DateTime.parse(json['return_date'])
          : null,
      status: json['status'] ?? 'issued',
      fineAmount: (json['fine_amount'] as num?)?.toDouble() ?? 0,
      finePaid: json['fine_paid'] ?? false,
      remarks: json['remarks'],
      createdAt: DateTime.parse(json['created_at']),
      book: book,
      borrowerName: borrowerName,
    );
  }

  bool get isOverdue {
    if (status == 'returned') return false;
    return DateTime.now().isAfter(dueDate);
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  int get daysRemaining {
    if (status == 'returned') return 0;
    final remaining = dueDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  String get statusDisplay {
    switch (status) {
      case 'issued':
        return isOverdue ? 'Overdue' : 'Issued';
      case 'returned':
        return 'Returned';
      case 'overdue':
        return 'Overdue';
      case 'lost':
        return 'Lost';
      default:
        return status;
    }
  }
}
