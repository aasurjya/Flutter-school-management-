// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ThreadImpl _$$ThreadImplFromJson(Map<String, dynamic> json) => _$ThreadImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      threadType: json['threadType'] as String,
      title: json['title'] as String?,
      sectionId: json['sectionId'] as String?,
      createdBy: json['createdBy'] as String,
      isActive: json['isActive'] as bool? ?? true,
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      createdByName: json['createdByName'] as String?,
      sectionName: json['sectionName'] as String?,
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => ThreadParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] == null
          ? null
          : Message.fromJson(json['lastMessage'] as Map<String, dynamic>),
      unreadCount: (json['unreadCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ThreadImplToJson(_$ThreadImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'threadType': instance.threadType,
      'title': instance.title,
      'sectionId': instance.sectionId,
      'createdBy': instance.createdBy,
      'isActive': instance.isActive,
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'createdByName': instance.createdByName,
      'sectionName': instance.sectionName,
      'participants': instance.participants,
      'lastMessage': instance.lastMessage,
      'unreadCount': instance.unreadCount,
    };

_$ThreadParticipantImpl _$$ThreadParticipantImplFromJson(
        Map<String, dynamic> json) =>
    _$ThreadParticipantImpl(
      id: json['id'] as String,
      threadId: json['threadId'] as String,
      userId: json['userId'] as String,
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
      isMuted: json['isMuted'] as bool? ?? false,
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
    );

Map<String, dynamic> _$$ThreadParticipantImplToJson(
        _$ThreadParticipantImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'threadId': instance.threadId,
      'userId': instance.userId,
      'joinedAt': instance.joinedAt?.toIso8601String(),
      'lastReadAt': instance.lastReadAt?.toIso8601String(),
      'isMuted': instance.isMuted,
      'userName': instance.userName,
      'userAvatar': instance.userAvatar,
    };

_$MessageImpl _$$MessageImplFromJson(Map<String, dynamic> json) =>
    _$MessageImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      threadId: json['threadId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      isEdited: json['isEdited'] as bool? ?? false,
      replyToId: json['replyToId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      replyTo: json['replyTo'] == null
          ? null
          : Message.fromJson(json['replyTo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MessageImplToJson(_$MessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'threadId': instance.threadId,
      'senderId': instance.senderId,
      'content': instance.content,
      'attachments': instance.attachments,
      'isEdited': instance.isEdited,
      'replyToId': instance.replyToId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'senderName': instance.senderName,
      'senderAvatar': instance.senderAvatar,
      'replyTo': instance.replyTo,
    };
