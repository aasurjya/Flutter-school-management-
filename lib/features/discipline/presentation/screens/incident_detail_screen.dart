import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/discipline.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/discipline_provider.dart';
import '../widgets/severity_badge.dart';

class IncidentDetailScreen extends ConsumerStatefulWidget {
  final String incidentId;

  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  ConsumerState<IncidentDetailScreen> createState() =>
      _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends ConsumerState<IncidentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final incidentAsync =
        ref.watch(incidentDetailProvider(widget.incidentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'escalate',
                child: ListTile(
                  leading: Icon(Icons.arrow_upward, color: AppColors.error),
                  title: Text('Escalate'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'resolve',
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: AppColors.success),
                  title: Text('Mark Resolved'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'add_action',
                child: ListTile(
                  leading: Icon(Icons.add_task, color: AppColors.info),
                  title: Text('Add Action'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: incidentAsync.when(
        data: (incident) => _buildContent(context, incident),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error: $e'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(incidentDetailProvider(widget.incidentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BehaviorIncident incident) {
    final dateStr =
        DateFormat('EEEE, dd MMMM yyyy').format(incident.incidentDate);
    final timeStr = incident.incidentTime ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: incident.studentPhotoUrl != null
                          ? NetworkImage(incident.studentPhotoUrl!)
                          : null,
                      child: incident.studentPhotoUrl == null
                          ? Text(
                              (incident.studentName ?? 'S')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.studentName ?? 'Unknown Student',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () => context.push(
                              '/discipline/student/${incident.studentId}',
                            ),
                            child: const Text(
                              'View behavior profile',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SeverityBadge(severity: incident.severity),
                    const SizedBox(width: 8),
                    StatusBadge(status: incident.status),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incident Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: dateStr,
                ),
                if (timeStr.isNotEmpty)
                  _DetailRow(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: timeStr,
                  ),
                if (incident.location != null)
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: incident.location!,
                  ),
                if (incident.categoryName != null)
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: incident.categoryName!,
                  ),
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Reported by',
                  value: incident.reporterName ?? 'Unknown',
                ),
                const Divider(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  incident.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Witnesses
          if (incident.witnesses.isNotEmpty) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.people_outline, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Witnesses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: incident.witnesses.map((w) {
                      return Chip(
                        avatar: const Icon(Icons.person, size: 16),
                        label: Text(
                          w.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Actions Taken
          const Text(
            'Actions Taken',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (incident.actions == null || incident.actions!.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'No actions taken yet',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...incident.actions!.map((action) => _ActionCard(action: action)),
          const SizedBox(height: 16),

          // Resolution Notes
          if (incident.resolutionNotes != null &&
              incident.resolutionNotes!.isNotEmpty) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.note_outlined, size: 18, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(
                        'Resolution Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident.resolutionNotes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Evidence
          if (incident.evidenceUrls.isNotEmpty) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.attach_file, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Evidence / Attachments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...incident.evidenceUrls.map((url) => ListTile(
                        leading: const Icon(Icons.image_outlined),
                        title: Text(
                          url.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) async {
    final repo = ref.read(disciplineRepositoryProvider);

    try {
      switch (action) {
        case 'escalate':
          await repo.updateIncident(
            widget.incidentId,
            {'status': 'escalated'},
          );
          if (mounted) {
            context.showSuccessSnackBar('Incident escalated');
            ref.invalidate(incidentDetailProvider(widget.incidentId));
          }
          break;
        case 'resolve':
          final notes = await _showResolutionDialog();
          if (notes != null) {
            await repo.updateIncident(widget.incidentId, {
              'status': 'resolved',
              'resolution_notes': notes,
            });
            if (mounted) {
              context.showSuccessSnackBar('Incident resolved');
              ref.invalidate(incidentDetailProvider(widget.incidentId));
            }
          }
          break;
        case 'add_action':
          _showAddActionDialog();
          break;
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error: $e');
      }
    }
  }

  Future<String?> _showResolutionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Incident'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Resolution notes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  void _showAddActionDialog() {
    BehaviorActionType selectedType = BehaviorActionType.verbalWarning;
    final notesController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Action'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<BehaviorActionType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Action Type',
                      border: OutlineInputBorder(),
                    ),
                    items: BehaviorActionType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.displayLabel),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (d != null) {
                              setDialogState(() => startDate = d);
                            }
                          },
                          child: Text(
                            startDate != null
                                ? '${startDate!.day}/${startDate!.month}'
                                : 'Start Date',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (d != null) {
                              setDialogState(() => endDate = d);
                            }
                          },
                          child: Text(
                            endDate != null
                                ? '${endDate!.day}/${endDate!.month}'
                                : 'End Date',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final repo = ref.read(disciplineRepositoryProvider);
                    final action = BehaviorAction(
                      id: '',
                      incidentId: widget.incidentId,
                      actionType: selectedType,
                      assignedBy: repo.requireUserId,
                      startDate: startDate,
                      endDate: endDate,
                      notes: notesController.text.isNotEmpty
                          ? notesController.text
                          : null,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await repo.createAction(action);
                    ref.invalidate(
                      incidentDetailProvider(widget.incidentId),
                    );
                    if (mounted) {
                      context.showSuccessSnackBar('Action added');
                    }
                  } catch (e) {
                    if (mounted) {
                      context.showErrorSnackBar('Failed: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final BehaviorAction action;

  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: action.completed
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action.completed
                    ? Icons.check_circle
                    : Icons.pending_actions,
                color: action.completed ? AppColors.success : AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.actionType.displayLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (action.notes != null)
                    Text(
                      action.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (action.startDate != null || action.endDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (action.startDate != null)
                          'From: ${DateFormat('dd MMM').format(action.startDate!)}',
                        if (action.endDate != null)
                          'To: ${DateFormat('dd MMM').format(action.endDate!)}',
                      ].join(' | '),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  if (action.assignedByName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'By: ${action.assignedByName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: action.completed
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                action.completed ? 'Done' : 'Pending',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      action.completed ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
