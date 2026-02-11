import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/emergency.dart';
import '../../../data/repositories/emergency_repository.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(ref.watch(supabaseProvider));
});

final alertsProvider = FutureProvider.family<List<EmergencyAlert>, AlertsFilter>(
  (ref, filter) async {
    final repository = ref.watch(emergencyRepositoryProvider);
    return repository.getAlerts(
      status: filter.status,
      alertType: filter.alertType,
      limit: filter.limit,
    );
  },
);

final alertByIdProvider = FutureProvider.family<EmergencyAlert?, String>(
  (ref, alertId) async {
    final repository = ref.watch(emergencyRepositoryProvider);
    return repository.getAlertById(alertId);
  },
);

final activeAlertProvider = FutureProvider<EmergencyAlert?>((ref) async {
  final repository = ref.watch(emergencyRepositoryProvider);
  return repository.getActiveAlert();
});

final alertResponsesProvider =
    FutureProvider.family<List<EmergencyResponse>, String>(
  (ref, alertId) async {
    final repository = ref.watch(emergencyRepositoryProvider);
    return repository.getAlertResponses(alertId);
  },
);

final responseStatsProvider =
    FutureProvider.family<Map<String, int>, String>(
  (ref, alertId) async {
    final repository = ref.watch(emergencyRepositoryProvider);
    return repository.getResponseStats(alertId);
  },
);

final emergencyContactsProvider =
    FutureProvider.family<List<EmergencyContact>, ContactsFilter>(
  (ref, filter) async {
    final repository = ref.watch(emergencyRepositoryProvider);
    return repository.getEmergencyContacts(
      contactType: filter.contactType,
      activeOnly: filter.activeOnly,
    );
  },
);

class AlertsFilter {
  final String? status;
  final String? alertType;
  final int limit;

  const AlertsFilter({
    this.status,
    this.alertType,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertsFilter &&
          other.status == status &&
          other.alertType == alertType &&
          other.limit == limit;

  @override
  int get hashCode => Object.hash(status, alertType, limit);
}

class ContactsFilter {
  final String? contactType;
  final bool activeOnly;

  const ContactsFilter({
    this.contactType,
    this.activeOnly = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactsFilter &&
          other.contactType == contactType &&
          other.activeOnly == activeOnly;

  @override
  int get hashCode => Object.hash(contactType, activeOnly);
}
