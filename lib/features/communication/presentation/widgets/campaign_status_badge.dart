import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/communication.dart';

class CampaignStatusBadge extends StatelessWidget {
  final CampaignStatus status;
  final bool showIcon;
  final double fontSize;

  const CampaignStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
  });

  Color get _color {
    switch (status) {
      case CampaignStatus.draft:
        return AppColors.textSecondaryLight;
      case CampaignStatus.scheduled:
        return AppColors.info;
      case CampaignStatus.sending:
        return AppColors.warning;
      case CampaignStatus.sent:
        return AppColors.success;
      case CampaignStatus.failed:
        return AppColors.error;
      case CampaignStatus.cancelled:
        return AppColors.textTertiaryLight;
    }
  }

  IconData get _icon {
    switch (status) {
      case CampaignStatus.draft:
        return Icons.edit_outlined;
      case CampaignStatus.scheduled:
        return Icons.schedule_outlined;
      case CampaignStatus.sending:
        return Icons.send_outlined;
      case CampaignStatus.sent:
        return Icons.check_circle_outlined;
      case CampaignStatus.failed:
        return Icons.error_outlined;
      case CampaignStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            if (status == CampaignStatus.sending)
              SizedBox(
                width: fontSize,
                height: fontSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _color,
                ),
              )
            else
              Icon(_icon, size: fontSize, color: _color),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class RecipientStatusBadge extends StatelessWidget {
  final RecipientStatus status;

  const RecipientStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case RecipientStatus.pending:
        return AppColors.textSecondaryLight;
      case RecipientStatus.sent:
        return AppColors.info;
      case RecipientStatus.delivered:
        return AppColors.success;
      case RecipientStatus.read:
        return AppColors.primary;
      case RecipientStatus.failed:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
