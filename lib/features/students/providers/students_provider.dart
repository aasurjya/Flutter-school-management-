import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(Supabase.instance.client);
});

final studentsProvider = FutureProvider.family<List<Student>, StudentsFilter>(
  (ref, filter) async {
    final repository = ref.watch(studentRepositoryProvider);
    return repository.getStudents(
      sectionId: filter.sectionId,
      classId: filter.classId,
      searchQuery: filter.searchQuery,
      activeOnly: filter.activeOnly,
    );
  },
);

final studentByIdProvider = FutureProvider.family<Student?, String>(
  (ref, studentId) async {
    final repository = ref.watch(studentRepositoryProvider);
    return repository.getStudentById(studentId);
  },
);

final studentsBySectionProvider = FutureProvider.family<List<Student>, String>(
  (ref, sectionId) async {
    final repository = ref.watch(studentRepositoryProvider);
    return repository.getStudentsBySection(sectionId);
  },
);

final parentChildrenProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final repository = ref.watch(studentRepositoryProvider);
    return repository.getParentChildren(userId);
  },
);

final currentStudentProvider = FutureProvider<Student?>((ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  return repository.getStudentByUserId(userId);
});

final studentCountProvider = FutureProvider.family<int, String?>(
  (ref, sectionId) async {
    final repository = ref.watch(studentRepositoryProvider);
    return repository.getStudentCount(sectionId: sectionId);
  },
);

class StudentsFilter {
  final String? sectionId;
  final String? classId;
  final String? searchQuery;
  final bool activeOnly;

  const StudentsFilter({
    this.sectionId,
    this.classId,
    this.searchQuery,
    this.activeOnly = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentsFilter &&
        other.sectionId == sectionId &&
        other.classId == classId &&
        other.searchQuery == searchQuery &&
        other.activeOnly == activeOnly;
  }

  @override
  int get hashCode {
    return Object.hash(sectionId, classId, searchQuery, activeOnly);
  }
}

class StudentsNotifier extends StateNotifier<AsyncValue<List<Student>>> {
  final StudentRepository _repository;

  StudentsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadStudents({
    String? sectionId,
    String? classId,
    String? searchQuery,
    bool activeOnly = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final students = await _repository.getStudents(
        sectionId: sectionId,
        classId: classId,
        searchQuery: searchQuery,
        activeOnly: activeOnly,
      );
      state = AsyncValue.data(students);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Student> createStudent(Map<String, dynamic> data) async {
    final student = await _repository.createStudent(data);
    await loadStudents();
    return student;
  }

  Future<Student> updateStudent(String studentId, Map<String, dynamic> data) async {
    final student = await _repository.updateStudent(studentId, data);
    await loadStudents();
    return student;
  }

  Future<void> enrollStudent({
    required String studentId,
    required String sectionId,
    required String academicYearId,
    String? rollNumber,
  }) async {
    await _repository.enrollStudent(
      studentId: studentId,
      sectionId: sectionId,
      academicYearId: academicYearId,
      rollNumber: rollNumber,
    );
    await loadStudents();
  }

  Future<void> changeSection({
    required String studentId,
    required String newSectionId,
    required String academicYearId,
  }) async {
    await _repository.changeSection(
      studentId: studentId,
      newSectionId: newSectionId,
      academicYearId: academicYearId,
    );
    await loadStudents();
  }

  Future<void> deactivateStudent(String studentId) async {
    await _repository.deactivateStudent(studentId);
    await loadStudents();
  }
}

final studentsNotifierProvider =
    StateNotifierProvider<StudentsNotifier, AsyncValue<List<Student>>>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return StudentsNotifier(repository);
});

final selectedChildProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
