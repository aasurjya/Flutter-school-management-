// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Thread _$ThreadFromJson(Map<String, dynamic> json) {
  return _Thread.fromJson(json);
}

/// @nodoc
mixin _$Thread {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get threadType => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get sectionId => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError; // Joined data
  String? get createdByName => throw _privateConstructorUsedError;
  String? get sectionName => throw _privateConstructorUsedError;
  List<ThreadParticipant>? get participants =>
      throw _privateConstructorUsedError;
  Message? get lastMessage => throw _privateConstructorUsedError;
  int? get unreadCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ThreadCopyWith<Thread> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThreadCopyWith<$Res> {
  factory $ThreadCopyWith(Thread value, $Res Function(Thread) then) =
      _$ThreadCopyWithImpl<$Res, Thread>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String threadType,
      String? title,
      String? sectionId,
      String createdBy,
      bool isActive,
      DateTime? lastMessageAt,
      DateTime? createdAt,
      String? createdByName,
      String? sectionName,
      List<ThreadParticipant>? participants,
      Message? lastMessage,
      int? unreadCount});

  $MessageCopyWith<$Res>? get lastMessage;
}

/// @nodoc
class _$ThreadCopyWithImpl<$Res, $Val extends Thread>
    implements $ThreadCopyWith<$Res> {
  _$ThreadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? threadType = null,
    Object? title = freezed,
    Object? sectionId = freezed,
    Object? createdBy = null,
    Object? isActive = null,
    Object? lastMessageAt = freezed,
    Object? createdAt = freezed,
    Object? createdByName = freezed,
    Object? sectionName = freezed,
    Object? participants = freezed,
    Object? lastMessage = freezed,
    Object? unreadCount = freezed,
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
      threadType: null == threadType
          ? _value.threadType
          : threadType // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      sectionId: freezed == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdByName: freezed == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String?,
      sectionName: freezed == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String?,
      participants: freezed == participants
          ? _value.participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<ThreadParticipant>?,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as Message?,
      unreadCount: freezed == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MessageCopyWith<$Res>? get lastMessage {
    if (_value.lastMessage == null) {
      return null;
    }

    return $MessageCopyWith<$Res>(_value.lastMessage!, (value) {
      return _then(_value.copyWith(lastMessage: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ThreadImplCopyWith<$Res> implements $ThreadCopyWith<$Res> {
  factory _$$ThreadImplCopyWith(
          _$ThreadImpl value, $Res Function(_$ThreadImpl) then) =
      __$$ThreadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String threadType,
      String? title,
      String? sectionId,
      String createdBy,
      bool isActive,
      DateTime? lastMessageAt,
      DateTime? createdAt,
      String? createdByName,
      String? sectionName,
      List<ThreadParticipant>? participants,
      Message? lastMessage,
      int? unreadCount});

  @override
  $MessageCopyWith<$Res>? get lastMessage;
}

/// @nodoc
class __$$ThreadImplCopyWithImpl<$Res>
    extends _$ThreadCopyWithImpl<$Res, _$ThreadImpl>
    implements _$$ThreadImplCopyWith<$Res> {
  __$$ThreadImplCopyWithImpl(
      _$ThreadImpl _value, $Res Function(_$ThreadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? threadType = null,
    Object? title = freezed,
    Object? sectionId = freezed,
    Object? createdBy = null,
    Object? isActive = null,
    Object? lastMessageAt = freezed,
    Object? createdAt = freezed,
    Object? createdByName = freezed,
    Object? sectionName = freezed,
    Object? participants = freezed,
    Object? lastMessage = freezed,
    Object? unreadCount = freezed,
  }) {
    return _then(_$ThreadImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      threadType: null == threadType
          ? _value.threadType
          : threadType // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      sectionId: freezed == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdByName: freezed == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String?,
      sectionName: freezed == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String?,
      participants: freezed == participants
          ? _value._participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<ThreadParticipant>?,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as Message?,
      unreadCount: freezed == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThreadImpl implements _Thread {
  const _$ThreadImpl(
      {required this.id,
      required this.tenantId,
      required this.threadType,
      this.title,
      this.sectionId,
      required this.createdBy,
      this.isActive = true,
      this.lastMessageAt,
      this.createdAt,
      this.createdByName,
      this.sectionName,
      final List<ThreadParticipant>? participants,
      this.lastMessage,
      this.unreadCount})
      : _participants = participants;

  factory _$ThreadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThreadImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String threadType;
  @override
  final String? title;
  @override
  final String? sectionId;
  @override
  final String createdBy;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? lastMessageAt;
  @override
  final DateTime? createdAt;
// Joined data
  @override
  final String? createdByName;
  @override
  final String? sectionName;
  final List<ThreadParticipant>? _participants;
  @override
  List<ThreadParticipant>? get participants {
    final value = _participants;
    if (value == null) return null;
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final Message? lastMessage;
  @override
  final int? unreadCount;

  @override
  String toString() {
    return 'Thread(id: $id, tenantId: $tenantId, threadType: $threadType, title: $title, sectionId: $sectionId, createdBy: $createdBy, isActive: $isActive, lastMessageAt: $lastMessageAt, createdAt: $createdAt, createdByName: $createdByName, sectionName: $sectionName, participants: $participants, lastMessage: $lastMessage, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThreadImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.threadType, threadType) ||
                other.threadType == threadType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdByName, createdByName) ||
                other.createdByName == createdByName) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            const DeepCollectionEquality()
                .equals(other._participants, _participants) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      threadType,
      title,
      sectionId,
      createdBy,
      isActive,
      lastMessageAt,
      createdAt,
      createdByName,
      sectionName,
      const DeepCollectionEquality().hash(_participants),
      lastMessage,
      unreadCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ThreadImplCopyWith<_$ThreadImpl> get copyWith =>
      __$$ThreadImplCopyWithImpl<_$ThreadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThreadImplToJson(
      this,
    );
  }
}

abstract class _Thread implements Thread {
  const factory _Thread(
      {required final String id,
      required final String tenantId,
      required final String threadType,
      final String? title,
      final String? sectionId,
      required final String createdBy,
      final bool isActive,
      final DateTime? lastMessageAt,
      final DateTime? createdAt,
      final String? createdByName,
      final String? sectionName,
      final List<ThreadParticipant>? participants,
      final Message? lastMessage,
      final int? unreadCount}) = _$ThreadImpl;

  factory _Thread.fromJson(Map<String, dynamic> json) = _$ThreadImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get threadType;
  @override
  String? get title;
  @override
  String? get sectionId;
  @override
  String get createdBy;
  @override
  bool get isActive;
  @override
  DateTime? get lastMessageAt;
  @override
  DateTime? get createdAt;
  @override // Joined data
  String? get createdByName;
  @override
  String? get sectionName;
  @override
  List<ThreadParticipant>? get participants;
  @override
  Message? get lastMessage;
  @override
  int? get unreadCount;
  @override
  @JsonKey(ignore: true)
  _$$ThreadImplCopyWith<_$ThreadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ThreadParticipant _$ThreadParticipantFromJson(Map<String, dynamic> json) {
  return _ThreadParticipant.fromJson(json);
}

/// @nodoc
mixin _$ThreadParticipant {
  String get id => throw _privateConstructorUsedError;
  String get threadId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime? get joinedAt => throw _privateConstructorUsedError;
  DateTime? get lastReadAt => throw _privateConstructorUsedError;
  bool get isMuted => throw _privateConstructorUsedError; // Joined data
  String? get userName => throw _privateConstructorUsedError;
  String? get userAvatar => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ThreadParticipantCopyWith<ThreadParticipant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThreadParticipantCopyWith<$Res> {
  factory $ThreadParticipantCopyWith(
          ThreadParticipant value, $Res Function(ThreadParticipant) then) =
      _$ThreadParticipantCopyWithImpl<$Res, ThreadParticipant>;
  @useResult
  $Res call(
      {String id,
      String threadId,
      String userId,
      DateTime? joinedAt,
      DateTime? lastReadAt,
      bool isMuted,
      String? userName,
      String? userAvatar});
}

/// @nodoc
class _$ThreadParticipantCopyWithImpl<$Res, $Val extends ThreadParticipant>
    implements $ThreadParticipantCopyWith<$Res> {
  _$ThreadParticipantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? threadId = null,
    Object? userId = null,
    Object? joinedAt = freezed,
    Object? lastReadAt = freezed,
    Object? isMuted = null,
    Object? userName = freezed,
    Object? userAvatar = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      threadId: null == threadId
          ? _value.threadId
          : threadId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastReadAt: freezed == lastReadAt
          ? _value.lastReadAt
          : lastReadAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      userName: freezed == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String?,
      userAvatar: freezed == userAvatar
          ? _value.userAvatar
          : userAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ThreadParticipantImplCopyWith<$Res>
    implements $ThreadParticipantCopyWith<$Res> {
  factory _$$ThreadParticipantImplCopyWith(_$ThreadParticipantImpl value,
          $Res Function(_$ThreadParticipantImpl) then) =
      __$$ThreadParticipantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String threadId,
      String userId,
      DateTime? joinedAt,
      DateTime? lastReadAt,
      bool isMuted,
      String? userName,
      String? userAvatar});
}

/// @nodoc
class __$$ThreadParticipantImplCopyWithImpl<$Res>
    extends _$ThreadParticipantCopyWithImpl<$Res, _$ThreadParticipantImpl>
    implements _$$ThreadParticipantImplCopyWith<$Res> {
  __$$ThreadParticipantImplCopyWithImpl(_$ThreadParticipantImpl _value,
      $Res Function(_$ThreadParticipantImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? threadId = null,
    Object? userId = null,
    Object? joinedAt = freezed,
    Object? lastReadAt = freezed,
    Object? isMuted = null,
    Object? userName = freezed,
    Object? userAvatar = freezed,
  }) {
    return _then(_$ThreadParticipantImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      threadId: null == threadId
          ? _value.threadId
          : threadId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      joinedAt: freezed == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastReadAt: freezed == lastReadAt
          ? _value.lastReadAt
          : lastReadAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      userName: freezed == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String?,
      userAvatar: freezed == userAvatar
          ? _value.userAvatar
          : userAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThreadParticipantImpl implements _ThreadParticipant {
  const _$ThreadParticipantImpl(
      {required this.id,
      required this.threadId,
      required this.userId,
      this.joinedAt,
      this.lastReadAt,
      this.isMuted = false,
      this.userName,
      this.userAvatar});

  factory _$ThreadParticipantImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThreadParticipantImplFromJson(json);

  @override
  final String id;
  @override
  final String threadId;
  @override
  final String userId;
  @override
  final DateTime? joinedAt;
  @override
  final DateTime? lastReadAt;
  @override
  @JsonKey()
  final bool isMuted;
// Joined data
  @override
  final String? userName;
  @override
  final String? userAvatar;

  @override
  String toString() {
    return 'ThreadParticipant(id: $id, threadId: $threadId, userId: $userId, joinedAt: $joinedAt, lastReadAt: $lastReadAt, isMuted: $isMuted, userName: $userName, userAvatar: $userAvatar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThreadParticipantImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.threadId, threadId) ||
                other.threadId == threadId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.lastReadAt, lastReadAt) ||
                other.lastReadAt == lastReadAt) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userAvatar, userAvatar) ||
                other.userAvatar == userAvatar));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, threadId, userId, joinedAt,
      lastReadAt, isMuted, userName, userAvatar);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ThreadParticipantImplCopyWith<_$ThreadParticipantImpl> get copyWith =>
      __$$ThreadParticipantImplCopyWithImpl<_$ThreadParticipantImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThreadParticipantImplToJson(
      this,
    );
  }
}

abstract class _ThreadParticipant implements ThreadParticipant {
  const factory _ThreadParticipant(
      {required final String id,
      required final String threadId,
      required final String userId,
      final DateTime? joinedAt,
      final DateTime? lastReadAt,
      final bool isMuted,
      final String? userName,
      final String? userAvatar}) = _$ThreadParticipantImpl;

  factory _ThreadParticipant.fromJson(Map<String, dynamic> json) =
      _$ThreadParticipantImpl.fromJson;

  @override
  String get id;
  @override
  String get threadId;
  @override
  String get userId;
  @override
  DateTime? get joinedAt;
  @override
  DateTime? get lastReadAt;
  @override
  bool get isMuted;
  @override // Joined data
  String? get userName;
  @override
  String? get userAvatar;
  @override
  @JsonKey(ignore: true)
  _$$ThreadParticipantImplCopyWith<_$ThreadParticipantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Message _$MessageFromJson(Map<String, dynamic> json) {
  return _Message.fromJson(json);
}

/// @nodoc
mixin _$Message {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get threadId => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get attachments =>
      throw _privateConstructorUsedError;
  bool get isEdited => throw _privateConstructorUsedError;
  String? get replyToId => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError; // Joined data
  String? get senderName => throw _privateConstructorUsedError;
  String? get senderAvatar => throw _privateConstructorUsedError;
  Message? get replyTo => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String threadId,
      String senderId,
      String content,
      List<Map<String, dynamic>> attachments,
      bool isEdited,
      String? replyToId,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? senderName,
      String? senderAvatar,
      Message? replyTo});

  $MessageCopyWith<$Res>? get replyTo;
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? threadId = null,
    Object? senderId = null,
    Object? content = null,
    Object? attachments = null,
    Object? isEdited = null,
    Object? replyToId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? senderName = freezed,
    Object? senderAvatar = freezed,
    Object? replyTo = freezed,
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
      threadId: null == threadId
          ? _value.threadId
          : threadId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      attachments: null == attachments
          ? _value.attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      isEdited: null == isEdited
          ? _value.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      replyToId: freezed == replyToId
          ? _value.replyToId
          : replyToId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderAvatar: freezed == senderAvatar
          ? _value.senderAvatar
          : senderAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      replyTo: freezed == replyTo
          ? _value.replyTo
          : replyTo // ignore: cast_nullable_to_non_nullable
              as Message?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MessageCopyWith<$Res>? get replyTo {
    if (_value.replyTo == null) {
      return null;
    }

    return $MessageCopyWith<$Res>(_value.replyTo!, (value) {
      return _then(_value.copyWith(replyTo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
          _$MessageImpl value, $Res Function(_$MessageImpl) then) =
      __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String threadId,
      String senderId,
      String content,
      List<Map<String, dynamic>> attachments,
      bool isEdited,
      String? replyToId,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? senderName,
      String? senderAvatar,
      Message? replyTo});

  @override
  $MessageCopyWith<$Res>? get replyTo;
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
      _$MessageImpl _value, $Res Function(_$MessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? threadId = null,
    Object? senderId = null,
    Object? content = null,
    Object? attachments = null,
    Object? isEdited = null,
    Object? replyToId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? senderName = freezed,
    Object? senderAvatar = freezed,
    Object? replyTo = freezed,
  }) {
    return _then(_$MessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      threadId: null == threadId
          ? _value.threadId
          : threadId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      attachments: null == attachments
          ? _value._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      isEdited: null == isEdited
          ? _value.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      replyToId: freezed == replyToId
          ? _value.replyToId
          : replyToId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderAvatar: freezed == senderAvatar
          ? _value.senderAvatar
          : senderAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      replyTo: freezed == replyTo
          ? _value.replyTo
          : replyTo // ignore: cast_nullable_to_non_nullable
              as Message?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageImpl implements _Message {
  const _$MessageImpl(
      {required this.id,
      required this.tenantId,
      required this.threadId,
      required this.senderId,
      required this.content,
      final List<Map<String, dynamic>> attachments = const [],
      this.isEdited = false,
      this.replyToId,
      this.createdAt,
      this.updatedAt,
      this.senderName,
      this.senderAvatar,
      this.replyTo})
      : _attachments = attachments;

  factory _$MessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String threadId;
  @override
  final String senderId;
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

  @override
  @JsonKey()
  final bool isEdited;
  @override
  final String? replyToId;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
// Joined data
  @override
  final String? senderName;
  @override
  final String? senderAvatar;
  @override
  final Message? replyTo;

  @override
  String toString() {
    return 'Message(id: $id, tenantId: $tenantId, threadId: $threadId, senderId: $senderId, content: $content, attachments: $attachments, isEdited: $isEdited, replyToId: $replyToId, createdAt: $createdAt, updatedAt: $updatedAt, senderName: $senderName, senderAvatar: $senderAvatar, replyTo: $replyTo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.threadId, threadId) ||
                other.threadId == threadId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            (identical(other.replyToId, replyToId) ||
                other.replyToId == replyToId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderAvatar, senderAvatar) ||
                other.senderAvatar == senderAvatar) &&
            (identical(other.replyTo, replyTo) || other.replyTo == replyTo));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      threadId,
      senderId,
      content,
      const DeepCollectionEquality().hash(_attachments),
      isEdited,
      replyToId,
      createdAt,
      updatedAt,
      senderName,
      senderAvatar,
      replyTo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageImplToJson(
      this,
    );
  }
}

abstract class _Message implements Message {
  const factory _Message(
      {required final String id,
      required final String tenantId,
      required final String threadId,
      required final String senderId,
      required final String content,
      final List<Map<String, dynamic>> attachments,
      final bool isEdited,
      final String? replyToId,
      final DateTime? createdAt,
      final DateTime? updatedAt,
      final String? senderName,
      final String? senderAvatar,
      final Message? replyTo}) = _$MessageImpl;

  factory _Message.fromJson(Map<String, dynamic> json) = _$MessageImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get threadId;
  @override
  String get senderId;
  @override
  String get content;
  @override
  List<Map<String, dynamic>> get attachments;
  @override
  bool get isEdited;
  @override
  String? get replyToId;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override // Joined data
  String? get senderName;
  @override
  String? get senderAvatar;
  @override
  Message? get replyTo;
  @override
  @JsonKey(ignore: true)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
