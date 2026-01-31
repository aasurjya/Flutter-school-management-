import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Thread with _$Thread {
  const factory Thread({
    required String id,
    required String tenantId,
    required String threadType,
    String? title,
    String? sectionId,
    required String createdBy,
    @Default(true) bool isActive,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    // Joined data
    String? createdByName,
    String? sectionName,
    List<ThreadParticipant>? participants,
    Message? lastMessage,
    int? unreadCount,
  }) = _Thread;

  factory Thread.fromJson(Map<String, dynamic> json) => _$ThreadFromJson(json);
}

@freezed
class ThreadParticipant with _$ThreadParticipant {
  const factory ThreadParticipant({
    required String id,
    required String threadId,
    required String userId,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    @Default(false) bool isMuted,
    // Joined data
    String? userName,
    String? userAvatar,
  }) = _ThreadParticipant;

  factory ThreadParticipant.fromJson(Map<String, dynamic> json) =>
      _$ThreadParticipantFromJson(json);
}

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String tenantId,
    required String threadId,
    required String senderId,
    required String content,
    @Default([]) List<Map<String, dynamic>> attachments,
    @Default(false) bool isEdited,
    String? replyToId,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Joined data
    String? senderName,
    String? senderAvatar,
    Message? replyTo,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}

extension ThreadHelpers on Thread {
  bool get isPrivate => threadType == 'private';
  bool get isClass => threadType == 'class';
  bool get isGroup => threadType == 'group';
  bool get isBroadcast => threadType == 'broadcast';
  
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (isPrivate && participants != null && participants!.isNotEmpty) {
      return participants!.map((p) => p.userName ?? 'Unknown').join(', ');
    }
    if (isClass && sectionName != null) return 'Class: $sectionName';
    return 'Conversation';
  }
  
  String get threadTypeDisplay {
    switch (threadType) {
      case 'private':
        return 'Private';
      case 'class':
        return 'Class';
      case 'group':
        return 'Group';
      case 'broadcast':
        return 'Broadcast';
      default:
        return threadType;
    }
  }
}
