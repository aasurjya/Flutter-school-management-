import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/report_card_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genState = ref.watch(rcGenerationProvider);
    final templatesAsync = ref.watch(rcTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report Cards'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select the academic year, term, class, section, and exams to generate report cards for all students in the section.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form
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

                  // Academic Year & Term
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedAcademicYear,
                          decoration: const InputDecoration(
                            labelText: 'Academic Year *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: '2024-25', child: Text('2024-25')),
                            DropdownMenuItem(
                                value: '2023-24', child: Text('2023-24')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedAcademicYear = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedTerm,
                          decoration: const InputDecoration(
                            labelText: 'Term *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'term1', child: Text('Term 1')),
                            DropdownMenuItem(
                                value: 'term2', child: Text('Term 2')),
                            DropdownMenuItem(
                                value: 'term3', child: Text('Final Term')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedTerm = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Class & Section
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedClass,
                          decoration: const InputDecoration(
                            labelText: 'Class *',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                              value: 'class${i + 1}',
                              child: Text('Class ${i + 1}'),
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _selectedClass = v;
                              _selectedSection = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSection,
                          decoration: const InputDecoration(
                            labelText: 'Section *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'secA', child: Text('Section A')),
                            DropdownMenuItem(
                                value: 'secB', child: Text('Section B')),
                            DropdownMenuItem(
                                value: 'secC', child: Text('Section C')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedSection = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Template
                  templatesAsync.when(
                    data: (templates) => DropdownButtonFormField<String>(
                      initialValue: _selectedTemplate,
                      decoration: const InputDecoration(
                        labelText: 'Report Template *',
                        border: OutlineInputBorder(),
                      ),
                      items: templates
                          .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                    '${t.name}${t.isDefault ? " (Default)" : ""}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedTemplate = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading templates: $e'),
                  ),
                  const SizedBox(height: 24),

                  // Exam Selection
                  Text(
                    'Select Exams to Include',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose which exam results to aggregate in the report card',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 12),
                  // Mock exam checkboxes
                  ..._mockExams.map((exam) => CheckboxListTile(
                        value: _selectedExams.contains(exam['id']),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedExams.add(exam['id']!);
                            } else {
                              _selectedExams.remove(exam['id']);
                            }
                          });
                        },
                        title: Text(exam['name']!),
                        subtitle: Text(exam['type']!),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )),
                  const SizedBox(height: 24),

                  // Generate Button
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
                      'Generating... ${genState.progress}/${genState.total}',
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
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _canGenerate ? _generate : null,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate Report Cards'),
                      ),
                    ),

                  if (genState.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(genState.error!,
                                  style: const TextStyle(
                                      color: AppColors.error, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Results
            if (genState.generatedReports.isNotEmpty) ...[
              const SizedBox(height: 24),
              GlassCard(
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
                              onPressed: () =>
                                  context.push('/report-cards/list'),
                              icon: const Icon(Icons.list, size: 18),
                              label: const Text('View All'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () {
                                ref
                                    .read(rcGenerationProvider.notifier)
                                    .publishAll();
                              },
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
                          const Icon(Icons.check_circle,
                              color: AppColors.success),
                          const SizedBox(width: 12),
                          Text(
                            '${genState.generatedReports.length} report cards generated successfully',
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
                              backgroundColor: AppColors.primary
                                  .withValues(alpha: 0.1),
                              child: Text(
                                (r.studentName ?? 'S')[0].toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(r.studentDisplayName),
                            subtitle: Text(r.classSection),
                            trailing: _StatusBadge(r.status),
                            onTap: () =>
                                context.push('/report-cards/detail/${r.id}'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    if (genState.generatedReports.length > 5)
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              context.push('/report-cards/list'),
                          child: Text(
                              'View all ${genState.generatedReports.length} reports'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _canGenerate =>
      _selectedAcademicYear != null &&
      _selectedTerm != null &&
      _selectedSection != null &&
      _selectedTemplate != null;

  void _generate() {
    ref.read(rcGenerationProvider.notifier).generateBulk(
          sectionId: _selectedSection!,
          academicYearId: _selectedAcademicYear!,
          termId: _selectedTerm!,
          templateId: _selectedTemplate!,
          examIds: _selectedExams.toList(),
        );
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

final _mockExams = [
  {'id': 'exam1', 'name': 'Unit Test 1', 'type': 'Unit Test'},
  {'id': 'exam2', 'name': 'Unit Test 2', 'type': 'Unit Test'},
  {'id': 'exam3', 'name': 'Mid Term Exam', 'type': 'Mid Term'},
  {'id': 'exam4', 'name': 'Final Term Exam', 'type': 'Final'},
];
