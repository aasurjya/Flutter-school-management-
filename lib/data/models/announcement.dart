import 'package:freezed_annotation/freezed_annotation.dart';

part 'announcement.freezed.dart';
part 'announcement.g.dart';

@freezed
class Announcement with _$Announcement {
  const factory Announcement({
    required String id,
    required String tenantId,
    required String title,
    required String content,
    @Default([]) List<Map<String, dynamic>> attachments,
    @Default([]) List<String> targetRoles,
    @Default([]) List<String> targetSections,
    @Default('normal') String priority,
    DateTime? publishAt,
    DateTime? expiresAt,
    required String createdBy,
    @Default(false) bool isPublished,
    DateTime? createdAt,
    // Joined data
    String? createdByName,
  }) = _Announcement;

  factory Announcement.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementFromJson(json);
}

extension AnnouncementHelpers on Announcement {
  bool get isHighPriority => priority == 'high';
  bool get isUrgent => priority == 'urgent';
  
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  bool get isScheduled {
    if (publishAt == null) return false;
    return DateTime.now().isBefore(publishAt!);
  }
  
  bool get isActive => isPublished && !isExpired && !isScheduled;
  
  String get priorityDisplay {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }
}
