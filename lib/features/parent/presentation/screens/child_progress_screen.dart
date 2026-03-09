import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../data/models/invoice.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../fees/providers/fees_provider.dart';
import '../../providers/parent_engagement_provider.dart';

/// Comprehensive view of ONE child's academic progress.
class ChildProgressScreen extends ConsumerStatefulWidget {
  final String childId;
  final String? childName;

  const ChildProgressScreen({
    super.key,
    required this.childId,
    this.childName,
  });

  @override
  ConsumerState<ChildProgressScreen> createState() =>
      _ChildProgressScreenState();
}

class _ChildProgressScreenState extends ConsumerState<ChildProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync =
        ref.watch(childProgressSummaryProvider(widget.childId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: summaryAsync.when(
        loading: () => const _LoadingScaffold(),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Child Progress')),
          body: AppErrorWidget(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(childProgressSummaryProvider(widget.childId)),
          ),
        ),
        data: (summary) => _ProgressBody(
          summary: summary,
          childId: widget.childId,
          tabs: _tabs,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _ProgressBody extends StatelessWidget {
  final ChildProgressSummary summary;
  final String childId;
  final TabController tabs;

  const _ProgressBody({
    required this.summary,
    required this.childId,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxScrolled) => [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: _ChildHeader(summary: summary),
          ),
          bottom: TabBar(
            controller: tabs,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Academics'),
              Tab(text: 'Attendance'),
              Tab(text: 'Behaviour'),
              Tab(text: 'Fees'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: tabs,
        children: [
          _OverviewTab(summary: summary, childId: childId),
          _AcademicsTab(childId: childId),
          _AttendanceTab(childId: childId),
          _BehaviourTab(childId: childId),
          _FeesTab(childId: childId),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header (inside SliverAppBar)
// ---------------------------------------------------------------------------

class _ChildHeader extends StatelessWidget {
  final ChildProgressSummary summary;

  const _ChildHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              image: summary.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(summary.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: summary.photoUrl == null
                ? Center(
                    child: Text(
                      summary.studentName.isNotEmpty
                          ? summary.studentName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  summary.studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.className} - ${summary.sectionName}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Roll No: ${summary.rollNumber}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
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

// ---------------------------------------------------------------------------
// 3-stat strip (no containers — just Row with Expanded)
// ---------------------------------------------------------------------------

class _StatStrip extends StatelessWidget {
  final double attendancePct;
  final double averagePct;
  final int points;

  const _StatStrip({
    required this.attendancePct,
    required this.averagePct,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(
          label: 'Attendance',
          value: '${attendancePct.toStringAsFixed(1)}%',
          icon: Icons.calendar_today,
          color: AppColors.success,
        ),
        _VertDivider(),
        _StatCell(
          label: 'Average',
          value: '${averagePct.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: AppColors.primary,
        ),
        _VertDivider(),
        _StatCell(
          label: 'Points',
          value: '$points',
          icon: Icons.star_rounded,
          color: AppColors.accent,
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 48, color: AppColors.grey200);
  }
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  final ChildProgressSummary summary;
  final String childId;

  const _OverviewTab({required this.summary, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marksAsync = ref.watch(childSubjectMarksProvider(childId));
    final attendanceAsync = ref.watch(childAttendanceProvider(childId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3-stat strip
          GlassCard(
            padding: EdgeInsets.zero,
            child: _StatStrip(
              attendancePct: summary.attendancePercentage,
              averagePct: summary.averagePercentage,
              points: summary.totalPoints,
            ),
          ),
          const SizedBox(height: 20),

          // Subject performance horizontal scroll
          const Text(
            'Subject Performance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          marksAsync.when(
            loading: () =>
                const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (marks) => SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: marks.length,
                itemBuilder: (context, i) => _SubjectCard(mark: marks[i]),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Recent activity feed
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          attendanceAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (records) {
              final recent = records.take(5).toList();
              if (recent.isEmpty) {
                return const Text(
                  'No recent attendance records',
                  style: TextStyle(color: AppColors.grey500),
                );
              }
              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(recent.length, (i) {
                    final rec = recent[i];
                    final isLast = i == recent.length - 1;
                    final statusColor = AppColors.attendanceStatusColor(rec.status);
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Timeline dot + line
                          Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: AppColors.grey200,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat('EEE, MMM d').format(rec.date),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  StatusChip.fromString(rec.status),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Upcoming section
          const Text(
            'Upcoming',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const GlassCard(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _UpcomingRow(
                  icon: Icons.quiz_outlined,
                  label: 'Next Exam',
                  value: 'Mid-Term — Mar 15',
                  color: AppColors.primary,
                ),
                Divider(height: 20),
                _UpcomingRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Fee Due',
                  value: '₹20,000 — Mar 31',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectMark mark;

  const _SubjectCard({required this.mark});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.gradeColor(mark.grade);
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            mark.subjectName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: mark.percentage / 100,
              minHeight: 6,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${mark.percentage.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mark.grade,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _UpcomingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Academics Tab
// ---------------------------------------------------------------------------

class _AcademicsTab extends ConsumerStatefulWidget {
  final String childId;

  const _AcademicsTab({required this.childId});

  @override
  ConsumerState<_AcademicsTab> createState() => _AcademicsTabState();
}

class _AcademicsTabState extends ConsumerState<_AcademicsTab> {
  String _selectedTerm = 'Term 2';
  final List<String> _terms = ['Term 1', 'Term 2', 'Term 3'];

  @override
  Widget build(BuildContext context) {
    final marksAsync = ref.watch(childSubjectMarksProvider(widget.childId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Term selector
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTerm,
                isExpanded: true,
                items: _terms
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedTerm = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          marksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorWidget(
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(childSubjectMarksProvider(widget.childId)),
            ),
            data: (marks) {
              if (marks.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No marks available'),
                  ),
                );
              }

              // Calculate overall
              final totalObtained = marks.fold<double>(0, (s, m) => s + m.marksObtained);
              final totalMax = marks.fold<double>(0, (s, m) => s + m.maxMarks);
              final overallPct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0;
              final overallGrade = gradeFromPct(overallPct.toDouble());

              return Column(
                children: [
                  // Marks table
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                  flex: 4,
                                  child: Text('Subject',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.grey600))),
                              Expanded(
                                  flex: 2,
                                  child: Text('Marks',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.grey600))),
                              Expanded(
                                  flex: 2,
                                  child: Text('%',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.grey600))),
                              Expanded(
                                  flex: 1,
                                  child: Text('Gr.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.grey600))),
                            ],
                          ),
                        ),
                        ...marks.asMap().entries.map((entry) {
                          final i = entry.key;
                          final m = entry.value;
                          final gradeColor = AppColors.gradeColor(m.grade);
                          return Container(
                            color: i.isEven
                                ? Colors.transparent
                                : AppColors.grey50,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(m.subjectName,
                                      style:
                                          const TextStyle(fontSize: 13)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${m.marksObtained.toInt()}/${m.maxMarks.toInt()}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${m.percentage.toStringAsFixed(1)}%',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: gradeColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    m.grade,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: gradeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Overall GPA
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Overall Performance',
                                  style: TextStyle(
                                      fontSize: 14, color: AppColors.grey500)),
                              const SizedBox(height: 4),
                              Text(
                                '${overallPct.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '${totalObtained.toInt()} / ${totalMax.toInt()} marks',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.grey400),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.gradeColor(overallGrade)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              overallGrade,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gradeColor(overallGrade),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance Tab
// ---------------------------------------------------------------------------

class _AttendanceTab extends ConsumerWidget {
  final String childId;

  const _AttendanceTab({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(childAttendanceProvider(childId));

    return attendanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(childAttendanceProvider(childId)),
      ),
      data: (records) {
        final present =
            records.where((r) => r.status.toLowerCase() == 'present').length;
        final absent =
            records.where((r) => r.status.toLowerCase() == 'absent').length;
        final late =
            records.where((r) => r.status.toLowerCase() == 'late').length;
        final total = records.length;
        final pct = total > 0 ? (present / total) * 100 : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats row
              Row(
                children: [
                  _AttStat(label: 'Present', count: present, color: AppColors.present),
                  const SizedBox(width: 10),
                  _AttStat(label: 'Absent', count: absent, color: AppColors.absent),
                  const SizedBox(width: 10),
                  _AttStat(label: 'Late', count: late, color: AppColors.late),
                ],
              ),
              const SizedBox(height: 12),

              // Monthly percentage
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monthly Attendance',
                              style: TextStyle(
                                  color: AppColors.grey500, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            '$present of $total days',
                            style: const TextStyle(
                                color: AppColors.grey400, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: pct / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation(
                          pct >= 75 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Attendance Log',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Monthly calendar-style grid
              _AttendanceCalendar(records: records),
              const SizedBox(height: 20),

              // Legend
              const Wrap(
                spacing: 16,
                children: [
                  _LegendItem(color: AppColors.present, label: 'Present'),
                  _LegendItem(color: AppColors.absent, label: 'Absent'),
                  _LegendItem(color: AppColors.late, label: 'Late'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _AttStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AttStat(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.grey500)),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCalendar extends StatelessWidget {
  final List<AttendanceDay> records;

  const _AttendanceCalendar({required this.records});

  @override
  Widget build(BuildContext context) {
    // Build a map of date → status
    final map = <String, String>{
      for (final r in records)
        DateFormat('yyyy-MM-dd').format(r.date): r.status,
    };

    // Show the last 30 days
    final today = DateTime.now();
    final days = List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: days.map((day) {
          final key = DateFormat('yyyy-MM-dd').format(day);
          final status = map[key];
          final isWeekend =
              day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

          Color dotColor;
          if (isWeekend) {
            dotColor = AppColors.grey200;
          } else if (status == null) {
            dotColor = AppColors.grey100;
          } else {
            dotColor = AppColors.attendanceStatusColor(status);
          }

          return Tooltip(
            message: DateFormat('MMM d').format(day),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: isWeekend ? 0.4 : 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isWeekend ? AppColors.grey400 : dotColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Behaviour Tab
// ---------------------------------------------------------------------------

class _BehaviourTab extends ConsumerWidget {
  final String childId;

  const _BehaviourTab({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final behaviourAsync = ref.watch(childBehaviourProvider(childId));

    return behaviourAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(childBehaviourProvider(childId)),
      ),
      data: (records) {
        final totalPoints =
            records.fold<int>(0, (s, r) => s + r.points);
        final badges = records.where((r) => r.type == 'badge').toList();
        final events = records.where((r) => r.type != 'badge').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total points card
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded,
                          color: AppColors.accent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Points',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.grey500)),
                        Text(
                          '$totalPoints pts',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (badges.isNotEmpty) ...[
                const Text('Badges Earned',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: badges.length,
                    itemBuilder: (context, i) => _BadgeCard(record: badges[i]),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Text('Recent Activities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              ...events.map((r) => _BehaviourRow(record: r)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BehaviourRecord record;

  const _BadgeCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 26),
          const SizedBox(height: 4),
          Text(
            record.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BehaviourRow extends StatelessWidget {
  final BehaviourRecord record;

  const _BehaviourRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final isPositive = record.points >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    final icon = record.type == 'incident'
        ? Icons.warning_amber_rounded
        : Icons.check_circle_rounded;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  DateFormat('MMM d, yyyy').format(record.date),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.grey400),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${record.points} pts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fees Tab
// ---------------------------------------------------------------------------

class _FeesTab extends ConsumerWidget {
  final String childId;

  const _FeesTab({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(
      invoicesProvider(InvoicesFilter(studentId: childId)),
    );
    final paymentsAsync = ref.watch(
      paymentsProvider(PaymentsFilter(studentId: childId)),
    );

    return invoicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(invoicesProvider(InvoicesFilter(studentId: childId))),
      ),
      data: (invoices) {
        final pending =
            invoices.where((inv) => !inv.isPaid && !inv.isCancelled).toList();
        final paid = invoices.where((inv) => inv.isPaid).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pending.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48,
                            color: AppColors.success.withValues(alpha: 0.7)),
                        const SizedBox(height: 12),
                        const Text('All fees are paid!',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              else ...[
                const Text('Outstanding Invoices',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...pending.map((inv) => _InvoiceCard(invoice: inv, childId: childId)),
              ],

              if (paid.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Payment History',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                paymentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (payments) => Column(
                    children: payments.map((p) {
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.check_circle,
                                  color: AppColors.success, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(p.paymentNumber,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13)),
                                  Text(
                                    p.paidAt != null
                                        ? DateFormat('MMM d, yyyy')
                                            .format(p.paidAt!)
                                        : 'Completed',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.grey400),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${p.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String childId;

  const _InvoiceCard({required this.invoice, required this.childId});

  @override
  Widget build(BuildContext context) {
    final isOverdue = invoice.isOverdueNow;
    final dueAmount = invoice.pendingAmount;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              if (isOverdue)
                StatusChip.fromString('overdue')
              else
                StatusChip.fromString('pending'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Due: ${DateFormat('MMM d, yyyy').format(invoice.dueDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverdue ? AppColors.error : AppColors.grey500,
                ),
              ),
              Text(
                '₹${dueAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(
                '/parent/child/$childId/fees',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Pay Now',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading scaffold
// ---------------------------------------------------------------------------

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Progress'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
