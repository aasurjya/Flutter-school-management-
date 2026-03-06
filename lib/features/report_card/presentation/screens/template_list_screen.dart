import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/report_card_full.dart';
import '../../providers/report_card_provider.dart';

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(rcTemplatesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Card Templates'),
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('No templates created yet'),
                  const SizedBox(height: 8),
                  Text(
                    'Create a template to define report card layout',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/report-cards/templates/new'),
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
              final t = templates[index];
              return _TemplateCard(
                template: t,
                onTap: () =>
                    context.push('/report-cards/templates/${t.id}'),
                onDelete: () => _deleteTemplate(context, ref, t.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/report-cards/templates/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _deleteTemplate(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template'),
        content:
            const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
        await ref
            .read(rcFullRepositoryProvider)
            .deleteTemplate(id);
        ref.invalidate(rcTemplatesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to delete: $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final ReportCardTemplateFull template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledSections =
        template.sections.where((s) => s.enabled).toList();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
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
                  _layoutIcon(template.layout),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (template.isDefault)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${template.layoutDisplay} layout  |  ${template.pageSize}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 18),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    onTap();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: enabledSections.map((s) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _sectionColor(s.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _sectionLabel(s.type),
                  style: TextStyle(
                    fontSize: 11,
                    color: _sectionColor(s.type),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _layoutIcon(String layout) {
    switch (layout) {
      case 'standard':
        return Icons.description;
      case 'detailed':
        return Icons.view_agenda;
      case 'competency_based':
        return Icons.radar;
      case 'narrative':
        return Icons.text_snippet;
      default:
        return Icons.description;
    }
  }

  String _sectionLabel(String type) {
    switch (type) {
      case 'grades':
        return 'Grades';
      case 'attendance':
        return 'Attendance';
      case 'behavior':
        return 'Behavior';
      case 'teacher_comment':
        return 'Teacher Comment';
      case 'principal_comment':
        return 'Principal Comment';
      case 'skills':
        return 'Skills';
      case 'activities':
        return 'Activities';
      default:
        return type;
    }
  }

  Color _sectionColor(String type) {
    switch (type) {
      case 'grades':
        return AppColors.primary;
      case 'attendance':
        return AppColors.success;
      case 'behavior':
        return AppColors.accent;
      case 'teacher_comment':
        return AppColors.info;
      case 'principal_comment':
        return AppColors.adminColor;
      case 'skills':
        return AppColors.secondary;
      case 'activities':
        return AppColors.parentColor;
      default:
        return Colors.grey;
    }
  }
}
