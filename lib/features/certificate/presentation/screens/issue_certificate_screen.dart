import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/certificate.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/certificate_provider.dart';

class IssueCertificateScreen extends ConsumerStatefulWidget {
  const IssueCertificateScreen({super.key});

  @override
  ConsumerState<IssueCertificateScreen> createState() =>
      _IssueCertificateScreenState();
}

class _IssueCertificateScreenState
    extends ConsumerState<IssueCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _purposeController = TextEditingController();

  CertificateTemplate? _selectedTemplate;
  bool _isIssuing = false;

  // Dynamic data fields based on template type
  final Map<String, TextEditingController> _dataControllers = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(templateNotifierProvider.notifier).loadTemplates();
    });
  }

  void _onTemplateSelected(CertificateTemplate? template) {
    // Clean up old controllers
    for (final c in _dataControllers.values) {
      c.dispose();
    }
    _dataControllers.clear();

    setState(() {
      _selectedTemplate = template;
    });

    if (template != null) {
      // Create controllers for common fields based on type
      final fields = _getFieldsForType(template.type);
      for (final field in fields) {
        _dataControllers[field] = TextEditingController();
      }
      setState(() {});
    }
  }

  List<String> _getFieldsForType(CertificateType type) {
    switch (type) {
      case CertificateType.transfer:
        return [
          'parent_name',
          'son_daughter',
          'from_date',
          'to_date',
          'conduct',
          'reason',
        ];
      case CertificateType.bonafide:
        return [
          'parent_name',
          'son_daughter',
          'dob',
          'academic_year',
        ];
      case CertificateType.character:
        return [
          'parent_name',
          'son_daughter',
          'from_date',
          'to_date',
          'conduct',
          'pronoun',
          'additional_remarks',
        ];
      case CertificateType.achievement:
      case CertificateType.participation:
      case CertificateType.merit:
        return [
          'achievement_description',
          'event_name',
          'date',
        ];
      case CertificateType.migration:
        return [
          'parent_name',
          'from_date',
          'to_date',
          'destination',
        ];
      case CertificateType.custom:
        return ['body'];
    }
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'parent_name':
        return "Parent/Guardian's Name";
      case 'son_daughter':
        return 'Son/Daughter of';
      case 'from_date':
        return 'From Date';
      case 'to_date':
        return 'To Date';
      case 'conduct':
        return 'Conduct & Character';
      case 'reason':
        return 'Reason for Leaving';
      case 'dob':
        return 'Date of Birth';
      case 'academic_year':
        return 'Academic Year';
      case 'pronoun':
        return 'Pronoun (he/she/they)';
      case 'additional_remarks':
        return 'Additional Remarks';
      case 'achievement_description':
        return 'Achievement Description';
      case 'event_name':
        return 'Event Name';
      case 'date':
        return 'Date';
      case 'destination':
        return 'Destination';
      case 'body':
        return 'Certificate Body';
      default:
        return field.replaceAll('_', ' ').toUpperCase();
    }
  }

  Future<void> _issueCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a template')),
      );
      return;
    }

    setState(() => _isIssuing = true);
    try {
      // Build data map
      final data = <String, dynamic>{};
      for (final entry in _dataControllers.entries) {
        if (entry.value.text.trim().isNotEmpty) {
          data[entry.key] = entry.value.text.trim();
        }
      }

      final certData = {
        'template_id': _selectedTemplate!.id,
        'student_id': _studentIdController.text.trim(),
        'purpose': _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        'data': data,
        'status': 'draft',
        'type': _selectedTemplate!.type.value,
      };

      final cert = await ref
          .read(issuedCertificateNotifierProvider.notifier)
          .issueCertificate(certData);

      ref.invalidate(certificateStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Certificate created: ${cert.certificateNumber}'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pushReplacement(
          AppRoutes.certificatePreview
              .replaceFirst(':certId', cert.id),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isIssuing = false);
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _purposeController.dispose();
    for (final c in _dataControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(templateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Certificate'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Template selection
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Template',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  templatesAsync.when(
                    data: (templates) {
                      return DropdownButtonFormField<CertificateTemplate>(
                        value: _selectedTemplate,
                        decoration: const InputDecoration(
                          labelText: 'Certificate Template *',
                          prefixIcon: Icon(Icons.design_services),
                        ),
                        items: templates
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                      '${t.name} (${t.type.label})'),
                                ))
                            .toList(),
                        onChanged: _onTemplateSelected,
                        validator: (v) =>
                            v == null ? 'Select a template' : null,
                      );
                    },
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading templates: $e'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Student selection
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Student ID *',
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Enter student UUID',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose',
                      prefixIcon: Icon(Icons.info_outline),
                      hintText: 'e.g., School transfer, Bank account',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic data fields
            if (_selectedTemplate != null &&
                _dataControllers.isNotEmpty) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Certificate Data',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._dataControllers.entries.map((entry) {
                      final isMultiline =
                          entry.key == 'body' ||
                              entry.key == 'additional_remarks' ||
                              entry.key == 'achievement_description';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText: _fieldLabel(entry.key),
                          ),
                          maxLines: isMultiline ? 3 : 1,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Issue button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isIssuing ? null : _issueCertificate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isIssuing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_circle),
                label: Text(
                  _isIssuing
                      ? 'Creating...'
                      : 'Create Certificate (Draft)',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
