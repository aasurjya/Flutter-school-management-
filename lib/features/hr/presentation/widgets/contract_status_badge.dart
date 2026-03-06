import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/hr_payroll.dart';

/// Badge showing contract status with appropriate color
class ContractStatusBadge extends StatelessWidget {
  final ContractStatus status;
  final bool showIcon;

  const ContractStatusBadge({
    super.key,
    required this.status,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final label = _statusLabel;
    final icon = _statusIcon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case ContractStatus.active:
        return AppColors.success;
      case ContractStatus.expired:
        return AppColors.warning;
      case ContractStatus.terminated:
        return AppColors.error;
    }
  }

  String get _statusLabel {
    switch (status) {
      case ContractStatus.active:
        return 'Active';
      case ContractStatus.expired:
        return 'Expired';
      case ContractStatus.terminated:
        return 'Terminated';
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case ContractStatus.active:
        return Icons.check_circle;
      case ContractStatus.expired:
        return Icons.schedule;
      case ContractStatus.terminated:
        return Icons.cancel;
    }
  }
}

/// Badge showing contract type
class ContractTypeBadge extends StatelessWidget {
  final ContractType type;

  const ContractTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;
    final label = _typeLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _typeColor {
    switch (type) {
      case ContractType.permanent:
        return AppColors.primary;
      case ContractType.temporary:
        return AppColors.warning;
      case ContractType.contract:
        return AppColors.info;
      case ContractType.probation:
        return const Color(0xFF8B5CF6);
    }
  }

  String get _typeLabel {
    switch (type) {
      case ContractType.permanent:
        return 'Permanent';
      case ContractType.temporary:
        return 'Temporary';
      case ContractType.contract:
        return 'Contract';
      case ContractType.probation:
        return 'Probation';
    }
  }
}
