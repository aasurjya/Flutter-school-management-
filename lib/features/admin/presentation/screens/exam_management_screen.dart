import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/academic.dart';
import '../../../../data/models/exam_statistics.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../exams/providers/exams_provider.dart';

/// Admin Exam Management — wired to real Supabase via [examsNotifierProvider].
///
/// Tabs:
///   - All Exams: every exam for the current academic year.
///   - Upcoming: exams whose start_date is in the future.
///   - Results: published exams (`is_published = true`).
class ExamManagementScreen extends ConsumerStatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  ConsumerState<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends ConsumerState<ExamManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(examsNotifierProvider.notifier).loadExams();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(examsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(examsNotifierProvider.notifier).loadExams(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Exams'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Results'),
          ],
        ),
      ),
      body: examsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: 'Could not load exams. $e',
          onRetry: () => ref.read(examsNotifierProvider.notifier).loadExams(),
        ),
        data: (exams) {
          final upcoming = exams.where(_isUpcoming).toList();
          final published = exams.where((e) => e.isPublished).toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _ExamsList(
                exams: exams,
                onTap: _showExamDetail,
                emptyMessage: 'No exams yet. Tap "Create exam" to schedule one.',
              ),
              _ExamsList(
                exams: upcoming,
                onTap: _showExamDetail,
                emptyMessage: 'No upcoming exams scheduled.',
              ),
              _ResultsList(
                exams: exams,
                publishedExams: published,
                onPublish: _confirmPublish,
                onUnpublish: _confirmUnpublish,
                onView: _showExamDetail,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateExamSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Create exam'),
      ),
    );
  }

  bool _isUpcoming(Exam e) {
    final start = e.startDate;
    if (start == null) return false;
    return start.isAfter(DateTime.now());
  }

  void _showExamDetail(Exam exam) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExamDetailSheet(
        exam: exam,
        onEdit: () {
          Navigator.pop(context);
          _showEditExamSheet(exam);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(exam);
        },
        onPublish: () {
          Navigator.pop(context);
          _confirmPublish(exam);
        },
        onUnpublish: () {
          Navigator.pop(context);
          _confirmUnpublish(exam);
        },
        onConfigureSubjects: () {
          Navigator.pop(context);
          _showConfigureSubjects(exam);
        },
        onSchedule: () {
          Navigator.pop(context);
          _showSchedule(exam);
        },
      ),
    );
  }

  void _showCreateExamSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ExamFormSheet(),
    );
  }

  void _showEditExamSheet(Exam exam) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExamFormSheet(existing: exam),
    );
  }

  void _showConfigureSubjects(Exam exam) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfigureSubjectsSheet(examId: exam.id),
    );
  }

  void _showSchedule(Exam exam) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleSheet(examId: exam.id),
    );
  }

  Future<void> _confirmDelete(Exam exam) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete exam?'),
        content: Text(
          '"${exam.name}" and all associated subject configurations will be removed. '
          'Marks already entered will be deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.error,
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(examsNotifierProvider.notifier).deleteExam(exam.id);
      if (!mounted) return;
      context.showSuccessSnackBar('Exam deleted');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Could not delete: $e');
    }
  }

  Future<void> _confirmPublish(Exam exam) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish results?'),
        content: Text(
          'Publish "${exam.name}" results. Students and parents will be able to view marks. '
          'You can unpublish later if needed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(examsNotifierProvider.notifier).publishExam(exam.id);
      if (!mounted) return;
      context.showSuccessSnackBar('Results published');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Could not publish: $e');
    }
  }

  Future<void> _confirmUnpublish(Exam exam) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpublish results?'),
        content: Text(
          'Hide "${exam.name}" results from students and parents.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unpublish'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(examsNotifierProvider.notifier).unpublishExam(exam.id);
      if (!mounted) return;
      context.showSuccessSnackBar('Results hidden');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Could not unpublish: $e');
    }
  }
}

// ===========================================================================
// Lists
// ===========================================================================

class _ExamsList extends StatelessWidget {
  const _ExamsList({
    required this.exams,
    required this.onTap,
    required this.emptyMessage,
  });
  final List<Exam> exams;
  final void Function(Exam) onTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return _EmptyState(message: emptyMessage);
    }
    return RefreshIndicator.adaptive(
      onRefresh: () async {
        // List rebuilds via watch in parent; pull-to-refresh is a stub.
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final exam = exams[index];
          return _ExamCard(exam: exam, onTap: () => onTap(exam));
        },
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.exams,
    required this.publishedExams,
    required this.onPublish,
    required this.onUnpublish,
    required this.onView,
  });
  final List<Exam> exams;
  final List<Exam> publishedExams;
  final void Function(Exam) onPublish;
  final void Function(Exam) onUnpublish;
  final void Function(Exam) onView;

  @override
  Widget build(BuildContext context) {
    final completable = exams.where((e) {
      final end = e.endDate;
      return end != null && end.isBefore(DateTime.now()) && !e.isPublished;
    }).toList();

    if (completable.isEmpty && publishedExams.isEmpty) {
      return const _EmptyState(
        message:
            'Once an exam ends and marks are entered, you can publish results here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (completable.isNotEmpty) ...[
          const _SectionLabel(label: 'Ready to publish'),
          ...completable.map((e) => _ResultRow(
                exam: e,
                published: false,
                onPrimary: () => onPublish(e),
                onTap: () => onView(e),
              )),
          const SizedBox(height: 16),
        ],
        if (publishedExams.isNotEmpty) ...[
          const _SectionLabel(label: 'Published'),
          ...publishedExams.map((e) => _ResultRow(
                exam: e,
                published: true,
                onPrimary: () => onUnpublish(e),
                onTap: () => onView(e),
              )),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 0.6,
          ),
        ),
      );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.exam,
    required this.published,
    required this.onPrimary,
    required this.onTap,
  });
  final Exam exam;
  final bool published;
  final VoidCallback onPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      exam.examTypeDisplay,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (published)
                OutlinedButton(
                  onPressed: onPrimary,
                  child: const Text('Unpublish'),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: onPrimary,
                  child: const Text('Publish'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}

// ===========================================================================
// Exam card
// ===========================================================================

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onTap});
  final Exam exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(exam);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exam.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: status.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _dateRangeLabel(exam.startDate, exam.endDate),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exam.examTypeDisplay,
                      style: const TextStyle(fontSize: 11, color: AppColors.info),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (exam.isPublished)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Published',
                        style: TextStyle(fontSize: 11, color: AppColors.success),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Status {
  const _Status(this.label, this.color);
  final String label;
  final Color color;
}

_Status _statusFor(Exam exam) {
  final start = exam.startDate;
  final end = exam.endDate;
  if (start == null) {
    return const _Status('Draft', Colors.grey);
  }
  final now = DateTime.now();
  if (exam.isPublished) {
    return const _Status('Published', AppColors.success);
  }
  if (end != null && end.isBefore(now)) {
    return const _Status('Awaiting results', AppColors.warning);
  }
  if (start.isAfter(now)) {
    return const _Status('Upcoming', AppColors.info);
  }
  return const _Status('Ongoing', AppColors.warning);
}

String _dateRangeLabel(DateTime? start, DateTime? end) {
  if (start == null) return 'Dates not set';
  final s = DateFormat('MMM d').format(start);
  if (end == null) return s;
  return '$s — ${DateFormat('MMM d, yyyy').format(end)}';
}

// ===========================================================================
// Detail sheet
// ===========================================================================

class _ExamDetailSheet extends ConsumerWidget {
  const _ExamDetailSheet({
    required this.exam,
    required this.onEdit,
    required this.onDelete,
    required this.onPublish,
    required this.onUnpublish,
    required this.onConfigureSubjects,
    required this.onSchedule,
  });

  final Exam exam;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onConfigureSubjects;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(examSubjectsProvider(exam.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exam.examTypeDisplay} · ${_dateRangeLabel(exam.startDate, exam.endDate)}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.primary),
                    title: const Text('Edit exam'),
                    subtitle: const Text('Change name, type, or dates'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onEdit,
                  ),
                  ListTile(
                    leading: const Icon(Icons.subject, color: AppColors.accent),
                    title: const Text('Configure subjects'),
                    subtitle: Text(
                      subjectsAsync.maybeWhen(
                        data: (subs) =>
                            subs.isEmpty ? 'No subjects yet' : '${subs.length} configured',
                        orElse: () => 'Tap to manage',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onConfigureSubjects,
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule, color: Colors.deepOrange),
                    title: const Text('Schedule'),
                    subtitle: Text(
                      subjectsAsync.maybeWhen(
                        data: (subs) {
                          final scheduled = subs.where((s) => s.examDate != null).length;
                          if (subs.isEmpty) return 'Add subjects first';
                          return '$scheduled of ${subs.length} scheduled';
                        },
                        orElse: () => 'Tap to set dates and times',
                      ),
                    ),
                    enabled: subjectsAsync.maybeWhen(
                      data: (subs) => subs.isNotEmpty,
                      orElse: () => true,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: subjectsAsync.maybeWhen(
                      data: (subs) => subs.isEmpty ? null : onSchedule,
                      orElse: () => onSchedule,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.grade, color: AppColors.info),
                    title: const Text('Enter marks'),
                    subtitle: const Text('Per subject mark entry'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/exams/${exam.id}/marks');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights, color: AppColors.secondary),
                    title: const Text('Analytics'),
                    subtitle: const Text('Pass rate, averages, toppers'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/exams/${exam.id}/analytics');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: const Text('Generate report cards'),
                    subtitle: const Text('Bulk-build cards from this exam'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        '${AppRoutes.reportCardGenerate}?examId=${exam.id}',
                      );
                    },
                  ),
                  const Divider(),
                  if (exam.isPublished)
                    ListTile(
                      leading: const Icon(Icons.visibility_off,
                          color: AppColors.warning),
                      title: const Text('Unpublish results'),
                      subtitle: const Text('Hide from students and parents'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onUnpublish,
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.publish, color: AppColors.success),
                      title: const Text('Publish results'),
                      subtitle: const Text('Share results with students and parents'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onPublish,
                    ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.error),
                    title: const Text(
                      'Delete exam',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Create / edit exam sheet
// ===========================================================================

const _examTypes = <_ExamTypeOption>[
  _ExamTypeOption('unit_test', 'Unit Test'),
  _ExamTypeOption('mid_term', 'Mid Term'),
  _ExamTypeOption('final', 'Final / Annual'),
  _ExamTypeOption('assignment', 'Assignment'),
  _ExamTypeOption('practical', 'Practical'),
  _ExamTypeOption('project', 'Project'),
];

class _ExamTypeOption {
  const _ExamTypeOption(this.value, this.label);
  final String value;
  final String label;
}

class _ExamFormSheet extends ConsumerStatefulWidget {
  const _ExamFormSheet({this.existing});
  final Exam? existing;

  @override
  ConsumerState<_ExamFormSheet> createState() => _ExamFormSheetState();
}

class _ExamFormSheetState extends ConsumerState<_ExamFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _examType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _examType = e?.examType ?? 'unit_test';
    _startDate = e?.startDate;
    _endDate = e?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: mq.size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Text(
                    _isEdit ? 'Edit exam' : 'Create exam',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Exam name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _examType,
                        decoration: const InputDecoration(
                          labelText: 'Exam type',
                          border: OutlineInputBorder(),
                        ),
                        items: _examTypes
                            .map((t) => DropdownMenuItem(
                                  value: t.value,
                                  child: Text(t.label),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _examType = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Start date *',
                              value: _startDate,
                              onPick: (d) => setState(() => _startDate = d),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DateField(
                              label: 'End date *',
                              value: _endDate,
                              onPick: (d) => setState(() => _endDate = d),
                              firstDate: _startDate ??
                                  DateTime.now()
                                      .subtract(const Duration(days: 365)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isEdit ? 'Save changes' : 'Create exam'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      context.showErrorSnackBar('Pick start and end dates');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      context.showErrorSnackBar('End date cannot be before start date');
      return;
    }

    final yearAsync = ref.read(currentAcademicYearProvider);
    final year = yearAsync.value;
    if (year == null) {
      context.showErrorSnackBar(
        'No current academic year set. Configure one under Classes first.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final payload = <String, dynamic>{
      'academic_year_id': year.id,
      'name': _nameController.text.trim(),
      'exam_type': _examType,
      'start_date': _startDate!.toIso8601String(),
      'end_date': _endDate!.toIso8601String(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    };
    try {
      if (_isEdit) {
        await ref
            .read(examsNotifierProvider.notifier)
            .updateExam(widget.existing!.id, payload);
      } else {
        await ref.read(examsNotifierProvider.notifier).createExam(payload);
      }
      if (!mounted) return;
      Navigator.pop(context);
      context.showSuccessSnackBar(_isEdit ? 'Exam updated' : 'Exam created');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.showErrorSnackBar('Could not save: $e');
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.firstDate,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final DateTime firstDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: firstDate,
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value != null ? DateFormat('MMM d, yyyy').format(value!) : 'Select',
        ),
      ),
    );
  }
}

// ===========================================================================
// Configure subjects sheet
// ===========================================================================

class _ConfigureSubjectsSheet extends ConsumerWidget {
  const _ConfigureSubjectsSheet({required this.examId});
  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(examSubjectsProvider(examId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Configure subjects',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: subjectsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Could not load subjects. $e'),
                ),
                data: (subjects) => ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: subjects.length + 1,
                  itemBuilder: (context, index) {
                    if (index == subjects.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddSubjectForm(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Add subject'),
                        ),
                      );
                    }
                    final s = subjects[index];
                    return _ExamSubjectTile(
                      subject: s,
                      onDelete: () async {
                        try {
                          await ref
                              .read(examRepositoryProvider)
                              .deleteExamSubject(s.id);
                          ref.invalidate(examSubjectsProvider(examId));
                          if (!context.mounted) return;
                          context.showSuccessSnackBar('Subject removed');
                        } catch (e) {
                          if (!context.mounted) return;
                          context.showErrorSnackBar('Could not remove: $e');
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExamSubjectSheet(examId: examId),
    );
  }
}

class _ExamSubjectTile extends StatelessWidget {
  const _ExamSubjectTile({required this.subject, required this.onDelete});
  final ExamSubject subject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          subject.subjectName ?? 'Subject',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (subject.className != null) subject.className!,
            'Max ${subject.maxMarks.toStringAsFixed(0)} · Pass ${subject.passingMarks.toStringAsFixed(0)}',
            if (subject.examDate != null)
              DateFormat('MMM d').format(subject.examDate!),
          ].join(' · '),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          tooltip: 'Remove',
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _AddExamSubjectSheet extends ConsumerStatefulWidget {
  const _AddExamSubjectSheet({required this.examId});
  final String examId;

  @override
  ConsumerState<_AddExamSubjectSheet> createState() => _AddExamSubjectSheetState();
}

class _AddExamSubjectSheetState extends ConsumerState<_AddExamSubjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _maxMarksController = TextEditingController(text: '100');
  final _passingController = TextEditingController(text: '35');
  String? _subjectId;
  String? _classId;
  DateTime? _examDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _maxMarksController.dispose();
    _passingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final classesAsync = ref.watch(classesProvider);
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: mq.size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add subject',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SubjectDropdown(
                        async: subjectsAsync,
                        value: _subjectId,
                        onChanged: (v) => setState(() => _subjectId = v),
                      ),
                      const SizedBox(height: 16),
                      _ClassDropdown(
                        async: classesAsync,
                        value: _classId,
                        onChanged: (v) => setState(() => _classId = v),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _maxMarksController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Max marks *',
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateNumber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _passingController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Passing marks *',
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateNumber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DateField(
                        label: 'Exam date (optional)',
                        value: _examDate,
                        onPick: (d) => setState(() => _examDate = d),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365)),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Add subject'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null || n <= 0) return 'Enter a positive number';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjectId == null) {
      context.showErrorSnackBar('Pick a subject');
      return;
    }
    if (_classId == null) {
      context.showErrorSnackBar('Pick a class');
      return;
    }
    final maxMarks = double.parse(_maxMarksController.text.trim());
    final passing = double.parse(_passingController.text.trim());
    if (passing > maxMarks) {
      context.showErrorSnackBar('Passing marks cannot exceed max marks');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(examRepositoryProvider).createExamSubject({
        'exam_id': widget.examId,
        'subject_id': _subjectId,
        'class_id': _classId,
        'max_marks': maxMarks,
        'passing_marks': passing,
        if (_examDate != null) 'exam_date': _examDate!.toIso8601String(),
      });
      ref.invalidate(examSubjectsProvider(widget.examId));
      if (!mounted) return;
      Navigator.pop(context);
      context.showSuccessSnackBar('Subject added');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.showErrorSnackBar('Could not add: $e');
    }
  }
}

class _SubjectDropdown extends StatelessWidget {
  const _SubjectDropdown({
    required this.async,
    required this.value,
    required this.onChanged,
  });
  final AsyncValue<List<Subject>> async;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Subjects unavailable: $e'),
      data: (items) {
        if (items.isEmpty) {
          return const Text(
            'No subjects yet. Add subjects under Classes first.',
            style: TextStyle(color: AppColors.error),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(
            labelText: 'Subject *',
            border: OutlineInputBorder(),
          ),
          items: items
              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }
}

class _ClassDropdown extends StatelessWidget {
  const _ClassDropdown({
    required this.async,
    required this.value,
    required this.onChanged,
  });
  final AsyncValue<List<SchoolClass>> async;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Classes unavailable: $e'),
      data: (items) {
        if (items.isEmpty) {
          return const Text(
            'No classes yet. Add classes under Classes first.',
            style: TextStyle(color: AppColors.error),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(
            labelText: 'Class *',
            border: OutlineInputBorder(),
          ),
          items: items
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }
}

// ===========================================================================
// Schedule sheet — per-subject date / start time / end time editor.
//
// Each row in the configured-subjects list becomes a card with three pickers.
// Save updates only the fields the user actually changed, then invalidates
// [examSubjectsProvider] so the detail-sheet counter updates.
// ===========================================================================

class _ScheduleSheet extends ConsumerWidget {
  const _ScheduleSheet({required this.examId});
  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(examSubjectsProvider(examId));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Schedule subjects',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: subjectsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Could not load subjects. $e'),
                ),
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return const _EmptyState(
                      message:
                          'No subjects yet. Add subjects to the exam first.',
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      return _ScheduleRow(
                        key: ValueKey(subjects[index].id),
                        subject: subjects[index],
                        examId: examId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends ConsumerStatefulWidget {
  const _ScheduleRow({
    super.key,
    required this.subject,
    required this.examId,
  });
  final ExamSubject subject;
  final String examId;

  @override
  ConsumerState<_ScheduleRow> createState() => _ScheduleRowState();
}

class _ScheduleRowState extends ConsumerState<_ScheduleRow> {
  late DateTime? _date;
  late String? _startTime;
  late String? _endTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.subject.examDate;
    _startTime = widget.subject.startTime;
    _endTime = widget.subject.endTime;
  }

  bool get _isDirty =>
      _date != widget.subject.examDate ||
      _startTime != widget.subject.startTime ||
      _endTime != widget.subject.endTime;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    TimeOfDay initial = TimeOfDay.now();
    final source = isStart ? _startTime : _endTime;
    if (source != null && source.contains(':')) {
      final parts = source.split(':');
      initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? initial.hour,
        minute: int.tryParse(parts[1]) ?? initial.minute,
      );
    }
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _startTime = formatted;
      } else {
        _endTime = formatted;
      }
    });
  }

  Future<void> _save() async {
    if (_endTime != null && _startTime != null && _endTime!.compareTo(_startTime!) <= 0) {
      context.showErrorSnackBar('End time must be after start time');
      return;
    }
    setState(() => _isSaving = true);
    final payload = <String, dynamic>{};
    if (_date != widget.subject.examDate) {
      payload['exam_date'] = _date?.toIso8601String();
    }
    if (_startTime != widget.subject.startTime) {
      payload['start_time'] = _startTime;
    }
    if (_endTime != widget.subject.endTime) {
      payload['end_time'] = _endTime;
    }
    try {
      await ref
          .read(examRepositoryProvider)
          .updateExamSubject(widget.subject.id, payload);
      ref.invalidate(examSubjectsProvider(widget.examId));
      if (!mounted) return;
      context.showSuccessSnackBar('Schedule saved');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Could not save: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject.subjectName ?? 'Subject',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (subject.className != null) subject.className!,
              'Max ${subject.maxMarks.toStringAsFixed(0)}',
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          _SchedField(
            label: 'Date',
            value: _date != null
                ? DateFormat('MMM d, yyyy').format(_date!)
                : null,
            onTap: _pickDate,
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SchedField(
                  label: 'Start',
                  value: _startTime,
                  onTap: () => _pickTime(isStart: true),
                  icon: Icons.access_time,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SchedField(
                  label: 'End',
                  value: _endTime,
                  onTap: () => _pickTime(isStart: false),
                  icon: Icons.access_time_filled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isDirty)
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _date = widget.subject.examDate;
                            _startTime = widget.subject.startTime;
                            _endTime = widget.subject.endTime;
                          });
                        },
                  child: const Text('Reset'),
                ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: (_isDirty && !_isSaving) ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SchedField extends StatelessWidget {
  const _SchedField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.icon,
  });
  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon, size: 18),
          isDense: true,
        ),
        child: Text(
          value ?? '—',
          style: TextStyle(
            color: value == null ? Colors.grey[500] : null,
          ),
        ),
      ),
    );
  }
}
