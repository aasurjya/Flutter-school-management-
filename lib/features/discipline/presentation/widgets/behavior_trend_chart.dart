import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/discipline.dart';

class BehaviorTrendChart extends StatelessWidget {
  final List<DailyIncidentCount> dailyTrend;
  final double height;

  const BehaviorTrendChart({
    super.key,
    required this.dailyTrend,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyTrend.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No data available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final spots = dailyTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
    }).toList();

    final maxY = dailyTrend
        .map((e) => e.count)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: dailyTrend.length > 14
                    ? (dailyTrend.length / 7).ceilToDouble()
                    : dailyTrend.length > 7
                        ? 2
                        : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= dailyTrend.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('d/M').format(dailyTrend[idx].date),
                      style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (dailyTrend.length - 1).toDouble(),
          minY: 0,
          maxY: maxY > 0 ? maxY + 1 : 5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.error,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: dailyTrend.length <= 14,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.error,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.error.withValues(alpha: 0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final idx = spot.spotIndex;
                  final date = dailyTrend[idx].date;
                  return LineTooltipItem(
                    '${DateFormat('dd MMM').format(date)}\n${spot.y.toInt()} incidents',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
