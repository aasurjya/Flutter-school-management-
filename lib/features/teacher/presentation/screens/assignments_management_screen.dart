import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/assignment.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../assignments/providers/assignments_provider.dart';

class AssignmentsManagementScreen extends ConsumerStatefulWidget {
  const AssignmentsManagementScreen({super.key});

  @override
  ConsumerState<AssignmentsManagementScreen> createState() => _AssignmentsManagementScreenState();
}

class _AssignmentsManagementScreenState extends ConsumerState<AssignmentsManagementScreen>
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
      appBar: AppBar(
        title: const Text('Assignments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Drafts'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AssignmentsList(filter: AssignmentsFilter(status: 'published')),
          _AssignmentsList(filter: AssignmentsFilter(status: 'draft')),
          _AssignmentsList(filter: AssignmentsFilter(status: 'closed')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAssignmentSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Assignment'),
      ),
    );
  }

  void _showCreateAssignmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateAssignmentSheet(),
    );
  }
}

class _AssignmentsList extends ConsumerWidget {
  final AssignmentsFilter filter;

  const _AssignmentsList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(assignmentsProvider(filter));

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) {
        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No ${filter.status} assignments',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(assignmentsProvider(filter)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return _AssignmentCard(
                assignment: assignment,
                onTap: () => _showAssignmentDetail(context, assignment),
              );
            },
          ),
        );
      },
    );
  }

  void _showAssignmentDetail(BuildContext context, Assignment assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignmentDetailSheet(assignment: assignment),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;

  const _AssignmentCard({
    required this.assignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = assignment.dueDate;
    final isPastDue = dueDate != null && dueDate.isBefore(DateTime.now());
    final submittedCount = assignment.submittedCount ?? 0;
    final totalStudents = assignment.totalStudents ?? 0;
    final gradedCount = assignment.gradedCount ?? 0;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title ?? 'Untitled',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${assignment.subjectName ?? ''} • ${assignment.sectionName ?? ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(assignment.status, isPastDue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPastDue && assignment.status == 'published' 
                          ? 'OVERDUE' 
                          : (assignment.status ?? '').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(assignment.status, isPastDue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.calendar_today, 
                      dueDate != null ? DateFormat('MMM d').format(dueDate) : 'No due date',
                      isPastDue ? AppColors.error : null),
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.people, '$submittedCount / $totalStudents submitted'),
                  if (submittedCount > 0) ...[
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.grading, '$gradedCount graded',
                        gradedCount < submittedCount ? AppColors.warning : AppColors.success),
                  ],
                ],
              ),
              if (assignment.status == 'published' && totalStudents > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: submittedCount / totalStudents,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, [Color? color]) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color ?? Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status, bool isPastDue) {
    if (isPastDue && status == 'published') return AppColors.error;
    switch (status) {
      case 'published':
        return AppColors.success;
      case 'draft':
        return Colors.grey;
      case 'closed':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }
}

class _AssignmentDetailSheet extends ConsumerWidget {
  final Assignment assignment;

  const _AssignmentDetailSheet({required this.assignment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(submissionsProvider(
      SubmissionsFilter(assignmentId: assignment.id),
    ));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title ?? 'Assignment',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${assignment.subjectName ?? ''} • ${assignment.sectionName ?? ''}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (assignment.dueDate != null)
                      _buildHeaderChip(Icons.calendar_today, 
                          'Due: ${DateFormat('MMM d, yyyy').format(assignment.dueDate)}'),
                    const SizedBox(width: 12),
                    if (assignment.maxMarks != null)
                      _buildHeaderChip(Icons.grade, 'Max: ${assignment.maxMarks} marks'),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          if (assignment.status == 'draft')
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.amber.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('This assignment is not published yet.')),
                  ElevatedButton(
                    onPressed: () => _publishAssignment(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Publish'),
                  ),
                ],
              ),
            ),

          // Submissions List
          Expanded(
            child: submissionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (submissions) {
                if (submissions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No submissions yet'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final submission = submissions[index];
                    return _SubmissionCard(
                      submission: submission,
                      onGrade: () => _showGradeDialog(context, ref, submission),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  void _publishAssignment(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(assignmentsNotifierProvider.notifier).publishAssignment(assignment.id);
      if (context.mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar('Assignment published');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Error: $e');
      }
    }
  }

  void _showGradeDialog(BuildContext context, WidgetRef ref, dynamic submission) {
    final marksController = TextEditingController(
      text: submission.marksObtained?.toString() ?? '',
    );
    final feedbackController = TextEditingController(
      text: submission.feedback ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade ${submission.studentName ?? "Student"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: marksController,
              decoration: InputDecoration(
                labelText: 'Marks',
                suffixText: '/ ${assignment.maxMarks ?? 100}',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final marks = double.tryParse(marksController.text);
              if (marks == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid marks')),
                );
                return;
              }

              try {
                await ref.read(assignmentRepositoryProvider).gradeSubmission(
                  submissionId: submission.id,
                  marksObtained: marks,
                  feedback: feedbackController.text.trim().isNotEmpty ? feedbackController.text.trim() : null,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  context.showSuccessSnackBar('Submission graded');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorSnackBar('Error: $e');
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final dynamic submission;
  final VoidCallback onGrade;

  const _SubmissionCard({
    required this.submission,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final isGraded = submission.status == 'graded';
    final isLate = submission.status == 'late';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              (submission.studentName ?? 'S')[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.studentName ?? 'Student',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Text(
                      submission.admissionNumber ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (isLate) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LATE',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (submission.submittedAt != null)
                  Text(
                    'Submitted: ${DateFormat('MMM d, h:mm a').format(submission.submittedAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          if (isGraded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${submission.marksObtained?.toStringAsFixed(0) ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'marks',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: onGrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Grade'),
            ),
        ],
      ),
    );
  }
}

class _CreateAssignmentSheet extends ConsumerStatefulWidget {
  const _CreateAssignmentSheet();

  @override
  ConsumerState<_CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends ConsumerState<_CreateAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxMarksController = TextEditingController(text: '100');
  DateTime? _dueDate;
  String? _selectedSubjectId;
  String? _selectedSectionId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxMarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                const Text(
                  'Create Assignment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description / Instructions',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDueDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Date *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _dueDate != null
                                    ? DateFormat('MMM d, yyyy').format(_dueDate!)
                                    : 'Select date',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxMarksController,
                            decoration: const InputDecoration(
                              labelText: 'Max Marks',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : () => _submit(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Save as Draft'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : () => _submit(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Publish'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _submit(bool publish) async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(assignmentsNotifierProvider.notifier).createAssignment({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'due_date': _dueDate!.toIso8601String(),
        'max_marks': double.tryParse(_maxMarksController.text) ?? 100,
        'status': publish ? 'published' : 'draft',
      });

      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar(publish ? 'Assignment published' : 'Draft saved');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
