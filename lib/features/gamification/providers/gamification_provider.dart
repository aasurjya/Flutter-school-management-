import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/achievement.dart';
import '../../../data/repositories/gamification_repository.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(ref.watch(supabaseProvider));
});

// Achievements providers
final achievementsProvider = FutureProvider.family<List<Achievement>, String?>(
  (ref, category) async {
    final repository = ref.watch(gamificationRepositoryProvider);
    return repository.getAchievements(category: category);
  },
);

final achievementByIdProvider = FutureProvider.family<Achievement?, String>(
  (ref, achievementId) async {
    final repository = ref.watch(gamificationRepositoryProvider);
    return repository.getAchievementById(achievementId);
  },
);

// Student achievements providers
final studentAchievementsProvider =
    FutureProvider.family<List<StudentAchievement>, String>(
  (ref, studentId) async {
    final repository = ref.watch(gamificationRepositoryProvider);
    return repository.getStudentAchievements(studentId);
  },
);

// Points providers
final studentPointsProvider = FutureProvider.family<List<StudentPoints>, String>(
  (ref, studentId) async {
    final repository = ref.watch(gamificationRepositoryProvider);
    return repository.getStudentPoints(studentId);
  },
);

final totalPointsProvider = FutureProvider.family<int, String>(
  (ref, studentId) async {
    final repository = ref.watch(gamificationRepositoryProvider);
    return repository.getTotalPoints(studentId);
  },
);

final pointTransactionsProvider =
    FutureProvider.family<List<PointTransaction>, String>(
  (ref, studentId) async {
    final repository = ref.watch(gamificationRepositoryProvider);
    return repository.getPointTransactions(studentId);
  },
);

// Leaderboard providers
final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String?>(
  (ref, sectionId) async {
    final repository = ref.watch(gamificationRepositoryProvider);
    return repository.getLeaderboard(sectionId: sectionId);
  },
);

final studentRankProvider = FutureProvider.family<LeaderboardEntry?, String>(
  (ref, studentId) async {
    final repository = ref.watch(gamificationRepositoryProvider);
    return repository.getStudentRank(studentId);
  },
);

// Stats provider
final gamificationStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getGamificationStats();
});

// Achievement categories
const achievementCategories = [
  'academic',
  'attendance',
  'sports',
  'arts',
  'behavior',
  'leadership',
  'community',
  'special',
];
