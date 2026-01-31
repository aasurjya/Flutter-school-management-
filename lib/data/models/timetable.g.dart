// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TimetableSlotImpl _$$TimetableSlotImplFromJson(Map<String, dynamic> json) =>
    _$TimetableSlotImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      name: json['name'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      slotType: json['slotType'] as String? ?? 'class',
      sequenceOrder: (json['sequenceOrder'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$TimetableSlotImplToJson(_$TimetableSlotImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'name': instance.name,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'slotType': instance.slotType,
      'sequenceOrder': instance.sequenceOrder,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$TimetableImpl _$$TimetableImplFromJson(Map<String, dynamic> json) =>
    _$TimetableImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      sectionId: json['sectionId'] as String,
      subjectId: json['subjectId'] as String?,
      teacherId: json['teacherId'] as String?,
      slotId: json['slotId'] as String,
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      roomNumber: json['roomNumber'] as String?,
      academicYearId: json['academicYearId'] as String,
      effectiveFrom: json['effectiveFrom'] == null
          ? null
          : DateTime.parse(json['effectiveFrom'] as String),
      effectiveUntil: json['effectiveUntil'] == null
          ? null
          : DateTime.parse(json['effectiveUntil'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      slot: json['slot'] == null
          ? null
          : TimetableSlot.fromJson(json['slot'] as Map<String, dynamic>),
      subjectName: json['subjectName'] as String?,
      subjectCode: json['subjectCode'] as String?,
      teacherName: json['teacherName'] as String?,
      sectionName: json['sectionName'] as String?,
      className: json['className'] as String?,
    );

Map<String, dynamic> _$$TimetableImplToJson(_$TimetableImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'sectionId': instance.sectionId,
      'subjectId': instance.subjectId,
      'teacherId': instance.teacherId,
      'slotId': instance.slotId,
      'dayOfWeek': instance.dayOfWeek,
      'roomNumber': instance.roomNumber,
      'academicYearId': instance.academicYearId,
      'effectiveFrom': instance.effectiveFrom?.toIso8601String(),
      'effectiveUntil': instance.effectiveUntil?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'slot': instance.slot,
      'subjectName': instance.subjectName,
      'subjectCode': instance.subjectCode,
      'teacherName': instance.teacherName,
      'sectionName': instance.sectionName,
      'className': instance.className,
    };

_$TimetableEntryImpl _$$TimetableEntryImplFromJson(Map<String, dynamic> json) =>
    _$TimetableEntryImpl(
      slotId: json['slotId'] as String,
      slotName: json['slotName'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      slotType: json['slotType'] as String,
      subjectId: json['subjectId'] as String?,
      subjectName: json['subjectName'] as String?,
      subjectCode: json['subjectCode'] as String?,
      teacherId: json['teacherId'] as String?,
      teacherName: json['teacherName'] as String?,
      roomNumber: json['roomNumber'] as String?,
      sequenceOrder: (json['sequenceOrder'] as num).toInt(),
    );

Map<String, dynamic> _$$TimetableEntryImplToJson(
        _$TimetableEntryImpl instance) =>
    <String, dynamic>{
      'slotId': instance.slotId,
      'slotName': instance.slotName,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'slotType': instance.slotType,
      'subjectId': instance.subjectId,
      'subjectName': instance.subjectName,
      'subjectCode': instance.subjectCode,
      'teacherId': instance.teacherId,
      'teacherName': instance.teacherName,
      'roomNumber': instance.roomNumber,
      'sequenceOrder': instance.sequenceOrder,
    };

_$DayTimetableImpl _$$DayTimetableImplFromJson(Map<String, dynamic> json) =>
    _$DayTimetableImpl(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      dayName: json['dayName'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$DayTimetableImplToJson(_$DayTimetableImpl instance) =>
    <String, dynamic>{
      'dayOfWeek': instance.dayOfWeek,
      'dayName': instance.dayName,
      'entries': instance.entries,
    };

_$WeeklyTimetableImpl _$$WeeklyTimetableImplFromJson(
        Map<String, dynamic> json) =>
    _$WeeklyTimetableImpl(
      sectionId: json['sectionId'] as String,
      sectionName: json['sectionName'] as String,
      className: json['className'] as String,
      academicYearId: json['academicYearId'] as String,
      days: (json['days'] as List<dynamic>)
          .map((e) => DayTimetable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$WeeklyTimetableImplToJson(
        _$WeeklyTimetableImpl instance) =>
    <String, dynamic>{
      'sectionId': instance.sectionId,
      'sectionName': instance.sectionName,
      'className': instance.className,
      'academicYearId': instance.academicYearId,
      'days': instance.days,
    };
