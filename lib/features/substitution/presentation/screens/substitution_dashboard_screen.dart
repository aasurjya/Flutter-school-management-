import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/substitution.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/substitution_provider.dart';

// ============================================================
// SubstitutionDashboardScreen — admin + teacher view
// Three tabs: Absences & AI | Final Schedule | My Duties (teacher)
// ============================================================

class SubstitutionDashboardScreen extends ConsumerStatefulWidget {
  const SubstitutionDashboardScreen({super.key});

  @override
  ConsumerState<SubstitutionDashboardScreen> createState() =>
      _SubstitutionDashboardScreenState();
}

class _SubstitutionDashboardScreenState
    extends ConsumerState<SubstitutionDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

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
    final currentUser = ref.watch(currentUserProvider);
    final dateLabel = _isToday(_selectedDate)
        ? 'Today'
        : DateFormat('d MMM').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Substitutions — $dateLabel'),
        actions: [
          // Previous day
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous day',
            onPressed: () => setState(() {
              _selectedDate =
                  _selectedDate.subtract(const Duration(days: 1));
            }),
          ),
          // Next day
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next day',
            onPressed: () => setState(() {
              _selectedDate =
                  _selectedDate.add(const Duration(days: 1));
            }),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pick date',
            onPressed: _pickDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Absences & AI'),
            Tab(text: 'Final Schedule'),
            Tab(text: 'My Duties'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AbsencesTab(date: _selectedDate),
          _AssignmentsTab(date: _selectedDate),
          _MyDutiesTab(teacherId: currentUser?.id),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _refresh() {
    ref.invalidate(teacherAbsencesForDateProvider(_selectedDate));
    ref.invalidate(substitutionAssignmentsProvider(_selectedDate));
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.id != null) {
      ref.invalidate(mySubstituteDutiesProvider(currentUser!.id));
    }
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }
}

// ============================================================
// Tab 1: Absences list + AI suggestions per teacher
// ============================================================

class _AbsencesTab extends ConsumerWidget {
  final DateTime date;
  const _AbsencesTab({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absencesAsync = ref.watch(teacherAbsencesForDateProvider(date));

    return absencesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Failed to load absences',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              '$e',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(teacherAbsencesForDateProvider(date)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (absences) {
        if (absences.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      size: 64, color: AppColors.success),
                ),
                const SizedBox(height: 16),
                const Text(
                  'All teachers present!',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'No absences reported for ${DateFormat("d MMMM").format(date)}.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.reportAbsence),
                  icon: const Icon(Icons.add),
                  label: const Text('Report an Absence'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Summary bar
            Container(
              color: Colors.orange.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.person_off_outlined,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${absences.length} teacher${absences.length == 1 ? "" : "s"} absent',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.reportAbsence),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.orange),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: absences.length,
                itemBuilder: (context, i) =>
                    _AbsenceCard(absence: absences[i], date: date),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// Absence card — expandable with AI suggestions per period
// ============================================================

class _AbsenceCard extends ConsumerStatefulWidget {
  final TeacherAbsence absence;
  final DateTime date;

  const _AbsenceCard({required this.absence, required this.date});

  @override
  ConsumerState<_AbsenceCard> createState() => _AbsenceCardState();
}

class _AbsenceCardState extends ConsumerState<_AbsenceCard> {
  bool _expanded = false;
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final absence = widget.absence;
    final isCancelled = absence.status == AbsenceStatus.cancelled;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Colors.orange.withValues(alpha: 0.15),
                    radius: 22,
                    child: Text(
                      _initials(absence.teacherName ?? '?'),
                      style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          absence.teacherName ?? 'Unknown Teacher',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _SmallChip(
                                absence.leaveType.label, Colors.orange),
                            const SizedBox(width: 6),
                            _SmallChip(
                                absence.status.label,
                                absence.status.color),
                          ],
                        ),
                        if (absence.reason != null &&
                            absence.reason!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            absence.reason!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      if (!isCancelled)
                        const Text(
                          'Find Subs',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Cancel action row
          if (!isCancelled) ...[
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _cancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          onPressed: () => _cancelAbsence(absence),
                          icon: const Icon(Icons.cancel_outlined,
                              size: 14, color: Colors.red),
                          label: const Text('Cancel Absence',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red)),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4)),
                        ),
                ],
              ),
            ),
          ],

          // Expanded — AI suggestions
          if (_expanded && !isCancelled) ...[
            const Divider(height: 1),
            _SuggestionsList(
                absence: absence, date: widget.date),
          ],
        ],
      ),
    );
  }

  Future<void> _cancelAbsence(TeacherAbsence absence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Absence'),
        content: Text(
          'Cancel the absence for ${absence.teacherName ?? "this teacher"} '
          'on ${DateFormat("d MMM yyyy").format(absence.absenceDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text('Cancel Absence'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final repo = ref.read(substitutionRepositoryProvider);
      await repo.updateAbsenceStatus(absence.id, AbsenceStatus.cancelled);
      if (mounted) {
        ref.invalidate(teacherAbsencesForDateProvider(widget.date));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Absence cancelled successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel absence: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _cancelling = false);
      }
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}

// ============================================================
// AI suggestions list for a teacher's periods
// ============================================================

class _SuggestionsList extends ConsumerWidget {
  final TeacherAbsence absence;
  final DateTime date;

  const _SuggestionsList(
      {required this.absence, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = SuggestionParams(
      absentTeacherId: absence.teacherId,
      date: date,
    );
    final suggestionsAsync =
        ref.watch(substituteSuggestionsProvider(params));

    return suggestionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 8),
              Text('Finding best substitutes…',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Could not load suggestions: $e',
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(substituteSuggestionsProvider(params)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (periods) {
        if (periods.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey, size: 16),
                SizedBox(width: 8),
                Text('No periods found for this teacher today.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  const Icon(Icons.auto_fix_high,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${periods.length} period${periods.length == 1 ? "" : "s"} to cover — AI-ranked substitutes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...periods.map((period) => _PeriodSuggestionRow(
                  period: period,
                  absence: absence,
                  date: date,
                )),
          ],
        );
      },
    );
  }
}

// ============================================================
// One period row with top-3 candidates
// ============================================================

class _PeriodSuggestionRow extends ConsumerWidget {
  final SubstitutePeriod period;
  final TeacherAbsence absence;
  final DateTime date;

  const _PeriodSuggestionRow({
    required this.period,
    required this.absence,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top3 = period.candidates.take(3).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  period.slotName,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${period.startTime} – ${period.endTime}',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                '${period.className} • ${period.subjectName ?? "Free"}',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (top3.isEmpty)
            const Text(
              'No free teachers available for this period.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            )
          else
            ...top3.asMap().entries.map((entry) {
              final i = entry.key;
              final candidate = entry.value;
              return _CandidateRow(
                candidate: candidate,
                rank: i + 1,
                isTop: i == 0,
                onAssign: () => _assign(context, ref, candidate),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    SubstituteCandidate candidate,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Assignment'),
        content: Text(
          'Assign ${candidate.teacherName} to cover '
          '${period.subjectName ?? "this class"} for '
          '${period.className} (${period.slotName})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final notifier = ref.read(assignSubstituteProvider.notifier);
    final success = await notifier.assign(
      absenceId: absence.id,
      timetableId: period.timetableId,
      absentTeacherId: absence.teacherId,
      substituteTeacherId: candidate.teacherId,
      slotId: period.slotId,
      sectionId: period.sectionId,
      subjectId: period.subjectId,
      date: date,
      matchScore: candidate.matchScore,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '${candidate.teacherName} assigned for ${period.slotName}'
              : 'Assignment failed. Please try again.'),
          backgroundColor:
              success ? AppColors.success : Colors.red,
        ),
      );
    }
  }
}

// ============================================================
// One candidate row
// ============================================================

class _CandidateRow extends StatelessWidget {
  final SubstituteCandidate candidate;
  final int rank;
  final bool isTop;
  final VoidCallback onAssign;

  const _CandidateRow({
    required this.candidate,
    required this.rank,
    required this.isTop,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isTop
                  ? AppColors.success.withValues(alpha: 0.15)
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isTop ? AppColors.success : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.teacherName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  candidate.matchReason,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Score badge — color-coded percentage container
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:
                  candidate.scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: candidate.scoreColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              '${candidate.matchScore}%',
              style: TextStyle(
                fontSize: 12,
                color: candidate.scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed: onAssign,
              style: ElevatedButton.styleFrom(
                backgroundColor: isTop
                    ? AppColors.success
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(fontSize: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Assign'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Tab 2: Final confirmed assignments for the day
// ============================================================

class _AssignmentsTab extends ConsumerWidget {
  final DateTime date;
  const _AssignmentsTab({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync =
        ref.watch(substitutionAssignmentsProvider(date));

    return assignmentsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Failed to load assignments',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              '$e',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(substitutionAssignmentsProvider(date)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (assignments) {
        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No substitutions assigned yet',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to the Absences & AI tab to assign substitutes.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, i) =>
              _AssignmentTile(assignment: assignments[i]),
        );
      },
    );
  }
}

// ============================================================
// Tab 3: My Duties — substitute duties for the logged-in teacher
// ============================================================

class _MyDutiesTab extends ConsumerWidget {
  final String? teacherId;
  const _MyDutiesTab({required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (teacherId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Not signed in',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Please sign in to view your duties.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final dutiesAsync = ref.watch(mySubstituteDutiesProvider(teacherId!));

    return dutiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Failed to load duties',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              '$e',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(mySubstituteDutiesProvider(teacherId!)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (duties) {
        if (duties.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event_available,
                      size: 64, color: AppColors.success),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No substitute duties',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have no upcoming substitution duties.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header bar
            Container(
              color: AppColors.primary.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${duties.length} duty${duties.length == 1 ? "" : "s"} assigned to you',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: duties.length,
                itemBuilder: (context, i) =>
                    _DutyTile(duty: duties[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// Duty tile — shown in My Duties tab
// ============================================================

class _DutyTile extends StatelessWidget {
  final SubstitutionAssignment duty;
  const _DutyTile({required this.duty});

  @override
  Widget build(BuildContext context) {
    final isUpcoming =
        duty.substitutionDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Date column
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                DateFormat('d').format(duty.substitutionDate),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                DateFormat('MMM').format(duty.substitutionDate),
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(width: 14),
          const VerticalDivider(width: 1),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (duty.slotName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          duty.slotName!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      duty.timeRange,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Covering ${duty.absentTeacherName ?? "absent teacher"}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${duty.className ?? ""} ${duty.sectionName ?? ""}${duty.subjectName != null ? " • ${duty.subjectName}" : ""}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUpcoming
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isUpcoming ? 'Upcoming' : 'Past',
              style: TextStyle(
                color: isUpcoming ? AppColors.primary : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final SubstitutionAssignment assignment;
  const _AssignmentTile({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Time column
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                assignment.slotName ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                assignment.timeRange,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(width: 14),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.substituteTeacherName ?? 'Unknown',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Covering ${assignment.absentTeacherName ?? "absent teacher"}'
                  ' • ${assignment.className ?? ""} ${assignment.sectionName ?? ""}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (assignment.subjectName != null)
                  Text(
                    assignment.subjectName!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.primary),
                  ),
              ],
            ),
          ),
          // Match score — color-coded percentage
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _scoreColor(assignment.matchScore)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _scoreColor(assignment.matchScore)
                      .withValues(alpha: 0.4)),
            ),
            child: Text(
              '${assignment.matchScore}%',
              style: TextStyle(
                color: _scoreColor(assignment.matchScore),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.grey;
  }
}

// ============================================================
// Small helpers
// ============================================================

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}
