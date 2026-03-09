import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../data/models/gradebook.dart';
import '../../../../data/repositories/timetable_repository.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../timetable/providers/timetable_provider.dart';
import '../../providers/gradebook_provider.dart';

/// Main teacher gradebook screen with three tabs:
///  1. By Student — class roster with weighted grades per category
///  2. By Assignment — expandable category sections with assignment averages
///  3. Summary — class average, grade distribution, students needing attention
class GradebookScreen extends ConsumerStatefulWidget {
  const GradebookScreen({super.key});

  @override
  ConsumerState<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends ConsumerState<GradebookScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Selected class-subject combination (teacher chooses at top).
  TeacherClassInfo? _selectedClass;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(supabaseProvider).auth.currentUser?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    final classesAsync = ref.watch(teacherClassesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedClass != null
              ? 'Gradebook — ${_selectedClass!.subjectName ?? "No Subject"}'
              : 'Gradebook',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'By Student'),
            Tab(text: 'By Assignment'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(error: e.toString()),
        data: (classes) => Column(
          children: [
            _ClassSelector(
              classes: classes,
              selected: _selectedClass,
              onSelected: (c) => setState(() => _selectedClass = c),
            ),
            Expanded(
              child: _selectedClass == null
                  ? const _EmptySelector()
                  : _GradebookTabs(
                      tabController: _tabController,
                      selectedClass: _selectedClass!,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedClass != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push(
                '/teacher/grade-entry',
                extra: _selectedClass,
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Grade'),
            )
          : null,
    );
  }
}

// ─── Class Selector ────────────────────────────────────────────────────────────

class _ClassSelector extends StatelessWidget {
  final List<TeacherClassInfo> classes;
  final TeacherClassInfo? selected;
  final ValueChanged<TeacherClassInfo?> onSelected;

  const _ClassSelector({
    required this.classes,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: AppColors.surfaceElevated,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: DropdownButtonFormField<TeacherClassInfo>(
        initialValue: selected,
        hint: const Text('Select Class & Subject'),
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: AppColors.background,
        ),
        items: classes.map((c) {
          return DropdownMenuItem(
            value: c,
            child: Text(
              '${c.className} ${c.sectionName} — ${c.subjectName ?? "No Subject"}',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onSelected,
      ),
    );
  }
}

// ─── Tab host ──────────────────────────────────────────────────────────────────

class _GradebookTabs extends ConsumerWidget {
  final TabController tabController;
  final TeacherClassInfo selectedClass;

  const _GradebookTabs({
    required this.tabController,
    required this.selectedClass,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use sectionId as proxy for classSubjectId until class_subjects are
    // wired into the timetable query. Teachers can still manage grades
    // scoped to sectionId + subject combination.
    final classSubjectId = selectedClass.sectionId;

    return TabBarView(
      controller: tabController,
      children: [
        _ByStudentTab(
          classSubjectId: classSubjectId,
          selectedClass: selectedClass,
        ),
        _ByAssignmentTab(classSubjectId: classSubjectId),
        _SummaryTab(
          classSubjectId: classSubjectId,
          selectedClass: selectedClass,
        ),
      ],
    );
  }
}

// ─── By Student Tab ──────────────────────────────────────────────────────────

class _ByStudentTab extends ConsumerWidget {
  final String classSubjectId;
  final TeacherClassInfo selectedClass;

  const _ByStudentTab({
    required this.classSubjectId,
    required this.selectedClass,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync =
        ref.watch(gradingCategoriesProvider(classSubjectId));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (categories) {
        if (categories.isEmpty) {
          return _NoCategoriesPlaceholder(
            classSubjectId: classSubjectId,
            selectedClass: selectedClass,
          );
        }
        return _StudentGradeTable(
          classSubjectId: classSubjectId,
          categories: categories,
          selectedClass: selectedClass,
        );
      },
    );
  }
}

class _NoCategoriesPlaceholder extends ConsumerWidget {
  final String classSubjectId;
  final TeacherClassInfo selectedClass;

  const _NoCategoriesPlaceholder({
    required this.classSubjectId,
    required this.selectedClass,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No grading categories yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create categories like Homework, Quiz, and Exams to start tracking grades.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddCategoryDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
      BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AddCategoryDialog(
        classSubjectId: classSubjectId,
        tenantId: ref.read(supabaseProvider).auth.currentUser?.appMetadata['tenant_id'] as String? ?? '',
        onSaved: () => ref.invalidate(gradingCategoriesProvider(classSubjectId)),
      ),
    );
  }
}

class _StudentGradeTable extends ConsumerWidget {
  final String classSubjectId;
  final List<GradingCategory> categories;
  final TeacherClassInfo selectedClass;

  const _StudentGradeTable({
    required this.classSubjectId,
    required this.categories,
    required this.selectedClass,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load students for this section
    final userId = ref.watch(supabaseProvider).auth.currentUser?.id ?? '';
    final classesAsync = ref.watch(teacherClassesProvider(userId));

    return classesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (_) {
        // Fetch students directly via Supabase
        return _StudentGradeLoader(
          classSubjectId: classSubjectId,
          categories: categories,
          sectionId: selectedClass.sectionId,
        );
      },
    );
  }
}

class _StudentGradeLoader extends ConsumerWidget {
  final String classSubjectId;
  final List<GradingCategory> categories;
  final String sectionId;

  const _StudentGradeLoader({
    required this.classSubjectId,
    required this.categories,
    required this.sectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync =
        ref.watch(_sectionStudentsProvider(sectionId));

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (students) {
        if (students.isEmpty) {
          return const Center(child: Text('No students enrolled'));
        }
        final params = ClassGradesParams(
          classSubjectId: classSubjectId,
          students: students,
        );
        final gradesAsync = ref.watch(classGradesProvider(params));

        return gradesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(error: e.toString()),
          data: (grades) => _buildTable(context, grades, categories),
        );
      },
    );
  }

  Widget _buildTable(
    BuildContext context,
    List<StudentGrade> grades,
    List<GradingCategory> cats,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(context, cats),
          const SizedBox(height: 4),
          ...grades.map((g) => _buildStudentRow(context, g, cats)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<GradingCategory> cats) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'Student',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          ...cats.map((c) => Expanded(
                flex: 2,
                child: Text(
                  '${c.name}\n(${c.weight.toStringAsFixed(0)}%)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 10),
                ),
              )),
          const Expanded(
            flex: 2,
            child: Text(
              'Avg',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'Grade',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(
    BuildContext context,
    StudentGrade grade,
    List<GradingCategory> cats,
  ) {
    final gradeColor = _gradeColor(grade.letterGrade);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              grade.studentName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...cats.map((c) {
            final pct = grade.categoryPercentages[c.id] ?? 0;
            return Expanded(
              flex: 2,
              child: Text(
                '${pct.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: _percentageColor(pct),
                ),
              ),
            );
          }),
          Expanded(
            flex: 2,
            child: Text(
              '${grade.weightedAverage.toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: gradeColor,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: gradeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                grade.letterGrade,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: gradeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(String letter) {
    switch (letter) {
      case 'A':
        return AppColors.gradeA;
      case 'B':
        return AppColors.gradeB;
      case 'C':
        return AppColors.gradeC;
      case 'D':
        return AppColors.gradeD;
      default:
        return AppColors.gradeF;
    }
  }

  Color _percentageColor(double pct) {
    if (pct >= 90) return AppColors.gradeA;
    if (pct >= 80) return AppColors.gradeB;
    if (pct >= 70) return AppColors.gradeC;
    if (pct >= 60) return AppColors.gradeD;
    return AppColors.gradeF;
  }
}

// ─── By Assignment Tab ──────────────────────────────────────────────────────

class _ByAssignmentTab extends ConsumerWidget {
  final String classSubjectId;

  const _ByAssignmentTab({required this.classSubjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync =
        ref.watch(gradingCategoriesProvider(classSubjectId));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(
            child: Text('No categories yet. Add a grade entry to begin.'),
          );
        }
        return _AssignmentList(
          classSubjectId: classSubjectId,
          categories: categories,
        );
      },
    );
  }
}

class _AssignmentList extends ConsumerWidget {
  final String classSubjectId;
  final List<GradingCategory> categories;

  const _AssignmentList({
    required this.classSubjectId,
    required this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategorySection(
          category: category,
          classSubjectId: classSubjectId,
        );
      },
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final GradingCategory category;
  final String classSubjectId;

  const _CategorySection({
    required this.category,
    required this.classSubjectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(
      gradeEntriesProvider(GradeEntriesParams(categoryId: category.id)),
    );

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.name,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${category.weight.toStringAsFixed(0)}% weight',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          entriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
            data: (entries) {
              final summaries = _buildSummaries(entries, category);
              if (summaries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No assignments yet',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }
              return Column(
                children: summaries
                    .map((s) => _AssignmentRow(summary: s))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<AssignmentSummary> _buildSummaries(
    List<GradeEntry> entries,
    GradingCategory category,
  ) {
    // Group by title + graded_at
    final Map<String, List<GradeEntry>> grouped = {};
    for (final entry in entries) {
      final key = '${entry.title}__${entry.gradedAt.toIso8601String().split('T')[0]}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return grouped.entries.map((e) {
      final group = e.value;
      final graded = group.where((g) => g.pointsEarned != null).toList();
      final scores = graded.map((g) => g.pointsEarned!).toList();
      final avg = scores.isEmpty
          ? 0.0
          : scores.reduce((a, b) => a + b) / scores.length;
      final highest = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a > b ? a : b);
      final lowest = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a < b ? a : b);

      return AssignmentSummary(
        title: group.first.title,
        categoryId: category.id,
        categoryName: category.name,
        gradedAt: group.first.gradedAt,
        pointsPossible: group.first.pointsPossible,
        averageScore: avg,
        highestScore: highest,
        lowestScore: lowest,
        gradedCount: graded.length,
        totalStudents: group.length,
      );
    }).toList()
      ..sort((a, b) => b.gradedAt.compareTo(a.gradedAt));
  }
}

class _AssignmentRow extends StatelessWidget {
  final AssignmentSummary summary;

  const _AssignmentRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final avgPct = summary.averagePercentage;
    final color = _pctColor(avgPct);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _formatDate(summary.gradedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(
                  label: 'Avg',
                  value:
                      '${avgPct.toStringAsFixed(1)}%',
                  color: color,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'High',
                  value:
                      '${summary.highestScore.toStringAsFixed(1)}/${summary.pointsPossible.toStringAsFixed(0)}',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Low',
                  value:
                      '${summary.lowestScore.toStringAsFixed(1)}/${summary.pointsPossible.toStringAsFixed(0)}',
                  color: AppColors.gradeF,
                ),
                const Spacer(),
                Text(
                  '${summary.gradedCount}/${summary.totalStudents} graded',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _pctColor(double pct) {
    if (pct >= 90) return AppColors.gradeA;
    if (pct >= 80) return AppColors.gradeB;
    if (pct >= 70) return AppColors.gradeC;
    if (pct >= 60) return AppColors.gradeD;
    return AppColors.gradeF;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Tab ────────────────────────────────────────────────────────────

class _SummaryTab extends ConsumerWidget {
  final String classSubjectId;
  final TeacherClassInfo selectedClass;

  const _SummaryTab({
    required this.classSubjectId,
    required this.selectedClass,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync =
        ref.watch(_sectionStudentsProvider(selectedClass.sectionId));
    final categoriesAsync =
        ref.watch(gradingCategoriesProvider(classSubjectId));

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (students) {
        if (students.isEmpty) {
          return const Center(child: Text('No students enrolled'));
        }
        return categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(error: e.toString()),
          data: (categories) {
            if (categories.isEmpty) {
              return const Center(
                child: Text('No grading categories yet'),
              );
            }
            final params = ClassGradesParams(
              classSubjectId: classSubjectId,
              students: students,
            );
            final gradesAsync = ref.watch(classGradesProvider(params));

            return gradesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(error: e.toString()),
              data: (grades) =>
                  _SummaryContent(grades: grades, categories: categories),
            );
          },
        );
      },
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final List<StudentGrade> grades;
  final List<GradingCategory> categories;

  const _SummaryContent({
    required this.grades,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) return const Center(child: Text('No data'));

    final classAvg =
        grades.fold(0.0, (sum, g) => sum + g.weightedAverage) /
            grades.length;

    final distribution = _computeDistribution(grades);
    final atRisk =
        grades.where((g) => g.weightedAverage < 60).toList()
          ..sort((a, b) => a.weightedAverage.compareTo(b.weightedAverage));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class average hero card
          GradientGlassCard(
            gradient: AppColors.primaryGradient,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '${classAvg.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Class Average',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${grades.length} students · ${categories.length} categories',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Grade distribution
          const Text(
            'Grade Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: distribution.entries
                  .map((e) => _DistributionBar(
                        label: e.key,
                        count: e.value,
                        total: grades.length,
                        color: AppColors.gradeColor(e.key),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Students needing attention
          if (atRisk.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Needs Attention (${atRisk.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: atRisk
                    .map((g) => _AtRiskStudentTile(grade: g))
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Map<String, int> _computeDistribution(List<StudentGrade> grades) {
    final counts = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};
    for (final g in grades) {
      final letter = g.letterGrade;
      counts[letter] = (counts[letter] ?? 0) + 1;
    }
    return counts;
  }
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DistributionBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    final pct = (fraction * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 16,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              '$count ($pct%)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _AtRiskStudentTile extends StatelessWidget {
  final StudentGrade grade;

  const _AtRiskStudentTile({required this.grade});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.errorLight,
        child: Text(
          grade.letterGrade,
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(grade.studentName),
      subtitle: grade.admissionNumber != null
          ? Text('ADM: ${grade.admissionNumber}')
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${grade.weightedAverage.toStringAsFixed(1)}%',
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── Shared providers ────────────────────────────────────────────────────────

/// Loads students for a section from Supabase directly.
final _sectionStudentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, sectionId) async {
    final client = ref.watch(supabaseProvider);
    final response = await client
        .from('student_enrollments')
        .select('students(id, full_name, admission_number)')
        .eq('section_id', sectionId)
        .eq('is_active', true);

    return (response as List).map((row) {
      final s = row['students'] as Map<String, dynamic>;
      return {
        'id': s['id'] as String,
        'full_name': s['full_name'] as String? ?? 'Unknown',
        'admission_number': s['admission_number'] as String?,
      };
    }).toList();
  },
);

// ─── Add Category Dialog ─────────────────────────────────────────────────────

class _AddCategoryDialog extends ConsumerStatefulWidget {
  final String classSubjectId;
  final String tenantId;
  final VoidCallback onSaved;

  const _AddCategoryDialog({
    required this.classSubjectId,
    required this.tenantId,
    required this.onSaved,
  });

  @override
  ConsumerState<_AddCategoryDialog> createState() =>
      _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<_AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController(text: '100');
  final _dropController = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Grading Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Homework, Quiz, Midterm...',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (%)',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dropController,
              decoration: const InputDecoration(
                labelText: 'Drop Lowest (# of scores)',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Enter 0 or more';
                return null;
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
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(gradebookRepositoryProvider);
      final category = GradingCategory(
        id: '',
        tenantId: widget.tenantId,
        classSubjectId: widget.classSubjectId,
        name: _nameController.text.trim(),
        weight: double.parse(_weightController.text),
        dropLowest: int.parse(_dropController.text),
        createdAt: DateTime.now(),
      );
      await repo.addCategory(category);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

class _EmptySelector extends StatelessWidget {
  const _EmptySelector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Select a class above to view the gradebook'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
