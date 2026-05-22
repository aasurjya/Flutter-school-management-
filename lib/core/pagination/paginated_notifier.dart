import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic, reusable paginated-list state.
///
/// Used by [PaginatedNotifier] to drive infinite-scroll lists across the app
/// (students, fees, messages, attendance, …). All state is immutable; mutate
/// through [copyWith].
@immutable
class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isEmpty => items.isEmpty && !isLoading;
}

/// Page fetcher signature. Implementations call the repository with the given
/// `offset`/`limit`. Returns the page slice; pagination ends when the slice
/// is shorter than `limit`.
typedef PageFetcher<T> = Future<List<T>> Function({
  required int offset,
  required int limit,
});

/// Generic infinite-scroll notifier.
///
/// Usage:
/// ```dart
/// final feesProvider = StateNotifierProvider.autoDispose
///     .family<PaginatedNotifier<Invoice>, PaginatedState<Invoice>, FeesFilter>(
///   (ref, filter) {
///     final repo = ref.watch(feeRepositoryProvider);
///     return PaginatedNotifier<Invoice>(
///       fetcher: ({required offset, required limit}) =>
///           repo.getInvoices(filter: filter, offset: offset, limit: limit),
///     )..loadInitial();
///   },
/// );
/// ```
class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  final PageFetcher<T> _fetcher;
  final int pageSize;
  int _offset = 0;

  PaginatedNotifier({
    required PageFetcher<T> fetcher,
    this.pageSize = 25,
  })  : _fetcher = fetcher,
        super(const PaginatedState());

  Future<void> loadInitial() async {
    _offset = 0;
    state = const PaginatedState(isLoading: true);
    try {
      final results = await _fetcher(offset: 0, limit: pageSize);
      _offset = results.length;
      state = PaginatedState<T>(
        items: results,
        hasMore: results.length == pageSize,
      );
    } catch (e) {
      state = PaginatedState<T>(error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final results = await _fetcher(offset: _offset, limit: pageSize);
      _offset += results.length;
      state = state.copyWith(
        items: [...state.items, ...results],
        isLoadingMore: false,
        hasMore: results.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() => loadInitial();

  /// Optimistic insert at top — useful after create-flows.
  void prepend(T item) {
    state = state.copyWith(items: [item, ...state.items]);
    _offset += 1;
  }

  /// Optimistic remove — useful after delete-flows.
  void removeWhere(bool Function(T) test) {
    final next = state.items.where((e) => !test(e)).toList();
    final removed = state.items.length - next.length;
    state = state.copyWith(items: next);
    _offset = (_offset - removed).clamp(0, _offset);
  }
}

/// Drop-in widget that attaches `loadMore()` to scroll near-end.
///
/// Wrap any scroll view; the controller is exposed so the caller can also
/// attach it to a `CustomScrollView`/`ListView` for the actual rendering.
class PaginationScrollListener {
  PaginationScrollListener({
    required this.controller,
    required this.onLoadMore,
    this.threshold = 240,
  }) {
    controller.addListener(_onScroll);
  }

  final ScrollController controller;
  final VoidCallback onLoadMore;

  /// Pixels-from-bottom that triggers a load.
  final double threshold;

  void _onScroll() {
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      onLoadMore();
    }
  }

  void dispose() => controller.removeListener(_onScroll);
}
