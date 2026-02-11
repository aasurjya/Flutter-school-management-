import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/student_insights.dart';
import '../../../data/repositories/insights_repository.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(ref.watch(supabaseProvider));
});

/// Provider for student insights
final studentInsightsProvider = FutureProvider.family<StudentInsights, String>(
  (ref, studentId) async {
    final repository = ref.watch(insightsRepositoryProvider);
    return repository.getStudentInsights(studentId);
  },
);

/// Provider for monthly attendance data
final monthlyAttendanceProvider =
    FutureProvider.family<List<MonthlyAttendanceSummary>, MonthlyAttendanceFilter>(
  (ref, filter) async {
    final repository = ref.watch(insightsRepositoryProvider);
    return repository.getMonthlyAttendance(
      filter.studentId,
      year: filter.year,
    );
  },
);

/// Provider for subject comparison data
final subjectComparisonProvider =
    FutureProvider.family<List<SubjectComparison>, SubjectComparisonFilter>(
  (ref, filter) async {
    final repository = ref.watch(insightsRepositoryProvider);
    return repository.getSubjectComparison(
      filter.studentId,
      filter.sectionId,
    );
  },
);

/// Provider for parent's children list
final parentChildrenProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, parentId) async {
    final repository = ref.watch(insightsRepositoryProvider);
    return repository.getParentChildren(parentId);
  },
);

/// Filter classes
class MonthlyAttendanceFilter {
  final String studentId;
  final int? year;

  const MonthlyAttendanceFilter({
    required this.studentId,
    this.year,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyAttendanceFilter &&
          other.studentId == studentId &&
          other.year == year;

  @override
  int get hashCode => Object.hash(studentId, year);
}

class SubjectComparisonFilter {
  final String studentId;
  final String sectionId;

  const SubjectComparisonFilter({
    required this.studentId,
    required this.sectionId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectComparisonFilter &&
          other.studentId == studentId &&
          other.sectionId == sectionId;

  @override
  int get hashCode => Object.hash(studentId, sectionId);
}

/// Selected child provider for parents with multiple children
final selectedChildProvider = StateProvider<String?>((ref) => null);
