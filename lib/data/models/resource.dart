// Study Resource Model

class StudyResource {
  final String id;
  final String tenantId;
  final String title;
  final String description;
  final String resourceType; // document, video, audio, link, image
  final String? fileUrl;
  final String? externalUrl;
  final String? thumbnailUrl;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? subjectId;
  final String? classId;
  final String? chapterId;
  final List<String> tags;
  final String uploadedBy;
  final bool isPublic;
  final int downloadCount;
  final int viewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Joined data
  final String? subjectName;
  final String? className;
  final String? chapterName;
  final String? uploaderName;

  const StudyResource({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.description,
    required this.resourceType,
    this.fileUrl,
    this.externalUrl,
    this.thumbnailUrl,
    this.fileSizeBytes,
    this.mimeType,
    this.subjectId,
    this.classId,
    this.chapterId,
    this.tags = const [],
    required this.uploadedBy,
    this.isPublic = true,
    this.downloadCount = 0,
    this.viewCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.subjectName,
    this.className,
    this.chapterName,
    this.uploaderName,
  });

  factory StudyResource.fromJson(Map<String, dynamic> json) {
    return StudyResource(
      id: json['id'],
      tenantId: json['tenant_id'],
      title: json['title'],
      description: json['description'] ?? '',
      resourceType: json['resource_type'] ?? 'document',
      fileUrl: json['file_url'],
      externalUrl: json['external_url'],
      thumbnailUrl: json['thumbnail_url'],
      fileSizeBytes: json['file_size_bytes'],
      mimeType: json['mime_type'],
      subjectId: json['subject_id'],
      classId: json['class_id'],
      chapterId: json['chapter_id'],
      tags: List<String>.from(json['tags'] ?? []),
      uploadedBy: json['uploaded_by'],
      isPublic: json['is_public'] ?? true,
      downloadCount: json['download_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      subjectName: json['subject']?['name'] ?? json['subject_name'],
      className: json['class']?['name'] ?? json['class_name'],
      chapterName: json['chapter']?['name'] ?? json['chapter_name'],
      uploaderName: json['uploader']?['full_name'] ?? json['uploader_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'resource_type': resourceType,
      'file_url': fileUrl,
      'external_url': externalUrl,
      'thumbnail_url': thumbnailUrl,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'subject_id': subjectId,
      'class_id': classId,
      'chapter_id': chapterId,
      'tags': tags,
      'uploaded_by': uploadedBy,
      'is_public': isPublic,
    };
  }

  String get resourceTypeDisplay {
    switch (resourceType) {
      case 'document':
        return 'Document';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'link':
        return 'External Link';
      case 'image':
        return 'Image';
      default:
        return resourceType;
    }
  }

  String get fileSizeDisplay {
    if (fileSizeBytes == null) return '';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1024 * 1024) {
      return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSizeBytes! < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get isDocument =>
      resourceType == 'document' ||
      mimeType?.contains('pdf') == true ||
      mimeType?.contains('word') == true ||
      mimeType?.contains('document') == true;

  bool get isVideo =>
      resourceType == 'video' || mimeType?.startsWith('video/') == true;

  bool get isAudio =>
      resourceType == 'audio' || mimeType?.startsWith('audio/') == true;

  bool get isImage =>
      resourceType == 'image' || mimeType?.startsWith('image/') == true;

  bool get isExternalLink => resourceType == 'link' && externalUrl != null;
}

class ResourceFolder {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String? parentId;
  final String? subjectId;
  final String? classId;
  final String createdBy;
  final DateTime createdAt;
  final int resourceCount;

  // Joined data
  final String? subjectName;
  final String? className;
  final List<ResourceFolder> subfolders;

  const ResourceFolder({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.parentId,
    this.subjectId,
    this.classId,
    required this.createdBy,
    required this.createdAt,
    this.resourceCount = 0,
    this.subjectName,
    this.className,
    this.subfolders = const [],
  });

  factory ResourceFolder.fromJson(Map<String, dynamic> json) {
    return ResourceFolder(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      description: json['description'],
      parentId: json['parent_id'],
      subjectId: json['subject_id'],
      classId: json['class_id'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      resourceCount: json['resource_count'] ?? 0,
      subjectName: json['subject']?['name'] ?? json['subject_name'],
      className: json['class']?['name'] ?? json['class_name'],
      subfolders: (json['subfolders'] as List?)
              ?.map((f) => ResourceFolder.fromJson(f))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'parent_id': parentId,
      'subject_id': subjectId,
      'class_id': classId,
      'created_by': createdBy,
    };
  }
}

class ResourceCategory {
  final String id;
  final String name;
  final String? iconName;
  final int resourceCount;

  const ResourceCategory({
    required this.id,
    required this.name,
    this.iconName,
    this.resourceCount = 0,
  });

  factory ResourceCategory.fromJson(Map<String, dynamic> json) {
    return ResourceCategory(
      id: json['id'] ?? json['subject_id'] ?? '',
      name: json['name'] ?? json['subject_name'] ?? 'Unknown',
      iconName: json['icon_name'],
      resourceCount: json['resource_count'] ?? 0,
    );
  }
}

class ResourceFilter {
  final String? subjectId;
  final String? classId;
  final String? resourceType;
  final String? searchQuery;
  final List<String>? tags;
  final String? uploadedBy;
  final bool myUploadsOnly;
  final int? limit;
  final int? offset;

  const ResourceFilter({
    this.subjectId,
    this.classId,
    this.resourceType,
    this.searchQuery,
    this.tags,
    this.uploadedBy,
    this.myUploadsOnly = false,
    this.limit,
    this.offset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceFilter &&
          other.subjectId == subjectId &&
          other.classId == classId &&
          other.resourceType == resourceType &&
          other.searchQuery == searchQuery &&
          other.myUploadsOnly == myUploadsOnly &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(
        subjectId,
        classId,
        resourceType,
        searchQuery,
        myUploadsOnly,
        limit,
        offset,
      );
}
