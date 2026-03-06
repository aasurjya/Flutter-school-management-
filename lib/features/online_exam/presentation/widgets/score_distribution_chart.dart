import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ScoreDistributionChart extends StatelessWidget {
  final List<Map<String, dynamic>> distribution;

  const ScoreDistributionChart({
    super.key,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = distribution.fold<int>(
        0, (max, b) => (b['count'] as int) > max ? b['count'] as int : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score Distribution',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: distribution.asMap().entries.map((entry) {
              final bucket = entry.value;
              final count = bucket['count'] as int;
              final range = bucket['range'] as String;
              final heightRatio =
                  maxCount > 0 ? count / maxCount : 0.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (count > 0)
                        Text(
                          count.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: heightRatio.clamp(0.05, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  _barColor(entry.key),
                                  _barColor(entry.key).withAlpha(180),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        range.replaceAll('-', '\n-\n'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Score Range (%)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Color _barColor(int index) {
    if (index < 3) return AppColors.error;
    if (index < 5) return AppColors.warning;
    if (index < 7) return AppColors.info;
    return AppColors.success;
  }
}
