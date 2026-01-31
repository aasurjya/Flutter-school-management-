// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnnouncementImpl _$$AnnouncementImplFromJson(Map<String, dynamic> json) =>
    _$AnnouncementImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      targetRoles: (json['targetRoles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      targetSections: (json['targetSections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      priority: json['priority'] as String? ?? 'normal',
      publishAt: json['publishAt'] == null
          ? null
          : DateTime.parse(json['publishAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdBy: json['createdBy'] as String,
      isPublished: json['isPublished'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      createdByName: json['createdByName'] as String?,
    );

Map<String, dynamic> _$$AnnouncementImplToJson(_$AnnouncementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'title': instance.title,
      'content': instance.content,
      'attachments': instance.attachments,
      'targetRoles': instance.targetRoles,
      'targetSections': instance.targetSections,
      'priority': instance.priority,
      'publishAt': instance.publishAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdBy': instance.createdBy,
      'isPublished': instance.isPublished,
      'createdAt': instance.createdAt?.toIso8601String(),
      'createdByName': instance.createdByName,
    };
