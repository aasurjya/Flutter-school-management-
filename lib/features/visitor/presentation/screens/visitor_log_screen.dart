import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/visitor.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/visitor_provider.dart';

class VisitorLogScreen extends ConsumerStatefulWidget {
  const VisitorLogScreen({super.key});

  @override
  ConsumerState<VisitorLogScreen> createState() =>
      _VisitorLogScreenState();
}

class _VisitorLogScreenState extends ConsumerState<VisitorLogScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _statusFilter;
  final _searchController = TextEditingController();

  VisitorLogFilter get _currentFilter => VisitorLogFilter(
        status: _statusFilter,
        fromDate: _fromDate,
        toDate: _toDate,
        search: _searchController.text.isEmpty
            ? null
            : _searchController.text,
        limit: 100,
      );

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end.add(const Duration(days: 1));
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(visitorLogsProvider(_currentFilter));
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat.jm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search visitors...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _statusFilter == null,
                        onTap: () =>
                            setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Checked In',
                        selected: _statusFilter == 'checked_in',
                        color: AppColors.success,
                        onTap: () => setState(
                            () => _statusFilter = 'checked_in'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Checked Out',
                        selected: _statusFilter == 'checked_out',
                        color: AppColors.info,
                        onTap: () => setState(
                            () => _statusFilter = 'checked_out'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Denied',
                        selected: _statusFilter == 'denied',
                        color: AppColors.error,
                        onTap: () =>
                            setState(() => _statusFilter = 'denied'),
                      ),
                      if (_fromDate != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            '${dateFormat.format(_fromDate!)} - ${dateFormat.format(_toDate ?? DateTime.now())}',
                            style: theme.textTheme.labelSmall,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setState(() {
                            _fromDate = null;
                            _toDate = null;
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Log list
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox,
                            size: 64, color: AppColors.textTertiaryLight),
                        const SizedBox(height: 16),
                        Text(
                          'No visitor logs found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return GlassCard(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        if (log.visitor != null) {
                          context.push(
                            AppRoutes.visitorDetail.replaceFirst(
                                ':visitorId', log.visitor!.id),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _statusColor(log.status)
                                .withValues(alpha: 0.1),
                            child: Icon(
                              _statusIcon(log.status),
                              color: _statusColor(log.status),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.visitor?.fullName ?? 'Visitor',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  log.purpose.label,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                                Text(
                                  '${dateFormat.format(log.checkInTime)} ${timeFormat.format(log.checkInTime)}'
                                  '${log.checkOutTime != null ? ' - ${timeFormat.format(log.checkOutTime!)}' : ''}',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppColors.textTertiaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusColor(log.status)
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  log.status.label,
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: _statusColor(log.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (log.badgeNumber != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '#${log.badgeNumber}',
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiaryLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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

  Color _statusColor(VisitorLogStatus status) {
    switch (status) {
      case VisitorLogStatus.checkedIn:
        return AppColors.success;
      case VisitorLogStatus.checkedOut:
        return AppColors.info;
      case VisitorLogStatus.denied:
        return AppColors.error;
      case VisitorLogStatus.preRegistered:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(VisitorLogStatus status) {
    switch (status) {
      case VisitorLogStatus.checkedIn:
        return Icons.login;
      case VisitorLogStatus.checkedOut:
        return Icons.logout;
      case VisitorLogStatus.denied:
        return Icons.block;
      case VisitorLogStatus.preRegistered:
        return Icons.event;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: chipColor.withValues(alpha: 0.15),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: selected ? chipColor : AppColors.textSecondaryLight,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
