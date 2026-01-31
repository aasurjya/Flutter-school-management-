import 'package:freezed_annotation/freezed_annotation.dart';

part 'exam_statistics.freezed.dart';
part 'exam_statistics.g.dart';

@freezed
class Exam with _$Exam {
  const factory Exam({
    required String id,
    required String tenantId,
    required String academicYearId,
    String? termId,
    required String name,
    required String examType,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    @Default(false) bool isPublished,
    DateTime? createdAt,
    // Joined data
    String? termName,
    String? academicYearName,
    List<ExamSubject>? subjects,
  }) = _Exam;

  factory Exam.fromJson(Map<String, dynamic> json) => _$ExamFromJson(json);
}

@freezed
class ExamSubject with _$ExamSubject {
  const factory ExamSubject({
    required String id,
    required String tenantId,
    required String examId,
    required String subjectId,
    required String classId,
    DateTime? examDate,
    String? startTime,
    String? endTime,
    required double maxMarks,
    required double passingMarks,
    @Default(1.0) double weightage,
    String? syllabus,
    DateTime? createdAt,
    // Joined data
    String? subjectName,
    String? subjectCode,
    String? className,
  }) = _ExamSubject;

  factory ExamSubject.fromJson(Map<String, dynamic> json) =>
      _$ExamSubjectFromJson(json);
}

@freezed
class Mark with _$Mark {
  const factory Mark({
    required String id,
    required String tenantId,
    required String examSubjectId,
    required String studentId,
    double? marksObtained,
    @Default(false) bool isAbsent,
    String? remarks,
    String? enteredBy,
    DateTime? enteredAt,
    DateTime? updatedAt,
    // Joined data
    String? studentName,
    String? admissionNumber,
    String? subjectName,
    double? maxMarks,
    double? passingMarks,
  }) = _Mark;

  factory Mark.fromJson(Map<String, dynamic> json) => _$MarkFromJson(json);
}

@freezed
class StudentPerformance with _$StudentPerformance {
  const factory StudentPerformance({
    required String tenantId,
    required String studentId,
    required String studentName,
    required String admissionNumber,
    required String sectionId,
    required String sectionName,
    required String classId,
    required String className,
    required String examId,
    required String examName,
    required String examType,
    required String subjectId,
    required String subjectName,
    String? subjectCode,
    required double marksObtained,
    required double maxMarks,
    required double passingMarks,
    required double percentage,
    required bool isPassed,
    @Default(false) bool isAbsent,
    required String academicYearId,
    String? termId,
  }) = _StudentPerformance;

  factory StudentPerformance.fromJson(Map<String, dynamic> json) =>
      _$StudentPerformanceFromJson(json);
}

@freezed
class StudentRank with _$StudentRank {
  const factory StudentRank({
    required String tenantId,
    required String studentId,
    required String studentName,
    required String admissionNumber,
    required String sectionId,
    required String sectionName,
    required String classId,
    required String className,
    required String examId,
    required String examName,
    required String examType,
    required String subjectId,
    required String subjectName,
    required double marksObtained,
    required double maxMarks,
    required double percentage,
    required int subjectRank,
    required int totalInSubject,
    required String academicYearId,
  }) = _StudentRank;

  factory StudentRank.fromJson(Map<String, dynamic> json) =>
      _$StudentRankFromJson(json);
}

@freezed
class StudentOverallRank with _$StudentOverallRank {
  const factory StudentOverallRank({
    required String tenantId,
    required String studentId,
    required String studentName,
    required String admissionNumber,
    required String sectionId,
    required String sectionName,
    required String classId,
    required String className,
    required String examId,
    required String examName,
    required String examType,
    required String academicYearId,
    required double totalObtained,
    required double totalMaxMarks,
    required double overallPercentage,
    required int subjectsCount,
    required int subjectsPassed,
    required int classRank,
  }) = _StudentOverallRank;

  factory StudentOverallRank.fromJson(Map<String, dynamic> json) =>
      _$StudentOverallRankFromJson(json);
}

@freezed
class ClassExamStats with _$ClassExamStats {
  const factory ClassExamStats({
    required String tenantId,
    required String examId,
    required String examName,
    required String examType,
    required String sectionId,
    required String sectionName,
    required String classId,
    required String className,
    required String subjectId,
    required String subjectName,
    required String academicYearId,
    required int totalStudents,
    required int studentsAppeared,
    required double classAverage,
    required double highestPercentage,
    required double lowestPercentage,
    required int passedCount,
    required int failedCount,
    required int absentCount,
    required double passPercentage,
  }) = _ClassExamStats;

  factory ClassExamStats.fromJson(Map<String, dynamic> json) =>
      _$ClassExamStatsFromJson(json);
}

@freezed
class GradeScale with _$GradeScale {
  const factory GradeScale({
    required String id,
    required String tenantId,
    required String name,
    @Default(false) bool isDefault,
    DateTime? createdAt,
    List<GradeScaleItem>? items,
  }) = _GradeScale;

  factory GradeScale.fromJson(Map<String, dynamic> json) =>
      _$GradeScaleFromJson(json);
}

@freezed
class GradeScaleItem with _$GradeScaleItem {
  const factory GradeScaleItem({
    required String id,
    required String gradeScaleId,
    required String grade,
    required double minPercentage,
    required double maxPercentage,
    double? gradePoint,
    String? description,
  }) = _GradeScaleItem;

  factory GradeScaleItem.fromJson(Map<String, dynamic> json) =>
      _$GradeScaleItemFromJson(json);
}

extension ExamHelpers on Exam {
  String get examTypeDisplay {
    switch (examType) {
      case 'unit_test':
        return 'Unit Test';
      case 'mid_term':
        return 'Mid Term';
      case 'final':
        return 'Final';
      case 'assignment':
        return 'Assignment';
      case 'practical':
        return 'Practical';
      case 'project':
        return 'Project';
      default:
        return examType;
    }
  }
}
