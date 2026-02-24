/// Fake repository implementations used in provider and widget tests.
/// Each class extends the real repository but overrides every async method
/// to return in-memory test fixtures without touching Supabase.
library fake_repositories;

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:school_management/data/models/substitution.dart';
import 'package:school_management/data/models/fee_default_prediction.dart';
import 'package:school_management/data/models/question_paper.dart';
import 'package:school_management/data/repositories/substitution_repository.dart';
import 'package:school_management/data/repositories/fee_repository.dart';
import 'package:school_management/data/repositories/question_paper_repository.dart';

import 'test_data.dart';

// ============================================================
// Mock SupabaseClient — never actually called in unit tests
// ============================================================

class MockSupabaseClient extends Mock implements SupabaseClient {}

// ============================================================
// FakeSubstitutionRepository
// ============================================================

class FakeSubstitutionRepository extends SubstitutionRepository {
  FakeSubstitutionRepository() : super(MockSupabaseClient());

  @override
  Future<List<TeacherAbsence>> getMyAbsences(String teacherId,
      {int limit = 20}) async {
    return [makeTeacherAbsence(teacherId: teacherId)];
  }

  @override
  Future<List<TeacherAbsence>> getAbsencesByDate(DateTime date) async {
    return [makeTeacherAbsence()];
  }

  @override
  Future<TeacherAbsence> reportAbsence({
    required String teacherId,
    required DateTime date,
    required AbsenceLeaveType leaveType,
    String? reason,
    String? notes,
  }) async {
    return makeTeacherAbsence(teacherId: teacherId, absenceDate: date);
  }

  @override
  Future<void> updateAbsenceStatus(
      String absenceId, AbsenceStatus status) async {}

  @override
  Future<List<SubstitutePeriod>> getSuggestedSubstitutes({
    required String absentTeacherId,
    required DateTime date,
  }) async {
    return [];
  }

  @override
  Future<SubstitutionAssignment> assignSubstitute({
    required String absenceId,
    required String timetableId,
    required String absentTeacherId,
    required String substituteTeacherId,
    required String slotId,
    required String sectionId,
    String? subjectId,
    required DateTime date,
    int matchScore = 0,
    String? notes,
  }) async {
    return makeSubstitutionAssignment(
      absentTeacherId: absentTeacherId,
      substituteTeacherId: substituteTeacherId,
      substitutionDate: date,
    );
  }

  @override
  Future<List<SubstitutionAssignment>> getAssignmentsByDate(
      DateTime date) async {
    return [makeSubstitutionAssignment(substitutionDate: date)];
  }

  @override
  Future<List<SubstitutionAssignment>> getMySubstituteDuties(
      String teacherId,
      {int limit = 20}) async {
    return [makeSubstitutionAssignment()];
  }

  @override
  Future<void> cancelAssignment(String assignmentId) async {}
}

// ============================================================
// FakeFeeRepository — only overrides the predictions method
// ============================================================

class FakeFeeRepository extends FeeRepository {
  final List<FeeDefaultPrediction> predictions;

  FakeFeeRepository({List<FeeDefaultPrediction>? predictions})
      : predictions = predictions ??
            [
              makeHighRiskPrediction(),
              makeMediumRiskPrediction(),
            ],
        super(MockSupabaseClient());

  @override
  Future<List<FeeDefaultPrediction>> getFeeDefaultPredictions() async {
    return predictions;
  }
}

// ============================================================
// FakeQuestionPaperRepository
// ============================================================

class FakeQuestionPaperRepository extends QuestionPaperRepository {
  final List<QuestionPaper> papers;

  FakeQuestionPaperRepository({List<QuestionPaper>? papers})
      : papers = papers ?? [makeQuestionPaper()],
        super(MockSupabaseClient());

  @override
  Future<List<QuestionPaper>> getQuestionPapers({
    String? subjectId,
    String? classId,
    PaperStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var result = papers;
    if (status != null) {
      result = result.where((p) => p.status == status).toList();
    }
    if (classId != null) {
      result = result.where((p) => p.classId == classId).toList();
    }
    return result;
  }

  @override
  Future<QuestionPaper> getQuestionPaper(String paperId) async {
    return papers.firstWhere(
      (p) => p.id == paperId,
      orElse: () => makeQuestionPaper(id: paperId),
    );
  }

  @override
  Future<QuestionPaper> createQuestionPaper({
    required Map<String, dynamic> paperData,
    required List<Map<String, dynamic>> sectionsWithItems,
  }) async {
    return makeQuestionPaper(
      title: paperData['title'] as String? ?? 'New Paper',
    );
  }
}
