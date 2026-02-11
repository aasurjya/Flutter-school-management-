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

final academicYearsProvider = FutureProvider<List<AcademicYear>>((ref) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getAcademicYears();
});

final currentAcademicYearProvider = FutureProvider<AcademicYear?>((ref) async {
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getCurrentAcademicYear();
});
