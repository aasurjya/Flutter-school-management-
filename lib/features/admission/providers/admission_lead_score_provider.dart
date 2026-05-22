import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';

/// Sprint 2.1 — 0-100 lead score from the `compute_admission_lead_score` RPC.
///
/// Pure SQL heuristic; no LLM cost. The RPC also UPDATEs the inquiry's cached
/// lead_score / lead_score_reasons / lead_score_computed_at columns so the
/// next render can skip the recompute when stale tolerance allows.
class LeadScore {
  final int score;
  final List<String> reasons;

  const LeadScore({required this.score, required this.reasons});

  /// HOT (80+), WARM (50-79), COLD (<50). The bands are the same ones the
  /// LeadScoreBadge color-codes against.
  String get band {
    if (score >= 80) return 'HOT';
    if (score >= 50) return 'WARM';
    return 'COLD';
  }
}

final leadScoreProvider =
    FutureProvider.autoDispose.family<LeadScore, String>((ref, inquiryId) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final rows = await client.rpc(
    'compute_admission_lead_score',
    params: {'p_inquiry_id': inquiryId},
  );

  if (rows is! List || rows.isEmpty) {
    return const LeadScore(score: 0, reasons: []);
  }

  final row = (rows.first as Map).cast<String, dynamic>();
  final score = (row['score'] as num?)?.toInt() ?? 0;
  final reasons = (row['reasons'] as List?)
          ?.whereType<String>()
          .toList(growable: false) ??
      const <String>[];
  return LeadScore(score: score, reasons: reasons);
});
