import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/student_insights.dart';
import '../../providers/insights_provider.dart';
import 'dart:math' as math;

class SubjectRadarChart extends ConsumerWidget {
  final String studentId;
  final StudentInsights insights;

  const SubjectRadarChart({
    super.key,
    required this.studentId,
    required this.insights,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Use subject insights from the already loaded data
    final subjects = insights.subjectInsights;

    if (subjects.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              const Text('No subject data available'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radar, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Subject Comparison',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your performance vs class average',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: CustomPaint(
                size: const Size(double.infinity, 250),
                painter: _RadarChartPainter(
                  subjects: subjects,
                  primaryColor: theme.colorScheme.primary,
                  secondaryColor: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: theme.colorScheme.primary,
                  label: 'Your Score',
                ),
                const SizedBox(width: 24),
                _LegendItem(
                  color: Colors.orange,
                  label: 'Class Average',
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<SubjectInsight> subjects;
  final Color primaryColor;
  final Color secondaryColor;

  _RadarChartPainter({
    required this.subjects,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    final count = subjects.length;

    if (count < 3) return;

    final angleStep = (2 * math.pi) / count;

    // Draw background circles
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 1; i <= 5; i++) {
      final r = radius * i / 5;
      canvas.drawCircle(center, r, gridPaint);
    }

    // Draw axis lines and labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(center, end, gridPaint);

      // Draw subject label
      final labelOffset = Offset(
        center.dx + (radius + 20) * math.cos(angle),
        center.dy + (radius + 20) * math.sin(angle),
      );

      textPainter.text = TextSpan(
        text: _shortenSubjectName(subjects[i].subjectName),
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelOffset.dx - textPainter.width / 2,
          labelOffset.dy - textPainter.height / 2,
        ),
      );
    }

    // Draw student score polygon
    _drawPolygon(
      canvas,
      center,
      radius,
      subjects.map((s) => s.percentage / 100).toList(),
      primaryColor,
    );

    // Draw class average polygon
    _drawPolygon(
      canvas,
      center,
      radius,
      subjects.map((s) => s.classAverage / 100).toList(),
      secondaryColor,
    );

    // Draw data points for student
    for (var i = 0; i < count; i++) {
      final value = subjects[i].percentage / 100;
      final angle = -math.pi / 2 + i * angleStep;
      final point = Offset(
        center.dx + radius * value * math.cos(angle),
        center.dy + radius * value * math.sin(angle),
      );

      final pointPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  void _drawPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    List<double> values,
    Color color,
  ) {
    final count = values.length;
    final angleStep = (2 * math.pi) / count;

    final path = Path();
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < count; i++) {
      final value = values[i].clamp(0.0, 1.0);
      final angle = -math.pi / 2 + i * angleStep;
      final point = Offset(
        center.dx + radius * value * math.cos(angle),
        center.dy + radius * value * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  String _shortenSubjectName(String name) {
    if (name.length <= 8) return name;

    // Common abbreviations
    final abbreviations = {
      'Mathematics': 'Math',
      'Science': 'Sci',
      'English': 'Eng',
      'Hindi': 'Hin',
      'Social Studies': 'SST',
      'Computer': 'Comp',
      'Physical Education': 'PE',
      'Environmental Studies': 'EVS',
    };

    return abbreviations[name] ?? name.substring(0, 6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
