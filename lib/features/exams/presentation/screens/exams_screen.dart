import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class ExamsScreen extends ConsumerWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exams & Results'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Results'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _UpcomingExamsTab(),
            _ResultsTab(),
            _AnalyticsTab(),
          ],
        ),
      ),
    );
  }
}

class _UpcomingExamsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current/Ongoing Exam
        const Text(
          'Ongoing',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _ExamCard(
          title: 'Final Term Examination',
          dateRange: 'Dec 10 - Dec 20, 2024',
          status: 'ongoing',
          subjects: ['Mathematics', 'Physics', 'Chemistry', 'English'],
          classInfo: 'Class 10',
        ),
        const SizedBox(height: 24),

        // Upcoming Exams
        const Text(
          'Upcoming',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _ExamCard(
          title: 'Unit Test 3',
          dateRange: 'Jan 15 - Jan 18, 2025',
          status: 'upcoming',
          subjects: ['Mathematics', 'Science'],
          classInfo: 'Class 9 & 10',
        ),
        _ExamCard(
          title: 'Practical Examinations',
          dateRange: 'Jan 25 - Jan 30, 2025',
          status: 'upcoming',
          subjects: ['Physics Lab', 'Chemistry Lab', 'Biology Lab'],
          classInfo: 'Class 11 & 12',
        ),
      ],
    );
  }
}

class _ResultsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recent Results
        _ResultCard(
          examName: 'Mid Term Examination',
          date: 'October 2024',
          percentage: 87.5,
          rank: 5,
          totalStudents: 42,
          subjects: [
            {'name': 'Mathematics', 'marks': 92, 'total': 100},
            {'name': 'Physics', 'marks': 88, 'total': 100},
            {'name': 'Chemistry', 'marks': 85, 'total': 100},
            {'name': 'English', 'marks': 90, 'total': 100},
            {'name': 'Computer Science', 'marks': 95, 'total': 100},
          ],
        ),
        const SizedBox(height: 16),
        _ResultCard(
          examName: 'Unit Test 2',
          date: 'September 2024',
          percentage: 82.0,
          rank: 8,
          totalStudents: 42,
          subjects: [
            {'name': 'Mathematics', 'marks': 85, 'total': 100},
            {'name': 'Physics', 'marks': 80, 'total': 100},
            {'name': 'Chemistry', 'marks': 78, 'total': 100},
            {'name': 'English', 'marks': 88, 'total': 100},
          ],
        ),
      ],
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Trend
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Trend',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up, size: 48, color: AppColors.success),
                        const SizedBox(height: 8),
                        const Text(
                          '+5.2% improvement',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'compared to last term',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Subject-wise Performance
          const Text(
            'Subject-wise Performance',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _SubjectPerformanceCard(
            subject: 'Mathematics',
            score: 92,
            trend: 'up',
            comparison: 'Class Avg: 78%',
          ),
          _SubjectPerformanceCard(
            subject: 'Physics',
            score: 88,
            trend: 'up',
            comparison: 'Class Avg: 75%',
          ),
          _SubjectPerformanceCard(
            subject: 'Chemistry',
            score: 85,
            trend: 'down',
            comparison: 'Class Avg: 72%',
          ),
          _SubjectPerformanceCard(
            subject: 'English',
            score: 90,
            trend: 'same',
            comparison: 'Class Avg: 80%',
          ),
          const SizedBox(height: 24),

          // Class Position
          GlassCard(
            padding: const EdgeInsets.all(20),
            gradient: AppColors.primaryGradient,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Rank',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '#5 out of 42',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '+2 from last',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final String title;
  final String dateRange;
  final String status;
  final List<String> subjects;
  final String classInfo;

  const _ExamCard({
    required this.title,
    required this.dateRange,
    required this.status,
    required this.subjects,
    required this.classInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isOngoing = status == 'ongoing';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOngoing ? 'Ongoing' : 'Upcoming',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOngoing ? AppColors.success : AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                dateRange,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.class_, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                classInfo,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects
                .map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String examName;
  final String date;
  final double percentage;
  final int rank;
  final int totalStudents;
  final List<Map<String, dynamic>> subjects;

  const _ResultCard({
    required this.examName,
    required this.date,
    required this.percentage,
    required this.rank,
    required this.totalStudents,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      examName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: percentage >= 80 ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  Text(
                    'Rank #$rank / $totalStudents',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          ...subjects.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(s['name'] as String),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: (s['marks'] as int) / (s['total'] as int),
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(
                          (s['marks'] as int) >= 80 ? AppColors.success : AppColors.warning,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${s['marks']}/${s['total']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            child: const Text('Download Report Card'),
          ),
        ],
      ),
    );
  }
}

class _SubjectPerformanceCard extends StatelessWidget {
  final String subject;
  final int score;
  final String trend;
  final String comparison;

  const _SubjectPerformanceCard({
    required this.subject,
    required this.score,
    required this.trend,
    required this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    final trendIcon = trend == 'up'
        ? Icons.trending_up
        : trend == 'down'
            ? Icons.trending_down
            : Icons.trending_flat;
    final trendColor = trend == 'up'
        ? AppColors.success
        : trend == 'down'
            ? AppColors.error
            : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(subject, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                score >= 80 ? AppColors.success : AppColors.warning,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$score%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Icon(trendIcon, color: trendColor, size: 20),
        ],
      ),
    );
  }
}
