import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/lms_provider.dart';
import '../widgets/module_list_widget.dart';

class CourseBuilderScreen extends ConsumerStatefulWidget {
  final String? courseId;

  const CourseBuilderScreen({super.key, this.courseId});

  @override
  ConsumerState<CourseBuilderScreen> createState() =>
      _CourseBuilderScreenState();
}

class _CourseBuilderScreenState extends ConsumerState<CourseBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  CourseStatus _status = CourseStatus.draft;
  bool _isSelfPaced = false;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _enrollmentLimit;
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  Course? _existingCourse;

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null) {
      _isEditing = true;
      _loadCourse();
    }
  }

  Future<void> _loadCourse() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(lmsRepositoryProvider);
      final course = await repo.getCourseById(widget.courseId!);
      if (course != null && mounted) {
        setState(() {
          _existingCourse = course;
          _titleController.text = course.title;
          _descriptionController.text = course.description ?? '';
          _status = course.status;
          _isSelfPaced = course.isSelfPaced;
          _startDate = course.startDate;
          _endDate = course.endDate;
          _enrollmentLimit = course.enrollmentLimit;
          _tags.addAll(course.tags);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading course: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Course' : 'Create Course'),
        actions: [
          if (_isEditing && _existingCourse != null)
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'publish',
                  enabled: _existingCourse!.status == CourseStatus.draft,
                  child: const Row(
                    children: [
                      Icon(Icons.publish, size: 18),
                      SizedBox(width: 8),
                      Text('Publish'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  enabled: _existingCourse!.status == CourseStatus.published,
                  child: const Row(
                    children: [
                      Icon(Icons.archive_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Archive'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleMenuAction(value),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Course Title *',
                      hintText: 'e.g., Introduction to Physics',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe what students will learn...',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // Self-paced toggle
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: SwitchListTile(
                      title: const Text('Self-paced Course'),
                      subtitle: const Text(
                          'Students can progress at their own pace'),
                      value: _isSelfPaced,
                      onChanged: (value) =>
                          setState(() => _isSelfPaced = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date range
                  if (!_isSelfPaced)
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            onTap: () => _pickDate(isStart: true),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _startDate != null
                                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                      : 'Start Date',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            onTap: () => _pickDate(isStart: false),
                            child: Row(
                              children: [
                                const Icon(Icons.event,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _endDate != null
                                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                      : 'End Date',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (!_isSelfPaced) const SizedBox(height: 16),

                  // Enrollment limit
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Enrollment Limit (optional)',
                      hintText: 'Max number of students',
                      prefixIcon: Icon(Icons.group_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _enrollmentLimit?.toString(),
                    onChanged: (value) {
                      _enrollmentLimit =
                          value.isNotEmpty ? int.tryParse(value) : null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  Text(
                    'Tags',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ..._tags.map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            onDeleted: () =>
                                setState(() => _tags.remove(tag)),
                            deleteIconColor: AppColors.error,
                            side: BorderSide.none,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : AppColors.infoLight,
                          )),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'Add tag...',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 12),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              setState(() => _tags.add(value.trim()));
                              _tagController.clear();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Modules section (only in edit mode)
                  if (_isEditing && _existingCourse != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Modules',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _showAddModuleDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Module'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ModuleListWidget(
                      modules: _existingCourse!.modules ?? [],
                      isEditable: true,
                      onEditModule: (module) =>
                          _showEditModuleDialog(module),
                      onDeleteModule: (module) =>
                          _deleteModule(module),
                      onAddContent: (module) =>
                          _showAddContentDialog(module),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _saveCourse,
                      icon: Icon(_isEditing ? Icons.save : Icons.add),
                      label: Text(_isEditing ? 'Save Changes' : 'Create Course'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(lmsRepositoryProvider);
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'is_self_paced': _isSelfPaced,
        'start_date': _startDate?.toIso8601String().split('T')[0],
        'end_date': _endDate?.toIso8601String().split('T')[0],
        'enrollment_limit': _enrollmentLimit,
        'tags': _tags,
        'status': _status.value,
      };

      if (_isEditing) {
        await repo.updateCourse(widget.courseId!, data);
      } else {
        final course = await repo.createCourse(data);
        if (mounted) {
          // Navigate to edit mode for newly created course
          context.pushReplacement(
            AppRoutes.lmsCourseBuilderEdit
                .replaceAll(':courseId', course.id),
          );
          return;
        }
      }

      ref.invalidate(allCoursesProvider);
      ref.invalidate(lmsStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(_isEditing ? 'Course updated' : 'Course created')),
        );
        if (!_isEditing) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMenuAction(String action) async {
    final repo = ref.read(lmsRepositoryProvider);

    switch (action) {
      case 'publish':
        await repo.updateCourse(widget.courseId!, {
          'status': CourseStatus.published.value,
        });
        ref.invalidate(courseByIdProvider);
        _loadCourse();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course published!')),
          );
        }
        break;
      case 'archive':
        await repo.updateCourse(widget.courseId!, {
          'status': CourseStatus.archived.value,
        });
        ref.invalidate(courseByIdProvider);
        _loadCourse();
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Course'),
            content: const Text(
                'Are you sure you want to delete this course? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await repo.deleteCourse(widget.courseId!);
          ref.invalidate(allCoursesProvider);
          if (mounted) context.pop();
        }
        break;
    }
  }

  Future<void> _showAddModuleDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Module'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Module Title *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durationCtrl,
              decoration:
                  const InputDecoration(labelText: 'Duration (minutes)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(context, {
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim().isNotEmpty
                    ? descCtrl.text.trim()
                    : null,
                'duration_minutes':
                    int.tryParse(durationCtrl.text) ?? 30,
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final repo = ref.read(lmsRepositoryProvider);
        final nextOrder =
            (_existingCourse?.modules?.length ?? 0);
        result['course_id'] = widget.courseId;
        result['sequence_order'] = nextOrder;
        await repo.createModule(result);
        _loadCourse();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditModuleDialog(CourseModule module) async {
    final titleCtrl = TextEditingController(text: module.title);
    final descCtrl =
        TextEditingController(text: module.description ?? '');
    final durationCtrl =
        TextEditingController(text: module.durationMinutes.toString());

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Module'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Module Title *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durationCtrl,
              decoration:
                  const InputDecoration(labelText: 'Duration (minutes)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(context, {
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim().isNotEmpty
                    ? descCtrl.text.trim()
                    : null,
                'duration_minutes':
                    int.tryParse(durationCtrl.text) ?? 30,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final repo = ref.read(lmsRepositoryProvider);
        await repo.updateModule(module.id, result);
        _loadCourse();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteModule(CourseModule module) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Module'),
        content: Text(
            'Delete "${module.title}" and all its content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(lmsRepositoryProvider);
        await repo.deleteModule(module.id);
        _loadCourse();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAddContentDialog(CourseModule module) async {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    ContentType selectedType = ContentType.text;
    bool isMandatory = true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Content'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Content Title *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ContentType>(
                  initialValue: selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Content Type'),
                  items: ContentType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (selectedType == ContentType.text)
                  TextField(
                    controller: textCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Content Text'),
                    maxLines: 4,
                  )
                else
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'https://...',
                    ),
                  ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Mandatory'),
                  value: isMandatory,
                  onChanged: (v) =>
                      setDialogState(() => isMandatory = v ?? true),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final contentData = <String, dynamic>{};
                if (selectedType == ContentType.text) {
                  contentData['text'] = textCtrl.text;
                } else {
                  contentData['url'] = urlCtrl.text;
                }

                Navigator.pop(context, {
                  'title': titleCtrl.text.trim(),
                  'content_type': selectedType.value,
                  'content_data': contentData,
                  'is_mandatory': isMandatory,
                });
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final repo = ref.read(lmsRepositoryProvider);
        final nextOrder = module.contents?.length ?? 0;
        result['module_id'] = module.id;
        result['sequence_order'] = nextOrder;
        await repo.createContent(result);
        _loadCourse();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
