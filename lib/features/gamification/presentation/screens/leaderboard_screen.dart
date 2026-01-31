import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/achievement.dart';
import '../../providers/gamification_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String? _selectedSectionId;

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider(_selectedSectionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedSectionId = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Students'),
              ),
              // In a real app, you'd fetch sections dynamically
            ],
          ),
        ],
      ),
      body: leaderboardAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text('No data available'),
            );
          }

          return CustomScrollView(
            slivers: [
              // Top 3 podium
              if (entries.length >= 3)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _TopThreePodium(entries: entries.take(3).toList()),
                  ),
                ),
              // Remaining entries
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final actualIndex = index + 3;
                      if (actualIndex >= entries.length) return null;
                      return _LeaderboardTile(
                        entry: entries[actualIndex],
                        rank: actualIndex + 1,
                      );
                    },
                    childCount: entries.length > 3 ? entries.length - 3 : 0,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _TopThreePodium extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _TopThreePodium({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 3) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(
            child: _PodiumItem(
              entry: entries[1],
              rank: 2,
              height: 140,
              color: Colors.grey[400]!,
            ),
          ),
          // 1st place
          Expanded(
            child: _PodiumItem(
              entry: entries[0],
              rank: 1,
              height: 180,
              color: Colors.amber,
            ),
          ),
          // 3rd place
          Expanded(
            child: _PodiumItem(
              entry: entries[2],
              rank: 3,
              height: 110,
              color: Colors.orange[300]!,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final Color color;

  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with crown for #1
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 35 : 28,
              backgroundColor: color,
              child: entry.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        entry.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          entry.initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: rank == 1 ? 20 : 16,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      entry.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: rank == 1 ? 20 : 16,
                      ),
                    ),
            ),
            if (rank == 1)
              const Positioned(
                top: -15,
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          entry.fullName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          '${entry.totalPoints} pts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        // Podium stand
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 32 : 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;

  const _LeaderboardTile({
    required this.entry,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '#$rank',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: entry.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        entry.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          entry.initials,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      entry.initials,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
            ),
          ],
        ),
        title: Text(entry.fullName),
        subtitle: Text(
          '${entry.className ?? ''} ${entry.sectionName ?? ''}'.trim(),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.totalPoints}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'points',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
