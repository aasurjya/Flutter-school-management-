import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/report_card_full.dart';
import '../../providers/report_card_provider.dart';

class ReportCardListScreen extends ConsumerStatefulWidget {
  const ReportCardListScreen({super.key});

  @override
  ConsumerState<ReportCardListScreen> createState() =>
      _ReportCardListScreenState();
}

class _ReportCardListScreenState extends ConsumerState<ReportCardListScreen> {
  String? _filterStatus;
  String? _filterSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ReportCardFullFilter(
      status: _filterStatus,
      sectionId: _filterSection,
    );
    final reportsAsync = ref.watch(rcListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterStatus == null,
                  onSelected: () => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Draft',
                  selected: _filterStatus == 'draft',
                  onSelected: () =>
                      setState(() => _filterStatus = 'draft'),
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Generated',
                  selected: _filterStatus == 'generated',
                  onSelected: () =>
                      setState(() => _filterStatus = 'generated'),
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Reviewed',
                  selected: _filterStatus == 'reviewed',
                  onSelected: () =>
                      setState(() => _filterStatus = 'reviewed'),
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Published',
                  selected: _filterStatus == 'published',
                  onSelected: () =>
                      setState(() => _filterStatus = 'published'),
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Sent',
                  selected: _filterStatus == 'sent',
                  onSelected: () =>
                      setState(() => _filterStatus = 'sent'),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        const Text('No report cards found'),
                        const SizedBox(height: 8),
                        Text(
                          _filterStatus != null
                              ? 'Try changing the filter'
                              : 'Generate report cards first',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _ReportCardItem(
                      report: report,
                      onTap: () => context
                          .push('/report-cards/detail/${report.id}'),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Report Cards',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _filterSection,
              decoration: const InputDecoration(
                labelText: 'Section',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Sections')),
                DropdownMenuItem(
                    value: 'secA', child: Text('Class 10-A')),
                DropdownMenuItem(
                    value: 'secB', child: Text('Class 10-B')),
              ],
              onChanged: (v) =>
                  setState(() => _filterSection = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: c.withValues(alpha: 0.2),
      checkmarkColor: c,
      labelStyle: TextStyle(
        color: selected ? c : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
    );
  }
}

class _ReportCardItem extends StatelessWidget {
  final ReportCardFull report;
  final VoidCallback onTap;

  const _ReportCardItem({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              (report.studentName ?? 'S')[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.studentDisplayName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.classSection}  |  Roll: ${report.rollNumber ?? "N/A"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${report.academicYearName ?? ""} | ${report.termName ?? ""}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(report.status),
              if (report.pdfUrl != null) ...[
                const SizedBox(height: 8),
                Icon(Icons.picture_as_pdf,
                    color: AppColors.error, size: 20),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'draft':
        color = Colors.orange;
      case 'generated':
        color = AppColors.info;
      case 'reviewed':
        color = AppColors.accent;
      case 'published':
        color = AppColors.success;
      case 'sent':
        color = AppColors.primary;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
