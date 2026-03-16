import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/services/ai_text_generator.dart';

/// Provides an AI-generated route insight for the transport manager.
final transportInsightProvider =
    FutureProvider.family<AITextResult, TransportInsightInput>(
        (ref, input) async {
  final aiStaff = ref.watch(aiStaffTextGeneratorProvider);

  final fallback = '${input.activeRoutes} active route${input.activeRoutes == 1 ? '' : 's'} '
      'with ${input.totalVehicles} vehicles at ${input.capacityPercent.round()}% capacity. '
      'Monitor trip schedules to ensure on-time arrivals.';

  try {
    return await aiStaff.generateRouteInsight(
      activeRoutes: input.activeRoutes,
      capacityPercent: input.capacityPercent,
      totalVehicles: input.totalVehicles,
      activeTrips: input.activeTrips,
      fallback: fallback,
    );
  } catch (_) {
    return AITextResult(text: fallback);
  }
});

class TransportInsightInput {
  final int activeRoutes;
  final double capacityPercent;
  final int totalVehicles;
  final int activeTrips;

  const TransportInsightInput({
    required this.activeRoutes,
    required this.capacityPercent,
    required this.totalVehicles,
    required this.activeTrips,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransportInsightInput &&
          activeRoutes == other.activeRoutes &&
          totalVehicles == other.totalVehicles;

  @override
  int get hashCode => Object.hash(activeRoutes, totalVehicles);
}
