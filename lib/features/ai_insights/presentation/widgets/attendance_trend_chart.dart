import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/attendance_insights.dart';

class AttendanceTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyHistory;
  final List<AttendanceAnomaly> anomalies;

  const AttendanceTrendChart({
    super.key,
    required this.dailyHistory,
    this.anomalies = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (dailyHistory.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No attendance history available')),
      );
    }

    final spots = dailyHistory.asMap().entries.map((entry) {
      final pct =
          (entry.value['attendance_percentage'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), pct);
    }).toList();

    // Map anomaly dates to indexes
    final anomalyIndexes = <int>{};
    for (final anomaly in anomalies) {
      for (var i = 0; i < dailyHistory.length; i++) {
        final date = DateTime.tryParse(dailyHistory[i]['date'] ?? '');
        if (date != null &&
            date.year == anomaly.date.year &&
            date.month == anomaly.date.month &&
            date.day == anomaly.date.day) {
          anomalyIndexes.add(i);
        }
      }
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          clipData: const FlClipData.all(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final dateStr = idx < dailyHistory.length
                      ? dailyHistory[idx]['date'] ?? ''
                      : '';
                  return LineTooltipItem(
                    '$dateStr\n${spot.y.toStringAsFixed(1)}%',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
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
                interval: (dailyHistory.length / 5).ceilToDouble().clamp(1, 30),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= dailyHistory.length) {
                    return const SizedBox.shrink();
                  }
                  final date =
                      DateTime.tryParse(dailyHistory[idx]['date'] ?? '');
                  if (date == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: TextStyle(fontSize: 9, color: Colors.grey[500]),
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
                    '${value.toInt()}%',
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
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (anomalyIndexes.contains(index)) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: AppColors.error,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
