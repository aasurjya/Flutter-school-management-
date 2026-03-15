import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

import '../../../data/models/academic.dart';
import '../../../data/repositories/academic_repository.dart';

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  return AcademicRepository(ref.watch(supabaseProvider));
});

final classesProvider = FutureProvider<List<SchoolClass>>((ref) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getClasses();
});

final sectionsByClassProvider = FutureProvider.family<List<Section>, String>((ref, classId) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getSections(classId: classId);
});

final allSectionsProvider = FutureProvider<List<Section>>((ref) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getSections();
});

final academicYearsProvider = FutureProvider<List<AcademicYear>>((ref) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getAcademicYears();
});

final currentAcademicYearProvider = FutureProvider<AcademicYear?>((ref) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getCurrentAcademicYear();
});

final termsProvider = FutureProvider.family<List<Term>, String>((ref, academicYearId) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getTerms(academicYearId);
});

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getSubjects();
});

final classTeacherSectionsProvider =
    FutureProvider.family<List<Section>, String>((ref, teacherId) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getClassTeacherSections(teacherId);
});

final teachersListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getTeachersList();
});
