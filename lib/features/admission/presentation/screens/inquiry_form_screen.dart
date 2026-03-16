import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/admission.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/admission_provider.dart';

class InquiryFormScreen extends ConsumerStatefulWidget {
  final AdmissionInquiry? inquiry;

  const InquiryFormScreen({super.key, this.inquiry});

  @override
  ConsumerState<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends ConsumerState<InquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _studentNameController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  InquirySource _source = InquirySource.walkIn;
  InquiryStatus _status = InquiryStatus.newInquiry;
  DateTime? _followupDate;
  bool _isSubmitting = false;

  bool get isEditing => widget.inquiry != null;

  @override
  void initState() {
    super.initState();
    final inq = widget.inquiry;
    _studentNameController = TextEditingController(text: inq?.studentName ?? '');
    _parentNameController = TextEditingController(text: inq?.parentName ?? '');
    _emailController = TextEditingController(text: inq?.email ?? '');
    _phoneController = TextEditingController(text: inq?.phone ?? '');
    _notesController = TextEditingController(text: inq?.notes ?? '');
    if (inq != null) {
      _source = inq.source;
      _status = inq.status;
      _followupDate = inq.nextFollowupDate;
    }
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _parentNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'student_name': _studentNameController.text.trim(),
        'parent_name': _parentNameController.text.trim(),
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'phone': _phoneController.text.trim(),
        'source': _source.value,
        'status': _status.value,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'next_followup_date':
            _followupDate?.toIso8601String().split('T')[0],
      };

      final notifier = ref.read(inquiryNotifierProvider.notifier);
      if (isEditing) {
        await notifier.updateInquiry(widget.inquiry!.id, data);
      } else {
        await notifier.createInquiry(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Inquiry updated' : 'Inquiry created',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Inquiry' : 'New Inquiry'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Student info section
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Information',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _studentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Student Name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Parent/Contact info
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parent / Contact',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _parentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Parent Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone *',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Inquiry details
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inquiry Details',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<InquirySource>(
                    initialValue: _source,
                    decoration: const InputDecoration(
                      labelText: 'Source',
                      prefixIcon: Icon(Icons.source),
                    ),
                    items: InquirySource.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _source = v);
                    },
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InquiryStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: InquiryStatus.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Follow-up date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: Text(
                      _followupDate != null
                          ? 'Follow-up: ${_followupDate!.day}/${_followupDate!.month}/${_followupDate!.year}'
                          : 'Set follow-up date',
                    ),
                    trailing: _followupDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear',
                            onPressed: () =>
                                setState(() => _followupDate = null),
                          )
                        : null,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _followupDate ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _followupDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Inquiry' : 'Create Inquiry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
