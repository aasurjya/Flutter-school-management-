import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/certificate.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/certificate_provider.dart';

class CertificateTemplateScreen extends ConsumerStatefulWidget {
  const CertificateTemplateScreen({super.key});

  @override
  ConsumerState<CertificateTemplateScreen> createState() =>
      _CertificateTemplateScreenState();
}

class _CertificateTemplateScreenState
    extends ConsumerState<CertificateTemplateScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(templateNotifierProvider.notifier).loadTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(templateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Templates'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTemplateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.design_services,
                      size: 64, color: AppColors.textTertiaryLight),
                  const SizedBox(height: 16),
                  Text(
                    'No templates yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showCreateTemplateDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Template'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _TemplateCard(
                template: template,
                onEdit: () =>
                    _showEditTemplateDialog(context, template),
                onDelete: () => _confirmDelete(template),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final nav = Navigator.of(context);
        return _TemplateForm(
          onSubmit: (data) async {
            await ref
                .read(templateNotifierProvider.notifier)
                .createTemplate(data);
            if (mounted) nav.pop();
          },
        );
      },
    );
  }

  void _showEditTemplateDialog(
      BuildContext context, CertificateTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final nav = Navigator.of(context);
        return _TemplateForm(
          template: template,
          onSubmit: (data) async {
            await ref
                .read(templateNotifierProvider.notifier)
                .updateTemplate(template.id, data);
            if (mounted) nav.pop();
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(CertificateTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text(
            'Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(templateNotifierProvider.notifier)
          .deleteTemplate(template.id);
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final CertificateTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _typeColor(template.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _typeIcon(template.type),
              color: _typeColor(template.type),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  template.type.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                if (template.variables.isNotEmpty)
                  Text(
                    '${template.variables.length} variables',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: template.isActive
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  template.isActive ? 'Active' : 'Inactive',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: template.isActive
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
                color: AppColors.primary,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(CertificateType type) {
    switch (type) {
      case CertificateType.transfer:
        return AppColors.info;
      case CertificateType.bonafide:
        return AppColors.success;
      case CertificateType.character:
        return AppColors.accent;
      case CertificateType.migration:
        return AppColors.primaryLight;
      case CertificateType.achievement:
        return AppColors.gradeA;
      case CertificateType.participation:
        return AppColors.gradeB;
      case CertificateType.merit:
        return AppColors.gradeC;
      case CertificateType.custom:
        return AppColors.primary;
    }
  }

  IconData _typeIcon(CertificateType type) {
    switch (type) {
      case CertificateType.transfer:
        return Icons.swap_horiz;
      case CertificateType.bonafide:
        return Icons.verified;
      case CertificateType.character:
        return Icons.person_pin;
      case CertificateType.migration:
        return Icons.flight;
      case CertificateType.achievement:
        return Icons.emoji_events;
      case CertificateType.participation:
        return Icons.groups;
      case CertificateType.merit:
        return Icons.star;
      case CertificateType.custom:
        return Icons.description;
    }
  }
}

class _TemplateForm extends StatefulWidget {
  final CertificateTemplate? template;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const _TemplateForm({this.template, required this.onSubmit});

  @override
  State<_TemplateForm> createState() => _TemplateFormState();
}

class _TemplateFormState extends State<_TemplateForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  CertificateType _type = CertificateType.custom;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _type = widget.template!.type;
      _isActive = widget.template!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.template != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Edit Template' : 'New Template',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name *',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CertificateType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Certificate Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: CertificateType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Available for issuing'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isLoading = true);
                          try {
                            await widget.onSubmit({
                              'name': _nameController.text.trim(),
                              'type': _type.value,
                              'is_active': _isActive,
                              'layout_data': widget.template
                                      ?.layoutData ??
                                  {
                                    'margins': {
                                      'top': 40,
                                      'bottom': 40,
                                      'left': 40,
                                      'right': 40,
                                    },
                                    'fields': [],
                                  },
                              'variables':
                                  widget.template?.variables ?? [],
                            });
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  child: Text(
                    _isLoading
                        ? 'Saving...'
                        : isEdit
                            ? 'Update Template'
                            : 'Create Template',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
