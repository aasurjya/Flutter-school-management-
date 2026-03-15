import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../students/providers/students_provider.dart';
import '../../providers/exams_provider.dart';

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
        body: const TabBarView(
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

// ---------------------------------------------------------------------------
// Upcoming Exams Tab
// ---------------------------------------------------------------------------

class _UpcomingExamsTab extends ConsumerWidget {
  const _UpcomingExamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider(const ExamsFilter()));

    return examsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Failed to load exams: $e'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(examsProvider(const ExamsFilter())),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (exams) {
        if (exams.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No exams scheduled'),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final ongoing = exams.where((e) {
          final start = e.startDate;
          final end = e.endDate;
          if (start == null || end == null) return false;
          return start.isBefore(now) && end.isAfter(now);
        }).toList();
        final upcoming = exams.where((e) {
          final start = e.startDate;
          if (start == null) return false;
          return start.isAfter(now);
        }).toList();
        final completed = exams.where((e) {
          final end = e.endDate;
          if (end == null) return false;
          return end.isBefore(now);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (ongoing.isNotEmpty) ...[
              const Text(
                'Ongoing',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...ongoing.map((e) => _ExamCard(exam: e, status: 'ongoing')),
              const SizedBox(height: 24),
            ],
            if (upcoming.isNotEmpty) ...[
              const Text(
                'Upcoming',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...upcoming.map((e) => _ExamCard(exam: e, status: 'upcoming')),
              const SizedBox(height: 24),
            ],
            if (completed.isNotEmpty) ...[
              const Text(
                'Completed',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...completed.map((e) => _ExamCard(exam: e, status: 'completed')),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Results Tab
// ---------------------------------------------------------------------------

class _ResultsTab extends ConsumerStatefulWidget {
  const _ResultsTab();

  @override
  ConsumerState<_ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends ConsumerState<_ResultsTab> {
  String? _selectedExamId;

  @override
  Widget build(BuildContext context) {
    final currentStudentAsync = ref.watch(currentStudentProvider);
    final examsAsync = ref.watch(examsProvider(const ExamsFilter(publishedOnly: true)));

    return examsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (exams) {
        if (exams.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No exam results available'),
              ],
            ),
          );
        }

        final currentExamId = _selectedExamId ?? exams.first.id;

        return currentStudentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading student: $e')),
          data: (student) {
            if (student == null) {
              return const Center(child: Text('Student profile not found'));
            }

            final performanceAsync = ref.watch(studentPerformanceProvider(
              StudentPerformanceFilter(
                studentId: student.id,
                examId: currentExamId,
              ),
            ));
            final overallRankAsync = ref.watch(studentOverallRankProvider(
              StudentExamFilter(
                studentId: student.id,
                examId: currentExamId,
              ),
            ));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Exam selector
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentExamId,
                      isExpanded: true,
                      items: exams.map((exam) {
                        return DropdownMenuItem<String>(
                          value: exam.id,
                          child: Text(exam.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedExamId = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Overall rank card
                overallRankAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (rank) {
                    if (rank == null) return const SizedBox.shrink();
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      gradient: AppColors.primaryGradient,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emoji_events,
                                color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Overall Performance',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  '${rank.overallPercentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${rank.totalObtained.toInt()} / ${rank.totalMaxMarks.toInt()} marks',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Rank',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Text(
                                '#${rank.classRank}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Subject results
                performanceAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (performance) {
                    if (performance.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No results available for this exam'),
                        ),
                      );
                    }

                    return Column(
                      children: performance.map((p) {
                        final color = p.isPassed ? AppColors.success : AppColors.error;
                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.subjectName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: color.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      '${p.marksObtained.toInt()}/${p.maxMarks.toInt()}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: p.percentage / 100,
                                        backgroundColor:
                                            Colors.grey.withValues(alpha: 0.2),
                                        valueColor:
                                            AlwaysStoppedAnimation(color),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${p.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Analytics Tab
// ---------------------------------------------------------------------------

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStudentAsync = ref.watch(currentStudentProvider);
    final examsAsync = ref.watch(examsProvider(const ExamsFilter(publishedOnly: true)));

    return examsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (exams) {
        if (exams.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No analytics available yet'),
              ],
            ),
          );
        }

        return currentStudentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (student) {
            if (student == null) {
              return const Center(child: Text('Student profile not found'));
            }

            // Use the latest exam for analytics
            final latestExam = exams.first;
            final performanceAsync = ref.watch(studentPerformanceProvider(
              StudentPerformanceFilter(
                studentId: student.id,
                examId: latestExam.id,
              ),
            ));
            final classStatsAsync = ref.watch(classExamStatsProvider(
              ClassStatsFilter(examId: latestExam.id),
            ));
            final rankAsync = ref.watch(studentOverallRankProvider(
              StudentExamFilter(
                studentId: student.id,
                examId: latestExam.id,
              ),
            ));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class rank card
                  rankAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (rank) {
                      if (rank == null) return const SizedBox.shrink();
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        gradient: AppColors.primaryGradient,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.emoji_events,
                                  color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Class Rank',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rank #${rank.classRank}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    latestExam.name,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Subject-wise performance vs class average
                  const Text(
                    'Subject-wise Performance',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  performanceAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (performance) {
                      return classStatsAsync.when(
                        loading: () => Column(
                          children: performance.map((p) {
                            return _SubjectPerformanceCard(
                              subject: p.subjectName,
                              score: p.percentage,
                              classAvg: null,
                            );
                          }).toList(),
                        ),
                        error: (_, __) => Column(
                          children: performance.map((p) {
                            return _SubjectPerformanceCard(
                              subject: p.subjectName,
                              score: p.percentage,
                              classAvg: null,
                            );
                          }).toList(),
                        ),
                        data: (classStats) {
                          return Column(
                            children: performance.map((p) {
                              final stat = classStats
                                  .where((s) => s.subjectName == p.subjectName)
                                  .firstOrNull;
                              return _SubjectPerformanceCard(
                                subject: p.subjectName,
                                score: p.percentage,
                                classAvg: stat?.classAverage,
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),

                  // Exam history summary
                  if (exams.length > 1) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Exam History',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ...exams.take(5).map((exam) {
                      final examRankAsync = ref.watch(studentOverallRankProvider(
                        StudentExamFilter(
                          studentId: student.id,
                          examId: exam.id,
                        ),
                      ));
                      return examRankAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (rank) {
                          if (rank == null) return const SizedBox.shrink();
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exam.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      if (exam.startDate != null)
                                        Text(
                                          DateFormat('MMM yyyy')
                                              .format(exam.startDate!),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${rank.overallPercentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: rank.overallPercentage >= 50
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                    Text(
                                      'Rank #${rank.classRank}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Widgets
// ---------------------------------------------------------------------------

class _ExamCard extends StatelessWidget {
  final dynamic exam;
  final String status;

  const _ExamCard({required this.exam, required this.status});

  @override
  Widget build(BuildContext context) {
    final isOngoing = status == 'ongoing';
    final isCompleted = status == 'completed';

    Color statusColor;
    String statusLabel;
    if (isOngoing) {
      statusColor = AppColors.success;
      statusLabel = 'Ongoing';
    } else if (isCompleted) {
      statusColor = Colors.grey;
      statusLabel = 'Completed';
    } else {
      statusColor = AppColors.info;
      statusLabel = 'Upcoming';
    }

    String dateRange = '';
    if (exam.startDate != null && exam.endDate != null) {
      dateRange = '${DateFormat('MMM d').format(exam.startDate!)} – '
          '${DateFormat('MMM d, yyyy').format(exam.endDate!)}';
    } else if (exam.startDate != null) {
      dateRange = DateFormat('MMM d, yyyy').format(exam.startDate!);
    }

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
                  exam.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor),
                ),
              ),
            ],
          ),
          if (dateRange.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(dateRange,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ],
          if (exam.description != null && exam.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exam.description!,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectPerformanceCard extends StatelessWidget {
  final String subject;
  final double score;
  final double? classAvg;

  const _SubjectPerformanceCard({
    required this.subject,
    required this.score,
    this.classAvg,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor =
        classAvg == null ? Colors.grey : score >= classAvg! ? AppColors.success : AppColors.error;
    final trendIcon = classAvg == null
        ? Icons.trending_flat
        : score >= classAvg!
            ? Icons.trending_up
            : Icons.trending_down;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(subject,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                  score >= 50 ? AppColors.success : AppColors.error),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text('${score.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Icon(trendIcon, color: trendColor, size: 20),
        ],
      ),
    );
  }
}
