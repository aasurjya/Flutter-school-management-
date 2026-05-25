import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/report_card_full.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../providers/report_card_provider.dart';

/// Report Card dashboard — admin/principal entry point.
///
/// Year and term selectors are real (academicYearsProvider, termsProvider).
/// Both `_OverviewStats` and `_ClassStatusGrid` are powered by
/// `rcDashboardSummaryProvider` which reads `v_report_card_summary`.
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
    final yearsAsync = ref.watch(academicYearsProvider);

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
            _QuickActionsSection(
              onGenerate: () => context.push('/report-cards/generate'),
              onTemplates: () => context.push('/report-cards/templates'),
              onGradingScales: () =>
                  context.push('/report-cards/grading-scales'),
              onViewAll: () => context.push('/report-cards/list'),
            ),
            const SizedBox(height: 24),

            // Filters — real year + term
            Row(
              children: [
                Expanded(child: _yearDropdown(yearsAsync)),
                const SizedBox(width: 12),
                Expanded(child: _termDropdown()),
              ],
            ),
            const SizedBox(height: 24),

            _OverviewStats(
              academicYearId: _selectedAcademicYear,
              termId: _selectedTerm,
            ),
            const SizedBox(height: 24),

            Text(
              'Class-wise Status',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ClassStatusGrid(
              academicYearId: _selectedAcademicYear,
              termId: _selectedTerm,
            ),
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

  Widget _yearDropdown(AsyncValue<List<dynamic>> yearsAsync) {
    return yearsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Years unavailable. $e'),
      data: (years) {
        if (years.isEmpty) {
          return const Text(
            'No academic years yet.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          );
        }
        _selectedAcademicYear ??= years.first.id as String;
        return DropdownButtonFormField<String>(
          initialValue: _selectedAcademicYear,
          decoration: const InputDecoration(
            labelText: 'Academic Year',
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: years
              .map((y) => DropdownMenuItem(
                    value: y.id as String,
                    child: Text(y.name as String),
                  ))
              .toList(),
          onChanged: (v) => setState(() {
            _selectedAcademicYear = v;
            _selectedTerm = null;
          }),
        );
      },
    );
  }

  Widget _termDropdown() {
    if (_selectedAcademicYear == null) {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Term',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: const [],
        onChanged: null,
      );
    }
    final termsAsync = ref.watch(termsProvider(_selectedAcademicYear!));
    return termsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Terms unavailable. $e'),
      data: (terms) {
        if (terms.isEmpty) {
          return const Text(
            'No terms yet.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: _selectedTerm,
          decoration: const InputDecoration(
            labelText: 'Term',
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: terms
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedTerm = v),
        );
      },
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

// ---------------------------------------------------------------------------
// Real overview stats — totals across all sections for the picked year/term
// ---------------------------------------------------------------------------

class _OverviewStats extends ConsumerWidget {
  const _OverviewStats({this.academicYearId, this.termId});
  final String? academicYearId;
  final String? termId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (academicYearId == null || termId == null) {
      return const _OverviewPlaceholder(
        message: 'Pick an academic year and term to see totals.',
      );
    }
    final params = RCDashboardParams(
      academicYearId: academicYearId!,
      termId: termId!,
    );
    final summaryAsync = ref.watch(rcDashboardSummaryProvider(params));
    return summaryAsync.when(
      loading: () => const _OverviewPlaceholder(
        message: 'Loading…',
        isProgress: true,
      ),
      error: (e, _) => _OverviewPlaceholder(
        message: 'Could not load summary. $e',
      ),
      data: (rows) => _OverviewRow(rows: rows),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.rows});
  final List<ReportCardSummary> rows;

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(0, (sum, r) => sum + r.totalReports);
    final pending = rows.fold<int>(0, (sum, r) => sum + r.pendingCount);
    final published = rows.fold<int>(0, (sum, r) => sum + r.publishedCount);
    final sent = rows.fold<int>(0, (sum, r) => sum + r.sentCount);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Total Generated',
            value: '$total',
            icon: Icons.description,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Pending Review',
            value: '$pending',
            icon: Icons.rate_review,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Published',
            value: '$published',
            icon: Icons.publish,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Sent to Parents',
            value: '$sent',
            icon: Icons.send,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _OverviewPlaceholder extends StatelessWidget {
  const _OverviewPlaceholder({required this.message, this.isProgress = false});
  final String message;
  final bool isProgress;
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (isProgress)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
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

// ---------------------------------------------------------------------------
// Real class-status grid — one tile per section
// ---------------------------------------------------------------------------

class _ClassStatusGrid extends ConsumerWidget {
  const _ClassStatusGrid({this.academicYearId, this.termId});
  final String? academicYearId;
  final String? termId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (academicYearId == null || termId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Select year and term to see per-class status.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    final params = RCDashboardParams(
      academicYearId: academicYearId!,
      termId: termId!,
    );
    final summaryAsync = ref.watch(rcDashboardSummaryProvider(params));

    return summaryAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Could not load class status. $e'),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const GlassCard(
            padding: EdgeInsets.all(20),
            child: Text(
              'No report cards generated for this term yet.\nTap Generate to start.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final r = rows[index];
            final publishedPct = r.publishedPercent;
            return GlassCard(
              padding: const EdgeInsets.all(16),
              onTap: () =>
                  context.push('/report-cards/list?section=${r.sectionId}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${r.className} · ${r.sectionName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    _statusLine(r),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _statusLine(ReportCardSummary r) {
    final parts = <String>[
      '${r.publishedCount + r.sentCount}/${r.totalReports} published',
    ];
    if (r.pendingCount > 0) parts.add('${r.pendingCount} pending');
    return parts.join('  ');
  }
}
