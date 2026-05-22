import 'package:flutter/material.dart';

import '../../../../data/models/student_risk_score.dart';
import 'risk_score_explanation.dart';

class RiskScoreBadge extends StatelessWidget {
  final StudentRiskScore riskScore;
  final bool showLabel;
  final double? fontSize;

  /// When true (default), tapping the badge opens the "How is this
  /// calculated?" disclosure sheet — making the deterministic SQL breakdown
  /// visible so users know this score isn't a black-box AI guess.
  final bool tappable;

  const RiskScoreBadge({
    super.key,
    required this.riskScore,
    this.showLabel = true,
    this.fontSize,
    this.tappable = true,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: riskScore.riskColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: riskScore.riskColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: riskScore.riskColor,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              riskScore.riskLevelLabel,
              style: TextStyle(
                color: riskScore.riskColor,
                fontWeight: FontWeight.w600,
                fontSize: fontSize ?? 12,
              ),
            ),
            if (tappable) ...[
              const SizedBox(width: 4),
              Icon(Icons.info_outline,
                  size: (fontSize ?? 12) + 2,
                  color: riskScore.riskColor),
            ],
          ],
        ],
      ),
    );
    if (!tappable) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showRiskExplanation(context, riskScore),
      child: pill,
    );
  }
}

class RiskScoreBadgeFromLevel extends StatelessWidget {
  final String riskLevel;

  const RiskScoreBadgeFromLevel({super.key, required this.riskLevel});

  Color get _color {
    switch (riskLevel) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF22C55E);
    }
  }

  String get _label {
    switch (riskLevel) {
      case 'critical':
        return 'Critical';
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
