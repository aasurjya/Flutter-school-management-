import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/services/ai_text_generator.dart';

/// Provides an AI-generated book recommendation for the librarian.
final libraryInsightProvider =
    FutureProvider.family<AITextResult, LibraryInsightInput>(
        (ref, input) async {
  final aiStaff = ref.watch(aiStaffTextGeneratorProvider);

  final fallback = '${input.totalIssued} book${input.totalIssued == 1 ? '' : 's'} '
      'issued today with ${input.overdueReturns} overdue return${input.overdueReturns == 1 ? '' : 's'}. '
      'Encourage students to explore new genres to broaden their reading habits.';

  try {
    return await aiStaff.generateBookRecommendation(
      popularGenres: input.popularGenres,
      totalIssued: input.totalIssued,
      overdueReturns: input.overdueReturns,
      catalogSize: input.catalogSize,
      fallback: fallback,
    );
  } catch (_) {
    return AITextResult(text: fallback);
  }
});

class LibraryInsightInput {
  final List<String> popularGenres;
  final int totalIssued;
  final int overdueReturns;
  final int catalogSize;

  const LibraryInsightInput({
    required this.popularGenres,
    required this.totalIssued,
    required this.overdueReturns,
    required this.catalogSize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryInsightInput &&
          totalIssued == other.totalIssued &&
          overdueReturns == other.overdueReturns;

  @override
  int get hashCode => Object.hash(totalIssued, overdueReturns);
}
