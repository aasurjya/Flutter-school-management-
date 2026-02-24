import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ai_text_generator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/trend_prediction_provider.dart';
import '../widgets/prediction_confidence_badge.dart';
import '../widgets/trend_line_chart.dart';

class TrendDashboardScreen extends ConsumerStatefulWidget {
  final String? sectionId;
  final String? studentId;

  const TrendDashboardScreen({
    super.key,
    this.sectionId,
    this.studentId,
  });

  @override
  ConsumerState<TrendDashboardScreen> createState() =>
      _TrendDashboardScreenState();
}

class _TrendDashboardScreenState extends ConsumerState<TrendDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Trend Predictions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.forestGradient,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Student exam performance trend
                if (widget.studentId != null) ...[
                  _buildStudentExamTrend(widget.studentId!),
                  const SizedBox(height: 24),
                ],

                // Section attendance trend
                if (widget.sectionId != null) ...[
                  _buildSectionAttendanceTrend(widget.sectionId!),
                  const SizedBox(height: 24),
                ],

                // Method note
                Text(
                  'Predictions use linear regression. Dashed lines show projections.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentExamTrend(String studentId) {
    final predictionAsync =
        ref.watch(studentExamPredictionProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Exam Performance Trend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        predictionAsync.when(
          loading: () => const GlassCard(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const GlassCard(
            padding: EdgeInsets.all(20),
            child: Text('Failed to load trend data'),
          ),
          data: (prediction) {
            return Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TrendDirectionChip(
                              direction: prediction.trendDirection),
                          const Spacer(),
                          if (prediction.hasEnoughData)
                            PredictionConfidenceBadge(
                                rSquared: prediction.rSquared),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TrendLineChart(prediction: prediction),
                      const SizedBox(height: 8),
                      _buildLegend(),
                    ],
                  ),
                ),
                // AI narrative
                Consumer(
                  builder: (context, ref, _) {
                    final narrativeAsync = ref
                        .watch(studentExamNarrativeProvider(studentId));
                    return narrativeAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (result) => _buildNarrativeCard(result),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionAttendanceTrend(String sectionId) {
    final predictionAsync =
        ref.watch(sectionAttendancePredictionProvider(sectionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 20, color: AppColors.secondary),
            const SizedBox(width: 8),
            const Text(
              'Attendance Trend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        predictionAsync.when(
          loading: () => const GlassCard(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const GlassCard(
            padding: EdgeInsets.all(20),
            child: Text('Failed to load trend data'),
          ),
          data: (prediction) {
            return Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TrendDirectionChip(
                              direction: prediction.trendDirection),
                          const Spacer(),
                          if (prediction.hasEnoughData)
                            PredictionConfidenceBadge(
                                rSquared: prediction.rSquared),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TrendLineChart(prediction: prediction),
                      const SizedBox(height: 8),
                      _buildLegend(),
                    ],
                  ),
                ),
                // AI narrative
                Consumer(
                  builder: (context, ref, _) {
                    final narrativeAsync = ref
                        .watch(sectionAttendanceNarrativeProvider(sectionId));
                    return narrativeAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (result) => _buildNarrativeCard(result),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNarrativeCard(AITextResult result) {
    if (result.text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              result.isLLMGenerated ? Icons.auto_awesome : Icons.info_outline,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: AppColors.primary, label: 'Historical'),
        const SizedBox(width: 20),
        _LegendItem(
          color: AppColors.accent,
          label: 'Predicted',
          isDashed: true,
        ),
      ],
    );
  }
}

class _TrendDirectionChip extends StatelessWidget {
  final String direction;

  const _TrendDirectionChip({required this.direction});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (direction) {
      case 'improving':
        icon = Icons.trending_up;
        color = AppColors.success;
        label = 'Improving';
        break;
      case 'declining':
        icon = Icons.trending_down;
        color = AppColors.error;
        label = 'Declining';
        break;
      default:
        icon = Icons.trending_flat;
        color = AppColors.textSecondaryLight;
        label = 'Stable';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            border: isDashed
                ? Border(
                    bottom: BorderSide(
                      color: color,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
