import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/substitution.dart';
import '../../../data/repositories/substitution_repository.dart';

// ==================== REPOSITORY ====================

final substitutionRepositoryProvider =
    Provider<SubstitutionRepository>((ref) {
  return SubstitutionRepository(ref.watch(supabaseProvider));
});

// ==================== ABSENCES FOR DATE ====================

final teacherAbsencesForDateProvider =
    FutureProvider.family<List<TeacherAbsence>, DateTime>(
  (ref, date) async {
    final repo = ref.watch(substitutionRepositoryProvider);
    return repo.getAbsencesByDate(date);
  },
);

// ==================== MY ABSENCES ====================

final myAbsencesProvider =
    FutureProvider.family<List<TeacherAbsence>, String>(
  (ref, teacherId) async {
    final repo = ref.watch(substitutionRepositoryProvider);
    return repo.getMyAbsences(teacherId);
  },
);

// ==================== SUGGESTIONS ====================

class SuggestionParams {
  final String absentTeacherId;
  final DateTime date;

  const SuggestionParams(
      {required this.absentTeacherId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionParams &&
          other.absentTeacherId == absentTeacherId &&
          other.date.toIso8601String().split('T')[0] ==
              date.toIso8601String().split('T')[0];

  @override
  int get hashCode =>
      Object.hash(absentTeacherId, date.toIso8601String().split('T')[0]);
}

final substituteSuggestionsProvider =
    FutureProvider.family<List<SubstitutePeriod>, SuggestionParams>(
  (ref, params) async {
    final repo = ref.watch(substitutionRepositoryProvider);
    return repo.getSuggestedSubstitutes(
      absentTeacherId: params.absentTeacherId,
      date: params.date,
    );
  },
);

// ==================== ASSIGNMENTS FOR DATE ====================

final substitutionAssignmentsProvider =
    FutureProvider.family<List<SubstitutionAssignment>, DateTime>(
  (ref, date) async {
    final repo = ref.watch(substitutionRepositoryProvider);
    return repo.getAssignmentsByDate(date);
  },
);

// ==================== MY SUBSTITUTE DUTIES ====================

final mySubstituteDutiesProvider =
    FutureProvider.family<List<SubstitutionAssignment>, String>(
  (ref, teacherId) async {
    final repo = ref.watch(substitutionRepositoryProvider);
    return repo.getMySubstituteDuties(teacherId);
  },
);

// ==================== ASSIGN NOTIFIER ====================

class AssignSubstituteNotifier extends StateNotifier<AsyncValue<void>> {
  final SubstitutionRepository _repo;
  final Ref _ref;

  AssignSubstituteNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> assign({
    required String absenceId,
    required String timetableId,
    required String absentTeacherId,
    required String substituteTeacherId,
    required String slotId,
    required String sectionId,
    String? subjectId,
    required DateTime date,
    int matchScore = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.assignSubstitute(
        absenceId: absenceId,
        timetableId: timetableId,
        absentTeacherId: absentTeacherId,
        substituteTeacherId: substituteTeacherId,
        slotId: slotId,
        sectionId: sectionId,
        subjectId: subjectId,
        date: date,
        matchScore: matchScore,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(substitutionAssignmentsProvider(date));
      _ref.invalidate(teacherAbsencesForDateProvider(date));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final assignSubstituteProvider =
    StateNotifierProvider<AssignSubstituteNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(substitutionRepositoryProvider);
  return AssignSubstituteNotifier(repo, ref);
});
