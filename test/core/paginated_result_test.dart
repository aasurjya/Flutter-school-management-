// Test: PaginatedResult model.
//
// Phase 3.3 — critical flow test #2: pagination.
// Verifies the pagination math (hasMore, offset, map) that all 18 repos
// now depend on. A bug here would break every list screen at scale.

import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/data/models/paginated_result.dart';

void main() {
  group('PaginatedResult', () {
    test('hasMore is true when there are more pages', () {
      final result = PaginatedResult<int>(
        items: List.generate(25, (i) => i),
        totalCount: 100,
        page: 0,
        pageSize: 25,
      );
      expect(result.hasMore, isTrue);
      expect(result.length, 25);
      expect(result.offset, 0);
    });

    test('hasMore is false on the last page', () {
      final result = PaginatedResult<int>(
        items: List.generate(10, (i) => i),
        totalCount: 60,
        page: 2,
        pageSize: 25,
      );
      // page 2 * 25 = 50, +25 = 75 > 60, so this is the last page
      expect(result.hasMore, isFalse);
      expect(result.offset, 50);
    });

    test('hasMore is false when totalCount equals exactly filled pages', () {
      final result = PaginatedResult<int>(
        items: List.generate(25, (i) => i),
        totalCount: 50,
        page: 1,
        pageSize: 25,
      );
      // page 1 * 25 = 25, +25 = 50 == 50, no more
      expect(result.hasMore, isFalse);
    });

    test('hasMore is true at the boundary (totalCount = page*pageSize + 1)', () {
      final result = PaginatedResult<int>(
        items: List.generate(25, (i) => i),
        totalCount: 51,
        page: 1,
        pageSize: 25,
      );
      // page 1 * 25 = 25, +25 = 50 < 51, so there's 1 more item
      expect(result.hasMore, isTrue);
    });

    test('map transforms items while preserving metadata', () {
      final result = PaginatedResult<int>(
        items: [1, 2, 3],
        totalCount: 10,
        page: 0,
        pageSize: 3,
      );
      final mapped = result.map((n) => n.toString());

      expect(mapped.items, ['1', '2', '3']);
      expect(mapped.totalCount, 10);
      expect(mapped.page, 0);
      expect(mapped.pageSize, 3);
      expect(mapped.hasMore, isTrue);
    });

    test('empty result has hasMore=false', () {
      final result = PaginatedResult<int>(
        items: const [],
        totalCount: 0,
        page: 0,
        pageSize: 25,
      );
      expect(result.hasMore, isFalse);
      expect(result.length, 0);
    });

    test('single-item result with totalCount=1 has hasMore=false', () {
      final result = PaginatedResult<int>(
        items: [42],
        totalCount: 1,
        page: 0,
        pageSize: 25,
      );
      expect(result.hasMore, isFalse);
    });
  });
}
