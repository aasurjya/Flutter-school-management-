import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Segmented horizontal progress bar showing topic coverage distribution.
///
/// Each segment is proportionally sized by its count value and colour-coded:
///   green (completed), amber (in progress), grey (not started), blueGrey (skipped).
///
/// If the total is zero, a single grey placeholder bar is rendered.
class CoverageProgressBar extends StatelessWidget {
  final int completed;
  final int inProgress;
  final int notStarted;
  final int skipped;
  final double height;

  const CoverageProgressBar({
    super.key,
    required this.completed,
    required this.inProgress,
    required this.notStarted,
    required this.skipped,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final total = completed + inProgress + notStarted + skipped;

    if (total == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            if (completed > 0)
              Flexible(
                flex: completed,
                child: Container(color: AppColors.success),
              ),
            if (inProgress > 0)
              Flexible(
                flex: inProgress,
                child: Container(color: AppColors.warning),
              ),
            if (notStarted > 0)
              Flexible(
                flex: notStarted,
                child: Container(color: Colors.grey.withValues(alpha: 0.35)),
              ),
            if (skipped > 0)
              Flexible(
                flex: skipped,
                child: Container(color: Colors.blueGrey),
              ),
          ],
        ),
      ),
    );
  }
}
