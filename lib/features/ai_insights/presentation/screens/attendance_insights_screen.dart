import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/attendance_insights_provider.dart';
import '../widgets/chronic_absentee_card.dart';
import '../widgets/day_pattern_chart.dart';
import '../widgets/attendance_trend_chart.dart';

class AttendanceInsightsScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final String? sectionName;

  const AttendanceInsightsScreen({
    super.key,
    required this.sectionId,
    this.sectionName,
  });

  @override
  ConsumerState<AttendanceInsightsScreen> createState() =>
      _AttendanceInsightsScreenState();
}

class _AttendanceInsightsScreenState
    extends ConsumerState<AttendanceInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.sectionName ?? 'Attendance Insights',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.oceanGradient,
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Patterns'),
                Tab(text: 'Students'),
                Tab(text: 'Anomalies'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _PatternsTab(sectionId: widget.sectionId),
            _StudentsTab(sectionId: widget.sectionId),
            _AnomaliesTab(sectionId: widget.sectionId),
          ],
        ),
      ),
    );
  }
}

class _PatternsTab extends ConsumerWidget {
  final String sectionId;
  const _PatternsTab({required this.sectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(dayPatternsProvider(sectionId));

    return patternsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Failed to load patterns')),
      data: (patterns) {
        if (patterns.isEmpty) {
          return const Center(child: Text('No attendance data available'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Summary (non-blocking)
              Consumer(
                builder: (context, ref, _) {
                  final narrativeAsync =
                      ref.watch(attendanceNarrativeProvider(sectionId));
                  return narrativeAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (result) {
                      if (result.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    result.isLLMGenerated
                                        ? Icons.auto_awesome
                                        : Icons.info_outline,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'AI Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                result.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const Text(
                'Attendance by Day of Week',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Identifies which days have the lowest attendance rates',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: DayPatternChart(patterns: patterns),
              ),
              const SizedBox(height: 16),
              // Problematic days
              ...patterns.where((p) => p.isProblematic).map((p) {
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${p.shortDayName}: ${p.attendancePercentage.toStringAsFixed(1)}% attendance (${p.absentCount} absences)',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  final String sectionId;
  const _StudentsTab({required this.sectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absenteesAsync = ref.watch(chronicAbsenteesProvider(sectionId));
    final streaksAsync = ref.watch(attendanceStreaksProvider(sectionId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chronic Absentees',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Students with >20% absence rate',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          absenteesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load data'),
            data: (absentees) {
              if (absentees.isEmpty) {
                return const GlassCard(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('No chronic absentees'),
                    ],
                  ),
                );
              }
              return Column(
                children: absentees
                    .map((a) => ChronicAbsenteeCard(absentee: a))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Streaks
          const Text(
            'Notable Streaks',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          streaksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load streaks'),
            data: (streaks) {
              if (streaks.isEmpty) {
                return const Text(
                  'No notable streaks detected',
                  style: TextStyle(color: Colors.grey),
                );
              }
              return Column(
                children: streaks.map((streak) {
                  final isAbsent = streak.streakType == 'absent';
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          isAbsent
                              ? Icons.cancel_outlined
                              : Icons.check_circle_outline,
                          color: isAbsent
                              ? AppColors.error
                              : AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${streak.studentName}: ${streak.streakLength} days ${streak.streakType}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnomaliesTab extends ConsumerWidget {
  final String sectionId;
  const _AnomaliesTab({required this.sectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomaliesAsync = ref.watch(attendanceAnomaliesProvider(sectionId));
    final repo = ref.watch(attendanceInsightsRepositoryProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.getSectionDailyHistory(sectionId),
      builder: (context, snapshot) {
        final dailyHistory = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '30-Day Attendance Trend',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Red dots indicate anomalies (>15% deviation from 7-day average)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: anomaliesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Failed to load'),
                  data: (anomalies) => AttendanceTrendChart(
                    dailyHistory: dailyHistory,
                    anomalies: anomalies,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Anomaly list
              anomaliesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (anomalies) {
                  if (anomalies.isEmpty) {
                    return const GlassCard(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success),
                          SizedBox(width: 8),
                          Text('No anomalies detected'),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Anomalies',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ...anomalies.map((a) {
                        final isDrop = a.type == 'drop';
                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                isDrop
                                    ? Icons.trending_down
                                    : Icons.trending_up,
                                color: isDrop
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${a.date.day}/${a.date.month}/${a.date.year}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${a.attendancePercentage.toStringAsFixed(1)}% (expected ${a.expectedPercentage.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${a.deviation > 0 ? '+' : ''}${a.deviation.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDrop
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
