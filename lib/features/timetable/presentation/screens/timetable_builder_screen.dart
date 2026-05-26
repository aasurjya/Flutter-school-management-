import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../data/models/academic.dart';
import '../../../../data/models/timetable.dart';
import '../../../../data/repositories/timetable_repository.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../providers/timetable_provider.dart';

// ---------------------------------------------------------------------------
// Conflict-detection helper
// ---------------------------------------------------------------------------

/// Returns all timetable rows where the given teacher is already booked for
/// [dayOfWeek] + [slotId].  An empty list means no conflict.
Future<List<Timetable>> detectTeacherConflicts({
  required TimetableRepository repository,
  required String teacherId,
  required int dayOfWeek,
  required String slotId,
  required String academicYearId,
  /// The entry being *edited* (excluded from conflict check).
  String? excludeTimetableId,
}) async {
  final rows = await repository.getTeacherTimetable(
    teacherId: teacherId,
    academicYearId: academicYearId,
    dayOfWeek: dayOfWeek,
  );
  return rows.where((r) {
    if (r.slotId != slotId) return false;
    if (excludeTimetableId != null && r.id == excludeTimetableId) return false;
    return true;
  }).toList();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TimetableBuilderScreen extends ConsumerStatefulWidget {
  const TimetableBuilderScreen({super.key});

  @override
  ConsumerState<TimetableBuilderScreen> createState() =>
      _TimetableBuilderScreenState();
}

class _TimetableBuilderScreenState
    extends ConsumerState<TimetableBuilderScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSectionName;

  // 1 = Mon … 6 = Sat (DB uses ISO weekday 1-7)
  static const _days = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.systemGroupedBackground,
      appBar: AppBar(
        title: const Text('Timetable Builder'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedSectionId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload',
              onPressed: _reload,
            ),
        ],
      ),
      body: Column(
        children: [
          _SectionPicker(
            selectedClassId: _selectedClassId,
            selectedSectionId: _selectedSectionId,
            onClassSelected: (id) => setState(() {
              _selectedClassId = id;
              _selectedSectionId = null;
              _selectedSectionName = null;
            }),
            onSectionSelected: (id, name) => setState(() {
              _selectedSectionId = id;
              _selectedSectionName = name;
            }),
          ),
          Expanded(
            child: _selectedSectionId == null
                ? _EmptyPicker(
                    message: _selectedClassId == null
                        ? 'Select a class to get started.'
                        : 'Select a section to view the timetable.',
                  )
                : _TimetableGrid(
                    sectionId: _selectedSectionId!,
                    sectionName: _selectedSectionName ?? '',
                    days: _days,
                  ),
          ),
        ],
      ),
    );
  }

  void _reload() => setState(() {});
}

// ---------------------------------------------------------------------------
// Section picker
// ---------------------------------------------------------------------------

class _SectionPicker extends ConsumerWidget {
  const _SectionPicker({
    required this.selectedClassId,
    required this.selectedSectionId,
    required this.onClassSelected,
    required this.onSectionSelected,
  });

  final String? selectedClassId;
  final String? selectedSectionId;
  final ValueChanged<String> onClassSelected;
  final void Function(String id, String name) onSectionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return Container(
      color: AppColors.secondaryGroupedBackground,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          // Class dropdown
          classesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'Error loading classes: $e',
              style: const TextStyle(color: AppColors.error),
            ),
            data: (classes) => _Dropdown<SchoolClass>(
              label: 'Class',
              value: selectedClassId == null
                  ? null
                  : classes.where((c) => c.id == selectedClassId).firstOrNull,
              items: classes,
              itemLabel: (c) => c.name,
              onChanged: (c) => onClassSelected(c.id),
            ),
          ),
          if (selectedClassId != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _SectionDropdown(
              classId: selectedClassId!,
              selectedSectionId: selectedSectionId,
              onSectionSelected: onSectionSelected,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionDropdown extends ConsumerWidget {
  const _SectionDropdown({
    required this.classId,
    required this.selectedSectionId,
    required this.onSectionSelected,
  });

  final String classId;
  final String? selectedSectionId;
  final void Function(String id, String name) onSectionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsByClassProvider(classId));

    return sectionsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'Error loading sections: $e',
        style: const TextStyle(color: AppColors.error),
      ),
      data: (sections) => _Dropdown<Section>(
        label: 'Section',
        value: selectedSectionId == null
            ? null
            : sections.where((s) => s.id == selectedSectionId).firstOrNull,
        items: sections,
        itemLabel: (s) => '${s.className ?? ''} – ${s.name}',
        onChanged: (s) =>
            onSectionSelected(s.id, '${s.className ?? ''} – ${s.name}'),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.systemBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: BorderSide(color: AppColors.opaqueSeparator),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: BorderSide(color: AppColors.opaqueSeparator),
        ),
      ),
      hint: Text('Select $label'),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Timetable grid
// ---------------------------------------------------------------------------

class _TimetableGrid extends ConsumerWidget {
  const _TimetableGrid({
    required this.sectionId,
    required this.sectionName,
    required this.days,
  });

  final String sectionId;
  final String sectionName;
  final List<(int, String)> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(timetableSlotsProvider);
    final yearAsync = ref.watch(currentAcademicYearProvider);

    return slotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load timetable slots: $e',
        onRetry: () => ref.invalidate(timetableSlotsProvider),
      ),
      data: (slots) {
        if (slots.isEmpty) {
          return const _EmptyPicker(
            message:
                'No timetable slots configured.\nAsk your admin to create periods first.',
          );
        }
        return yearAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: 'Could not load academic year: $e',
            onRetry: () => ref.invalidate(currentAcademicYearProvider),
          ),
          data: (year) => _GridBody(
            sectionId: sectionId,
            sectionName: sectionName,
            slots: slots,
            days: days,
            academicYearId: year?.id,
          ),
        );
      },
    );
  }
}

class _GridBody extends ConsumerWidget {
  const _GridBody({
    required this.sectionId,
    required this.sectionName,
    required this.slots,
    required this.days,
    required this.academicYearId,
  });

  final String sectionId;
  final String sectionName;
  final List<TimetableSlot> slots;
  final List<(int, String)> days;
  final String? academicYearId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = WeeklyTimetableFilter(
      sectionId: sectionId,
      academicYearId: academicYearId,
    );
    final weeklyAsync = ref.watch(weeklyTimetableProvider(filter));

    return weeklyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load timetable: $e',
        onRetry: () => ref.invalidate(weeklyTimetableProvider(filter)),
      ),
      data: (weekly) {
        // Build a lookup: dayOfWeek → slotId → TimetableEntry
        final lookup = <int, Map<String, TimetableEntry>>{};
        for (final day in weekly.days) {
          final slotMap = <String, TimetableEntry>{};
          for (final entry in day.entries) {
            slotMap[entry.slotId] = entry;
          }
          lookup[day.dayOfWeek] = slotMap;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  sectionName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.label,
                      ),
                ),
              ),
              // Scrollable grid
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildTable(context, ref, lookup, weekly),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable(
    BuildContext context,
    WidgetRef ref,
    Map<int, Map<String, TimetableEntry>> lookup,
    WeeklyTimetable weekly,
  ) {
    const slotColWidth = 90.0;
    const dayColWidth = 120.0;

    return Table(
      border: TableBorder.all(
        color: AppColors.opaqueSeparator,
        width: 0.5,
        borderRadius: AppRadius.card,
      ),
      columnWidths: {
        0: const FixedColumnWidth(slotColWidth),
        for (int i = 0; i < days.length; i++)
          i + 1: const FixedColumnWidth(dayColWidth),
      },
      children: [
        // Header row
        TableRow(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.sm),
            ),
          ),
          children: [
            _headerCell('Period'),
            for (final (_, label) in days) _headerCell(label),
          ],
        ),
        // Data rows — one per slot
        for (final slot in slots)
          TableRow(
            decoration: BoxDecoration(
              color: slot.slotType == 'break'
                  ? AppColors.grey100
                  : AppColors.systemBackground,
            ),
            children: [
              // Slot label
              Padding(
                padding: AppSpacing.cellPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.name,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.label,
                          ),
                    ),
                    Text(
                      '${slot.startTime.substring(0, 5)}–${slot.endTime.substring(0, 5)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.secondaryLabel,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
              // One cell per day
              for (final (dayNum, _) in days)
                _buildCell(context, ref, lookup, slot, dayNum, weekly),
            ],
          ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: AppSpacing.cellPadding,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    WidgetRef ref,
    Map<int, Map<String, TimetableEntry>> lookup,
    TimetableSlot slot,
    int dayNum,
    WeeklyTimetable weekly,
  ) {
    final entry = lookup[dayNum]?[slot.id];
    final hasAssignment =
        entry != null && entry.subjectId != null;

    if (slot.slotType == 'break') {
      return const Padding(
        padding: AppSpacing.cellPadding,
        child: Center(
          child: Text(
            '—',
            style: TextStyle(color: AppColors.tertiaryLabel),
          ),
        ),
      );
    }

    if (hasAssignment) {
      return _FilledCell(
        entry: entry,
        onTap: () => _showEditSheet(context, ref, slot, dayNum, entry, weekly),
      );
    }

    return _EmptyCell(
      onTap: () => _showAssignSheet(context, ref, slot, dayNum, weekly),
    );
  }

  void _showAssignSheet(
    BuildContext context,
    WidgetRef ref,
    TimetableSlot slot,
    int dayNum,
    WeeklyTimetable weekly,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignPeriodSheet(
        sectionId: sectionId,
        slot: slot,
        dayOfWeek: dayNum,
        academicYearId: academicYearId ?? '',
        onSaved: () => ref.invalidate(weeklyTimetableProvider(
          WeeklyTimetableFilter(
            sectionId: sectionId,
            academicYearId: academicYearId,
          ),
        )),
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    TimetableSlot slot,
    int dayNum,
    TimetableEntry entry,
    WeeklyTimetable weekly,
  ) {
    // DB id is not in TimetableEntry (only slotId is); _EditPeriodSheet
    // re-fetches the actual row id via getTimetables internally.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPeriodSheet(
        sectionId: sectionId,
        slot: slot,
        dayOfWeek: dayNum,
        entry: entry,
        academicYearId: academicYearId ?? '',
        onSaved: () => ref.invalidate(weeklyTimetableProvider(
          WeeklyTimetableFilter(
            sectionId: sectionId,
            academicYearId: academicYearId,
          ),
        )),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cell widgets
// ---------------------------------------------------------------------------

class _FilledCell extends StatelessWidget {
  const _FilledCell({required this.entry, required this.onTap});

  final TimetableEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cellPadding,
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.subjectName ?? '—',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (entry.teacherName != null)
              Text(
                entry.teacherName!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.secondaryLabel,
                      fontSize: 10,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (entry.roomNumber != null)
              Text(
                entry.roomNumber!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.tertiaryLabel,
                      fontSize: 10,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cellPadding,
        color: Colors.transparent,
        child: Center(
          child: Text(
            '+ Add',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.tint.withValues(alpha: 0.45),
                ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assign Period bottom sheet
// ---------------------------------------------------------------------------

class _AssignPeriodSheet extends ConsumerStatefulWidget {
  const _AssignPeriodSheet({
    required this.sectionId,
    required this.slot,
    required this.dayOfWeek,
    required this.academicYearId,
    required this.onSaved,
  });

  final String sectionId;
  final TimetableSlot slot;
  final int dayOfWeek;
  final String academicYearId;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AssignPeriodSheet> createState() => _AssignPeriodSheetState();
}

class _AssignPeriodSheetState extends ConsumerState<_AssignPeriodSheet> {
  Subject? _subject;
  Map<String, dynamic>? _teacher;
  final _roomCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final teachersAsync = ref.watch(teachersListProvider);

    return _SheetScaffold(
      title:
          'Assign ${widget.slot.name} — ${_dayName(widget.dayOfWeek)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subject picker
          subjectsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(WarmCopy.loadFailed('subjects'),
                style: const TextStyle(color: AppColors.error)),
            data: (subjects) => _Dropdown<Subject>(
              label: 'Subject',
              value: _subject,
              items: subjects,
              itemLabel: (s) =>
                  s.code != null ? '${s.name} (${s.code})' : s.name,
              onChanged: (s) => setState(() => _subject = s),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Teacher picker
          teachersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(WarmCopy.loadFailed('teachers'),
                style: const TextStyle(color: AppColors.error)),
            data: (teachers) => DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: _teacher,
              decoration: const InputDecoration(
                labelText: 'Teacher (optional)',
                filled: true,
                fillColor: AppColors.systemBackground,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.button,
                  borderSide: BorderSide(color: AppColors.opaqueSeparator),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.button,
                  borderSide: BorderSide(color: AppColors.opaqueSeparator),
                ),
              ),
              hint: const Text('Select teacher'),
              items: [
                const DropdownMenuItem<Map<String, dynamic>>(
                  value: null,
                  child: Text('— None —'),
                ),
                ...teachers.map(
                  (t) => DropdownMenuItem<Map<String, dynamic>>(
                    value: t,
                    child: Text(t['full_name'] as String? ?? t['id'] as String),
                  ),
                ),
              ],
              onChanged: (t) => setState(() => _teacher = t),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Room
          TextField(
            controller: _roomCtrl,
            decoration: const InputDecoration(
              labelText: 'Room number (optional)',
              filled: true,
              fillColor: AppColors.systemBackground,
              border: OutlineInputBorder(borderRadius: AppRadius.button),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.button,
                borderSide: BorderSide(color: AppColors.opaqueSeparator),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
            onPressed: _saving || _subject == null ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_subject == null) return;

    // Conflict check if teacher is set
    if (_teacher != null) {
      final repo = ref.read(timetableRepositoryProvider);
      final conflicts = await detectTeacherConflicts(
        repository: repo,
        teacherId: _teacher!['id'] as String,
        dayOfWeek: widget.dayOfWeek,
        slotId: widget.slot.id,
        academicYearId: widget.academicYearId,
      );
      if (conflicts.isNotEmpty && mounted) {
        final teacherName =
            _teacher!['full_name'] as String? ?? 'This teacher';
        final confirm = await _showConflictDialog(teacherName, conflicts);
        if (confirm != true) return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notifier = ref.read(timetableNotifierProvider.notifier);
      await notifier.createEntry({
        'section_id': widget.sectionId,
        'slot_id': widget.slot.id,
        'day_of_week': widget.dayOfWeek,
        'subject_id': _subject!.id,
        if (_teacher != null) 'teacher_id': _teacher!['id'],
        if (_roomCtrl.text.trim().isNotEmpty)
          'room_number': _roomCtrl.text.trim(),
        'academic_year_id': widget.academicYearId,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<bool?> _showConflictDialog(
      String teacherName, List<Timetable> conflicts) {
    final sections = conflicts
        .map((c) => c.sectionName ?? c.sectionId)
        .toSet()
        .join(', ');
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teacher conflict'),
        content: Text(
          '$teacherName is already assigned to $sections '
          'during this period. Assign anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.warning,
              backgroundColor: AppColors.warningLight,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Assign anyway'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit / Delete bottom sheet
// ---------------------------------------------------------------------------

class _EditPeriodSheet extends ConsumerStatefulWidget {
  const _EditPeriodSheet({
    required this.sectionId,
    required this.slot,
    required this.dayOfWeek,
    required this.entry,
    required this.academicYearId,
    required this.onSaved,
  });

  final String sectionId;
  final TimetableSlot slot;
  final int dayOfWeek;
  final TimetableEntry entry;
  final String academicYearId;
  final VoidCallback onSaved;

  @override
  ConsumerState<_EditPeriodSheet> createState() => _EditPeriodSheetState();
}

class _EditPeriodSheetState extends ConsumerState<_EditPeriodSheet> {
  late Subject? _subject;
  Map<String, dynamic>? _teacher;
  late final TextEditingController _roomCtrl;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  // DB id of the timetable row (needed for update/delete)
  String? _timetableId;
  bool _loadingId = true;

  @override
  void initState() {
    super.initState();
    _roomCtrl = TextEditingController(text: widget.entry.roomNumber ?? '');
    _fetchTimetableId();
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  /// Fetches the actual DB row id for this slot+day+section combination.
  Future<void> _fetchTimetableId() async {
    try {
      final repo = ref.read(timetableRepositoryProvider);
      final rows = await repo.getTimetables(
        sectionId: widget.sectionId,
        academicYearId: widget.academicYearId,
        dayOfWeek: widget.dayOfWeek,
      );
      final match = rows.where((r) => r.slotId == widget.slot.id).firstOrNull;
      if (mounted) {
        setState(() {
          _timetableId = match?.id;
          _loadingId = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingId = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final teachersAsync = ref.watch(teachersListProvider);

    return _SheetScaffold(
      title:
          'Edit ${widget.slot.name} — ${_dayName(widget.dayOfWeek)}',
      child: _loadingId
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subject
                subjectsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(WarmCopy.loadFailed('subjects'),
                      style: const TextStyle(color: AppColors.error)),
                  data: (subjects) {
                    _subject ??= subjects
                        .where((s) => s.id == widget.entry.subjectId)
                        .firstOrNull;
                    return _Dropdown<Subject>(
                      label: 'Subject',
                      value: _subject,
                      items: subjects,
                      itemLabel: (s) => s.code != null
                          ? '${s.name} (${s.code})'
                          : s.name,
                      onChanged: (s) => setState(() => _subject = s),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Teacher
                teachersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(WarmCopy.loadFailed('teachers'),
                      style: const TextStyle(color: AppColors.error)),
                  data: (teachers) {
                    _teacher ??= teachers
                        .where((t) => t['id'] == widget.entry.teacherId)
                        .firstOrNull;
                    return DropdownButtonFormField<Map<String, dynamic>>(
                      initialValue: _teacher,
                      decoration: const InputDecoration(
                        labelText: 'Teacher (optional)',
                        filled: true,
                        fillColor: AppColors.systemBackground,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.button,
                          borderSide:
                              BorderSide(color: AppColors.opaqueSeparator),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.button,
                          borderSide:
                              BorderSide(color: AppColors.opaqueSeparator),
                        ),
                      ),
                      hint: const Text('Select teacher'),
                      items: [
                        const DropdownMenuItem<Map<String, dynamic>>(
                          value: null,
                          child: Text('— None —'),
                        ),
                        ...teachers.map(
                          (t) => DropdownMenuItem<Map<String, dynamic>>(
                            value: t,
                            child: Text(t['full_name'] as String? ??
                                t['id'] as String),
                          ),
                        ),
                      ],
                      onChanged: (t) => setState(() => _teacher = t),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Room
                TextField(
                  controller: _roomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Room number (optional)',
                    filled: true,
                    fillColor: AppColors.systemBackground,
                    border: OutlineInputBorder(borderRadius: AppRadius.button),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.button,
                      borderSide: BorderSide(color: AppColors.opaqueSeparator),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    // Delete
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.button),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                        ),
                        icon: _deleting
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.error,
                                ),
                              )
                            : const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                        onPressed:
                            (_saving || _deleting || _timetableId == null)
                                ? null
                                : _delete,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Save
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.button),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                        ),
                        onPressed: (_saving ||
                                _deleting ||
                                _timetableId == null ||
                                _subject == null)
                            ? null
                            : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    if (_subject == null || _timetableId == null) return;

    // Conflict check
    if (_teacher != null) {
      final repo = ref.read(timetableRepositoryProvider);
      final conflicts = await detectTeacherConflicts(
        repository: repo,
        teacherId: _teacher!['id'] as String,
        dayOfWeek: widget.dayOfWeek,
        slotId: widget.slot.id,
        academicYearId: widget.academicYearId,
        excludeTimetableId: _timetableId,
      );
      if (conflicts.isNotEmpty && mounted) {
        final teacherName =
            _teacher!['full_name'] as String? ?? 'This teacher';
        final sections = conflicts
            .map((c) => c.sectionName ?? c.sectionId)
            .toSet()
            .join(', ');
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Teacher conflict'),
            content: Text(
              '$teacherName is already assigned to $sections '
              'during this period. Save anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  backgroundColor: AppColors.warningLight,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save anyway'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notifier = ref.read(timetableNotifierProvider.notifier);
      await notifier.updateEntry(_timetableId!, {
        'subject_id': _subject!.id,
        'teacher_id': _teacher?['id'],
        'room_number': _roomCtrl.text.trim().isEmpty
            ? null
            : _roomCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _delete() async {
    if (_timetableId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove period?'),
        content: const Text(
          'This will clear the subject and teacher from this slot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.error,
              backgroundColor: AppColors.errorLight,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      final notifier = ref.read(timetableNotifierProvider.notifier);
      await notifier.deleteEntry(_timetableId!);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = e.toString();
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Shared sheet scaffold
// ---------------------------------------------------------------------------

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: GlassCard(
        borderRadius: AppRadius.lg,
        margin: EdgeInsets.zero,
        padding: AppSpacing.sheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.opaqueSeparator,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.label,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Misc helpers
// ---------------------------------------------------------------------------

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pageHV,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryLabel,
              ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pageHV,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _dayName(int dayOfWeek) {
  const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  if (dayOfWeek < 1 || dayOfWeek > 7) return 'Day $dayOfWeek';
  return names[dayOfWeek];
}
