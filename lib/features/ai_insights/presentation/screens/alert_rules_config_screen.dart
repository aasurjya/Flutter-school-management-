import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/early_warning_alert.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/early_warning_provider.dart';

/// Admin screen for managing alert rules configuration.
///
/// Displays a list of existing [AlertRule]s that can be toggled on/off,
/// and provides a bottom sheet form to create new rules with custom
/// conditions (e.g. "Attendance < 75% over 30 days").
class AlertRulesConfigScreen extends ConsumerWidget {
  const AlertRulesConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(alertRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Rule',
            onPressed: () => _showAddRuleSheet(context, ref),
          ),
        ],
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load rules',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        data: (rules) {
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rule_folder_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No alert rules configured',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to create your first rule',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRuleSheet(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Rule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return _AlertRuleCard(
                rule: rule,
                onToggle: (isActive) =>
                    _toggleRule(context, ref, rule.id, isActive),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleSheet(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Toggle rule active state
  // -----------------------------------------------------------------------
  Future<void> _toggleRule(
    BuildContext context,
    WidgetRef ref,
    String ruleId,
    bool isActive,
  ) async {
    try {
      final repo = ref.read(earlyWarningRepositoryProvider);
      await repo.toggleAlertRule(ruleId, isActive);
      ref.invalidate(alertRulesProvider);
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Failed to update rule: $e');
      }
    }
  }

  // -----------------------------------------------------------------------
  // Add Rule Bottom Sheet
  // -----------------------------------------------------------------------
  void _showAddRuleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddRuleSheet(ref: ref),
    );
  }
}

// ==========================================================================
// Alert Rule Card
// ==========================================================================

class _AlertRuleCard extends StatelessWidget {
  final AlertRule rule;
  final ValueChanged<bool> onToggle;

  const _AlertRuleCard({
    required this.rule,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = rule.severity.color;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rule name + active toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  rule.ruleName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: rule.isActive ? null : Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Switch.adaptive(
                value: rule.isActive,
                onChanged: onToggle,
                activeTrackColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Category and severity chips
          Row(
            children: [
              _buildChip(
                label: rule.category.displayLabel,
                icon: rule.category.icon,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: rule.severity.displayLabel,
                color: severityColor,
              ),
              if (rule.notifyParents) ...[
                const SizedBox(width: 8),
                _buildChip(
                  label: 'Notifies Parents',
                  icon: Icons.notifications_active,
                  color: AppColors.info,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Condition logic summary
          Text(
            _buildConditionSummary(rule.conditionLogic),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Converts the rule's [conditionLogic] JSON to a human-readable summary.
  String _buildConditionSummary(Map<String, dynamic> logic) {
    if (logic.isEmpty) return 'No conditions configured';

    final type = logic['condition_type'] ?? logic['type'] ?? '';
    final operator = logic['operator'] ?? '';
    final value = logic['value'] ?? '';
    final days = logic['days'] ?? logic['time_window_days'];

    final typeLabel = _conditionTypeLabel(type.toString());

    final buffer = StringBuffer(typeLabel);
    if (operator.toString().isNotEmpty && value.toString().isNotEmpty) {
      buffer.write(' $operator $value');
      if (type.toString().contains('percentage')) buffer.write('%');
    }
    if (days != null) {
      buffer.write(' over $days days');
    }

    return buffer.toString();
  }

  String _conditionTypeLabel(String type) {
    switch (type) {
      case 'attendance_percentage':
        return 'Attendance';
      case 'exam_average':
        return 'Exam Average';
      case 'fee_pending_percentage':
        return 'Pending Fee';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}

// ==========================================================================
// Add Rule Bottom Sheet
// ==========================================================================

class _AddRuleSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddRuleSheet({required this.ref});

  @override
  State<_AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends State<_AddRuleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ruleNameController = TextEditingController();
  final _valueController = TextEditingController();
  final _daysController = TextEditingController();

  AlertCategory _selectedCategory = AlertCategory.attendanceIssue;
  AlertSeverity _selectedSeverity = AlertSeverity.warning;
  String _conditionType = 'attendance_percentage';
  String _operator = '<';
  bool _notifyParents = false;
  bool _isSaving = false;

  static const _conditionTypes = [
    ('attendance_percentage', 'Attendance %'),
    ('exam_average', 'Exam Average'),
    ('fee_pending_percentage', 'Pending Fee %'),
  ];

  static const _operators = ['<', '>', '<=', '>='];

  @override
  void dispose() {
    _ruleNameController.dispose();
    _valueController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create Alert Rule',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),

              // Rule name
              TextFormField(
                controller: _ruleNameController,
                decoration: InputDecoration(
                  labelText: 'Rule Name',
                  hintText: 'e.g. Low Attendance Warning',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.inputFillLight,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Rule name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<AlertCategory>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.inputFillLight,
                ),
                items: AlertCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(cat.displayLabel),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Severity dropdown
              DropdownButtonFormField<AlertSeverity>(
                initialValue: _selectedSeverity,
                decoration: InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.inputFillLight,
                ),
                items: AlertSeverity.values.map((sev) {
                  return DropdownMenuItem(
                    value: sev,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: sev.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(sev.displayLabel),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSeverity = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Condition type dropdown
              DropdownButtonFormField<String>(
                initialValue: _conditionType,
                decoration: InputDecoration(
                  labelText: 'Condition Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.inputFillLight,
                ),
                items: _conditionTypes.map((entry) {
                  return DropdownMenuItem(
                    value: entry.$1,
                    child: Text(entry.$2),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _conditionType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Operator + Value row
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      initialValue: _operator,
                      decoration: InputDecoration(
                        labelText: 'Operator',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.inputFillLight,
                      ),
                      items: _operators.map((op) {
                        return DropdownMenuItem(value: op, child: Text(op));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _operator = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Value',
                        hintText: 'e.g. 75',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.inputFillLight,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Must be a number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Days (time window)
              TextFormField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Time Window (days)',
                  hintText: 'e.g. 30 (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.inputFillLight,
                ),
              ),
              const SizedBox(height: 16),

              // Notify parents checkbox
              CheckboxListTile(
                value: _notifyParents,
                onChanged: (value) {
                  setState(() => _notifyParents = value ?? false);
                },
                title: const Text(
                  'Notify parents when alert triggers',
                  style: TextStyle(fontSize: 14),
                ),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveRule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Rule',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveRule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final conditionLogic = <String, dynamic>{
        'condition_type': _conditionType,
        'operator': _operator,
        'value': double.tryParse(_valueController.text.trim()) ?? 0,
      };

      final days = int.tryParse(_daysController.text.trim());
      if (days != null && days > 0) {
        conditionLogic['time_window_days'] = days;
      }

      final repo = widget.ref.read(earlyWarningRepositoryProvider);
      await repo.createAlertRule({
        'rule_name': _ruleNameController.text.trim(),
        'alert_category': _selectedCategory.dbValue,
        'severity': _selectedSeverity.dbValue,
        'condition_logic': conditionLogic,
        'notify_parents': _notifyParents,
      });

      widget.ref.invalidate(alertRulesProvider);

      if (mounted) {
        context.showSuccessSnackBar('Alert rule created successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to create rule: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
