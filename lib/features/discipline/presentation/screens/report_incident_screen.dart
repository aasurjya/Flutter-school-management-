import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/discipline.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../providers/discipline_provider.dart';

class ReportIncidentScreen extends ConsumerStatefulWidget {
  final String? preselectedStudentId;

  const ReportIncidentScreen({super.key, this.preselectedStudentId});

  @override
  ConsumerState<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _witnessController = TextEditingController();

  String? _studentId;
  String? _categoryId;
  IncidentSeverity _severity = IncidentSeverity.minor;
  DateTime _incidentDate = DateTime.now();
  TimeOfDay? _incidentTime;
  final List<String> _witnesses = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _studentId = widget.preselectedStudentId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _witnessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync =
        ref.watch(behaviorCategoriesProvider(BehaviorCategoryType.negative));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student ID input
              TextFormField(
                initialValue: _studentId,
                decoration: const InputDecoration(
                  labelText: 'Student ID *',
                  hintText: 'Enter student ID',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Student is required' : null,
                onChanged: (v) => _studentId = v.trim(),
              ),
              const SizedBox(height: 16),

              // Category
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<String>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.name} (${c.points} pts)'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Failed to load categories'),
              ),
              const SizedBox(height: 16),

              // Severity
              const Text(
                'Severity *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _SeveritySelector(
                selected: _severity,
                onChanged: (s) => setState(() => _severity = s),
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Incident Date *',
                      date: _incidentDate,
                      onChanged: (d) => setState(() => _incidentDate = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'Time (optional)',
                      time: _incidentTime,
                      onChanged: (t) => setState(() => _incidentTime = t),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe the incident in detail...',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  hintText: 'e.g. Classroom 5B, Playground',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Witnesses
              const Text(
                'Witnesses (optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _witnessController,
                      decoration: const InputDecoration(
                        hintText: 'Witness name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      final name = _witnessController.text.trim();
                      if (name.isNotEmpty) {
                        setState(() {
                          _witnesses.add(name);
                          _witnessController.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  ),
                ],
              ),
              if (_witnesses.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _witnesses.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      onDeleted: () {
                        setState(() => _witnesses.removeAt(entry.key));
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(disciplineRepositoryProvider);
      final userId = repo.requireUserId;
      final tenantId = repo.requireTenantId;

      String? timeStr;
      if (_incidentTime != null) {
        timeStr =
            '${_incidentTime!.hour.toString().padLeft(2, '0')}:${_incidentTime!.minute.toString().padLeft(2, '0')}:00';
      }

      final incident = BehaviorIncident(
        id: '',
        tenantId: tenantId,
        studentId: _studentId!,
        reportedBy: userId,
        categoryId: _categoryId,
        incidentDate: _incidentDate,
        incidentTime: timeStr,
        description: _descriptionController.text.trim(),
        severity: _severity,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        witnesses: _witnesses,
        evidenceUrls: [],
        status: IncidentStatus.reported,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createIncident(incident);

      if (mounted) {
        context.showSuccessSnackBar('Incident reported successfully');
        ref.invalidate(recentIncidentsProvider);
        ref.invalidate(defaultBehaviorStatsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to report incident: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _SeveritySelector extends StatelessWidget {
  final IncidentSeverity selected;
  final ValueChanged<IncidentSeverity> onChanged;

  const _SeveritySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: IncidentSeverity.values.map((s) {
        final isSelected = selected == s;
        final color = _colorFor(s);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onChanged(s),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    s.displayLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _colorFor(IncidentSeverity s) {
    switch (s) {
      case IncidentSeverity.minor:
        return const Color(0xFF3B82F6);
      case IncidentSeverity.moderate:
        return const Color(0xFFF59E0B);
      case IncidentSeverity.major:
        return const Color(0xFFF97316);
      case IncidentSeverity.critical:
        return const Color(0xFFEF4444);
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DateField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeField({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (t != null) onChanged(t);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.access_time, size: 18),
        ),
        child: Text(
          time != null ? time!.format(context) : 'Not set',
          style: TextStyle(
            fontSize: 14,
            color: time != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }
}
