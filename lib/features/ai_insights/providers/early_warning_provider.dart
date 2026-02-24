import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/early_warning_alert.dart';
import '../../../data/repositories/early_warning_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final earlyWarningRepositoryProvider =
    Provider<EarlyWarningRepository>((ref) {
  return EarlyWarningRepository(ref.watch(supabaseProvider));
});

// ---------------------------------------------------------------------------
// Filter class
// ---------------------------------------------------------------------------

class AlertsFilter {
  final String? status;
  final String? severity;
  final int limit;
  final int offset;

  const AlertsFilter({
    this.status,
    this.severity,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertsFilter &&
          other.status == status &&
          other.severity == severity &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(status, severity, limit, offset);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Fetches a paginated, optionally filtered list of early warning alerts.
final alertsProvider =
    FutureProvider.family<List<EarlyWarningAlert>, AlertsFilter>(
  (ref, filter) async {
    final repo = ref.watch(earlyWarningRepositoryProvider);
    return repo.getAlerts(
      status: filter.status,
      severity: filter.severity,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

/// Returns the total count of unresolved alerts (new + acknowledged + in_progress).
final unresolvedAlertCountProvider = FutureProvider<int>(
  (ref) async {
    final repo = ref.watch(earlyWarningRepositoryProvider);
    return repo.getUnresolvedCount();
  },
);

/// Fetches a single alert by its ID, including joined student data.
final alertDetailProvider =
    FutureProvider.family<EarlyWarningAlert?, String>(
  (ref, alertId) async {
    final repo = ref.watch(earlyWarningRepositoryProvider);
    return repo.getAlertById(alertId);
  },
);

/// Fetches all alert rules for the current tenant.
final alertRulesProvider = FutureProvider<List<AlertRule>>(
  (ref) async {
    final repo = ref.watch(earlyWarningRepositoryProvider);
    return repo.getAlertRules();
  },
);

/// Enriches an alert with an LLM-generated explanation.
///
/// Fetches the base alert via [alertDetailProvider], then calls the AI text
/// generator to produce a human-readable explanation. Falls back to the
/// un-enriched alert if the LLM is unavailable.
final enrichedAlertDetailProvider =
    FutureProvider.family<EarlyWarningAlert?, String>(
  (ref, alertId) async {
    final alert = await ref.watch(alertDetailProvider(alertId).future);
    if (alert == null) return null;

    final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

    final result = await aiTextGenerator.generateAlertExplanation(
      studentName: alert.studentName ?? 'Student',
      category: alert.category.displayLabel,
      severity: alert.severity.displayLabel,
      triggerConditions: alert.triggerConditions,
      fallback: '',
    );

    if (result.text.isEmpty) return alert;
    return alert.copyWith(aiExplanation: result.text);
  },
);
