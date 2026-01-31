import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/ptm.dart';
import '../../providers/ptm_provider.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final String scheduleId;

  const BookAppointmentScreen({super.key, required this.scheduleId});

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bookingProvider.notifier).loadSchedule(widget.scheduleId);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: state.isLoading && state.schedule == null
          ? const Center(child: CircularProgressIndicator())
          : state.schedule == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load PTM details'),
                      if (state.error != null)
                        Text(state.error!, style: const TextStyle(color: Colors.red)),
                      TextButton(
                        onPressed: () => ref
                            .read(bookingProvider.notifier)
                            .loadSchedule(widget.scheduleId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stepper(
                  type: StepperType.vertical,
                  currentStep: _getCurrentStep(state),
                  onStepContinue: () => _handleStepContinue(state),
                  onStepCancel: () => _handleStepCancel(state),
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          if (details.onStepContinue != null)
                            FilledButton(
                              onPressed: details.onStepContinue,
                              child: Text(
                                _getCurrentStep(state) == 3
                                    ? 'Book Appointment'
                                    : 'Continue',
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (details.onStepCancel != null &&
                              _getCurrentStep(state) > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Back'),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Select Teacher'),
                      subtitle: state.selectedTeacher != null
                          ? Text(state.selectedTeacher!.teacherName ?? 'Selected')
                          : null,
                      content: _TeacherSelectionStep(
                        scheduleId: widget.scheduleId,
                      ),
                      isActive: _getCurrentStep(state) >= 0,
                      state: state.selectedTeacher != null
                          ? StepState.complete
                          : StepState.indexed,
                    ),
                    Step(
                      title: const Text('Select Time Slot'),
                      subtitle: state.selectedSlot != null
                          ? Text(state.selectedSlot!)
                          : null,
                      content: state.selectedTeacher != null
                          ? _TimeSlotSelectionStep(
                              schedule: state.schedule!,
                              teacherAvailability: state.selectedTeacher!,
                            )
                          : const Text('Please select a teacher first'),
                      isActive: _getCurrentStep(state) >= 1,
                      state: state.selectedSlot != null
                          ? StepState.complete
                          : StepState.indexed,
                    ),
                    Step(
                      title: const Text('Select Child'),
                      content: const _ChildSelectionStep(),
                      isActive: _getCurrentStep(state) >= 2,
                      state: state.selectedStudentId != null
                          ? StepState.complete
                          : StepState.indexed,
                    ),
                    Step(
                      title: const Text('Confirm Booking'),
                      content: _ConfirmationStep(
                        state: state,
                        notesController: _notesController,
                      ),
                      isActive: _getCurrentStep(state) >= 3,
                    ),
                  ],
                ),
    );
  }

  int _getCurrentStep(BookingState state) {
    if (state.selectedTeacher == null) return 0;
    if (state.selectedSlot == null) return 1;
    if (state.selectedStudentId == null) return 2;
    return 3;
  }

  void _handleStepContinue(BookingState state) async {
    final currentStep = _getCurrentStep(state);

    if (currentStep < 3) {
      // Stepper will auto-advance when selection is made
    } else {
      // Book the appointment
      // In a real app, get the current parent ID
      const parentId = 'current-parent-id';

      final appointment = await ref.read(bookingProvider.notifier).bookAppointment(
            parentId,
            notes: _notesController.text.trim(),
          );

      if (appointment != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    }
  }

  void _handleStepCancel(BookingState state) {
    final notifier = ref.read(bookingProvider.notifier);
    final currentStep = _getCurrentStep(state);

    if (currentStep == 1) {
      notifier.selectTeacher(TeacherAvailability(
        id: '',
        ptmScheduleId: '',
        teacherId: '',
        roomNumber: '',
      )); // This will reset to null in practice
      ref.read(bookingProvider.notifier).reset();
      ref.read(bookingProvider.notifier).loadSchedule(widget.scheduleId);
    } else if (currentStep == 2) {
      notifier.selectSlot(''); // Reset slot
    } else if (currentStep == 3) {
      notifier.selectStudent(''); // Reset student
    }
  }
}

class _TeacherSelectionStep extends ConsumerWidget {
  final String scheduleId;

  const _TeacherSelectionStep({required this.scheduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, get the current parent ID
    final teachersAsync = ref.watch(teacherAvailabilityProvider(scheduleId));
    final selectedTeacher = ref.watch(bookingProvider).selectedTeacher;

    return teachersAsync.when(
      data: (teachers) {
        final availableTeachers = teachers.where((t) => t.isAvailable).toList();

        if (availableTeachers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No teachers available for this PTM'),
          );
        }

        return Column(
          children: availableTeachers.map((teacher) {
            final isSelected = selectedTeacher?.id == teacher.id;

            return Card(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    teacher.teacherName?.isNotEmpty == true
                        ? teacher.teacherName![0]
                        : 'T',
                  ),
                ),
                title: Text(teacher.teacherName ?? 'Teacher'),
                subtitle: Text('Room: ${teacher.roomNumber}'),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () =>
                    ref.read(bookingProvider.notifier).selectTeacher(teacher),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error: $error'),
    );
  }
}

class _TimeSlotSelectionStep extends ConsumerWidget {
  final PTMSchedule schedule;
  final TeacherAvailability teacherAvailability;

  const _TimeSlotSelectionStep({
    required this.schedule,
    required this.teacherAvailability,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookedSlotsAsync = ref.watch(
      bookedSlotsProvider(BookedSlotsFilter(
        scheduleId: schedule.id,
        teacherAvailabilityId: teacherAvailability.id,
      )),
    );

    final selectedSlot = ref.watch(bookingProvider).selectedSlot;
    final timeSlots = schedule.generateTimeSlots();

    return bookedSlotsAsync.when(
      data: (bookedSlots) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeSlots.map((slot) {
            final slotString = slot.display;
            final isBooked = bookedSlots.contains(slotString);
            final isSelected = selectedSlot == slotString;

            return ChoiceChip(
              label: Text(slotString),
              selected: isSelected,
              onSelected: isBooked
                  ? null
                  : (selected) {
                      if (selected) {
                        ref.read(bookingProvider.notifier).selectSlot(slotString);
                      }
                    },
              backgroundColor: isBooked ? Colors.grey[200] : null,
              disabledColor: Colors.grey[200],
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error: $error'),
    );
  }
}

class _ChildSelectionStep extends ConsumerWidget {
  const _ChildSelectionStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, get the parent's children
    // For now, show a placeholder
    final selectedStudentId = ref.watch(bookingProvider).selectedStudentId;

    // Placeholder children list
    final children = [
      {'id': 'child1', 'name': 'Student 1', 'class': 'Class 5 - A'},
      {'id': 'child2', 'name': 'Student 2', 'class': 'Class 3 - B'},
    ];

    return Column(
      children: children.map((child) {
        final isSelected = selectedStudentId == child['id'];

        return Card(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: CircleAvatar(
              child: Text(child['name']![0]),
            ),
            title: Text(child['name']!),
            subtitle: Text(child['class']!),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () =>
                ref.read(bookingProvider.notifier).selectStudent(child['id']!),
          ),
        );
      }).toList(),
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  final BookingState state;
  final TextEditingController notesController;

  const _ConfirmationStep({
    required this.state,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ConfirmationRow(
                  icon: Icons.event,
                  label: 'Date',
                  value: state.schedule?.dateDisplay ?? '',
                ),
                const Divider(),
                _ConfirmationRow(
                  icon: Icons.person,
                  label: 'Teacher',
                  value: state.selectedTeacher?.teacherName ?? '',
                ),
                const Divider(),
                _ConfirmationRow(
                  icon: Icons.room,
                  label: 'Room',
                  value: state.selectedTeacher?.roomNumber ?? '',
                ),
                const Divider(),
                _ConfirmationRow(
                  icon: Icons.schedule,
                  label: 'Time',
                  value: state.selectedSlot ?? '',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Notes for Teacher (Optional)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add any topics you want to discuss...',
            border: OutlineInputBorder(),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Text(
            state.error!,
            style: const TextStyle(color: Colors.red),
          ),
        ],
        if (state.isLoading) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConfirmationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
