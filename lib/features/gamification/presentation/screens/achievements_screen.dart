import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/achievement.dart';
import '../../providers/gamification_provider.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  final String studentId;

  const AchievementsScreen({super.key, required this.studentId});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPointsAsync = ref.watch(totalPointsProvider(widget.studentId));
    final rankAsync = ref.watch(studentRankProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => context.push('/gamification/leaderboard'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Achievements'),
            Tab(text: 'All Badges'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(
                  icon: Icons.stars,
                  label: 'Total Points',
                  value: totalPointsAsync.when(
                    data: (points) => points.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
                _StatColumn(
                  icon: Icons.military_tech,
                  label: 'School Rank',
                  value: rankAsync.when(
                    data: (rank) => rank != null ? '#${rank.tenantRank}' : '-',
                    loading: () => '...',
                    error: (_, __) => '-',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
                _StatColumn(
                  icon: Icons.emoji_events,
                  label: 'Class Rank',
                  value: rankAsync.when(
                    data: (rank) => rank != null ? '#${rank.sectionRank}' : '-',
                    loading: () => '...',
                    error: (_, __) => '-',
                  ),
                ),
              ],
            ),
          ),
          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MyAchievementsTab(studentId: widget.studentId),
                _AllBadgesTab(studentId: widget.studentId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MyAchievementsTab extends ConsumerWidget {
  final String studentId;

  const _MyAchievementsTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(studentAchievementsProvider(studentId));

    return achievementsAsync.when(
      data: (achievements) {
        if (achievements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                const Text('No achievements yet'),
                const SizedBox(height: 8),
                Text(
                  'Keep up the good work to earn badges!',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            return _AchievementBadge(
              achievement: achievements[index].achievement!,
              isEarned: true,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _AllBadgesTab extends ConsumerWidget {
  final String studentId;

  const _AllBadgesTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAchievementsAsync = ref.watch(achievementsProvider(null));
    final studentAchievementsAsync =
        ref.watch(studentAchievementsProvider(studentId));

    return allAchievementsAsync.when(
      data: (allAchievements) {
        return studentAchievementsAsync.when(
          data: (earnedAchievements) {
            final earnedIds =
                earnedAchievements.map((a) => a.achievementId).toSet();

            // Group by category
            final byCategory = <String, List<Achievement>>{};
            for (final achievement in allAchievements) {
              byCategory.putIfAbsent(achievement.category, () => []);
              byCategory[achievement.category]!.add(achievement);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: byCategory.length,
              itemBuilder: (context, index) {
                final category = byCategory.keys.elementAt(index);
                final achievements = byCategory[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievements.first.categoryDisplay,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: achievements.length,
                        itemBuilder: (context, i) {
                          final achievement = achievements[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 90,
                              child: _AchievementBadge(
                                achievement: achievement,
                                isEarned: earnedIds.contains(achievement.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool isEarned;

  const _AchievementBadge({
    required this.achievement,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showAchievementDetails(context),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEarned
                  ? _getCategoryColor(achievement.category)
                  : Colors.grey.withOpacity(0.3),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: _getCategoryColor(achievement.category)
                            .withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _getCategoryIcon(achievement.category),
              color: isEarned ? Colors.white : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isEarned ? null : Colors.grey,
                  fontWeight: isEarned ? FontWeight.w600 : null,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${achievement.points} pts',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEarned
                    ? _getCategoryColor(achievement.category)
                    : Colors.grey.withOpacity(0.3),
              ),
              child: Icon(
                _getCategoryIcon(achievement.category),
                color: isEarned ? Colors.white : Colors.grey,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${achievement.points} points',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            if (achievement.description != null) ...[
              const SizedBox(height: 16),
              Text(
                achievement.description!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              isEarned ? 'Earned!' : 'Not yet earned',
              style: TextStyle(
                color: isEarned ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'academic':
        return Colors.blue;
      case 'attendance':
        return Colors.green;
      case 'sports':
        return Colors.orange;
      case 'arts':
        return Colors.purple;
      case 'behavior':
        return Colors.teal;
      case 'leadership':
        return Colors.indigo;
      case 'community':
        return Colors.pink;
      case 'special':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'academic':
        return Icons.school;
      case 'attendance':
        return Icons.check_circle;
      case 'sports':
        return Icons.sports_soccer;
      case 'arts':
        return Icons.palette;
      case 'behavior':
        return Icons.favorite;
      case 'leadership':
        return Icons.star;
      case 'community':
        return Icons.people;
      case 'special':
        return Icons.auto_awesome;
      default:
        return Icons.emoji_events;
    }
  }
}
