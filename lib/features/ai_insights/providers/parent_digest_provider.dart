import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/parent_digest.dart';
import '../../../data/repositories/parent_digest_repository.dart';

final parentDigestRepositoryProvider = Provider<ParentDigestRepository>((ref) {
  return ParentDigestRepository(
    ref.watch(supabaseProvider),
    ref.watch(aiTextGeneratorProvider),
  );
});

// --- Filter classes ---

class ParentDigestFilter {
  final String parentId;
  final String? studentId;
  final int limit;

  const ParentDigestFilter({
    required this.parentId,
    this.studentId,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentDigestFilter &&
          other.parentId == parentId &&
          other.studentId == studentId &&
          other.limit == limit;

  @override
  int get hashCode => Object.hash(parentId, studentId, limit);
}

// --- Providers ---

final parentDigestsProvider =
    FutureProvider.family<List<ParentDigest>, ParentDigestFilter>(
  (ref, filter) async {
    final repo = ref.watch(parentDigestRepositoryProvider);
    return repo.getDigestsForParent(
      filter.parentId,
      studentId: filter.studentId,
      limit: filter.limit,
    );
  },
);

final unreadDigestCountProvider = FutureProvider.family<int, String>(
  (ref, parentId) async {
    final repo = ref.watch(parentDigestRepositoryProvider);
    return repo.getUnreadCount(parentId);
  },
);

final digestDetailProvider =
    FutureProvider.family<ParentDigest?, String>(
  (ref, digestId) async {
    final repo = ref.watch(parentDigestRepositoryProvider);
    return repo.getDigestById(digestId);
  },
);
