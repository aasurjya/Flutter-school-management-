import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/discipline_provider.dart';
import '../widgets/behavior_trend_chart.dart';
import '../widgets/incident_card.dart';
import '../widgets/recognition_card.dart';

class DisciplineDashboardScreen extends ConsumerWidget {
  const DisciplineDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(defaultBehaviorStatsProvider);
    final recentAsync = ref.watch(recentIncidentsProvider);
    final topStudentsAsync = ref.watch(topPositiveStudentsProvider);
    final publicRecAsync = ref.watch(publicRecognitionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discipline Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/discipline/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(defaultBehaviorStatsProvider);
          ref.invalidate(recentIncidentsProvider);
          ref.invalidate(topPositiveStudentsProvider);
          ref.invalidate(publicRecognitionsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stat Cards ──
              statsAsync.when(
                data: (stats) => _buildStatCards(context, stats),
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _errorCard('Failed to load stats'),
              ),
              const SizedBox(height: 24),

              // ── Trend Chart ──
              const Text(
                'Incident Trend (30 days)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: statsAsync.when(
                  data: (stats) =>
                      BehaviorTrendChart(dailyTrend: stats.dailyTrend),
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox(
                    height: 200,
                    child: Center(child: Text('Chart unavailable')),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick Actions ──
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // ── Recent Incidents ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Incidents',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => context.push('/discipline/incidents'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              recentAsync.when(
                data: (incidents) {
                  if (incidents.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No recent incidents',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: incidents
                        .take(5)
                        .map((inc) => IncidentCard(
                              incident: inc,
                              onTap: () => context
                                  .push('/discipline/incidents/${inc.id}'),
                            ))
                        .toList(),
                  );
                },
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _errorCard('Failed to load incidents'),
              ),
              const SizedBox(height: 24),

              // ── Top Positive Students ──
              const Text(
                'Top Positive Students',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              topStudentsAsync.when(
                data: (students) {
                  if (students.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No recognition data yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return _buildLeaderboard(students);
                },
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _errorCard('Failed to load leaderboard'),
              ),
              const SizedBox(height: 24),

              // ── Recent Recognitions ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Recognitions',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => context.push('/discipline/recognitions'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              publicRecAsync.when(
                data: (recs) {
                  if (recs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No recognitions yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: recs
                        .take(5)
                        .map((r) => RecognitionCard(recognition: r))
                        .toList(),
                  );
                },
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _errorCard('Failed to load recognitions'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, dynamic stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassStatCard(
                title: 'Total Incidents',
                value: '${stats.totalIncidents}',
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassStatCard(
                title: 'Open / Active',
                value: '${stats.openIncidents}',
                icon: Icons.pending_outlined,
                iconColor: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassStatCard(
                title: 'Resolved',
                value: '${stats.resolvedIncidents}',
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassStatCard(
                title: 'Recognitions',
                value: '${stats.totalRecognitions}',
                icon: Icons.star_outline,
                iconColor: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_circle_outline,
            label: 'Report\nIncident',
            color: AppColors.error,
            onTap: () => context.push('/discipline/report'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.star_outline,
            label: 'Recognize\nStudent',
            color: AppColors.success,
            onTap: () => context.push('/discipline/recognitions'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.assignment_outlined,
            label: 'Behavior\nPlans',
            color: AppColors.info,
            onTap: () => context.push('/discipline/plans'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.schedule_outlined,
            label: 'Detention\nMgmt',
            color: AppColors.warning,
            onTap: () => context.push('/discipline/detention'),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(List<Map<String, dynamic>> students) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: students.asMap().entries.take(5).map((entry) {
          final idx = entry.key;
          final data = entry.value;
          final student = data['students'] as Map<String, dynamic>?;
          final name = student != null
              ? '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'
                  .trim()
              : 'Student';
          final points = data['positive_points'] ?? 0;

          Color medalColor;
          if (idx == 0) {
            medalColor = const Color(0xFFFFD700);
          } else if (idx == 1) {
            medalColor = const Color(0xFFC0C0C0);
          } else if (idx == 2) {
            medalColor = const Color(0xFFCD7F32);
          } else {
            medalColor = Colors.grey;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#${idx + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: medalColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: medalColor.withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: medalColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$points pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _errorCard(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(msg, style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
