import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/discipline.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/discipline_provider.dart';

class BehaviorPlanScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const BehaviorPlanScreen({super.key, this.studentId});

  @override
  ConsumerState<BehaviorPlanScreen> createState() =>
      _BehaviorPlanScreenState();
}

class _BehaviorPlanScreenState extends ConsumerState<BehaviorPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Behavior Plans'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Discontinued'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PlanList(
            studentId: widget.studentId,
            status: BehaviorPlanStatus.active,
          ),
          _PlanList(
            studentId: widget.studentId,
            status: BehaviorPlanStatus.completed,
          ),
          _PlanList(
            studentId: widget.studentId,
            status: BehaviorPlanStatus.discontinued,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlanDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreatePlanDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final studentIdController =
        TextEditingController(text: widget.studentId ?? '');
    final goals = <String>[];
    final strategies = <String>[];
    final goalController = TextEditingController();
    final strategyController = TextEditingController();
    DateTime? reviewDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Behavior Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (widget.studentId == null)
                      TextField(
                        controller: studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (widget.studentId == null) const SizedBox(height: 12),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Plan Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // Goals
                    const Text(
                      'Goals',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: goalController,
                            decoration: const InputDecoration(
                              hintText: 'Add a goal...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: AppColors.primary),
                          onPressed: () {
                            if (goalController.text.trim().isNotEmpty) {
                              setSheetState(() {
                                goals.add(goalController.text.trim());
                                goalController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (goals.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...goals.asMap().entries.map((e) => ListTile(
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.primary),
                              ),
                            ),
                            title: Text(e.value, style: const TextStyle(fontSize: 13)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 18, color: AppColors.error),
                              onPressed: () {
                                setSheetState(() => goals.removeAt(e.key));
                              },
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          )),
                    ],
                    const SizedBox(height: 12),

                    // Strategies
                    const Text(
                      'Strategies',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: strategyController,
                            decoration: const InputDecoration(
                              hintText: 'Add a strategy...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: AppColors.secondary),
                          onPressed: () {
                            if (strategyController.text.trim().isNotEmpty) {
                              setSheetState(() {
                                strategies
                                    .add(strategyController.text.trim());
                                strategyController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (strategies.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...strategies.asMap().entries.map((e) => ListTile(
                            leading: const Icon(Icons.lightbulb_outline,
                                size: 18, color: AppColors.secondary),
                            title: Text(e.value, style: const TextStyle(fontSize: 13)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 18, color: AppColors.error),
                              onPressed: () {
                                setSheetState(
                                    () => strategies.removeAt(e.key));
                              },
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          )),
                    ],
                    const SizedBox(height: 12),

                    // Review Date
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(reviewDate != null
                          ? 'Review: ${DateFormat('dd MMM yyyy').format(reviewDate!)}'
                          : 'Set Review Date'),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) {
                          setSheetState(() => reviewDate = d);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty ||
                              (widget.studentId == null &&
                                  studentIdController.text.trim().isEmpty)) {
                            return;
                          }
                          Navigator.pop(ctx);
                          await _createPlan(
                            studentId: widget.studentId ??
                                studentIdController.text.trim(),
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            goals: goals,
                            strategies: strategies,
                            reviewDate: reviewDate,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Create Plan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createPlan({
    required String studentId,
    required String title,
    String? description,
    required List<String> goals,
    required List<String> strategies,
    DateTime? reviewDate,
  }) async {
    try {
      final repo = ref.read(disciplineRepositoryProvider);
      final plan = BehaviorPlan(
        id: '',
        tenantId: repo.requireTenantId,
        studentId: studentId,
        createdBy: repo.requireUserId,
        title: title,
        description: description?.isNotEmpty == true ? description : null,
        goals: goals.map((g) => {'goal': g, 'status': 'pending'}).toList(),
        strategies: strategies,
        startDate: DateTime.now(),
        reviewDate: reviewDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createPlan(plan);

      if (mounted) {
        context.showSuccessSnackBar('Plan created successfully');
        ref.invalidate(behaviorPlansProvider(widget.studentId));
        ref.invalidate(activePlansProvider);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed: $e');
      }
    }
  }
}

class _PlanList extends ConsumerWidget {
  final String? studentId;
  final BehaviorPlanStatus status;

  const _PlanList({this.studentId, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(behaviorPlansProvider(studentId));

    return plansAsync.when(
      data: (plans) {
        final filtered = plans.where((p) => p.status == status).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment_outlined,
                    size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'No ${status.displayLabel.toLowerCase()} plans',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, idx) {
            final plan = filtered[idx];
            return _PlanCard(plan: plan);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final BehaviorPlan plan;

  const _PlanCard({required this.plan});

  Color get _statusColor {
    switch (plan.status) {
      case BehaviorPlanStatus.active:
        return AppColors.info;
      case BehaviorPlanStatus.completed:
        return AppColors.success;
      case BehaviorPlanStatus.discontinued:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalCount = plan.goals.length;
    final completedGoals = plan.goals
        .where((g) => (g as Map?)?['status'] == 'completed')
        .length;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: _statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      plan.studentName ?? 'Student',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.status.displayLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (plan.description != null) ...[
            const SizedBox(height: 8),
            Text(
              plan.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 10),

          // Goals progress
          if (goalCount > 0) ...[
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: goalCount > 0 ? completedGoals / goalCount : 0,
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.success),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completedGoals/$goalCount goals',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Footer
          Row(
            children: [
              Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'Started: ${DateFormat('dd MMM yyyy').format(plan.startDate)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              if (plan.reviewDate != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.event, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Review: ${DateFormat('dd MMM').format(plan.reviewDate!)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
              const Spacer(),
              if (plan.parentAcknowledged)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Parent Ack.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
