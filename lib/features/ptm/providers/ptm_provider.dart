import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/ptm.dart';
import '../../../data/repositories/ptm_repository.dart';

final ptmRepositoryProvider = Provider<PTMRepository>((ref) {
  return PTMRepository(ref.watch(supabaseProvider));
});

// ==================== PTM SCHEDULE PROVIDERS ====================

final ptmSchedulesProvider =
    FutureProvider.family<List<PTMSchedule>, PTMSchedulesFilter>(
  (ref, filter) async {
    final repository = ref.watch(ptmRepositoryProvider);
    return repository.getPTMSchedules(
      status: filter.status,
      upcomingOnly: filter.upcomingOnly,
    );
  },
);

final ptmScheduleByIdProvider = FutureProvider.family<PTMSchedule?, String>(
  (ref, scheduleId) async {
    final repository = ref.watch(ptmRepositoryProvider);
    return repository.getPTMScheduleById(scheduleId);
  },
);

final ptmStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, scheduleId) async {
    final repository = ref.watch(ptmRepositoryProvider);
    return repository.getPTMStatistics(scheduleId);
  },
);

// ==================== TEACHER AVAILABILITY PROVIDERS ====================

final teacherAvailabilityProvider =
    FutureProvider.family<List<TeacherAvailability>, String>(
  (ref, scheduleId) async {
    final repository = ref.watch(ptmRepositoryProvider);
    return repository.getTeacherAvailability(scheduleId);
  },
);

final teachersForParentProvider =
    FutureProvider.family<List<TeacherAvailability>, TeachersForParentFilter>(
  (ref, filter) async {
    final repository = ref.watch(ptmRepositoryProvider);
    return repository.getTeachersForParent(filter.scheduleId, filter.parentId);
  },
);

// ==================== APPOINTMENT PROVIDERS ====================

final ptmAppointmentsProvider =
    FutureProvider.family<List<PTMAppointment>, AppointmentsFilter>(
  (ref, filter) async {
    final repository = ref.watch(ptmRepositoryProvider);
    return repository.getAppointments(
      scheduleId: filter.scheduleId,
      teacherAvailabilityId: filter.teacherAvailabilityId,
      parentId: filter.parentId,
      studentId: filter.studentId,
      status: filter.status,
    );
  },
);

final appointmentByIdProvider = FutureProvider.family<PTMAppointment?, String>(
  (ref, appointmentId) async {
    final repository = ref.watch(ptmRepositoryProvider);
    return repository.getAppointmentById(appointmentId);
  },
);

final bookedSlotsProvider =
    FutureProvider.family<List<String>, BookedSlotsFilter>(
  (ref, filter) async {
    final repository = ref.watch(ptmRepositoryProvider);
    return repository.getBookedSlots(
      filter.scheduleId,
      filter.teacherAvailabilityId,
    );
  },
);

// ==================== FILTER CLASSES ====================

class PTMSchedulesFilter {
  final String? status;
  final bool upcomingOnly;

  const PTMSchedulesFilter({
    this.status,
    this.upcomingOnly = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PTMSchedulesFilter &&
          other.status == status &&
          other.upcomingOnly == upcomingOnly;

  @override
  int get hashCode => Object.hash(status, upcomingOnly);
}

class TeachersForParentFilter {
  final String scheduleId;
  final String parentId;

  const TeachersForParentFilter({
    required this.scheduleId,
    required this.parentId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeachersForParentFilter &&
          other.scheduleId == scheduleId &&
          other.parentId == parentId;

  @override
  int get hashCode => Object.hash(scheduleId, parentId);
}

class AppointmentsFilter {
  final String? scheduleId;
  final String? teacherAvailabilityId;
  final String? parentId;
  final String? studentId;
  final String? status;

  const AppointmentsFilter({
    this.scheduleId,
    this.teacherAvailabilityId,
    this.parentId,
    this.studentId,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentsFilter &&
          other.scheduleId == scheduleId &&
          other.teacherAvailabilityId == teacherAvailabilityId &&
          other.parentId == parentId &&
          other.studentId == studentId &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
        scheduleId,
        teacherAvailabilityId,
        parentId,
        studentId,
        status,
      );
}

class BookedSlotsFilter {
  final String scheduleId;
  final String teacherAvailabilityId;

  const BookedSlotsFilter({
    required this.scheduleId,
    required this.teacherAvailabilityId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookedSlotsFilter &&
          other.scheduleId == scheduleId &&
          other.teacherAvailabilityId == teacherAvailabilityId;

  @override
  int get hashCode => Object.hash(scheduleId, teacherAvailabilityId);
}

// ==================== BOOKING NOTIFIER ====================

class BookingState {
  final PTMSchedule? schedule;
  final TeacherAvailability? selectedTeacher;
  final String? selectedSlot;
  final String? selectedStudentId;
  final bool isLoading;
  final String? error;

  const BookingState({
    this.schedule,
    this.selectedTeacher,
    this.selectedSlot,
    this.selectedStudentId,
    this.isLoading = false,
    this.error,
  });

  BookingState copyWith({
    PTMSchedule? schedule,
    TeacherAvailability? selectedTeacher,
    String? selectedSlot,
    String? selectedStudentId,
    bool? isLoading,
    String? error,
  }) {
    return BookingState(
      schedule: schedule ?? this.schedule,
      selectedTeacher: selectedTeacher ?? this.selectedTeacher,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      selectedStudentId: selectedStudentId ?? this.selectedStudentId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get canBook =>
      schedule != null &&
      selectedTeacher != null &&
      selectedSlot != null &&
      selectedStudentId != null;
}

class BookingNotifier extends StateNotifier<BookingState> {
  final PTMRepository _repository;

  BookingNotifier(this._repository) : super(const BookingState());

  Future<void> loadSchedule(String scheduleId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final schedule = await _repository.getPTMScheduleById(scheduleId);
      state = state.copyWith(schedule: schedule, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectTeacher(TeacherAvailability teacher) {
    state = state.copyWith(selectedTeacher: teacher, selectedSlot: null);
  }

  void selectSlot(String slot) {
    state = state.copyWith(selectedSlot: slot);
  }

  void selectStudent(String studentId) {
    state = state.copyWith(selectedStudentId: studentId);
  }

  Future<PTMAppointment?> bookAppointment(String parentId, {String? notes}) async {
    if (!state.canBook) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final appointment = await _repository.bookAppointment(
        scheduleId: state.schedule!.id,
        teacherAvailabilityId: state.selectedTeacher!.id,
        parentId: parentId,
        studentId: state.selectedStudentId!,
        timeSlot: state.selectedSlot!,
        notes: notes,
      );

      state = const BookingState(); // Reset state
      return appointment;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() {
    state = const BookingState();
  }
}

final bookingProvider =
    StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  final repository = ref.watch(ptmRepositoryProvider);
  return BookingNotifier(repository);
});
