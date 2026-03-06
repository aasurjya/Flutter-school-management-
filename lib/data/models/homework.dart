// ============================================================
// Homework Tracker Models
// ============================================================

enum HomeworkStatus {
  draft('draft', 'Draft'),
  published('published', 'Published'),
  closed('closed', 'Closed');

  final String value;
  final String label;
  const HomeworkStatus(this.value, this.label);

  static HomeworkStatus fromString(String value) {
    return HomeworkStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HomeworkStatus.draft,
    );
  }
}

enum HomeworkPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High');

  final String value;
  final String label;
  const HomeworkPriority(this.value, this.label);

  static HomeworkPriority fromString(String value) {
    return HomeworkPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HomeworkPriority.medium,
    );
  }
}

enum SubmissionStatus {
  pending('pending', 'Pending'),
  submitted('submitted', 'Submitted'),
  late_('late', 'Late'),
  graded('graded', 'Graded'),
  returned('returned', 'Returned');

  final String value;
  final String label;
  const SubmissionStatus(this.value, this.label);

  static SubmissionStatus fromString(String value) {
    return SubmissionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubmissionStatus.pending,
    );
  }
}

class Homework {
  final String id;
  final String tenantId;
  final String title;
  final String? description;
  final String? instructions;
  final String subjectId;
  final String sectionId;
  final String assignedBy;
  final DateTime assignedDate;
  final DateTime dueDate;
  final HomeworkStatus status;
  final HomeworkPriority priority;
  final int? maxMarks;
  final bool allowLateSubmission;
  final List<String> attachmentUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined data
  final String? subjectName;
  final String? sectionName;
  final String? className;
  final String? assignedByName;
  final int? totalStudents;
  final int? submittedCount;

  const Homework({
    required this.id,
    required this.tenantId,
    required this.title,
    this.description,
    this.instructions,
    required this.subjectId,
    required this.sectionId,
    required this.assignedBy,
    required this.assignedDate,
    required this.dueDate,
    this.status = HomeworkStatus.draft,
    this.priority = HomeworkPriority.medium,
    this.maxMarks,
    this.allowLateSubmission = false,
    this.attachmentUrls = const [],
    this.createdAt,
    this.updatedAt,
    this.subjectName,
    this.sectionName,
    this.className,
    this.assignedByName,
    this.totalStudents,
    this.submittedCount,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachment_urls'];
    List<String> parsedAttachments = [];
    if (rawAttachments is List) {
      parsedAttachments = rawAttachments.map((e) => e.toString()).toList();
    }

    // Parse joined data
    String? subjectName;
    if (json['subjects'] is Map<String, dynamic>) {
      subjectName = (json['subjects'] as Map<String, dynamic>)['name'] as String?;
    }

    String? sectionName;
    String? className;
    if (json['sections'] is Map<String, dynamic>) {
      final section = json['sections'] as Map<String, dynamic>;
      sectionName = section['name'] as String?;
      if (section['classes'] is Map<String, dynamic>) {
        className = (section['classes'] as Map<String, dynamic>)['name'] as String?;
      }
    }

    String? assignedByName;
    if (json['users'] is Map<String, dynamic>) {
      assignedByName = (json['users'] as Map<String, dynamic>)['full_name'] as String?;
    }

    return Homework(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      subjectId: json['subject_id'] as String,
      sectionId: json['section_id'] as String,
      assignedBy: json['assigned_by'] as String,
      assignedDate: DateTime.parse(json['assigned_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: HomeworkStatus.fromString(json['status'] as String? ?? 'draft'),
      priority: HomeworkPriority.fromString(json['priority'] as String? ?? 'medium'),
      maxMarks: (json['max_marks'] as num?)?.toInt(),
      allowLateSubmission: json['allow_late_submission'] as bool? ?? false,
      attachmentUrls: parsedAttachments,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      subjectName: subjectName,
      sectionName: sectionName,
      className: className,
      assignedByName: assignedByName,
      totalStudents: (json['total_students'] as num?)?.toInt(),
      submittedCount: (json['submitted_count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'subject_id': subjectId,
      'section_id': sectionId,
      'assigned_by': assignedBy,
      'assigned_date': assignedDate.toIso8601String().split('T').first,
      'due_date': dueDate.toIso8601String().split('T').first,
      'status': status.value,
      'priority': priority.value,
      'max_marks': maxMarks,
      'allow_late_submission': allowLateSubmission,
      'attachment_urls': attachmentUrls,
    };
  }

  Homework copyWith({
    String? title,
    String? description,
    String? instructions,
    String? subjectId,
    String? sectionId,
    DateTime? assignedDate,
    DateTime? dueDate,
    HomeworkStatus? status,
    HomeworkPriority? priority,
    int? maxMarks,
    bool? allowLateSubmission,
    List<String>? attachmentUrls,
  }) {
    return Homework(
      id: id,
      tenantId: tenantId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      subjectId: subjectId ?? this.subjectId,
      sectionId: sectionId ?? this.sectionId,
      assignedBy: assignedBy,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      maxMarks: maxMarks ?? this.maxMarks,
      allowLateSubmission: allowLateSubmission ?? this.allowLateSubmission,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt,
      updatedAt: updatedAt,
      subjectName: subjectName,
      sectionName: sectionName,
      className: className,
      assignedByName: assignedByName,
      totalStudents: totalStudents,
      submittedCount: submittedCount,
    );
  }

  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status == HomeworkStatus.published;
  double get submissionRate =>
      (totalStudents != null && totalStudents! > 0 && submittedCount != null)
          ? (submittedCount! / totalStudents!) * 100
          : 0;
}

class HomeworkSubmission {
  final String id;
  final String homeworkId;
  final String studentId;
  final String? content;
  final List<String> attachmentUrls;
  final SubmissionStatus status;
  final DateTime? submittedAt;
  final int? marks;
  final String? feedback;
  final String? gradedBy;
  final DateTime? gradedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined data
  final String? studentName;
  final String? studentRollNo;

  const HomeworkSubmission({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    this.content,
    this.attachmentUrls = const [],
    this.status = SubmissionStatus.pending,
    this.submittedAt,
    this.marks,
    this.feedback,
    this.gradedBy,
    this.gradedAt,
    this.createdAt,
    this.updatedAt,
    this.studentName,
    this.studentRollNo,
  });

  factory HomeworkSubmission.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachment_urls'];
    List<String> parsedAttachments = [];
    if (rawAttachments is List) {
      parsedAttachments = rawAttachments.map((e) => e.toString()).toList();
    }

    String? studentName;
    String? studentRollNo;
    if (json['students'] is Map<String, dynamic>) {
      final student = json['students'] as Map<String, dynamic>;
      studentName = student['full_name'] as String?;
      studentRollNo = student['roll_number'] as String?;
    }

    return HomeworkSubmission(
      id: json['id'] as String,
      homeworkId: json['homework_id'] as String,
      studentId: json['student_id'] as String,
      content: json['content'] as String?,
      attachmentUrls: parsedAttachments,
      status: SubmissionStatus.fromString(json['status'] as String? ?? 'pending'),
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at'] as String) : null,
      marks: (json['marks'] as num?)?.toInt(),
      feedback: json['feedback'] as String?,
      gradedBy: json['graded_by'] as String?,
      gradedAt: json['graded_at'] != null ? DateTime.parse(json['graded_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      studentName: studentName,
      studentRollNo: studentRollNo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homework_id': homeworkId,
      'student_id': studentId,
      'content': content,
      'attachment_urls': attachmentUrls,
      'status': status.value,
      'submitted_at': submittedAt?.toIso8601String(),
      'marks': marks,
      'feedback': feedback,
      'graded_by': gradedBy,
      'graded_at': gradedAt?.toIso8601String(),
    };
  }

  HomeworkSubmission copyWith({
    String? content,
    List<String>? attachmentUrls,
    SubmissionStatus? status,
    DateTime? submittedAt,
    int? marks,
    String? feedback,
    String? gradedBy,
    DateTime? gradedAt,
  }) {
    return HomeworkSubmission(
      id: id,
      homeworkId: homeworkId,
      studentId: studentId,
      content: content ?? this.content,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      marks: marks ?? this.marks,
      feedback: feedback ?? this.feedback,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      studentName: studentName,
      studentRollNo: studentRollNo,
    );
  }
}

class HomeworkDashboardStats {
  final int totalHomework;
  final int activeHomework;
  final int overdueHomework;
  final int pendingSubmissions;
  final int gradedSubmissions;
  final double averageSubmissionRate;

  const HomeworkDashboardStats({
    this.totalHomework = 0,
    this.activeHomework = 0,
    this.overdueHomework = 0,
    this.pendingSubmissions = 0,
    this.gradedSubmissions = 0,
    this.averageSubmissionRate = 0,
  });
}
