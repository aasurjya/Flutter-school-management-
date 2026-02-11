import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/assignment.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../assignments/providers/assignments_provider.dart';
import '../../../students/providers/students_provider.dart';

class StudentAssignmentsScreen extends ConsumerStatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  ConsumerState<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends ConsumerState<StudentAssignmentsScreen>
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
    final currentStudent = ref.watch(currentStudentProvider);

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
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: currentStudent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Student not found'));
          }

          final sectionId = student.currentEnrollment?.sectionId;
          if (sectionId == null) {
            return const Center(child: Text('No enrollment found'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _AssignmentsList(
                sectionId: sectionId,
                studentId: student.id,
                filter: 'pending',
              ),
              _AssignmentsList(
                sectionId: sectionId,
                studentId: student.id,
                filter: 'submitted',
              ),
              _AssignmentsList(
                sectionId: sectionId,
                studentId: student.id,
                filter: 'all',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AssignmentsList extends ConsumerWidget {
  final String sectionId;
  final String studentId;
  final String filter;

  const _AssignmentsList({
    required this.sectionId,
    required this.studentId,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider(
      StudentAssignmentsFilter(
        sectionId: sectionId,
        pendingOnly: filter == 'pending',
      ),
    ));

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) {
        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  filter == 'pending'
                      ? 'No pending assignments'
                      : 'No assignments found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return _AssignmentCard(
              assignment: assignment,
              studentId: studentId,
              onTap: () => _showAssignmentDetail(context, ref, assignment, studentId),
            );
          },
        );
      },
    );
  }

  void _showAssignmentDetail(
    BuildContext context,
    WidgetRef ref,
    Assignment assignment,
    String studentId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignmentDetailSheet(
        assignment: assignment,
        studentId: studentId,
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final String studentId;
  final VoidCallback onTap;

  const _AssignmentCard({
    required this.assignment,
    required this.studentId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPastDue = DateTime.now().isAfter(assignment.dueDate);
    final daysRemaining = assignment.dueDate.difference(DateTime.now()).inDays;

    Color statusColor;
    String statusText;

    if (isPastDue) {
      statusColor = AppColors.error;
      statusText = 'Overdue';
    } else if (daysRemaining == 0) {
      statusColor = AppColors.warning;
      statusText = 'Due Today';
    } else if (daysRemaining <= 2) {
      statusColor = AppColors.warning;
      statusText = 'Due in $daysRemaining days';
    } else {
      statusColor = AppColors.success;
      statusText = 'Due in $daysRemaining days';
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assignment,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment.subjectName ?? 'Unknown Subject',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Due: ${DateFormat('MMM d, yyyy h:mm a').format(assignment.dueDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (assignment.maxMarks != null) ...[
                  Icon(Icons.grade, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Max: ${assignment.maxMarks} marks',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentDetailSheet extends ConsumerStatefulWidget {
  final Assignment assignment;
  final String studentId;

  const _AssignmentDetailSheet({
    required this.assignment,
    required this.studentId,
  });

  @override
  ConsumerState<_AssignmentDetailSheet> createState() => _AssignmentDetailSheetState();
}

class _AssignmentDetailSheetState extends ConsumerState<_AssignmentDetailSheet> {
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submissionAsync = ref.watch(studentSubmissionProvider(
      StudentSubmissionFilter(
        assignmentId: widget.assignment.id,
        studentId: widget.studentId,
      ),
    ));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.assignment.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
                Row(
                  children: [
                    Icon(Icons.book, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      widget.assignment.subjectName ?? 'Unknown Subject',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${DateFormat('MMM d, yyyy').format(widget.assignment.dueDate)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.assignment.description != null) ...[
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.assignment.description!),
                    const SizedBox(height: 24),
                  ],
                  if (widget.assignment.instructions != null) ...[
                    const Text(
                      'Instructions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.assignment.instructions!),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Your Submission',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  submissionAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (submission) {
                      if (submission != null && submission.isGraded) {
                        return _buildGradedSubmission(submission);
                      } else if (submission != null && submission.isSubmitted) {
                        return _buildSubmittedView(submission);
                      } else {
                        return _buildSubmissionForm();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradedSubmission(dynamic submission) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check_circle, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Graded',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  if (submission.marksObtained != null)
                    Text(
                      'Score: ${submission.marksObtained}/${widget.assignment.maxMarks ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
          if (submission.feedback != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Teacher Feedback',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(submission.feedback!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmittedView(dynamic submission) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.hourglass_empty, color: AppColors.info),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submitted - Awaiting Review',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                  if (submission.submittedAt != null)
                    Text(
                      'Submitted on: ${DateFormat('MMM d, yyyy h:mm a').format(submission.submittedAt!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
          if (submission.content != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Your Answer',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(submission.content!),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmissionForm() {
    return Column(
      children: [
        TextField(
          controller: _contentController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAssignment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                : const Text(
                    'Submit Assignment',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitAssignment() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your answer')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(submissionNotifierProvider.notifier).submitAssignment(
        assignmentId: widget.assignment.id,
        studentId: widget.studentId,
        content: _contentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar('Assignment submitted successfully!');
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
