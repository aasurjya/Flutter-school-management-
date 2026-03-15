import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class PredictionConfidenceBadge extends StatelessWidget {
  final double rSquared;

  const PredictionConfidenceBadge({
    super.key,
    required this.rSquared,
  });

  String get _label {
    if (rSquared >= 0.7) return 'High Confidence';
    if (rSquared >= 0.4) return 'Medium Confidence';
    return 'Low Confidence';
  }

  Color get _color {
    if (rSquared >= 0.7) return AppColors.success;
    if (rSquared >= 0.4) return AppColors.warning;
    return AppColors.textSecondaryLight;
  }

  IconData get _icon {
    if (rSquared >= 0.7) return Icons.verified;
    if (rSquared >= 0.4) return Icons.info_outline;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            '$_label (R²=${(rSquared * 100).toStringAsFixed(0)}%)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
