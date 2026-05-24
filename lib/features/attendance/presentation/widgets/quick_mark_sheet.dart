import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/apple_sheet.dart';
import '../../../../core/widgets/undo_banner.dart';
import '../../providers/quick_mark_provider.dart';

/// Apple-style "mark today's class present" sheet.
///
/// The dashboard's primary CTA opens this. Every student is present by
/// default; tapping a row toggles them to absent. The footer button
/// re-labels live ("Save 28 present" → "Save 25 present, 3 absent") so
/// the teacher always sees what they're about to save.
///
/// Tap-budget contract: from cold open to saved is 3 taps in the happy
/// path (dashboard CTA → sheet save → optional dismiss).
Future<void> showQuickMarkSheet(BuildContext context) {
  return showAppleSheet<void>(
    context,
    builder: (_) => const _QuickMarkSheetBody(),
  );
}

class _QuickMarkSheetBody extends ConsumerStatefulWidget {
  const _QuickMarkSheetBody();

  @override
  ConsumerState<_QuickMarkSheetBody> createState() => _QuickMarkSheetBodyState();
}

class _QuickMarkSheetBodyState extends ConsumerState<_QuickMarkSheetBody> {
  final Set<String> _absentIds = <String>{};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final asyncTarget = ref.watch(quickMarkTargetProvider);

    return asyncTarget.when(
      loading: () => const _SheetLoading(),
      error: (_, __) => _SheetMessage(
        title: WarmCopy.loadFailed('today\'s class'),
        body: 'Open Mark Attendance to pick a class by hand.',
      ),
      data: (target) {
        if (target == null) {
          return const _SheetMessage(
            title: 'No class right now.',
            body: 'Open Mark Attendance from the menu to pick a class.',
          );
        }
        return _SheetBody(
          target: target,
          absentIds: _absentIds,
          isSaving: _isSaving,
          theme: theme,
          brightness: brightness,
          onToggle: (id) => setState(() {
            if (!_absentIds.add(id)) _absentIds.remove(id);
          }),
          onSave: () => _save(target),
        );
      },
    );
  }

  Future<void> _save(NextClassTarget target) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final snapshot = Set<String>.from(_absentIds);
    try {
      final savedOnline = await persistQuickMark(
        ref,
        target: target,
        absentStudentIds: snapshot,
      );
      if (!mounted) return;

      final presentCount = target.roster.length - snapshot.length;
      Navigator.of(context).pop();

      UndoBanner.show(
        context,
        message: savedOnline
            ? '${target.sectionLabel.split(' · ').first} marked: $presentCount present'
                '${snapshot.isEmpty ? '' : ', ${snapshot.length} absent'}.'
            : WarmCopy.savedOffline('Attendance'),
        onUndo: () {
          // Re-open the sheet so the teacher can change marks.
          showQuickMarkSheet(context);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(WarmCopy.saveFailed('attendance'))),
      );
    }
  }
}

class _SheetLoading extends StatelessWidget {
  const _SheetLoading();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.labelFor(theme.brightness, tier: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.target,
    required this.absentIds,
    required this.isSaving,
    required this.theme,
    required this.brightness,
    required this.onToggle,
    required this.onSave,
  });

  final NextClassTarget target;
  final Set<String> absentIds;
  final bool isSaving;
  final ThemeData theme;
  final Brightness brightness;
  final ValueChanged<String> onToggle;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final presentCount = target.roster.length - absentIds.length;
    final subtitle = absentIds.isEmpty
        ? '${target.roster.length} students · all marked present'
        : '$presentCount present, ${absentIds.length} absent';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(target.sectionLabel, style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.labelFor(brightness, tier: 2),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tap a name to mark absent.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.labelFor(brightness, tier: 3),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RosterList(
          roster: target.roster,
          absentIds: absentIds,
          onToggle: onToggle,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.label,
              foregroundColor: AppColors.labelDark,
            ),
            child: Text(
              isSaving
                  ? WarmCopy.savingShort
                  : absentIds.isEmpty
                      ? 'Save ${target.roster.length} present'
                      : 'Save $presentCount present, ${absentIds.length} absent',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RosterList extends StatelessWidget {
  const _RosterList({
    required this.roster,
    required this.absentIds,
    required this.onToggle,
  });

  final List<RosterStudent> roster;
  final Set<String> absentIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cellBg = AppColors.groupedCellFor(brightness);
    final separator = AppColors.separatorFor(brightness);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: cellBg,
        child: Column(
          children: [
            for (var i = 0; i < roster.length; i++) ...[
              _RosterRow(
                student: roster[i],
                isAbsent: absentIds.contains(roster[i].studentId),
                onTap: () => onToggle(roster[i].studentId),
              ),
              if (i < roster.length - 1)
                Divider(height: 0.5, thickness: 0.5, color: separator, indent: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.student,
    required this.isAbsent,
    required this.onTap,
  });

  final RosterStudent student;
  final bool isAbsent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Semantics(
      button: true,
      toggled: isAbsent,
      label: '${student.name}, ${isAbsent ? "marked absent" : "marked present"}, '
          'double-tap to toggle',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  student.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.labelFor(brightness, tier: 1),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isAbsent ? 'Absent' : 'Present',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isAbsent
                      ? AppColors.error
                      : AppColors.labelFor(brightness, tier: 2),
                  fontWeight: isAbsent ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
