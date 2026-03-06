// LMS (Learning Management System) module models

// ============================================
// ENUMS
// ============================================

enum CourseStatus {
  draft,
  published,
  archived;

  String get value {
    switch (this) {
      case CourseStatus.draft:
        return 'draft';
      case CourseStatus.published:
        return 'published';
      case CourseStatus.archived:
        return 'archived';
    }
  }

  String get label {
    switch (this) {
      case CourseStatus.draft:
        return 'Draft';
      case CourseStatus.published:
        return 'Published';
      case CourseStatus.archived:
        return 'Archived';
    }
  }

  static CourseStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return CourseStatus.draft;
      case 'published':
        return CourseStatus.published;
      case 'archived':
        return CourseStatus.archived;
      default:
        return CourseStatus.draft;
    }
  }
}

enum ContentType {
  video,
  document,
  presentation,
  link,
  text,
  quiz,
  assignment;

  String get value {
    switch (this) {
      case ContentType.video:
        return 'video';
      case ContentType.document:
        return 'document';
      case ContentType.presentation:
        return 'presentation';
      case ContentType.link:
        return 'link';
      case ContentType.text:
        return 'text';
      case ContentType.quiz:
        return 'quiz';
      case ContentType.assignment:
        return 'assignment';
    }
  }

  String get label {
    switch (this) {
      case ContentType.video:
        return 'Video';
      case ContentType.document:
        return 'Document';
      case ContentType.presentation:
        return 'Presentation';
      case ContentType.link:
        return 'Link';
      case ContentType.text:
        return 'Text';
      case ContentType.quiz:
        return 'Quiz';
      case ContentType.assignment:
        return 'Assignment';
    }
  }

  static ContentType fromString(String value) {
    switch (value) {
      case 'video':
        return ContentType.video;
      case 'document':
        return ContentType.document;
      case 'presentation':
        return ContentType.presentation;
      case 'link':
        return ContentType.link;
      case 'text':
        return ContentType.text;
      case 'quiz':
        return ContentType.quiz;
      case 'assignment':
        return ContentType.assignment;
      default:
        return ContentType.text;
    }
  }
}

enum EnrollmentStatus {
  enrolled,
  inProgress,
  completed,
  dropped;

  String get value {
    switch (this) {
      case EnrollmentStatus.enrolled:
        return 'enrolled';
      case EnrollmentStatus.inProgress:
        return 'in_progress';
      case EnrollmentStatus.completed:
        return 'completed';
      case EnrollmentStatus.dropped:
        return 'dropped';
    }
  }

  String get label {
    switch (this) {
      case EnrollmentStatus.enrolled:
        return 'Enrolled';
      case EnrollmentStatus.inProgress:
        return 'In Progress';
      case EnrollmentStatus.completed:
        return 'Completed';
      case EnrollmentStatus.dropped:
        return 'Dropped';
    }
  }

  static EnrollmentStatus fromString(String value) {
    switch (value) {
      case 'enrolled':
        return EnrollmentStatus.enrolled;
      case 'in_progress':
        return EnrollmentStatus.inProgress;
      case 'completed':
        return EnrollmentStatus.completed;
      case 'dropped':
        return EnrollmentStatus.dropped;
      default:
        return EnrollmentStatus.enrolled;
    }
  }
}

enum ContentProgressStatus {
  notStarted,
  inProgress,
  completed;

  String get value {
    switch (this) {
      case ContentProgressStatus.notStarted:
        return 'not_started';
      case ContentProgressStatus.inProgress:
        return 'in_progress';
      case ContentProgressStatus.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case ContentProgressStatus.notStarted:
        return 'Not Started';
      case ContentProgressStatus.inProgress:
        return 'In Progress';
      case ContentProgressStatus.completed:
        return 'Completed';
    }
  }

  static ContentProgressStatus fromString(String value) {
    switch (value) {
      case 'not_started':
        return ContentProgressStatus.notStarted;
      case 'in_progress':
        return ContentProgressStatus.inProgress;
      case 'completed':
        return ContentProgressStatus.completed;
      default:
        return ContentProgressStatus.notStarted;
    }
  }
}

// ============================================
// MODEL CLASSES
// ============================================

/// Course model
class Course {
  final String id;
  final String tenantId;
  final String title;
  final String? description;
  final String? subjectId;
  final String? classId;
  final String teacherId;
  final String? thumbnailUrl;
  final CourseStatus status;
  final bool isSelfPaced;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? enrollmentLimit;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? subjectName;
  final String? className;
  final String? teacherName;
  final int? enrolledCount;
  final List<CourseModule>? modules;

  const Course({
    required this.id,
    required this.tenantId,
    required this.title,
    this.description,
    this.subjectId,
    this.classId,
    required this.teacherId,
    this.thumbnailUrl,
    required this.status,
    this.isSelfPaced = false,
    this.startDate,
    this.endDate,
    this.enrollmentLimit,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.subjectName,
    this.className,
    this.teacherName,
    this.enrolledCount,
    this.modules,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    String? subjectName;
    if (json['subjects'] != null) {
      subjectName = json['subjects']['name'];
    }

    String? className;
    if (json['classes'] != null) {
      className = json['classes']['name'];
    }

    String? teacherName;
    if (json['users'] != null) {
      teacherName = json['users']['full_name'];
    }

    List<CourseModule>? modules;
    if (json['course_modules'] != null) {
      modules = (json['course_modules'] as List)
          .map((j) => CourseModule.fromJson(j))
          .toList()
        ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
    }

    List<String> tags = [];
    if (json['tags'] != null && json['tags'] is List) {
      tags = (json['tags'] as List).map((e) => e.toString()).toList();
    }

    int? enrolledCount;
    if (json['course_enrollments'] != null &&
        json['course_enrollments'] is List) {
      enrolledCount = (json['course_enrollments'] as List).length;
    }

    return Course(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      subjectId: json['subject_id'],
      classId: json['class_id'],
      teacherId: json['teacher_id'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      status: CourseStatus.fromString(json['status'] ?? 'draft'),
      isSelfPaced: json['is_self_paced'] ?? false,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      enrollmentLimit: json['enrollment_limit'],
      tags: tags,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      subjectName: subjectName,
      className: className,
      teacherName: teacherName,
      enrolledCount: enrolledCount,
      modules: modules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'class_id': classId,
      'teacher_id': teacherId,
      'thumbnail_url': thumbnailUrl,
      'status': status.value,
      'is_self_paced': isSelfPaced,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'enrollment_limit': enrollmentLimit,
      'tags': tags,
    };
  }

  /// Total duration of all modules in minutes
  int get totalDurationMinutes =>
      modules?.fold<int>(0, (sum, m) => sum + m.durationMinutes) ?? 0;

  /// Total content count across all modules
  int get totalContentCount =>
      modules?.fold<int>(0, (sum, m) => sum + (m.contents?.length ?? 0)) ?? 0;
}

/// Course Module model
class CourseModule {
  final String id;
  final String tenantId;
  final String courseId;
  final String title;
  final String? description;
  final int sequenceOrder;
  final int durationMinutes;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final List<ModuleContent>? contents;

  const CourseModule({
    required this.id,
    required this.tenantId,
    required this.courseId,
    required this.title,
    this.description,
    required this.sequenceOrder,
    this.durationMinutes = 0,
    this.isLocked = false,
    required this.createdAt,
    required this.updatedAt,
    this.contents,
  });

  factory CourseModule.fromJson(Map<String, dynamic> json) {
    List<ModuleContent>? contents;
    if (json['module_content'] != null) {
      contents = (json['module_content'] as List)
          .map((j) => ModuleContent.fromJson(j))
          .toList()
        ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
    }

    return CourseModule(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      courseId: json['course_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      sequenceOrder: json['sequence_order'] ?? 0,
      durationMinutes: json['duration_minutes'] ?? 0,
      isLocked: json['is_locked'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      contents: contents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'course_id': courseId,
      'title': title,
      'description': description,
      'sequence_order': sequenceOrder,
      'duration_minutes': durationMinutes,
      'is_locked': isLocked,
    };
  }
}

/// Module Content model
class ModuleContent {
  final String id;
  final String tenantId;
  final String moduleId;
  final ContentType contentType;
  final String title;
  final Map<String, dynamic> contentData;
  final int sequenceOrder;
  final bool isMandatory;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ModuleContent({
    required this.id,
    required this.tenantId,
    required this.moduleId,
    required this.contentType,
    required this.title,
    required this.contentData,
    required this.sequenceOrder,
    this.isMandatory = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModuleContent.fromJson(Map<String, dynamic> json) {
    final contentDataRaw = json['content_data'];
    final contentData = contentDataRaw is Map<String, dynamic>
        ? contentDataRaw
        : <String, dynamic>{};

    return ModuleContent(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      moduleId: json['module_id'] ?? '',
      contentType: ContentType.fromString(json['content_type'] ?? 'text'),
      title: json['title'] ?? '',
      contentData: contentData,
      sequenceOrder: json['sequence_order'] ?? 0,
      isMandatory: json['is_mandatory'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'module_id': moduleId,
      'content_type': contentType.value,
      'title': title,
      'content_data': contentData,
      'sequence_order': sequenceOrder,
      'is_mandatory': isMandatory,
    };
  }

  /// Convenience getters for common content_data fields
  String? get url => contentData['url'] as String?;
  String? get text => contentData['text'] as String?;
  int? get fileSize => contentData['file_size'] as int?;
  int? get duration => contentData['duration'] as int?;
}

/// Course Enrollment model
class CourseEnrollment {
  final String id;
  final String tenantId;
  final String courseId;
  final String studentId;
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final double progressPercentage;
  final EnrollmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? courseName;
  final String? studentName;
  final Course? course;

  const CourseEnrollment({
    required this.id,
    required this.tenantId,
    required this.courseId,
    required this.studentId,
    required this.enrolledAt,
    this.completedAt,
    this.progressPercentage = 0,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.courseName,
    this.studentName,
    this.course,
  });

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) {
    String? courseName;
    Course? course;
    if (json['courses'] != null) {
      courseName = json['courses']['title'];
      course = Course.fromJson(json['courses']);
    }

    String? studentName;
    if (json['users'] != null) {
      studentName = json['users']['full_name'];
    }

    return CourseEnrollment(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      courseId: json['course_id'] ?? '',
      studentId: json['student_id'] ?? '',
      enrolledAt: json['enrolled_at'] != null
          ? DateTime.parse(json['enrolled_at'])
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      progressPercentage: json['progress_percentage'] != null
          ? (json['progress_percentage'] as num).toDouble()
          : 0,
      status: EnrollmentStatus.fromString(json['status'] ?? 'enrolled'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      courseName: courseName,
      studentName: studentName,
      course: course,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'course_id': courseId,
      'student_id': studentId,
      'status': status.value,
      'progress_percentage': progressPercentage,
    };
  }
}

/// Content Progress model
class ContentProgress {
  final String id;
  final String tenantId;
  final String enrollmentId;
  final String contentId;
  final ContentProgressStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int timeSpentSeconds;
  final double? score;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentProgress({
    required this.id,
    required this.tenantId,
    required this.enrollmentId,
    required this.contentId,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.timeSpentSeconds = 0,
    this.score,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentProgress.fromJson(Map<String, dynamic> json) {
    return ContentProgress(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      enrollmentId: json['enrollment_id'] ?? '',
      contentId: json['content_id'] ?? '',
      status:
          ContentProgressStatus.fromString(json['status'] ?? 'not_started'),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      timeSpentSeconds: json['time_spent_seconds'] ?? 0,
      score:
          json['score'] != null ? (json['score'] as num).toDouble() : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'enrollment_id': enrollmentId,
      'content_id': contentId,
      'status': status.value,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'time_spent_seconds': timeSpentSeconds,
      'score': score,
    };
  }

  /// Format time spent as human-readable string
  String get timeSpentFormatted {
    final h = timeSpentSeconds ~/ 3600;
    final m = (timeSpentSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

/// Discussion Forum model
class DiscussionForum {
  final String id;
  final String tenantId;
  final String courseId;
  final String title;
  final String? description;
  final String createdBy;
  final bool isPinned;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? createdByName;
  final int? postCount;
  final List<ForumPost>? posts;

  const DiscussionForum({
    required this.id,
    required this.tenantId,
    required this.courseId,
    required this.title,
    this.description,
    required this.createdBy,
    this.isPinned = false,
    this.isLocked = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdByName,
    this.postCount,
    this.posts,
  });

  factory DiscussionForum.fromJson(Map<String, dynamic> json) {
    String? createdByName;
    if (json['users'] != null) {
      createdByName = json['users']['full_name'];
    }

    List<ForumPost>? posts;
    int? postCount;
    if (json['forum_posts'] != null && json['forum_posts'] is List) {
      final postsList = json['forum_posts'] as List;
      postCount = postsList.length;
      posts = postsList.map((j) => ForumPost.fromJson(j)).toList();
    }

    return DiscussionForum(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      courseId: json['course_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      createdBy: json['created_by'] ?? '',
      isPinned: json['is_pinned'] ?? false,
      isLocked: json['is_locked'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      createdByName: createdByName,
      postCount: postCount,
      posts: posts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'course_id': courseId,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'is_pinned': isPinned,
      'is_locked': isLocked,
    };
  }
}

/// Forum Post model
class ForumPost {
  final String id;
  final String tenantId;
  final String forumId;
  final String authorId;
  final String? parentPostId;
  final String content;
  final bool isAnswer;
  final int upvotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? authorName;
  final List<ForumPost>? replies;

  const ForumPost({
    required this.id,
    required this.tenantId,
    required this.forumId,
    required this.authorId,
    this.parentPostId,
    required this.content,
    this.isAnswer = false,
    this.upvotes = 0,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.replies,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    String? authorName;
    if (json['users'] != null) {
      authorName = json['users']['full_name'];
    }

    return ForumPost(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      forumId: json['forum_id'] ?? '',
      authorId: json['author_id'] ?? '',
      parentPostId: json['parent_post_id'],
      content: json['content'] ?? '',
      isAnswer: json['is_answer'] ?? false,
      upvotes: json['upvotes'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      authorName: authorName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'forum_id': forumId,
      'author_id': authorId,
      'parent_post_id': parentPostId,
      'content': content,
      'is_answer': isAnswer,
    };
  }
}

/// Course Certificate model
class CourseCertificate {
  final String id;
  final String tenantId;
  final String enrollmentId;
  final String certificateNumber;
  final DateTime issuedAt;
  final Map<String, dynamic> templateData;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? courseName;
  final String? studentName;

  const CourseCertificate({
    required this.id,
    required this.tenantId,
    required this.enrollmentId,
    required this.certificateNumber,
    required this.issuedAt,
    this.templateData = const {},
    required this.createdAt,
    required this.updatedAt,
    this.courseName,
    this.studentName,
  });

  factory CourseCertificate.fromJson(Map<String, dynamic> json) {
    String? courseName;
    String? studentName;
    if (json['course_enrollments'] != null) {
      final enrollment = json['course_enrollments'];
      if (enrollment['courses'] != null) {
        courseName = enrollment['courses']['title'];
      }
      if (enrollment['users'] != null) {
        studentName = enrollment['users']['full_name'];
      }
    }

    final templateDataRaw = json['template_data'];
    final templateData = templateDataRaw is Map<String, dynamic>
        ? templateDataRaw
        : <String, dynamic>{};

    return CourseCertificate(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      enrollmentId: json['enrollment_id'] ?? '',
      certificateNumber: json['certificate_number'] ?? '',
      issuedAt: json['issued_at'] != null
          ? DateTime.parse(json['issued_at'])
          : DateTime.now(),
      templateData: templateData,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      courseName: courseName,
      studentName: studentName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'enrollment_id': enrollmentId,
      'certificate_number': certificateNumber,
      'issued_at': issuedAt.toIso8601String(),
      'template_data': templateData,
    };
  }
}

/// LMS Dashboard Stats
class LmsStats {
  final int totalCourses;
  final int publishedCourses;
  final int totalEnrollments;
  final int completedEnrollments;
  final int inProgressEnrollments;
  final double avgProgress;
  final int totalCertificates;

  const LmsStats({
    this.totalCourses = 0,
    this.publishedCourses = 0,
    this.totalEnrollments = 0,
    this.completedEnrollments = 0,
    this.inProgressEnrollments = 0,
    this.avgProgress = 0,
    this.totalCertificates = 0,
  });

  double get completionRate =>
      totalEnrollments > 0 ? completedEnrollments / totalEnrollments : 0;
}
