import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/services/ai_text_generator.dart';

/// Provides an AI-generated fee collection insight for the accountant.
final feeInsightProvider =
    FutureProvider.family<AITextResult, FeeInsightInput>((ref, input) async {
  final aiStaff = ref.watch(aiStaffTextGeneratorProvider);

  final rate = input.totalBilled > 0
      ? (input.totalCollected / input.totalBilled * 100)
      : 0.0;

  final fallback = '${input.overdueCount} invoice${input.overdueCount == 1 ? ' is' : 's are'} '
      'overdue with a collection rate of ${rate.round()}%. '
      'Follow up on overdue accounts to improve cash flow.';

  try {
    return await aiStaff.generateFeeCollectionInsight(
      overdueCount: input.overdueCount,
      collectionRate: rate,
      totalBilled: input.totalBilled,
      totalCollected: input.totalCollected,
      fallback: fallback,
    );
  } catch (_) {
    return AITextResult(text: fallback);
  }
});

class FeeInsightInput {
  final int overdueCount;
  final double totalBilled;
  final double totalCollected;

  const FeeInsightInput({
    required this.overdueCount,
    required this.totalBilled,
    required this.totalCollected,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeInsightInput &&
          overdueCount == other.overdueCount &&
          totalBilled == other.totalBilled;

  @override
  int get hashCode => Object.hash(overdueCount, totalBilled);
}
