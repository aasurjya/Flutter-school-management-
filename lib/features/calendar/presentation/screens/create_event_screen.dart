import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/school_event.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/calendar_provider.dart';

/// Form screen for creating/editing events with type, dates, time,
/// recurrence, visibility, target classes, and color picker
class CreateEventScreen extends ConsumerStatefulWidget {
  final SchoolEvent? existingEvent;

  const CreateEventScreen({super.key, this.existingEvent});

  @override
  ConsumerState<CreateEventScreen> createState() =>
      _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  EventType _eventType = EventType.academic;
  EventVisibility _visibility = EventVisibility.all;
  EventStatus _status = EventStatus.scheduled;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = true;
  bool _isMandatory = false;
  bool _isRecurring = false;
  String _recurrenceFrequency = 'weekly';
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;
  String _colorHex = '#6366F1';
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existingEvent!;
      _titleController.text = e.title;
      _descriptionController.text = e.description ?? '';
      _locationController.text = e.location ?? '';
      _eventType = e.eventType;
      _visibility = e.visibility;
      _status = e.status;
      _startDate = e.startDate;
      _endDate = e.endDate;
      _isAllDay = e.isAllDay;
      _isMandatory = e.isMandatory;
      _isRecurring = e.isRecurring;
      _colorHex = e.colorHex ?? e.eventType.colorHex;

      if (e.startTime != null) {
        final parts = e.startTime!.split(':');
        _startTime = TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (e.endTime != null) {
        final parts = e.endTime!.split(':');
        _endTime = TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (e.recurrenceRule != null) {
        _recurrenceFrequency = e.recurrenceRule!.frequency;
        _recurrenceInterval = e.recurrenceRule!.interval;
        _recurrenceEndDate = e.recurrenceRule!.endDate;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event Details',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title *',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Event type
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event Type',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EventType.values.map((type) {
                      final isSelected = _eventType == type;
                      final color = _colorFromHex(type.colorHex);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _eventType = type;
                            _colorHex = type.colorHex;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected ? color : AppColors.borderLight,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_typeIcon(type),
                                  size: 16, color: color),
                              const SizedBox(width: 6),
                              Text(
                                type.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : AppColors.textSecondaryLight,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date & Time
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date & Time',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  // All day switch
                  SwitchListTile(
                    title: const Text('All Day Event'),
                    value: _isAllDay,
                    onChanged: (v) => setState(() => _isAllDay = v),
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Start date
                  _DatePickerTile(
                    label: 'Start Date',
                    date: _startDate,
                    onPick: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          if (_endDate.isBefore(_startDate)) {
                            _endDate = _startDate;
                          }
                        });
                      }
                    },
                  ),

                  // End date
                  _DatePickerTile(
                    label: 'End Date',
                    date: _endDate,
                    onPick: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                      }
                    },
                  ),

                  // Time pickers (if not all day)
                  if (!_isAllDay) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TimePickerTile(
                            label: 'Start Time',
                            time: _startTime,
                            onPick: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    _startTime ?? const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (picked != null) {
                                setState(() => _startTime = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimePickerTile(
                            label: 'End Time',
                            time: _endTime,
                            onPick: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    _endTime ?? const TimeOfDay(hour: 17, minute: 0),
                              );
                              if (picked != null) {
                                setState(() => _endTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recurrence
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: Text('Recurring Event',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Every '),
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            initialValue: '$_recurrenceInterval',
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            onChanged: (v) {
                              _recurrenceInterval = int.tryParse(v) ?? 1;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _recurrenceFrequency,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            items: ['daily', 'weekly', 'monthly', 'yearly']
                                .map((f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f[0].toUpperCase() +
                                        f.substring(1))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(
                                    () => _recurrenceFrequency = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DatePickerTile(
                      label: 'Recurrence End Date',
                      date: _recurrenceEndDate,
                      onPick: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _recurrenceEndDate ?? _endDate.add(const Duration(days: 90)),
                          firstDate: _endDate,
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(
                              () => _recurrenceEndDate = picked);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Visibility & Mandatory
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EventVisibility>(
                    initialValue: _visibility,
                    decoration: const InputDecoration(
                      labelText: 'Visibility',
                      prefixIcon: Icon(Icons.visibility),
                    ),
                    items: EventVisibility.values.map((v) {
                      return DropdownMenuItem(
                          value: v, child: Text(v.label));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _visibility = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_isEditing) ...[
                    DropdownButtonFormField<EventStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: EventStatus.values.map((s) {
                        return DropdownMenuItem(
                            value: s, child: Text(s.label));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  SwitchListTile(
                    title: const Text('Mandatory Event'),
                    subtitle: const Text(
                        'Attendance is required for this event'),
                    value: _isMandatory,
                    onChanged: (v) => setState(() => _isMandatory = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Color picker
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event Color',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      '#6366F1', '#EC4899', '#22C55E', '#F59E0B',
                      '#EF4444', '#8B5CF6', '#06B6D4', '#F97316',
                      '#14B8A6', '#D946EF', '#3B82F6', '#84CC16',
                    ].map((hex) {
                      final color = _colorFromHex(hex);
                      final isSelected = _colorHex == hex;
                      return GestureDetector(
                        onTap: () => setState(() => _colorHex = hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black,
                                    width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Event' : 'Create Event',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(calendarRepositoryProvider);

      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'event_type': _eventType.value,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
        'is_all_day': _isAllDay,
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        'is_recurring': _isRecurring,
        'color_hex': _colorHex,
        'visibility': _visibility.value,
        'is_mandatory': _isMandatory,
        'status': _status.value,
      };

      if (!_isAllDay) {
        if (_startTime != null) {
          data['start_time'] =
              '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
        }
        if (_endTime != null) {
          data['end_time'] =
              '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';
        }
      }

      if (_isRecurring) {
        data['recurrence_rule'] = {
          'frequency': _recurrenceFrequency,
          'interval': _recurrenceInterval,
          if (_recurrenceEndDate != null)
            'end_date':
                _recurrenceEndDate!.toIso8601String().split('T')[0],
        };
      }

      if (_isEditing) {
        await repo.updateEvent(widget.existingEvent!.id, data);
      } else {
        await repo.createEvent(data);
      }

      // Invalidate relevant providers
      ref.invalidate(eventsForRangeProvider);
      ref.invalidate(upcomingEventsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Event ${_isEditing ? 'updated' : 'created'} successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  IconData _typeIcon(EventType type) {
    switch (type) {
      case EventType.academic:
        return Icons.school;
      case EventType.cultural:
        return Icons.theater_comedy;
      case EventType.sports:
        return Icons.sports_soccer;
      case EventType.holiday:
        return Icons.beach_access;
      case EventType.exam:
        return Icons.quiz;
      case EventType.ptaMeeting:
        return Icons.groups;
      case EventType.workshop:
        return Icons.build;
      case EventType.fieldTrip:
        return Icons.directions_bus;
      case EventType.competition:
        return Icons.emoji_events;
      case EventType.celebration:
        return Icons.celebration;
    }
  }

  Color _colorFromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: TextButton(
        onPressed: onPick,
        child: Text(
          date != null
              ? DateFormat('MMM d, yyyy').format(date!)
              : 'Select',
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onPick;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondaryLight),
                ),
                Text(
                  time != null ? time!.format(context) : 'Pick time',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
