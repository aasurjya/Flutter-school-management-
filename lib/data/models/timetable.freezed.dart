// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timetable.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TimetableSlot _$TimetableSlotFromJson(Map<String, dynamic> json) {
  return _TimetableSlot.fromJson(json);
}

/// @nodoc
mixin _$TimetableSlot {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get startTime => throw _privateConstructorUsedError;
  String get endTime => throw _privateConstructorUsedError;
  String get slotType => throw _privateConstructorUsedError;
  int get sequenceOrder => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TimetableSlotCopyWith<TimetableSlot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimetableSlotCopyWith<$Res> {
  factory $TimetableSlotCopyWith(
          TimetableSlot value, $Res Function(TimetableSlot) then) =
      _$TimetableSlotCopyWithImpl<$Res, TimetableSlot>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String name,
      String startTime,
      String endTime,
      String slotType,
      int sequenceOrder,
      DateTime? createdAt});
}

/// @nodoc
class _$TimetableSlotCopyWithImpl<$Res, $Val extends TimetableSlot>
    implements $TimetableSlotCopyWith<$Res> {
  _$TimetableSlotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? name = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? slotType = null,
    Object? sequenceOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      slotType: null == slotType
          ? _value.slotType
          : slotType // ignore: cast_nullable_to_non_nullable
              as String,
      sequenceOrder: null == sequenceOrder
          ? _value.sequenceOrder
          : sequenceOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TimetableSlotImplCopyWith<$Res>
    implements $TimetableSlotCopyWith<$Res> {
  factory _$$TimetableSlotImplCopyWith(
          _$TimetableSlotImpl value, $Res Function(_$TimetableSlotImpl) then) =
      __$$TimetableSlotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String name,
      String startTime,
      String endTime,
      String slotType,
      int sequenceOrder,
      DateTime? createdAt});
}

/// @nodoc
class __$$TimetableSlotImplCopyWithImpl<$Res>
    extends _$TimetableSlotCopyWithImpl<$Res, _$TimetableSlotImpl>
    implements _$$TimetableSlotImplCopyWith<$Res> {
  __$$TimetableSlotImplCopyWithImpl(
      _$TimetableSlotImpl _value, $Res Function(_$TimetableSlotImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? name = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? slotType = null,
    Object? sequenceOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$TimetableSlotImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      slotType: null == slotType
          ? _value.slotType
          : slotType // ignore: cast_nullable_to_non_nullable
              as String,
      sequenceOrder: null == sequenceOrder
          ? _value.sequenceOrder
          : sequenceOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimetableSlotImpl implements _TimetableSlot {
  const _$TimetableSlotImpl(
      {required this.id,
      required this.tenantId,
      required this.name,
      required this.startTime,
      required this.endTime,
      this.slotType = 'class',
      required this.sequenceOrder,
      this.createdAt});

  factory _$TimetableSlotImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimetableSlotImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String name;
  @override
  final String startTime;
  @override
  final String endTime;
  @override
  @JsonKey()
  final String slotType;
  @override
  final int sequenceOrder;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'TimetableSlot(id: $id, tenantId: $tenantId, name: $name, startTime: $startTime, endTime: $endTime, slotType: $slotType, sequenceOrder: $sequenceOrder, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimetableSlotImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.slotType, slotType) ||
                other.slotType == slotType) &&
            (identical(other.sequenceOrder, sequenceOrder) ||
                other.sequenceOrder == sequenceOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, tenantId, name, startTime,
      endTime, slotType, sequenceOrder, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TimetableSlotImplCopyWith<_$TimetableSlotImpl> get copyWith =>
      __$$TimetableSlotImplCopyWithImpl<_$TimetableSlotImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimetableSlotImplToJson(
      this,
    );
  }
}

abstract class _TimetableSlot implements TimetableSlot {
  const factory _TimetableSlot(
      {required final String id,
      required final String tenantId,
      required final String name,
      required final String startTime,
      required final String endTime,
      final String slotType,
      required final int sequenceOrder,
      final DateTime? createdAt}) = _$TimetableSlotImpl;

  factory _TimetableSlot.fromJson(Map<String, dynamic> json) =
      _$TimetableSlotImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get name;
  @override
  String get startTime;
  @override
  String get endTime;
  @override
  String get slotType;
  @override
  int get sequenceOrder;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$TimetableSlotImplCopyWith<_$TimetableSlotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Timetable _$TimetableFromJson(Map<String, dynamic> json) {
  return _Timetable.fromJson(json);
}

/// @nodoc
mixin _$Timetable {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String? get subjectId => throw _privateConstructorUsedError;
  String? get teacherId => throw _privateConstructorUsedError;
  String get slotId => throw _privateConstructorUsedError;
  int get dayOfWeek => throw _privateConstructorUsedError;
  String? get roomNumber => throw _privateConstructorUsedError;
  String get academicYearId => throw _privateConstructorUsedError;
  DateTime? get effectiveFrom => throw _privateConstructorUsedError;
  DateTime? get effectiveUntil => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError; // Joined data
  TimetableSlot? get slot => throw _privateConstructorUsedError;
  String? get subjectName => throw _privateConstructorUsedError;
  String? get subjectCode => throw _privateConstructorUsedError;
  String? get teacherName => throw _privateConstructorUsedError;
  String? get sectionName => throw _privateConstructorUsedError;
  String? get className => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TimetableCopyWith<Timetable> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimetableCopyWith<$Res> {
  factory $TimetableCopyWith(Timetable value, $Res Function(Timetable) then) =
      _$TimetableCopyWithImpl<$Res, Timetable>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String sectionId,
      String? subjectId,
      String? teacherId,
      String slotId,
      int dayOfWeek,
      String? roomNumber,
      String academicYearId,
      DateTime? effectiveFrom,
      DateTime? effectiveUntil,
      DateTime? createdAt,
      TimetableSlot? slot,
      String? subjectName,
      String? subjectCode,
      String? teacherName,
      String? sectionName,
      String? className});

  $TimetableSlotCopyWith<$Res>? get slot;
}

/// @nodoc
class _$TimetableCopyWithImpl<$Res, $Val extends Timetable>
    implements $TimetableCopyWith<$Res> {
  _$TimetableCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? sectionId = null,
    Object? subjectId = freezed,
    Object? teacherId = freezed,
    Object? slotId = null,
    Object? dayOfWeek = null,
    Object? roomNumber = freezed,
    Object? academicYearId = null,
    Object? effectiveFrom = freezed,
    Object? effectiveUntil = freezed,
    Object? createdAt = freezed,
    Object? slot = freezed,
    Object? subjectName = freezed,
    Object? subjectCode = freezed,
    Object? teacherName = freezed,
    Object? sectionName = freezed,
    Object? className = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: freezed == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String?,
      teacherId: freezed == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as String?,
      slotId: null == slotId
          ? _value.slotId
          : slotId // ignore: cast_nullable_to_non_nullable
              as String,
      dayOfWeek: null == dayOfWeek
          ? _value.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as int,
      roomNumber: freezed == roomNumber
          ? _value.roomNumber
          : roomNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      effectiveFrom: freezed == effectiveFrom
          ? _value.effectiveFrom
          : effectiveFrom // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      effectiveUntil: freezed == effectiveUntil
          ? _value.effectiveUntil
          : effectiveUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      slot: freezed == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as TimetableSlot?,
      subjectName: freezed == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectCode: freezed == subjectCode
          ? _value.subjectCode
          : subjectCode // ignore: cast_nullable_to_non_nullable
              as String?,
      teacherName: freezed == teacherName
          ? _value.teacherName
          : teacherName // ignore: cast_nullable_to_non_nullable
              as String?,
      sectionName: freezed == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String?,
      className: freezed == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $TimetableSlotCopyWith<$Res>? get slot {
    if (_value.slot == null) {
      return null;
    }

    return $TimetableSlotCopyWith<$Res>(_value.slot!, (value) {
      return _then(_value.copyWith(slot: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TimetableImplCopyWith<$Res>
    implements $TimetableCopyWith<$Res> {
  factory _$$TimetableImplCopyWith(
          _$TimetableImpl value, $Res Function(_$TimetableImpl) then) =
      __$$TimetableImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String sectionId,
      String? subjectId,
      String? teacherId,
      String slotId,
      int dayOfWeek,
      String? roomNumber,
      String academicYearId,
      DateTime? effectiveFrom,
      DateTime? effectiveUntil,
      DateTime? createdAt,
      TimetableSlot? slot,
      String? subjectName,
      String? subjectCode,
      String? teacherName,
      String? sectionName,
      String? className});

  @override
  $TimetableSlotCopyWith<$Res>? get slot;
}

/// @nodoc
class __$$TimetableImplCopyWithImpl<$Res>
    extends _$TimetableCopyWithImpl<$Res, _$TimetableImpl>
    implements _$$TimetableImplCopyWith<$Res> {
  __$$TimetableImplCopyWithImpl(
      _$TimetableImpl _value, $Res Function(_$TimetableImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? sectionId = null,
    Object? subjectId = freezed,
    Object? teacherId = freezed,
    Object? slotId = null,
    Object? dayOfWeek = null,
    Object? roomNumber = freezed,
    Object? academicYearId = null,
    Object? effectiveFrom = freezed,
    Object? effectiveUntil = freezed,
    Object? createdAt = freezed,
    Object? slot = freezed,
    Object? subjectName = freezed,
    Object? subjectCode = freezed,
    Object? teacherName = freezed,
    Object? sectionName = freezed,
    Object? className = freezed,
  }) {
    return _then(_$TimetableImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: freezed == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String?,
      teacherId: freezed == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as String?,
      slotId: null == slotId
          ? _value.slotId
          : slotId // ignore: cast_nullable_to_non_nullable
              as String,
      dayOfWeek: null == dayOfWeek
          ? _value.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as int,
      roomNumber: freezed == roomNumber
          ? _value.roomNumber
          : roomNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      effectiveFrom: freezed == effectiveFrom
          ? _value.effectiveFrom
          : effectiveFrom // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      effectiveUntil: freezed == effectiveUntil
          ? _value.effectiveUntil
          : effectiveUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      slot: freezed == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as TimetableSlot?,
      subjectName: freezed == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectCode: freezed == subjectCode
          ? _value.subjectCode
          : subjectCode // ignore: cast_nullable_to_non_nullable
              as String?,
      teacherName: freezed == teacherName
          ? _value.teacherName
          : teacherName // ignore: cast_nullable_to_non_nullable
              as String?,
      sectionName: freezed == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String?,
      className: freezed == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimetableImpl implements _Timetable {
  const _$TimetableImpl(
      {required this.id,
      required this.tenantId,
      required this.sectionId,
      this.subjectId,
      this.teacherId,
      required this.slotId,
      required this.dayOfWeek,
      this.roomNumber,
      required this.academicYearId,
      this.effectiveFrom,
      this.effectiveUntil,
      this.createdAt,
      this.slot,
      this.subjectName,
      this.subjectCode,
      this.teacherName,
      this.sectionName,
      this.className});

  factory _$TimetableImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimetableImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String sectionId;
  @override
  final String? subjectId;
  @override
  final String? teacherId;
  @override
  final String slotId;
  @override
  final int dayOfWeek;
  @override
  final String? roomNumber;
  @override
  final String academicYearId;
  @override
  final DateTime? effectiveFrom;
  @override
  final DateTime? effectiveUntil;
  @override
  final DateTime? createdAt;
// Joined data
  @override
  final TimetableSlot? slot;
  @override
  final String? subjectName;
  @override
  final String? subjectCode;
  @override
  final String? teacherName;
  @override
  final String? sectionName;
  @override
  final String? className;

  @override
  String toString() {
    return 'Timetable(id: $id, tenantId: $tenantId, sectionId: $sectionId, subjectId: $subjectId, teacherId: $teacherId, slotId: $slotId, dayOfWeek: $dayOfWeek, roomNumber: $roomNumber, academicYearId: $academicYearId, effectiveFrom: $effectiveFrom, effectiveUntil: $effectiveUntil, createdAt: $createdAt, slot: $slot, subjectName: $subjectName, subjectCode: $subjectCode, teacherName: $teacherName, sectionName: $sectionName, className: $className)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimetableImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.teacherId, teacherId) ||
                other.teacherId == teacherId) &&
            (identical(other.slotId, slotId) || other.slotId == slotId) &&
            (identical(other.dayOfWeek, dayOfWeek) ||
                other.dayOfWeek == dayOfWeek) &&
            (identical(other.roomNumber, roomNumber) ||
                other.roomNumber == roomNumber) &&
            (identical(other.academicYearId, academicYearId) ||
                other.academicYearId == academicYearId) &&
            (identical(other.effectiveFrom, effectiveFrom) ||
                other.effectiveFrom == effectiveFrom) &&
            (identical(other.effectiveUntil, effectiveUntil) ||
                other.effectiveUntil == effectiveUntil) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.slot, slot) || other.slot == slot) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.subjectCode, subjectCode) ||
                other.subjectCode == subjectCode) &&
            (identical(other.teacherName, teacherName) ||
                other.teacherName == teacherName) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.className, className) ||
                other.className == className));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      sectionId,
      subjectId,
      teacherId,
      slotId,
      dayOfWeek,
      roomNumber,
      academicYearId,
      effectiveFrom,
      effectiveUntil,
      createdAt,
      slot,
      subjectName,
      subjectCode,
      teacherName,
      sectionName,
      className);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TimetableImplCopyWith<_$TimetableImpl> get copyWith =>
      __$$TimetableImplCopyWithImpl<_$TimetableImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimetableImplToJson(
      this,
    );
  }
}

abstract class _Timetable implements Timetable {
  const factory _Timetable(
      {required final String id,
      required final String tenantId,
      required final String sectionId,
      final String? subjectId,
      final String? teacherId,
      required final String slotId,
      required final int dayOfWeek,
      final String? roomNumber,
      required final String academicYearId,
      final DateTime? effectiveFrom,
      final DateTime? effectiveUntil,
      final DateTime? createdAt,
      final TimetableSlot? slot,
      final String? subjectName,
      final String? subjectCode,
      final String? teacherName,
      final String? sectionName,
      final String? className}) = _$TimetableImpl;

  factory _Timetable.fromJson(Map<String, dynamic> json) =
      _$TimetableImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get sectionId;
  @override
  String? get subjectId;
  @override
  String? get teacherId;
  @override
  String get slotId;
  @override
  int get dayOfWeek;
  @override
  String? get roomNumber;
  @override
  String get academicYearId;
  @override
  DateTime? get effectiveFrom;
  @override
  DateTime? get effectiveUntil;
  @override
  DateTime? get createdAt;
  @override // Joined data
  TimetableSlot? get slot;
  @override
  String? get subjectName;
  @override
  String? get subjectCode;
  @override
  String? get teacherName;
  @override
  String? get sectionName;
  @override
  String? get className;
  @override
  @JsonKey(ignore: true)
  _$$TimetableImplCopyWith<_$TimetableImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TimetableEntry _$TimetableEntryFromJson(Map<String, dynamic> json) {
  return _TimetableEntry.fromJson(json);
}

/// @nodoc
mixin _$TimetableEntry {
  String get slotId => throw _privateConstructorUsedError;
  String get slotName => throw _privateConstructorUsedError;
  String get startTime => throw _privateConstructorUsedError;
  String get endTime => throw _privateConstructorUsedError;
  String get slotType => throw _privateConstructorUsedError;
  String? get subjectId => throw _privateConstructorUsedError;
  String? get subjectName => throw _privateConstructorUsedError;
  String? get subjectCode => throw _privateConstructorUsedError;
  String? get teacherId => throw _privateConstructorUsedError;
  String? get teacherName => throw _privateConstructorUsedError;
  String? get roomNumber => throw _privateConstructorUsedError;
  int get sequenceOrder => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TimetableEntryCopyWith<TimetableEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimetableEntryCopyWith<$Res> {
  factory $TimetableEntryCopyWith(
          TimetableEntry value, $Res Function(TimetableEntry) then) =
      _$TimetableEntryCopyWithImpl<$Res, TimetableEntry>;
  @useResult
  $Res call(
      {String slotId,
      String slotName,
      String startTime,
      String endTime,
      String slotType,
      String? subjectId,
      String? subjectName,
      String? subjectCode,
      String? teacherId,
      String? teacherName,
      String? roomNumber,
      int sequenceOrder});
}

/// @nodoc
class _$TimetableEntryCopyWithImpl<$Res, $Val extends TimetableEntry>
    implements $TimetableEntryCopyWith<$Res> {
  _$TimetableEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slotId = null,
    Object? slotName = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? slotType = null,
    Object? subjectId = freezed,
    Object? subjectName = freezed,
    Object? subjectCode = freezed,
    Object? teacherId = freezed,
    Object? teacherName = freezed,
    Object? roomNumber = freezed,
    Object? sequenceOrder = null,
  }) {
    return _then(_value.copyWith(
      slotId: null == slotId
          ? _value.slotId
          : slotId // ignore: cast_nullable_to_non_nullable
              as String,
      slotName: null == slotName
          ? _value.slotName
          : slotName // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      slotType: null == slotType
          ? _value.slotType
          : slotType // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: freezed == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectName: freezed == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectCode: freezed == subjectCode
          ? _value.subjectCode
          : subjectCode // ignore: cast_nullable_to_non_nullable
              as String?,
      teacherId: freezed == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as String?,
      teacherName: freezed == teacherName
          ? _value.teacherName
          : teacherName // ignore: cast_nullable_to_non_nullable
              as String?,
      roomNumber: freezed == roomNumber
          ? _value.roomNumber
          : roomNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      sequenceOrder: null == sequenceOrder
          ? _value.sequenceOrder
          : sequenceOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TimetableEntryImplCopyWith<$Res>
    implements $TimetableEntryCopyWith<$Res> {
  factory _$$TimetableEntryImplCopyWith(_$TimetableEntryImpl value,
          $Res Function(_$TimetableEntryImpl) then) =
      __$$TimetableEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String slotId,
      String slotName,
      String startTime,
      String endTime,
      String slotType,
      String? subjectId,
      String? subjectName,
      String? subjectCode,
      String? teacherId,
      String? teacherName,
      String? roomNumber,
      int sequenceOrder});
}

/// @nodoc
class __$$TimetableEntryImplCopyWithImpl<$Res>
    extends _$TimetableEntryCopyWithImpl<$Res, _$TimetableEntryImpl>
    implements _$$TimetableEntryImplCopyWith<$Res> {
  __$$TimetableEntryImplCopyWithImpl(
      _$TimetableEntryImpl _value, $Res Function(_$TimetableEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slotId = null,
    Object? slotName = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? slotType = null,
    Object? subjectId = freezed,
    Object? subjectName = freezed,
    Object? subjectCode = freezed,
    Object? teacherId = freezed,
    Object? teacherName = freezed,
    Object? roomNumber = freezed,
    Object? sequenceOrder = null,
  }) {
    return _then(_$TimetableEntryImpl(
      slotId: null == slotId
          ? _value.slotId
          : slotId // ignore: cast_nullable_to_non_nullable
              as String,
      slotName: null == slotName
          ? _value.slotName
          : slotName // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      slotType: null == slotType
          ? _value.slotType
          : slotType // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: freezed == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectName: freezed == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectCode: freezed == subjectCode
          ? _value.subjectCode
          : subjectCode // ignore: cast_nullable_to_non_nullable
              as String?,
      teacherId: freezed == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as String?,
      teacherName: freezed == teacherName
          ? _value.teacherName
          : teacherName // ignore: cast_nullable_to_non_nullable
              as String?,
      roomNumber: freezed == roomNumber
          ? _value.roomNumber
          : roomNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      sequenceOrder: null == sequenceOrder
          ? _value.sequenceOrder
          : sequenceOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimetableEntryImpl implements _TimetableEntry {
  const _$TimetableEntryImpl(
      {required this.slotId,
      required this.slotName,
      required this.startTime,
      required this.endTime,
      required this.slotType,
      this.subjectId,
      this.subjectName,
      this.subjectCode,
      this.teacherId,
      this.teacherName,
      this.roomNumber,
      required this.sequenceOrder});

  factory _$TimetableEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimetableEntryImplFromJson(json);

  @override
  final String slotId;
  @override
  final String slotName;
  @override
  final String startTime;
  @override
  final String endTime;
  @override
  final String slotType;
  @override
  final String? subjectId;
  @override
  final String? subjectName;
  @override
  final String? subjectCode;
  @override
  final String? teacherId;
  @override
  final String? teacherName;
  @override
  final String? roomNumber;
  @override
  final int sequenceOrder;

  @override
  String toString() {
    return 'TimetableEntry(slotId: $slotId, slotName: $slotName, startTime: $startTime, endTime: $endTime, slotType: $slotType, subjectId: $subjectId, subjectName: $subjectName, subjectCode: $subjectCode, teacherId: $teacherId, teacherName: $teacherName, roomNumber: $roomNumber, sequenceOrder: $sequenceOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimetableEntryImpl &&
            (identical(other.slotId, slotId) || other.slotId == slotId) &&
            (identical(other.slotName, slotName) ||
                other.slotName == slotName) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.slotType, slotType) ||
                other.slotType == slotType) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.subjectCode, subjectCode) ||
                other.subjectCode == subjectCode) &&
            (identical(other.teacherId, teacherId) ||
                other.teacherId == teacherId) &&
            (identical(other.teacherName, teacherName) ||
                other.teacherName == teacherName) &&
            (identical(other.roomNumber, roomNumber) ||
                other.roomNumber == roomNumber) &&
            (identical(other.sequenceOrder, sequenceOrder) ||
                other.sequenceOrder == sequenceOrder));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      slotId,
      slotName,
      startTime,
      endTime,
      slotType,
      subjectId,
      subjectName,
      subjectCode,
      teacherId,
      teacherName,
      roomNumber,
      sequenceOrder);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TimetableEntryImplCopyWith<_$TimetableEntryImpl> get copyWith =>
      __$$TimetableEntryImplCopyWithImpl<_$TimetableEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimetableEntryImplToJson(
      this,
    );
  }
}

abstract class _TimetableEntry implements TimetableEntry {
  const factory _TimetableEntry(
      {required final String slotId,
      required final String slotName,
      required final String startTime,
      required final String endTime,
      required final String slotType,
      final String? subjectId,
      final String? subjectName,
      final String? subjectCode,
      final String? teacherId,
      final String? teacherName,
      final String? roomNumber,
      required final int sequenceOrder}) = _$TimetableEntryImpl;

  factory _TimetableEntry.fromJson(Map<String, dynamic> json) =
      _$TimetableEntryImpl.fromJson;

  @override
  String get slotId;
  @override
  String get slotName;
  @override
  String get startTime;
  @override
  String get endTime;
  @override
  String get slotType;
  @override
  String? get subjectId;
  @override
  String? get subjectName;
  @override
  String? get subjectCode;
  @override
  String? get teacherId;
  @override
  String? get teacherName;
  @override
  String? get roomNumber;
  @override
  int get sequenceOrder;
  @override
  @JsonKey(ignore: true)
  _$$TimetableEntryImplCopyWith<_$TimetableEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DayTimetable _$DayTimetableFromJson(Map<String, dynamic> json) {
  return _DayTimetable.fromJson(json);
}

/// @nodoc
mixin _$DayTimetable {
  int get dayOfWeek => throw _privateConstructorUsedError;
  String get dayName => throw _privateConstructorUsedError;
  List<TimetableEntry> get entries => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DayTimetableCopyWith<DayTimetable> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DayTimetableCopyWith<$Res> {
  factory $DayTimetableCopyWith(
          DayTimetable value, $Res Function(DayTimetable) then) =
      _$DayTimetableCopyWithImpl<$Res, DayTimetable>;
  @useResult
  $Res call({int dayOfWeek, String dayName, List<TimetableEntry> entries});
}

/// @nodoc
class _$DayTimetableCopyWithImpl<$Res, $Val extends DayTimetable>
    implements $DayTimetableCopyWith<$Res> {
  _$DayTimetableCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayOfWeek = null,
    Object? dayName = null,
    Object? entries = null,
  }) {
    return _then(_value.copyWith(
      dayOfWeek: null == dayOfWeek
          ? _value.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as int,
      dayName: null == dayName
          ? _value.dayName
          : dayName // ignore: cast_nullable_to_non_nullable
              as String,
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<TimetableEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DayTimetableImplCopyWith<$Res>
    implements $DayTimetableCopyWith<$Res> {
  factory _$$DayTimetableImplCopyWith(
          _$DayTimetableImpl value, $Res Function(_$DayTimetableImpl) then) =
      __$$DayTimetableImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int dayOfWeek, String dayName, List<TimetableEntry> entries});
}

/// @nodoc
class __$$DayTimetableImplCopyWithImpl<$Res>
    extends _$DayTimetableCopyWithImpl<$Res, _$DayTimetableImpl>
    implements _$$DayTimetableImplCopyWith<$Res> {
  __$$DayTimetableImplCopyWithImpl(
      _$DayTimetableImpl _value, $Res Function(_$DayTimetableImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayOfWeek = null,
    Object? dayName = null,
    Object? entries = null,
  }) {
    return _then(_$DayTimetableImpl(
      dayOfWeek: null == dayOfWeek
          ? _value.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as int,
      dayName: null == dayName
          ? _value.dayName
          : dayName // ignore: cast_nullable_to_non_nullable
              as String,
      entries: null == entries
          ? _value._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<TimetableEntry>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DayTimetableImpl implements _DayTimetable {
  const _$DayTimetableImpl(
      {required this.dayOfWeek,
      required this.dayName,
      required final List<TimetableEntry> entries})
      : _entries = entries;

  factory _$DayTimetableImpl.fromJson(Map<String, dynamic> json) =>
      _$$DayTimetableImplFromJson(json);

  @override
  final int dayOfWeek;
  @override
  final String dayName;
  final List<TimetableEntry> _entries;
  @override
  List<TimetableEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  @override
  String toString() {
    return 'DayTimetable(dayOfWeek: $dayOfWeek, dayName: $dayName, entries: $entries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DayTimetableImpl &&
            (identical(other.dayOfWeek, dayOfWeek) ||
                other.dayOfWeek == dayOfWeek) &&
            (identical(other.dayName, dayName) || other.dayName == dayName) &&
            const DeepCollectionEquality().equals(other._entries, _entries));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, dayOfWeek, dayName,
      const DeepCollectionEquality().hash(_entries));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DayTimetableImplCopyWith<_$DayTimetableImpl> get copyWith =>
      __$$DayTimetableImplCopyWithImpl<_$DayTimetableImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DayTimetableImplToJson(
      this,
    );
  }
}

abstract class _DayTimetable implements DayTimetable {
  const factory _DayTimetable(
      {required final int dayOfWeek,
      required final String dayName,
      required final List<TimetableEntry> entries}) = _$DayTimetableImpl;

  factory _DayTimetable.fromJson(Map<String, dynamic> json) =
      _$DayTimetableImpl.fromJson;

  @override
  int get dayOfWeek;
  @override
  String get dayName;
  @override
  List<TimetableEntry> get entries;
  @override
  @JsonKey(ignore: true)
  _$$DayTimetableImplCopyWith<_$DayTimetableImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WeeklyTimetable _$WeeklyTimetableFromJson(Map<String, dynamic> json) {
  return _WeeklyTimetable.fromJson(json);
}

/// @nodoc
mixin _$WeeklyTimetable {
  String get sectionId => throw _privateConstructorUsedError;
  String get sectionName => throw _privateConstructorUsedError;
  String get className => throw _privateConstructorUsedError;
  String get academicYearId => throw _privateConstructorUsedError;
  List<DayTimetable> get days => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WeeklyTimetableCopyWith<WeeklyTimetable> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeeklyTimetableCopyWith<$Res> {
  factory $WeeklyTimetableCopyWith(
          WeeklyTimetable value, $Res Function(WeeklyTimetable) then) =
      _$WeeklyTimetableCopyWithImpl<$Res, WeeklyTimetable>;
  @useResult
  $Res call(
      {String sectionId,
      String sectionName,
      String className,
      String academicYearId,
      List<DayTimetable> days});
}

/// @nodoc
class _$WeeklyTimetableCopyWithImpl<$Res, $Val extends WeeklyTimetable>
    implements $WeeklyTimetableCopyWith<$Res> {
  _$WeeklyTimetableCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sectionId = null,
    Object? sectionName = null,
    Object? className = null,
    Object? academicYearId = null,
    Object? days = null,
  }) {
    return _then(_value.copyWith(
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      days: null == days
          ? _value.days
          : days // ignore: cast_nullable_to_non_nullable
              as List<DayTimetable>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WeeklyTimetableImplCopyWith<$Res>
    implements $WeeklyTimetableCopyWith<$Res> {
  factory _$$WeeklyTimetableImplCopyWith(_$WeeklyTimetableImpl value,
          $Res Function(_$WeeklyTimetableImpl) then) =
      __$$WeeklyTimetableImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sectionId,
      String sectionName,
      String className,
      String academicYearId,
      List<DayTimetable> days});
}

/// @nodoc
class __$$WeeklyTimetableImplCopyWithImpl<$Res>
    extends _$WeeklyTimetableCopyWithImpl<$Res, _$WeeklyTimetableImpl>
    implements _$$WeeklyTimetableImplCopyWith<$Res> {
  __$$WeeklyTimetableImplCopyWithImpl(
      _$WeeklyTimetableImpl _value, $Res Function(_$WeeklyTimetableImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sectionId = null,
    Object? sectionName = null,
    Object? className = null,
    Object? academicYearId = null,
    Object? days = null,
  }) {
    return _then(_$WeeklyTimetableImpl(
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      days: null == days
          ? _value._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<DayTimetable>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WeeklyTimetableImpl implements _WeeklyTimetable {
  const _$WeeklyTimetableImpl(
      {required this.sectionId,
      required this.sectionName,
      required this.className,
      required this.academicYearId,
      required final List<DayTimetable> days})
      : _days = days;

  factory _$WeeklyTimetableImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeeklyTimetableImplFromJson(json);

  @override
  final String sectionId;
  @override
  final String sectionName;
  @override
  final String className;
  @override
  final String academicYearId;
  final List<DayTimetable> _days;
  @override
  List<DayTimetable> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @override
  String toString() {
    return 'WeeklyTimetable(sectionId: $sectionId, sectionName: $sectionName, className: $className, academicYearId: $academicYearId, days: $days)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeeklyTimetableImpl &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.academicYearId, academicYearId) ||
                other.academicYearId == academicYearId) &&
            const DeepCollectionEquality().equals(other._days, _days));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, sectionId, sectionName,
      className, academicYearId, const DeepCollectionEquality().hash(_days));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WeeklyTimetableImplCopyWith<_$WeeklyTimetableImpl> get copyWith =>
      __$$WeeklyTimetableImplCopyWithImpl<_$WeeklyTimetableImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeeklyTimetableImplToJson(
      this,
    );
  }
}

abstract class _WeeklyTimetable implements WeeklyTimetable {
  const factory _WeeklyTimetable(
      {required final String sectionId,
      required final String sectionName,
      required final String className,
      required final String academicYearId,
      required final List<DayTimetable> days}) = _$WeeklyTimetableImpl;

  factory _WeeklyTimetable.fromJson(Map<String, dynamic> json) =
      _$WeeklyTimetableImpl.fromJson;

  @override
  String get sectionId;
  @override
  String get sectionName;
  @override
  String get className;
  @override
  String get academicYearId;
  @override
  List<DayTimetable> get days;
  @override
  @JsonKey(ignore: true)
  _$$WeeklyTimetableImplCopyWith<_$WeeklyTimetableImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
