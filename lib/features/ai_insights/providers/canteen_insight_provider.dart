import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/services/ai_text_generator.dart';

/// Provides an AI-generated canteen insight for canteen staff.
///
/// Uses the fee collection insight generator repurposed for canteen revenue,
/// since canteen has similar financial metrics (orders = invoices).
final canteenInsightProvider =
    FutureProvider.family<AITextResult, CanteenInsightInput>(
        (ref, input) async {
  final aiStaff = ref.watch(aiStaffTextGeneratorProvider);

  final fallback = '${input.pendingOrders} order${input.pendingOrders == 1 ? '' : 's'} '
      'pending with ${input.fulfilledToday} fulfilled today. '
      '${input.revenueToday > 0 ? 'Revenue so far: \u20B9${input.revenueToday.toStringAsFixed(0)}.' : 'Track daily orders to optimize menu planning.'}';

  // Reuse fee insight generator for canteen revenue metrics.
  try {
    return await aiStaff.generateFeeCollectionInsight(
      overdueCount: input.pendingOrders,
      collectionRate: input.fulfilledToday > 0 && input.totalOrders > 0
          ? (input.fulfilledToday / input.totalOrders * 100)
          : 0,
      totalBilled: input.revenueToday,
      totalCollected: input.revenueToday,
      fallback: fallback,
    );
  } catch (_) {
    return AITextResult(text: fallback);
  }
});

class CanteenInsightInput {
  final int pendingOrders;
  final int fulfilledToday;
  final int totalOrders;
  final double revenueToday;

  const CanteenInsightInput({
    required this.pendingOrders,
    required this.fulfilledToday,
    required this.totalOrders,
    required this.revenueToday,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanteenInsightInput &&
          pendingOrders == other.pendingOrders &&
          fulfilledToday == other.fulfilledToday;

  @override
  int get hashCode => Object.hash(pendingOrders, fulfilledToday);
}
