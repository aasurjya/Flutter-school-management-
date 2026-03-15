import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/academic.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../academic/providers/academic_provider.dart';

class AcademicConfigScreen extends ConsumerStatefulWidget {
  const AcademicConfigScreen({super.key});

  @override
  ConsumerState<AcademicConfigScreen> createState() => _AcademicConfigScreenState();
}

class _AcademicConfigScreenState extends ConsumerState<AcademicConfigScreen> {
  int _selectedIndex = 0;

  final List<_ConfigItem> _configItems = [
    _ConfigItem(title: 'Academic Years', icon: Icons.calendar_today,  description: 'Manage academic years and sessions'),
    _ConfigItem(title: 'Terms',          icon: Icons.date_range,       description: 'Configure terms and semesters'),
    _ConfigItem(title: 'Classes',        icon: Icons.class_,           description: 'Manage class levels'),
    _ConfigItem(title: 'Sections',       icon: Icons.grid_view,        description: 'Configure sections per class'),
    _ConfigItem(title: 'Subjects',       icon: Icons.book,             description: 'Manage subjects curriculum'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Configuration'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isWide
          ? Row(
              children: [
                Container(
                  width: 220,
                  color: Colors.grey[100],
                  child: _buildSidebar(),
                ),
                Expanded(child: _buildContent()),
              ],
            )
          : Column(
              children: [
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: _configItems.length,
                    itemBuilder: (context, index) {
                      final item = _configItems[index];
                      final isSelected = _selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(item.title),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedIndex = index),
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }

  Widget _buildSidebar() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _configItems.length,
      itemBuilder: (context, index) {
        final item = _configItems[index];
        final isSelected = _selectedIndex == index;
        return ListTile(
          leading: Icon(item.icon, color: isSelected ? AppColors.primary : Colors.grey[600]),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.grey[800],
            ),
          ),
          selected: isSelected,
          selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: () => setState(() => _selectedIndex = index),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return const _AcademicYearsConfig();
      case 1: return const _TermsConfig();
      case 2: return const _ClassesConfig();
      case 3: return const _SectionsConfig();
      case 4: return const _SubjectsConfig();
      default: return const Center(child: Text('Select a configuration'));
    }
  }
}

class _ConfigItem {
  final String title;
  final IconData icon;
  final String description;
  _ConfigItem({required this.title, required this.icon, required this.description});
}

// ─── Academic Years ────────────────────────────────────────────────────────────

class _AcademicYearsConfig extends ConsumerWidget {
  const _AcademicYearsConfig();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(academicYearsProvider);

    return yearsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: 'Failed to load academic years: $e',
        onRetry: () => ref.invalidate(academicYearsProvider),
      ),
      data: (years) => _ConfigListScaffold(
        title: 'Academic Years',
        description: 'Manage academic years and set the current active year.',
        isEmpty: years.isEmpty,
        emptyLabel: 'academic years',
        onAdd: () => _showAddYearDialog(context, ref),
        child: ListView.separated(
          itemCount: years.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final year = years[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: year.isCurrent
                      ? AppColors.success.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_today,
                    color: year.isCurrent ? AppColors.success : Colors.grey),
              ),
              title: Text(year.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                '${DateFormat('MMM d, yyyy').format(year.startDate)} to ${DateFormat('MMM d, yyyy').format(year.endDate)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (year.isCurrent)
                    _Badge(label: 'CURRENT', color: AppColors.success)
                  else
                    TextButton(
                      onPressed: () => _setCurrentYear(context, ref, year.id),
                      child: const Text('Set as Current'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () => _deleteYear(context, ref, year),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _setCurrentYear(BuildContext context, WidgetRef ref, String yearId) async {
    try {
      await ref.read(academicRepositoryProvider).setCurrentAcademicYear(yearId);
      ref.invalidate(academicYearsProvider);
      ref.invalidate(currentAcademicYearProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Academic year set as current'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteYear(BuildContext context, WidgetRef ref, AcademicYear year) async {
    final confirmed = await _confirmDelete(context, 'academic year "${year.name}"');
    if (!confirmed) return;

    try {
      await ref.read(academicRepositoryProvider).deleteAcademicYear(year.id);
      ref.invalidate(academicYearsProvider);
      ref.invalidate(currentAcademicYearProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddYearDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    bool isCurrent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Academic Year'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormField(controller: nameCtrl, label: 'Name (e.g. 2025-2026)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Start Date',
                      value: startDate,
                      onPicked: (d) => setDialogState(() => startDate = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'End Date',
                      value: endDate,
                      onPicked: (d) => setDialogState(() => endDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: isCurrent,
                onChanged: (v) => setDialogState(() => isCurrent = v ?? false),
                title: const Text('Set as current year'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref.read(academicRepositoryProvider).createAcademicYear(
                    name: nameCtrl.text.trim(),
                    startDate: startDate!,
                    endDate: endDate!,
                    isCurrent: isCurrent,
                  );
                  ref.invalidate(academicYearsProvider);
                  ref.invalidate(currentAcademicYearProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${nameCtrl.text.trim()} created'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Terms ─────────────────────────────────────────────────────────────────────

class _TermsConfig extends ConsumerWidget {
  const _TermsConfig();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(academicYearsProvider);

    return yearsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: 'Failed to load: $e',
        onRetry: () => ref.invalidate(academicYearsProvider),
      ),
      data: (years) {
        if (years.isEmpty) {
          return const Center(
            child: Text('Create an academic year first, then add terms to it.'),
          );
        }
        final currentYear = years.firstWhere(
          (y) => y.isCurrent,
          orElse: () => years.first,
        );
        return _TermsForYear(academicYear: currentYear, allYears: years);
      },
    );
  }
}

class _TermsForYear extends ConsumerWidget {
  final AcademicYear academicYear;
  final List<AcademicYear> allYears;

  const _TermsForYear({required this.academicYear, required this.allYears});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(termsProvider(academicYear.id));

    return termsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: 'Failed to load terms: $e',
        onRetry: () => ref.invalidate(termsProvider(academicYear.id)),
      ),
      data: (terms) => _ConfigListScaffold(
        title: 'Terms — ${academicYear.name}',
        description: 'Configure terms/semesters for the academic year.',
        isEmpty: terms.isEmpty,
        emptyLabel: 'terms',
        onAdd: () => _showAddTermDialog(context, ref),
        child: ListView.separated(
          itemCount: terms.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final term = terms[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.info.withValues(alpha: 0.1),
                child: Text('${term.sequenceOrder}',
                    style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.bold)),
              ),
              title: Text(term.name),
              subtitle: Text(
                '${DateFormat('MMM d').format(term.startDate)} to ${DateFormat('MMM d, yyyy').format(term.endDate)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                onPressed: () => _deleteTerm(context, ref, term),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteTerm(BuildContext context, WidgetRef ref, Term term) async {
    final confirmed = await _confirmDelete(context, 'term "${term.name}"');
    if (!confirmed) return;

    try {
      await ref.read(academicRepositoryProvider).deleteTerm(term.id);
      ref.invalidate(termsProvider(academicYear.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddTermDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final orderCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Term'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormField(controller: nameCtrl, label: 'Name (e.g. Term 1)'),
              const SizedBox(height: 12),
              _FormField(
                controller: orderCtrl,
                label: 'Order (1, 2, 3...)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Start Date',
                      value: startDate,
                      onPicked: (d) => setDialogState(() => startDate = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'End Date',
                      value: endDate,
                      onPicked: (d) => setDialogState(() => endDate = d),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    orderCtrl.text.trim().isEmpty ||
                    startDate == null ||
                    endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref.read(academicRepositoryProvider).createTerm(
                    academicYearId: academicYear.id,
                    name: nameCtrl.text.trim(),
                    startDate: startDate!,
                    endDate: endDate!,
                    sequenceOrder: int.tryParse(orderCtrl.text.trim()) ?? 1,
                  );
                  ref.invalidate(termsProvider(academicYear.id));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${nameCtrl.text.trim()} created'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Classes ──────────────────────────────────────────────────────────────────

class _ClassesConfig extends ConsumerWidget {
  const _ClassesConfig();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return classesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: 'Failed to load classes: $e',
        onRetry: () => ref.invalidate(classesProvider),
      ),
      data: (classes) => _ConfigListScaffold(
        title: 'Classes',
        description: 'Manage class levels in your school.',
        isEmpty: classes.isEmpty,
        emptyLabel: 'classes',
        onAdd: () => _showClassDialog(context, ref),
        child: ListView.separated(
          itemCount: classes.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final cls = classes[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  '${cls.sequenceOrder}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(cls.name),
              subtitle: Text('Order: ${cls.sequenceOrder}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showClassDialog(context, ref, existing: cls),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () => _deleteClass(context, ref, cls),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteClass(BuildContext context, WidgetRef ref, SchoolClass cls) async {
    final confirmed = await _confirmDelete(context, 'class "${cls.name}"');
    if (!confirmed) return;

    try {
      await ref.read(academicRepositoryProvider).deleteClass(cls.id);
      ref.invalidate(classesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${cls.name} deleted'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showClassDialog(BuildContext context, WidgetRef ref, {SchoolClass? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final orderCtrl = TextEditingController(text: existing?.sequenceOrder.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Class' : 'Add Class'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormField(
                controller: nameCtrl,
                label: 'Class Name',
                hint: 'e.g. Class 10, Grade 10',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: orderCtrl,
                label: 'Display Order',
                hint: 'e.g. 10',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) return 'Must be a number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final name = nameCtrl.text.trim();
              final order = int.parse(orderCtrl.text.trim());
              Navigator.pop(ctx);

              try {
                if (isEdit) {
                  await ref.read(academicRepositoryProvider).updateClass(
                    existing.id,
                    name: name,
                    sequenceOrder: order,
                  );
                } else {
                  await ref.read(academicRepositoryProvider).createClass(
                    name: name,
                    sequenceOrder: order,
                    numericName: order,
                  );
                }
                ref.invalidate(classesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? '$name updated' : '$name created'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }
}

// ─── Sections ─────────────────────────────────────────────────────────────────

class _SectionsConfig extends ConsumerWidget {
  const _SectionsConfig();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(allSectionsProvider);
    final classesAsync = ref.watch(classesProvider);
    final currentYearAsync = ref.watch(currentAcademicYearProvider);

    final isLoading = sectionsAsync.isLoading || classesAsync.isLoading || currentYearAsync.isLoading;
    final error = sectionsAsync.error ?? classesAsync.error ?? currentYearAsync.error;

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return _ErrorRetry(
        message: 'Failed to load: $error',
        onRetry: () {
          ref.invalidate(allSectionsProvider);
          ref.invalidate(classesProvider);
          ref.invalidate(currentAcademicYearProvider);
        },
      );
    }

    final sections = sectionsAsync.valueOrNull ?? [];
    final classes = classesAsync.valueOrNull ?? [];
    final currentYear = currentYearAsync.valueOrNull;

    if (classes.isEmpty) {
      return const Center(child: Text('Create classes first, then add sections.'));
    }

    if (currentYear == null) {
      return const Center(child: Text('Create an academic year first, then add sections.'));
    }

    return _ConfigListScaffold(
      title: 'Sections',
      description: 'Configure sections for each class.',
      isEmpty: sections.isEmpty,
      emptyLabel: 'sections',
      onAdd: () => _showSectionDialog(context, ref, classes, currentYear),
      child: ListView.separated(
        itemCount: sections.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final section = sections[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
              child: Text(
                section.name,
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text('${section.className ?? 'Unknown'} - ${section.name}'),
            subtitle: Text('Capacity: ${section.capacity}${section.roomNumber != null ? ' • Room: ${section.roomNumber}' : ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditSectionDialog(context, ref, section),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _deleteSection(context, ref, section),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteSection(BuildContext context, WidgetRef ref, Section section) async {
    final confirmed = await _confirmDelete(context, 'section "${section.className} - ${section.name}"');
    if (!confirmed) return;

    try {
      await ref.read(academicRepositoryProvider).deleteSection(section.id);
      ref.invalidate(allSectionsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showEditSectionDialog(BuildContext context, WidgetRef ref, Section section) {
    final nameCtrl = TextEditingController(text: section.name);
    final capacityCtrl = TextEditingController(text: '${section.capacity}');
    final roomCtrl = TextEditingController(text: section.roomNumber ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Section'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormField(
                controller: nameCtrl,
                label: 'Section Name',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: capacityCtrl,
                label: 'Capacity',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _FormField(controller: roomCtrl, label: 'Room No. (optional)'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await ref.read(academicRepositoryProvider).updateSection(
                  section.id,
                  name: nameCtrl.text.trim(),
                  capacity: int.tryParse(capacityCtrl.text.trim()),
                  roomNumber: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
                );
                ref.invalidate(allSectionsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSectionDialog(
    BuildContext context,
    WidgetRef ref,
    List<SchoolClass> classes,
    AcademicYear currentYear,
  ) {
    final nameCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '40');
    final roomCtrl = TextEditingController();
    String? selectedClassId = classes.isNotEmpty ? classes.first.id : null;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Section'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Class', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedClassId,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: classes
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedClassId = v),
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: nameCtrl,
                  label: 'Section Name',
                  hint: 'e.g. A, B, C',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        controller: capacityCtrl,
                        label: 'Capacity',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormField(controller: roomCtrl, label: 'Room No. (optional)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (!formKey.currentState!.validate() || selectedClassId == null) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(academicRepositoryProvider).createSection(
                    classId: selectedClassId!,
                    academicYearId: currentYear.id,
                    name: nameCtrl.text.trim(),
                    capacity: int.tryParse(capacityCtrl.text.trim()) ?? 40,
                    roomNumber: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
                  );
                  ref.invalidate(allSectionsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Section ${nameCtrl.text.trim()} created'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subjects ─────────────────────────────────────────────────────────────────

class _SubjectsConfig extends ConsumerWidget {
  const _SubjectsConfig();

  // Map DB enum values to display labels
  static const _typeLabels = {
    'mandatory': 'Core',
    'elective': 'Elective',
    'extra_curricular': 'Extra',
  };

  static const _typeDbValues = {
    'Core': 'mandatory',
    'Elective': 'elective',
    'Extra': 'extra_curricular',
  };

  Color _typeColor(String dbType) {
    switch (dbType) {
      case 'mandatory': return AppColors.primary;
      case 'elective': return AppColors.secondary;
      case 'extra_curricular': return AppColors.accent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return subjectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: 'Failed to load subjects: $e',
        onRetry: () => ref.invalidate(subjectsProvider),
      ),
      data: (subjects) => _ConfigListScaffold(
        title: 'Subjects',
        description: 'Manage subjects in the curriculum.',
        isEmpty: subjects.isEmpty,
        emptyLabel: 'subjects',
        onAdd: () => _showSubjectDialog(context, ref),
        child: ListView.separated(
          itemCount: subjects.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final subject = subjects[index];
            final typeLabel = _typeLabels[subject.subjectType] ?? subject.subjectType;
            final color = _typeColor(subject.subjectType);
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subject.code ?? '??',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              title: Text(subject.name),
              subtitle: Text(typeLabel),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Badge(label: typeLabel, color: color),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showSubjectDialog(context, ref, existing: subject),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () => _deleteSubject(context, ref, subject),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteSubject(BuildContext context, WidgetRef ref, Subject subject) async {
    final confirmed = await _confirmDelete(context, 'subject "${subject.name}"');
    if (!confirmed) return;

    try {
      await ref.read(academicRepositoryProvider).deleteSubject(subject.id);
      ref.invalidate(subjectsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showSubjectDialog(BuildContext context, WidgetRef ref, {Subject? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    String selectedType = _typeLabels[existing?.subjectType] ?? 'Core';
    final formKey = GlobalKey<FormState>();
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Subject' : 'Add Subject'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormField(
                  controller: nameCtrl,
                  label: 'Subject Name',
                  hint: 'e.g. Mathematics',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: codeCtrl,
                  label: 'Subject Code',
                  hint: 'e.g. MATH',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                const Text('Type', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ['Core', 'Elective', 'Extra']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final name = nameCtrl.text.trim();
                final code = codeCtrl.text.trim().toUpperCase();
                final dbType = _typeDbValues[selectedType] ?? 'mandatory';
                Navigator.pop(ctx);

                try {
                  if (isEdit) {
                    await ref.read(academicRepositoryProvider).updateSubject(
                      existing.id,
                      name: name,
                      code: code,
                      subjectType: dbType,
                    );
                  } else {
                    await ref.read(academicRepositoryProvider).createSubject(
                      name: name,
                      code: code,
                      subjectType: dbType,
                    );
                  }
                  ref.invalidate(subjectsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? '$name updated' : '$name created'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

Future<bool> _confirmDelete(BuildContext context, String itemName) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text('Delete $itemName? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  ) ?? false;
}

class _ConfigListScaffold extends StatelessWidget {
  final String title;
  final String description;
  final bool isEmpty;
  final String emptyLabel;
  final VoidCallback onAdd;
  final Widget child;

  const _ConfigListScaffold({
    required this.title,
    required this.description,
    required this.isEmpty,
    required this.emptyLabel,
    required this.onAdd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text('Add ${title.split(' — ').first}'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: isEmpty
                  ? Center(
                      child: Text(
                        'No $emptyLabel yet. Add one to get started.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Text(
          value != null ? DateFormat('MMM d, yyyy').format(value!) : 'Select',
          style: value == null ? TextStyle(color: Theme.of(context).hintColor) : null,
        ),
      ),
    );
  }
}
