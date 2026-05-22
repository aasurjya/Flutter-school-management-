import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';

/// Sprint 2.4 — providers for the super-admin AI cost dashboard.

class AiUsageOverview {
  final int tenantsWithActivity;
  final int callsMtd;
  final double costMtdUsd;
  final double projectedMonthUsd;
  final double costLastMonthUsd;
  final int blockedCallsMtd;
  final int cacheHitsMtd;
  final String? mostExpensiveFeature;
  final String? mostExpensiveProvider;

  const AiUsageOverview({
    required this.tenantsWithActivity,
    required this.callsMtd,
    required this.costMtdUsd,
    required this.projectedMonthUsd,
    required this.costLastMonthUsd,
    required this.blockedCallsMtd,
    required this.cacheHitsMtd,
    required this.mostExpensiveFeature,
    required this.mostExpensiveProvider,
  });

  factory AiUsageOverview.fromJson(Map<String, dynamic> j) =>
      AiUsageOverview(
        tenantsWithActivity: (j['tenants_with_activity'] as num?)?.toInt() ?? 0,
        callsMtd: (j['calls_mtd'] as num?)?.toInt() ?? 0,
        costMtdUsd: (j['cost_mtd_usd'] as num?)?.toDouble() ?? 0,
        projectedMonthUsd: (j['projected_month_usd'] as num?)?.toDouble() ?? 0,
        costLastMonthUsd:
            (j['cost_last_month_usd'] as num?)?.toDouble() ?? 0,
        blockedCallsMtd: (j['blocked_calls_mtd'] as num?)?.toInt() ?? 0,
        cacheHitsMtd: (j['cache_hits_mtd'] as num?)?.toInt() ?? 0,
        mostExpensiveFeature: j['most_expensive_feature'] as String?,
        mostExpensiveProvider: j['most_expensive_provider'] as String?,
      );
}

class AiUsageTenantRow {
  final String tenantId;
  final String tenantName;
  final String? tier;
  final double budgetUsd;
  final double usedUsdPeriod;
  final int callsPeriod;
  final int blockedPeriod;
  final double usedPctOfBudget;
  final DateTime? lastCallAt;

  const AiUsageTenantRow({
    required this.tenantId,
    required this.tenantName,
    required this.tier,
    required this.budgetUsd,
    required this.usedUsdPeriod,
    required this.callsPeriod,
    required this.blockedPeriod,
    required this.usedPctOfBudget,
    required this.lastCallAt,
  });

  factory AiUsageTenantRow.fromJson(Map<String, dynamic> j) =>
      AiUsageTenantRow(
        tenantId: j['tenant_id'] as String,
        tenantName: (j['tenant_name'] as String?) ?? '—',
        tier: j['tier'] as String?,
        budgetUsd: (j['budget_usd'] as num?)?.toDouble() ?? 0,
        usedUsdPeriod: (j['used_usd_period'] as num?)?.toDouble() ?? 0,
        callsPeriod: (j['calls_period'] as num?)?.toInt() ?? 0,
        blockedPeriod: (j['blocked_period'] as num?)?.toInt() ?? 0,
        usedPctOfBudget: (j['used_pct_of_budget'] as num?)?.toDouble() ?? 0,
        lastCallAt: (j['last_call_at'] as String?) != null
            ? DateTime.tryParse(j['last_call_at'] as String)
            : null,
      );
}

class AiUsageFeatureRow {
  final String featureType;
  final int calls;
  final int tokensIn;
  final int tokensOut;
  final double costUsd;
  final double avgCostPerCall;
  final int cacheHits;
  final int errors;

  const AiUsageFeatureRow({
    required this.featureType,
    required this.calls,
    required this.tokensIn,
    required this.tokensOut,
    required this.costUsd,
    required this.avgCostPerCall,
    required this.cacheHits,
    required this.errors,
  });

  factory AiUsageFeatureRow.fromJson(Map<String, dynamic> j) =>
      AiUsageFeatureRow(
        featureType: j['feature_type'] as String,
        calls: (j['calls'] as num?)?.toInt() ?? 0,
        tokensIn: (j['tokens_in'] as num?)?.toInt() ?? 0,
        tokensOut: (j['tokens_out'] as num?)?.toInt() ?? 0,
        costUsd: (j['cost_usd'] as num?)?.toDouble() ?? 0,
        avgCostPerCall: (j['avg_cost_per_call'] as num?)?.toDouble() ?? 0,
        cacheHits: (j['cache_hits'] as num?)?.toInt() ?? 0,
        errors: (j['errors'] as num?)?.toInt() ?? 0,
      );
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final aiUsageOverviewProvider =
    FutureProvider.autoDispose<AiUsageOverview>((ref) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final rows = await client.rpc('get_ai_usage_overview');
  if (rows is! List || rows.isEmpty) {
    return const AiUsageOverview(
      tenantsWithActivity: 0,
      callsMtd: 0,
      costMtdUsd: 0,
      projectedMonthUsd: 0,
      costLastMonthUsd: 0,
      blockedCallsMtd: 0,
      cacheHitsMtd: 0,
      mostExpensiveFeature: null,
      mostExpensiveProvider: null,
    );
  }
  return AiUsageOverview.fromJson(
      (rows.first as Map).cast<String, dynamic>());
});

final aiUsageByTenantProvider =
    FutureProvider.autoDispose.family<List<AiUsageTenantRow>, int>(
        (ref, days) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final rows =
      await client.rpc('get_ai_usage_by_tenant', params: {'p_days': days});
  if (rows is! List) return const [];
  return rows
      .whereType<Map>()
      .map((r) => AiUsageTenantRow.fromJson(r.cast<String, dynamic>()))
      .toList(growable: false);
});

final aiUsageByFeatureProvider =
    FutureProvider.autoDispose.family<List<AiUsageFeatureRow>, int>(
        (ref, days) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final rows =
      await client.rpc('get_ai_usage_by_feature', params: {'p_days': days});
  if (rows is! List) return const [];
  return rows
      .whereType<Map>()
      .map((r) => AiUsageFeatureRow.fromJson(r.cast<String, dynamic>()))
      .toList(growable: false);
});
