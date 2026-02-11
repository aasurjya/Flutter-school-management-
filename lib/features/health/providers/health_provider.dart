import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/health_record.dart';
import '../../../data/repositories/health_repository.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(ref.watch(supabaseProvider));
});

// Health record providers
final healthRecordProvider = FutureProvider.family<StudentHealthRecord?, String>(
  (ref, studentId) async {
    final repository = ref.watch(healthRepositoryProvider);
    return repository.getHealthRecord(studentId);
  },
);

final studentsWithAllergiesProvider =
    FutureProvider<List<StudentHealthRecord>>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  return repository.getHealthRecordsWithAllergies();
});

final studentsWithConditionsProvider =
    FutureProvider<List<StudentHealthRecord>>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  return repository.getHealthRecordsWithConditions();
});

// Incident providers
final incidentsProvider = FutureProvider.family<List<HealthIncident>, IncidentFilter>(
  (ref, filter) async {
    final repository = ref.watch(healthRepositoryProvider);
    return repository.getIncidents(
      studentId: filter.studentId,
      severity: filter.severity,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      pendingFollowUp: filter.pendingFollowUp,
    );
  },
);

final incidentByIdProvider = FutureProvider.family<HealthIncident?, String>(
  (ref, incidentId) async {
    final repository = ref.watch(healthRepositoryProvider);
    return repository.getIncidentById(incidentId);
  },
);

final pendingFollowUpsProvider = FutureProvider<List<HealthIncident>>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  return repository.getIncidents(pendingFollowUp: true);
});

// Stats provider
final healthStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  return repository.getHealthStats();
});

// Filter class
class IncidentFilter {
  final String? studentId;
  final String? severity;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool pendingFollowUp;

  const IncidentFilter({
    this.studentId,
    this.severity,
    this.fromDate,
    this.toDate,
    this.pendingFollowUp = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncidentFilter &&
        other.studentId == studentId &&
        other.severity == severity &&
        other.fromDate == fromDate &&
        other.toDate == toDate &&
        other.pendingFollowUp == pendingFollowUp;
  }

  @override
  int get hashCode =>
      Object.hash(studentId, severity, fromDate, toDate, pendingFollowUp);
}
