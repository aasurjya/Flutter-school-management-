import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/services/ai_text_generator.dart';
import '../../attendance/providers/attendance_provider.dart';

/// Provides an AI-generated school health narrative for the admin dashboard.
///
/// Fetches today's attendance percentage and uses the AI context builder
/// to enrich with real school data (student count, fee collection rate, etc.)
/// instead of hardcoded placeholder zeroes.
final schoolHealthNarrativeProvider = FutureProvider<AITextResult>((ref) async {
  final aiTextGenerator = ref.watch(aiTextGeneratorProvider);
  final contextBuilder = ref.watch(aiContextBuilderProvider);

  // Fetch today's attendance.
  double attendancePercent = 0;
  try {
    attendancePercent =
        await ref.watch(todayAttendancePercentageProvider.future);
  } catch (_) {}

  // Use context builder to get real school data.
  final client = Supabase.instance.client;
  final appMetadata = client.auth.currentUser?.appMetadata;
  final tenantId = appMetadata?['tenant_id'] as String?;
  final userId = client.auth.currentUser?.id;
  final userRole = appMetadata?['role'] as String? ?? 'tenant_admin';

  final context = await contextBuilder.build(
    role: userRole,
    tenantId: tenantId,
    userId: userId,
  );

  // Extract enriched data with fallback to defaults.
  final totalStudents = context.schoolData['total_students'] as int? ?? 0;

  // Fetch fee collection rate if available.
  var feeCollectionRate = 0.0;
  final riskDistribution = <String, int>{};

  if (tenantId != null) {
    try {
      final feeStats = await client.rpc('get_fee_collection_stats', params: {
        'p_tenant_id': tenantId,
      }).maybeSingle();
      if (feeStats != null) {
        final billed = (feeStats['total_billed'] as num?)?.toDouble() ?? 0;
        final collected = (feeStats['total_collected'] as num?)?.toDouble() ?? 0;
        feeCollectionRate = billed > 0 ? (collected / billed * 100) : 0;
      }
    } catch (_) {
      // RPC may not exist — use fallback.
    }

    try {
      final riskResult = await client
          .from('student_risk_scores')
          .select('risk_level')
          .eq('tenant_id', tenantId);
      for (final row in (riskResult as List)) {
        final level = (row as Map<String, dynamic>)['risk_level'] as String? ?? 'low';
        riskDistribution[level] = (riskDistribution[level] ?? 0) + 1;
      }
    } catch (_) {
      // Table may not have data yet.
    }
  }

  final fallback = 'Today\'s school attendance is '
      '${attendancePercent > 0 ? '${attendancePercent.round()}%' : 'not yet recorded'}. '
      '${totalStudents > 0 ? 'The school has $totalStudents students enrolled. ' : ''}'
      'Monitor fee collections and at-risk students throughout the day for '
      'a complete picture of school health.';

  try {
    return await aiTextGenerator.generateSchoolHealthNarrative(
      attendancePercent: attendancePercent,
      feeCollectionRate: feeCollectionRate,
      riskDistribution: riskDistribution,
      totalStudents: totalStudents,
      fallback: fallback,
    );
  } catch (_) {
    return AITextResult(text: fallback);
  }
});
