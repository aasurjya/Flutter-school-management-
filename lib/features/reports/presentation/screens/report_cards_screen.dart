import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/report_card.dart';
import '../../providers/report_card_provider.dart';

class ReportCardsScreen extends ConsumerStatefulWidget {
  const ReportCardsScreen({super.key});

  @override
  ConsumerState<ReportCardsScreen> createState() => _ReportCardsScreenState();
}

class _ReportCardsScreenState extends ConsumerState<ReportCardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showTemplateSettings(context),
            tooltip: 'Templates',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Reports'),
            Tab(text: 'Generate'),
            Tab(text: 'Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AllReportsTab(),
          _GenerateTab(),
          _TemplatesTab(),
        ],
      ),
    );
  }

  void _showTemplateSettings(BuildContext context) {
    _tabController.animateTo(2);
  }
}

class _AllReportsTab extends ConsumerWidget {
  const _AllReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(
      reportCardsProvider(const ReportCardFilter()),
    );

    return Column(
      children: [
        _FilterBar(),
        Expanded(
          child: reportsAsync.when(
            data: (reports) {
              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text('No report cards generated yet'),
                      const SizedBox(height: 8),
                      const Text(
                        'Generate report cards for a class to see them here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) =>
                    _ReportCardListItem(report: reports[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Academic Year',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Years')),
                DropdownMenuItem(value: '2024-25', child: Text('2024-25')),
                DropdownMenuItem(value: '2023-24', child: Text('2023-24')),
              ],
              onChanged: (value) {
                ref.read(selectedAcademicYearProvider.notifier).state = value;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Term',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Terms')),
                DropdownMenuItem(value: 'term1', child: Text('Term 1')),
                DropdownMenuItem(value: 'term2', child: Text('Term 2')),
                DropdownMenuItem(value: 'term3', child: Text('Term 3')),
              ],
              onChanged: (value) {
                ref.read(selectedTermProvider.notifier).state = value;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Status')),
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'generated', child: Text('Generated')),
                DropdownMenuItem(value: 'published', child: Text('Published')),
              ],
              onChanged: (value) {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCardListItem extends StatelessWidget {
  final ReportCard report;

  const _ReportCardListItem({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/reports/${report.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  report.studentName?.isNotEmpty == true
                      ? report.studentName![0].toUpperCase()
                      : 'S',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.studentName ?? 'Unknown Student',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.className ?? ''} ${report.sectionName ?? ''} • Roll: ${report.studentRollNumber ?? 'N/A'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.academicYearName ?? ''} • ${report.termName ?? ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(status: report.status),
                  const SizedBox(height: 8),
                  if (report.pdfUrl != null)
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadPdf(context),
                      tooltip: 'Download PDF',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadPdf(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading report card...')),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'draft':
        color = Colors.orange;
        break;
      case 'generated':
        color = Colors.blue;
        break;
      case 'published':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
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

class _GenerateTab extends ConsumerStatefulWidget {
  const _GenerateTab();

  @override
  ConsumerState<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends ConsumerState<_GenerateTab> {
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedAcademicYear;
  String? _selectedTerm;
  String? _selectedTemplate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generationState = ref.watch(reportGenerationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Generate Report Cards',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate report cards for all students in a class at once',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedAcademicYear,
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
                          onChanged: (value) {
                            setState(() => _selectedAcademicYear = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTerm,
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
                          onChanged: (value) {
                            setState(() => _selectedTerm = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedClass,
                          decoration: const InputDecoration(
                            labelText: 'Class *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'class1', child: Text('Class 1')),
                            DropdownMenuItem(
                                value: 'class2', child: Text('Class 2')),
                            DropdownMenuItem(
                                value: 'class3', child: Text('Class 3')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedClass = value;
                              _selectedSection = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSection,
                          decoration: const InputDecoration(
                            labelText: 'Section *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'A', child: Text('Section A')),
                            DropdownMenuItem(value: 'B', child: Text('Section B')),
                            DropdownMenuItem(value: 'C', child: Text('Section C')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedSection = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedTemplate,
                    decoration: const InputDecoration(
                      labelText: 'Report Template *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'default',
                        child: Text('Standard Report Card'),
                      ),
                      DropdownMenuItem(
                        value: 'detailed',
                        child: Text('Detailed Academic Report'),
                      ),
                      DropdownMenuItem(
                        value: 'simple',
                        child: Text('Simple Grade Card'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedTemplate = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  if (generationState.isGenerating) ...[
                    LinearProgressIndicator(
                      value: generationState.progressPercentage / 100,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generating report cards... ${generationState.progress}/${generationState.total}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (generationState.currentStudent != null)
                      Text(
                        'Processing: ${generationState.currentStudent}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _canGenerate ? _generateReports : null,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate Report Cards'),
                      ),
                    ),
                  if (generationState.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      generationState.error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (generationState.generatedReports.isNotEmpty) ...[
            const SizedBox(height: 24),
            _GeneratedReportsSection(
              reports: generationState.generatedReports,
            ),
          ],
        ],
      ),
    );
  }

  bool get _canGenerate =>
      _selectedAcademicYear != null &&
      _selectedTerm != null &&
      _selectedClass != null &&
      _selectedSection != null &&
      _selectedTemplate != null;

  void _generateReports() {
    // In a real app, call the provider to generate reports
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating report cards...')),
    );
  }
}

class _GeneratedReportsSection extends StatelessWidget {
  final List<ReportCard> reports;

  const _GeneratedReportsSection({required this.reports});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Generated Reports (${reports.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('Download All'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.publish),
                      label: const Text('Publish All'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length > 5 ? 5 : reports.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final report = reports[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      report.studentName?.isNotEmpty == true
                          ? report.studentName![0]
                          : 'S',
                    ),
                  ),
                  title: Text(report.studentName ?? 'Unknown'),
                  subtitle: Text('Roll: ${report.studentRollNumber ?? 'N/A'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusChip(status: report.status),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => context.push('/reports/${report.id}'),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (reports.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text('View all ${reports.length} reports'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(reportCardTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Report Card Templates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCreateTemplateDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New Template'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: templates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 64,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          const Text('No templates created yet'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _showCreateTemplateDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Template'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: templates.length,
                      itemBuilder: (context, index) =>
                          _TemplateCard(template: templates[index]),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _showCreateTemplateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateTemplateDialog(),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ReportCardTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => _editTemplate(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (template.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DEFAULT',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (template.description != null)
                Text(
                  template.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (template.includesGrades)
                    _FeatureChip(label: 'Grades', color: Colors.blue),
                  if (template.includesAttendance)
                    _FeatureChip(label: 'Attendance', color: Colors.green),
                  if (template.includesRemarks)
                    _FeatureChip(label: 'Remarks', color: Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editTemplate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit template: ${template.name}')),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final Color color;

  const _FeatureChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _CreateTemplateDialog extends StatefulWidget {
  const _CreateTemplateDialog();

  @override
  State<_CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<_CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _includesGrades = true;
  bool _includesAttendance = true;
  bool _includesRemarks = true;
  bool _includesBehavior = false;
  bool _isDefault = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Template'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Include Sections',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                value: _includesGrades,
                onChanged: (v) => setState(() => _includesGrades = v!),
                title: const Text('Academic Grades'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _includesAttendance,
                onChanged: (v) => setState(() => _includesAttendance = v!),
                title: const Text('Attendance Summary'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _includesRemarks,
                onChanged: (v) => setState(() => _includesRemarks = v!),
                title: const Text('Teacher Remarks'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _includesBehavior,
                onChanged: (v) => setState(() => _includesBehavior = v!),
                title: const Text('Behavior Ratings'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v!),
                title: const Text('Set as Default Template'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _createTemplate,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createTemplate() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template created')),
      );
    }
  }
}
