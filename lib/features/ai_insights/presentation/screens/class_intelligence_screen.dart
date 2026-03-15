import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/class_intelligence_provider.dart';
import '../widgets/class_narrative_card.dart';
import '../widgets/subject_comparison_chart.dart';

class ClassIntelligenceScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final String? sectionName;

  const ClassIntelligenceScreen({
    super.key,
    required this.sectionId,
    this.sectionName,
  });

  @override
  ConsumerState<ClassIntelligenceScreen> createState() =>
      _ClassIntelligenceScreenState();
}

class _ClassIntelligenceScreenState
    extends ConsumerState<ClassIntelligenceScreen> {
  // Hardcoded for now -- in production, derive from the current academic year
  // context or accept it as a constructor parameter.
  final String _academicYearId = 'current';

  @override
  Widget build(BuildContext context) {
    final filter = SectionYearFilter(
      sectionId: widget.sectionId,
      academicYearId: _academicYearId,
    );

    final intelligenceAsync =
        ref.watch(enrichedClassIntelligenceProvider(filter));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---------- App Bar ----------
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.sectionName ?? 'Class Intelligence',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24, bottom: 8),
                    child: Icon(
                      Icons.insights,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ---------- Body ----------
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: intelligenceAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load class intelligence',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(enrichedClassIntelligenceProvider(filter)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (intelligence) => SliverList(
                delegate: SliverChildListDelegate([
                  // ---- Stats Row ----
                  _buildStatsRow(intelligence),
                  const SizedBox(height: 20),

                  // ---- Subject Comparison Chart ----
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bar_chart,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Subject Comparison',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SubjectComparisonChart(
                          subjects: intelligence.subjectStats,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- Risk Distribution ----
                  _buildRiskDistribution(context, intelligence.riskDistribution),
                  const SizedBox(height: 16),

                  // ---- AI Narrative Card ----
                  ClassNarrativeCard(
                    narrative: intelligence.aiNarrative,
                    isLoading: false,
                  ),
                  const SizedBox(height: 16),

                  // ---- View At-Risk Students ----
                  _buildAtRiskLink(context),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats row: 4 stat cards in a 2x2 grid
  // ---------------------------------------------------------------------------
  Widget _buildStatsRow(dynamic intelligence) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.people,
                iconColor: AppColors.primary,
                label: 'Total Students',
                value: '${intelligence.totalStudents}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.calendar_today,
                iconColor: AppColors.info,
                label: 'Avg Attendance',
                value: '${intelligence.averageAttendance.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.school,
                iconColor: AppColors.accent,
                label: 'Avg Score',
                value: '${intelligence.averageExamScore.toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
                label: 'Pass Rate',
                value: '${intelligence.passRate.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Risk distribution: colored chips showing low / medium / high / critical
  // ---------------------------------------------------------------------------
  Widget _buildRiskDistribution(
      BuildContext context, Map<String, int> distribution) {
    final theme = Theme.of(context);

    final levels = [
      ('Low', distribution['low'] ?? 0, AppColors.success),
      ('Medium', distribution['medium'] ?? 0, AppColors.warning),
      ('High', distribution['high'] ?? 0, const Color(0xFFF97316)),
      ('Critical', distribution['critical'] ?? 0, AppColors.error),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Risk Distribution',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: levels.map((level) {
              final (label, count, color) = level;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
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
                    const SizedBox(width: 8),
                    Text(
                      '$label: $count',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Link button to navigate to the risk dashboard filtered by this section
  // ---------------------------------------------------------------------------
  Widget _buildAtRiskLink(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      onTap: () {
        context.push(
          '${AppRoutes.riskDashboard}?sectionId=${widget.sectionId}',
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View At-Risk Students',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Students needing immediate attention in this section',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiaryLight,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Private stat tile widget
// =============================================================================

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
