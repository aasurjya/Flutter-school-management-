import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/discipline.dart';
import '../../providers/discipline_provider.dart';
import '../widgets/incident_card.dart';

class IncidentListScreen extends ConsumerStatefulWidget {
  const IncidentListScreen({super.key});

  @override
  ConsumerState<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends ConsumerState<IncidentListScreen> {
  IncidentSeverity? _selectedSeverity;
  IncidentStatus? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  IncidentFilter get _currentFilter => IncidentFilter(
        severity: _selectedSeverity,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
      );

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(behaviorIncidentsProvider(_currentFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior Incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Filters
          if (_hasActiveFilters) _buildActiveFilters(),

          // List
          Expanded(
            child: incidentsAsync.when(
              data: (incidents) {
                if (incidents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No incidents found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
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
                    ref.invalidate(
                      behaviorIncidentsProvider(_currentFilter),
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: incidents.length,
                    itemBuilder: (context, index) {
                      final incident = incidents[index];
                      return IncidentCard(
                        incident: incident,
                        onTap: () => context.push(
                          '/discipline/incidents/${incident.id}',
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Error: $e'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                        behaviorIncidentsProvider(_currentFilter),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/discipline/report'),
        icon: const Icon(Icons.add),
        label: const Text('Report Incident'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedSeverity != null ||
      _selectedStatus != null ||
      _startDate != null ||
      _endDate != null;

  Widget _buildActiveFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (_selectedSeverity != null)
            _FilterChip(
              label: _selectedSeverity!.displayLabel,
              onRemove: () => setState(() => _selectedSeverity = null),
            ),
          if (_selectedStatus != null)
            _FilterChip(
              label: _selectedStatus!.displayLabel,
              onRemove: () => setState(() => _selectedStatus = null),
            ),
          if (_startDate != null || _endDate != null)
            _FilterChip(
              label: 'Date range',
              onRemove: () => setState(() {
                _startDate = null;
                _endDate = null;
              }),
            ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedSeverity = null;
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Incidents',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Severity
                  const Text(
                    'Severity',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: IncidentSeverity.values.map((s) {
                      final selected = _selectedSeverity == s;
                      return ChoiceChip(
                        label: Text(s.displayLabel),
                        selected: selected,
                        onSelected: (val) {
                          setModalState(() {});
                          setState(() {
                            _selectedSeverity = val ? s : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Status
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: IncidentStatus.values.map((s) {
                      final selected = _selectedStatus == s;
                      return ChoiceChip(
                        label: Text(s.displayLabel),
                        selected: selected,
                        onSelected: (val) {
                          setModalState(() {});
                          setState(() {
                            _selectedStatus = val ? s : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Date Range
                  const Text(
                    'Date Range',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : 'Start Date',
                          ),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) {
                              setModalState(() {});
                              setState(() => _startDate = d);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'End Date',
                          ),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) {
                              setModalState(() {});
                              setState(() => _endDate = d);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
