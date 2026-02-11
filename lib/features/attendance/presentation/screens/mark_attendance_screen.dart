import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../data/models/attendance.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../students/providers/students_provider.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final String? date;

  const MarkAttendanceScreen({
    super.key,
    required this.sectionId,
    this.date,
  });

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  late List<StudentAttendanceRecord> _students;
  bool _isSubmitting = false;
  bool _hasChanges = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    _fetchStudentsAndExistingAttendance();
  }

  Future<void> _fetchStudentsAndExistingAttendance() async {
    setState(() {
      _isLoading = true;
      _students = [];
      _hasChanges = false;
    });

    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      final attendanceRepo = ref.read(attendanceRepositoryProvider);

      final date = widget.date != null
          ? DateTime.parse(widget.date!)
          : DateTime.now();

      // Load active students for this section from Supabase
      final students = await studentRepo.getStudentsBySection(widget.sectionId);

      // Load any existing attendance records for this date/section
      final existing = await attendanceRepo.getAttendanceBySection(
        sectionId: widget.sectionId,
        date: date,
      );

      final existingByStudentId = {
        for (final a in existing) a.studentId: a,
      };

      _students = students.map((s) {
        final Attendance? a = existingByStudentId[s.id];
        return StudentAttendanceRecord(
          studentId: s.id,
          studentName: s.fullName,
          rollNumber: a?.studentRollNumber ?? s.rollNumber,
          photoUrl: s.photoUrl,
          status: a?.status ?? AttendanceStatus.present,
          remarks: a?.remarks,
        );
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to load students: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mark Attendance')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final presentCount = _students.where((s) => s.status == AttendanceStatus.present).length;
    final absentCount = _students.where((s) => s.status == AttendanceStatus.absent).length;
    final lateCount = _students.where((s) => s.status == AttendanceStatus.late).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        actions: [
          TextButton(
            onPressed: _markAllPresent,
            child: const Text('All Present'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black12
                : Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryChip(
                  label: 'Present',
                  count: presentCount,
                  color: AppColors.success,
                ),
                _SummaryChip(
                  label: 'Absent',
                  count: absentCount,
                  color: AppColors.error,
                ),
                _SummaryChip(
                  label: 'Late',
                  count: lateCount,
                  color: AppColors.warning,
                ),
                _SummaryChip(
                  label: 'Total',
                  count: _students.length,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markAllPresent,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('All Present'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markAllAbsent,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('All Absent'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return _StudentAttendanceCard(
                  student: student,
                  onStatusChanged: (status) {
                    setState(() {
                      student.status = status;
                      _hasChanges = true;
                    });
                  },
                  onRemarksChanged: (remarks) {
                    student.remarks = remarks;
                    _hasChanges = true;
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _hasChanges && !_isSubmitting ? _submitAttendance : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Submit Attendance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _markAllPresent() {
    setState(() {
      for (final student in _students) {
        student.status = AttendanceStatus.present;
      }
      _hasChanges = true;
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (final student in _students) {
        student.status = AttendanceStatus.absent;
      }
      _hasChanges = true;
    });
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSubmitting = true);

    try {
      final attendanceRepo = ref.read(attendanceRepositoryProvider);

      await attendanceRepo.markBulkAttendance(
        sectionId: widget.sectionId,
        date: widget.date != null
            ? DateTime.parse(widget.date!)
            : DateTime.now(),
        attendanceRecords: _students
            .map((s) => {
                  'student_id': s.studentId,
                  'status': s.status.dbValue,
                  'remarks': s.remarks,
                })
            .toList(),
      );

      if (mounted) {
        context.showSuccessSnackBar('Attendance submitted successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to submit: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _StudentAttendanceCard extends StatelessWidget {
  final StudentAttendanceRecord student;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final ValueChanged<String> onRemarksChanged;

  const _StudentAttendanceCard({
    required this.student,
    required this.onStatusChanged,
    required this.onRemarksChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(student.status).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Student Info
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    student.studentName.substring(0, 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Roll No: ${student.rollNumber}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // More Options
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status Buttons
            Row(
              children: [
                _StatusButton(
                  label: 'Present',
                  icon: Icons.check,
                  color: AppColors.success,
                  isSelected: student.status == AttendanceStatus.present,
                  onTap: () => onStatusChanged(AttendanceStatus.present),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  label: 'Absent',
                  icon: Icons.close,
                  color: AppColors.error,
                  isSelected: student.status == AttendanceStatus.absent,
                  onTap: () => onStatusChanged(AttendanceStatus.absent),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  label: 'Late',
                  icon: Icons.access_time,
                  color: AppColors.warning,
                  isSelected: student.status == AttendanceStatus.late,
                  onTap: () => onStatusChanged(AttendanceStatus.late),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late:
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.studentName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Remarks (optional)',
                  hintText: 'Add any notes...',
                ),
                maxLines: 2,
                onChanged: onRemarksChanged,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.event_busy, color: AppColors.info),
                title: const Text('Mark as Excused'),
                onTap: () {
                  onStatusChanged(AttendanceStatus.excused);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timelapse, color: AppColors.accent),
                title: const Text('Mark as Half Day'),
                onTap: () {
                  onStatusChanged(AttendanceStatus.halfDay);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color,
              width: isSelected ? 0 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Mock list removed – data now loaded from Supabase
