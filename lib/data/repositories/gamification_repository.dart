import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement.dart';
import 'base_repository.dart';

class GamificationRepository extends BaseRepository {
  GamificationRepository(super.client);

  // ==================== ACHIEVEMENTS ====================

  Future<List<Achievement>> getAchievements({
    String? category,
    bool activeOnly = true,
  }) async {
    var query = client
        .from('achievements')
        .select()
        .eq('tenant_id', tenantId!);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    if (category != null) {
      query = query.eq('category', category);
    }

    final response = await query.order('category').order('name');
    return (response as List).map((json) => Achievement.fromJson(json)).toList();
  }

  Future<Achievement?> getAchievementById(String achievementId) async {
    final response = await client
        .from('achievements')
        .select()
        .eq('id', achievementId)
        .maybeSingle();

    if (response == null) return null;
    return Achievement.fromJson(response);
  }

  Future<Achievement> createAchievement(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    final response = await client
        .from('achievements')
        .insert(data)
        .select()
        .single();
    return Achievement.fromJson(response);
  }

  Future<Achievement> updateAchievement(
    String achievementId,
    Map<String, dynamic> data,
  ) async {
    final response = await client
        .from('achievements')
        .update(data)
        .eq('id', achievementId)
        .select()
        .single();
    return Achievement.fromJson(response);
  }

  // ==================== STUDENT ACHIEVEMENTS ====================

  Future<List<StudentAchievement>> getStudentAchievements(String studentId) async {
    final response = await client
        .from('student_achievements')
        .select('''
          *,
          achievements(*)
        ''')
        .eq('student_id', studentId)
        .order('earned_at', ascending: false);

    return (response as List)
        .map((json) => StudentAchievement.fromJson(json))
        .toList();
  }

  Future<StudentAchievement> awardAchievement({
    required String studentId,
    required String achievementId,
    String? notes,
  }) async {
    // Check if already earned
    final existing = await client
        .from('student_achievements')
        .select('id')
        .eq('student_id', studentId)
        .eq('achievement_id', achievementId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Achievement already earned');
    }

    final response = await client
        .from('student_achievements')
        .insert({
          'tenant_id': tenantId,
          'student_id': studentId,
          'achievement_id': achievementId,
          'awarded_by': currentUserId,
          'notes': notes,
        })
        .select('''
          *,
          achievements(*)
        ''')
        .single();

    // Award points for the achievement
    final achievement = await getAchievementById(achievementId);
    if (achievement != null) {
      await awardPoints(
        studentId: studentId,
        category: achievement.category,
        points: achievement.points,
        reason: 'Achievement: ${achievement.name}',
      );
    }

    return StudentAchievement.fromJson(response);
  }

  Future<void> revokeAchievement(String studentAchievementId) async {
    await client
        .from('student_achievements')
        .delete()
        .eq('id', studentAchievementId);
  }

  // ==================== POINTS ====================

  Future<List<StudentPoints>> getStudentPoints(String studentId) async {
    final response = await client
        .from('student_points')
        .select()
        .eq('student_id', studentId)
        .order('category');

    return (response as List)
        .map((json) => StudentPoints.fromJson(json))
        .toList();
  }

  Future<int> getTotalPoints(String studentId) async {
    final points = await getStudentPoints(studentId);
    return points.fold<int>(0, (sum, p) => sum + p.points);
  }

  Future<void> awardPoints({
    required String studentId,
    required String category,
    required int points,
    required String reason,
    String? referenceType,
    String? referenceId,
  }) async {
    await client.rpc('award_points', params: {
      'p_tenant_id': tenantId,
      'p_student_id': studentId,
      'p_category': category,
      'p_points': points,
      'p_reason': reason,
      'p_awarded_by': currentUserId,
    });
  }

  Future<List<PointTransaction>> getPointTransactions(
    String studentId, {
    int limit = 50,
  }) async {
    final response = await client
        .from('point_transactions')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => PointTransaction.fromJson(json))
        .toList();
  }

  // ==================== LEADERBOARD ====================

  Future<List<LeaderboardEntry>> getLeaderboard({
    String? sectionId,
    int limit = 50,
  }) async {
    var query = client
        .from('v_student_leaderboard')
        .select()
        .eq('tenant_id', tenantId!);

    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }

    final response = await query
        .order('total_points', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => LeaderboardEntry.fromJson(json))
        .toList();
  }

  Future<LeaderboardEntry?> getStudentRank(String studentId) async {
    final response = await client
        .from('v_student_leaderboard')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();

    if (response == null) return null;
    return LeaderboardEntry.fromJson(response);
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getGamificationStats() async {
    // Total achievements count
    final achievementsResponse = await client
        .from('achievements')
        .select('id')
        .eq('tenant_id', tenantId!)
        .eq('is_active', true);

    // Total awarded achievements
    final awardedResponse = await client
        .from('student_achievements')
        .select('id')
        .eq('tenant_id', tenantId!);

    // Total points distributed
    final pointsResponse = await client
        .from('student_points')
        .select('points')
        .eq('tenant_id', tenantId!);

    final totalPoints = (pointsResponse as List)
        .fold<int>(0, (sum, p) => sum + (p['points'] as int));

    // Top achiever
    final topAchiever = await getLeaderboard(limit: 1);

    return {
      'total_achievements': (achievementsResponse as List).length,
      'total_awarded': (awardedResponse as List).length,
      'total_points_distributed': totalPoints,
      'top_achiever': topAchiever.isNotEmpty ? topAchiever.first : null,
    };
  }
}
