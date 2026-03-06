import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/homework.dart';
import '../../providers/homework_provider.dart';

class HomeworkCreateScreen extends ConsumerStatefulWidget {
  const HomeworkCreateScreen({super.key});

  @override
  ConsumerState<HomeworkCreateScreen> createState() =>
      _HomeworkCreateScreenState();
}

class _HomeworkCreateScreenState extends ConsumerState<HomeworkCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _maxMarksController = TextEditingController();

  String? _selectedSubjectId;
  String? _selectedSectionId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  HomeworkPriority _priority = HomeworkPriority.medium;
  bool _allowLateSubmission = false;
  bool _isSubmitting = false;

  // Mock data for dropdowns - in production these come from providers
  final List<Map<String, String>> _subjects = [
    {'id': 'math-001', 'name': 'Mathematics'},
    {'id': 'eng-001', 'name': 'English'},
    {'id': 'sci-001', 'name': 'Science'},
    {'id': 'his-001', 'name': 'History'},
    {'id': 'geo-001', 'name': 'Geography'},
  ];

  final List<Map<String, String>> _sections = [
    {'id': 'sec-001', 'name': 'Class 10 - A'},
    {'id': 'sec-002', 'name': 'Class 10 - B'},
    {'id': 'sec-003', 'name': 'Class 9 - A'},
    {'id': 'sec-004', 'name': 'Class 9 - B'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _maxMarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit({bool publish = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'instructions': _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        'subject_id': _selectedSubjectId,
        'section_id': _selectedSectionId,
        'assigned_date': DateTime.now().toIso8601String().split('T').first,
        'due_date': _dueDate.toIso8601String().split('T').first,
        'status': publish
            ? HomeworkStatus.published.value
            : HomeworkStatus.draft.value,
        'priority': _priority.value,
        'max_marks': _maxMarksController.text.isNotEmpty
            ? int.tryParse(_maxMarksController.text)
            : null,
        'allow_late_submission': _allowLateSubmission,
        'attachment_urls': <String>[],
      };

      await ref.read(homeworkNotifierProvider.notifier).create(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish
                ? 'Homework published successfully'
                : 'Homework saved as draft'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Homework'),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : () => _submit(publish: false),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Homework Details',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g., Chapter 5 Practice Problems',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.assignment),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Brief description of the homework',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Instructions',
                      hintText: 'Step-by-step instructions for students',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.list_alt),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Class & Subject Selection
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class & Subject',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSectionId,
                    decoration: const InputDecoration(
                      labelText: 'Class/Section *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: _sections.map((s) {
                      return DropdownMenuItem(
                        value: s['id'],
                        child: Text(s['name']!),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedSectionId = v),
                    validator: (v) => v == null ? 'Please select a class' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Subject *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                    items: _subjects.map((s) {
                      return DropdownMenuItem(
                        value: s['id'],
                        child: Text(s['name']!),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedSubjectId = v),
                    validator: (v) => v == null ? 'Please select a subject' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Due Date & Settings
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule & Settings',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                    ),
                    title: const Text('Due Date'),
                    subtitle: Text(
                      dateFormat.format(_dueDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _selectDueDate,
                  ),
                  const Divider(),
                  DropdownButtonFormField<HomeworkPriority>(
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: HomeworkPriority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: p == HomeworkPriority.high
                                  ? AppColors.error
                                  : p == HomeworkPriority.medium
                                      ? AppColors.accent
                                      : AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(p.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _priority = v ?? HomeworkPriority.medium),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _maxMarksController,
                    decoration: const InputDecoration(
                      labelText: 'Max Marks (optional)',
                      hintText: 'e.g., 100',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grade),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) {
                          return 'Enter a valid positive number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow Late Submission'),
                    subtitle: const Text(
                        'Students can submit after the due date'),
                    value: _allowLateSubmission,
                    onChanged: (v) =>
                        setState(() => _allowLateSubmission = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : () => _submit(publish: true),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish),
                label: Text(
                    _isSubmitting ? 'Publishing...' : 'Publish Homework'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
