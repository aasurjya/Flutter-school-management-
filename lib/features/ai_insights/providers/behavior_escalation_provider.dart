import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';

/// Sprint 1.4: one row per student whose discipline incident rate has
/// accelerated in the last 14 days vs the prior 14 days.
///
/// Backed by the SQL RPC `compute_behavior_escalation` (migration 00057).
/// Pure SQL, no LLM. Cost per query: ~free.
class BehaviorEscalationRow {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? admissionNumber;
  final int recentIncidentCount;
  final int priorIncidentCount;
  final int recentWeightedScore;
  final int priorWeightedScore;
  final int escalationScore;
  final String? mostSevereRecent;
  final DateTime? lastIncidentDate;

  const BehaviorEscalationRow({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.admissionNumber,
    required this.recentIncidentCount,
    required this.priorIncidentCount,
    required this.recentWeightedScore,
    required this.priorWeightedScore,
    required this.escalationScore,
    required this.mostSevereRecent,
    required this.lastIncidentDate,
  });

  factory BehaviorEscalationRow.fromJson(Map<String, dynamic> j) {
    final lastDt = j['last_incident_date'] as String?;
    return BehaviorEscalationRow(
      studentId: j['student_id'] as String,
      firstName: j['first_name'] as String,
      lastName: j['last_name'] as String,
      admissionNumber: j['admission_number'] as String?,
      recentIncidentCount: (j['recent_incident_count'] as num).toInt(),
      priorIncidentCount: (j['prior_incident_count'] as num).toInt(),
      recentWeightedScore: (j['recent_weighted_score'] as num).toInt(),
      priorWeightedScore: (j['prior_weighted_score'] as num).toInt(),
      escalationScore: (j['escalation_score'] as num).toInt(),
      mostSevereRecent: j['most_severe_recent'] as String?,
      lastIncidentDate: lastDt != null ? DateTime.tryParse(lastDt) : null,
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  /// 0..1 for a UI sparkline-style indicator. recent_weighted of 8+ caps.
  double get severityIndicator =>
      (recentWeightedScore / 8).clamp(0, 1).toDouble();
}

class BehaviorEscalationFilter {
  final String tenantId;
  final String? sectionId;
  final int limit;

  const BehaviorEscalationFilter({
    required this.tenantId,
    this.sectionId,
    this.limit = 5,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BehaviorEscalationFilter &&
          other.tenantId == tenantId &&
          other.sectionId == sectionId &&
          other.limit == limit;

  @override
  int get hashCode => Object.hash(tenantId, sectionId, limit);
}

class BehaviorEscalationSummary {
  final int studentsWithRecentIncidents;
  final int totalRecentIncidents;
  final int recentMajorOrCritical;
  final int priorTotalIncidents;

  const BehaviorEscalationSummary({
    required this.studentsWithRecentIncidents,
    required this.totalRecentIncidents,
    required this.recentMajorOrCritical,
    required this.priorTotalIncidents,
  });

  factory BehaviorEscalationSummary.empty() =>
      const BehaviorEscalationSummary(
        studentsWithRecentIncidents: 0,
        totalRecentIncidents: 0,
        recentMajorOrCritical: 0,
        priorTotalIncidents: 0,
      );

  factory BehaviorEscalationSummary.fromJson(Map<String, dynamic> j) =>
      BehaviorEscalationSummary(
        studentsWithRecentIncidents:
            (j['students_with_recent_incidents'] as num?)?.toInt() ?? 0,
        totalRecentIncidents:
            (j['total_recent_incidents'] as num?)?.toInt() ?? 0,
        recentMajorOrCritical:
            (j['recent_major_or_critical'] as num?)?.toInt() ?? 0,
        priorTotalIncidents:
            (j['prior_total_incidents'] as num?)?.toInt() ?? 0,
      );

  /// Δ vs prior 14 days. Positive = trending up.
  int get trendDelta => totalRecentIncidents - priorTotalIncidents;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final behaviorEscalationProvider = FutureProvider.autoDispose
    .family<List<BehaviorEscalationRow>, BehaviorEscalationFilter>(
        (ref, filter) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final rows = await client.rpc(
    'compute_behavior_escalation',
    params: {
      'p_tenant_id': filter.tenantId,
      'p_section_id': filter.sectionId,
      'p_limit': filter.limit,
    },
  );
  if (rows is! List) return const [];
  return rows
      .whereType<Map>()
      .map((r) => BehaviorEscalationRow.fromJson(r.cast<String, dynamic>()))
      .toList();
});

final behaviorEscalationSummaryProvider =
    FutureProvider.autoDispose.family<BehaviorEscalationSummary, String>(
        (ref, tenantId) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final row = await client
      .from('v_behavior_escalation_summary')
      .select()
      .eq('tenant_id', tenantId)
      .maybeSingle();
  if (row == null) return BehaviorEscalationSummary.empty();
  return BehaviorEscalationSummary.fromJson(row);
});
