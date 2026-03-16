import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/services/ai_text_generator.dart';

/// Provides an AI-generated hostel insight for the hostel warden.
final hostelInsightProvider =
    FutureProvider.family<AITextResult, HostelInsightInput>(
        (ref, input) async {
  final aiStaff = ref.watch(aiStaffTextGeneratorProvider);

  final fallback = 'Hostel occupancy is at ${input.occupancyPercent.round()}% '
      'with ${input.availableBeds} bed${input.availableBeds == 1 ? '' : 's'} available. '
      '${input.maintenanceRequests > 0 ? '${input.maintenanceRequests} maintenance request${input.maintenanceRequests == 1 ? '' : 's'} pending.' : 'No pending maintenance requests.'}';

  try {
    return await aiStaff.generateHostelInsight(
      occupancyPercent: input.occupancyPercent,
      availableBeds: input.availableBeds,
      maintenanceRequests: input.maintenanceRequests,
      totalHostels: input.totalHostels,
      fallback: fallback,
    );
  } catch (_) {
    return AITextResult(text: fallback);
  }
});

class HostelInsightInput {
  final double occupancyPercent;
  final int availableBeds;
  final int maintenanceRequests;
  final int totalHostels;

  const HostelInsightInput({
    required this.occupancyPercent,
    required this.availableBeds,
    required this.maintenanceRequests,
    required this.totalHostels,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostelInsightInput &&
          occupancyPercent == other.occupancyPercent &&
          availableBeds == other.availableBeds;

  @override
  int get hashCode => Object.hash(occupancyPercent, availableBeds);
}
