import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/trend_prediction.dart';

class TrendLineChart extends StatelessWidget {
  final TrendPrediction prediction;
  final String yAxisLabel;

  const TrendLineChart({
    super.key,
    required this.prediction,
    this.yAxisLabel = '%',
  });

  @override
  Widget build(BuildContext context) {
    if (!prediction.hasEnoughData) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Not enough data for trend analysis',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final historicalSpots = prediction.historicalData
        .map((d) => FlSpot(d.x, d.y))
        .toList();

    final predictedSpots = <FlSpot>[];
    if (prediction.predictedData.isNotEmpty && historicalSpots.isNotEmpty) {
      // Bridge: last historical point + predicted points
      predictedSpots.add(historicalSpots.last);
      predictedSpots.addAll(
        prediction.predictedData.map((d) => FlSpot(d.x, d.y)),
      );
    }

    final allPoints = [
      ...prediction.historicalData,
      ...prediction.predictedData,
    ];
    final maxX = allPoints.isEmpty
        ? 10.0
        : allPoints.map((d) => d.x).reduce((a, b) => a > b ? a : b);
    final minX = allPoints.isEmpty
        ? 0.0
        : allPoints.map((d) => d.x).reduce((a, b) => a < b ? a : b);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          minX: minX,
          maxX: maxX,
          clipData: const FlClipData.all(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isPredicted = spot.barIndex == 1;
                  final label = _getLabelForX(spot.x);
                  return LineTooltipItem(
                    '${isPredicted ? "(Predicted) " : ""}$label\n${spot.y.toStringAsFixed(1)}$yAxisLabel',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final label = _getLabelForX(value);
                  if (label.isEmpty) return const SizedBox.shrink();
                  final isPredicted = prediction.predictedData
                      .any((d) => d.x == value);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: isPredicted ? AppColors.accent : Colors.grey[500],
                        fontStyle: isPredicted
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value % 25 != 0) return const SizedBox.shrink();
                  return Text(
                    '${value.toInt()}$yAxisLabel',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Historical (solid line)
            LineChartBarData(
              spots: historicalSpots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            // Predicted (dashed line)
            if (predictedSpots.isNotEmpty)
              LineChartBarData(
                spots: predictedSpots,
                isCurved: true,
                curveSmoothness: 0.2,
                color: AppColors.accent,
                barWidth: 2.5,
                dashArray: [8, 4],
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.accent,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.accent.withValues(alpha: 0.08),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getLabelForX(double x) {
    // Check historical data first
    for (final d in prediction.historicalData) {
      if (d.x == x && d.label != null) return d.label!;
    }
    // Then predicted
    for (final d in prediction.predictedData) {
      if (d.x == x && d.label != null) return d.label!;
    }
    return '';
  }
}
