import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/risk_score_provider.dart';
import '../widgets/risk_factor_bar.dart';
import '../widgets/risk_score_badge.dart';

class StudentRiskDetailScreen extends ConsumerWidget {
  final String studentId;
  final String academicYearId;

  const StudentRiskDetailScreen({
    super.key,
    required this.studentId,
    required this.academicYearId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskAsync = ref.watch(enrichedStudentRiskProvider(
      StudentRiskFilter(
        studentId: studentId,
        academicYearId: academicYearId,
      ),
    ));

    return Scaffold(
      body: riskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (risk) {
          if (risk == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No risk data available for this student',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          risk.riskColor,
                          risk.riskColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              risk.studentName ?? 'Student',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Risk Score: ${risk.overallRiskScore.round()}/100',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Risk level + trend
                    Row(
                      children: [
                        RiskScoreBadge(riskScore: risk, fontSize: 14),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              risk.trendIcon,
                              color: risk.trendColor,
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              risk.scoreTrend.toUpperCase(),
                              style: TextStyle(
                                color: risk.trendColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            if (risk.previousScore != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(was ${risk.previousScore!.round()})',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Factor breakdown
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.analytics_outlined,
                                  size: 20, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'Risk Factor Breakdown',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          RiskFactorBar(
                            label: 'Attendance (30%)',
                            score: risk.attendanceScore,
                          ),
                          RiskFactorBar(
                            label: 'Academic (35%)',
                            score: risk.academicScore,
                          ),
                          RiskFactorBar(
                            label: 'Fee Status (15%)',
                            score: risk.feeScore,
                          ),
                          RiskFactorBar(
                            label: 'Engagement (20%)',
                            score: risk.engagementScore,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AI Analysis
                    if (risk.riskExplanation != null &&
                        risk.riskExplanation!.isNotEmpty) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 20, color: AppColors.accent),
                                SizedBox(width: 8),
                                Text(
                                  'AI Analysis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              risk.riskExplanation!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Flags
                    if (risk.flags.isNotEmpty) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.flag_outlined,
                                    size: 20, color: AppColors.warning),
                                SizedBox(width: 8),
                                Text(
                                  'Warning Flags',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: risk.flags.map((flag) {
                                return Chip(
                                  label: Text(
                                    flag.replaceAll('_', ' '),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor:
                                      AppColors.warning.withValues(alpha: 0.1),
                                  side: BorderSide(
                                    color:
                                        AppColors.warning.withValues(alpha: 0.3),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Recommended actions
                    if (risk.recommendedActions.isNotEmpty) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    size: 20, color: AppColors.success),
                                SizedBox(width: 8),
                                Text(
                                  'Recommended Actions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            ...risk.recommendedActions.map(
                              (action) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        action,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
