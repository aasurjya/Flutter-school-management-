import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';

/// Sprint P0.3 — tenant-self AI usage view (the admin-dashboard card).
/// Backed by `get_my_tenant_ai_usage()` SQL function (migration 00060).
class TenantAiUsage {
  final String tenantId;
  final String? tier;
  final double budgetUsd;
  final double usedUsdMtd;
  final int callsMtd;
  final int blockedMtd;
  final int cacheHitsMtd;
  final double usedPctOfBudget;
  final DateTime? lastCallAt;

  const TenantAiUsage({
    required this.tenantId,
    required this.tier,
    required this.budgetUsd,
    required this.usedUsdMtd,
    required this.callsMtd,
    required this.blockedMtd,
    required this.cacheHitsMtd,
    required this.usedPctOfBudget,
    required this.lastCallAt,
  });

  bool get hasBudget => budgetUsd > 0;
  bool get overBudget => hasBudget && usedPctOfBudget >= 100;
  bool get nearBudget => hasBudget && usedPctOfBudget >= 80;

  factory TenantAiUsage.fromJson(Map<String, dynamic> j) {
    return TenantAiUsage(
      tenantId: j['tenant_id'] as String,
      tier: j['tier'] as String?,
      budgetUsd: (j['budget_usd'] as num?)?.toDouble() ?? 0,
      usedUsdMtd: (j['used_usd_mtd'] as num?)?.toDouble() ?? 0,
      callsMtd: (j['calls_mtd'] as num?)?.toInt() ?? 0,
      blockedMtd: (j['blocked_mtd'] as num?)?.toInt() ?? 0,
      cacheHitsMtd: (j['cache_hits_mtd'] as num?)?.toInt() ?? 0,
      usedPctOfBudget: (j['used_pct_of_budget'] as num?)?.toDouble() ?? 0,
      lastCallAt: j['last_call_at'] == null
          ? null
          : DateTime.tryParse(j['last_call_at'] as String),
    );
  }
}

/// Returns null when the caller has no tenant context (e.g. super_admin),
/// or when the RPC has not been deployed yet (graceful migration window).
final tenantAiUsageProvider =
    FutureProvider.autoDispose<TenantAiUsage?>((ref) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  try {
    final res = await client.rpc('get_my_tenant_ai_usage');
    if (res is! List || res.isEmpty) return null;
    return TenantAiUsage.fromJson((res.first as Map).cast<String, dynamic>());
  } on PostgrestException catch (e) {
    // `no_tenant_in_jwt` (super_admin) → show nothing.
    // Missing function (migration not deployed yet) → show nothing.
    if (e.message.contains('no_tenant_in_jwt') ||
        e.code == 'PGRST202' ||
        e.code == '42883') {
      return null;
    }
    rethrow;
  }
});
