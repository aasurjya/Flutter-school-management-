import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/discipline.dart';

class BehaviorScoreWidget extends StatelessWidget {
  final BehaviorScore score;
  final double size;

  const BehaviorScoreWidget({
    super.key,
    required this.score,
    this.size = 140,
  });

  Color get _scoreColor {
    if (score.netScore >= 50) return AppColors.success;
    if (score.netScore >= 20) return const Color(0xFF22D3EE);
    if (score.netScore >= 0) return AppColors.warning;
    if (score.netScore >= -20) return const Color(0xFFF97316);
    return AppColors.error;
  }

  String get _label {
    if (score.netScore >= 50) return 'Excellent';
    if (score.netScore >= 20) return 'Good';
    if (score.netScore >= 0) return 'Fair';
    if (score.netScore >= -20) return 'Needs Work';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    // Normalize score to 0..1 range for the arc (clamp between -100 and 100)
    final normalizedValue =
        ((score.netScore + 100) / 200).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ScoreArcPainter(
              value: normalizedValue,
              color: _scoreColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.netScore}',
                    style: TextStyle(
                      fontSize: size * 0.25,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor,
                    ),
                  ),
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: size * 0.1,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ScoreDetail(
              icon: Icons.thumb_up_outlined,
              color: AppColors.success,
              label: 'Positive',
              value: '+${score.positivePoints}',
            ),
            const SizedBox(width: 24),
            _ScoreDetail(
              icon: Icons.thumb_down_outlined,
              color: AppColors.error,
              label: 'Negative',
              value: '-${score.negativePoints}',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ScoreDetail(
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              label: 'Incidents',
              value: '${score.incidentCount}',
            ),
            const SizedBox(width: 24),
            _ScoreDetail(
              icon: Icons.star_outline,
              color: AppColors.accent,
              label: 'Recognitions',
              value: '${score.recognitionCount}',
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreDetail extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _ScoreDetail({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$value ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ScoreArcPainter extends CustomPainter {
  final double value; // 0.0 .. 1.0
  final Color color;

  _ScoreArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = math.pi * 0.75; // 135 degrees
    const sweepTotal = math.pi * 1.5; // 270 degrees

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * value,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreArcPainter oldDelegate) =>
      value != oldDelegate.value || color != oldDelegate.color;
}
