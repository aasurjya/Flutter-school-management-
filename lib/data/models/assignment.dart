import 'package:freezed_annotation/freezed_annotation.dart';

part 'assignment.freezed.dart';
part 'assignment.g.dart';

@freezed
class Assignment with _$Assignment {
  const factory Assignment({
    required String id,
    required String tenantId,
    required String sectionId,
    required String subjectId,
    required String teacherId,
    required String title,
    String? description,
    String? instructions,
    required DateTime dueDate,
    double? maxMarks,
    @Default([]) List<Map<String, dynamic>> attachments,
    @Default('draft') String status,
    @Default(false) bool allowLateSubmission,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Joined data
    String? sectionName,
    String? className,
    String? subjectName,
    String? subjectCode,
    String? teacherName,
    // Summary
    int? totalStudents,
    int? submittedCount,
    int? gradedCount,
    int? lateCount,
  }) = _Assignment;

  factory Assignment.fromJson(Map<String, dynamic> json) =>
      _$AssignmentFromJson(json);
}

@freezed
class Submission with _$Submission {
  const Submission._();
  
  const factory Submission({
    required String id,
    required String tenantId,
    required String assignmentId,
    required String studentId,
    String? content,
    @Default([]) List<Map<String, dynamic>> attachments,
    DateTime? submittedAt,
    @Default('pending') String status,
    double? marksObtained,
    String? feedback,
    String? gradedBy,
    DateTime? gradedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Joined data
    String? studentName,
    String? admissionNumber,
    String? assignmentTitle,
    double? maxMarks,
    DateTime? dueDate,
    String? gradedByName,
  }) = _Submission;

  factory Submission.fromJson(Map<String, dynamic> json) =>
      _$SubmissionFromJson(json);

  bool get isPending => status == 'pending';
  bool get isSubmitted => status == 'submitted';
  bool get isLate => status == 'late';
  bool get isGraded => status == 'graded';
  bool get isReturned => status == 'returned';
}

@freezed
class AssignmentSummary with _$AssignmentSummary {
  const factory AssignmentSummary({
    required String tenantId,
    required String assignmentId,
    required String title,
    required String sectionId,
    required String sectionName,
    required String className,
    required String subjectId,
    required String subjectName,
    required String teacherId,
    required String teacherName,
    required DateTime dueDate,
    double? maxMarks,
    required String status,
    required int totalStudents,
    required int submittedCount,
    required int gradedCount,
    required int lateCount,
    required bool isPastDue,
  }) = _AssignmentSummary;

  factory AssignmentSummary.fromJson(Map<String, dynamic> json) =>
      _$AssignmentSummaryFromJson(json);
}

extension AssignmentHelpers on Assignment {
  bool get isPastDue => DateTime.now().isAfter(dueDate);
  
  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isClosed => status == 'closed';
  
  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'published':
        return 'Published';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }
  
  int get pendingCount => (totalStudents ?? 0) - (submittedCount ?? 0);
  int get pendingGradingCount => (submittedCount ?? 0) - (gradedCount ?? 0);
}

