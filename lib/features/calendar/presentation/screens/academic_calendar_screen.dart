import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/school_event.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/calendar_provider.dart';
import '../widgets/academic_timeline.dart';

/// Year overview screen with terms, exams, and holidays on a timeline
class AcademicCalendarScreen extends ConsumerStatefulWidget {
  final String? academicYearId;

  const AcademicCalendarScreen({super.key, this.academicYearId});

  @override
  ConsumerState<AcademicCalendarScreen> createState() =>
      _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState
    extends ConsumerState<AcademicCalendarScreen> {
  String? _academicYearId;
  AcademicItemType? _filterType;
  bool _showAddForm = false;

  // Form fields for adding new item
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  AcademicItemType _newItemType = AcademicItemType.holiday;
  DateTime _newDate = DateTime.now();
  DateTime? _newEndDate;
  bool _newIsHoliday = false;

  @override
  void initState() {
    super.initState();
    _academicYearId = widget.academicYearId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Academic Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: _academicYearId == null
          ? _buildNoYearSelected(context)
          : _buildContent(context),
      floatingActionButton: _academicYearId != null
          ? FloatingActionButton(
              onPressed: () => setState(() => _showAddForm = !_showAddForm),
              backgroundColor: AppColors.primary,
              child: Icon(
                _showAddForm ? Icons.close : Icons.add,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget _buildNoYearSelected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month,
              size: 64, color: AppColors.textTertiaryLight),
          const SizedBox(height: 12),
          Text(
            'No Academic Year Selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Please select an academic year to view the calendar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // In production, this would open a year picker.
              // For now, just show a placeholder message.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Connect to academic year selector')),
              );
            },
            child: const Text('Select Year'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync =
        ref.watch(academicCalendarProvider(_academicYearId!));

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load: $error'),
          ],
        ),
      ),
      data: (items) {
        // Apply filter
        final filtered = _filterType != null
            ? items.where((i) => i.itemType == _filterType).toList()
            : items;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(academicCalendarProvider(_academicYearId!));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              _buildSummaryCards(context, items),

              const SizedBox(height: 16),

              // Add form (collapsible)
              if (_showAddForm) ...[
                _buildAddForm(context),
                const SizedBox(height: 16),
              ],

              // Filter active indicator
              if (_filterType != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Showing: ${_filterType!.label}',
                          style: const TextStyle(
                            color: AppColors.primary,
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

              // Timeline
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Timeline',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    AcademicTimeline(items: filtered),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, List<AcademicCalendarItem> items) {
    final holidays = items.where((i) => i.isHoliday).length;
    final exams = items
        .where((i) =>
            i.itemType == AcademicItemType.examStart ||
            i.itemType == AcademicItemType.examEnd)
        .length;
    final terms = items
        .where((i) =>
            i.itemType == AcademicItemType.termStart ||
            i.itemType == AcademicItemType.termEnd)
        .length;
    return Row(
      children: [
        _SummaryChip(
            label: 'Total', count: items.length, color: AppColors.primary),
        _SummaryChip(
            label: 'Holidays', count: holidays, color: AppColors.accent),
        _SummaryChip(
            label: 'Exams', count: exams, color: AppColors.error),
        _SummaryChip(
            label: 'Terms', count: terms, color: AppColors.success),
      ],
    );
  }

  Widget _buildAddForm(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Calendar Item',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<AcademicItemType>(
            value: _newItemType,
            decoration: const InputDecoration(
              labelText: 'Item Type',
              isDense: true,
            ),
            items: AcademicItemType.values.map((t) {
              return DropdownMenuItem(value: t, child: Text(t.label));
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _newItemType = v;
                  _newIsHoliday = v == AcademicItemType.holiday;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DatePickerTile(
                  label: 'Date',
                  date: _newDate,
                  onPick: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _newDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _newDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DatePickerTile(
                  label: 'End Date (opt.)',
                  date: _newEndDate,
                  onPick: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _newEndDate ?? _newDate,
                      firstDate: _newDate,
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _newEndDate = picked);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Is Holiday'),
            value: _newIsHoliday,
            onChanged: (v) => setState(() => _newIsHoliday = v),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Item'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    try {
      final repo = ref.read(calendarRepositoryProvider);
      await repo.createAcademicCalendarItem({
        'academic_year_id': _academicYearId,
        'title': _titleController.text.trim(),
        'date': _newDate.toIso8601String().split('T')[0],
        'end_date': _newEndDate?.toIso8601String().split('T')[0],
        'item_type': _newItemType.value,
        'is_holiday': _newIsHoliday,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      });

      ref.invalidate(academicCalendarProvider(_academicYearId!));
      _titleController.clear();
      _notesController.clear();
      setState(() => _showAddForm = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calendar item added')),
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

  void _showFilterDialog(BuildContext context) {
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
              children: AcademicItemType.values.map((type) {
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
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
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

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 2),
            Text(
              date != null
                  ? DateFormat('MMM d, yy').format(date!)
                  : 'Select',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
