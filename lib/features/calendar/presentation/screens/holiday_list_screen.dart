import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/school_event.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/calendar_provider.dart';

/// Holiday calendar management screen (add/edit/delete holidays)
class HolidayListScreen extends ConsumerStatefulWidget {
  final String? academicYearId;

  const HolidayListScreen({super.key, this.academicYearId});

  @override
  ConsumerState<HolidayListScreen> createState() =>
      _HolidayListScreenState();
}

class _HolidayListScreenState extends ConsumerState<HolidayListScreen> {
  String? _academicYearId;
  HolidayType? _filterType;

  @override
  void initState() {
    super.initState();
    _academicYearId = widget.academicYearId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Holiday Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: _academicYearId == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.beach_access,
                      size: 64, color: AppColors.textTertiaryLight),
                  const SizedBox(height: 12),
                  Text(
                    'No Academic Year Selected',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : _buildContent(context),
      floatingActionButton: _academicYearId != null
          ? FloatingActionButton(
              onPressed: () => _showAddHolidayDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final holidaysAsync =
        ref.watch(holidaysProvider(_academicYearId!));

    return holidaysAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Failed to load: $error')),
      data: (holidays) {
        // Apply filter
        final filtered = _filterType != null
            ? holidays.where((h) => h.type == _filterType).toList()
            : holidays;

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.beach_access,
                    size: 64, color: AppColors.textTertiaryLight),
                const SizedBox(height: 12),
                Text(
                  'No holidays found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add holidays using the + button',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        // Summary row
        final totalDays = filtered.fold<int>(
            0, (sum, h) => sum + h.totalDays);
        final upcoming = filtered
            .where((h) =>
                !h.date.isBefore(DateTime.now()))
            .length;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(holidaysProvider(_academicYearId!));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary
              Row(
                children: [
                  _SummaryChip(
                    label: 'Total',
                    count: '${filtered.length}',
                    color: AppColors.accent,
                  ),
                  _SummaryChip(
                    label: 'Total Days',
                    count: '$totalDays',
                    color: AppColors.success,
                  ),
                  _SummaryChip(
                    label: 'Upcoming',
                    count: '$upcoming',
                    color: AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter indicator
              if (_filterType != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Showing: ${_filterType!.label}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _filterType = null),
                        child: const Icon(Icons.close,
                            size: 18,
                            color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),

              // Holiday list
              ...filtered.map((holiday) =>
                  _buildHolidayCard(context, holiday)),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHolidayCard(BuildContext context, Holiday holiday) {
    final theme = Theme.of(context);
    final isPast = holiday.date.isBefore(DateTime.now());
    final typeColor = _holidayTypeColor(holiday.type);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            // Date column
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM').format(holiday.date).toUpperCase(),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${holiday.date.day}',
                    style: TextStyle(
                      color: isPast
                          ? AppColors.textSecondaryLight
                          : AppColors.textPrimaryLight,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (holiday.totalDays > 1)
                    Text(
                      '${holiday.totalDays}d',
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            holiday.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPast
                                  ? AppColors.textSecondaryLight
                                  : null,
                              decoration: isPast
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (holiday.isOptional)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Optional',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            holiday.type.label,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Actions
                        IconButton(
                          onPressed: () =>
                              _showEditHolidayDialog(context, holiday),
                          icon: const Icon(Icons.edit, size: 16),
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          color: AppColors.textSecondaryLight,
                        ),
                        IconButton(
                          onPressed: () =>
                              _confirmDeleteHoliday(context, holiday),
                          icon: const Icon(Icons.delete, size: 16),
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _holidayTypeColor(HolidayType type) {
    switch (type) {
      case HolidayType.national:
        return AppColors.error;
      case HolidayType.state:
        return AppColors.info;
      case HolidayType.religious:
        return AppColors.accent;
      case HolidayType.schoolDeclared:
        return AppColors.primary;
      case HolidayType.vacation:
        return AppColors.success;
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filter by Type',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _filterType = null);
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HolidayType.values.map((type) {
                return FilterChip(
                  label: Text(type.label),
                  selected: _filterType == type,
                  onSelected: (selected) {
                    setState(
                        () => _filterType = selected ? type : null);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddHolidayDialog(BuildContext context, {Holiday? existing}) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    var type = existing?.type ?? HolidayType.schoolDeclared;
    var date = existing?.date ?? DateTime.now();
    DateTime? endDate = existing?.endDate;
    var isOptional = existing?.isOptional ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing != null
                  ? 'Edit Holiday'
                  : 'Add Holiday'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Holiday Name *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<HolidayType>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                      ),
                      items: HolidayType.values
                          .map((t) => DropdownMenuItem(
                              value: t, child: Text(t.label)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => type = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => date = picked);
                          }
                        },
                        child: Text(DateFormat('MMM d, yyyy')
                            .format(date)),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End Date (optional)'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? date,
                            firstDate: date,
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                        child: Text(endDate != null
                            ? DateFormat('MMM d, yyyy')
                                .format(endDate!)
                            : 'Select'),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Optional Holiday'),
                      value: isOptional,
                      onChanged: (v) {
                        setDialogState(
                            () => isOptional = v ?? false);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    await _saveHoliday(
                      existing?.id,
                      name: nameCtrl.text.trim(),
                      type: type,
                      date: date,
                      endDate: endDate,
                      isOptional: isOptional,
                    );
                  },
                  child: Text(existing != null ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditHolidayDialog(BuildContext context, Holiday holiday) {
    _showAddHolidayDialog(context, existing: holiday);
  }

  Future<void> _saveHoliday(
    String? existingId, {
    required String name,
    required HolidayType type,
    required DateTime date,
    DateTime? endDate,
    required bool isOptional,
  }) async {
    try {
      final repo = ref.read(calendarRepositoryProvider);
      final data = {
        'academic_year_id': _academicYearId,
        'name': name,
        'date': date.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'type': type.value,
        'is_optional': isOptional,
      };

      if (existingId != null) {
        await repo.updateHoliday(existingId, data);
      } else {
        await repo.createHoliday(data);
      }

      ref.invalidate(holidaysProvider(_academicYearId!));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Holiday ${existingId != null ? 'updated' : 'added'}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteHoliday(
      BuildContext context, Holiday holiday) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text(
            'Are you sure you want to delete "${holiday.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(calendarRepositoryProvider);
        await repo.deleteHoliday(holiday.id);
        ref.invalidate(holidaysProvider(_academicYearId!));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Holiday deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
