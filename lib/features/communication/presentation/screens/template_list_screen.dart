import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/communication.dart';
import '../../providers/communication_provider.dart';
import '../widgets/channel_selector.dart';

class TemplateListScreen extends ConsumerStatefulWidget {
  const TemplateListScreen({super.key});

  @override
  ConsumerState<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends ConsumerState<TemplateListScreen> {
  TemplateCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(templatesNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(templatesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(theme, null, 'All'),
                  ...TemplateCategory.values.map(
                    (cat) => _buildCategoryChip(theme, cat, cat.label),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Templates list
          Expanded(
            child: templatesAsync.when(
              data: (templates) {
                final filtered = _selectedCategory != null
                    ? templates
                        .where((t) => t.category == _selectedCategory)
                        .toList()
                    : templates;

                if (filtered.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(templatesNotifierProvider.notifier)
                        .load(category: _selectedCategory);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _TemplateCard(
                        template: filtered[index],
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/communication/templates/edit',
                          arguments: filtered[index],
                        ),
                        onToggle: (active) {
                          ref
                              .read(templatesNotifierProvider.notifier)
                              .toggle(filtered[index].id, active);
                        },
                        onDelete: () => _confirmDelete(filtered[index]),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(templatesNotifierProvider.notifier).load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/communication/templates/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryChip(
      ThemeData theme, TemplateCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
          ref
              .read(templatesNotifierProvider.notifier)
              .load(category: category);
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined,
                size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'No Templates Found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create message templates to quickly send common notifications.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(CommunicationTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
            'Are you sure you want to delete "${template.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(templatesNotifierProvider.notifier)
                  .delete(template.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final CommunicationTemplate template;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  Color get _categoryColor {
    switch (template.category) {
      case TemplateCategory.feeReminder:
        return AppColors.warning;
      case TemplateCategory.attendanceAlert:
        return AppColors.error;
      case TemplateCategory.examNotice:
        return AppColors.info;
      case TemplateCategory.eventInvite:
        return AppColors.success;
      case TemplateCategory.general:
        return AppColors.textSecondaryLight;
      case TemplateCategory.emergency:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  ChannelSelector.iconForChannel(template.channel),
                  size: 20,
                  color: _categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            template.category.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _categoryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          template.channel.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Active toggle
              Switch(
                value: template.isActive,
                onChanged: onToggle,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (template.subject != null && template.subject!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Subject: ${template.subject}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            template.bodyTemplate,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (template.variables.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: template.variables.take(5).map((v) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '{{$v}}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: AppColors.info,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
