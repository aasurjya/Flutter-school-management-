import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/alumni_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/story_card.dart';

class AlumniDashboardScreen extends ConsumerWidget {
  const AlumniDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(alumniStatsProvider);
    final upcomingEventsAsync = ref.watch(upcomingAlumniEventsProvider);
    final featuredStoriesAsync = ref.watch(featuredStoriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(alumniStatsProvider);
          ref.invalidate(upcomingAlumniEventsProvider);
          ref.invalidate(featuredStoriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Alumni Network',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      context.push(AppRoutes.alumniDirectory),
                ),
              ],
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GlassStatCard(
                              title: 'Total Alumni',
                              value: stats.totalAlumni.toString(),
                              icon: Icons.people,
                              iconColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassStatCard(
                              title: 'Mentors',
                              value: stats.mentorCount.toString(),
                              icon: Icons.psychology,
                              iconColor: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassStatCard(
                              title: 'Total Donations',
                              value:
                                  '\u20B9${_formatAmount(stats.totalDonations)}',
                              icon: Icons.volunteer_activism,
                              iconColor: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassStatCard(
                              title: 'Events',
                              value: stats.upcomingEventsCount.toString(),
                              icon: Icons.event,
                              iconColor: AppColors.info,
                              subtitle: 'upcoming',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading stats: $e'),
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickActionChip(
                            icon: Icons.person_search,
                            label: 'Directory',
                            onTap: () =>
                                context.push(AppRoutes.alumniDirectory),
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.event,
                            label: 'Events',
                            onTap: () =>
                                context.push(AppRoutes.alumniEvents),
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.volunteer_activism,
                            label: 'Donate',
                            onTap: () =>
                                context.push(AppRoutes.alumniDonations),
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.psychology,
                            label: 'Mentorship',
                            onTap: () =>
                                context.push(AppRoutes.alumniMentorship),
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.auto_stories,
                            label: 'Stories',
                            onTap: () =>
                                context.push(AppRoutes.alumniStories),
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.person_add,
                            label: 'Register',
                            onTap: () =>
                                context.push(AppRoutes.alumniRegistration),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Upcoming Events
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Events',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push(AppRoutes.alumniEvents),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),
            upcomingEventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: GlassCard(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No upcoming events'),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = events[index];
                      return AlumniEventCard(
                        event: event,
                        onTap: () => context.push(
                          AppRoutes.alumniEventDetail
                              .replaceAll(':eventId', event.id),
                        ),
                      );
                    },
                    childCount: events.take(3).length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Text('Error: $e'),
              ),
            ),

            // Featured Stories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Success Stories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push(AppRoutes.alumniStories),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),
            featuredStoriesAsync.when(
              data: (stories) {
                if (stories.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: GlassCard(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No featured stories yet'),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return StoryCard(story: stories[index]);
                    },
                    childCount: stories.take(3).length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Text('Error: $e'),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primary.withValues(alpha: 0.06),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
