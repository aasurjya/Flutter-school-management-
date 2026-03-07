import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/student_portfolio.dart';
import '../../providers/student_portfolio_provider.dart';

class StudentPortfolioScreen extends ConsumerWidget {
  final String studentId;

  const StudentPortfolioScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(portfolioSummaryProvider(studentId));
    final worksAsync = ref.watch(portfolioWorkProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Student Portfolio')),
      body: summaryAsync.when(
        data: (summary) => _PortfolioBody(
          summary: summary,
          worksAsync: worksAsync,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PortfolioBody extends StatelessWidget {
  final PortfolioSummary summary;
  final AsyncValue<List<PortfolioWork>> worksAsync;

  const _PortfolioBody({required this.summary, required this.worksAsync});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileCard(summary: summary),
          const SizedBox(height: 20),
          _StatsRow(summary: summary),
          const SizedBox(height: 20),
          const Text(
            'Subjects',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...summary.subjectScores.map((s) => _SubjectRow(score: s)),
          if (summary.achievements.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Achievements',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: summary.achievements.length,
                itemBuilder: (ctx, i) =>
                    _AchievementChip(achievement: summary.achievements[i]),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Portfolio Work',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          worksAsync.when(
            data: (works) => works.isEmpty
                ? const _EmptyWorks()
                : Column(
                    children: works.map((w) => _WorkCard(work: w)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load work'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final PortfolioSummary summary;

  const _ProfileCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: summary.photoUrl != null
                  ? NetworkImage(summary.photoUrl!)
                  : null,
              child: summary.photoUrl == null
                  ? Text(
                      summary.studentName.isNotEmpty
                          ? summary.studentName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.studentName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (summary.className != null)
                    Text(
                      '${summary.className} ${summary.sectionName ?? ''}'.trim(),
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                    ),
                  Text(
                    'Roll: ${summary.rollNumber}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                  if (summary.overallGrade != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Grade ${summary.overallGrade}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final PortfolioSummary summary;

  const _StatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.trending_up,
          label: 'Overall',
          value: summary.overallPercentage != null
              ? '${summary.overallPercentage!.toStringAsFixed(1)}%'
              : 'N/A',
          color: Colors.blue,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.calendar_today,
          label: 'Attendance',
          value: '${summary.attendancePercentage.toStringAsFixed(1)}%',
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.star,
          label: 'Points',
          value: '${summary.totalPoints}',
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color),
              ),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectScore score;

  const _SubjectRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = score.percentage ?? 0;
    final color = pct >= 80
        ? Colors.green
        : pct >= 60
            ? Colors.blue
            : pct >= 40
                ? Colors.orange
                : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(score.subjectName,
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              score.grade != null
                  ? score.grade!
                  : '${pct.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final PortfolioAchievement achievement;

  const _AchievementChip({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
          const SizedBox(height: 4),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  final PortfolioWork work;

  const _WorkCard({required this.work});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description, color: AppColors.primary),
        ),
        title: Text(work.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${work.subjectName ?? work.workType} · ${work.submittedAt.toLocal().toString().split(' ')[0]}',
        ),
        trailing: work.grade != null
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  work.grade!,
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    );
  }
}

class _EmptyWorks extends StatelessWidget {
  const _EmptyWorks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('No portfolio work yet',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
