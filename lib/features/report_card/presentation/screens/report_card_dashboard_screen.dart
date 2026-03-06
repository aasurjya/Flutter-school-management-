import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/report_card_provider.dart';

class ReportCardDashboardScreen extends ConsumerStatefulWidget {
  const ReportCardDashboardScreen({super.key});

  @override
  ConsumerState<ReportCardDashboardScreen> createState() =>
      _ReportCardDashboardScreenState();
}

class _ReportCardDashboardScreenState
    extends ConsumerState<ReportCardDashboardScreen> {
  String? _selectedAcademicYear;
  String? _selectedTerm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Card Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/report-cards/templates'),
            tooltip: 'Manage Templates',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            _QuickActionsSection(
              onGenerate: () => context.push('/report-cards/generate'),
              onTemplates: () => context.push('/report-cards/templates'),
              onGradingScales: () =>
                  context.push('/report-cards/grading-scales'),
              onViewAll: () => context.push('/report-cards/list'),
            ),
            const SizedBox(height: 24),

            // Filter Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAcademicYear,
                    decoration: const InputDecoration(
                      labelText: 'Academic Year',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: '2024-25', child: Text('2024-25')),
                      DropdownMenuItem(
                          value: '2023-24', child: Text('2023-24')),
                    ],
                    onChanged: (v) => setState(() => _selectedAcademicYear = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTerm,
                    decoration: const InputDecoration(
                      labelText: 'Term',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'term1', child: Text('Term 1')),
                      DropdownMenuItem(value: 'term2', child: Text('Term 2')),
                      DropdownMenuItem(
                          value: 'term3', child: Text('Final Term')),
                    ],
                    onChanged: (v) => setState(() => _selectedTerm = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Stats
            _OverviewStats(),
            const SizedBox(height: 24),

            // Per-Class Status
            Text(
              'Class-wise Status',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ClassStatusGrid(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/report-cards/generate'),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onGenerate;
  final VoidCallback onTemplates;
  final VoidCallback onGradingScales;
  final VoidCallback onViewAll;

  const _QuickActionsSection({
    required this.onGenerate,
    required this.onTemplates,
    required this.onGradingScales,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassStatCard(
            title: 'Generate',
            value: '',
            icon: Icons.auto_awesome,
            iconColor: AppColors.primary,
            gradient: AppColors.primaryGradient,
            onTap: onGenerate,
            subtitle: 'Bulk generate report cards',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassStatCard(
            title: 'Templates',
            value: '',
            icon: Icons.article_outlined,
            iconColor: AppColors.secondary,
            onTap: onTemplates,
            subtitle: 'Manage layouts',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassStatCard(
            title: 'Grading',
            value: '',
            icon: Icons.grade_outlined,
            iconColor: AppColors.accent,
            onTap: onGradingScales,
            subtitle: 'Grade scales',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassStatCard(
            title: 'All Reports',
            value: '',
            icon: Icons.list_alt,
            iconColor: AppColors.info,
            onTap: onViewAll,
            subtitle: 'View generated',
          ),
        ),
      ],
    );
  }
}

class _OverviewStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // In production, these would come from the dashboard summary provider
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Total Generated',
            value: '248',
            icon: Icons.description,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Pending Review',
            value: '32',
            icon: Icons.rate_review,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Published',
            value: '180',
            icon: Icons.publish,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Sent to Parents',
            value: '156',
            icon: Icons.send,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
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
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassStatusGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock data; in production this comes from v_report_card_summary
    final classes = [
      _ClassStatus('Class 1-A', 40, 38, 2, 0),
      _ClassStatus('Class 1-B', 42, 40, 0, 2),
      _ClassStatus('Class 2-A', 38, 30, 5, 3),
      _ClassStatus('Class 2-B', 40, 40, 0, 0),
      _ClassStatus('Class 3-A', 45, 20, 10, 15),
      _ClassStatus('Class 3-B', 43, 0, 0, 43),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final c = classes[index];
        final publishedPct =
            c.total > 0 ? (c.published / c.total * 100) : 0.0;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          onTap: () =>
              context.push('/report-cards/list?section=${c.name}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                c.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: publishedPct / 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    publishedPct == 100
                        ? AppColors.success
                        : publishedPct > 50
                            ? AppColors.info
                            : AppColors.warning,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${c.published}/${c.total} published  '
                '${c.pending > 0 ? "${c.pending} pending" : ""}'
                '${c.notGenerated > 0 ? "  ${c.notGenerated} not started" : ""}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClassStatus {
  final String name;
  final int total;
  final int published;
  final int pending;
  final int notGenerated;

  _ClassStatus(
      this.name, this.total, this.published, this.pending, this.notGenerated);
}
