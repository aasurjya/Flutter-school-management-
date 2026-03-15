import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum StatusType { success, error, warning, info, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;

  const StatusChip({super.key, required this.label, this.type = StatusType.neutral});

  factory StatusChip.fromString(String status) {
    final lower = status.toLowerCase();
    StatusType type;
    if (['active', 'present', 'approved', 'published', 'paid', 'completed', 'available'].contains(lower)) {
      type = StatusType.success;
    } else if (['inactive', 'absent', 'rejected', 'failed', 'overdue', 'cancelled'].contains(lower)) {
      type = StatusType.error;
    } else if (['pending', 'late', 'partial', 'draft', 'excused'].contains(lower)) {
      type = StatusType.warning;
    } else if (['info', 'processing', 'submitted', 'review'].contains(lower)) {
      type = StatusType.info;
    } else {
      type = StatusType.neutral;
    }
    return StatusChip(label: status, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      StatusType.success => (AppColors.successLight, AppColors.success),
      StatusType.error   => (AppColors.errorLight,   AppColors.error),
      StatusType.warning => (AppColors.warningLight, AppColors.warning),
      StatusType.info    => (AppColors.infoLight,    AppColors.info),
      StatusType.neutral => (AppColors.grey100,      AppColors.grey600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
