/// Constant test fixtures shared across all test files.
library test_data;

import 'package:school_management/data/models/substitution.dart';
import 'package:school_management/data/models/fee_default_prediction.dart';
import 'package:school_management/data/models/question_paper.dart';

// ============================================================
// UUIDs
// ============================================================

const kTenantId = 'aaaaaaaa-0000-0000-0000-000000000001';
const kTeacherId1 = 'bbbbbbbb-0000-0000-0000-000000000001';
const kTeacherId2 = 'bbbbbbbb-0000-0000-0000-000000000002';
const kAbsenceId = 'cccccccc-0000-0000-0000-000000000001';
const kTimetableId = 'dddddddd-0000-0000-0000-000000000001';
const kSlotId = 'eeeeeeee-0000-0000-0000-000000000001';
const kSectionId = 'ffffffff-0000-0000-0000-000000000001';
const kStudentId1 = '11111111-0000-0000-0000-000000000001';
const kInvoiceId1 = '22222222-0000-0000-0000-000000000001';
const kPaperId1 = '33333333-0000-0000-0000-000000000001';
const kSectionPaperId1 = '44444444-0000-0000-0000-000000000001';

final kBaseDate = DateTime(2026, 2, 24);

// ============================================================
// TeacherAbsence fixture
// ============================================================

TeacherAbsence makeTeacherAbsence({
  String id = kAbsenceId,
  String teacherId = kTeacherId1,
  DateTime? absenceDate,
  AbsenceLeaveType leaveType = AbsenceLeaveType.sick,
  AbsenceStatus status = AbsenceStatus.confirmed,
  String? teacherName = 'Test Teacher',
}) =>
    TeacherAbsence(
      id: id,
      tenantId: kTenantId,
      teacherId: teacherId,
      absenceDate: absenceDate ?? kBaseDate,
      leaveType: leaveType,
      status: status,
      createdAt: kBaseDate,
      teacherName: teacherName,
    );

// ============================================================
// SubstitutionAssignment fixture
// ============================================================

SubstitutionAssignment makeSubstitutionAssignment({
  String id = 'assign-0001',
  String absentTeacherId = kTeacherId1,
  String substituteTeacherId = kTeacherId2,
  String status = 'confirmed',
  int matchScore = 80,
  DateTime? substitutionDate,
}) =>
    SubstitutionAssignment(
      id: id,
      tenantId: kTenantId,
      absenceId: kAbsenceId,
      timetableId: kTimetableId,
      absentTeacherId: absentTeacherId,
      substituteTeacherId: substituteTeacherId,
      slotId: kSlotId,
      sectionId: kSectionId,
      substitutionDate: substitutionDate ?? kBaseDate,
      status: status,
      matchScore: matchScore,
      createdAt: kBaseDate,
      slotName: 'Period 1',
      startTime: '08:00',
      endTime: '08:45',
      sectionName: '10-A',
      className: 'Class 10',
      subjectName: 'Mathematics',
      absentTeacherName: 'Test Teacher',
      substituteTeacherName: 'Sub Teacher',
    );

// ============================================================
// FeeDefaultPrediction fixture
// ============================================================

FeeDefaultPrediction makeHighRiskPrediction({
  String studentId = kStudentId1,
  String invoiceId = kInvoiceId1,
  int riskScore = 85,
  double amountDue = 15000.0,
}) =>
    FeeDefaultPrediction(
      studentId: studentId,
      studentName: 'Rahul Sharma',
      className: 'Class 10-A',
      invoiceId: invoiceId,
      invoiceNumber: 'INV-2026-001',
      amountDue: amountDue,
      dueDate: kBaseDate.subtract(const Duration(days: 5)),
      riskScore: riskScore,
      riskFactors: ['Late payment history', '3 overdue invoices'],
      recommendedAction: 'Send immediate reminder and schedule meeting',
    );

FeeDefaultPrediction makeMediumRiskPrediction({
  String studentId = '11111111-0000-0000-0000-000000000002',
  String invoiceId = '22222222-0000-0000-0000-000000000002',
}) =>
    FeeDefaultPrediction(
      studentId: studentId,
      studentName: 'Priya Patel',
      className: 'Class 9-B',
      invoiceId: invoiceId,
      invoiceNumber: 'INV-2026-002',
      amountDue: 8500.0,
      dueDate: kBaseDate.add(const Duration(days: 3)),
      riskScore: 55,
      riskFactors: ['Payment delayed twice'],
      recommendedAction: 'Send friendly reminder',
    );

// ============================================================
// QuestionPaper fixture
// ============================================================

QuestionPaper makeQuestionPaper({
  String id = kPaperId1,
  String title = 'Mathematics Unit Test',
  PaperStatus status = PaperStatus.draft,
  bool isAiGenerated = false,
}) =>
    QuestionPaper(
      id: id,
      tenantId: kTenantId,
      title: title,
      examType: 'unit_test',
      difficulty: DifficultyLevel.medium,
      totalMarks: 50,
      durationMinutes: 60,
      isAiGenerated: isAiGenerated,
      status: status,
      createdAt: kBaseDate,
      updatedAt: kBaseDate,
      subjectName: 'Mathematics',
      className: 'Class 10',
      sections: [],
    );

QuestionPaperConfig makeQuestionPaperConfig() => const QuestionPaperConfig(
      subjectName: 'Mathematics',
      className: 'Class 10',
      examType: 'unit_test',
      totalMarks: 50,
      durationMinutes: 60,
      difficulty: DifficultyLevel.medium,
      topics: ['Algebra', 'Geometry'],
    );
