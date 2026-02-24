import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/student.dart';
import '../../../../data/models/student_checkin.dart';
import '../../../../data/models/attendance.dart';
import '../../../../data/repositories/attendance_repository.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../qr_scan/providers/qr_scan_provider.dart';
import 'parent_contact_sheet.dart';

/// Bottom sheet shown after scanning a student QR code.
class StudentQuickActionSheet extends ConsumerStatefulWidget {
  final Student student;
  final String mode; // 'lookup', 'attendance', 'checkin'
  final String? sectionId;

  const StudentQuickActionSheet({
    super.key,
    required this.student,
    this.mode = 'lookup',
    this.sectionId,
  });

  @override
  ConsumerState<StudentQuickActionSheet> createState() =>
      _StudentQuickActionSheetState();
}

class _StudentQuickActionSheetState
    extends ConsumerState<StudentQuickActionSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Student info header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: student.photoUrl != null
                      ? NetworkImage(student.photoUrl!)
                      : null,
                  child: student.photoUrl == null
                      ? Text(
                          student.initials,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student.currentClass} • ADM: ${student.admissionNumber}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildActions(context),
          ),
          const SizedBox(height: 16),

          // Secondary actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.person,
                    label: 'View Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/students/${student.id}');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.badge,
                    label: 'ID Card',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/student-id-card/${student.id}');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.phone,
                    label: 'Contact',
                    onTap: () => _showParentContact(context),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionButton(
          icon: Icons.check_circle,
          label: 'Mark Present',
          color: AppColors.success,
          onTap: () => _markAttendance(AttendanceStatus.present),
        ),
        _ActionButton(
          icon: Icons.cancel,
          label: 'Mark Absent',
          color: AppColors.error,
          onTap: () => _markAttendance(AttendanceStatus.absent),
        ),
        _ActionButton(
          icon: Icons.login,
          label: 'Check In',
          color: AppColors.info,
          onTap: () => _recordCheckin(CheckType.checkIn),
        ),
        _ActionButton(
          icon: Icons.logout,
          label: 'Check Out',
          color: AppColors.accent,
          onTap: () => _recordCheckin(CheckType.checkOut),
        ),
      ],
    );
  }

  Future<void> _markAttendance(AttendanceStatus status) async {
    final sectionId =
        widget.sectionId ?? widget.student.currentEnrollment?.sectionId;
    if (sectionId == null) {
      _showError('Student has no current enrollment');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = AttendanceRepository(ref.read(supabaseProvider));
      await repo.markAttendance(
        studentId: widget.student.id,
        sectionId: sectionId,
        date: DateTime.now(),
        status: status.dbValue,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${widget.student.fullName} marked ${status.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to mark attendance: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recordCheckin(CheckType type) async {
    final sectionId =
        widget.sectionId ?? widget.student.currentEnrollment?.sectionId;
    if (sectionId == null) {
      _showError('Student has no current enrollment');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(checkinRepositoryProvider);
      await repo.recordCheckin(
        studentId: widget.student.id,
        sectionId: sectionId,
        checkType: type,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.student.fullName} ${type.displayName} recorded'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to record ${type.displayName}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showParentContact(BuildContext context) {
    if (widget.student.parents == null || widget.student.parents!.isEmpty) {
      _showError('No parent contact information available');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ParentContactSheet(parents: widget.student.parents!),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
