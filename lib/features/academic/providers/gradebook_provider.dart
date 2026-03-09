import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/gradebook.dart';
import '../../../data/repositories/gradebook_repository.dart';

// ─── Repository ────────────────────────────────────────────────────────────

final gradebookRepositoryProvider = Provider<GradebookRepository>((ref) {
  return GradebookRepository(ref.watch(supabaseProvider));
});

// ─── Categories ─────────────────────────────────────────────────────────────

final gradingCategoriesProvider =
    FutureProvider.family<List<GradingCategory>, String>(
  (ref, classSubjectId) async {
    final repo = ref.watch(gradebookRepositoryProvider);
    return repo.getCategories(classSubjectId);
  },
);

// ─── Grade Entries ───────────────────────────────────────────────────────────

final gradeEntriesProvider =
    FutureProvider.family<List<GradeEntry>, GradeEntriesParams>(
  (ref, params) async {
    final repo = ref.watch(gradebookRepositoryProvider);
    return repo.getGradeEntries(params.categoryId, studentId: params.studentId);
  },
);

// ─── Class Grades ────────────────────────────────────────────────────────────

final classGradesProvider =
    FutureProvider.family<List<StudentGrade>, ClassGradesParams>(
  (ref, params) async {
    final repo = ref.watch(gradebookRepositoryProvider);
    return repo.getClassGrades(params.classSubjectId, params.students);
  },
);

// ─── Single Student Grade ─────────────────────────────────────────────────────

final studentGradeProvider =
    FutureProvider.family<StudentGrade, StudentGradeParams>(
  (ref, params) async {
    final repo = ref.watch(gradebookRepositoryProvider);
    return repo.getStudentGrades(
      params.classSubjectId,
      params.studentId,
      params.studentName,
      admissionNumber: params.admissionNumber,
    );
  },
);

// ─── Parameter Objects ────────────────────────────────────────────────────────

class GradeEntriesParams {
  final String categoryId;
  final String? studentId;

  const GradeEntriesParams({required this.categoryId, this.studentId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeEntriesParams &&
          categoryId == other.categoryId &&
          studentId == other.studentId;

  @override
  int get hashCode => Object.hash(categoryId, studentId);
}

class ClassGradesParams {
  final String classSubjectId;
  final List<Map<String, dynamic>> students;

  const ClassGradesParams({
    required this.classSubjectId,
    required this.students,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassGradesParams && classSubjectId == other.classSubjectId;

  @override
  int get hashCode => classSubjectId.hashCode;
}

class StudentGradeParams {
  final String classSubjectId;
  final String studentId;
  final String studentName;
  final String? admissionNumber;

  const StudentGradeParams({
    required this.classSubjectId,
    required this.studentId,
    required this.studentName,
    this.admissionNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentGradeParams &&
          classSubjectId == other.classSubjectId &&
          studentId == other.studentId;

  @override
  int get hashCode => Object.hash(classSubjectId, studentId);
}
