import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';

/// One server-side feature flag.
class FeatureFlag {
  final String key;
  final bool enabled;
  final int rolloutPercent; // 0..100
  final Map<String, dynamic> payload;
  final List<String> audience; // tenant id allowlist; empty = no restriction

  const FeatureFlag({
    required this.key,
    required this.enabled,
    required this.rolloutPercent,
    required this.payload,
    required this.audience,
  });

  static const FeatureFlag off = FeatureFlag(
    key: '',
    enabled: false,
    rolloutPercent: 0,
    payload: {},
    audience: [],
  );

  factory FeatureFlag.fromJson(Map<String, dynamic> j) => FeatureFlag(
        key: j['key'] as String,
        enabled: j['enabled'] as bool? ?? false,
        rolloutPercent: (j['rollout_percent'] as num?)?.toInt() ?? 0,
        payload: (j['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        audience: ((j['audience'] as List?) ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );

  /// Returns true iff this flag is on for [tenantId]. Applies audience >
  /// rollout_percent (stable per tenant).
  bool isOnFor(String? tenantId) {
    if (!enabled) return false;
    if (audience.isNotEmpty) {
      return tenantId != null && audience.contains(tenantId);
    }
    if (rolloutPercent >= 100) return true;
    if (rolloutPercent <= 0) return false;
    if (tenantId == null) return false;
    // Stable bucket — mirrors the SQL `resolve_feature_flag` function.
    final bucket = _stableBucket('$tenantId:$key');
    return bucket < rolloutPercent;
  }
}

int _stableBucket(String s) {
  // Java/Postgres-compatible hashCode, then mod 100. Matches the spirit of
  // SQL `hashtext(...)` closely enough for our bucketing — the server-side
  // RPC `resolve_feature_flag` is the authoritative bucket if it matters.
  var h = 0;
  for (final code in utf8.encode(s)) {
    h = (h * 31 + code) & 0xFFFFFFFF;
  }
  return h.abs() % 100;
}

/// Snapshot of every flag fetched on app boot. Keyed by `key`.
class FeatureFlagsSnapshot {
  final Map<String, FeatureFlag> flags;
  final DateTime fetchedAt;

  const FeatureFlagsSnapshot({required this.flags, required this.fetchedAt});

  FeatureFlag get(String key) => flags[key] ?? FeatureFlag.off;
}

/// Fetches the full flag table on app boot. Returns an empty snapshot if the
/// table is unreachable / missing — feature checks then default to off.
final featureFlagsProvider =
    FutureProvider<FeatureFlagsSnapshot>((ref) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  try {
    final rows = await client
        .from('feature_flags')
        .select('key, enabled, rollout_percent, payload, audience')
        .timeout(const Duration(seconds: 3));
    final list = (rows as List).cast<Map<String, dynamic>>();
    final byKey = {
      for (final r in list) (r['key'] as String): FeatureFlag.fromJson(r),
    };
    return FeatureFlagsSnapshot(flags: byKey, fetchedAt: DateTime.now());
  } catch (e) {
    developer.log(
      'feature_flags boot fetch failed — defaulting all flags off',
      name: 'FeatureFlags',
      error: e,
    );
    return FeatureFlagsSnapshot(flags: const {}, fetchedAt: DateTime.now());
  }
});

/// Quick accessor: `ref.watch(flagProvider(('ai_streaming', tenantId)))`.
///
/// Family key is `(flagKey, tenantId)` because the resolved state depends on
/// both. Returns `false` while the snapshot is loading — features must
/// default to off, never on, until the server confirms.
final flagProvider = Provider.family<bool, (String key, String? tenantId)>(
  (ref, args) {
    final (key, tenantId) = args;
    final snap = ref.watch(featureFlagsProvider).valueOrNull;
    if (snap == null) return false;
    return snap.get(key).isOnFor(tenantId);
  },
);
