import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/supabase_provider.dart';

/// Sprint 1.2 — Principal's Weekly Digest provider.
///
/// Reads the cached row from `principal_digests` for the current week; if
/// missing, gathers KPIs from existing dashboard providers and asks the
/// gateway for a 5-7 sentence executive briefing, then upserts the row via
/// the `upsert_principal_digest` RPC (migration 00056).
///
/// Note: the provider is `autoDispose` and the card invalidates on pull-to-
/// refresh — so users cannot infinite-loop expensive Claude calls; the
/// gateway also caches by `request_hash` for the same week's KPIs.
class PrincipalDigest {
  final String narrative;
  final DateTime weekStart;
  final Map<String, dynamic> kpis;
  final bool aiGenerated;
  final bool fromCache;

  const PrincipalDigest({
    required this.narrative,
    required this.weekStart,
    required this.kpis,
    required this.aiGenerated,
    required this.fromCache,
  });

  int? get attendancePct => _intOrNull('attendance_pct');
  int? get attendanceDeltaPct => _intOrNull('attendance_delta_pct');
  int? get feePct => _intOrNull('fee_pct');
  int? get feeDeltaPct => _intOrNull('fee_delta_pct');
  int? get incidentsCount => _intOrNull('incidents_count');
  int? get incidentsDelta => _intOrNull('incidents_delta');
  int? get escalatingCount => _intOrNull('escalating_count');
  int? get atRiskCount => _intOrNull('at_risk_count');

  int? _intOrNull(String key) {
    final v = kpis[key];
    if (v is num) return v.toInt();
    return null;
  }
}

class PrincipalDigestArgs {
  final String tenantId;
  final String schoolName;
  const PrincipalDigestArgs({
    required this.tenantId,
    required this.schoolName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrincipalDigestArgs &&
          other.tenantId == tenantId &&
          other.schoolName == schoolName;

  @override
  int get hashCode => Object.hash(tenantId, schoolName);
}

DateTime _currentWeekStart() {
  final now = DateTime.now();
  // Monday as week start.
  final monday = now.subtract(Duration(days: now.weekday - DateTime.monday));
  return DateTime(monday.year, monday.month, monday.day);
}

String _isoDate(DateTime d) => d.toIso8601String().substring(0, 10);

// ---------------------------------------------------------------------------
// Cache-first load with on-demand generation
// ---------------------------------------------------------------------------

Future<PrincipalDigest> _loadOrGenerate(
  Ref ref,
  PrincipalDigestArgs args,
) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final weekStart = _currentWeekStart();
  final weekIso = _isoDate(weekStart);

  // 1. Cache lookup
  final cached = await client
      .from('principal_digests')
      .select()
      .eq('tenant_id', args.tenantId)
      .eq('week_start', weekIso)
      .maybeSingle();

  if (cached != null) {
    return PrincipalDigest(
      narrative: cached['narrative'] as String,
      weekStart: DateTime.parse(cached['week_start'] as String),
      kpis: Map<String, dynamic>.from(cached['kpis'] as Map? ?? {}),
      aiGenerated: (cached['ai_generated'] as bool?) ?? true,
      fromCache: true,
    );
  }

  // 2. Pull KPIs (best effort — any failure falls back to nulls/zeros).
  final kpis = await _gatherKpis(client, args.tenantId);

  // 3. Ask the gateway for a fresh narrative.
  final gen = ref.watch(aiTextGeneratorProvider);
  final result = await gen.generatePrincipalDigest(
    schoolName: args.schoolName,
    weekStartDate: weekIso,
    attendancePercent: (kpis['attendance_pct'] as num?)?.toInt() ?? 0,
    attendanceDeltaPct: (kpis['attendance_delta_pct'] as num?)?.toInt() ?? 0,
    feeCollectionPercent: (kpis['fee_pct'] as num?)?.toInt() ?? 0,
    feeCollectionDeltaPct: (kpis['fee_delta_pct'] as num?)?.toInt() ?? 0,
    incidentsThisWeek: (kpis['incidents_count'] as num?)?.toInt() ?? 0,
    incidentsDeltaCount: (kpis['incidents_delta'] as num?)?.toInt() ?? 0,
    escalatingStudents: (kpis['escalating_count'] as num?)?.toInt() ?? 0,
    atRiskStudents: (kpis['at_risk_count'] as num?)?.toInt() ?? 0,
    fallback: 'This week\'s automated digest is unavailable. '
        'Use the dashboard tiles to review attendance, fee collection, and '
        'recent incidents directly. Recommended action: review the '
        '"Escalating students" tile for any students flagged this fortnight.',
  );

  // 4. Persist via RPC (server enforces tenant + admin role).
  try {
    await client.rpc('upsert_principal_digest', params: {
      'p_week_start': weekIso,
      'p_narrative': result.text,
      'p_kpis': kpis,
      'p_ai_provider': null,
      'p_ai_generated': result.isLLMGenerated,
    });
  } catch (_) {
    // Persistence failure is non-fatal — caller still sees the narrative.
  }

  return PrincipalDigest(
    narrative: result.text,
    weekStart: weekStart,
    kpis: kpis,
    aiGenerated: result.isLLMGenerated,
    fromCache: false,
  );
}

// ---------------------------------------------------------------------------
// KPI gathering — best effort, all failures swallow to 0/null
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _gatherKpis(
  SupabaseClient client,
  String tenantId,
) async {
  final kpis = <String, dynamic>{};

  // Attendance percent (this week vs prior week)
  try {
    final today = DateTime.now();
    final thisWeekStart =
        today.subtract(Duration(days: today.weekday - DateTime.monday));
    final priorWeekStart =
        thisWeekStart.subtract(const Duration(days: 7));
    final att = await client
        .from('attendance')
        .select('status, date')
        .eq('tenant_id', tenantId)
        .gte('date', _isoDate(priorWeekStart));
    int thisP = 0, thisT = 0, priorP = 0, priorT = 0;
    for (final r in att.whereType<Map>()) {
      final dStr = r['date'] as String?;
      final s = r['status'] as String?;
      if (dStr == null) continue;
      final d = DateTime.tryParse(dStr);
      if (d == null) continue;
      final inThis = !d.isBefore(thisWeekStart);
      final present = s == 'present' || s == 'late';
      if (inThis) {
        thisT++;
        if (present) thisP++;
      } else {
        priorT++;
        if (present) priorP++;
      }
    }
    final thisPct = thisT > 0 ? (thisP * 100 / thisT).round() : 0;
    final priorPct = priorT > 0 ? (priorP * 100 / priorT).round() : 0;
    kpis['attendance_pct'] = thisPct;
    kpis['attendance_delta_pct'] = thisPct - priorPct;
  } catch (_) {}

  // Discipline incidents (this week vs prior week)
  try {
    final today = DateTime.now();
    final thisWeekStart =
        today.subtract(Duration(days: today.weekday - DateTime.monday));
    final priorWeekStart =
        thisWeekStart.subtract(const Duration(days: 7));
    final inc = await client
        .from('behavior_incidents')
        .select('incident_date')
        .eq('tenant_id', tenantId)
        .gte('incident_date', _isoDate(priorWeekStart));
    int thisN = 0, priorN = 0;
    for (final r in inc.whereType<Map>()) {
      final d = DateTime.tryParse(r['incident_date'] as String? ?? '');
      if (d == null) continue;
      if (!d.isBefore(thisWeekStart)) {
        thisN++;
      } else {
        priorN++;
      }
    }
    kpis['incidents_count'] = thisN;
    kpis['incidents_delta'] = thisN - priorN;
  } catch (_) {}

  // Escalating students (reuses Sprint 1.4 RPC)
  try {
    final rows = await client.rpc('compute_behavior_escalation', params: {
      'p_tenant_id': tenantId,
      'p_section_id': null,
      'p_limit': 50,
    });
    if (rows is List) kpis['escalating_count'] = rows.length;
  } catch (_) {}

  // At-risk students (from existing risk score table)
  try {
    final risk = await client
        .from('student_risk_scores')
        .select('id')
        .eq('tenant_id', tenantId)
        .inFilter('risk_level', ['high', 'critical']);
    kpis['at_risk_count'] = risk.length;
  } catch (_) {}

  return kpis;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final principalDigestProvider = FutureProvider.autoDispose
    .family<PrincipalDigest, PrincipalDigestArgs>(
        (ref, args) => _loadOrGenerate(ref, args));
