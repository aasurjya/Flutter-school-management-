import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/substitution.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/substitution_provider.dart';

class ReportAbsenceScreen extends ConsumerStatefulWidget {
  const ReportAbsenceScreen({super.key});

  @override
  ConsumerState<ReportAbsenceScreen> createState() =>
      _ReportAbsenceScreenState();
}

class _ReportAbsenceScreenState
    extends ConsumerState<ReportAbsenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  AbsenceLeaveType _leaveType = AbsenceLeaveType.sick;
  bool _submitting = false;
  bool _pastAbsencesExpanded = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Report Absence')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.8),
                    Colors.deepOrange.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_off_outlined,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Your Absence',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The system will automatically find substitute teachers for your classes.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date picker
            const _SectionLabel('Absence Date'),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DateChip(
                          label: 'Today',
                          date: DateTime.now(),
                          selected: _isSameDay(
                              _selectedDate, DateTime.now()),
                          onTap: () => setState(
                              () => _selectedDate = DateTime.now()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DateChip(
                          label: 'Tomorrow',
                          date: DateTime.now()
                              .add(const Duration(days: 1)),
                          selected: _isSameDay(
                              _selectedDate,
                              DateTime.now()
                                  .add(const Duration(days: 1))),
                          onTap: () => setState(() => _selectedDate =
                              DateTime.now()
                                  .add(const Duration(days: 1))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today,
                              size: 14),
                          label: const Text('Pick',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      DateFormat('EEEE, d MMMM yyyy')
                          .format(_selectedDate),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Leave type
            const _SectionLabel('Leave Type'),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AbsenceLeaveType.values.map((type) {
                  final selected = _leaveType == type;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: selected,
                    selectedColor:
                        AppColors.warning.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.warning
                          : Colors.grey[600],
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (_) =>
                        setState(() => _leaveType = type),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Reason
            const _SectionLabel('Reason'),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Brief reason (optional)',
                  hintText: 'e.g. Fever, family emergency...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _submitting ? null : () => _submit(currentUser?.id),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _submitting ? 'Reporting...' : 'Report Absence',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // My Past Absences — collapsible section
            if (currentUser?.id != null) ...[
              _PastAbsencesSection(
                teacherId: currentUser!.id,
                expanded: _pastAbsencesExpanded,
                onToggle: () => setState(
                    () => _pastAbsencesExpanded = !_pastAbsencesExpanded),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit(String? teacherId) async {
    if (teacherId == null) return;

    // Check for existing absence on selected date
    final existingAbsences = ref.read(myAbsencesProvider(teacherId));
    final existingForDate = existingAbsences.valueOrNull?.where((a) =>
        a.absenceDate.year == _selectedDate.year &&
        a.absenceDate.month == _selectedDate.month &&
        a.absenceDate.day == _selectedDate.day);

    if (existingForDate != null && existingForDate.isNotEmpty) {
      final existing = existingForDate.first;
      if (!mounted) return;
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Absence Already Reported'),
          content: Text(
            'You already have a ${existing.leaveType.label} absence reported '
            'for ${DateFormat("d MMM yyyy").format(_selectedDate)} '
            '(Status: ${existing.status.label}). '
            'Do you want to update it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update'),
            ),
          ],
        ),
      );
      if (overwrite != true) return;
    }

    setState(() => _submitting = true);

    try {
      final repo = ref.read(substitutionRepositoryProvider);
      await repo.reportAbsence(
        teacherId: teacherId,
        date: _selectedDate,
        leaveType: _leaveType,
        reason: _reasonCtrl.text.isEmpty ? null : _reasonCtrl.text,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      );

      ref.invalidate(myAbsencesProvider(teacherId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Absence reported for ${DateFormat("d MMM yyyy").format(_selectedDate)}. '
              'Admin will assign substitute teachers.',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report absence: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _submitting = false);
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ============================================================
// Past Absences collapsible section
// ============================================================

class _PastAbsencesSection extends ConsumerWidget {
  final String teacherId;
  final bool expanded;
  final VoidCallback onToggle;

  const _PastAbsencesSection({
    required this.teacherId,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absencesAsync = ref.watch(myAbsencesProvider(teacherId));

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.history, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'My Past Absences',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  absencesAsync.when(
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${list.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            absencesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load absences: $e',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(myAbsencesProvider(teacherId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (absences) {
                if (absences.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AppColors.success, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'No absences reported yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final recent = absences.take(5).toList();
                return Column(
                  children: recent.map((absence) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            absence.status.icon,
                            color: absence.status.color,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEE, d MMM yyyy')
                                      .format(absence.absenceDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  absence.leaveType.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: absence.status.color
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              absence.status.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: absence.status.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.primary,
        ),
      );
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              DateFormat('d MMM').format(date),
              style: TextStyle(
                color: selected
                    ? Colors.white70
                    : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
