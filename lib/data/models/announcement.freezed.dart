// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'announcement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) {
  return _Announcement.fromJson(json);
}

/// @nodoc
mixin _$Announcement {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get attachments =>
      throw _privateConstructorUsedError;
  List<String> get targetRoles => throw _privateConstructorUsedError;
  List<String> get targetSections => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  DateTime? get publishAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  bool get isPublished => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError; // Joined data
  String? get createdByName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AnnouncementCopyWith<Announcement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnnouncementCopyWith<$Res> {
  factory $AnnouncementCopyWith(
          Announcement value, $Res Function(Announcement) then) =
      _$AnnouncementCopyWithImpl<$Res, Announcement>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String title,
      String content,
      List<Map<String, dynamic>> attachments,
      List<String> targetRoles,
      List<String> targetSections,
      String priority,
      DateTime? publishAt,
      DateTime? expiresAt,
      String createdBy,
      bool isPublished,
      DateTime? createdAt,
      String? createdByName});
}

/// @nodoc
class _$AnnouncementCopyWithImpl<$Res, $Val extends Announcement>
    implements $AnnouncementCopyWith<$Res> {
  _$AnnouncementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? title = null,
    Object? content = null,
    Object? attachments = null,
    Object? targetRoles = null,
    Object? targetSections = null,
    Object? priority = null,
    Object? publishAt = freezed,
    Object? expiresAt = freezed,
    Object? createdBy = null,
    Object? isPublished = null,
    Object? createdAt = freezed,
    Object? createdByName = freezed,
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
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      attachments: null == attachments
          ? _value.attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      targetRoles: null == targetRoles
          ? _value.targetRoles
          : targetRoles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      targetSections: null == targetSections
          ? _value.targetSections
          : targetSections // ignore: cast_nullable_to_non_nullable
              as List<String>,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      publishAt: freezed == publishAt
          ? _value.publishAt
          : publishAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      isPublished: null == isPublished
          ? _value.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdByName: freezed == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AnnouncementImplCopyWith<$Res>
    implements $AnnouncementCopyWith<$Res> {
  factory _$$AnnouncementImplCopyWith(
          _$AnnouncementImpl value, $Res Function(_$AnnouncementImpl) then) =
      __$$AnnouncementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String title,
      String content,
      List<Map<String, dynamic>> attachments,
      List<String> targetRoles,
      List<String> targetSections,
      String priority,
      DateTime? publishAt,
      DateTime? expiresAt,
      String createdBy,
      bool isPublished,
      DateTime? createdAt,
      String? createdByName});
}

/// @nodoc
class __$$AnnouncementImplCopyWithImpl<$Res>
    extends _$AnnouncementCopyWithImpl<$Res, _$AnnouncementImpl>
    implements _$$AnnouncementImplCopyWith<$Res> {
  __$$AnnouncementImplCopyWithImpl(
      _$AnnouncementImpl _value, $Res Function(_$AnnouncementImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? title = null,
    Object? content = null,
    Object? attachments = null,
    Object? targetRoles = null,
    Object? targetSections = null,
    Object? priority = null,
    Object? publishAt = freezed,
    Object? expiresAt = freezed,
    Object? createdBy = null,
    Object? isPublished = null,
    Object? createdAt = freezed,
    Object? createdByName = freezed,
  }) {
    return _then(_$AnnouncementImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      attachments: null == attachments
          ? _value._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      targetRoles: null == targetRoles
          ? _value._targetRoles
          : targetRoles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      targetSections: null == targetSections
          ? _value._targetSections
          : targetSections // ignore: cast_nullable_to_non_nullable
              as List<String>,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      publishAt: freezed == publishAt
          ? _value.publishAt
          : publishAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      isPublished: null == isPublished
          ? _value.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdByName: freezed == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnnouncementImpl implements _Announcement {
  const _$AnnouncementImpl(
      {required this.id,
      required this.tenantId,
      required this.title,
      required this.content,
      final List<Map<String, dynamic>> attachments = const [],
      final List<String> targetRoles = const [],
      final List<String> targetSections = const [],
      this.priority = 'normal',
      this.publishAt,
      this.expiresAt,
      required this.createdBy,
      this.isPublished = false,
      this.createdAt,
      this.createdByName})
      : _attachments = attachments,
        _targetRoles = targetRoles,
        _targetSections = targetSections;

  factory _$AnnouncementImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnnouncementImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String title;
  @override
  final String content;
  final List<Map<String, dynamic>> _attachments;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  final List<String> _targetRoles;
  @override
  @JsonKey()
  List<String> get targetRoles {
    if (_targetRoles is EqualUnmodifiableListView) return _targetRoles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_targetRoles);
  }

  final List<String> _targetSections;
  @override
  @JsonKey()
  List<String> get targetSections {
    if (_targetSections is EqualUnmodifiableListView) return _targetSections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_targetSections);
  }

  @override
  @JsonKey()
  final String priority;
  @override
  final DateTime? publishAt;
  @override
  final DateTime? expiresAt;
  @override
  final String createdBy;
  @override
  @JsonKey()
  final bool isPublished;
  @override
  final DateTime? createdAt;
// Joined data
  @override
  final String? createdByName;

  @override
  String toString() {
    return 'Announcement(id: $id, tenantId: $tenantId, title: $title, content: $content, attachments: $attachments, targetRoles: $targetRoles, targetSections: $targetSections, priority: $priority, publishAt: $publishAt, expiresAt: $expiresAt, createdBy: $createdBy, isPublished: $isPublished, createdAt: $createdAt, createdByName: $createdByName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnnouncementImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
            const DeepCollectionEquality()
                .equals(other._targetRoles, _targetRoles) &&
            const DeepCollectionEquality()
                .equals(other._targetSections, _targetSections) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.publishAt, publishAt) ||
                other.publishAt == publishAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.isPublished, isPublished) ||
                other.isPublished == isPublished) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdByName, createdByName) ||
                other.createdByName == createdByName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      title,
      content,
      const DeepCollectionEquality().hash(_attachments),
      const DeepCollectionEquality().hash(_targetRoles),
      const DeepCollectionEquality().hash(_targetSections),
      priority,
      publishAt,
      expiresAt,
      createdBy,
      isPublished,
      createdAt,
      createdByName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AnnouncementImplCopyWith<_$AnnouncementImpl> get copyWith =>
      __$$AnnouncementImplCopyWithImpl<_$AnnouncementImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnnouncementImplToJson(
      this,
    );
  }
}

abstract class _Announcement implements Announcement {
  const factory _Announcement(
      {required final String id,
      required final String tenantId,
      required final String title,
      required final String content,
      final List<Map<String, dynamic>> attachments,
      final List<String> targetRoles,
      final List<String> targetSections,
      final String priority,
      final DateTime? publishAt,
      final DateTime? expiresAt,
      required final String createdBy,
      final bool isPublished,
      final DateTime? createdAt,
      final String? createdByName}) = _$AnnouncementImpl;

  factory _Announcement.fromJson(Map<String, dynamic> json) =
      _$AnnouncementImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get title;
  @override
  String get content;
  @override
  List<Map<String, dynamic>> get attachments;
  @override
  List<String> get targetRoles;
  @override
  List<String> get targetSections;
  @override
  String get priority;
  @override
  DateTime? get publishAt;
  @override
  DateTime? get expiresAt;
  @override
  String get createdBy;
  @override
  bool get isPublished;
  @override
  DateTime? get createdAt;
  @override // Joined data
  String? get createdByName;
  @override
  @JsonKey(ignore: true)
  _$$AnnouncementImplCopyWith<_$AnnouncementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
