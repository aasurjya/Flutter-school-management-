import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/hr_payroll.dart';
import '../../providers/hr_provider.dart';

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  ConsumerState<StaffAttendanceScreen> createState() =>
      _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState
    extends ConsumerState<StaffAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, StaffAttendanceStatus> _attendanceMap = {};
  bool _isSubmitting = false;
  bool _modified = false;

  @override
  Widget build(BuildContext context) {
    final attendanceAsync =
        ref.watch(staffAttendanceProvider(_selectedDate));
    final contractsAsync = ref.watch(
      staffContractsProvider(const StaffContractFilter(status: 'active')),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Attendance'),
        actions: [
          TextButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(DateFormat('dd MMM').format(_selectedDate)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryChip(
                  label: 'Present',
                  count: _countByStatus(StaffAttendanceStatus.present),
                  color: AppColors.success,
                ),
                _SummaryChip(
                  label: 'Absent',
                  count: _countByStatus(StaffAttendanceStatus.absent),
                  color: AppColors.error,
                ),
                _SummaryChip(
                  label: 'Half Day',
                  count: _countByStatus(StaffAttendanceStatus.halfDay),
                  color: AppColors.warning,
                ),
                _SummaryChip(
                  label: 'On Leave',
                  count: _countByStatus(StaffAttendanceStatus.onLeave),
                  color: AppColors.info,
                ),
              ],
            ),
          ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _markAll(StaffAttendanceStatus.present),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('All Present'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Staff list
          Expanded(
            child: contractsAsync.when(
              data: (contracts) {
                // Pre-populate from existing attendance
                attendanceAsync.whenData((existing) {
                  if (!_modified) {
                    for (final att in existing) {
                      _attendanceMap[att.staffId] = att.status;
                    }
                  }
                });

                if (contracts.isEmpty) {
                  return const Center(child: Text('No active staff found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: contracts.length,
                  itemBuilder: (context, index) {
                    final contract = contracts[index];
                    final currentStatus = _attendanceMap[contract.staffId];

                    return _StaffAttendanceRow(
                      name: contract.staffName ?? 'Unknown',
                      employeeId: contract.staffEmployeeId,
                      currentStatus: currentStatus,
                      onStatusChanged: (status) {
                        setState(() {
                          _attendanceMap[contract.staffId] = status;
                          _modified = true;
                        });
                      },
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _attendanceMap.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitAttendance,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Submit Attendance (${_attendanceMap.length} staff)'),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  int _countByStatus(StaffAttendanceStatus status) {
    return _attendanceMap.values.where((s) => s == status).length;
  }

  void _markAll(StaffAttendanceStatus status) {
    final contractsAsync = ref.read(
      staffContractsProvider(const StaffContractFilter(status: 'active')),
    );

    contractsAsync.whenData((contracts) {
      setState(() {
        for (final c in contracts) {
          _attendanceMap[c.staffId] = status;
        }
        _modified = true;
      });
    });
  }

  void _clearAll() {
    setState(() {
      _attendanceMap.clear();
      _modified = true;
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _attendanceMap.clear();
        _modified = false;
      });
      ref.invalidate(staffAttendanceProvider(_selectedDate));
    }
  }

  Future<void> _submitAttendance() async {
    if (_attendanceMap.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final records = _attendanceMap.entries.map((entry) {
        return {
          'staff_id': entry.key,
          'date': _selectedDate.toIso8601String().split('T')[0],
          'status': entry.value.name,
        };
      }).toList();

      await ref
          .read(hrNotifierProvider.notifier)
          .upsertStaffAttendance(records);

      ref.invalidate(staffAttendanceProvider(_selectedDate));
      ref.invalidate(hrStatsProvider);

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Attendance submitted for ${records.length} staff'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _StaffAttendanceRow extends StatelessWidget {
  final String name;
  final String? employeeId;
  final StaffAttendanceStatus? currentStatus;
  final ValueChanged<StaffAttendanceStatus> onStatusChanged;

  const _StaffAttendanceRow({
    required this.name,
    this.employeeId,
    this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = name.trim().split(' ').length >= 2
        ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'
            .toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withAlpha(20),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (employeeId != null)
                        Text(
                          employeeId!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusButton(
                  label: 'Present',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                  selected: currentStatus == StaffAttendanceStatus.present,
                  onTap: () =>
                      onStatusChanged(StaffAttendanceStatus.present),
                ),
                const SizedBox(width: 6),
                _StatusButton(
                  label: 'Absent',
                  icon: Icons.cancel,
                  color: AppColors.error,
                  selected: currentStatus == StaffAttendanceStatus.absent,
                  onTap: () =>
                      onStatusChanged(StaffAttendanceStatus.absent),
                ),
                const SizedBox(width: 6),
                _StatusButton(
                  label: 'Half',
                  icon: Icons.timelapse,
                  color: AppColors.warning,
                  selected:
                      currentStatus == StaffAttendanceStatus.halfDay,
                  onTap: () =>
                      onStatusChanged(StaffAttendanceStatus.halfDay),
                ),
                const SizedBox(width: 6),
                _StatusButton(
                  label: 'Leave',
                  icon: Icons.event_busy,
                  color: AppColors.info,
                  selected:
                      currentStatus == StaffAttendanceStatus.onLeave,
                  onTap: () =>
                      onStatusChanged(StaffAttendanceStatus.onLeave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(40) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : AppColors.borderLight,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: selected ? color : AppColors.textTertiaryLight),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? color : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
