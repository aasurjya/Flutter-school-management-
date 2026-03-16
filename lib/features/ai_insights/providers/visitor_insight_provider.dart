import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/services/ai_text_generator.dart';

/// Provides an AI-generated visitor insight for the receptionist.
final visitorInsightProvider =
    FutureProvider.family<AITextResult, VisitorInsightInput>(
        (ref, input) async {
  final aiStaff = ref.watch(aiStaffTextGeneratorProvider);

  final fallback = '${input.dailyVisitorCount} visitor${input.dailyVisitorCount == 1 ? '' : 's'} '
      'today with ${input.onPremises} currently on premises. '
      '${input.preRegistrations > 0 ? '${input.preRegistrations} pre-registered for today.' : 'Encourage visitors to pre-register for faster check-in.'}';

  try {
    return await aiStaff.generateVisitorInsight(
      dailyVisitorCount: input.dailyVisitorCount,
      onPremises: input.onPremises,
      preRegistrations: input.preRegistrations,
      checkedOut: input.checkedOut,
      fallback: fallback,
    );
  } catch (_) {
    return AITextResult(text: fallback);
  }
});

class VisitorInsightInput {
  final int dailyVisitorCount;
  final int onPremises;
  final int preRegistrations;
  final int checkedOut;

  const VisitorInsightInput({
    required this.dailyVisitorCount,
    required this.onPremises,
    required this.preRegistrations,
    required this.checkedOut,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitorInsightInput &&
          dailyVisitorCount == other.dailyVisitorCount &&
          onPremises == other.onPremises;

  @override
  int get hashCode => Object.hash(dailyVisitorCount, onPremises);
}
