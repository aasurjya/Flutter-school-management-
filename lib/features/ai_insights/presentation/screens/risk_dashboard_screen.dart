import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/risk_score_provider.dart';
import '../widgets/risk_score_badge.dart';

class RiskDashboardScreen extends ConsumerStatefulWidget {
  final String academicYearId;

  const RiskDashboardScreen({
    super.key,
    required this.academicYearId,
  });

  @override
  ConsumerState<RiskDashboardScreen> createState() =>
      _RiskDashboardScreenState();
}

class _RiskDashboardScreenState extends ConsumerState<RiskDashboardScreen> {
  String? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    final distributionAsync = ref.watch(riskDistributionProvider(
      RiskDistributionFilter(academicYearId: widget.academicYearId),
    ));

    final atRiskAsync = ref.watch(atRiskStudentsProvider(
      AtRiskFilter(
        academicYearId: widget.academicYearId,
        riskLevel: _selectedLevel,
        limit: 50,
      ),
    ));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Risk Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Distribution cards
                distributionAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const Text('Failed to load distribution'),
                  data: (dist) => _buildDistributionRow(dist),
                ),
                const SizedBox(height: 20),

                // Filter chips
                _buildFilterChips(),
                const SizedBox(height: 16),

                // Student list
                atRiskAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const Center(
                    child: Text('Failed to load at-risk students'),
                  ),
                  data: (students) {
                    if (students.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: AppColors.success,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No at-risk students found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: students
                          .map((s) => _buildStudentRiskCard(context, s))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionRow(Map<String, int> dist) {
    return Row(
      children: [
        _DistCard('Low', dist['low'] ?? 0, const Color(0xFF22C55E)),
        const SizedBox(width: 8),
        _DistCard('Medium', dist['medium'] ?? 0, const Color(0xFFF59E0B)),
        const SizedBox(width: 8),
        _DistCard('High', dist['high'] ?? 0, const Color(0xFFF97316)),
        const SizedBox(width: 8),
        _DistCard('Critical', dist['critical'] ?? 0, const Color(0xFFEF4444)),
      ].map((w) => w is _DistCard ? Expanded(child: w) : w).toList(),
    );
  }

  Widget _buildFilterChips() {
    final levels = [null, 'critical', 'high', 'medium', 'low'];
    final labels = ['All', 'Critical', 'High', 'Medium', 'Low'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(levels.length, (i) {
          final isSelected = _selectedLevel == levels[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[i]),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedLevel = levels[i]);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStudentRiskCard(BuildContext context, dynamic riskScore) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () {
        context.push(
          '${AppRoutes.riskDashboard}/${riskScore.studentId}'
          '?yearId=${widget.academicYearId}',
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: riskScore.riskColor.withValues(alpha: 0.15),
            child: Text(
              '${riskScore.overallRiskScore.round()}',
              style: TextStyle(
                color: riskScore.riskColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskScore.studentName ?? 'Student',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${riskScore.className ?? ''} ${riskScore.sectionName ?? ''}'
                      .trim(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          RiskScoreBadge(riskScore: riskScore),
          const SizedBox(width: 8),
          Icon(riskScore.trendIcon, color: riskScore.trendColor, size: 20),
        ],
      ),
    );
  }
}

class _DistCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _DistCard(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return GlassStatCard(
      title: label,
      value: '$count',
      icon: Icons.person,
      iconColor: color,
    );
  }
}
