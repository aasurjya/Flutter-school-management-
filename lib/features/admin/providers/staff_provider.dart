import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/repositories/staff_repository.dart';

export '../../../data/repositories/staff_repository.dart' show StaffMember;

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(supabaseProvider));
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class StaffListState {
  final List<StaffMember> staff;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const StaffListState({
    this.staff = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  StaffListState copyWith({
    List<StaffMember>? staff,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) =>
      StaffListState(
        staff: staff ?? this.staff,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class StaffNotifier extends StateNotifier<StaffListState> {
  final StaffRepository _repo;
  final String role;

  static const _pageSize = 25;
  int _offset = 0;
  String? _lastSearchQuery;

  StaffNotifier(this._repo, this.role) : super(const StaffListState()) {
    loadInitial();
  }

  Future<void> loadInitial({String? searchQuery}) async {
    _offset = 0;
    _lastSearchQuery = searchQuery;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _repo.getStaffByRole(
        role,
        limit: _pageSize,
        offset: 0,
        searchQuery: searchQuery,
      );
      state = state.copyWith(
        staff: results,
        isLoading: false,
        hasMore: results.length == _pageSize,
      );
      _offset = results.length;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final results = await _repo.getStaffByRole(
        role,
        limit: _pageSize,
        offset: _offset,
        searchQuery: _lastSearchQuery,
      );
      state = state.copyWith(
        staff: [...state.staff, ...results],
        isLoadingMore: false,
        hasMore: results.length == _pageSize,
      );
      _offset += results.length;
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Prepends a freshly created member to the top of the list without a round-trip.
  void addStaff(StaffMember member) {
    state = state.copyWith(staff: [member, ...state.staff]);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final staffNotifierProvider =
    StateNotifierProvider.family<StaffNotifier, StaffListState, String>(
  (ref, role) {
    final repo = ref.watch(staffRepositoryProvider);
    return StaffNotifier(repo, role);
  },
);
