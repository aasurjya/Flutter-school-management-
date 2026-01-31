import 'package:freezed_annotation/freezed_annotation.dart';

part 'timetable.freezed.dart';
part 'timetable.g.dart';

@freezed
class TimetableSlot with _$TimetableSlot {
  const factory TimetableSlot({
    required String id,
    required String tenantId,
    required String name,
    required String startTime,
    required String endTime,
    @Default('class') String slotType,
    required int sequenceOrder,
    DateTime? createdAt,
  }) = _TimetableSlot;

  factory TimetableSlot.fromJson(Map<String, dynamic> json) =>
      _$TimetableSlotFromJson(json);
}

@freezed
class Timetable with _$Timetable {
  const factory Timetable({
    required String id,
    required String tenantId,
    required String sectionId,
    String? subjectId,
    String? teacherId,
    required String slotId,
    required int dayOfWeek,
    String? roomNumber,
    required String academicYearId,
    DateTime? effectiveFrom,
    DateTime? effectiveUntil,
    DateTime? createdAt,
    // Joined data
    TimetableSlot? slot,
    String? subjectName,
    String? subjectCode,
    String? teacherName,
    String? sectionName,
    String? className,
  }) = _Timetable;

  factory Timetable.fromJson(Map<String, dynamic> json) =>
      _$TimetableFromJson(json);
}

@freezed
class TimetableEntry with _$TimetableEntry {
  const factory TimetableEntry({
    required String slotId,
    required String slotName,
    required String startTime,
    required String endTime,
    required String slotType,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    String? teacherId,
    String? teacherName,
    String? roomNumber,
    required int sequenceOrder,
  }) = _TimetableEntry;

  factory TimetableEntry.fromJson(Map<String, dynamic> json) =>
      _$TimetableEntryFromJson(json);
}

@freezed
class DayTimetable with _$DayTimetable {
  const factory DayTimetable({
    required int dayOfWeek,
    required String dayName,
    required List<TimetableEntry> entries,
  }) = _DayTimetable;

  factory DayTimetable.fromJson(Map<String, dynamic> json) =>
      _$DayTimetableFromJson(json);
}

@freezed
class WeeklyTimetable with _$WeeklyTimetable {
  const factory WeeklyTimetable({
    required String sectionId,
    required String sectionName,
    required String className,
    required String academicYearId,
    required List<DayTimetable> days,
  }) = _WeeklyTimetable;

  factory WeeklyTimetable.fromJson(Map<String, dynamic> json) =>
      _$WeeklyTimetableFromJson(json);
}

extension TimetableHelpers on Timetable {
  String get dayName {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek];
  }
}
