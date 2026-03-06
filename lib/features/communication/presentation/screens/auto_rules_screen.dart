import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/communication.dart';
import '../../providers/communication_provider.dart';
import '../widgets/channel_selector.dart';

class AutoRulesScreen extends ConsumerStatefulWidget {
  const AutoRulesScreen({super.key});

  @override
  ConsumerState<AutoRulesScreen> createState() => _AutoRulesScreenState();
}

class _AutoRulesScreenState extends ConsumerState<AutoRulesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(autoRulesNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rulesAsync = ref.watch(autoRulesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Notification Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: rulesAsync.when(
        data: (rules) {
          if (rules.isEmpty) {
            return _buildEmptyState(theme);
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(autoRulesNotifierProvider.notifier).load();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                return _RuleCard(
                  rule: rules[index],
                  onToggle: (active) {
                    ref
                        .read(autoRulesNotifierProvider.notifier)
                        .toggle(rules[index].id, active);
                  },
                  onEdit: () => _showRuleEditor(context, rules[index]),
                  onDelete: () => _confirmDelete(rules[index]),
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
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(autoRulesNotifierProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRuleEditor(context, null),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
            Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Auto Rules',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up automatic notification rules to send alerts when events occur (e.g., student absent, fee overdue).',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showRuleEditor(context, null),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Rule',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRuleEditor(BuildContext context, AutoNotificationRule? rule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _RuleEditorSheet(
              rule: rule,
              scrollController: scrollController,
              onSave: (data) async {
                try {
                  if (rule != null) {
                    await ref
                        .read(autoRulesNotifierProvider.notifier)
                        .update(rule.id, data);
                  } else {
                    await ref
                        .read(autoRulesNotifierProvider.notifier)
                        .create(data);
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  void _confirmDelete(AutoNotificationRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: Text(
            'Delete "${rule.name}"? Automatic notifications for ${rule.triggerEvent.label} will stop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(autoRulesNotifierProvider.notifier).delete(rule.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Auto Rules'),
        content: const Text(
          'Auto notification rules automatically send messages when specific events occur in the school.\n\n'
          'For example:\n'
          '- When a student is marked absent, notify the parent via SMS and push\n'
          '- When a fee is overdue, send a reminder email\n'
          '- On a student\'s birthday, send a greeting\n\n'
          'Each rule can be configured with specific channels and delay times.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final AutoNotificationRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  IconData get _triggerIcon {
    switch (rule.triggerEvent) {
      case TriggerEvent.absentMarked:
        return Icons.person_off_outlined;
      case TriggerEvent.feeOverdue:
        return Icons.payment_outlined;
      case TriggerEvent.examPublished:
        return Icons.assignment_outlined;
      case TriggerEvent.assignmentDue:
        return Icons.task_outlined;
      case TriggerEvent.lowGrade:
        return Icons.trending_down_outlined;
      case TriggerEvent.birthday:
        return Icons.cake_outlined;
      case TriggerEvent.feePaymentReceived:
        return Icons.receipt_long_outlined;
      case TriggerEvent.reportCardPublished:
        return Icons.grade_outlined;
      case TriggerEvent.ptmScheduled:
        return Icons.groups_outlined;
      case TriggerEvent.emergencyAlert:
        return Icons.warning_amber_outlined;
    }
  }

  Color get _triggerColor {
    switch (rule.triggerEvent) {
      case TriggerEvent.absentMarked:
        return AppColors.error;
      case TriggerEvent.feeOverdue:
        return AppColors.warning;
      case TriggerEvent.examPublished:
        return AppColors.info;
      case TriggerEvent.assignmentDue:
        return AppColors.accent;
      case TriggerEvent.lowGrade:
        return AppColors.error;
      case TriggerEvent.birthday:
        return AppColors.success;
      case TriggerEvent.feePaymentReceived:
        return AppColors.secondary;
      case TriggerEvent.reportCardPublished:
        return AppColors.primary;
      case TriggerEvent.ptmScheduled:
        return AppColors.info;
      case TriggerEvent.emergencyAlert:
        return AppColors.error;
    }
  }

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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _triggerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_triggerIcon, color: _triggerColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Trigger: ${rule.triggerEvent.label}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _triggerColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: rule.isActive,
                onChanged: onToggle,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (rule.description != null && rule.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rule.description!,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              // Channels
              ChannelIndicatorRow(channels: rule.channels),
              const SizedBox(width: 8),
              // Target roles
              ...rule.targetRoles.take(3).map((role) {
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.roleColor(role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatRole(role),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.roleColor(role),
                    ),
                  ),
                );
              }),
              const Spacer(),
              if (rule.delayMinutes > 0)
                Text(
                  'Delay: ${rule.delayMinutes}min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Triggered ${rule.triggerCount} times',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
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

  String _formatRole(String role) {
    return role
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class _RuleEditorSheet extends StatefulWidget {
  final AutoNotificationRule? rule;
  final ScrollController scrollController;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _RuleEditorSheet({
    this.rule,
    required this.scrollController,
    required this.onSave,
  });

  @override
  State<_RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<_RuleEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TriggerEvent _triggerEvent;
  late List<CommunicationChannel> _channels;
  late List<String> _targetRoles;
  late bool _isActive;
  late int _delayMinutes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.rule?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.rule?.description ?? '');
    _triggerEvent = widget.rule?.triggerEvent ?? TriggerEvent.absentMarked;
    _channels = widget.rule?.channels ??
        [CommunicationChannel.push, CommunicationChannel.inApp];
    _targetRoles = widget.rule?.targetRoles ?? ['parent'];
    _isActive = widget.rule?.isActive ?? true;
    _delayMinutes = widget.rule?.delayMinutes ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Row(
            children: [
              Text(
                widget.rule != null ? 'Edit Rule' : 'New Auto Rule',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Rule Name',
              hintText: 'e.g., Notify Parents on Absence',
            ),
          ),
          const SizedBox(height: 12),

          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'What this rule does...',
            ),
          ),
          const SizedBox(height: 16),

          // Trigger event
          Text('Trigger Event',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<TriggerEvent>(
            value: _triggerEvent,
            decoration: const InputDecoration(
              hintText: 'Select trigger...',
            ),
            items: TriggerEvent.values.map((event) {
              return DropdownMenuItem(
                value: event,
                child: Text(event.label),
              );
            }).toList(),
            onChanged: (event) {
              if (event != null) setState(() => _triggerEvent = event);
            },
          ),
          const SizedBox(height: 16),

          // Channels
          Text('Notification Channels',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ChannelSelector(
            selectedChannels: _channels,
            onChanged: (channels) => setState(() => _channels = channels),
          ),
          const SizedBox(height: 16),

          // Target roles
          Text('Target Roles',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['parent', 'student', 'teacher'].map((role) {
              final isSelected = _targetRoles.contains(role);
              return FilterChip(
                label: Text(_formatRole(role)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _targetRoles.add(role);
                    } else {
                      _targetRoles.remove(role);
                    }
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Delay
          Text('Delay (minutes)',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Time to wait after trigger before sending. Set to 0 for immediate.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Slider(
            value: _delayMinutes.toDouble(),
            min: 0,
            max: 120,
            divisions: 24,
            label: '$_delayMinutes min',
            onChanged: (v) => setState(() => _delayMinutes = v.round()),
            activeColor: AppColors.primary,
          ),
          Center(
            child: Text('${_delayMinutes} minutes',
                style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 16),

          // Active toggle
          SwitchListTile(
            title: const Text('Active'),
            subtitle: const Text('Enable or disable this rule'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.rule != null ? 'Update Rule' : 'Create Rule',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rule name is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_channels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one channel'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      'trigger_event': _triggerEvent.value,
      'channels': _channels.map((c) => c.value).toList(),
      'target_roles': _targetRoles,
      'is_active': _isActive,
      'delay_minutes': _delayMinutes,
    };

    await widget.onSave(data);

    if (mounted) setState(() => _isSaving = false);
  }

  String _formatRole(String role) {
    return role
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
