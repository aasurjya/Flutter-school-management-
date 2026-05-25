import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/copy/warm_strings.dart';
import '../../../../data/models/academic.dart';
import '../../../../data/models/certificate.dart';
import '../../../../data/models/student.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../students/providers/students_provider.dart';
import '../../providers/certificate_provider.dart';
import 'certificate_pdf_builder.dart';

/// Bottom-sheet workflow that lets an admin pick a template + class/section,
/// review eligible students, and bulk-issue + bulk-print certificates.
class BulkIssueCertificateSheet extends ConsumerStatefulWidget {
  const BulkIssueCertificateSheet({super.key});

  @override
  ConsumerState<BulkIssueCertificateSheet> createState() =>
      _BulkIssueCertificateSheetState();
}

class _BulkIssueCertificateSheetState
    extends ConsumerState<BulkIssueCertificateSheet> {
  CertificateTemplate? _template;
  SchoolClass? _selectedClass;
  Section? _selectedSection;
  final Set<String> _selectedStudentIds = <String>{};
  bool _isIssuing = false;
  double _progress = 0;
  String _statusLine = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(templateNotifierProvider.notifier).loadTemplates();
    });
  }

  Future<void> _issueAll(List<Student> students) async {
    if (_template == null) {
      context.showErrorSnackBar('Pick a template first');
      return;
    }
    final selected = students
        .where((s) => _selectedStudentIds.contains(s.id))
        .toList();
    if (selected.isEmpty) {
      context.showErrorSnackBar('Select at least one student');
      return;
    }

    setState(() {
      _isIssuing = true;
      _progress = 0;
      _statusLine = 'Starting…';
    });

    final notifier =
        ref.read(issuedCertificateNotifierProvider.notifier);
    final mergedDoc = pw.Document();
    int succeeded = 0;
    final failures = <String>[];

    for (int i = 0; i < selected.length; i++) {
      final student = selected[i];
      setState(() {
        _progress = i / selected.length;
        _statusLine =
            'Issuing ${i + 1}/${selected.length} — ${student.fullName}';
      });
      try {
        final cert = await notifier.issueCertificate({
          'template_id': _template!.id,
          'student_id': student.id,
          'data': <String, dynamic>{},
          'status': 'issued',
          'type': _template!.type.value,
        });
        // Build PDF page for this cert and append into the merged doc
        final pdfBytes =
            await CertificatePdfBuilder.buildCertificatePdf(
          certificate: cert.copyWith(
            studentName: student.fullName,
            template: _template,
          ),
          template: _template!,
          schoolName: 'School Name',
          schoolAddress: 'School Address, City, State',
        );
        // Append produced single-page PDF as raster image into the merged
        // document. The bytes are independent A4 PDFs — we re-emit each as
        // its own page in the merged doc by re-running the builder per
        // student. (Simpler than parsing & merging.)
        await for (final page
            in Printing.raster(pdfBytes, dpi: 144)) {
          final img = await pageImageToPdfImage(page, mergedDoc);
          mergedDoc.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4.landscape,
              margin: pw.EdgeInsets.zero,
              build: (_) => pw.Center(child: pw.Image(img)),
            ),
          );
        }
        succeeded++;
      } catch (e) {
        failures.add(student.fullName);
      }
    }

    if (!mounted) return;
    setState(() {
      _progress = 1.0;
      _statusLine = 'Done — $succeeded issued';
      _isIssuing = false;
    });

    ref.invalidate(certificateStatsProvider);
    ref.invalidate(issuedCertificatesProvider);

    if (succeeded > 0) {
      try {
        final mergedBytes = await mergedDoc.save();
        await Printing.layoutPdf(
          onLayout: (_) => mergedBytes,
          name:
              'bulk-certificates-${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      } catch (_) {
        // Surface only — issuance already persisted server-side
      }
    }

    if (mounted) {
      Navigator.pop(context);
      if (failures.isEmpty) {
        context.showSuccessSnackBar(
            'Issued $succeeded certificates successfully');
      } else {
        context.showErrorSnackBar(
            'Issued $succeeded · failed ${failures.length}');
      }
    }
  }

  /// Convert one rasterised page into a `pw.ImageProvider` for embedding.
  Future<pw.ImageProvider> pageImageToPdfImage(
    PdfRaster page,
    pw.Document doc,
  ) async {
    return pw.MemoryImage(await page.toPng());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(templateNotifierProvider);
    final classesAsync = ref.watch(classesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bulk Issue Certificates',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a template, then a class/section. Toggle students off if needed and issue in one go.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),

            // Template picker
            templatesAsync.when(
              data: (templates) => DropdownButtonFormField<CertificateTemplate>(
                initialValue: _template,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Certificate Template *',
                  prefixIcon: Icon(Icons.design_services),
                  border: OutlineInputBorder(),
                ),
                items: templates
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text('${t.name} (${t.type.label})'),
                        ))
                    .toList(),
                onChanged: _isIssuing
                    ? null
                    : (v) => setState(() => _template = v),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(WarmCopy.genericError),
            ),
            const SizedBox(height: 16),

            // Class picker
            classesAsync.when(
              data: (classes) => DropdownButtonFormField<SchoolClass>(
                initialValue: _selectedClass,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Class *',
                  prefixIcon: Icon(Icons.class_outlined),
                  border: OutlineInputBorder(),
                ),
                items: classes
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: _isIssuing
                    ? null
                    : (v) => setState(() {
                          _selectedClass = v;
                          _selectedSection = null;
                          _selectedStudentIds.clear();
                        }),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(WarmCopy.genericError),
            ),
            const SizedBox(height: 16),

            // Section picker (only after class is selected)
            if (_selectedClass != null)
              Consumer(
                builder: (ctx, ref, _) {
                  final sectionsAsync = ref.watch(
                      sectionsByClassProvider(_selectedClass!.id));
                  return sectionsAsync.when(
                    data: (sections) =>
                        DropdownButtonFormField<Section>(
                      initialValue: _selectedSection,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Section *',
                        prefixIcon: Icon(Icons.groups_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: sections
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name),
                              ))
                          .toList(),
                      onChanged: _isIssuing
                          ? null
                          : (v) => setState(() {
                                _selectedSection = v;
                                _selectedStudentIds.clear();
                              }),
                    ),
                    loading: () => const SizedBox(
                      height: 56,
                      child: Center(
                          child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text(WarmCopy.genericError),
                  );
                },
              ),
            if (_selectedClass != null) const SizedBox(height: 20),

            // Student list (only after section is selected)
            if (_selectedSection != null)
              _StudentChecklist(
                sectionId: _selectedSection!.id,
                selectedIds: _selectedStudentIds,
                onToggle: _isIssuing
                    ? null
                    : (id, value) {
                        setState(() {
                          if (value) {
                            _selectedStudentIds.add(id);
                          } else {
                            _selectedStudentIds.remove(id);
                          }
                        });
                      },
                onSelectAll: _isIssuing
                    ? null
                    : (ids) {
                        setState(() {
                          _selectedStudentIds
                            ..clear()
                            ..addAll(ids);
                        });
                      },
                onClearAll: _isIssuing
                    ? null
                    : () => setState(_selectedStudentIds.clear),
              ),
            const SizedBox(height: 20),

            if (_isIssuing) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(_statusLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  )),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.send),
                label: Text(
                  _selectedStudentIds.isEmpty
                      ? 'Select students to issue'
                      : 'Issue ${_selectedStudentIds.length} Certificate(s)',
                ),
                onPressed: (_isIssuing ||
                        _template == null ||
                        _selectedSection == null ||
                        _selectedStudentIds.isEmpty)
                    ? null
                    : () async {
                        final students = await ref.read(
                          studentsBySectionProvider(
                                  _selectedSection!.id)
                              .future,
                        );
                        await _issueAll(students);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentChecklist extends ConsumerWidget {
  final String sectionId;
  final Set<String> selectedIds;
  final void Function(String id, bool value)? onToggle;
  final void Function(Iterable<String> ids)? onSelectAll;
  final VoidCallback? onClearAll;

  const _StudentChecklist({
    required this.sectionId,
    required this.selectedIds,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentsAsync =
        ref.watch(studentsBySectionProvider(sectionId));

    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No students in this section',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${students.length} students',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSelectAll == null
                      ? null
                      : () => onSelectAll!(students.map((s) => s.id)),
                  child: const Text('Select all'),
                ),
                TextButton(
                  onPressed: onClearAll,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: students.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final s = students[i];
                  final checked = selectedIds.contains(s.id);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: onToggle == null
                        ? null
                        : (v) => onToggle!(s.id, v ?? false),
                    title: Text(s.fullName),
                    subtitle: Text(s.admissionNumber),
                    dense: true,
                    controlAffinity:
                        ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(WarmCopy.genericError),
      ),
    );
  }
}
