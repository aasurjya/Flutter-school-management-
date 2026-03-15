import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/student.dart';
import '../../../data/repositories/parent_repository.dart';

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepository(Supabase.instance.client);
});

/// Provides all parents linked to a given [studentId].
final parentsByStudentProvider =
    FutureProvider.family<List<StudentParentLink>, String>(
  (ref, studentId) async {
    final repo = ref.watch(parentRepositoryProvider);
    return repo.getParentsByStudent(studentId);
  },
);

/// Notifier that drives parent search results.
class ParentSearchNotifier extends StateNotifier<AsyncValue<List<Parent>>> {
  final ParentRepository _repo;

  ParentSearchNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final results = await _repo.searchParents(query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data([]);
}

final parentSearchProvider =
    StateNotifierProvider<ParentSearchNotifier, AsyncValue<List<Parent>>>(
  (ref) => ParentSearchNotifier(ref.watch(parentRepositoryProvider)),
);
