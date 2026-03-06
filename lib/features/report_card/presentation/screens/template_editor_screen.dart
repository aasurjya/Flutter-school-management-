import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/report_card_full.dart';
import '../../providers/report_card_provider.dart';

class TemplateEditorScreen extends ConsumerStatefulWidget {
  final String? templateId; // null = create new

  const TemplateEditorScreen({super.key, this.templateId});

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _footerController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mottoController = TextEditingController();

  String _layout = 'standard';
  String _pageSize = 'A4';
  bool _isDefault = false;
  String? _gradingScaleId;
  List<_SectionItem> _sections = [];
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSections();
  }

  void _initializeSections() {
    _sections = [
      _SectionItem('grades', 'Academic Grades', Icons.school, true, 0),
      _SectionItem(
          'attendance', 'Attendance Summary', Icons.calendar_today, true, 1),
      _SectionItem(
          'teacher_comment', 'Teacher Comment', Icons.comment, true, 2),
      _SectionItem('principal_comment', 'Principal Comment',
          Icons.person_outline, true, 3),
      _SectionItem('skills', 'Co-Scholastic Skills', Icons.radar, false, 4),
      _SectionItem(
          'activities', 'Activities & Achievements', Icons.emoji_events, false, 5),
      _SectionItem(
          'behavior', 'Behavior & Discipline', Icons.thumb_up, false, 6),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _footerController.dispose();
    _schoolNameController.dispose();
    _addressController.dispose();
    _mottoController.dispose();
    super.dispose();
  }

  void _loadExistingTemplate(ReportCardTemplateFull template) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = template.name;
    _footerController.text = template.footerText ?? '';
    _schoolNameController.text =
        template.headerConfig['school_name'] as String? ?? '';
    _addressController.text =
        template.headerConfig['address'] as String? ?? '';
    _mottoController.text =
        template.headerConfig['motto'] as String? ?? '';
    _layout = template.layout;
    _pageSize = template.pageSize;
    _isDefault = template.isDefault;
    _gradingScaleId = template.gradingScaleId;

    for (final ts in template.sections) {
      final idx = _sections.indexWhere((s) => s.type == ts.type);
      if (idx >= 0) {
        _sections[idx].enabled = ts.enabled;
        _sections[idx].order = ts.order;
      }
    }
    _sections.sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.templateId != null;

    // Load existing template if editing
    if (isEditing) {
      final templateAsync =
          ref.watch(rcTemplateByIdProvider(widget.templateId!));
      templateAsync.whenData((template) {
        if (template != null) {
          _loadExistingTemplate(template);
        }
      });
    }

    final gradingScalesAsync = ref.watch(gradingScalesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Template' : 'Create Template'),
        actions: [
          if (isEditing)
            TextButton.icon(
              onPressed: _previewTemplate,
              icon: const Icon(Icons.preview),
              label: const Text('Preview'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name *',
                      hintText: 'e.g., Standard Report Card 2024-25',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _layout,
                          decoration: const InputDecoration(
                            labelText: 'Layout',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'standard', child: Text('Standard')),
                            DropdownMenuItem(
                                value: 'detailed', child: Text('Detailed')),
                            DropdownMenuItem(
                                value: 'competency_based',
                                child: Text('Competency Based')),
                            DropdownMenuItem(
                                value: 'narrative', child: Text('Narrative')),
                          ],
                          onChanged: (v) =>
                              setState(() => _layout = v ?? 'standard'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _pageSize,
                          decoration: const InputDecoration(
                            labelText: 'Page Size',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'A4', child: Text('A4')),
                            DropdownMenuItem(
                                value: 'letter', child: Text('Letter')),
                          ],
                          onChanged: (v) =>
                              setState(() => _pageSize = v ?? 'A4'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  gradingScalesAsync.when(
                    data: (scales) => DropdownButtonFormField<String>(
                      value: _gradingScaleId,
                      decoration: const InputDecoration(
                        labelText: 'Grading Scale',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Default (CBSE)')),
                        ...scales.map((s) => DropdownMenuItem(
                            value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (v) =>
                          setState(() => _gradingScaleId = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading scales: $e'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Set as Default Template'),
                    subtitle: const Text(
                        'This template will be pre-selected during generation'),
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // School Header Config
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'School Header',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Displayed at the top of every report card',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _schoolNameController,
                    decoration: const InputDecoration(
                      labelText: 'School Name',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mottoController,
                    decoration: const InputDecoration(
                      labelText: 'School Motto / Tagline',
                      prefixIcon: Icon(Icons.format_quote),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sections (Reorderable)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Sections',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toggle sections and drag to reorder',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 16),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sections.length,
                    onReorder: _reorderSections,
                    itemBuilder: (context, index) {
                      final s = _sections[index];
                      return _SectionTile(
                        key: ValueKey(s.type),
                        item: s,
                        onToggle: (enabled) {
                          setState(() => s.enabled = enabled);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Footer',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _footerController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Footer Text',
                      hintText:
                          'e.g., This is a computer-generated report card...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _saveTemplate,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(isEditing ? 'Update Template' : 'Create Template'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _reorderSections(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, item);
      for (var i = 0; i < _sections.length; i++) {
        _sections[i].order = i;
      }
    });
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(rcFullRepositoryProvider);
      final data = {
        'tenant_id': repo.requireTenantId,
        'name': _nameController.text.trim(),
        'layout': _layout,
        'header_config': {
          'school_name': _schoolNameController.text.trim(),
          'address': _addressController.text.trim(),
          'motto': _mottoController.text.trim(),
        },
        'sections': _sections
            .map((s) => {
                  'type': s.type,
                  'enabled': s.enabled,
                  'order': s.order,
                  'config': <String, dynamic>{},
                })
            .toList(),
        'grading_scale_id': _gradingScaleId,
        'footer_text': _footerController.text.trim(),
        'is_default': _isDefault,
        'page_size': _pageSize,
      };

      if (widget.templateId != null) {
        await repo.updateTemplate(widget.templateId!, data);
      } else {
        await repo.createTemplate(
          ReportCardTemplateFull(
            id: '',
            tenantId: repo.requireTenantId,
            name: _nameController.text.trim(),
            layout: _layout,
            headerConfig: data['header_config'] as Map<String, dynamic>,
            sections: _sections
                .map((s) => TemplateSectionConfig(
                      type: s.type,
                      enabled: s.enabled,
                      order: s.order,
                    ))
                .toList(),
            gradingScaleId: _gradingScaleId,
            footerText: _footerController.text.trim(),
            isDefault: _isDefault,
            pageSize: _pageSize,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      ref.invalidate(rcTemplatesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.templateId != null
                ? 'Template updated'
                : 'Template created'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _previewTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview coming soon')),
    );
  }
}

class _SectionItem {
  final String type;
  final String label;
  final IconData icon;
  bool enabled;
  int order;

  _SectionItem(this.type, this.label, this.icon, this.enabled, this.order);
}

class _SectionTile extends StatelessWidget {
  final _SectionItem item;
  final ValueChanged<bool> onToggle;

  const _SectionTile({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.enabled
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.enabled
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: item.enabled ? AppColors.primary : Colors.grey,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: item.enabled ? null : Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: item.enabled,
              onChanged: onToggle,
            ),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
