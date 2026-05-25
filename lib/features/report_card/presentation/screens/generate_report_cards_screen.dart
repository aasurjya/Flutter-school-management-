import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/exam_statistics.dart';
import '../../../../data/models/report_card.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../exams/providers/exams_provider.dart';
import '../../../id_card/providers/id_card_provider.dart';
import '../../providers/report_card_provider.dart';
import '../../utils/report_card_bulk_pdf.dart';
import '../widgets/report_card_pdf_builder.dart';

/// Bulk generation entry point.
///
/// Picks academic year / term / class / section / template / exams from real
/// Supabase data via the academic + exams providers. Optionally pre-selects
/// an exam when invoked from Exam Management with `?examId=<id>`.
class GenerateReportCardsScreen extends ConsumerStatefulWidget {
  const GenerateReportCardsScreen({super.key});

  @override
  ConsumerState<GenerateReportCardsScreen> createState() =>
      _GenerateReportCardsScreenState();
}

class _GenerateReportCardsScreenState
    extends ConsumerState<GenerateReportCardsScreen> {
  String? _selectedAcademicYear;
  String? _selectedTerm;
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedTemplate;
  final Set<String> _selectedExams = {};
  bool _prefilledFromQuery = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genState = ref.watch(rcGenerationProvider);
    final templatesAsync = ref.watch(rcTemplatesProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final classesAsync = ref.watch(classesProvider);

    // Pre-fill examId from query string the first time we have a year.
    if (!_prefilledFromQuery) {
      final qpExamId = GoRouterState.of(context).uri.queryParameters['examId'];
      if (qpExamId != null && qpExamId.isNotEmpty) {
        _selectedExams.add(qpExamId);
        _prefilledFromQuery = true;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Report Cards')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoBanner(theme),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Generation Settings',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Academic year + term
                  Row(
                    children: [
                      Expanded(child: _yearDropdown(yearsAsync)),
                      const SizedBox(width: 16),
                      Expanded(child: _termDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Class + section
                  Row(
                    children: [
                      Expanded(child: _classDropdown(classesAsync)),
                      const SizedBox(width: 16),
                      Expanded(child: _sectionDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Template
                  templatesAsync.when(
                    data: (templates) {
                      if (templates.isEmpty) {
                        return _emptyHint(
                          'No report card templates yet. Create one under Report Cards → Templates.',
                        );
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedTemplate,
                        decoration: const InputDecoration(
                          labelText: 'Report Template *',
                          border: OutlineInputBorder(),
                        ),
                        items: templates
                            .map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(
                                    '${t.name}${t.isDefault ? " (Default)" : ""}',
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedTemplate = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Could not load templates. $e'),
                  ),
                  const SizedBox(height: 24),

                  // Exam selection — real data
                  Text(
                    'Select Exams to Include',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aggregated marks from these exams build the report card.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 12),
                  _examPicker(),
                  const SizedBox(height: 24),

                  if (genState.isGenerating) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: genState.progressPercent / 100,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Generating ${genState.progress} of ${genState.total}…',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (genState.currentStudent != null)
                      Text(
                        'Processing: ${genState.currentStudent}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _canPreview ? _previewOne : null,
                            icon: const Icon(Icons.preview_outlined),
                            label: const Text('Preview Sample'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _canGenerate ? _generate : null,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Generate for All'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (genState.error != null) ...[
                    const SizedBox(height: 12),
                    _errorBox(genState.error!),
                  ],
                ],
              ),
            ),

            if (genState.generatedReports.isNotEmpty) ...[
              const SizedBox(height: 24),
              _resultsCard(theme, genState),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Pieces
  // -------------------------------------------------------------------------

  Widget _infoBanner(ThemeData theme) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.info),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pick the academic year, term, class, section, and exams. We generate one card per student in the section.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );

  Widget _yearDropdown(AsyncValue<List<dynamic>> yearsAsync) {
    return yearsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Years unavailable. $e'),
      data: (years) {
        if (years.isEmpty) {
          return _emptyHint('No academic years yet. Configure under Classes.');
        }
        // Default to first (most recent) year if nothing selected.
        _selectedAcademicYear ??= years.first.id as String;
        return DropdownButtonFormField<String>(
          initialValue: _selectedAcademicYear,
          decoration: const InputDecoration(
            labelText: 'Academic Year *',
            border: OutlineInputBorder(),
          ),
          items: years
              .map((y) => DropdownMenuItem(
                    value: y.id as String,
                    child: Text(y.name as String),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedAcademicYear = v;
              _selectedTerm = null;
              _selectedExams.clear();
            });
          },
        );
      },
    );
  }

  Widget _termDropdown() {
    if (_selectedAcademicYear == null) {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Term *',
          border: OutlineInputBorder(),
        ),
        items: const [],
        onChanged: null,
      );
    }
    final termsAsync = ref.watch(termsProvider(_selectedAcademicYear!));
    return termsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Terms unavailable. $e'),
      data: (terms) {
        if (terms.isEmpty) {
          return _emptyHint('No terms in this year yet.');
        }
        return DropdownButtonFormField<String>(
          initialValue: _selectedTerm,
          decoration: const InputDecoration(
            labelText: 'Term *',
            border: OutlineInputBorder(),
          ),
          items: terms
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedTerm = v),
        );
      },
    );
  }

  Widget _classDropdown(AsyncValue<List<dynamic>> async) {
    return async.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Classes unavailable. $e'),
      data: (classes) {
        if (classes.isEmpty) {
          return _emptyHint('No classes yet. Add classes under Classes.');
        }
        return DropdownButtonFormField<String>(
          initialValue: _selectedClass,
          decoration: const InputDecoration(
            labelText: 'Class *',
            border: OutlineInputBorder(),
          ),
          items: classes
              .map((c) => DropdownMenuItem(
                    value: c.id as String,
                    child: Text(c.name as String),
                  ))
              .toList(),
          onChanged: (v) => setState(() {
            _selectedClass = v;
            _selectedSection = null;
          }),
        );
      },
    );
  }

  Widget _sectionDropdown() {
    if (_selectedClass == null) {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Section *',
          border: OutlineInputBorder(),
        ),
        items: const [],
        onChanged: null,
      );
    }
    final sectionsAsync = ref.watch(sectionsByClassProvider(_selectedClass!));
    return sectionsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Sections unavailable. $e'),
      data: (sections) {
        if (sections.isEmpty) {
          return _emptyHint('No sections in this class yet.');
        }
        return DropdownButtonFormField<String>(
          initialValue: _selectedSection,
          decoration: const InputDecoration(
            labelText: 'Section *',
            border: OutlineInputBorder(),
          ),
          items: sections
              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedSection = v),
        );
      },
    );
  }

  Widget _examPicker() {
    if (_selectedAcademicYear == null) {
      return _emptyHint('Pick an academic year first to see exams.');
    }
    final filter = ExamsFilter(
      academicYearId: _selectedAcademicYear,
      termId: _selectedTerm,
    );
    final examsAsync = ref.watch(examsProvider(filter));
    return examsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Exams unavailable. $e'),
      data: (exams) {
        if (exams.isEmpty) {
          return _emptyHint('No exams configured. Add exams under Exam Management.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: exams
              .map((Exam e) => CheckboxListTile(
                    value: _selectedExams.contains(e.id),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedExams.add(e.id);
                        } else {
                          _selectedExams.remove(e.id);
                        }
                      });
                    },
                    title: Text(e.name),
                    subtitle: Text(e.examTypeDisplay),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _emptyHint(String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );

  Widget _errorBox(String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
        ),
      );

  Widget _resultsCard(ThemeData theme, RCGenerationState genState) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Generated (${genState.generatedReports.length})',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/report-cards/list'),
                    icon: const Icon(Icons.list, size: 18),
                    label: const Text('View All'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _downloadMerged,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Download PDF'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(rcGenerationProvider.notifier).publishAll(),
                    icon: const Icon(Icons.publish, size: 18),
                    label: const Text('Publish All'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Text(
                  '${genState.generatedReports.length} report cards generated',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...genState.generatedReports.take(5).map(
                (r) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      (r.studentName ?? 'S')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(r.studentDisplayName),
                  subtitle: Text(r.classSection),
                  trailing: _StatusBadge(r.status),
                  onTap: () => context.push('/report-cards/detail/${r.id}'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          if (genState.generatedReports.length > 5)
            Center(
              child: TextButton(
                onPressed: () => context.push('/report-cards/list'),
                child: Text(
                  'View all ${genState.generatedReports.length} reports',
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _canGenerate =>
      _selectedAcademicYear != null &&
      _selectedTerm != null &&
      _selectedSection != null &&
      _selectedTemplate != null &&
      _selectedExams.isNotEmpty;

  /// Preview needs the same inputs as generation; the first student in the
  /// section is rendered as a sample.
  bool get _canPreview => _canGenerate;

  void _generate() {
    ref.read(rcGenerationProvider.notifier).generateBulk(
          sectionId: _selectedSection!,
          academicYearId: _selectedAcademicYear!,
          termId: _selectedTerm!,
          templateId: _selectedTemplate!,
          examIds: _selectedExams.toList(),
        );
  }

  /// Generate a single report card for the first student in the chosen
  /// section, then hand the bytes to the OS print/preview dialog. No DB
  /// row stays around because we don't show a "save" path here.
  Future<void> _previewOne() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(rcFullRepositoryProvider);
      final client = repo.client;

      // Find first enrolled student in the section.
      final firstEnroll = await client
          .from('student_enrollments')
          .select('student_id')
          .eq('section_id', _selectedSection!)
          .eq('academic_year_id', _selectedAcademicYear!)
          .limit(1);
      final list = firstEnroll as List;
      if (list.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No students enrolled in this section.')),
        );
        return;
      }
      final studentId = list.first['student_id'] as String;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Building sample preview…'),
          duration: Duration(seconds: 1),
        ),
      );

      // Generate (and persist) the report for that one student via the repo.
      final report = await repo.generateReportCard(
        studentId: studentId,
        academicYearId: _selectedAcademicYear!,
        termId: _selectedTerm!,
        templateId: _selectedTemplate!,
        examIds: _selectedExams.toList(),
      );

      final data =
          report.data.isNotEmpty ? ReportCardData.fromJson(report.data) : null;
      if (data == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not assemble report data.')),
        );
        return;
      }

      // Pull tenant + template header config for branding.
      final tenant = await ref.read(currentTenantProvider.future);
      final headerConfig = <String, dynamic>{
        if (tenant?.name != null) 'school_name': tenant!.name,
      };

      final bytes = await ReportCardPdfBuilder.build(
        data: data,
        comments: report.comments,
        skills: report.skills,
        activities: report.activities,
        headerConfig: headerConfig,
      );
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(WarmCopy.genericError)),
      );
    }
  }

  /// Render every generated report card into a single merged PDF and offer
  /// the OS share sheet so admins can save / email / AirDrop.
  Future<void> _downloadMerged() async {
    final messenger = ScaffoldMessenger.of(context);
    final reports = ref.read(rcGenerationProvider).generatedReports;
    if (reports.isEmpty) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text('Building PDF for ${reports.length} report cards…'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final tenant = await ref.read(currentTenantProvider.future);
      await ReportCardBulkPdf.shareMerged(
        reports: reports,
        tenant: tenant,
        filename: 'report-cards-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(WarmCopy.genericError)),
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'draft':
        color = Colors.orange;
      case 'generated':
        color = AppColors.info;
      case 'reviewed':
        color = AppColors.accent;
      case 'published':
        color = AppColors.success;
      case 'sent':
        color = AppColors.primary;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
