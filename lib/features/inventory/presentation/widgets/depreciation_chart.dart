import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DepreciationChart extends StatelessWidget {
  final List<Map<String, dynamic>> depreciationData;
  final double? purchasePrice;

  const DepreciationChart({
    super.key,
    required this.depreciationData,
    this.purchasePrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (depreciationData.isEmpty) {
      return Center(
        child: Text(
          'No depreciation data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    final maxValue = depreciationData
        .map((d) => (d['value'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    final spots = depreciationData.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['value'] as num).toDouble(),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asset Depreciation',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxValue / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.borderLight,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatCompact(value),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiaryLight,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= depreciationData.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        '${depreciationData[index]['year']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiaryLight,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isCurrentYear = index < depreciationData.length &&
                          depreciationData[index]['year'] ==
                              DateTime.now().year;
                      return FlDotCirclePainter(
                        radius: isCurrentYear ? 5 : 3,
                        color: isCurrentYear
                            ? AppColors.warning
                            : AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final year = index < depreciationData.length
                          ? depreciationData[index]['year']
                          : '';
                      return LineTooltipItem(
                        '$year\n\u20B9${_formatCompact(spot.y)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(
              color: AppColors.primary,
              label: 'Book Value',
            ),
            const SizedBox(width: 16),
            _LegendItem(
              color: AppColors.warning,
              label: 'Current Year',
            ),
          ],
        ),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
      ],
    );
  }
}
