import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/discipline.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/discipline_provider.dart';

class DetentionManagementScreen extends ConsumerStatefulWidget {
  const DetentionManagementScreen({super.key});

  @override
  ConsumerState<DetentionManagementScreen> createState() =>
      _DetentionManagementScreenState();
}

class _DetentionManagementScreenState
    extends ConsumerState<DetentionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

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
        title: const Text('Detention Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assignments'),
            Tab(text: 'Schedules'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentsTab(),
          _buildSchedulesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignDetentionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Assign Detention'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    final assignmentsAsync =
        ref.watch(detentionAssignmentsProvider(_selectedDate));

    return Column(
      children: [
        // Date selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous',
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate
                          .subtract(const Duration(days: 1));
                    });
                  },
                ),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() => _selectedDate = d);
                      },
                      child: Text(
                        DateFormat('EEEE, dd MMM yyyy')
                            .format(_selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next',
                  onPressed: () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.add(const Duration(days: 1));
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        // Assignments list
        Expanded(
          child: assignmentsAsync.when(
            data: (assignments) {
              if (assignments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No detentions for this date',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: assignments.length,
                itemBuilder: (context, idx) {
                  final a = assignments[idx];
                  return _DetentionAssignmentCard(
                    assignment: a,
                    onStatusChange: (newStatus) =>
                        _updateAssignmentStatus(a.id, newStatus),
                    onCheckIn: () => _checkIn(a.id),
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulesTab() {
    final schedulesAsync = ref.watch(detentionSchedulesProvider);

    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'No detention schedules set up',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showCreateScheduleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Schedule'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedules.length + 1,
          itemBuilder: (context, idx) {
            if (idx == schedules.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton.icon(
                  onPressed: _showCreateScheduleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Schedule'),
                ),
              );
            }
            final s = schedules[idx];
            return _ScheduleCard(schedule: s);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _updateAssignmentStatus(
    String id,
    String newStatus,
  ) async {
    try {
      final repo = ref.read(disciplineRepositoryProvider);
      await repo.updateDetentionAssignment(id, {'status': newStatus});
      ref.invalidate(detentionAssignmentsProvider(_selectedDate));
      if (mounted) {
        context.showSuccessSnackBar('Status updated');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed: $e');
    }
  }

  Future<void> _checkIn(String id) async {
    try {
      final repo = ref.read(disciplineRepositoryProvider);
      await repo.updateDetentionAssignment(id, {
        'check_in_time': DateTime.now().toIso8601String(),
        'status': 'served',
      });
      ref.invalidate(detentionAssignmentsProvider(_selectedDate));
      if (mounted) {
        context.showSuccessSnackBar('Student checked in');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed: $e');
    }
  }

  void _showAssignDetentionDialog() {
    final studentIdController = TextEditingController();
    final notesController = TextEditingController();
    DateTime detentionDate = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assign Detention',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Student ID *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(detentionDate)}',
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: detentionDate,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) {
                        setSheetState(() => detentionDate = d);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (studentIdController.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        try {
                          final repo =
                              ref.read(disciplineRepositoryProvider);
                          final assignment = DetentionAssignment(
                            id: '',
                            tenantId: repo.requireTenantId,
                            studentId: studentIdController.text.trim(),
                            detentionDate: detentionDate,
                            assignedBy: repo.requireUserId,
                            notes: notesController.text.isNotEmpty
                                ? notesController.text
                                : null,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          await repo
                              .createDetentionAssignment(assignment);
                          ref.invalidate(
                            detentionAssignmentsProvider(_selectedDate),
                          );
                          if (mounted) {
                            messenger.showSnackBar(const SnackBar(
                              content: Text('Detention assigned'),
                              backgroundColor: AppColors.success,
                            ));
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(SnackBar(
                              content: Text('Failed: $e'),
                              backgroundColor: AppColors.error,
                            ));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Assign'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateScheduleDialog() {
    int dayOfWeek = 0;
    TimeOfDay startTime = const TimeOfDay(hour: 15, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 16, minute: 0);
    final locationController = TextEditingController();
    final capacityController = TextEditingController(text: '30');
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            const days = [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ];
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Detention Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: dayOfWeek,
                    decoration: const InputDecoration(
                      labelText: 'Day of Week',
                      border: OutlineInputBorder(),
                    ),
                    items: days.asMap().entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => dayOfWeek = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (t != null) {
                              setSheetState(() => startTime = t);
                            }
                          },
                          child: Text('Start: ${startTime.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (t != null) {
                              setSheetState(() => endTime = t);
                            }
                          },
                          child: Text('End: ${endTime.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location *',
                      hintText: 'e.g. Room 101',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (locationController.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        try {
                          final repo =
                              ref.read(disciplineRepositoryProvider);
                          String timeToStr(TimeOfDay t) =>
                              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
                          final schedule = DetentionSchedule(
                            id: '',
                            tenantId: repo.requireTenantId,
                            dayOfWeek: dayOfWeek,
                            startTime: timeToStr(startTime),
                            endTime: timeToStr(endTime),
                            location: locationController.text.trim(),
                            capacity:
                                int.tryParse(capacityController.text) ?? 30,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          await repo.createDetentionSchedule(schedule);
                          ref.invalidate(detentionSchedulesProvider);
                          if (mounted) {
                            messenger.showSnackBar(const SnackBar(
                              content: Text('Schedule created'),
                              backgroundColor: AppColors.success,
                            ));
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(SnackBar(
                              content: Text('Failed: $e'),
                              backgroundColor: AppColors.error,
                            ));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Create Schedule'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DetentionAssignmentCard extends StatelessWidget {
  final DetentionAssignment assignment;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onCheckIn;

  const _DetentionAssignmentCard({
    required this.assignment,
    required this.onStatusChange,
    required this.onCheckIn,
  });

  Color get _statusColor {
    switch (assignment.status) {
      case DetentionAssignmentStatus.assigned:
        return AppColors.warning;
      case DetentionAssignmentStatus.served:
        return AppColors.success;
      case DetentionAssignmentStatus.missed:
        return AppColors.error;
      case DetentionAssignmentStatus.excused:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (assignment.studentName ?? 'S')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.studentName ?? 'Unknown Student',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (assignment.notes != null)
                      Text(
                        assignment.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  assignment.status.displayLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (assignment.status == DetentionAssignmentStatus.assigned) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('Check In'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                    ),
                    onPressed: onCheckIn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Missed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () => onStatusChange('missed'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => onStatusChange('excused'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                  ),
                  child: const Text('Excuse'),
                ),
              ],
            ),
          ],
          if (assignment.checkInTime != null) ...[
            const SizedBox(height: 8),
            Text(
              'Checked in: ${DateFormat('hh:mm a').format(assignment.checkInTime!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final DetentionSchedule schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.dayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${schedule.startTime.substring(0, 5)} - ${schedule.endTime.substring(0, 5)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      schedule.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.people, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      'Cap: ${schedule.capacity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (schedule.supervisorName != null)
            Chip(
              avatar: const Icon(Icons.person, size: 14),
              label: Text(
                schedule.supervisorName!,
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
