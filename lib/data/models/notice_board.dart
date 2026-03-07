/// Notice Board Models

enum NoticeCategory {
  academic,
  sports,
  events,
  holiday,
  examination,
  fee,
  general,
  emergency;

  String get label {
    switch (this) {
      case NoticeCategory.academic:
        return 'Academic';
      case NoticeCategory.sports:
        return 'Sports';
      case NoticeCategory.events:
        return 'Events';
      case NoticeCategory.holiday:
        return 'Holiday';
      case NoticeCategory.examination:
        return 'Examination';
      case NoticeCategory.fee:
        return 'Fee';
      case NoticeCategory.general:
        return 'General';
      case NoticeCategory.emergency:
        return 'Emergency';
    }
  }

  String get value => name;

  static NoticeCategory fromString(String value) {
    return NoticeCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoticeCategory.general,
    );
  }
}

enum NoticeAudience {
  all,
  students,
  parents,
  teachers,
  staff;

  String get label {
    switch (this) {
      case NoticeAudience.all:
        return 'Everyone';
      case NoticeAudience.students:
        return 'Students';
      case NoticeAudience.parents:
        return 'Parents';
      case NoticeAudience.teachers:
        return 'Teachers';
      case NoticeAudience.staff:
        return 'Staff';
    }
  }

  String get value => name;

  static NoticeAudience fromString(String value) {
    return NoticeAudience.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoticeAudience.all,
    );
  }
}

class Notice {
  final String id;
  final String tenantId;
  final String title;
  final String body;
  final NoticeCategory category;
  final NoticeAudience audience;
  final bool isPinned;
  final bool isPublished;
  final String? attachmentUrl;
  final String? attachmentName;
  final String createdBy;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? authorName;

  const Notice({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.body,
    required this.category,
    required this.audience,
    required this.isPinned,
    required this.isPublished,
    this.attachmentUrl,
    this.attachmentName,
    required this.createdBy,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: NoticeCategory.fromString(json['category'] as String? ?? 'general'),
      audience: NoticeAudience.fromString(json['audience'] as String? ?? 'all'),
      isPinned: json['is_pinned'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? true,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      createdBy: json['created_by'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorName: (json['author'] as Map<String, dynamic>?)?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'title': title,
        'body': body,
        'category': category.value,
        'audience': audience.value,
        'is_pinned': isPinned,
        'is_published': isPublished,
        'attachment_url': attachmentUrl,
        'attachment_name': attachmentName,
        'created_by': createdBy,
        'expires_at': expiresAt?.toIso8601String(),
      };

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isActive => isPublished && !isExpired;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Notice copyWith({
    String? title,
    String? body,
    NoticeCategory? category,
    NoticeAudience? audience,
    bool? isPinned,
    bool? isPublished,
    String? attachmentUrl,
    String? attachmentName,
    DateTime? expiresAt,
  }) {
    return Notice(
      id: id,
      tenantId: tenantId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      audience: audience ?? this.audience,
      isPinned: isPinned ?? this.isPinned,
      isPublished: isPublished ?? this.isPublished,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      createdBy: createdBy,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      authorName: authorName,
    );
  }
}

class NoticeFilter {
  final NoticeCategory? category;
  final NoticeAudience? audience;
  final bool pinnedOnly;
  final String? search;

  const NoticeFilter({
    this.category,
    this.audience,
    this.pinnedOnly = false,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoticeFilter &&
          other.category == category &&
          other.audience == audience &&
          other.pinnedOnly == pinnedOnly &&
          other.search == search;

  @override
  int get hashCode => Object.hash(category, audience, pinnedOnly, search);
}
