import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/discipline.dart';
import '../../../data/repositories/discipline_repository.dart';

// ─── Repository Provider ────────────────────────────────────

final disciplineRepositoryProvider = Provider<DisciplineRepository>((ref) {
  return DisciplineRepository(ref.watch(supabaseProvider));
});

// ─── Categories ─────────────────────────────────────────────

final behaviorCategoriesProvider =
    FutureProvider.family<List<BehaviorCategory>, BehaviorCategoryType?>(
  (ref, type) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getCategories(type: type);
  },
);

final allCategoriesProvider = FutureProvider<List<BehaviorCategory>>(
  (ref) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getCategories(activeOnly: false);
  },
);

// ─── Incidents ──────────────────────────────────────────────

final behaviorIncidentsProvider =
    FutureProvider.family<List<BehaviorIncident>, IncidentFilter>(
  (ref, filter) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getIncidents(filter: filter);
  },
);

final incidentDetailProvider =
    FutureProvider.family<BehaviorIncident, String>(
  (ref, id) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getIncidentById(id);
  },
);

final recentIncidentsProvider = FutureProvider<List<BehaviorIncident>>(
  (ref) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getIncidents(
      filter: const IncidentFilter(limit: 10),
    );
  },
);

// ─── Student Behavior ───────────────────────────────────────

final studentBehaviorHistoryProvider =
    FutureProvider.family<List<BehaviorIncident>, String>(
  (ref, studentId) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getStudentBehaviorHistory(studentId);
  },
);

final studentBehaviorScoreProvider =
    FutureProvider.family<BehaviorScore, String>(
  (ref, studentId) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getStudentBehaviorScore(studentId);
  },
);

// ─── Behavior Plans ─────────────────────────────────────────

final behaviorPlansProvider =
    FutureProvider.family<List<BehaviorPlan>, String?>(
  (ref, studentId) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getPlans(studentId: studentId);
  },
);

final activePlansProvider = FutureProvider<List<BehaviorPlan>>(
  (ref) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getPlans(status: BehaviorPlanStatus.active);
  },
);

final planDetailProvider =
    FutureProvider.family<BehaviorPlan, String>(
  (ref, id) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getPlanById(id);
  },
);

// ─── Positive Recognitions ──────────────────────────────────

final positiveRecognitionsProvider =
    FutureProvider.family<List<PositiveRecognition>, String?>(
  (ref, studentId) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getRecognitions(studentId: studentId);
  },
);

final publicRecognitionsProvider =
    FutureProvider<List<PositiveRecognition>>(
  (ref) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getRecognitions(publicOnly: true, limit: 20);
  },
);

// ─── Stats / Dashboard ─────────────────────────────────────

final behaviorStatsProvider =
    FutureProvider.family<BehaviorStats, DateRangeFilter>(
  (ref, filter) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getBehaviorStats(
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
  },
);

final defaultBehaviorStatsProvider = FutureProvider<BehaviorStats>(
  (ref) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getBehaviorStats();
  },
);

final topPositiveStudentsProvider =
    FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getTopPositiveStudents();
  },
);

// ─── Detention ──────────────────────────────────────────────

final detentionSchedulesProvider =
    FutureProvider<List<DetentionSchedule>>(
  (ref) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getDetentionSchedules();
  },
);

final detentionAssignmentsProvider =
    FutureProvider.family<List<DetentionAssignment>, DateTime?>(
  (ref, date) async {
    final repo = ref.watch(disciplineRepositoryProvider);
    return repo.getDetentionAssignments(date: date);
  },
);

// ─── Filter Models ──────────────────────────────────────────

class DateRangeFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  const DateRangeFilter({this.startDate, this.endDate});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRangeFilter &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate);
}

// ─── State Providers (for filters) ──────────────────────────

final incidentFilterProvider = StateProvider<IncidentFilter>(
  (ref) => const IncidentFilter(),
);

final selectedIncidentSeverityProvider =
    StateProvider<IncidentSeverity?>((ref) => null);

final selectedIncidentStatusProvider =
    StateProvider<IncidentStatus?>((ref) => null);
