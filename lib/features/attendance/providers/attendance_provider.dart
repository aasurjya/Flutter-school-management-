import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/attendance.dart';
import '../../../data/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(Supabase.instance.client);
});

final sectionAttendanceProvider = FutureProvider.family<List<Attendance>, SectionDateFilter>(
  (ref, filter) async {
    final repository = ref.watch(attendanceRepositoryProvider);
    return repository.getAttendanceBySection(
      sectionId: filter.sectionId,
      date: filter.date,
    );
  },
);

final studentAttendanceProvider = FutureProvider.family<List<Attendance>, StudentAttendanceFilter>(
  (ref, filter) async {
    final repository = ref.watch(attendanceRepositoryProvider);
    return repository.getStudentAttendance(
      studentId: filter.studentId,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
  },
);

final attendanceSummaryProvider = FutureProvider.family<List<Map<String, dynamic>>, AttendanceSummaryFilter>(
  (ref, filter) async {
    final repository = ref.watch(attendanceRepositoryProvider);
    return repository.getAttendanceSummary(
      studentId: filter.studentId,
      year: filter.year,
    );
  },
);

final attendanceStatsProvider = FutureProvider.family<Map<String, int>, String>(
  (ref, studentId) async {
    final repository = ref.watch(attendanceRepositoryProvider);
    return repository.getAttendanceStats(studentId: studentId);
  },
);

final todayAttendancePercentageProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getTodayAttendancePercentage();
});

final sectionDailyAttendanceProvider = FutureProvider.family<Map<String, dynamic>?, SectionDateFilter>(
  (ref, filter) async {
    final repository = ref.watch(attendanceRepositoryProvider);
    return repository.getSectionDailyAttendance(
      sectionId: filter.sectionId,
      date: filter.date,
    );
  },
);

class SectionDateFilter {
  final String sectionId;
  final DateTime date;

  const SectionDateFilter({
    required this.sectionId,
    required this.date,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SectionDateFilter &&
        other.sectionId == sectionId &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day;
  }

  @override
  int get hashCode => Object.hash(sectionId, date.year, date.month, date.day);
}

class StudentAttendanceFilter {
  final String studentId;
  final DateTime? startDate;
  final DateTime? endDate;

  const StudentAttendanceFilter({
    required this.studentId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentAttendanceFilter &&
        other.studentId == studentId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(studentId, startDate, endDate);
}

class AttendanceSummaryFilter {
  final String studentId;
  final int? year;

  const AttendanceSummaryFilter({
    required this.studentId,
    this.year,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceSummaryFilter &&
        other.studentId == studentId &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(studentId, year);
}

class AttendanceNotifier extends StateNotifier<AsyncValue<List<Attendance>>> {
  final AttendanceRepository _repository;
  String? _currentSectionId;
  DateTime? _currentDate;

  AttendanceNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadAttendance({
    required String sectionId,
    required DateTime date,
  }) async {
    _currentSectionId = sectionId;
    _currentDate = date;
    state = const AsyncValue.loading();
    try {
      final attendance = await _repository.getAttendanceBySection(
        sectionId: sectionId,
        date: date,
      );
      state = AsyncValue.data(attendance);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAttendance({
    required String studentId,
    required String status,
    String? remarks,
  }) async {
    if (_currentSectionId == null || _currentDate == null) return;

    await _repository.markAttendance(
      studentId: studentId,
      sectionId: _currentSectionId!,
      date: _currentDate!,
      status: status,
      remarks: remarks,
    );
    await loadAttendance(sectionId: _currentSectionId!, date: _currentDate!);
  }

  Future<void> markBulkAttendance(List<Map<String, dynamic>> records) async {
    if (_currentSectionId == null || _currentDate == null) return;

    await _repository.markBulkAttendance(
      sectionId: _currentSectionId!,
      date: _currentDate!,
      attendanceRecords: records,
    );
    await loadAttendance(sectionId: _currentSectionId!, date: _currentDate!);
  }

  Future<void> updateAttendance({
    required String attendanceId,
    required String status,
    String? remarks,
  }) async {
    await _repository.updateAttendance(
      attendanceId: attendanceId,
      status: status,
      remarks: remarks,
    );
    if (_currentSectionId != null && _currentDate != null) {
      await loadAttendance(sectionId: _currentSectionId!, date: _currentDate!);
    }
  }
}

final attendanceNotifierProvider =
    StateNotifierProvider<AttendanceNotifier, AsyncValue<List<Attendance>>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return AttendanceNotifier(repository);
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
