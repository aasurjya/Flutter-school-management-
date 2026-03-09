import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/report_card_full.dart';
import '../../providers/report_card_provider.dart';

class GradingScaleScreen extends ConsumerWidget {
  const GradingScaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scalesAsync = ref.watch(gradingScalesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grading Scales'),
      ),
      body: scalesAsync.when(
        data: (scales) {
          if (scales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grade_outlined,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('No grading scales defined'),
                  const SizedBox(height: 8),
                  Text(
                    'Create a scale to define how grades are assigned',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () =>
                        _showScaleEditor(context, ref, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Scale'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scales.length,
            itemBuilder: (context, index) {
              final scale = scales[index];
              return _GradingScaleCard(
                scale: scale,
                onEdit: () =>
                    _showScaleEditor(context, ref, scale),
                onDelete: () =>
                    _deleteScale(context, ref, scale.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScaleEditor(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New Scale'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showScaleEditor(
      BuildContext context, WidgetRef ref, GradingScale? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _GradingScaleEditorSheet(
        existing: existing,
        onSave: (data) async {
          final repo = ref.read(rcFullRepositoryProvider);
          if (existing != null) {
            await repo.updateGradingScale(existing.id, data);
          } else {
            await repo.createGradingScale(
              GradingScale(
                id: '',
                tenantId: repo.requireTenantId,
                name: data['name'] as String,
                type: data['type'] as String,
                scaleItems: (data['scale_items'] as List)
                    .map((e) =>
                        GradingScaleItem.fromJson(e as Map<String, dynamic>))
                    .toList(),
                isDefault: data['is_default'] as bool? ?? false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
          }
          ref.invalidate(gradingScalesProvider);
        },
      ),
    );
  }

  void _deleteScale(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Grading Scale'),
        content: const Text(
            'Are you sure? Templates using this scale will revert to default grading.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(rcFullRepositoryProvider).deleteGradingScale(id);
        ref.invalidate(gradingScalesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scale deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _GradingScaleCard extends StatelessWidget {
  final GradingScale scale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GradingScaleCard({
    required this.scale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          scale.name,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (scale.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${scale.type.toUpperCase()}  |  ${scale.scaleItems.length} grades',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grade items preview
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scale.scaleItems.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gradeColor(item.grade)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gradeColor(item.grade)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      item.grade,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gradeColor(item.grade),
                      ),
                    ),
                    Text(
                      '${item.minMarks.toInt()}-${item.maxMarks.toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GradingScaleEditorSheet extends StatefulWidget {
  final GradingScale? existing;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _GradingScaleEditorSheet({this.existing, required this.onSave});

  @override
  State<_GradingScaleEditorSheet> createState() =>
      _GradingScaleEditorSheetState();
}

class _GradingScaleEditorSheetState extends State<_GradingScaleEditorSheet> {
  final _nameController = TextEditingController();
  String _type = 'percentage';
  bool _isDefault = false;
  bool _isSaving = false;
  final List<_GradeRow> _grades = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _type = widget.existing!.type;
      _isDefault = widget.existing!.isDefault;
      for (final item in widget.existing!.scaleItems) {
        _grades.add(_GradeRow(
          gradeController: TextEditingController(text: item.grade),
          minController:
              TextEditingController(text: item.minMarks.toInt().toString()),
          maxController:
              TextEditingController(text: item.maxMarks.toInt().toString()),
          gpaController: TextEditingController(
              text: item.gpaValue?.toString() ?? ''),
          descController:
              TextEditingController(text: item.description ?? ''),
        ));
      }
    } else {
      // Pre-fill with CBSE standard grades
      _nameController.text = 'Standard Grading';
      _grades.addAll([
        _GradeRow.preset('A1', 91, 100, 10.0, 'Outstanding'),
        _GradeRow.preset('A2', 81, 90, 9.0, 'Excellent'),
        _GradeRow.preset('B1', 71, 80, 8.0, 'Very Good'),
        _GradeRow.preset('B2', 61, 70, 7.0, 'Good'),
        _GradeRow.preset('C1', 51, 60, 6.0, 'Above Average'),
        _GradeRow.preset('C2', 41, 50, 5.0, 'Average'),
        _GradeRow.preset('D', 33, 40, 4.0, 'Below Average'),
        _GradeRow.preset('E', 0, 32, 0.0, 'Needs Improvement'),
      ]);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final g in _grades) {
      g.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing != null
                    ? 'Edit Grading Scale'
                    : 'Create Grading Scale',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Scale Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'percentage', child: Text('Percentage')),
                        DropdownMenuItem(
                            value: 'letter', child: Text('Letter')),
                        DropdownMenuItem(value: 'gpa', child: Text('GPA')),
                        DropdownMenuItem(
                            value: 'cgpa', child: Text('CGPA')),
                      ],
                      onChanged: (v) =>
                          setState(() => _type = v ?? 'percentage'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _isDefault,
                        onChanged: (v) =>
                            setState(() => _isDefault = v ?? false),
                      ),
                      const Text('Default'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Grade Items',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addGrade,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Grade'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Header
              const Row(
                children: [
                  SizedBox(width: 70, child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  SizedBox(width: 8),
                  SizedBox(width: 60, child: Text('Min %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  SizedBox(width: 8),
                  SizedBox(width: 60, child: Text('Max %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  SizedBox(width: 8),
                  SizedBox(width: 60, child: Text('GPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  SizedBox(width: 8),
                  Expanded(child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _grades.length,
                  itemBuilder: (context, index) {
                    final g = _grades[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: g.gradeController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: g.minController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: g.maxController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: g.gpaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: g.descController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: AppColors.error),
                              onPressed: () =>
                                  setState(() => _grades.removeAt(index)),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Grading Scale'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addGrade() {
    setState(() {
      _grades.add(_GradeRow(
        gradeController: TextEditingController(),
        minController: TextEditingController(),
        maxController: TextEditingController(),
        gpaController: TextEditingController(),
        descController: TextEditingController(),
      ));
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a scale name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final items = _grades
          .where((g) => g.gradeController.text.trim().isNotEmpty)
          .map((g) => {
                'grade': g.gradeController.text.trim(),
                'min_marks': double.tryParse(g.minController.text) ?? 0,
                'max_marks': double.tryParse(g.maxController.text) ?? 100,
                'gpa_value': double.tryParse(g.gpaController.text),
                'description': g.descController.text.trim(),
              })
          .toList();

      await widget.onSave({
        'name': _nameController.text.trim(),
        'type': _type,
        'scale_items': items,
        'is_default': _isDefault,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Grading scale saved'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _GradeRow {
  final TextEditingController gradeController;
  final TextEditingController minController;
  final TextEditingController maxController;
  final TextEditingController gpaController;
  final TextEditingController descController;

  _GradeRow({
    required this.gradeController,
    required this.minController,
    required this.maxController,
    required this.gpaController,
    required this.descController,
  });

  factory _GradeRow.preset(
      String grade, int min, int max, double gpa, String desc) {
    return _GradeRow(
      gradeController: TextEditingController(text: grade),
      minController: TextEditingController(text: min.toString()),
      maxController: TextEditingController(text: max.toString()),
      gpaController: TextEditingController(text: gpa.toString()),
      descController: TextEditingController(text: desc),
    );
  }

  void dispose() {
    gradeController.dispose();
    minController.dispose();
    maxController.dispose();
    gpaController.dispose();
    descController.dispose();
  }
}
