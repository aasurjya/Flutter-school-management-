import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/communication.dart';
import '../../providers/communication_provider.dart';
import '../widgets/channel_selector.dart';

class CommunicationLogScreen extends ConsumerStatefulWidget {
  const CommunicationLogScreen({super.key});

  @override
  ConsumerState<CommunicationLogScreen> createState() =>
      _CommunicationLogScreenState();
}

class _CommunicationLogScreenState
    extends ConsumerState<CommunicationLogScreen> {
  CommunicationChannel? _channelFilter;
  RecipientStatus? _statusFilter;
  CommunicationDirection? _directionFilter;
  DateTime? _fromDate;
  DateTime? _toDate;

  CommunicationLogFilter get _currentFilter => CommunicationLogFilter(
        channel: _channelFilter,
        status: _statusFilter,
        direction: _directionFilter,
        fromDate: _fromDate,
        toDate: _toDate,
        limit: 100,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logAsync = ref.watch(communicationLogProvider(_currentFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters
          if (_hasActiveFilters) _buildActiveFilters(theme),

          // Log list
          Expanded(
            child: logAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No communication logs found',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(communicationLogProvider(_currentFilter));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      return _LogEntry(log: logs[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                          communicationLogProvider(_currentFilter)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _channelFilter != null ||
      _statusFilter != null ||
      _directionFilter != null ||
      _fromDate != null ||
      _toDate != null;

  Widget _buildActiveFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_channelFilter != null)
                    _buildFilterChip(
                      _channelFilter!.label,
                      () => setState(() => _channelFilter = null),
                    ),
                  if (_statusFilter != null)
                    _buildFilterChip(
                      _statusFilter!.label,
                      () => setState(() => _statusFilter = null),
                    ),
                  if (_directionFilter != null)
                    _buildFilterChip(
                      _directionFilter!.label,
                      () => setState(() => _directionFilter = null),
                    ),
                  if (_fromDate != null)
                    _buildFilterChip(
                      'From: ${DateFormat('MMM d').format(_fromDate!)}',
                      () => setState(() => _fromDate = null),
                    ),
                  if (_toDate != null)
                    _buildFilterChip(
                      'To: ${DateFormat('MMM d').format(_toDate!)}',
                      () => setState(() => _toDate = null),
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onDeleted: onRemove,
        deleteIconColor: AppColors.primary,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _channelFilter = null;
      _statusFilter = null;
      _directionFilter = null;
      _fromDate = null;
      _toDate = null;
    });
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            _clearFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Channel filter
                    const Text('Channel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _channelFilter == null,
                          onSelected: (_) {
                            setSheetState(() => _channelFilter = null);
                            setState(() {});
                          },
                        ),
                        ...CommunicationChannel.values.map((ch) {
                          return ChoiceChip(
                            label: Text(ch.label),
                            selected: _channelFilter == ch,
                            onSelected: (_) {
                              setSheetState(() => _channelFilter = ch);
                              setState(() {});
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status filter
                    const Text('Status',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _statusFilter == null,
                          onSelected: (_) {
                            setSheetState(() => _statusFilter = null);
                            setState(() {});
                          },
                        ),
                        ...RecipientStatus.values.map((s) {
                          return ChoiceChip(
                            label: Text(s.label),
                            selected: _statusFilter == s,
                            onSelected: (_) {
                              setSheetState(() => _statusFilter = s);
                              setState(() {});
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Direction filter
                    const Text('Direction',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _directionFilter == null,
                          onSelected: (_) {
                            setSheetState(() => _directionFilter = null);
                            setState(() {});
                          },
                        ),
                        ...CommunicationDirection.values.map((d) {
                          return ChoiceChip(
                            label: Text(d.label),
                            selected: _directionFilter == d,
                            onSelected: (_) {
                              setSheetState(() => _directionFilter = d);
                              setState(() {});
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date range
                    const Text('Date Range',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _fromDate ?? DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setSheetState(() => _fromDate = date);
                                setState(() {});
                              }
                            },
                            child: Text(
                              _fromDate != null
                                  ? DateFormat('MMM d').format(_fromDate!)
                                  : 'From Date',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _toDate ?? DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setSheetState(() => _toDate = date);
                                setState(() {});
                              }
                            },
                            child: Text(
                              _toDate != null
                                  ? DateFormat('MMM d').format(_toDate!)
                                  : 'To Date',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Apply Filters',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LogEntry extends StatelessWidget {
  final CommunicationLog log;

  const _LogEntry({required this.log});

  Color get _statusColor {
    switch (log.status) {
      case RecipientStatus.pending:
        return AppColors.textSecondaryLight;
      case RecipientStatus.sent:
        return AppColors.info;
      case RecipientStatus.delivered:
        return AppColors.success;
      case RecipientStatus.read:
        return AppColors.primary;
      case RecipientStatus.failed:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormatter = DateFormat('h:mm a');
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ChannelSelector.colorForChannel(log.channel)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ChannelSelector.iconForChannel(log.channel),
              size: 18,
              color: ChannelSelector.colorForChannel(log.channel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Direction icon
                    Icon(
                      log.direction == CommunicationDirection.outbound
                          ? Icons.arrow_outward
                          : Icons.arrow_downward,
                      size: 14,
                      color: log.direction == CommunicationDirection.outbound
                          ? AppColors.primary
                          : AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.userName ?? log.recipientInfo ?? 'Unknown',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (log.contentPreview != null &&
                    log.contentPreview!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.contentPreview!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (log.errorMessage != null &&
                    log.errorMessage!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${log.errorMessage}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  log.createdAt != null
                      ? '${dateFormatter.format(log.createdAt!)} at ${timeFormatter.format(log.createdAt!)}'
                      : '',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
