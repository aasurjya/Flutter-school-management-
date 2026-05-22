import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';

// ---------------------------------------------------------------------------
// Models — kept small and local; no Freezed dependency required for this UI
// ---------------------------------------------------------------------------

class TenantAiCredits {
  final String tenantId;
  final String tier;
  final DateTime cycleStart;
  final double budgetUsd;
  final double usedUsd;
  final int callsUsed;
  final int callsLimit;
  final int softCapPct;
  final int hardCapPct;
  final int burstPerMin;
  final DateTime? warnSentAt;
  final DateTime? blockedAt;
  final double lastCycleUsedUsd;
  final int lastCycleCalls;

  TenantAiCredits({
    required this.tenantId,
    required this.tier,
    required this.cycleStart,
    required this.budgetUsd,
    required this.usedUsd,
    required this.callsUsed,
    required this.callsLimit,
    required this.softCapPct,
    required this.hardCapPct,
    required this.burstPerMin,
    required this.warnSentAt,
    required this.blockedAt,
    required this.lastCycleUsedUsd,
    required this.lastCycleCalls,
  });

  factory TenantAiCredits.fromJson(Map<String, dynamic> json) {
    return TenantAiCredits(
      tenantId: json['tenant_id'] as String,
      tier: json['tier'] as String,
      cycleStart: DateTime.parse(json['cycle_start'] as String),
      budgetUsd: (json['budget_usd'] as num).toDouble(),
      usedUsd: (json['used_usd'] as num).toDouble(),
      callsUsed: json['calls_used'] as int,
      callsLimit: json['calls_limit'] as int,
      softCapPct: json['soft_cap_pct'] as int,
      hardCapPct: json['hard_cap_pct'] as int,
      burstPerMin: json['burst_per_min'] as int,
      warnSentAt: json['warn_sent_at'] != null
          ? DateTime.parse(json['warn_sent_at'] as String)
          : null,
      blockedAt: json['blocked_at'] != null
          ? DateTime.parse(json['blocked_at'] as String)
          : null,
      lastCycleUsedUsd: (json['last_cycle_used_usd'] as num).toDouble(),
      lastCycleCalls: json['last_cycle_calls'] as int,
    );
  }

  double get usedPct => budgetUsd > 0 ? usedUsd / budgetUsd : 0;
}

class TenantAiFeatureSetting {
  final String tenantId;
  final String featureType;
  final bool enabled;
  final String preferredProvider;
  final int maxTokensOut;
  final double maxCostPerCallUsd;
  final int cacheTtlSeconds;

  TenantAiFeatureSetting({
    required this.tenantId,
    required this.featureType,
    required this.enabled,
    required this.preferredProvider,
    required this.maxTokensOut,
    required this.maxCostPerCallUsd,
    required this.cacheTtlSeconds,
  });

  factory TenantAiFeatureSetting.fromJson(Map<String, dynamic> json) {
    return TenantAiFeatureSetting(
      tenantId: json['tenant_id'] as String,
      featureType: json['feature_type'] as String,
      enabled: json['enabled'] as bool,
      preferredProvider: json['preferred_provider'] as String,
      maxTokensOut: json['max_tokens_out'] as int,
      maxCostPerCallUsd: (json['max_cost_per_call_usd'] as num).toDouble(),
      cacheTtlSeconds: json['cache_ttl_seconds'] as int,
    );
  }
}

/// Catalogue of every feature the gateway knows about. Keep in sync with
/// FEATURE_ROUTES in supabase/functions/ai-gateway/index.ts.
const kAiFeatureCatalogue = <String, String>{
  'parent_digest':        'Parent weekly digest',
  'report_card_remark':   'Report card remarks',
  'parent_message':       'Parent message drafts',
  'lesson_plan_json':     'Lesson plan generator',
  'question_paper_json':  'Question paper generator',
  'syllabus_structure':   'Syllabus structure generator',
  'risk_explanation':     'Student risk explanations',
  'fee_reminder':         'Fee reminder messages',
  'attendance_narrative': 'Attendance narratives',
  'early_warning_alert':  'Early warning alerts',
  'class_performance':    'Class performance narratives',
  'study_recommendation': 'Study recommendations',
  'trend_narrative':      'Trend narratives',
  'school_health':        'School health summary',
  'platform_health':      'Platform health summary',
  'admissions_chatbot':   'Admissions chatbot (Phase 2)',
  'ai_tutor':             'AI tutor (metered add-on)',
  'ptm_brief':            'Pre-PTM brief',
  'principal_digest':     'Principal weekly digest',
};

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class TenantAiSettingsRepository {
  final SupabaseClient _client;
  TenantAiSettingsRepository(this._client);

  Future<TenantAiCredits?> getCredits(String tenantId) async {
    final row = await _client
        .from('tenant_ai_credits')
        .select()
        .eq('tenant_id', tenantId)
        .maybeSingle();
    if (row == null) return null;
    return TenantAiCredits.fromJson(row);
  }

  Future<List<TenantAiFeatureSetting>> getSettings(String tenantId) async {
    final rows = await _client
        .from('tenant_ai_settings')
        .select()
        .eq('tenant_id', tenantId);
    return (rows as List)
        .map((r) => TenantAiFeatureSetting.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertSetting({
    required String tenantId,
    required String featureType,
    required bool enabled,
    String preferredProvider = 'auto',
    int maxTokensOut = 1024,
    double maxCostPerCallUsd = 0.05,
    int cacheTtlSeconds = 3600,
  }) async {
    await _client.from('tenant_ai_settings').upsert({
      'tenant_id': tenantId,
      'feature_type': featureType,
      'enabled': enabled,
      'preferred_provider': preferredProvider,
      'max_tokens_out': maxTokensOut,
      'max_cost_per_call_usd': maxCostPerCallUsd,
      'cache_ttl_seconds': cacheTtlSeconds,
    }, onConflict: 'tenant_id,feature_type');
  }

  Future<void> updateCredits({
    required String tenantId,
    String? tier,
    double? budgetUsd,
    int? callsLimit,
    int? hardCapPct,
    int? softCapPct,
  }) async {
    final patch = <String, dynamic>{};
    if (tier != null) patch['tier'] = tier;
    if (budgetUsd != null) patch['budget_usd'] = budgetUsd;
    if (callsLimit != null) patch['calls_limit'] = callsLimit;
    if (hardCapPct != null) patch['hard_cap_pct'] = hardCapPct;
    if (softCapPct != null) patch['soft_cap_pct'] = softCapPct;
    if (patch.isEmpty) return;
    await _client.from('tenant_ai_credits').update(patch).eq('tenant_id', tenantId);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final tenantAiSettingsRepositoryProvider =
    Provider<TenantAiSettingsRepository>((ref) {
  return TenantAiSettingsRepository(ref.watch(supabaseProvider));
});

final tenantAiCreditsProvider =
    FutureProvider.autoDispose.family<TenantAiCredits?, String>(
        (ref, tenantId) {
  return ref.watch(tenantAiSettingsRepositoryProvider).getCredits(tenantId);
});

final tenantAiSettingsProvider = FutureProvider.autoDispose
    .family<List<TenantAiFeatureSetting>, String>((ref, tenantId) {
  return ref.watch(tenantAiSettingsRepositoryProvider).getSettings(tenantId);
});
