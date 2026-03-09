import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../data/models/gradebook.dart';
import '../../../../data/repositories/timetable_repository.dart';
import '../../providers/gradebook_provider.dart';

/// Screen to add or edit a grade entry.
///
/// Receives an optional [GradeEntry] via [extra] for edit mode, and
/// optionally a [TeacherClassInfo] to pre-fill the class context.
class GradeEntryFormScreen extends ConsumerStatefulWidget {
  /// When non-null, the form is in edit mode for this entry.
  final GradeEntry? existingEntry;

  /// Pre-selected class context from the gradebook screen.
  final TeacherClassInfo? classInfo;

  const GradeEntryFormScreen({
    super.key,
    this.existingEntry,
    this.classInfo,
  });

  @override
  ConsumerState<GradeEntryFormScreen> createState() =>
      _GradeEntryFormScreenState();
}

class _GradeEntryFormScreenState
    extends ConsumerState<GradeEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _earnedController = TextEditingController();
  final _possibleController = TextEditingController();
  final _notesController = TextEditingController();

  GradingCategory? _selectedCategory;
  String? _selectedStudentId;
  DateTime _gradedAt = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _populateFromExisting();
  }

  void _populateFromExisting() {
    final entry = widget.existingEntry;
    if (entry == null) return;
    _titleController.text = entry.title;
    if (entry.pointsEarned != null) {
      _earnedController.text = entry.pointsEarned!.toString();
    }
    _possibleController.text = entry.pointsPossible.toString();
    _notesController.text = entry.notes ?? '';
    _gradedAt = entry.gradedAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _earnedController.dispose();
    _possibleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classSubjectId =
        widget.classInfo?.sectionId ?? _selectedCategory?.classSubjectId ?? '';

    final categoriesAsync = classSubjectId.isNotEmpty
        ? ref.watch(gradingCategoriesProvider(classSubjectId))
        : const AsyncValue<List<GradingCategory>>.data([]);

    final studentsAsync = widget.classInfo != null
        ? ref.watch(_sectionStudentsProvider(widget.classInfo!.sectionId))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Grade Entry' : 'Add Grade Entry'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category selector
              _buildSectionHeader(context, 'Category'),
              const SizedBox(height: 8),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Failed to load categories: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
                data: (categories) => _buildCategoryDropdown(categories),
              ),

              const SizedBox(height: 20),

              // Student selector
              _buildSectionHeader(context, 'Student'),
              const SizedBox(height: 8),
              studentsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Failed to load students: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
                data: (students) => _buildStudentDropdown(students),
              ),

              const SizedBox(height: 20),

              // Assignment title
              _buildSectionHeader(context, 'Assignment'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Assignment Title', 'e.g. Chapter 3 Quiz'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),

              const SizedBox(height: 20),

              // Points
              _buildSectionHeader(context, 'Score'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _earnedController,
                      decoration:
                          _inputDecoration('Points Earned', '0.0'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v);
                        if (n == null || n < 0) {
                          return 'Enter a valid score';
                        }
                        final possible =
                            double.tryParse(_possibleController.text);
                        if (possible != null && n > possible) {
                          return 'Cannot exceed max points';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '/',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.grey[400]),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _possibleController,
                      decoration:
                          _inputDecoration('Max Points', '100'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return 'Enter max points';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Date picker
              _buildSectionHeader(context, 'Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: _inputDecoration('Date', ''),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(_formatDate(_gradedAt)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Notes
              _buildSectionHeader(context, 'Notes (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration('Notes', 'Optional feedback...'),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Update Grade' : 'Save Grade',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildCategoryDropdown(List<GradingCategory> categories) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'No categories found. Please add a grading category from the gradebook first.',
          style: TextStyle(color: AppColors.warning),
        ),
      );
    }

    return DropdownButtonFormField<GradingCategory>(
      initialValue: _selectedCategory,
      hint: const Text('Select Category'),
      decoration: _inputDecoration('', ''),
      isExpanded: true,
      items: categories.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text('${c.name} (${c.weight.toStringAsFixed(0)}%)'),
        );
      }).toList(),
      validator: (v) => v == null ? 'Please select a category' : null,
      onChanged: (c) => setState(() => _selectedCategory = c),
    );
  }

  Widget _buildStudentDropdown(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.infoLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'No students found for this class.',
          style: TextStyle(color: AppColors.info),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedStudentId,
      hint: const Text('Select Student'),
      decoration: _inputDecoration('', ''),
      isExpanded: true,
      items: students.map((s) {
        return DropdownMenuItem<String>(
          value: s['id'] as String,
          child: Text(
            s['full_name'] as String? ?? 'Unknown',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      validator: (v) => v == null ? 'Please select a student' : null,
      onChanged: (id) => setState(() => _selectedStudentId = id),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label.isNotEmpty ? label : null,
      hintText: hint.isNotEmpty ? hint : null,
      filled: true,
      fillColor: AppColors.inputFillLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _gradedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _gradedAt = picked);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a grading category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedStudentId == null && !_isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a student'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(gradebookRepositoryProvider);
      final tenantId = ref
              .read(supabaseProvider)
              .auth
              .currentUser
              ?.appMetadata['tenant_id'] as String? ??
          '';

      if (_isEdit) {
        final entry = widget.existingEntry!;
        await repo.updateGradeEntry(
          entry.id,
          pointsEarned: _earnedController.text.trim().isNotEmpty
              ? double.parse(_earnedController.text)
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
        _invalidateRelatedProviders(entry.categoryId);
      } else {
        final newEntry = GradeEntry(
          id: '',
          tenantId: tenantId,
          categoryId: _selectedCategory!.id,
          studentId: _selectedStudentId!,
          title: _titleController.text.trim(),
          pointsEarned: _earnedController.text.trim().isNotEmpty
              ? double.parse(_earnedController.text)
              : null,
          pointsPossible: double.parse(_possibleController.text),
          gradedAt: _gradedAt,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          createdAt: DateTime.now(),
        );
        await repo.addGradeEntry(newEntry);
        _invalidateRelatedProviders(_selectedCategory!.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEdit ? 'Grade updated' : 'Grade saved'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) setState(() => _saving = false);
    }
  }

  void _invalidateRelatedProviders(String categoryId) {
    ref.invalidate(gradeEntriesProvider(
      GradeEntriesParams(categoryId: categoryId),
    ));
    if (widget.classInfo != null) {
      ref.invalidate(
        gradingCategoriesProvider(widget.classInfo!.sectionId),
      );
    }
  }
}

// ─── Section-students provider (scoped to this file) ─────────────────────────

final _sectionStudentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, sectionId) async {
    final client = ref.watch(supabaseProvider);
    final response = await client
        .from('student_enrollments')
        .select('students(id, full_name, admission_number)')
        .eq('section_id', sectionId)
        .eq('is_active', true);

    return (response as List).map((row) {
      final s = row['students'] as Map<String, dynamic>;
      return {
        'id': s['id'] as String,
        'full_name': s['full_name'] as String? ?? 'Unknown',
        'admission_number': s['admission_number'] as String?,
      };
    }).toList();
  },
);
