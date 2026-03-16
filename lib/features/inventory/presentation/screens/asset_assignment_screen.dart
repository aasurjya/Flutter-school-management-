import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';
import '../../providers/inventory_provider.dart';

class AssetAssignmentScreen extends ConsumerStatefulWidget {
  final String? preselectedAssetId;

  const AssetAssignmentScreen({super.key, this.preselectedAssetId});

  @override
  ConsumerState<AssetAssignmentScreen> createState() =>
      _AssetAssignmentScreenState();
}

class _AssetAssignmentScreenState
    extends ConsumerState<AssetAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Assignments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Assign New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveAssignmentsTab(),
          _AssignNewTab(preselectedAssetId: widget.preselectedAssetId),
        ],
      ),
    );
  }
}

class _ActiveAssignmentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(activeAssignmentsProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_outlined,
                    size: 64, color: AppColors.textTertiaryLight),
                const SizedBox(height: 16),
                Text(
                  'No active assignments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final a = assignments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.info.withValues(alpha: 0.1),
                          child: const Icon(Icons.person,
                              color: AppColors.info, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.assignedToName ?? 'Unknown User',
                                style:
                                    theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (a.asset != null)
                                Text(
                                  '${a.asset!.name} (${a.asset!.assetCode})',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (a.isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Overdue ${a.daysOverdue}d',
                              style:
                                  theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: AppColors.textTertiaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned: ${dateFormat.format(a.assignedDate)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        if (a.expectedReturnDate != null)
                          Text(
                            'Due: ${dateFormat.format(a.expectedReturnDate!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: a.isOverdue
                                  ? AppColors.error
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showReturnDialog(context, ref, a),
                        icon: const Icon(Icons.assignment_return),
                        label: const Text('Return Asset'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _showReturnDialog(
      BuildContext context, WidgetRef ref, AssetAssignment assignment) {
    AssetCondition returnCondition = AssetCondition.good;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Return Asset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<AssetCondition>(
                initialValue: returnCondition,
                decoration: const InputDecoration(
                  labelText: 'Condition at Return',
                ),
                items: AssetCondition.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(
                        () => returnCondition = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any remarks about the return',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final repo = ref.read(inventoryRepositoryProvider);
                  await repo.returnAsset(
                    assignmentId: assignment.id,
                    returnCondition: returnCondition,
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  );
                  ref.invalidate(activeAssignmentsProvider);
                  ref.invalidate(assetsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Asset returned successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Confirm Return'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignNewTab extends ConsumerStatefulWidget {
  final String? preselectedAssetId;

  const _AssignNewTab({this.preselectedAssetId});

  @override
  ConsumerState<_AssignNewTab> createState() => _AssignNewTabState();
}

class _AssignNewTabState extends ConsumerState<_AssignNewTab> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAssetId;
  final _userIdController = TextEditingController();
  DateTime? _expectedReturnDate;
  AssetCondition _condition = AssetCondition.good;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAssetId = widget.preselectedAssetId;
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableAssetsAsync = ref.watch(assetsProvider(
      const AssetFilter(status: 'available'),
    ));
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asset selection
            availableAssetsAsync.when(
              data: (assets) => DropdownButtonFormField<String>(
                initialValue: _selectedAssetId,
                decoration: const InputDecoration(
                  labelText: 'Select Asset *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: assets.map((a) {
                  return DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} (${a.assetCode})'),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedAssetId = value),
                validator: (v) => v == null ? 'Select an asset' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) =>
                  const Text('Error loading available assets'),
            ),
            const SizedBox(height: 16),

            // User ID (in production would be a user search/picker)
            TextFormField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'Assign To (User ID) *',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Enter the user ID to assign to',
              ),
              validator: (v) =>
                  v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Expected return date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                _expectedReturnDate != null
                    ? 'Expected Return: ${dateFormat.format(_expectedReturnDate!)}'
                    : 'Set Expected Return Date (optional)',
              ),
              trailing: _expectedReturnDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear',
                      onPressed: () =>
                          setState(() => _expectedReturnDate = null),
                    )
                  : null,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _expectedReturnDate = date);
                }
              },
            ),
            const SizedBox(height: 16),

            // Condition at assignment
            DropdownButtonFormField<AssetCondition>(
              initialValue: _condition,
              decoration: const InputDecoration(
                labelText: 'Condition at Assignment',
                prefixIcon: Icon(Icons.assessment_outlined),
              ),
              items: AssetCondition.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _condition = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.assignment_ind),
              label: const Text('Assign Asset'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.assignAsset(
        assetId: _selectedAssetId!,
        assignedTo: _userIdController.text.trim(),
        expectedReturnDate: _expectedReturnDate,
        condition: _condition,
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text,
      );

      ref.invalidate(activeAssignmentsProvider);
      ref.invalidate(assetsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Asset assigned successfully')),
        );
        context.pop();
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
}
