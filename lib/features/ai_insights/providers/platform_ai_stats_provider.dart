import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/services/ai_text_generator.dart';

/// Provides an AI-generated platform health narrative for super admin.
///
/// Uses tenant and user counts to generate a platform-wide summary.
/// Falls back to a template when LLM is unavailable.
final platformHealthNarrativeProvider =
    FutureProvider.family<AITextResult, PlatformStats>((ref, stats) async {
  final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

  final fallback = 'The platform serves ${stats.tenantCount} active '
      'tenant${stats.tenantCount == 1 ? '' : 's'} with '
      '${stats.totalStudents} total students. '
      '${stats.activePercent.round()}% of users are active this month.';

  try {
    return await aiTextGenerator.generatePlatformHealthNarrative(
      tenantCount: stats.tenantCount,
      totalStudents: stats.totalStudents,
      activePercent: stats.activePercent,
      monthlyRevenue: stats.monthlyRevenue,
      fallback: fallback,
    );
  } catch (_) {
    return AITextResult(text: fallback);
  }
});

class PlatformStats {
  final int tenantCount;
  final int totalStudents;
  final double activePercent;
  final double monthlyRevenue;

  const PlatformStats({
    required this.tenantCount,
    required this.totalStudents,
    required this.activePercent,
    required this.monthlyRevenue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformStats &&
          tenantCount == other.tenantCount &&
          totalStudents == other.totalStudents;

  @override
  int get hashCode => Object.hash(tenantCount, totalStudents);
}
