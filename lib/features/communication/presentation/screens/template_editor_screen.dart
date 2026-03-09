import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/communication.dart';
import '../../providers/communication_provider.dart';
import '../widgets/channel_selector.dart';
import '../widgets/template_preview.dart';

class TemplateEditorScreen extends ConsumerStatefulWidget {
  final CommunicationTemplate? template;

  const TemplateEditorScreen({super.key, this.template});

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  late TemplateCategory _category;
  late CommunicationChannel _channel;
  late bool _isActive;
  final List<String> _variables = [];
  bool _showPreview = false;
  bool _isSaving = false;

  bool get _isEditing => widget.template != null;

  static const List<String> _availableVariables = [
    'student_name',
    'parent_name',
    'class_name',
    'teacher_name',
    'school_name',
    'date',
    'time',
    'amount',
    'subject_name',
    'exam_name',
    'event_name',
    'attendance_date',
    'due_date',
    'grade',
    'percentage',
    'marks',
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.template?.name ?? '');
    _subjectController =
        TextEditingController(text: widget.template?.subject ?? '');
    _bodyController =
        TextEditingController(text: widget.template?.bodyTemplate ?? '');
    _category = widget.template?.category ?? TemplateCategory.general;
    _channel = widget.template?.channel ?? CommunicationChannel.inApp;
    _isActive = widget.template?.isActive ?? true;

    if (widget.template != null) {
      _variables.addAll(widget.template!.variables);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Template' : 'Create Template'),
        actions: [
          IconButton(
            icon: Icon(
              _showPreview ? Icons.edit_outlined : Icons.preview_outlined,
            ),
            tooltip: _showPreview ? 'Edit' : 'Preview',
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildForm(theme),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Template name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Template Name',
              hintText: 'e.g., Absence Alert to Parents',
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),

          // Category
          Text('Category',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TemplateCategory.values.map((cat) {
              return ChoiceChip(
                label: Text(cat.label),
                selected: _category == cat,
                onSelected: (_) => setState(() => _category = cat),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Channel
          Text('Channel',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ChannelSelector(
            selectedChannels: [_channel],
            allowMultiple: false,
            onChanged: (channels) {
              setState(() => _channel = channels.first);
            },
          ),
          const SizedBox(height: 16),

          // Subject (for email/in-app)
          if (_channel == CommunicationChannel.email ||
              _channel == CommunicationChannel.inApp) ...[
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                hintText: 'e.g., Attendance Alert - {{student_name}}',
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Body template
          Text('Message Body',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bodyController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText:
                  'Dear {{parent_name}},\n\nYour child {{student_name}} was marked absent on {{attendance_date}}.\n\nRegards,\n{{school_name}}',
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Message body is required' : null,
          ),
          const SizedBox(height: 16),

          // Variable insertion
          Text('Insert Variables',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Tap a variable to insert it at the cursor position.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableVariables.map((variable) {
              final isUsed = _variables.contains(variable);
              return ActionChip(
                label: Text(
                  '{{$variable}}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isUsed ? AppColors.primary : AppColors.info,
                  ),
                ),
                backgroundColor: isUsed
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.info.withValues(alpha: 0.08),
                side: BorderSide(
                  color: isUsed
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
                onPressed: () => _insertVariable(variable),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Active toggle
          SwitchListTile(
            title: const Text('Active'),
            subtitle: const Text('Inactive templates cannot be used in campaigns'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeThumbColor: AppColors.primary,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    _extractVariables();
    final previewTemplate = CommunicationTemplate(
      id: widget.template?.id ?? '',
      tenantId: '',
      name: _nameController.text,
      category: _category,
      subject: _subjectController.text.isNotEmpty
          ? _subjectController.text
          : null,
      bodyTemplate: _bodyController.text,
      variables: _variables,
      channel: _channel,
      isActive: _isActive,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: TemplatePreview(template: previewTemplate),
    );
  }

  void _insertVariable(String variable) {
    final text = '{{$variable}}';
    final selection = _bodyController.selection;

    if (selection.isValid && selection.start >= 0) {
      final newText = _bodyController.text.replaceRange(
        selection.start,
        selection.end,
        text,
      );
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + text.length,
        ),
      );
    } else {
      _bodyController.text += text;
    }

    if (!_variables.contains(variable)) {
      setState(() => _variables.add(variable));
    }
  }

  void _extractVariables() {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    final body = _bodyController.text;
    final subject = _subjectController.text;
    final allText = '$body $subject';
    final matches = regex.allMatches(allText);

    _variables.clear();
    for (final match in matches) {
      final variable = match.group(1)!;
      if (!_variables.contains(variable)) {
        _variables.add(variable);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    _extractVariables();

    setState(() => _isSaving = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'category': _category.value,
        'subject': _subjectController.text.trim().isNotEmpty
            ? _subjectController.text.trim()
            : null,
        'body_template': _bodyController.text,
        'variables': _variables,
        'channel': _channel.value,
        'is_active': _isActive,
      };

      if (_isEditing) {
        await ref
            .read(templatesNotifierProvider.notifier)
            .update(widget.template!.id, data);
      } else {
        await ref.read(templatesNotifierProvider.notifier).create(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Template ${_isEditing ? "updated" : "created"} successfully'),
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
