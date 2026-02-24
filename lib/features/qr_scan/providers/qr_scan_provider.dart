import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/student.dart';
import '../../../data/models/student_checkin.dart';
import '../../../data/repositories/checkin_repository.dart';
import '../../students/providers/students_provider.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  return CheckinRepository(ref.watch(supabaseProvider));
});

/// Holds the last scanned student (set imperatively from the scanner screen).
final scannedStudentProvider = StateProvider<Student?>((ref) => null);

/// Look up a student by admission number.
final studentFromAdmissionNumberProvider =
    FutureProvider.family<Student?, String>((ref, admissionNumber) async {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudentByAdmissionNumber(admissionNumber);
});

/// Get check-in log for a student.
final studentCheckinsProvider =
    FutureProvider.family<List<StudentCheckin>, String>(
        (ref, studentId) async {
  final repository = ref.watch(checkinRepositoryProvider);
  return repository.getStudentCheckins(
    studentId: studentId,
    date: DateTime.now(),
  );
});

/// Get check-in log for a section today.
final sectionCheckinsProvider =
    FutureProvider.family<List<StudentCheckin>, String>(
        (ref, sectionId) async {
  final repository = ref.watch(checkinRepositoryProvider);
  return repository.getSectionCheckins(
    sectionId: sectionId,
    date: DateTime.now(),
  );
});
