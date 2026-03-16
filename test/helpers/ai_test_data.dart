/// Test fixtures for AI features testing.
library ai_test_data;

import 'package:flutter/material.dart';
import 'package:school_management/core/services/ai_text_generator.dart';
import 'package:school_management/data/models/exam_statistics.dart';
import 'package:school_management/data/models/report_commentary.dart';
import 'package:school_management/data/models/student.dart';
import 'package:school_management/data/models/study_recommendation.dart';

import 'test_data.dart';

// ============================================================
// Additional UUIDs for AI tests
// ============================================================

const kStudentUserId1 = 'aaaaaaaa-1111-0000-0000-000000000001';
const kStudentUserId2 = 'aaaaaaaa-1111-0000-0000-000000000002';
const kExamId1 = 'eeeeeeee-1111-0000-0000-000000000001';
const kSubjectId1 = 'ssssssss-1111-0000-0000-000000000001';
const kSubjectId2 = 'ssssssss-1111-0000-0000-000000000002';
const kAcademicYearId = 'yyyyyyyy-1111-0000-0000-000000000001';

// ============================================================
// Student fixture
// ============================================================

Student makeStudent({
  String id = kStudentId1,
  String? userId = kStudentUserId1,
  String firstName = 'Aarav',
  String lastName = 'Sharma',
  bool isActive = true,
}) =>
    Student.fromJson({
      'id': id,
      'tenant_id': kTenantId,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'admission_number': 'ADM-001',
      'is_active': isActive,
      'created_at': kBaseDate.toIso8601String(),
    });

// ============================================================
// StudentPerformance fixture
// ============================================================

StudentPerformance makeStudentPerformance({
  String studentId = kStudentId1,
  String subjectName = 'Mathematics',
  String subjectId = kSubjectId1,
  double marksObtained = 85,
  double maxMarks = 100,
  double passingMarks = 35,
  bool isAbsent = false,
}) =>
    StudentPerformance(
      tenantId: kTenantId,
      studentId: studentId,
      studentName: 'Aarav Sharma',
      admissionNumber: 'ADM-001',
      sectionId: kSectionId,
      sectionName: '10-A',
      classId: 'class-001',
      className: 'Class 10',
      examId: kExamId1,
      examName: 'Mid Term',
      examType: 'mid_term',
      subjectId: subjectId,
      subjectName: subjectName,
      marksObtained: marksObtained,
      maxMarks: maxMarks,
      passingMarks: passingMarks,
      percentage: (marksObtained / maxMarks) * 100,
      isPassed: marksObtained >= passingMarks,
      isAbsent: isAbsent,
      academicYearId: kAcademicYearId,
    );

List<StudentPerformance> makePerformanceList() => [
      makeStudentPerformance(
        subjectName: 'Mathematics',
        subjectId: kSubjectId1,
        marksObtained: 85,
      ),
      makeStudentPerformance(
        subjectName: 'Science',
        subjectId: kSubjectId2,
        marksObtained: 72,
      ),
      makeStudentPerformance(
        subjectName: 'English',
        subjectId: 'sub-003',
        marksObtained: 91,
      ),
    ];

// ============================================================
// Attendance stats fixture
// ============================================================

Map<String, int> makeAttendanceStats({
  int totalDays = 200,
  int presentDays = 180,
  int absentDays = 15,
  int lateDays = 5,
}) =>
    {
      'total_days': totalDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'late_days': lateDays,
      'attendance_percentage':
          totalDays > 0 ? ((presentDays + lateDays) * 100 ~/ totalDays) : 0,
    };

// ============================================================
// AITextResult fixtures
// ============================================================

AITextResult makeLLMResult({String text = 'AI generated insight text.'}) =>
    AITextResult(text: text, isLLMGenerated: true);

AITextResult makeFallbackResult({String text = 'Fallback insight text.'}) =>
    AITextResult(text: text);

// ============================================================
// StudyRecommendation fixture
// ============================================================

StudyRecommendation makeStudyRecommendation({
  String studentId = kStudentUserId1,
  bool isLLMGenerated = false,
}) =>
    StudyRecommendation(
      studentId: studentId,
      recommendations: const [
        RecommendationItem(
          title: 'Focus on Science',
          description: 'Your Science score is below 80%.',
          priority: RecommendationPriority.high,
          icon: Icons.priority_high,
        ),
        RecommendationItem(
          title: 'Great work in English',
          description: 'Keep it up!',
          priority: RecommendationPriority.low,
          icon: Icons.star,
        ),
        RecommendationItem(
          title: 'Practice papers',
          description: 'Solve previous year papers.',
          priority: RecommendationPriority.medium,
          icon: Icons.description,
        ),
      ],
      generatedAt: kBaseDate,
      isLLMGenerated: isLLMGenerated,
    );

// ============================================================
// ReportCommentary fixture
// ============================================================

ReportCommentary makeReportCommentary({
  String studentId = kStudentId1,
  String studentName = 'Aarav Sharma',
  String remark = 'Aarav has shown excellent progress this term.',
  bool isLLMGenerated = false,
}) =>
    ReportCommentary(
      studentId: studentId,
      studentName: studentName,
      remark: remark,
      isLLMGenerated: isLLMGenerated,
    );
