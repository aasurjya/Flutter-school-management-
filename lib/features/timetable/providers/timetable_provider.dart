import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/timetable.dart';
import '../../../data/repositories/timetable_repository.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(ref.watch(supabaseProvider));
});

final timetableSlotsProvider = FutureProvider<List<TimetableSlot>>((ref) async {
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getTimetableSlots();
});

final sectionTimetableProvider = FutureProvider.family<List<Timetable>, SectionTimetableFilter>(
  (ref, filter) async {
    final repository = ref.watch(timetableRepositoryProvider);
    return repository.getTimetables(
      sectionId: filter.sectionId,
      academicYearId: filter.academicYearId,
      dayOfWeek: filter.dayOfWeek,
    );
  },
);

final weeklyTimetableProvider = FutureProvider.family<WeeklyTimetable, WeeklyTimetableFilter>(
  (ref, filter) async {
    final repository = ref.watch(timetableRepositoryProvider);
    return repository.getWeeklyTimetable(
      sectionId: filter.sectionId,
      academicYearId: filter.academicYearId,
    );
  },
);

final todayTimetableProvider = FutureProvider.family<List<TimetableEntry>, TodayTimetableFilter>(
  (ref, filter) async {
    final repository = ref.watch(timetableRepositoryProvider);
    return repository.getTodayTimetable(
      sectionId: filter.sectionId,
      academicYearId: filter.academicYearId,
    );
  },
);

final teacherTimetableProvider = FutureProvider.family<List<Timetable>, TeacherTimetableFilter>(
  (ref, filter) async {
    final repository = ref.watch(timetableRepositoryProvider);
    return repository.getTeacherTimetable(
      teacherId: filter.teacherId,
      academicYearId: filter.academicYearId,
      dayOfWeek: filter.dayOfWeek,
    );
  },
);

class SectionTimetableFilter {
  final String sectionId;
  final String? academicYearId;
  final int? dayOfWeek;

  const SectionTimetableFilter({
    required this.sectionId,
    this.academicYearId,
    this.dayOfWeek,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionTimetableFilter &&
          other.sectionId == sectionId &&
          other.academicYearId == academicYearId &&
          other.dayOfWeek == dayOfWeek;

  @override
  int get hashCode => Object.hash(sectionId, academicYearId, dayOfWeek);
}

class WeeklyTimetableFilter {
  final String sectionId;
  final String? academicYearId;

  const WeeklyTimetableFilter({
    required this.sectionId,
    this.academicYearId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyTimetableFilter &&
          other.sectionId == sectionId &&
          other.academicYearId == academicYearId;

  @override
  int get hashCode => Object.hash(sectionId, academicYearId);
}

class TodayTimetableFilter {
  final String sectionId;
  final String? academicYearId;

  const TodayTimetableFilter({
    required this.sectionId,
    this.academicYearId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodayTimetableFilter &&
          other.sectionId == sectionId &&
          other.academicYearId == academicYearId;

  @override
  int get hashCode => Object.hash(sectionId, academicYearId);
}

class TeacherTimetableFilter {
  final String teacherId;
  final String? academicYearId;
  final int? dayOfWeek;

  const TeacherTimetableFilter({
    required this.teacherId,
    this.academicYearId,
    this.dayOfWeek,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherTimetableFilter &&
          other.teacherId == teacherId &&
          other.academicYearId == academicYearId &&
          other.dayOfWeek == dayOfWeek;

  @override
  int get hashCode => Object.hash(teacherId, academicYearId, dayOfWeek);
}

class TimetableNotifier extends StateNotifier<AsyncValue<WeeklyTimetable?>> {
  final TimetableRepository _repository;

  TimetableNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadWeeklyTimetable({
    required String sectionId,
    String? academicYearId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final timetable = await _repository.getWeeklyTimetable(
        sectionId: sectionId,
        academicYearId: academicYearId,
      );
      state = AsyncValue.data(timetable);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Timetable> createEntry(Map<String, dynamic> data) async {
    final entry = await _repository.createTimetableEntry(data);
    return entry;
  }

  Future<Timetable> updateEntry(String timetableId, Map<String, dynamic> data) async {
    final entry = await _repository.updateTimetableEntry(timetableId, data);
    return entry;
  }

  Future<void> deleteEntry(String timetableId) async {
    await _repository.deleteTimetableEntry(timetableId);
  }

  Future<void> copyTimetable({
    required String fromSectionId,
    required String toSectionId,
    required String academicYearId,
  }) async {
    await _repository.copyTimetable(
      fromSectionId: fromSectionId,
      toSectionId: toSectionId,
      academicYearId: academicYearId,
    );
  }
}

final timetableNotifierProvider =
    StateNotifierProvider<TimetableNotifier, AsyncValue<WeeklyTimetable?>>((ref) {
  final repository = ref.watch(timetableRepositoryProvider);
  return TimetableNotifier(repository);
});

final selectedDayProvider = StateProvider<int>((ref) => DateTime.now().weekday);

/// Provider for teacher's assigned classes (for My Classes screen)
final teacherClassesProvider = FutureProvider.family<List<TeacherClassInfo>, String>(
  (ref, teacherId) async {
    final repository = ref.watch(timetableRepositoryProvider);
    return repository.getTeacherClasses(teacherId);
  },
);
