import '../models/gradebook.dart';
import 'base_repository.dart';

class GradebookRepository extends BaseRepository {
  GradebookRepository(super.client);

  // ─── Categories ────────────────────────────────────────────────────────────

  Future<List<GradingCategory>> getCategories(String classSubjectId) async {
    final response = await client
        .from('grading_categories')
        .select()
        .eq('tenant_id', requireTenantId)
        .eq('class_subject_id', classSubjectId)
        .order('created_at');

    return (response as List)
        .map((json) => GradingCategory.fromJson(json))
        .toList();
  }

  Future<GradingCategory> addCategory(GradingCategory category) async {
    final response = await client
        .from('grading_categories')
        .insert(category.toJson())
        .select()
        .single();

    return GradingCategory.fromJson(response);
  }

  Future<void> deleteCategory(String categoryId) async {
    await client
        .from('grading_categories')
        .delete()
        .eq('id', categoryId)
        .eq('tenant_id', requireTenantId);
  }

  // ─── Grade Entries ──────────────────────────────────────────────────────────

  Future<List<GradeEntry>> getGradeEntries(
    String categoryId, {
    String? studentId,
  }) async {
    var query = client
        .from('grade_entries')
        .select()
        .eq('tenant_id', requireTenantId)
        .eq('category_id', categoryId);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    final response = await query.order('graded_at', ascending: false);

    return (response as List)
        .map((json) => GradeEntry.fromJson(json))
        .toList();
  }

  /// Load all grade entries for all categories of a subject at once.
  Future<List<GradeEntry>> getAllEntriesForSubject(
    List<String> categoryIds,
  ) async {
    if (categoryIds.isEmpty) return [];

    final response = await client
        .from('grade_entries')
        .select()
        .eq('tenant_id', requireTenantId)
        .inFilter('category_id', categoryIds)
        .order('graded_at', ascending: false);

    return (response as List)
        .map((json) => GradeEntry.fromJson(json))
        .toList();
  }

  Future<GradeEntry> addGradeEntry(GradeEntry entry) async {
    final response = await client
        .from('grade_entries')
        .insert(entry.toJson())
        .select()
        .single();

    return GradeEntry.fromJson(response);
  }

  Future<GradeEntry> updateGradeEntry(
    String id, {
    double? pointsEarned,
    String? notes,
  }) async {
    final updates = <String, dynamic>{};
    if (pointsEarned != null) updates['points_earned'] = pointsEarned;
    if (notes != null) updates['notes'] = notes;

    if (updates.isEmpty) {
      throw ArgumentError('No fields to update');
    }

    final response = await client
        .from('grade_entries')
        .update(updates)
        .eq('id', id)
        .eq('tenant_id', requireTenantId)
        .select()
        .single();

    return GradeEntry.fromJson(response);
  }

  Future<void> deleteGradeEntry(String id) async {
    await client
        .from('grade_entries')
        .delete()
        .eq('id', id)
        .eq('tenant_id', requireTenantId);
  }

  // ─── Aggregated Grade Views ─────────────────────────────────────────────────

  /// Compute [StudentGrade] for a single student.
  Future<StudentGrade> getStudentGrades(
    String classSubjectId,
    String studentId,
    String studentName, {
    String? admissionNumber,
  }) async {
    final categories = await getCategories(classSubjectId);
    if (categories.isEmpty) {
      return StudentGrade(
        studentId: studentId,
        studentName: studentName,
        admissionNumber: admissionNumber,
        categoryPercentages: {},
        weightedAverage: 0,
      );
    }

    final categoryIds = categories.map((c) => c.id).toList();
    final entries = await getAllEntriesForSubject(categoryIds);

    final populatedCategories = categories.map((cat) {
      final catEntries =
          entries.where((e) => e.categoryId == cat.id).toList();
      return cat.copyWith(entries: catEntries);
    }).toList();

    return StudentGrade.calculate(
      studentId,
      studentName,
      populatedCategories,
      admissionNumber: admissionNumber,
    );
  }

  /// Compute [StudentGrade] for every enrolled student in a class-subject.
  ///
  /// [students] is a list of maps with keys: id, full_name, admission_number.
  Future<List<StudentGrade>> getClassGrades(
    String classSubjectId,
    List<Map<String, dynamic>> students,
  ) async {
    final categories = await getCategories(classSubjectId);
    if (categories.isEmpty || students.isEmpty) {
      return students
          .map((s) => StudentGrade(
                studentId: s['id'] as String,
                studentName: s['full_name'] as String? ?? 'Unknown',
                admissionNumber: s['admission_number'] as String?,
                categoryPercentages: {},
                weightedAverage: 0,
              ))
          .toList();
    }

    final categoryIds = categories.map((c) => c.id).toList();
    final entries = await getAllEntriesForSubject(categoryIds);

    final populatedCategories = categories.map((cat) {
      final catEntries =
          entries.where((e) => e.categoryId == cat.id).toList();
      return cat.copyWith(entries: catEntries);
    }).toList();

    return students.map((student) {
      final id = student['id'] as String;
      final name = student['full_name'] as String? ?? 'Unknown';
      final admNo = student['admission_number'] as String?;
      return StudentGrade.calculate(
        id,
        name,
        populatedCategories,
        admissionNumber: admNo,
      );
    }).toList();
  }
}
