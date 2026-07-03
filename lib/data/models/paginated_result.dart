/// Generic paginated list result.
///
/// Repositories return this instead of bare `List<T>` so list screens can
/// drive infinite-scroll: [hasMore] tells the UI whether to fetch the next
/// page, and [totalCount] powers the header count.
///
/// Pattern:
///   final page1 = await repo.getStudentsPaginated(page: 0, pageSize: 25);
///   // page1.items, page1.hasMore, page1.totalCount
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  /// True when there are more pages to fetch.
  bool get hasMore => (page + 1) * pageSize < totalCount;

  /// Index of the first item in this page (0-based).
  int get offset => page * pageSize;

  /// Number of items actually returned (may be < pageSize on the last page).
  int get length => items.length;

  /// Map the items to a new type, preserving pagination metadata.
  PaginatedResult<R> map<R>(R Function(T) fn) => PaginatedResult<R>(
        items: items.map(fn).toList(),
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
      );
}
