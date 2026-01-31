// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exam_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Exam _$ExamFromJson(Map<String, dynamic> json) {
  return _Exam.fromJson(json);
}

/// @nodoc
mixin _$Exam {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get academicYearId => throw _privateConstructorUsedError;
  String? get termId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get examType => throw _privateConstructorUsedError;
  DateTime? get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  bool get isPublished => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError; // Joined data
  String? get termName => throw _privateConstructorUsedError;
  String? get academicYearName => throw _privateConstructorUsedError;
  List<ExamSubject>? get subjects => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExamCopyWith<Exam> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamCopyWith<$Res> {
  factory $ExamCopyWith(Exam value, $Res Function(Exam) then) =
      _$ExamCopyWithImpl<$Res, Exam>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String academicYearId,
      String? termId,
      String name,
      String examType,
      DateTime? startDate,
      DateTime? endDate,
      String? description,
      bool isPublished,
      DateTime? createdAt,
      String? termName,
      String? academicYearName,
      List<ExamSubject>? subjects});
}

/// @nodoc
class _$ExamCopyWithImpl<$Res, $Val extends Exam>
    implements $ExamCopyWith<$Res> {
  _$ExamCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? academicYearId = null,
    Object? termId = freezed,
    Object? name = null,
    Object? examType = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? description = freezed,
    Object? isPublished = null,
    Object? createdAt = freezed,
    Object? termName = freezed,
    Object? academicYearName = freezed,
    Object? subjects = freezed,
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
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      termId: freezed == termId
          ? _value.termId
          : termId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      examType: null == examType
          ? _value.examType
          : examType // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isPublished: null == isPublished
          ? _value.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      termName: freezed == termName
          ? _value.termName
          : termName // ignore: cast_nullable_to_non_nullable
              as String?,
      academicYearName: freezed == academicYearName
          ? _value.academicYearName
          : academicYearName // ignore: cast_nullable_to_non_nullable
              as String?,
      subjects: freezed == subjects
          ? _value.subjects
          : subjects // ignore: cast_nullable_to_non_nullable
              as List<ExamSubject>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExamImplCopyWith<$Res> implements $ExamCopyWith<$Res> {
  factory _$$ExamImplCopyWith(
          _$ExamImpl value, $Res Function(_$ExamImpl) then) =
      __$$ExamImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String academicYearId,
      String? termId,
      String name,
      String examType,
      DateTime? startDate,
      DateTime? endDate,
      String? description,
      bool isPublished,
      DateTime? createdAt,
      String? termName,
      String? academicYearName,
      List<ExamSubject>? subjects});
}

/// @nodoc
class __$$ExamImplCopyWithImpl<$Res>
    extends _$ExamCopyWithImpl<$Res, _$ExamImpl>
    implements _$$ExamImplCopyWith<$Res> {
  __$$ExamImplCopyWithImpl(_$ExamImpl _value, $Res Function(_$ExamImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? academicYearId = null,
    Object? termId = freezed,
    Object? name = null,
    Object? examType = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? description = freezed,
    Object? isPublished = null,
    Object? createdAt = freezed,
    Object? termName = freezed,
    Object? academicYearName = freezed,
    Object? subjects = freezed,
  }) {
    return _then(_$ExamImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      termId: freezed == termId
          ? _value.termId
          : termId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      examType: null == examType
          ? _value.examType
          : examType // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isPublished: null == isPublished
          ? _value.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      termName: freezed == termName
          ? _value.termName
          : termName // ignore: cast_nullable_to_non_nullable
              as String?,
      academicYearName: freezed == academicYearName
          ? _value.academicYearName
          : academicYearName // ignore: cast_nullable_to_non_nullable
              as String?,
      subjects: freezed == subjects
          ? _value._subjects
          : subjects // ignore: cast_nullable_to_non_nullable
              as List<ExamSubject>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExamImpl implements _Exam {
  const _$ExamImpl(
      {required this.id,
      required this.tenantId,
      required this.academicYearId,
      this.termId,
      required this.name,
      required this.examType,
      this.startDate,
      this.endDate,
      this.description,
      this.isPublished = false,
      this.createdAt,
      this.termName,
      this.academicYearName,
      final List<ExamSubject>? subjects})
      : _subjects = subjects;

  factory _$ExamImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExamImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String academicYearId;
  @override
  final String? termId;
  @override
  final String name;
  @override
  final String examType;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  final String? description;
  @override
  @JsonKey()
  final bool isPublished;
  @override
  final DateTime? createdAt;
// Joined data
  @override
  final String? termName;
  @override
  final String? academicYearName;
  final List<ExamSubject>? _subjects;
  @override
  List<ExamSubject>? get subjects {
    final value = _subjects;
    if (value == null) return null;
    if (_subjects is EqualUnmodifiableListView) return _subjects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'Exam(id: $id, tenantId: $tenantId, academicYearId: $academicYearId, termId: $termId, name: $name, examType: $examType, startDate: $startDate, endDate: $endDate, description: $description, isPublished: $isPublished, createdAt: $createdAt, termName: $termName, academicYearName: $academicYearName, subjects: $subjects)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.academicYearId, academicYearId) ||
                other.academicYearId == academicYearId) &&
            (identical(other.termId, termId) || other.termId == termId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.examType, examType) ||
                other.examType == examType) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isPublished, isPublished) ||
                other.isPublished == isPublished) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.termName, termName) ||
                other.termName == termName) &&
            (identical(other.academicYearName, academicYearName) ||
                other.academicYearName == academicYearName) &&
            const DeepCollectionEquality().equals(other._subjects, _subjects));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      academicYearId,
      termId,
      name,
      examType,
      startDate,
      endDate,
      description,
      isPublished,
      createdAt,
      termName,
      academicYearName,
      const DeepCollectionEquality().hash(_subjects));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamImplCopyWith<_$ExamImpl> get copyWith =>
      __$$ExamImplCopyWithImpl<_$ExamImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExamImplToJson(
      this,
    );
  }
}

abstract class _Exam implements Exam {
  const factory _Exam(
      {required final String id,
      required final String tenantId,
      required final String academicYearId,
      final String? termId,
      required final String name,
      required final String examType,
      final DateTime? startDate,
      final DateTime? endDate,
      final String? description,
      final bool isPublished,
      final DateTime? createdAt,
      final String? termName,
      final String? academicYearName,
      final List<ExamSubject>? subjects}) = _$ExamImpl;

  factory _Exam.fromJson(Map<String, dynamic> json) = _$ExamImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get academicYearId;
  @override
  String? get termId;
  @override
  String get name;
  @override
  String get examType;
  @override
  DateTime? get startDate;
  @override
  DateTime? get endDate;
  @override
  String? get description;
  @override
  bool get isPublished;
  @override
  DateTime? get createdAt;
  @override // Joined data
  String? get termName;
  @override
  String? get academicYearName;
  @override
  List<ExamSubject>? get subjects;
  @override
  @JsonKey(ignore: true)
  _$$ExamImplCopyWith<_$ExamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExamSubject _$ExamSubjectFromJson(Map<String, dynamic> json) {
  return _ExamSubject.fromJson(json);
}

/// @nodoc
mixin _$ExamSubject {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get examId => throw _privateConstructorUsedError;
  String get subjectId => throw _privateConstructorUsedError;
  String get classId => throw _privateConstructorUsedError;
  DateTime? get examDate => throw _privateConstructorUsedError;
  String? get startTime => throw _privateConstructorUsedError;
  String? get endTime => throw _privateConstructorUsedError;
  double get maxMarks => throw _privateConstructorUsedError;
  double get passingMarks => throw _privateConstructorUsedError;
  double get weightage => throw _privateConstructorUsedError;
  String? get syllabus => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError; // Joined data
  String? get subjectName => throw _privateConstructorUsedError;
  String? get subjectCode => throw _privateConstructorUsedError;
  String? get className => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExamSubjectCopyWith<ExamSubject> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamSubjectCopyWith<$Res> {
  factory $ExamSubjectCopyWith(
          ExamSubject value, $Res Function(ExamSubject) then) =
      _$ExamSubjectCopyWithImpl<$Res, ExamSubject>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String examId,
      String subjectId,
      String classId,
      DateTime? examDate,
      String? startTime,
      String? endTime,
      double maxMarks,
      double passingMarks,
      double weightage,
      String? syllabus,
      DateTime? createdAt,
      String? subjectName,
      String? subjectCode,
      String? className});
}

/// @nodoc
class _$ExamSubjectCopyWithImpl<$Res, $Val extends ExamSubject>
    implements $ExamSubjectCopyWith<$Res> {
  _$ExamSubjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? examId = null,
    Object? subjectId = null,
    Object? classId = null,
    Object? examDate = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? maxMarks = null,
    Object? passingMarks = null,
    Object? weightage = null,
    Object? syllabus = freezed,
    Object? createdAt = freezed,
    Object? subjectName = freezed,
    Object? subjectCode = freezed,
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
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      examDate: freezed == examDate
          ? _value.examDate
          : examDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String?,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String?,
      maxMarks: null == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double,
      passingMarks: null == passingMarks
          ? _value.passingMarks
          : passingMarks // ignore: cast_nullable_to_non_nullable
              as double,
      weightage: null == weightage
          ? _value.weightage
          : weightage // ignore: cast_nullable_to_non_nullable
              as double,
      syllabus: freezed == syllabus
          ? _value.syllabus
          : syllabus // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      subjectName: freezed == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectCode: freezed == subjectCode
          ? _value.subjectCode
          : subjectCode // ignore: cast_nullable_to_non_nullable
              as String?,
      className: freezed == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExamSubjectImplCopyWith<$Res>
    implements $ExamSubjectCopyWith<$Res> {
  factory _$$ExamSubjectImplCopyWith(
          _$ExamSubjectImpl value, $Res Function(_$ExamSubjectImpl) then) =
      __$$ExamSubjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String examId,
      String subjectId,
      String classId,
      DateTime? examDate,
      String? startTime,
      String? endTime,
      double maxMarks,
      double passingMarks,
      double weightage,
      String? syllabus,
      DateTime? createdAt,
      String? subjectName,
      String? subjectCode,
      String? className});
}

/// @nodoc
class __$$ExamSubjectImplCopyWithImpl<$Res>
    extends _$ExamSubjectCopyWithImpl<$Res, _$ExamSubjectImpl>
    implements _$$ExamSubjectImplCopyWith<$Res> {
  __$$ExamSubjectImplCopyWithImpl(
      _$ExamSubjectImpl _value, $Res Function(_$ExamSubjectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? examId = null,
    Object? subjectId = null,
    Object? classId = null,
    Object? examDate = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? maxMarks = null,
    Object? passingMarks = null,
    Object? weightage = null,
    Object? syllabus = freezed,
    Object? createdAt = freezed,
    Object? subjectName = freezed,
    Object? subjectCode = freezed,
    Object? className = freezed,
  }) {
    return _then(_$ExamSubjectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      examDate: freezed == examDate
          ? _value.examDate
          : examDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String?,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String?,
      maxMarks: null == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double,
      passingMarks: null == passingMarks
          ? _value.passingMarks
          : passingMarks // ignore: cast_nullable_to_non_nullable
              as double,
      weightage: null == weightage
          ? _value.weightage
          : weightage // ignore: cast_nullable_to_non_nullable
              as double,
      syllabus: freezed == syllabus
          ? _value.syllabus
          : syllabus // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      subjectName: freezed == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectCode: freezed == subjectCode
          ? _value.subjectCode
          : subjectCode // ignore: cast_nullable_to_non_nullable
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
class _$ExamSubjectImpl implements _ExamSubject {
  const _$ExamSubjectImpl(
      {required this.id,
      required this.tenantId,
      required this.examId,
      required this.subjectId,
      required this.classId,
      this.examDate,
      this.startTime,
      this.endTime,
      required this.maxMarks,
      required this.passingMarks,
      this.weightage = 1.0,
      this.syllabus,
      this.createdAt,
      this.subjectName,
      this.subjectCode,
      this.className});

  factory _$ExamSubjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExamSubjectImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String examId;
  @override
  final String subjectId;
  @override
  final String classId;
  @override
  final DateTime? examDate;
  @override
  final String? startTime;
  @override
  final String? endTime;
  @override
  final double maxMarks;
  @override
  final double passingMarks;
  @override
  @JsonKey()
  final double weightage;
  @override
  final String? syllabus;
  @override
  final DateTime? createdAt;
// Joined data
  @override
  final String? subjectName;
  @override
  final String? subjectCode;
  @override
  final String? className;

  @override
  String toString() {
    return 'ExamSubject(id: $id, tenantId: $tenantId, examId: $examId, subjectId: $subjectId, classId: $classId, examDate: $examDate, startTime: $startTime, endTime: $endTime, maxMarks: $maxMarks, passingMarks: $passingMarks, weightage: $weightage, syllabus: $syllabus, createdAt: $createdAt, subjectName: $subjectName, subjectCode: $subjectCode, className: $className)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamSubjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.examId, examId) || other.examId == examId) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.examDate, examDate) ||
                other.examDate == examDate) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.maxMarks, maxMarks) ||
                other.maxMarks == maxMarks) &&
            (identical(other.passingMarks, passingMarks) ||
                other.passingMarks == passingMarks) &&
            (identical(other.weightage, weightage) ||
                other.weightage == weightage) &&
            (identical(other.syllabus, syllabus) ||
                other.syllabus == syllabus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.subjectCode, subjectCode) ||
                other.subjectCode == subjectCode) &&
            (identical(other.className, className) ||
                other.className == className));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      examId,
      subjectId,
      classId,
      examDate,
      startTime,
      endTime,
      maxMarks,
      passingMarks,
      weightage,
      syllabus,
      createdAt,
      subjectName,
      subjectCode,
      className);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamSubjectImplCopyWith<_$ExamSubjectImpl> get copyWith =>
      __$$ExamSubjectImplCopyWithImpl<_$ExamSubjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExamSubjectImplToJson(
      this,
    );
  }
}

abstract class _ExamSubject implements ExamSubject {
  const factory _ExamSubject(
      {required final String id,
      required final String tenantId,
      required final String examId,
      required final String subjectId,
      required final String classId,
      final DateTime? examDate,
      final String? startTime,
      final String? endTime,
      required final double maxMarks,
      required final double passingMarks,
      final double weightage,
      final String? syllabus,
      final DateTime? createdAt,
      final String? subjectName,
      final String? subjectCode,
      final String? className}) = _$ExamSubjectImpl;

  factory _ExamSubject.fromJson(Map<String, dynamic> json) =
      _$ExamSubjectImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get examId;
  @override
  String get subjectId;
  @override
  String get classId;
  @override
  DateTime? get examDate;
  @override
  String? get startTime;
  @override
  String? get endTime;
  @override
  double get maxMarks;
  @override
  double get passingMarks;
  @override
  double get weightage;
  @override
  String? get syllabus;
  @override
  DateTime? get createdAt;
  @override // Joined data
  String? get subjectName;
  @override
  String? get subjectCode;
  @override
  String? get className;
  @override
  @JsonKey(ignore: true)
  _$$ExamSubjectImplCopyWith<_$ExamSubjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Mark _$MarkFromJson(Map<String, dynamic> json) {
  return _Mark.fromJson(json);
}

/// @nodoc
mixin _$Mark {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get examSubjectId => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  double? get marksObtained => throw _privateConstructorUsedError;
  bool get isAbsent => throw _privateConstructorUsedError;
  String? get remarks => throw _privateConstructorUsedError;
  String? get enteredBy => throw _privateConstructorUsedError;
  DateTime? get enteredAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError; // Joined data
  String? get studentName => throw _privateConstructorUsedError;
  String? get admissionNumber => throw _privateConstructorUsedError;
  String? get subjectName => throw _privateConstructorUsedError;
  double? get maxMarks => throw _privateConstructorUsedError;
  double? get passingMarks => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MarkCopyWith<Mark> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MarkCopyWith<$Res> {
  factory $MarkCopyWith(Mark value, $Res Function(Mark) then) =
      _$MarkCopyWithImpl<$Res, Mark>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String examSubjectId,
      String studentId,
      double? marksObtained,
      bool isAbsent,
      String? remarks,
      String? enteredBy,
      DateTime? enteredAt,
      DateTime? updatedAt,
      String? studentName,
      String? admissionNumber,
      String? subjectName,
      double? maxMarks,
      double? passingMarks});
}

/// @nodoc
class _$MarkCopyWithImpl<$Res, $Val extends Mark>
    implements $MarkCopyWith<$Res> {
  _$MarkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? examSubjectId = null,
    Object? studentId = null,
    Object? marksObtained = freezed,
    Object? isAbsent = null,
    Object? remarks = freezed,
    Object? enteredBy = freezed,
    Object? enteredAt = freezed,
    Object? updatedAt = freezed,
    Object? studentName = freezed,
    Object? admissionNumber = freezed,
    Object? subjectName = freezed,
    Object? maxMarks = freezed,
    Object? passingMarks = freezed,
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
      examSubjectId: null == examSubjectId
          ? _value.examSubjectId
          : examSubjectId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      marksObtained: freezed == marksObtained
          ? _value.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double?,
      isAbsent: null == isAbsent
          ? _value.isAbsent
          : isAbsent // ignore: cast_nullable_to_non_nullable
              as bool,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      enteredBy: freezed == enteredBy
          ? _value.enteredBy
          : enteredBy // ignore: cast_nullable_to_non_nullable
              as String?,
      enteredAt: freezed == enteredAt
          ? _value.enteredAt
          : enteredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      studentName: freezed == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String?,
      admissionNumber: freezed == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectName: freezed == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String?,
      maxMarks: freezed == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double?,
      passingMarks: freezed == passingMarks
          ? _value.passingMarks
          : passingMarks // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MarkImplCopyWith<$Res> implements $MarkCopyWith<$Res> {
  factory _$$MarkImplCopyWith(
          _$MarkImpl value, $Res Function(_$MarkImpl) then) =
      __$$MarkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String examSubjectId,
      String studentId,
      double? marksObtained,
      bool isAbsent,
      String? remarks,
      String? enteredBy,
      DateTime? enteredAt,
      DateTime? updatedAt,
      String? studentName,
      String? admissionNumber,
      String? subjectName,
      double? maxMarks,
      double? passingMarks});
}

/// @nodoc
class __$$MarkImplCopyWithImpl<$Res>
    extends _$MarkCopyWithImpl<$Res, _$MarkImpl>
    implements _$$MarkImplCopyWith<$Res> {
  __$$MarkImplCopyWithImpl(_$MarkImpl _value, $Res Function(_$MarkImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? examSubjectId = null,
    Object? studentId = null,
    Object? marksObtained = freezed,
    Object? isAbsent = null,
    Object? remarks = freezed,
    Object? enteredBy = freezed,
    Object? enteredAt = freezed,
    Object? updatedAt = freezed,
    Object? studentName = freezed,
    Object? admissionNumber = freezed,
    Object? subjectName = freezed,
    Object? maxMarks = freezed,
    Object? passingMarks = freezed,
  }) {
    return _then(_$MarkImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      examSubjectId: null == examSubjectId
          ? _value.examSubjectId
          : examSubjectId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      marksObtained: freezed == marksObtained
          ? _value.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double?,
      isAbsent: null == isAbsent
          ? _value.isAbsent
          : isAbsent // ignore: cast_nullable_to_non_nullable
              as bool,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      enteredBy: freezed == enteredBy
          ? _value.enteredBy
          : enteredBy // ignore: cast_nullable_to_non_nullable
              as String?,
      enteredAt: freezed == enteredAt
          ? _value.enteredAt
          : enteredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      studentName: freezed == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String?,
      admissionNumber: freezed == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      subjectName: freezed == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String?,
      maxMarks: freezed == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double?,
      passingMarks: freezed == passingMarks
          ? _value.passingMarks
          : passingMarks // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MarkImpl implements _Mark {
  const _$MarkImpl(
      {required this.id,
      required this.tenantId,
      required this.examSubjectId,
      required this.studentId,
      this.marksObtained,
      this.isAbsent = false,
      this.remarks,
      this.enteredBy,
      this.enteredAt,
      this.updatedAt,
      this.studentName,
      this.admissionNumber,
      this.subjectName,
      this.maxMarks,
      this.passingMarks});

  factory _$MarkImpl.fromJson(Map<String, dynamic> json) =>
      _$$MarkImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String examSubjectId;
  @override
  final String studentId;
  @override
  final double? marksObtained;
  @override
  @JsonKey()
  final bool isAbsent;
  @override
  final String? remarks;
  @override
  final String? enteredBy;
  @override
  final DateTime? enteredAt;
  @override
  final DateTime? updatedAt;
// Joined data
  @override
  final String? studentName;
  @override
  final String? admissionNumber;
  @override
  final String? subjectName;
  @override
  final double? maxMarks;
  @override
  final double? passingMarks;

  @override
  String toString() {
    return 'Mark(id: $id, tenantId: $tenantId, examSubjectId: $examSubjectId, studentId: $studentId, marksObtained: $marksObtained, isAbsent: $isAbsent, remarks: $remarks, enteredBy: $enteredBy, enteredAt: $enteredAt, updatedAt: $updatedAt, studentName: $studentName, admissionNumber: $admissionNumber, subjectName: $subjectName, maxMarks: $maxMarks, passingMarks: $passingMarks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.examSubjectId, examSubjectId) ||
                other.examSubjectId == examSubjectId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.marksObtained, marksObtained) ||
                other.marksObtained == marksObtained) &&
            (identical(other.isAbsent, isAbsent) ||
                other.isAbsent == isAbsent) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
            (identical(other.enteredBy, enteredBy) ||
                other.enteredBy == enteredBy) &&
            (identical(other.enteredAt, enteredAt) ||
                other.enteredAt == enteredAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.admissionNumber, admissionNumber) ||
                other.admissionNumber == admissionNumber) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.maxMarks, maxMarks) ||
                other.maxMarks == maxMarks) &&
            (identical(other.passingMarks, passingMarks) ||
                other.passingMarks == passingMarks));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      examSubjectId,
      studentId,
      marksObtained,
      isAbsent,
      remarks,
      enteredBy,
      enteredAt,
      updatedAt,
      studentName,
      admissionNumber,
      subjectName,
      maxMarks,
      passingMarks);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MarkImplCopyWith<_$MarkImpl> get copyWith =>
      __$$MarkImplCopyWithImpl<_$MarkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MarkImplToJson(
      this,
    );
  }
}

abstract class _Mark implements Mark {
  const factory _Mark(
      {required final String id,
      required final String tenantId,
      required final String examSubjectId,
      required final String studentId,
      final double? marksObtained,
      final bool isAbsent,
      final String? remarks,
      final String? enteredBy,
      final DateTime? enteredAt,
      final DateTime? updatedAt,
      final String? studentName,
      final String? admissionNumber,
      final String? subjectName,
      final double? maxMarks,
      final double? passingMarks}) = _$MarkImpl;

  factory _Mark.fromJson(Map<String, dynamic> json) = _$MarkImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get examSubjectId;
  @override
  String get studentId;
  @override
  double? get marksObtained;
  @override
  bool get isAbsent;
  @override
  String? get remarks;
  @override
  String? get enteredBy;
  @override
  DateTime? get enteredAt;
  @override
  DateTime? get updatedAt;
  @override // Joined data
  String? get studentName;
  @override
  String? get admissionNumber;
  @override
  String? get subjectName;
  @override
  double? get maxMarks;
  @override
  double? get passingMarks;
  @override
  @JsonKey(ignore: true)
  _$$MarkImplCopyWith<_$MarkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StudentPerformance _$StudentPerformanceFromJson(Map<String, dynamic> json) {
  return _StudentPerformance.fromJson(json);
}

/// @nodoc
mixin _$StudentPerformance {
  String get tenantId => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get studentName => throw _privateConstructorUsedError;
  String get admissionNumber => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String get sectionName => throw _privateConstructorUsedError;
  String get classId => throw _privateConstructorUsedError;
  String get className => throw _privateConstructorUsedError;
  String get examId => throw _privateConstructorUsedError;
  String get examName => throw _privateConstructorUsedError;
  String get examType => throw _privateConstructorUsedError;
  String get subjectId => throw _privateConstructorUsedError;
  String get subjectName => throw _privateConstructorUsedError;
  String? get subjectCode => throw _privateConstructorUsedError;
  double get marksObtained => throw _privateConstructorUsedError;
  double get maxMarks => throw _privateConstructorUsedError;
  double get passingMarks => throw _privateConstructorUsedError;
  double get percentage => throw _privateConstructorUsedError;
  bool get isPassed => throw _privateConstructorUsedError;
  bool get isAbsent => throw _privateConstructorUsedError;
  String get academicYearId => throw _privateConstructorUsedError;
  String? get termId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StudentPerformanceCopyWith<StudentPerformance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentPerformanceCopyWith<$Res> {
  factory $StudentPerformanceCopyWith(
          StudentPerformance value, $Res Function(StudentPerformance) then) =
      _$StudentPerformanceCopyWithImpl<$Res, StudentPerformance>;
  @useResult
  $Res call(
      {String tenantId,
      String studentId,
      String studentName,
      String admissionNumber,
      String sectionId,
      String sectionName,
      String classId,
      String className,
      String examId,
      String examName,
      String examType,
      String subjectId,
      String subjectName,
      String? subjectCode,
      double marksObtained,
      double maxMarks,
      double passingMarks,
      double percentage,
      bool isPassed,
      bool isAbsent,
      String academicYearId,
      String? termId});
}

/// @nodoc
class _$StudentPerformanceCopyWithImpl<$Res, $Val extends StudentPerformance>
    implements $StudentPerformanceCopyWith<$Res> {
  _$StudentPerformanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? studentId = null,
    Object? studentName = null,
    Object? admissionNumber = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? classId = null,
    Object? className = null,
    Object? examId = null,
    Object? examName = null,
    Object? examType = null,
    Object? subjectId = null,
    Object? subjectName = null,
    Object? subjectCode = freezed,
    Object? marksObtained = null,
    Object? maxMarks = null,
    Object? passingMarks = null,
    Object? percentage = null,
    Object? isPassed = null,
    Object? isAbsent = null,
    Object? academicYearId = null,
    Object? termId = freezed,
  }) {
    return _then(_value.copyWith(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      admissionNumber: null == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      examName: null == examName
          ? _value.examName
          : examName // ignore: cast_nullable_to_non_nullable
              as String,
      examType: null == examType
          ? _value.examType
          : examType // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      subjectCode: freezed == subjectCode
          ? _value.subjectCode
          : subjectCode // ignore: cast_nullable_to_non_nullable
              as String?,
      marksObtained: null == marksObtained
          ? _value.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double,
      maxMarks: null == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double,
      passingMarks: null == passingMarks
          ? _value.passingMarks
          : passingMarks // ignore: cast_nullable_to_non_nullable
              as double,
      percentage: null == percentage
          ? _value.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
      isPassed: null == isPassed
          ? _value.isPassed
          : isPassed // ignore: cast_nullable_to_non_nullable
              as bool,
      isAbsent: null == isAbsent
          ? _value.isAbsent
          : isAbsent // ignore: cast_nullable_to_non_nullable
              as bool,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      termId: freezed == termId
          ? _value.termId
          : termId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudentPerformanceImplCopyWith<$Res>
    implements $StudentPerformanceCopyWith<$Res> {
  factory _$$StudentPerformanceImplCopyWith(_$StudentPerformanceImpl value,
          $Res Function(_$StudentPerformanceImpl) then) =
      __$$StudentPerformanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tenantId,
      String studentId,
      String studentName,
      String admissionNumber,
      String sectionId,
      String sectionName,
      String classId,
      String className,
      String examId,
      String examName,
      String examType,
      String subjectId,
      String subjectName,
      String? subjectCode,
      double marksObtained,
      double maxMarks,
      double passingMarks,
      double percentage,
      bool isPassed,
      bool isAbsent,
      String academicYearId,
      String? termId});
}

/// @nodoc
class __$$StudentPerformanceImplCopyWithImpl<$Res>
    extends _$StudentPerformanceCopyWithImpl<$Res, _$StudentPerformanceImpl>
    implements _$$StudentPerformanceImplCopyWith<$Res> {
  __$$StudentPerformanceImplCopyWithImpl(_$StudentPerformanceImpl _value,
      $Res Function(_$StudentPerformanceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? studentId = null,
    Object? studentName = null,
    Object? admissionNumber = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? classId = null,
    Object? className = null,
    Object? examId = null,
    Object? examName = null,
    Object? examType = null,
    Object? subjectId = null,
    Object? subjectName = null,
    Object? subjectCode = freezed,
    Object? marksObtained = null,
    Object? maxMarks = null,
    Object? passingMarks = null,
    Object? percentage = null,
    Object? isPassed = null,
    Object? isAbsent = null,
    Object? academicYearId = null,
    Object? termId = freezed,
  }) {
    return _then(_$StudentPerformanceImpl(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      admissionNumber: null == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      examName: null == examName
          ? _value.examName
          : examName // ignore: cast_nullable_to_non_nullable
              as String,
      examType: null == examType
          ? _value.examType
          : examType // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      subjectCode: freezed == subjectCode
          ? _value.subjectCode
          : subjectCode // ignore: cast_nullable_to_non_nullable
              as String?,
      marksObtained: null == marksObtained
          ? _value.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double,
      maxMarks: null == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double,
      passingMarks: null == passingMarks
          ? _value.passingMarks
          : passingMarks // ignore: cast_nullable_to_non_nullable
              as double,
      percentage: null == percentage
          ? _value.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
      isPassed: null == isPassed
          ? _value.isPassed
          : isPassed // ignore: cast_nullable_to_non_nullable
              as bool,
      isAbsent: null == isAbsent
          ? _value.isAbsent
          : isAbsent // ignore: cast_nullable_to_non_nullable
              as bool,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      termId: freezed == termId
          ? _value.termId
          : termId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentPerformanceImpl implements _StudentPerformance {
  const _$StudentPerformanceImpl(
      {required this.tenantId,
      required this.studentId,
      required this.studentName,
      required this.admissionNumber,
      required this.sectionId,
      required this.sectionName,
      required this.classId,
      required this.className,
      required this.examId,
      required this.examName,
      required this.examType,
      required this.subjectId,
      required this.subjectName,
      this.subjectCode,
      required this.marksObtained,
      required this.maxMarks,
      required this.passingMarks,
      required this.percentage,
      required this.isPassed,
      this.isAbsent = false,
      required this.academicYearId,
      this.termId});

  factory _$StudentPerformanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentPerformanceImplFromJson(json);

  @override
  final String tenantId;
  @override
  final String studentId;
  @override
  final String studentName;
  @override
  final String admissionNumber;
  @override
  final String sectionId;
  @override
  final String sectionName;
  @override
  final String classId;
  @override
  final String className;
  @override
  final String examId;
  @override
  final String examName;
  @override
  final String examType;
  @override
  final String subjectId;
  @override
  final String subjectName;
  @override
  final String? subjectCode;
  @override
  final double marksObtained;
  @override
  final double maxMarks;
  @override
  final double passingMarks;
  @override
  final double percentage;
  @override
  final bool isPassed;
  @override
  @JsonKey()
  final bool isAbsent;
  @override
  final String academicYearId;
  @override
  final String? termId;

  @override
  String toString() {
    return 'StudentPerformance(tenantId: $tenantId, studentId: $studentId, studentName: $studentName, admissionNumber: $admissionNumber, sectionId: $sectionId, sectionName: $sectionName, classId: $classId, className: $className, examId: $examId, examName: $examName, examType: $examType, subjectId: $subjectId, subjectName: $subjectName, subjectCode: $subjectCode, marksObtained: $marksObtained, maxMarks: $maxMarks, passingMarks: $passingMarks, percentage: $percentage, isPassed: $isPassed, isAbsent: $isAbsent, academicYearId: $academicYearId, termId: $termId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentPerformanceImpl &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.admissionNumber, admissionNumber) ||
                other.admissionNumber == admissionNumber) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.examId, examId) || other.examId == examId) &&
            (identical(other.examName, examName) ||
                other.examName == examName) &&
            (identical(other.examType, examType) ||
                other.examType == examType) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.subjectCode, subjectCode) ||
                other.subjectCode == subjectCode) &&
            (identical(other.marksObtained, marksObtained) ||
                other.marksObtained == marksObtained) &&
            (identical(other.maxMarks, maxMarks) ||
                other.maxMarks == maxMarks) &&
            (identical(other.passingMarks, passingMarks) ||
                other.passingMarks == passingMarks) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.isPassed, isPassed) ||
                other.isPassed == isPassed) &&
            (identical(other.isAbsent, isAbsent) ||
                other.isAbsent == isAbsent) &&
            (identical(other.academicYearId, academicYearId) ||
                other.academicYearId == academicYearId) &&
            (identical(other.termId, termId) || other.termId == termId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        tenantId,
        studentId,
        studentName,
        admissionNumber,
        sectionId,
        sectionName,
        classId,
        className,
        examId,
        examName,
        examType,
        subjectId,
        subjectName,
        subjectCode,
        marksObtained,
        maxMarks,
        passingMarks,
        percentage,
        isPassed,
        isAbsent,
        academicYearId,
        termId
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentPerformanceImplCopyWith<_$StudentPerformanceImpl> get copyWith =>
      __$$StudentPerformanceImplCopyWithImpl<_$StudentPerformanceImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentPerformanceImplToJson(
      this,
    );
  }
}

abstract class _StudentPerformance implements StudentPerformance {
  const factory _StudentPerformance(
      {required final String tenantId,
      required final String studentId,
      required final String studentName,
      required final String admissionNumber,
      required final String sectionId,
      required final String sectionName,
      required final String classId,
      required final String className,
      required final String examId,
      required final String examName,
      required final String examType,
      required final String subjectId,
      required final String subjectName,
      final String? subjectCode,
      required final double marksObtained,
      required final double maxMarks,
      required final double passingMarks,
      required final double percentage,
      required final bool isPassed,
      final bool isAbsent,
      required final String academicYearId,
      final String? termId}) = _$StudentPerformanceImpl;

  factory _StudentPerformance.fromJson(Map<String, dynamic> json) =
      _$StudentPerformanceImpl.fromJson;

  @override
  String get tenantId;
  @override
  String get studentId;
  @override
  String get studentName;
  @override
  String get admissionNumber;
  @override
  String get sectionId;
  @override
  String get sectionName;
  @override
  String get classId;
  @override
  String get className;
  @override
  String get examId;
  @override
  String get examName;
  @override
  String get examType;
  @override
  String get subjectId;
  @override
  String get subjectName;
  @override
  String? get subjectCode;
  @override
  double get marksObtained;
  @override
  double get maxMarks;
  @override
  double get passingMarks;
  @override
  double get percentage;
  @override
  bool get isPassed;
  @override
  bool get isAbsent;
  @override
  String get academicYearId;
  @override
  String? get termId;
  @override
  @JsonKey(ignore: true)
  _$$StudentPerformanceImplCopyWith<_$StudentPerformanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StudentRank _$StudentRankFromJson(Map<String, dynamic> json) {
  return _StudentRank.fromJson(json);
}

/// @nodoc
mixin _$StudentRank {
  String get tenantId => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get studentName => throw _privateConstructorUsedError;
  String get admissionNumber => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String get sectionName => throw _privateConstructorUsedError;
  String get classId => throw _privateConstructorUsedError;
  String get className => throw _privateConstructorUsedError;
  String get examId => throw _privateConstructorUsedError;
  String get examName => throw _privateConstructorUsedError;
  String get examType => throw _privateConstructorUsedError;
  String get subjectId => throw _privateConstructorUsedError;
  String get subjectName => throw _privateConstructorUsedError;
  double get marksObtained => throw _privateConstructorUsedError;
  double get maxMarks => throw _privateConstructorUsedError;
  double get percentage => throw _privateConstructorUsedError;
  int get subjectRank => throw _privateConstructorUsedError;
  int get totalInSubject => throw _privateConstructorUsedError;
  String get academicYearId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StudentRankCopyWith<StudentRank> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentRankCopyWith<$Res> {
  factory $StudentRankCopyWith(
          StudentRank value, $Res Function(StudentRank) then) =
      _$StudentRankCopyWithImpl<$Res, StudentRank>;
  @useResult
  $Res call(
      {String tenantId,
      String studentId,
      String studentName,
      String admissionNumber,
      String sectionId,
      String sectionName,
      String classId,
      String className,
      String examId,
      String examName,
      String examType,
      String subjectId,
      String subjectName,
      double marksObtained,
      double maxMarks,
      double percentage,
      int subjectRank,
      int totalInSubject,
      String academicYearId});
}

/// @nodoc
class _$StudentRankCopyWithImpl<$Res, $Val extends StudentRank>
    implements $StudentRankCopyWith<$Res> {
  _$StudentRankCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? studentId = null,
    Object? studentName = null,
    Object? admissionNumber = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? classId = null,
    Object? className = null,
    Object? examId = null,
    Object? examName = null,
    Object? examType = null,
    Object? subjectId = null,
    Object? subjectName = null,
    Object? marksObtained = null,
    Object? maxMarks = null,
    Object? percentage = null,
    Object? subjectRank = null,
    Object? totalInSubject = null,
    Object? academicYearId = null,
  }) {
    return _then(_value.copyWith(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      admissionNumber: null == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      examName: null == examName
          ? _value.examName
          : examName // ignore: cast_nullable_to_non_nullable
              as String,
      examType: null == examType
          ? _value.examType
          : examType // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      marksObtained: null == marksObtained
          ? _value.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double,
      maxMarks: null == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double,
      percentage: null == percentage
          ? _value.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
      subjectRank: null == subjectRank
          ? _value.subjectRank
          : subjectRank // ignore: cast_nullable_to_non_nullable
              as int,
      totalInSubject: null == totalInSubject
          ? _value.totalInSubject
          : totalInSubject // ignore: cast_nullable_to_non_nullable
              as int,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudentRankImplCopyWith<$Res>
    implements $StudentRankCopyWith<$Res> {
  factory _$$StudentRankImplCopyWith(
          _$StudentRankImpl value, $Res Function(_$StudentRankImpl) then) =
      __$$StudentRankImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tenantId,
      String studentId,
      String studentName,
      String admissionNumber,
      String sectionId,
      String sectionName,
      String classId,
      String className,
      String examId,
      String examName,
      String examType,
      String subjectId,
      String subjectName,
      double marksObtained,
      double maxMarks,
      double percentage,
      int subjectRank,
      int totalInSubject,
      String academicYearId});
}

/// @nodoc
class __$$StudentRankImplCopyWithImpl<$Res>
    extends _$StudentRankCopyWithImpl<$Res, _$StudentRankImpl>
    implements _$$StudentRankImplCopyWith<$Res> {
  __$$StudentRankImplCopyWithImpl(
      _$StudentRankImpl _value, $Res Function(_$StudentRankImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? studentId = null,
    Object? studentName = null,
    Object? admissionNumber = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? classId = null,
    Object? className = null,
    Object? examId = null,
    Object? examName = null,
    Object? examType = null,
    Object? subjectId = null,
    Object? subjectName = null,
    Object? marksObtained = null,
    Object? maxMarks = null,
    Object? percentage = null,
    Object? subjectRank = null,
    Object? totalInSubject = null,
    Object? academicYearId = null,
  }) {
    return _then(_$StudentRankImpl(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      admissionNumber: null == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      examName: null == examName
          ? _value.examName
          : examName // ignore: cast_nullable_to_non_nullable
              as String,
      examType: null == examType
          ? _value.examType
          : examType // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      marksObtained: null == marksObtained
          ? _value.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double,
      maxMarks: null == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double,
      percentage: null == percentage
          ? _value.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
      subjectRank: null == subjectRank
          ? _value.subjectRank
          : subjectRank // ignore: cast_nullable_to_non_nullable
              as int,
      totalInSubject: null == totalInSubject
          ? _value.totalInSubject
          : totalInSubject // ignore: cast_nullable_to_non_nullable
              as int,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentRankImpl implements _StudentRank {
  const _$StudentRankImpl(
      {required this.tenantId,
      required this.studentId,
      required this.studentName,
      required this.admissionNumber,
      required this.sectionId,
      required this.sectionName,
      required this.classId,
      required this.className,
      required this.examId,
      required this.examName,
      required this.examType,
      required this.subjectId,
      required this.subjectName,
      required this.marksObtained,
      required this.maxMarks,
      required this.percentage,
      required this.subjectRank,
      required this.totalInSubject,
      required this.academicYearId});

  factory _$StudentRankImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentRankImplFromJson(json);

  @override
  final String tenantId;
  @override
  final String studentId;
  @override
  final String studentName;
  @override
  final String admissionNumber;
  @override
  final String sectionId;
  @override
  final String sectionName;
  @override
  final String classId;
  @override
  final String className;
  @override
  final String examId;
  @override
  final String examName;
  @override
  final String examType;
  @override
  final String subjectId;
  @override
  final String subjectName;
  @override
  final double marksObtained;
  @override
  final double maxMarks;
  @override
  final double percentage;
  @override
  final int subjectRank;
  @override
  final int totalInSubject;
  @override
  final String academicYearId;

  @override
  String toString() {
    return 'StudentRank(tenantId: $tenantId, studentId: $studentId, studentName: $studentName, admissionNumber: $admissionNumber, sectionId: $sectionId, sectionName: $sectionName, classId: $classId, className: $className, examId: $examId, examName: $examName, examType: $examType, subjectId: $subjectId, subjectName: $subjectName, marksObtained: $marksObtained, maxMarks: $maxMarks, percentage: $percentage, subjectRank: $subjectRank, totalInSubject: $totalInSubject, academicYearId: $academicYearId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentRankImpl &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.admissionNumber, admissionNumber) ||
                other.admissionNumber == admissionNumber) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.examId, examId) || other.examId == examId) &&
            (identical(other.examName, examName) ||
                other.examName == examName) &&
            (identical(other.examType, examType) ||
                other.examType == examType) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.marksObtained, marksObtained) ||
                other.marksObtained == marksObtained) &&
            (identical(other.maxMarks, maxMarks) ||
                other.maxMarks == maxMarks) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.subjectRank, subjectRank) ||
                other.subjectRank == subjectRank) &&
            (identical(other.totalInSubject, totalInSubject) ||
                other.totalInSubject == totalInSubject) &&
            (identical(other.academicYearId, academicYearId) ||
                other.academicYearId == academicYearId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        tenantId,
        studentId,
        studentName,
        admissionNumber,
        sectionId,
        sectionName,
        classId,
        className,
        examId,
        examName,
        examType,
        subjectId,
        subjectName,
        marksObtained,
        maxMarks,
        percentage,
        subjectRank,
        totalInSubject,
        academicYearId
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentRankImplCopyWith<_$StudentRankImpl> get copyWith =>
      __$$StudentRankImplCopyWithImpl<_$StudentRankImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentRankImplToJson(
      this,
    );
  }
}

abstract class _StudentRank implements StudentRank {
  const factory _StudentRank(
      {required final String tenantId,
      required final String studentId,
      required final String studentName,
      required final String admissionNumber,
      required final String sectionId,
      required final String sectionName,
      required final String classId,
      required final String className,
      required final String examId,
      required final String examName,
      required final String examType,
      required final String subjectId,
      required final String subjectName,
      required final double marksObtained,
      required final double maxMarks,
      required final double percentage,
      required final int subjectRank,
      required final int totalInSubject,
      required final String academicYearId}) = _$StudentRankImpl;

  factory _StudentRank.fromJson(Map<String, dynamic> json) =
      _$StudentRankImpl.fromJson;

  @override
  String get tenantId;
  @override
  String get studentId;
  @override
  String get studentName;
  @override
  String get admissionNumber;
  @override
  String get sectionId;
  @override
  String get sectionName;
  @override
  String get classId;
  @override
  String get className;
  @override
  String get examId;
  @override
  String get examName;
  @override
  String get examType;
  @override
  String get subjectId;
  @override
  String get subjectName;
  @override
  double get marksObtained;
  @override
  double get maxMarks;
  @override
  double get percentage;
  @override
  int get subjectRank;
  @override
  int get totalInSubject;
  @override
  String get academicYearId;
  @override
  @JsonKey(ignore: true)
  _$$StudentRankImplCopyWith<_$StudentRankImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StudentOverallRank _$StudentOverallRankFromJson(Map<String, dynamic> json) {
  return _StudentOverallRank.fromJson(json);
}

/// @nodoc
mixin _$StudentOverallRank {
  String get tenantId => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get studentName => throw _privateConstructorUsedError;
  String get admissionNumber => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String get sectionName => throw _privateConstructorUsedError;
  String get classId => throw _privateConstructorUsedError;
  String get className => throw _privateConstructorUsedError;
  String get examId => throw _privateConstructorUsedError;
  String get examName => throw _privateConstructorUsedError;
  String get examType => throw _privateConstructorUsedError;
  String get academicYearId => throw _privateConstructorUsedError;
  double get totalObtained => throw _privateConstructorUsedError;
  double get totalMaxMarks => throw _privateConstructorUsedError;
  double get overallPercentage => throw _privateConstructorUsedError;
  int get subjectsCount => throw _privateConstructorUsedError;
  int get subjectsPassed => throw _privateConstructorUsedError;
  int get classRank => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StudentOverallRankCopyWith<StudentOverallRank> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentOverallRankCopyWith<$Res> {
  factory $StudentOverallRankCopyWith(
          StudentOverallRank value, $Res Function(StudentOverallRank) then) =
      _$StudentOverallRankCopyWithImpl<$Res, StudentOverallRank>;
  @useResult
  $Res call(
      {String tenantId,
      String studentId,
      String studentName,
      String admissionNumber,
      String sectionId,
      String sectionName,
      String classId,
      String className,
      String examId,
      String examName,
      String examType,
      String academicYearId,
      double totalObtained,
      double totalMaxMarks,
      double overallPercentage,
      int subjectsCount,
      int subjectsPassed,
      int classRank});
}

/// @nodoc
class _$StudentOverallRankCopyWithImpl<$Res, $Val extends StudentOverallRank>
    implements $StudentOverallRankCopyWith<$Res> {
  _$StudentOverallRankCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? studentId = null,
    Object? studentName = null,
    Object? admissionNumber = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? classId = null,
    Object? className = null,
    Object? examId = null,
    Object? examName = null,
    Object? examType = null,
    Object? academicYearId = null,
    Object? totalObtained = null,
    Object? totalMaxMarks = null,
    Object? overallPercentage = null,
    Object? subjectsCount = null,
    Object? subjectsPassed = null,
    Object? classRank = null,
  }) {
    return _then(_value.copyWith(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      admissionNumber: null == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      examName: null == examName
          ? _value.examName
          : examName // ignore: cast_nullable_to_non_nullable
              as String,
      examType: null == examType
          ? _value.examType
          : examType // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      totalObtained: null == totalObtained
          ? _value.totalObtained
          : totalObtained // ignore: cast_nullable_to_non_nullable
              as double,
      totalMaxMarks: null == totalMaxMarks
          ? _value.totalMaxMarks
          : totalMaxMarks // ignore: cast_nullable_to_non_nullable
              as double,
      overallPercentage: null == overallPercentage
          ? _value.overallPercentage
          : overallPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      subjectsCount: null == subjectsCount
          ? _value.subjectsCount
          : subjectsCount // ignore: cast_nullable_to_non_nullable
              as int,
      subjectsPassed: null == subjectsPassed
          ? _value.subjectsPassed
          : subjectsPassed // ignore: cast_nullable_to_non_nullable
              as int,
      classRank: null == classRank
          ? _value.classRank
          : classRank // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudentOverallRankImplCopyWith<$Res>
    implements $StudentOverallRankCopyWith<$Res> {
  factory _$$StudentOverallRankImplCopyWith(_$StudentOverallRankImpl value,
          $Res Function(_$StudentOverallRankImpl) then) =
      __$$StudentOverallRankImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tenantId,
      String studentId,
      String studentName,
      String admissionNumber,
      String sectionId,
      String sectionName,
      String classId,
      String className,
      String examId,
      String examName,
      String examType,
      String academicYearId,
      double totalObtained,
      double totalMaxMarks,
      double overallPercentage,
      int subjectsCount,
      int subjectsPassed,
      int classRank});
}

/// @nodoc
class __$$StudentOverallRankImplCopyWithImpl<$Res>
    extends _$StudentOverallRankCopyWithImpl<$Res, _$StudentOverallRankImpl>
    implements _$$StudentOverallRankImplCopyWith<$Res> {
  __$$StudentOverallRankImplCopyWithImpl(_$StudentOverallRankImpl _value,
      $Res Function(_$StudentOverallRankImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? studentId = null,
    Object? studentName = null,
    Object? admissionNumber = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? classId = null,
    Object? className = null,
    Object? examId = null,
    Object? examName = null,
    Object? examType = null,
    Object? academicYearId = null,
    Object? totalObtained = null,
    Object? totalMaxMarks = null,
    Object? overallPercentage = null,
    Object? subjectsCount = null,
    Object? subjectsPassed = null,
    Object? classRank = null,
  }) {
    return _then(_$StudentOverallRankImpl(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      admissionNumber: null == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      examName: null == examName
          ? _value.examName
          : examName // ignore: cast_nullable_to_non_nullable
              as String,
      examType: null == examType
          ? _value.examType
          : examType // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      totalObtained: null == totalObtained
          ? _value.totalObtained
          : totalObtained // ignore: cast_nullable_to_non_nullable
              as double,
      totalMaxMarks: null == totalMaxMarks
          ? _value.totalMaxMarks
          : totalMaxMarks // ignore: cast_nullable_to_non_nullable
              as double,
      overallPercentage: null == overallPercentage
          ? _value.overallPercentage
          : overallPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      subjectsCount: null == subjectsCount
          ? _value.subjectsCount
          : subjectsCount // ignore: cast_nullable_to_non_nullable
              as int,
      subjectsPassed: null == subjectsPassed
          ? _value.subjectsPassed
          : subjectsPassed // ignore: cast_nullable_to_non_nullable
              as int,
      classRank: null == classRank
          ? _value.classRank
          : classRank // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentOverallRankImpl implements _StudentOverallRank {
  const _$StudentOverallRankImpl(
      {required this.tenantId,
      required this.studentId,
      required this.studentName,
      required this.admissionNumber,
      required this.sectionId,
      required this.sectionName,
      required this.classId,
      required this.className,
      required this.examId,
      required this.examName,
      required this.examType,
      required this.academicYearId,
      required this.totalObtained,
      required this.totalMaxMarks,
      required this.overallPercentage,
      required this.subjectsCount,
      required this.subjectsPassed,
      required this.classRank});

  factory _$StudentOverallRankImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentOverallRankImplFromJson(json);

  @override
  final String tenantId;
  @override
  final String studentId;
  @override
  final String studentName;
  @override
  final String admissionNumber;
  @override
  final String sectionId;
  @override
  final String sectionName;
  @override
  final String classId;
  @override
  final String className;
  @override
  final String examId;
  @override
  final String examName;
  @override
  final String examType;
  @override
  final String academicYearId;
  @override
  final double totalObtained;
  @override
  final double totalMaxMarks;
  @override
  final double overallPercentage;
  @override
  final int subjectsCount;
  @override
  final int subjectsPassed;
  @override
  final int classRank;

  @override
  String toString() {
    return 'StudentOverallRank(tenantId: $tenantId, studentId: $studentId, studentName: $studentName, admissionNumber: $admissionNumber, sectionId: $sectionId, sectionName: $sectionName, classId: $classId, className: $className, examId: $examId, examName: $examName, examType: $examType, academicYearId: $academicYearId, totalObtained: $totalObtained, totalMaxMarks: $totalMaxMarks, overallPercentage: $overallPercentage, subjectsCount: $subjectsCount, subjectsPassed: $subjectsPassed, classRank: $classRank)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentOverallRankImpl &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.admissionNumber, admissionNumber) ||
                other.admissionNumber == admissionNumber) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.examId, examId) || other.examId == examId) &&
            (identical(other.examName, examName) ||
                other.examName == examName) &&
            (identical(other.examType, examType) ||
                other.examType == examType) &&
            (identical(other.academicYearId, academicYearId) ||
                other.academicYearId == academicYearId) &&
            (identical(other.totalObtained, totalObtained) ||
                other.totalObtained == totalObtained) &&
            (identical(other.totalMaxMarks, totalMaxMarks) ||
                other.totalMaxMarks == totalMaxMarks) &&
            (identical(other.overallPercentage, overallPercentage) ||
                other.overallPercentage == overallPercentage) &&
            (identical(other.subjectsCount, subjectsCount) ||
                other.subjectsCount == subjectsCount) &&
            (identical(other.subjectsPassed, subjectsPassed) ||
                other.subjectsPassed == subjectsPassed) &&
            (identical(other.classRank, classRank) ||
                other.classRank == classRank));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      tenantId,
      studentId,
      studentName,
      admissionNumber,
      sectionId,
      sectionName,
      classId,
      className,
      examId,
      examName,
      examType,
      academicYearId,
      totalObtained,
      totalMaxMarks,
      overallPercentage,
      subjectsCount,
      subjectsPassed,
      classRank);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentOverallRankImplCopyWith<_$StudentOverallRankImpl> get copyWith =>
      __$$StudentOverallRankImplCopyWithImpl<_$StudentOverallRankImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentOverallRankImplToJson(
      this,
    );
  }
}

abstract class _StudentOverallRank implements StudentOverallRank {
  const factory _StudentOverallRank(
      {required final String tenantId,
      required final String studentId,
      required final String studentName,
      required final String admissionNumber,
      required final String sectionId,
      required final String sectionName,
      required final String classId,
      required final String className,
      required final String examId,
      required final String examName,
      required final String examType,
      required final String academicYearId,
      required final double totalObtained,
      required final double totalMaxMarks,
      required final double overallPercentage,
      required final int subjectsCount,
      required final int subjectsPassed,
      required final int classRank}) = _$StudentOverallRankImpl;

  factory _StudentOverallRank.fromJson(Map<String, dynamic> json) =
      _$StudentOverallRankImpl.fromJson;

  @override
  String get tenantId;
  @override
  String get studentId;
  @override
  String get studentName;
  @override
  String get admissionNumber;
  @override
  String get sectionId;
  @override
  String get sectionName;
  @override
  String get classId;
  @override
  String get className;
  @override
  String get examId;
  @override
  String get examName;
  @override
  String get examType;
  @override
  String get academicYearId;
  @override
  double get totalObtained;
  @override
  double get totalMaxMarks;
  @override
  double get overallPercentage;
  @override
  int get subjectsCount;
  @override
  int get subjectsPassed;
  @override
  int get classRank;
  @override
  @JsonKey(ignore: true)
  _$$StudentOverallRankImplCopyWith<_$StudentOverallRankImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClassExamStats _$ClassExamStatsFromJson(Map<String, dynamic> json) {
  return _ClassExamStats.fromJson(json);
}

/// @nodoc
mixin _$ClassExamStats {
  String get tenantId => throw _privateConstructorUsedError;
  String get examId => throw _privateConstructorUsedError;
  String get examName => throw _privateConstructorUsedError;
  String get examType => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String get sectionName => throw _privateConstructorUsedError;
  String get classId => throw _privateConstructorUsedError;
  String get className => throw _privateConstructorUsedError;
  String get subjectId => throw _privateConstructorUsedError;
  String get subjectName => throw _privateConstructorUsedError;
  String get academicYearId => throw _privateConstructorUsedError;
  int get totalStudents => throw _privateConstructorUsedError;
  int get studentsAppeared => throw _privateConstructorUsedError;
  double get classAverage => throw _privateConstructorUsedError;
  double get highestPercentage => throw _privateConstructorUsedError;
  double get lowestPercentage => throw _privateConstructorUsedError;
  int get passedCount => throw _privateConstructorUsedError;
  int get failedCount => throw _privateConstructorUsedError;
  int get absentCount => throw _privateConstructorUsedError;
  double get passPercentage => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ClassExamStatsCopyWith<ClassExamStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClassExamStatsCopyWith<$Res> {
  factory $ClassExamStatsCopyWith(
          ClassExamStats value, $Res Function(ClassExamStats) then) =
      _$ClassExamStatsCopyWithImpl<$Res, ClassExamStats>;
  @useResult
  $Res call(
      {String tenantId,
      String examId,
      String examName,
      String examType,
      String sectionId,
      String sectionName,
      String classId,
      String className,
      String subjectId,
      String subjectName,
      String academicYearId,
      int totalStudents,
      int studentsAppeared,
      double classAverage,
      double highestPercentage,
      double lowestPercentage,
      int passedCount,
      int failedCount,
      int absentCount,
      double passPercentage});
}

/// @nodoc
class _$ClassExamStatsCopyWithImpl<$Res, $Val extends ClassExamStats>
    implements $ClassExamStatsCopyWith<$Res> {
  _$ClassExamStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? examId = null,
    Object? examName = null,
    Object? examType = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? classId = null,
    Object? className = null,
    Object? subjectId = null,
    Object? subjectName = null,
    Object? academicYearId = null,
    Object? totalStudents = null,
    Object? studentsAppeared = null,
    Object? classAverage = null,
    Object? highestPercentage = null,
    Object? lowestPercentage = null,
    Object? passedCount = null,
    Object? failedCount = null,
    Object? absentCount = null,
    Object? passPercentage = null,
  }) {
    return _then(_value.copyWith(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      examName: null == examName
          ? _value.examName
          : examName // ignore: cast_nullable_to_non_nullable
              as String,
      examType: null == examType
          ? _value.examType
          : examType // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      totalStudents: null == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int,
      studentsAppeared: null == studentsAppeared
          ? _value.studentsAppeared
          : studentsAppeared // ignore: cast_nullable_to_non_nullable
              as int,
      classAverage: null == classAverage
          ? _value.classAverage
          : classAverage // ignore: cast_nullable_to_non_nullable
              as double,
      highestPercentage: null == highestPercentage
          ? _value.highestPercentage
          : highestPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      lowestPercentage: null == lowestPercentage
          ? _value.lowestPercentage
          : lowestPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      passedCount: null == passedCount
          ? _value.passedCount
          : passedCount // ignore: cast_nullable_to_non_nullable
              as int,
      failedCount: null == failedCount
          ? _value.failedCount
          : failedCount // ignore: cast_nullable_to_non_nullable
              as int,
      absentCount: null == absentCount
          ? _value.absentCount
          : absentCount // ignore: cast_nullable_to_non_nullable
              as int,
      passPercentage: null == passPercentage
          ? _value.passPercentage
          : passPercentage // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClassExamStatsImplCopyWith<$Res>
    implements $ClassExamStatsCopyWith<$Res> {
  factory _$$ClassExamStatsImplCopyWith(_$ClassExamStatsImpl value,
          $Res Function(_$ClassExamStatsImpl) then) =
      __$$ClassExamStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tenantId,
      String examId,
      String examName,
      String examType,
      String sectionId,
      String sectionName,
      String classId,
      String className,
      String subjectId,
      String subjectName,
      String academicYearId,
      int totalStudents,
      int studentsAppeared,
      double classAverage,
      double highestPercentage,
      double lowestPercentage,
      int passedCount,
      int failedCount,
      int absentCount,
      double passPercentage});
}

/// @nodoc
class __$$ClassExamStatsImplCopyWithImpl<$Res>
    extends _$ClassExamStatsCopyWithImpl<$Res, _$ClassExamStatsImpl>
    implements _$$ClassExamStatsImplCopyWith<$Res> {
  __$$ClassExamStatsImplCopyWithImpl(
      _$ClassExamStatsImpl _value, $Res Function(_$ClassExamStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? examId = null,
    Object? examName = null,
    Object? examType = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? classId = null,
    Object? className = null,
    Object? subjectId = null,
    Object? subjectName = null,
    Object? academicYearId = null,
    Object? totalStudents = null,
    Object? studentsAppeared = null,
    Object? classAverage = null,
    Object? highestPercentage = null,
    Object? lowestPercentage = null,
    Object? passedCount = null,
    Object? failedCount = null,
    Object? absentCount = null,
    Object? passPercentage = null,
  }) {
    return _then(_$ClassExamStatsImpl(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      examId: null == examId
          ? _value.examId
          : examId // ignore: cast_nullable_to_non_nullable
              as String,
      examName: null == examName
          ? _value.examName
          : examName // ignore: cast_nullable_to_non_nullable
              as String,
      examType: null == examType
          ? _value.examType
          : examType // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      totalStudents: null == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int,
      studentsAppeared: null == studentsAppeared
          ? _value.studentsAppeared
          : studentsAppeared // ignore: cast_nullable_to_non_nullable
              as int,
      classAverage: null == classAverage
          ? _value.classAverage
          : classAverage // ignore: cast_nullable_to_non_nullable
              as double,
      highestPercentage: null == highestPercentage
          ? _value.highestPercentage
          : highestPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      lowestPercentage: null == lowestPercentage
          ? _value.lowestPercentage
          : lowestPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      passedCount: null == passedCount
          ? _value.passedCount
          : passedCount // ignore: cast_nullable_to_non_nullable
              as int,
      failedCount: null == failedCount
          ? _value.failedCount
          : failedCount // ignore: cast_nullable_to_non_nullable
              as int,
      absentCount: null == absentCount
          ? _value.absentCount
          : absentCount // ignore: cast_nullable_to_non_nullable
              as int,
      passPercentage: null == passPercentage
          ? _value.passPercentage
          : passPercentage // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClassExamStatsImpl implements _ClassExamStats {
  const _$ClassExamStatsImpl(
      {required this.tenantId,
      required this.examId,
      required this.examName,
      required this.examType,
      required this.sectionId,
      required this.sectionName,
      required this.classId,
      required this.className,
      required this.subjectId,
      required this.subjectName,
      required this.academicYearId,
      required this.totalStudents,
      required this.studentsAppeared,
      required this.classAverage,
      required this.highestPercentage,
      required this.lowestPercentage,
      required this.passedCount,
      required this.failedCount,
      required this.absentCount,
      required this.passPercentage});

  factory _$ClassExamStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClassExamStatsImplFromJson(json);

  @override
  final String tenantId;
  @override
  final String examId;
  @override
  final String examName;
  @override
  final String examType;
  @override
  final String sectionId;
  @override
  final String sectionName;
  @override
  final String classId;
  @override
  final String className;
  @override
  final String subjectId;
  @override
  final String subjectName;
  @override
  final String academicYearId;
  @override
  final int totalStudents;
  @override
  final int studentsAppeared;
  @override
  final double classAverage;
  @override
  final double highestPercentage;
  @override
  final double lowestPercentage;
  @override
  final int passedCount;
  @override
  final int failedCount;
  @override
  final int absentCount;
  @override
  final double passPercentage;

  @override
  String toString() {
    return 'ClassExamStats(tenantId: $tenantId, examId: $examId, examName: $examName, examType: $examType, sectionId: $sectionId, sectionName: $sectionName, classId: $classId, className: $className, subjectId: $subjectId, subjectName: $subjectName, academicYearId: $academicYearId, totalStudents: $totalStudents, studentsAppeared: $studentsAppeared, classAverage: $classAverage, highestPercentage: $highestPercentage, lowestPercentage: $lowestPercentage, passedCount: $passedCount, failedCount: $failedCount, absentCount: $absentCount, passPercentage: $passPercentage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClassExamStatsImpl &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.examId, examId) || other.examId == examId) &&
            (identical(other.examName, examName) ||
                other.examName == examName) &&
            (identical(other.examType, examType) ||
                other.examType == examType) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.academicYearId, academicYearId) ||
                other.academicYearId == academicYearId) &&
            (identical(other.totalStudents, totalStudents) ||
                other.totalStudents == totalStudents) &&
            (identical(other.studentsAppeared, studentsAppeared) ||
                other.studentsAppeared == studentsAppeared) &&
            (identical(other.classAverage, classAverage) ||
                other.classAverage == classAverage) &&
            (identical(other.highestPercentage, highestPercentage) ||
                other.highestPercentage == highestPercentage) &&
            (identical(other.lowestPercentage, lowestPercentage) ||
                other.lowestPercentage == lowestPercentage) &&
            (identical(other.passedCount, passedCount) ||
                other.passedCount == passedCount) &&
            (identical(other.failedCount, failedCount) ||
                other.failedCount == failedCount) &&
            (identical(other.absentCount, absentCount) ||
                other.absentCount == absentCount) &&
            (identical(other.passPercentage, passPercentage) ||
                other.passPercentage == passPercentage));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        tenantId,
        examId,
        examName,
        examType,
        sectionId,
        sectionName,
        classId,
        className,
        subjectId,
        subjectName,
        academicYearId,
        totalStudents,
        studentsAppeared,
        classAverage,
        highestPercentage,
        lowestPercentage,
        passedCount,
        failedCount,
        absentCount,
        passPercentage
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ClassExamStatsImplCopyWith<_$ClassExamStatsImpl> get copyWith =>
      __$$ClassExamStatsImplCopyWithImpl<_$ClassExamStatsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClassExamStatsImplToJson(
      this,
    );
  }
}

abstract class _ClassExamStats implements ClassExamStats {
  const factory _ClassExamStats(
      {required final String tenantId,
      required final String examId,
      required final String examName,
      required final String examType,
      required final String sectionId,
      required final String sectionName,
      required final String classId,
      required final String className,
      required final String subjectId,
      required final String subjectName,
      required final String academicYearId,
      required final int totalStudents,
      required final int studentsAppeared,
      required final double classAverage,
      required final double highestPercentage,
      required final double lowestPercentage,
      required final int passedCount,
      required final int failedCount,
      required final int absentCount,
      required final double passPercentage}) = _$ClassExamStatsImpl;

  factory _ClassExamStats.fromJson(Map<String, dynamic> json) =
      _$ClassExamStatsImpl.fromJson;

  @override
  String get tenantId;
  @override
  String get examId;
  @override
  String get examName;
  @override
  String get examType;
  @override
  String get sectionId;
  @override
  String get sectionName;
  @override
  String get classId;
  @override
  String get className;
  @override
  String get subjectId;
  @override
  String get subjectName;
  @override
  String get academicYearId;
  @override
  int get totalStudents;
  @override
  int get studentsAppeared;
  @override
  double get classAverage;
  @override
  double get highestPercentage;
  @override
  double get lowestPercentage;
  @override
  int get passedCount;
  @override
  int get failedCount;
  @override
  int get absentCount;
  @override
  double get passPercentage;
  @override
  @JsonKey(ignore: true)
  _$$ClassExamStatsImplCopyWith<_$ClassExamStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GradeScale _$GradeScaleFromJson(Map<String, dynamic> json) {
  return _GradeScale.fromJson(json);
}

/// @nodoc
mixin _$GradeScale {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  List<GradeScaleItem>? get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GradeScaleCopyWith<GradeScale> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GradeScaleCopyWith<$Res> {
  factory $GradeScaleCopyWith(
          GradeScale value, $Res Function(GradeScale) then) =
      _$GradeScaleCopyWithImpl<$Res, GradeScale>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String name,
      bool isDefault,
      DateTime? createdAt,
      List<GradeScaleItem>? items});
}

/// @nodoc
class _$GradeScaleCopyWithImpl<$Res, $Val extends GradeScale>
    implements $GradeScaleCopyWith<$Res> {
  _$GradeScaleCopyWithImpl(this._value, this._then);

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
    Object? isDefault = null,
    Object? createdAt = freezed,
    Object? items = freezed,
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
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      items: freezed == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<GradeScaleItem>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GradeScaleImplCopyWith<$Res>
    implements $GradeScaleCopyWith<$Res> {
  factory _$$GradeScaleImplCopyWith(
          _$GradeScaleImpl value, $Res Function(_$GradeScaleImpl) then) =
      __$$GradeScaleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String name,
      bool isDefault,
      DateTime? createdAt,
      List<GradeScaleItem>? items});
}

/// @nodoc
class __$$GradeScaleImplCopyWithImpl<$Res>
    extends _$GradeScaleCopyWithImpl<$Res, _$GradeScaleImpl>
    implements _$$GradeScaleImplCopyWith<$Res> {
  __$$GradeScaleImplCopyWithImpl(
      _$GradeScaleImpl _value, $Res Function(_$GradeScaleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? name = null,
    Object? isDefault = null,
    Object? createdAt = freezed,
    Object? items = freezed,
  }) {
    return _then(_$GradeScaleImpl(
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
      isDefault: null == isDefault
          ? _value.isDefault
          : isDefault // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      items: freezed == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<GradeScaleItem>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GradeScaleImpl implements _GradeScale {
  const _$GradeScaleImpl(
      {required this.id,
      required this.tenantId,
      required this.name,
      this.isDefault = false,
      this.createdAt,
      final List<GradeScaleItem>? items})
      : _items = items;

  factory _$GradeScaleImpl.fromJson(Map<String, dynamic> json) =>
      _$$GradeScaleImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isDefault;
  @override
  final DateTime? createdAt;
  final List<GradeScaleItem>? _items;
  @override
  List<GradeScaleItem>? get items {
    final value = _items;
    if (value == null) return null;
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'GradeScale(id: $id, tenantId: $tenantId, name: $name, isDefault: $isDefault, createdAt: $createdAt, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GradeScaleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, tenantId, name, isDefault,
      createdAt, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GradeScaleImplCopyWith<_$GradeScaleImpl> get copyWith =>
      __$$GradeScaleImplCopyWithImpl<_$GradeScaleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GradeScaleImplToJson(
      this,
    );
  }
}

abstract class _GradeScale implements GradeScale {
  const factory _GradeScale(
      {required final String id,
      required final String tenantId,
      required final String name,
      final bool isDefault,
      final DateTime? createdAt,
      final List<GradeScaleItem>? items}) = _$GradeScaleImpl;

  factory _GradeScale.fromJson(Map<String, dynamic> json) =
      _$GradeScaleImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get name;
  @override
  bool get isDefault;
  @override
  DateTime? get createdAt;
  @override
  List<GradeScaleItem>? get items;
  @override
  @JsonKey(ignore: true)
  _$$GradeScaleImplCopyWith<_$GradeScaleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GradeScaleItem _$GradeScaleItemFromJson(Map<String, dynamic> json) {
  return _GradeScaleItem.fromJson(json);
}

/// @nodoc
mixin _$GradeScaleItem {
  String get id => throw _privateConstructorUsedError;
  String get gradeScaleId => throw _privateConstructorUsedError;
  String get grade => throw _privateConstructorUsedError;
  double get minPercentage => throw _privateConstructorUsedError;
  double get maxPercentage => throw _privateConstructorUsedError;
  double? get gradePoint => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GradeScaleItemCopyWith<GradeScaleItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GradeScaleItemCopyWith<$Res> {
  factory $GradeScaleItemCopyWith(
          GradeScaleItem value, $Res Function(GradeScaleItem) then) =
      _$GradeScaleItemCopyWithImpl<$Res, GradeScaleItem>;
  @useResult
  $Res call(
      {String id,
      String gradeScaleId,
      String grade,
      double minPercentage,
      double maxPercentage,
      double? gradePoint,
      String? description});
}

/// @nodoc
class _$GradeScaleItemCopyWithImpl<$Res, $Val extends GradeScaleItem>
    implements $GradeScaleItemCopyWith<$Res> {
  _$GradeScaleItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gradeScaleId = null,
    Object? grade = null,
    Object? minPercentage = null,
    Object? maxPercentage = null,
    Object? gradePoint = freezed,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      gradeScaleId: null == gradeScaleId
          ? _value.gradeScaleId
          : gradeScaleId // ignore: cast_nullable_to_non_nullable
              as String,
      grade: null == grade
          ? _value.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as String,
      minPercentage: null == minPercentage
          ? _value.minPercentage
          : minPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      maxPercentage: null == maxPercentage
          ? _value.maxPercentage
          : maxPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      gradePoint: freezed == gradePoint
          ? _value.gradePoint
          : gradePoint // ignore: cast_nullable_to_non_nullable
              as double?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GradeScaleItemImplCopyWith<$Res>
    implements $GradeScaleItemCopyWith<$Res> {
  factory _$$GradeScaleItemImplCopyWith(_$GradeScaleItemImpl value,
          $Res Function(_$GradeScaleItemImpl) then) =
      __$$GradeScaleItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String gradeScaleId,
      String grade,
      double minPercentage,
      double maxPercentage,
      double? gradePoint,
      String? description});
}

/// @nodoc
class __$$GradeScaleItemImplCopyWithImpl<$Res>
    extends _$GradeScaleItemCopyWithImpl<$Res, _$GradeScaleItemImpl>
    implements _$$GradeScaleItemImplCopyWith<$Res> {
  __$$GradeScaleItemImplCopyWithImpl(
      _$GradeScaleItemImpl _value, $Res Function(_$GradeScaleItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gradeScaleId = null,
    Object? grade = null,
    Object? minPercentage = null,
    Object? maxPercentage = null,
    Object? gradePoint = freezed,
    Object? description = freezed,
  }) {
    return _then(_$GradeScaleItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      gradeScaleId: null == gradeScaleId
          ? _value.gradeScaleId
          : gradeScaleId // ignore: cast_nullable_to_non_nullable
              as String,
      grade: null == grade
          ? _value.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as String,
      minPercentage: null == minPercentage
          ? _value.minPercentage
          : minPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      maxPercentage: null == maxPercentage
          ? _value.maxPercentage
          : maxPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      gradePoint: freezed == gradePoint
          ? _value.gradePoint
          : gradePoint // ignore: cast_nullable_to_non_nullable
              as double?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GradeScaleItemImpl implements _GradeScaleItem {
  const _$GradeScaleItemImpl(
      {required this.id,
      required this.gradeScaleId,
      required this.grade,
      required this.minPercentage,
      required this.maxPercentage,
      this.gradePoint,
      this.description});

  factory _$GradeScaleItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$GradeScaleItemImplFromJson(json);

  @override
  final String id;
  @override
  final String gradeScaleId;
  @override
  final String grade;
  @override
  final double minPercentage;
  @override
  final double maxPercentage;
  @override
  final double? gradePoint;
  @override
  final String? description;

  @override
  String toString() {
    return 'GradeScaleItem(id: $id, gradeScaleId: $gradeScaleId, grade: $grade, minPercentage: $minPercentage, maxPercentage: $maxPercentage, gradePoint: $gradePoint, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GradeScaleItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.gradeScaleId, gradeScaleId) ||
                other.gradeScaleId == gradeScaleId) &&
            (identical(other.grade, grade) || other.grade == grade) &&
            (identical(other.minPercentage, minPercentage) ||
                other.minPercentage == minPercentage) &&
            (identical(other.maxPercentage, maxPercentage) ||
                other.maxPercentage == maxPercentage) &&
            (identical(other.gradePoint, gradePoint) ||
                other.gradePoint == gradePoint) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, gradeScaleId, grade,
      minPercentage, maxPercentage, gradePoint, description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GradeScaleItemImplCopyWith<_$GradeScaleItemImpl> get copyWith =>
      __$$GradeScaleItemImplCopyWithImpl<_$GradeScaleItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GradeScaleItemImplToJson(
      this,
    );
  }
}

abstract class _GradeScaleItem implements GradeScaleItem {
  const factory _GradeScaleItem(
      {required final String id,
      required final String gradeScaleId,
      required final String grade,
      required final double minPercentage,
      required final double maxPercentage,
      final double? gradePoint,
      final String? description}) = _$GradeScaleItemImpl;

  factory _GradeScaleItem.fromJson(Map<String, dynamic> json) =
      _$GradeScaleItemImpl.fromJson;

  @override
  String get id;
  @override
  String get gradeScaleId;
  @override
  String get grade;
  @override
  double get minPercentage;
  @override
  double get maxPercentage;
  @override
  double? get gradePoint;
  @override
  String? get description;
  @override
  @JsonKey(ignore: true)
  _$$GradeScaleItemImplCopyWith<_$GradeScaleItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
