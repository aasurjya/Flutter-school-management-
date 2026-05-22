import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/student_risk_score.dart';

/// "How is this calculated?" disclosure for a [StudentRiskScore].
///
/// The composite score is a deterministic SQL computation
/// (`compute_student_risk_score`). This widget exposes the four input factors
/// and their weights so parents/teachers can verify the score isn't a
/// black-box AI output.
///
///   • Attendance  — 30% weight
///   • Academics   — 35% weight
///   • Fees        — 15% weight
///   • Engagement  — 20% weight
///
/// Higher sub-score = more risk. Display:
///   tap the badge / tile to open this sheet via [showRiskExplanation].
class RiskScoreExplanation extends StatelessWidget {
  final StudentRiskScore score;

  const RiskScoreExplanation({super.key, required this.score});

  static const _factors = <_Factor>[
    _Factor(
      label: 'Attendance',
      weight: 0.30,
      description:
          'Lower attendance % over the last 60 days raises this score.',
      field: _Field.attendance,
    ),
    _Factor(
      label: 'Academics',
      weight: 0.35,
      description:
          'Recent exam marks below class average raise this score.',
      field: _Field.academic,
    ),
    _Factor(
      label: 'Fees',
      weight: 0.15,
      description:
          'Overdue invoices and partial payments raise this score.',
      field: _Field.fees,
    ),
    _Factor(
      label: 'Engagement',
      weight: 0.20,
      description:
          'Lower assignment submission rate and LMS activity raise this score.',
      field: _Field.engagement,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('How is this calculated?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 4),
            Text(
              'This score is a deterministic calculation from four signals — '
              'not a guess. The same inputs always produce the same score.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 20),
            ..._factors.map((f) => _FactorRow(factor: f, score: score)),
            const SizedBox(height: 20),
            _CompositeRow(score: score),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.grey500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Any narrative summary on this screen is AI-generated '
                      'and may need verification. The score itself is not.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showRiskExplanation(
  BuildContext context,
  StudentRiskScore score,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (_) => RiskScoreExplanation(score: score),
  );
}

enum _Field { attendance, academic, fees, engagement }

class _Factor {
  final String label;
  final double weight;
  final String description;
  final _Field field;

  const _Factor({
    required this.label,
    required this.weight,
    required this.description,
    required this.field,
  });
}

class _FactorRow extends StatelessWidget {
  final _Factor factor;
  final StudentRiskScore score;

  const _FactorRow({required this.factor, required this.score});

  double _value() {
    switch (factor.field) {
      case _Field.attendance:
        return score.attendanceScore;
      case _Field.academic:
        return score.academicScore;
      case _Field.fees:
        return score.feeScore;
      case _Field.engagement:
        return score.engagementScore;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = _value().clamp(0, 100).toDouble();
    final pct = (factor.weight * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(factor.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
              ),
              Text('$pct% weight',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey500,
                  )),
              const SizedBox(width: 12),
              Text(value.toStringAsFixed(0),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  )),
              Text(' / 100',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey400,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: AppColors.grey100,
              valueColor: AlwaysStoppedAnimation(_colorFor(value)),
            ),
          ),
          const SizedBox(height: 6),
          Text(factor.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              )),
        ],
      ),
    );
  }

  Color _colorFor(double v) {
    if (v >= 70) return AppColors.error;
    if (v >= 50) return AppColors.warning;
    if (v >= 30) return AppColors.info;
    return AppColors.success;
  }
}

class _CompositeRow extends StatelessWidget {
  final StudentRiskScore score;

  const _CompositeRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: score.riskColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: score.riskColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Composite risk score',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    )),
                const SizedBox(height: 4),
                Text(score.overallRiskScore.toStringAsFixed(0),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: score.riskColor,
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: score.riskColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(score.riskLevelLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}
