import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/student_insights.dart';
import '../../providers/insights_provider.dart';
import '../widgets/performance_summary_card.dart';
import '../widgets/subject_radar_chart.dart';
import '../widgets/attendance_chart.dart';
import '../widgets/improvement_tips_card.dart';
import '../widgets/subject_performance_list.dart';

class ChildInsightsScreen extends ConsumerStatefulWidget {
  final String studentId;

  const ChildInsightsScreen({super.key, required this.studentId});

  @override
  ConsumerState<ChildInsightsScreen> createState() => _ChildInsightsScreenState();
}

class _ChildInsightsScreenState extends ConsumerState<ChildInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(studentInsightsProvider(widget.studentId));

    return Scaffold(
      body: insightsAsync.when(
        data: (insights) => _buildContent(context, insights),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading insights: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(studentInsightsProvider(widget.studentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StudentInsights insights) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              insights.studentName,
              style: const TextStyle(fontSize: 16),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 50),
                  child: _buildHeaderStats(context, insights),
                ),
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Subjects'),
              Tab(text: 'Attendance'),
              Tab(text: 'Tips'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(insights: insights, studentId: widget.studentId),
          _SubjectsTab(insights: insights),
          _AttendanceTab(studentId: widget.studentId, insights: insights),
          _TipsTab(insights: insights),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(BuildContext context, StudentInsights insights) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          icon: Icons.school,
          value: '${insights.overallPercentage.toStringAsFixed(1)}%',
          label: 'Overall',
        ),
        _StatItem(
          icon: Icons.leaderboard,
          value: '#${insights.classRank}',
          label: 'Class Rank',
        ),
        _StatItem(
          icon: Icons.calendar_today,
          value: '${insights.attendancePercentage.toStringAsFixed(1)}%',
          label: 'Attendance',
        ),
        _StatItem(
          icon: Icons.stars,
          value: '${insights.totalPoints}',
          label: 'Points',
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final StudentInsights insights;
  final String studentId;

  const _OverviewTab({required this.insights, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PerformanceSummaryCard(insights: insights),
        const SizedBox(height: 16),
        SubjectRadarChart(studentId: studentId, insights: insights),
        const SizedBox(height: 16),
        _StrengthsWeaknessesCard(insights: insights),
        const SizedBox(height: 16),
        _GamificationCard(insights: insights),
      ],
    );
  }
}

class _StrengthsWeaknessesCard extends StatelessWidget {
  final StudentInsights insights;

  const _StrengthsWeaknessesCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Strengths & Areas for Improvement',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (insights.strengths.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.thumb_up, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Strengths',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: insights.strengths.map((subject) {
                  return Chip(
                    avatar: const Icon(Icons.star, size: 16),
                    label: Text(subject),
                    backgroundColor: Colors.green[50],
                    labelStyle: TextStyle(color: Colors.green[700]),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (insights.areasForImprovement.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Areas for Improvement',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: insights.areasForImprovement.map((subject) {
                  return Chip(
                    avatar: const Icon(Icons.lightbulb_outline, size: 16),
                    label: Text(subject),
                    backgroundColor: Colors.orange[50],
                    labelStyle: TextStyle(color: Colors.orange[700]),
                  );
                }).toList(),
              ),
            ],
            if (insights.strengths.isEmpty &&
                insights.areasForImprovement.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Not enough data to determine strengths'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GamificationCard extends StatelessWidget {
  final StudentInsights insights;

  const _GamificationCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Achievements & Rewards',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _GamificationStat(
                  icon: Icons.stars,
                  value: '${insights.totalPoints}',
                  label: 'Total Points',
                  color: Colors.amber,
                ),
                _GamificationStat(
                  icon: Icons.military_tech,
                  value: '${insights.achievementsCount}',
                  label: 'Badges Earned',
                  color: Colors.purple,
                ),
                _GamificationStat(
                  icon: Icons.leaderboard,
                  value: insights.schoolRank > 0 ? '#${insights.schoolRank}' : '-',
                  label: 'School Rank',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GamificationStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _GamificationStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SubjectsTab extends StatelessWidget {
  final StudentInsights insights;

  const _SubjectsTab({required this.insights});

  @override
  Widget build(BuildContext context) {
    return SubjectPerformanceList(subjectInsights: insights.subjectInsights);
  }
}

class _AttendanceTab extends ConsumerWidget {
  final String studentId;
  final StudentInsights insights;

  const _AttendanceTab({required this.studentId, required this.insights});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AttendanceSummaryCard(insights: insights),
        const SizedBox(height: 16),
        AttendanceChart(studentId: studentId),
      ],
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final StudentInsights insights;

  const _AttendanceSummaryCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getAttendanceColor(insights.attendancePercentage);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${insights.attendancePercentage.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Rate',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insights.attendanceStatus,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _getAttendanceIcon(insights.attendanceStatus),
                  color: color,
                  size: 40,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: insights.attendancePercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getAttendanceIcon(String status) {
    switch (status) {
      case 'Excellent':
        return Icons.emoji_events;
      case 'Good':
        return Icons.thumb_up;
      case 'Concerning':
        return Icons.warning;
      default:
        return Icons.error;
    }
  }
}

class _TipsTab extends StatelessWidget {
  final StudentInsights insights;

  const _TipsTab({required this.insights});

  @override
  Widget build(BuildContext context) {
    return ImprovementTipsCard(tips: insights.tips);
  }
}
