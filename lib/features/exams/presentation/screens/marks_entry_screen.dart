import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../students/providers/students_provider.dart';
import '../../providers/exams_provider.dart';

class MarksEntryScreen extends ConsumerStatefulWidget {
  final String examId;

  const MarksEntryScreen({super.key, required this.examId});

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  String? _selectedExamSubjectId;
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String studentId) {
    return _controllers.putIfAbsent(
      studentId,
      () => TextEditingController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final examAsync = ref.watch(examByIdProvider(widget.examId));
    final subjectsAsync = ref.watch(examSubjectsProvider(widget.examId));

    return examAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Enter Marks')),
        body: Center(child: Text('Failed to load exam: $e')),
      ),
      data: (exam) => subjectsAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Enter Marks')),
          body: Center(child: Text('Failed to load subjects: $e')),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Enter Marks')),
              body: const Center(
                child: Text('No subjects configured for this exam'),
              ),
            );
          }

          // Select first subject by default
          final selectedSubjectId =
              _selectedExamSubjectId ?? subjects.first.id;
          final selectedSubject = subjects.firstWhere(
            (s) => s.id == selectedSubjectId,
            orElse: () => subjects.first,
          );
          final classId = selectedSubject.classId;
          final maxMarks = selectedSubject.maxMarks.toInt();
          final passingMarks = selectedSubject.passingMarks.toInt();

          return _buildContent(
            context: context,
            exam: exam,
            subjects: subjects,
            selectedSubject: selectedSubject,
            classId: classId,
            maxMarks: maxMarks,
            passingMarks: passingMarks,
          );
        },
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required exam,
    required List subjects,
    required selectedSubject,
    required String classId,
    required int maxMarks,
    required int passingMarks,
  }) {
    final studentsAsync = ref.watch(
      studentsProvider(StudentsFilter(classId: classId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Marks'),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : () => _saveAsDraft(selectedSubject, studentsAsync),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black12
                : AppColors.primary.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${exam?.name ?? 'Exam'} — ${selectedSubject.className ?? 'Class'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                // Subject Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: subjects
                        .map((subject) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label:
                                    Text(subject.subjectName ?? subject.id),
                                selected: subject.id == selectedSubject.id,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedExamSubjectId = subject.id;
                                    });
                                  }
                                },
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: subject.id == selectedSubject.id
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                studentsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (students) => Row(
                    children: [
                      _InfoChip(
                        icon: Icons.assignment,
                        label: 'Max Marks: $maxMarks',
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.check_circle_outline,
                        label: 'Pass: $passingMarks',
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.people,
                        label: '${students.length} Students',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Bar (computed from entered marks)
          studentsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (students) {
              int entered = 0;
              int absent = 0;
              double total = 0;
              for (final student in students) {
                final ctrl = _controllers[student.id];
                if (ctrl != null && ctrl.text.isNotEmpty) {
                  if (ctrl.text == 'AB') {
                    absent++;
                  } else {
                    final m = double.tryParse(ctrl.text);
                    if (m != null) {
                      entered++;
                      total += m;
                    }
                  }
                }
              }
              final pending = students.length - entered - absent;
              final avg =
                  entered > 0 ? (total / entered).toStringAsFixed(1) : '—';

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                        label: 'Entered',
                        value: '$entered',
                        color: AppColors.success),
                    _StatItem(
                        label: 'Pending',
                        value: '$pending',
                        color: AppColors.warning),
                    _StatItem(
                        label: 'Absent',
                        value: '$absent',
                        color: AppColors.error),
                    _StatItem(
                        label: 'Average',
                        value: avg,
                        color: AppColors.info),
                  ],
                ),
              );
            },
          ),

          // Student List
          Expanded(
            child: studentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Failed to load students: $e'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(
                        studentsProvider(StudentsFilter(classId: classId)),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (students) {
                if (students.isEmpty) {
                  return const Center(
                    child: Text('No students found for this class'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final rollNo = student.currentEnrollment?.rollNumber ??
                        student.rollNumber ??
                        '${index + 1}';
                    return _MarksEntryCard(
                      rollNo: rollNo,
                      name: student.fullName,
                      controller: _controllerFor(student.id),
                      maxMarks: maxMarks,
                      onChanged: (value) => setState(() {}),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _saveAsDraft(selectedSubject, studentsAsync),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitMarks(
                          selectedSubject, studentsAsync, maxMarks),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Marks',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAsDraft(selectedSubject, AsyncValue studentsAsync) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _submitMarks(
    selectedSubject,
    AsyncValue studentsAsync,
    int maxMarks,
  ) async {
    final students = studentsAsync.asData?.value;
    if (students == null) return;

    // Validate
    for (final student in students) {
      final ctrl = _controllers[student.id];
      if (ctrl != null && ctrl.text.isNotEmpty && ctrl.text != 'AB') {
        final marks = double.tryParse(ctrl.text);
        if (marks == null || marks < 0 || marks > maxMarks) {
          context.showErrorSnackBar(
              'Please enter valid marks (0–$maxMarks) for ${student.fullName}');
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final examSubjectId = selectedSubject.id as String;
      final bulkMarks = <Map<String, dynamic>>[];

      for (final student in students) {
        final ctrl = _controllers[student.id];
        if (ctrl != null && ctrl.text.isNotEmpty) {
          final isAbsent = ctrl.text == 'AB';
          final marksObtained =
              isAbsent ? null : double.tryParse(ctrl.text);
          bulkMarks.add({
            'exam_subject_id': examSubjectId,
            'student_id': student.id,
            if (marksObtained != null) 'marks_obtained': marksObtained,
            'is_absent': isAbsent,
          });
        }
      }

      if (bulkMarks.isNotEmpty) {
        await ref
            .read(marksEntryNotifierProvider.notifier)
            .enterBulkMarks(bulkMarks);
      }

      if (mounted) {
        context.showSuccessSnackBar('Marks submitted successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to submit: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _MarksEntryCard extends StatelessWidget {
  final String rollNo;
  final String name;
  final TextEditingController controller;
  final int maxMarks;
  final ValueChanged<String> onChanged;

  const _MarksEntryCard({
    required this.rollNo,
    required this.name,
    required this.controller,
    required this.maxMarks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final marks = double.tryParse(controller.text);
    final isAbsent = controller.text == 'AB';
    final isValid = isAbsent ||
        marks == null ||
        (marks >= 0 && marks <= maxMarks);
    final isPassing = marks != null && marks >= (maxMarks * 0.35);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Roll Number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  rollNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            // Marks Input
            SizedBox(
              width: 80,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                enabled: !isAbsent,
                decoration: InputDecoration(
                  hintText: isAbsent ? 'AB' : '0',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color:
                          isValid ? Colors.grey.shade300 : AppColors.error,
                    ),
                  ),
                  filled: true,
                  fillColor: controller.text.isEmpty
                      ? Colors.grey.withValues(alpha: 0.05)
                      : isAbsent
                          ? AppColors.error.withValues(alpha: 0.1)
                          : isPassing
                              ? AppColors.success.withValues(alpha: 0.05)
                              : AppColors.error.withValues(alpha: 0.05),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '/ $maxMarks',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            // Absent toggle
            IconButton(
              icon: Icon(
                Icons.person_off_outlined,
                color: isAbsent ? AppColors.error : Colors.grey[400],
                size: 20,
              ),
              onPressed: () {
                if (isAbsent) {
                  controller.text = '';
                } else {
                  controller.text = 'AB';
                }
                onChanged(controller.text);
              },
              tooltip: isAbsent ? 'Mark Present' : 'Mark Absent',
            ),
          ],
        ),
      ),
    );
  }
}
