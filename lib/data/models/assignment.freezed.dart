// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assignment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Assignment _$AssignmentFromJson(Map<String, dynamic> json) {
  return _Assignment.fromJson(json);
}

/// @nodoc
mixin _$Assignment {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String get subjectId => throw _privateConstructorUsedError;
  String get teacherId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get instructions => throw _privateConstructorUsedError;
  DateTime get dueDate => throw _privateConstructorUsedError;
  double? get maxMarks => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get attachments =>
      throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  bool get allowLateSubmission => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError; // Joined data
  String? get sectionName => throw _privateConstructorUsedError;
  String? get className => throw _privateConstructorUsedError;
  String? get subjectName => throw _privateConstructorUsedError;
  String? get subjectCode => throw _privateConstructorUsedError;
  String? get teacherName => throw _privateConstructorUsedError; // Summary
  int? get totalStudents => throw _privateConstructorUsedError;
  int? get submittedCount => throw _privateConstructorUsedError;
  int? get gradedCount => throw _privateConstructorUsedError;
  int? get lateCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AssignmentCopyWith<Assignment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssignmentCopyWith<$Res> {
  factory $AssignmentCopyWith(
          Assignment value, $Res Function(Assignment) then) =
      _$AssignmentCopyWithImpl<$Res, Assignment>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String sectionId,
      String subjectId,
      String teacherId,
      String title,
      String? description,
      String? instructions,
      DateTime dueDate,
      double? maxMarks,
      List<Map<String, dynamic>> attachments,
      String status,
      bool allowLateSubmission,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? sectionName,
      String? className,
      String? subjectName,
      String? subjectCode,
      String? teacherName,
      int? totalStudents,
      int? submittedCount,
      int? gradedCount,
      int? lateCount});
}

/// @nodoc
class _$AssignmentCopyWithImpl<$Res, $Val extends Assignment>
    implements $AssignmentCopyWith<$Res> {
  _$AssignmentCopyWithImpl(this._value, this._then);

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
    Object? subjectId = null,
    Object? teacherId = null,
    Object? title = null,
    Object? description = freezed,
    Object? instructions = freezed,
    Object? dueDate = null,
    Object? maxMarks = freezed,
    Object? attachments = null,
    Object? status = null,
    Object? allowLateSubmission = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? sectionName = freezed,
    Object? className = freezed,
    Object? subjectName = freezed,
    Object? subjectCode = freezed,
    Object? teacherName = freezed,
    Object? totalStudents = freezed,
    Object? submittedCount = freezed,
    Object? gradedCount = freezed,
    Object? lateCount = freezed,
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
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      teacherId: null == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      instructions: freezed == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as String?,
      dueDate: null == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      maxMarks: freezed == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double?,
      attachments: null == attachments
          ? _value.attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      allowLateSubmission: null == allowLateSubmission
          ? _value.allowLateSubmission
          : allowLateSubmission // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sectionName: freezed == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String?,
      className: freezed == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String?,
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
      totalStudents: freezed == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int?,
      submittedCount: freezed == submittedCount
          ? _value.submittedCount
          : submittedCount // ignore: cast_nullable_to_non_nullable
              as int?,
      gradedCount: freezed == gradedCount
          ? _value.gradedCount
          : gradedCount // ignore: cast_nullable_to_non_nullable
              as int?,
      lateCount: freezed == lateCount
          ? _value.lateCount
          : lateCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AssignmentImplCopyWith<$Res>
    implements $AssignmentCopyWith<$Res> {
  factory _$$AssignmentImplCopyWith(
          _$AssignmentImpl value, $Res Function(_$AssignmentImpl) then) =
      __$$AssignmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String sectionId,
      String subjectId,
      String teacherId,
      String title,
      String? description,
      String? instructions,
      DateTime dueDate,
      double? maxMarks,
      List<Map<String, dynamic>> attachments,
      String status,
      bool allowLateSubmission,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? sectionName,
      String? className,
      String? subjectName,
      String? subjectCode,
      String? teacherName,
      int? totalStudents,
      int? submittedCount,
      int? gradedCount,
      int? lateCount});
}

/// @nodoc
class __$$AssignmentImplCopyWithImpl<$Res>
    extends _$AssignmentCopyWithImpl<$Res, _$AssignmentImpl>
    implements _$$AssignmentImplCopyWith<$Res> {
  __$$AssignmentImplCopyWithImpl(
      _$AssignmentImpl _value, $Res Function(_$AssignmentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? sectionId = null,
    Object? subjectId = null,
    Object? teacherId = null,
    Object? title = null,
    Object? description = freezed,
    Object? instructions = freezed,
    Object? dueDate = null,
    Object? maxMarks = freezed,
    Object? attachments = null,
    Object? status = null,
    Object? allowLateSubmission = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? sectionName = freezed,
    Object? className = freezed,
    Object? subjectName = freezed,
    Object? subjectCode = freezed,
    Object? teacherName = freezed,
    Object? totalStudents = freezed,
    Object? submittedCount = freezed,
    Object? gradedCount = freezed,
    Object? lateCount = freezed,
  }) {
    return _then(_$AssignmentImpl(
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
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      teacherId: null == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      instructions: freezed == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as String?,
      dueDate: null == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      maxMarks: freezed == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double?,
      attachments: null == attachments
          ? _value._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      allowLateSubmission: null == allowLateSubmission
          ? _value.allowLateSubmission
          : allowLateSubmission // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sectionName: freezed == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String?,
      className: freezed == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String?,
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
      totalStudents: freezed == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int?,
      submittedCount: freezed == submittedCount
          ? _value.submittedCount
          : submittedCount // ignore: cast_nullable_to_non_nullable
              as int?,
      gradedCount: freezed == gradedCount
          ? _value.gradedCount
          : gradedCount // ignore: cast_nullable_to_non_nullable
              as int?,
      lateCount: freezed == lateCount
          ? _value.lateCount
          : lateCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AssignmentImpl implements _Assignment {
  const _$AssignmentImpl(
      {required this.id,
      required this.tenantId,
      required this.sectionId,
      required this.subjectId,
      required this.teacherId,
      required this.title,
      this.description,
      this.instructions,
      required this.dueDate,
      this.maxMarks,
      final List<Map<String, dynamic>> attachments = const [],
      this.status = 'draft',
      this.allowLateSubmission = false,
      this.createdAt,
      this.updatedAt,
      this.sectionName,
      this.className,
      this.subjectName,
      this.subjectCode,
      this.teacherName,
      this.totalStudents,
      this.submittedCount,
      this.gradedCount,
      this.lateCount})
      : _attachments = attachments;

  factory _$AssignmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssignmentImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String sectionId;
  @override
  final String subjectId;
  @override
  final String teacherId;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? instructions;
  @override
  final DateTime dueDate;
  @override
  final double? maxMarks;
  final List<Map<String, dynamic>> _attachments;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final bool allowLateSubmission;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
// Joined data
  @override
  final String? sectionName;
  @override
  final String? className;
  @override
  final String? subjectName;
  @override
  final String? subjectCode;
  @override
  final String? teacherName;
// Summary
  @override
  final int? totalStudents;
  @override
  final int? submittedCount;
  @override
  final int? gradedCount;
  @override
  final int? lateCount;

  @override
  String toString() {
    return 'Assignment(id: $id, tenantId: $tenantId, sectionId: $sectionId, subjectId: $subjectId, teacherId: $teacherId, title: $title, description: $description, instructions: $instructions, dueDate: $dueDate, maxMarks: $maxMarks, attachments: $attachments, status: $status, allowLateSubmission: $allowLateSubmission, createdAt: $createdAt, updatedAt: $updatedAt, sectionName: $sectionName, className: $className, subjectName: $subjectName, subjectCode: $subjectCode, teacherName: $teacherName, totalStudents: $totalStudents, submittedCount: $submittedCount, gradedCount: $gradedCount, lateCount: $lateCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssignmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.teacherId, teacherId) ||
                other.teacherId == teacherId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.instructions, instructions) ||
                other.instructions == instructions) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.maxMarks, maxMarks) ||
                other.maxMarks == maxMarks) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.allowLateSubmission, allowLateSubmission) ||
                other.allowLateSubmission == allowLateSubmission) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.subjectCode, subjectCode) ||
                other.subjectCode == subjectCode) &&
            (identical(other.teacherName, teacherName) ||
                other.teacherName == teacherName) &&
            (identical(other.totalStudents, totalStudents) ||
                other.totalStudents == totalStudents) &&
            (identical(other.submittedCount, submittedCount) ||
                other.submittedCount == submittedCount) &&
            (identical(other.gradedCount, gradedCount) ||
                other.gradedCount == gradedCount) &&
            (identical(other.lateCount, lateCount) ||
                other.lateCount == lateCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        tenantId,
        sectionId,
        subjectId,
        teacherId,
        title,
        description,
        instructions,
        dueDate,
        maxMarks,
        const DeepCollectionEquality().hash(_attachments),
        status,
        allowLateSubmission,
        createdAt,
        updatedAt,
        sectionName,
        className,
        subjectName,
        subjectCode,
        teacherName,
        totalStudents,
        submittedCount,
        gradedCount,
        lateCount
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AssignmentImplCopyWith<_$AssignmentImpl> get copyWith =>
      __$$AssignmentImplCopyWithImpl<_$AssignmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssignmentImplToJson(
      this,
    );
  }
}

abstract class _Assignment implements Assignment {
  const factory _Assignment(
      {required final String id,
      required final String tenantId,
      required final String sectionId,
      required final String subjectId,
      required final String teacherId,
      required final String title,
      final String? description,
      final String? instructions,
      required final DateTime dueDate,
      final double? maxMarks,
      final List<Map<String, dynamic>> attachments,
      final String status,
      final bool allowLateSubmission,
      final DateTime? createdAt,
      final DateTime? updatedAt,
      final String? sectionName,
      final String? className,
      final String? subjectName,
      final String? subjectCode,
      final String? teacherName,
      final int? totalStudents,
      final int? submittedCount,
      final int? gradedCount,
      final int? lateCount}) = _$AssignmentImpl;

  factory _Assignment.fromJson(Map<String, dynamic> json) =
      _$AssignmentImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get sectionId;
  @override
  String get subjectId;
  @override
  String get teacherId;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get instructions;
  @override
  DateTime get dueDate;
  @override
  double? get maxMarks;
  @override
  List<Map<String, dynamic>> get attachments;
  @override
  String get status;
  @override
  bool get allowLateSubmission;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override // Joined data
  String? get sectionName;
  @override
  String? get className;
  @override
  String? get subjectName;
  @override
  String? get subjectCode;
  @override
  String? get teacherName;
  @override // Summary
  int? get totalStudents;
  @override
  int? get submittedCount;
  @override
  int? get gradedCount;
  @override
  int? get lateCount;
  @override
  @JsonKey(ignore: true)
  _$$AssignmentImplCopyWith<_$AssignmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Submission _$SubmissionFromJson(Map<String, dynamic> json) {
  return _Submission.fromJson(json);
}

/// @nodoc
mixin _$Submission {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get assignmentId => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get attachments =>
      throw _privateConstructorUsedError;
  DateTime? get submittedAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  double? get marksObtained => throw _privateConstructorUsedError;
  String? get feedback => throw _privateConstructorUsedError;
  String? get gradedBy => throw _privateConstructorUsedError;
  DateTime? get gradedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError; // Joined data
  String? get studentName => throw _privateConstructorUsedError;
  String? get admissionNumber => throw _privateConstructorUsedError;
  String? get assignmentTitle => throw _privateConstructorUsedError;
  double? get maxMarks => throw _privateConstructorUsedError;
  DateTime? get dueDate => throw _privateConstructorUsedError;
  String? get gradedByName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SubmissionCopyWith<Submission> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubmissionCopyWith<$Res> {
  factory $SubmissionCopyWith(
          Submission value, $Res Function(Submission) then) =
      _$SubmissionCopyWithImpl<$Res, Submission>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String assignmentId,
      String studentId,
      String? content,
      List<Map<String, dynamic>> attachments,
      DateTime? submittedAt,
      String status,
      double? marksObtained,
      String? feedback,
      String? gradedBy,
      DateTime? gradedAt,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? studentName,
      String? admissionNumber,
      String? assignmentTitle,
      double? maxMarks,
      DateTime? dueDate,
      String? gradedByName});
}

/// @nodoc
class _$SubmissionCopyWithImpl<$Res, $Val extends Submission>
    implements $SubmissionCopyWith<$Res> {
  _$SubmissionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? assignmentId = null,
    Object? studentId = null,
    Object? content = freezed,
    Object? attachments = null,
    Object? submittedAt = freezed,
    Object? status = null,
    Object? marksObtained = freezed,
    Object? feedback = freezed,
    Object? gradedBy = freezed,
    Object? gradedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? studentName = freezed,
    Object? admissionNumber = freezed,
    Object? assignmentTitle = freezed,
    Object? maxMarks = freezed,
    Object? dueDate = freezed,
    Object? gradedByName = freezed,
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
      assignmentId: null == assignmentId
          ? _value.assignmentId
          : assignmentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      attachments: null == attachments
          ? _value.attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      marksObtained: freezed == marksObtained
          ? _value.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double?,
      feedback: freezed == feedback
          ? _value.feedback
          : feedback // ignore: cast_nullable_to_non_nullable
              as String?,
      gradedBy: freezed == gradedBy
          ? _value.gradedBy
          : gradedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      gradedAt: freezed == gradedAt
          ? _value.gradedAt
          : gradedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
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
      assignmentTitle: freezed == assignmentTitle
          ? _value.assignmentTitle
          : assignmentTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      maxMarks: freezed == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double?,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gradedByName: freezed == gradedByName
          ? _value.gradedByName
          : gradedByName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubmissionImplCopyWith<$Res>
    implements $SubmissionCopyWith<$Res> {
  factory _$$SubmissionImplCopyWith(
          _$SubmissionImpl value, $Res Function(_$SubmissionImpl) then) =
      __$$SubmissionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String assignmentId,
      String studentId,
      String? content,
      List<Map<String, dynamic>> attachments,
      DateTime? submittedAt,
      String status,
      double? marksObtained,
      String? feedback,
      String? gradedBy,
      DateTime? gradedAt,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? studentName,
      String? admissionNumber,
      String? assignmentTitle,
      double? maxMarks,
      DateTime? dueDate,
      String? gradedByName});
}

/// @nodoc
class __$$SubmissionImplCopyWithImpl<$Res>
    extends _$SubmissionCopyWithImpl<$Res, _$SubmissionImpl>
    implements _$$SubmissionImplCopyWith<$Res> {
  __$$SubmissionImplCopyWithImpl(
      _$SubmissionImpl _value, $Res Function(_$SubmissionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? assignmentId = null,
    Object? studentId = null,
    Object? content = freezed,
    Object? attachments = null,
    Object? submittedAt = freezed,
    Object? status = null,
    Object? marksObtained = freezed,
    Object? feedback = freezed,
    Object? gradedBy = freezed,
    Object? gradedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? studentName = freezed,
    Object? admissionNumber = freezed,
    Object? assignmentTitle = freezed,
    Object? maxMarks = freezed,
    Object? dueDate = freezed,
    Object? gradedByName = freezed,
  }) {
    return _then(_$SubmissionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      assignmentId: null == assignmentId
          ? _value.assignmentId
          : assignmentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      attachments: null == attachments
          ? _value._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      marksObtained: freezed == marksObtained
          ? _value.marksObtained
          : marksObtained // ignore: cast_nullable_to_non_nullable
              as double?,
      feedback: freezed == feedback
          ? _value.feedback
          : feedback // ignore: cast_nullable_to_non_nullable
              as String?,
      gradedBy: freezed == gradedBy
          ? _value.gradedBy
          : gradedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      gradedAt: freezed == gradedAt
          ? _value.gradedAt
          : gradedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
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
      assignmentTitle: freezed == assignmentTitle
          ? _value.assignmentTitle
          : assignmentTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      maxMarks: freezed == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double?,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gradedByName: freezed == gradedByName
          ? _value.gradedByName
          : gradedByName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubmissionImpl extends _Submission {
  const _$SubmissionImpl(
      {required this.id,
      required this.tenantId,
      required this.assignmentId,
      required this.studentId,
      this.content,
      final List<Map<String, dynamic>> attachments = const [],
      this.submittedAt,
      this.status = 'pending',
      this.marksObtained,
      this.feedback,
      this.gradedBy,
      this.gradedAt,
      this.createdAt,
      this.updatedAt,
      this.studentName,
      this.admissionNumber,
      this.assignmentTitle,
      this.maxMarks,
      this.dueDate,
      this.gradedByName})
      : _attachments = attachments,
        super._();

  factory _$SubmissionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubmissionImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String assignmentId;
  @override
  final String studentId;
  @override
  final String? content;
  final List<Map<String, dynamic>> _attachments;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  final DateTime? submittedAt;
  @override
  @JsonKey()
  final String status;
  @override
  final double? marksObtained;
  @override
  final String? feedback;
  @override
  final String? gradedBy;
  @override
  final DateTime? gradedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
// Joined data
  @override
  final String? studentName;
  @override
  final String? admissionNumber;
  @override
  final String? assignmentTitle;
  @override
  final double? maxMarks;
  @override
  final DateTime? dueDate;
  @override
  final String? gradedByName;

  @override
  String toString() {
    return 'Submission(id: $id, tenantId: $tenantId, assignmentId: $assignmentId, studentId: $studentId, content: $content, attachments: $attachments, submittedAt: $submittedAt, status: $status, marksObtained: $marksObtained, feedback: $feedback, gradedBy: $gradedBy, gradedAt: $gradedAt, createdAt: $createdAt, updatedAt: $updatedAt, studentName: $studentName, admissionNumber: $admissionNumber, assignmentTitle: $assignmentTitle, maxMarks: $maxMarks, dueDate: $dueDate, gradedByName: $gradedByName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubmissionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.assignmentId, assignmentId) ||
                other.assignmentId == assignmentId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.marksObtained, marksObtained) ||
                other.marksObtained == marksObtained) &&
            (identical(other.feedback, feedback) ||
                other.feedback == feedback) &&
            (identical(other.gradedBy, gradedBy) ||
                other.gradedBy == gradedBy) &&
            (identical(other.gradedAt, gradedAt) ||
                other.gradedAt == gradedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.admissionNumber, admissionNumber) ||
                other.admissionNumber == admissionNumber) &&
            (identical(other.assignmentTitle, assignmentTitle) ||
                other.assignmentTitle == assignmentTitle) &&
            (identical(other.maxMarks, maxMarks) ||
                other.maxMarks == maxMarks) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.gradedByName, gradedByName) ||
                other.gradedByName == gradedByName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        tenantId,
        assignmentId,
        studentId,
        content,
        const DeepCollectionEquality().hash(_attachments),
        submittedAt,
        status,
        marksObtained,
        feedback,
        gradedBy,
        gradedAt,
        createdAt,
        updatedAt,
        studentName,
        admissionNumber,
        assignmentTitle,
        maxMarks,
        dueDate,
        gradedByName
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SubmissionImplCopyWith<_$SubmissionImpl> get copyWith =>
      __$$SubmissionImplCopyWithImpl<_$SubmissionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubmissionImplToJson(
      this,
    );
  }
}

abstract class _Submission extends Submission {
  const factory _Submission(
      {required final String id,
      required final String tenantId,
      required final String assignmentId,
      required final String studentId,
      final String? content,
      final List<Map<String, dynamic>> attachments,
      final DateTime? submittedAt,
      final String status,
      final double? marksObtained,
      final String? feedback,
      final String? gradedBy,
      final DateTime? gradedAt,
      final DateTime? createdAt,
      final DateTime? updatedAt,
      final String? studentName,
      final String? admissionNumber,
      final String? assignmentTitle,
      final double? maxMarks,
      final DateTime? dueDate,
      final String? gradedByName}) = _$SubmissionImpl;
  const _Submission._() : super._();

  factory _Submission.fromJson(Map<String, dynamic> json) =
      _$SubmissionImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get assignmentId;
  @override
  String get studentId;
  @override
  String? get content;
  @override
  List<Map<String, dynamic>> get attachments;
  @override
  DateTime? get submittedAt;
  @override
  String get status;
  @override
  double? get marksObtained;
  @override
  String? get feedback;
  @override
  String? get gradedBy;
  @override
  DateTime? get gradedAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override // Joined data
  String? get studentName;
  @override
  String? get admissionNumber;
  @override
  String? get assignmentTitle;
  @override
  double? get maxMarks;
  @override
  DateTime? get dueDate;
  @override
  String? get gradedByName;
  @override
  @JsonKey(ignore: true)
  _$$SubmissionImplCopyWith<_$SubmissionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AssignmentSummary _$AssignmentSummaryFromJson(Map<String, dynamic> json) {
  return _AssignmentSummary.fromJson(json);
}

/// @nodoc
mixin _$AssignmentSummary {
  String get tenantId => throw _privateConstructorUsedError;
  String get assignmentId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String get sectionName => throw _privateConstructorUsedError;
  String get className => throw _privateConstructorUsedError;
  String get subjectId => throw _privateConstructorUsedError;
  String get subjectName => throw _privateConstructorUsedError;
  String get teacherId => throw _privateConstructorUsedError;
  String get teacherName => throw _privateConstructorUsedError;
  DateTime get dueDate => throw _privateConstructorUsedError;
  double? get maxMarks => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get totalStudents => throw _privateConstructorUsedError;
  int get submittedCount => throw _privateConstructorUsedError;
  int get gradedCount => throw _privateConstructorUsedError;
  int get lateCount => throw _privateConstructorUsedError;
  bool get isPastDue => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AssignmentSummaryCopyWith<AssignmentSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssignmentSummaryCopyWith<$Res> {
  factory $AssignmentSummaryCopyWith(
          AssignmentSummary value, $Res Function(AssignmentSummary) then) =
      _$AssignmentSummaryCopyWithImpl<$Res, AssignmentSummary>;
  @useResult
  $Res call(
      {String tenantId,
      String assignmentId,
      String title,
      String sectionId,
      String sectionName,
      String className,
      String subjectId,
      String subjectName,
      String teacherId,
      String teacherName,
      DateTime dueDate,
      double? maxMarks,
      String status,
      int totalStudents,
      int submittedCount,
      int gradedCount,
      int lateCount,
      bool isPastDue});
}

/// @nodoc
class _$AssignmentSummaryCopyWithImpl<$Res, $Val extends AssignmentSummary>
    implements $AssignmentSummaryCopyWith<$Res> {
  _$AssignmentSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? assignmentId = null,
    Object? title = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? className = null,
    Object? subjectId = null,
    Object? subjectName = null,
    Object? teacherId = null,
    Object? teacherName = null,
    Object? dueDate = null,
    Object? maxMarks = freezed,
    Object? status = null,
    Object? totalStudents = null,
    Object? submittedCount = null,
    Object? gradedCount = null,
    Object? lateCount = null,
    Object? isPastDue = null,
  }) {
    return _then(_value.copyWith(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      assignmentId: null == assignmentId
          ? _value.assignmentId
          : assignmentId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
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
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      teacherId: null == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as String,
      teacherName: null == teacherName
          ? _value.teacherName
          : teacherName // ignore: cast_nullable_to_non_nullable
              as String,
      dueDate: null == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      maxMarks: freezed == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      totalStudents: null == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int,
      submittedCount: null == submittedCount
          ? _value.submittedCount
          : submittedCount // ignore: cast_nullable_to_non_nullable
              as int,
      gradedCount: null == gradedCount
          ? _value.gradedCount
          : gradedCount // ignore: cast_nullable_to_non_nullable
              as int,
      lateCount: null == lateCount
          ? _value.lateCount
          : lateCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPastDue: null == isPastDue
          ? _value.isPastDue
          : isPastDue // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AssignmentSummaryImplCopyWith<$Res>
    implements $AssignmentSummaryCopyWith<$Res> {
  factory _$$AssignmentSummaryImplCopyWith(_$AssignmentSummaryImpl value,
          $Res Function(_$AssignmentSummaryImpl) then) =
      __$$AssignmentSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tenantId,
      String assignmentId,
      String title,
      String sectionId,
      String sectionName,
      String className,
      String subjectId,
      String subjectName,
      String teacherId,
      String teacherName,
      DateTime dueDate,
      double? maxMarks,
      String status,
      int totalStudents,
      int submittedCount,
      int gradedCount,
      int lateCount,
      bool isPastDue});
}

/// @nodoc
class __$$AssignmentSummaryImplCopyWithImpl<$Res>
    extends _$AssignmentSummaryCopyWithImpl<$Res, _$AssignmentSummaryImpl>
    implements _$$AssignmentSummaryImplCopyWith<$Res> {
  __$$AssignmentSummaryImplCopyWithImpl(_$AssignmentSummaryImpl _value,
      $Res Function(_$AssignmentSummaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? assignmentId = null,
    Object? title = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? className = null,
    Object? subjectId = null,
    Object? subjectName = null,
    Object? teacherId = null,
    Object? teacherName = null,
    Object? dueDate = null,
    Object? maxMarks = freezed,
    Object? status = null,
    Object? totalStudents = null,
    Object? submittedCount = null,
    Object? gradedCount = null,
    Object? lateCount = null,
    Object? isPastDue = null,
  }) {
    return _then(_$AssignmentSummaryImpl(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      assignmentId: null == assignmentId
          ? _value.assignmentId
          : assignmentId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
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
      subjectId: null == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String,
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      teacherId: null == teacherId
          ? _value.teacherId
          : teacherId // ignore: cast_nullable_to_non_nullable
              as String,
      teacherName: null == teacherName
          ? _value.teacherName
          : teacherName // ignore: cast_nullable_to_non_nullable
              as String,
      dueDate: null == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      maxMarks: freezed == maxMarks
          ? _value.maxMarks
          : maxMarks // ignore: cast_nullable_to_non_nullable
              as double?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      totalStudents: null == totalStudents
          ? _value.totalStudents
          : totalStudents // ignore: cast_nullable_to_non_nullable
              as int,
      submittedCount: null == submittedCount
          ? _value.submittedCount
          : submittedCount // ignore: cast_nullable_to_non_nullable
              as int,
      gradedCount: null == gradedCount
          ? _value.gradedCount
          : gradedCount // ignore: cast_nullable_to_non_nullable
              as int,
      lateCount: null == lateCount
          ? _value.lateCount
          : lateCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPastDue: null == isPastDue
          ? _value.isPastDue
          : isPastDue // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AssignmentSummaryImpl implements _AssignmentSummary {
  const _$AssignmentSummaryImpl(
      {required this.tenantId,
      required this.assignmentId,
      required this.title,
      required this.sectionId,
      required this.sectionName,
      required this.className,
      required this.subjectId,
      required this.subjectName,
      required this.teacherId,
      required this.teacherName,
      required this.dueDate,
      this.maxMarks,
      required this.status,
      required this.totalStudents,
      required this.submittedCount,
      required this.gradedCount,
      required this.lateCount,
      required this.isPastDue});

  factory _$AssignmentSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssignmentSummaryImplFromJson(json);

  @override
  final String tenantId;
  @override
  final String assignmentId;
  @override
  final String title;
  @override
  final String sectionId;
  @override
  final String sectionName;
  @override
  final String className;
  @override
  final String subjectId;
  @override
  final String subjectName;
  @override
  final String teacherId;
  @override
  final String teacherName;
  @override
  final DateTime dueDate;
  @override
  final double? maxMarks;
  @override
  final String status;
  @override
  final int totalStudents;
  @override
  final int submittedCount;
  @override
  final int gradedCount;
  @override
  final int lateCount;
  @override
  final bool isPastDue;

  @override
  String toString() {
    return 'AssignmentSummary(tenantId: $tenantId, assignmentId: $assignmentId, title: $title, sectionId: $sectionId, sectionName: $sectionName, className: $className, subjectId: $subjectId, subjectName: $subjectName, teacherId: $teacherId, teacherName: $teacherName, dueDate: $dueDate, maxMarks: $maxMarks, status: $status, totalStudents: $totalStudents, submittedCount: $submittedCount, gradedCount: $gradedCount, lateCount: $lateCount, isPastDue: $isPastDue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssignmentSummaryImpl &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.assignmentId, assignmentId) ||
                other.assignmentId == assignmentId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.subjectName, subjectName) ||
                other.subjectName == subjectName) &&
            (identical(other.teacherId, teacherId) ||
                other.teacherId == teacherId) &&
            (identical(other.teacherName, teacherName) ||
                other.teacherName == teacherName) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.maxMarks, maxMarks) ||
                other.maxMarks == maxMarks) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalStudents, totalStudents) ||
                other.totalStudents == totalStudents) &&
            (identical(other.submittedCount, submittedCount) ||
                other.submittedCount == submittedCount) &&
            (identical(other.gradedCount, gradedCount) ||
                other.gradedCount == gradedCount) &&
            (identical(other.lateCount, lateCount) ||
                other.lateCount == lateCount) &&
            (identical(other.isPastDue, isPastDue) ||
                other.isPastDue == isPastDue));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      tenantId,
      assignmentId,
      title,
      sectionId,
      sectionName,
      className,
      subjectId,
      subjectName,
      teacherId,
      teacherName,
      dueDate,
      maxMarks,
      status,
      totalStudents,
      submittedCount,
      gradedCount,
      lateCount,
      isPastDue);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AssignmentSummaryImplCopyWith<_$AssignmentSummaryImpl> get copyWith =>
      __$$AssignmentSummaryImplCopyWithImpl<_$AssignmentSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssignmentSummaryImplToJson(
      this,
    );
  }
}

abstract class _AssignmentSummary implements AssignmentSummary {
  const factory _AssignmentSummary(
      {required final String tenantId,
      required final String assignmentId,
      required final String title,
      required final String sectionId,
      required final String sectionName,
      required final String className,
      required final String subjectId,
      required final String subjectName,
      required final String teacherId,
      required final String teacherName,
      required final DateTime dueDate,
      final double? maxMarks,
      required final String status,
      required final int totalStudents,
      required final int submittedCount,
      required final int gradedCount,
      required final int lateCount,
      required final bool isPastDue}) = _$AssignmentSummaryImpl;

  factory _AssignmentSummary.fromJson(Map<String, dynamic> json) =
      _$AssignmentSummaryImpl.fromJson;

  @override
  String get tenantId;
  @override
  String get assignmentId;
  @override
  String get title;
  @override
  String get sectionId;
  @override
  String get sectionName;
  @override
  String get className;
  @override
  String get subjectId;
  @override
  String get subjectName;
  @override
  String get teacherId;
  @override
  String get teacherName;
  @override
  DateTime get dueDate;
  @override
  double? get maxMarks;
  @override
  String get status;
  @override
  int get totalStudents;
  @override
  int get submittedCount;
  @override
  int get gradedCount;
  @override
  int get lateCount;
  @override
  bool get isPastDue;
  @override
  @JsonKey(ignore: true)
  _$$AssignmentSummaryImplCopyWith<_$AssignmentSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
