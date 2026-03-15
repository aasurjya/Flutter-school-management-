import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(supabaseProvider));
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
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
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

// ─── Paginated Students (for infinite scroll) ────────────────────────────────

class PaginatedStudentsState {
  final List<Student> students;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? searchQuery;
  final String? filterClassId;
  final String? filterSectionId;

  const PaginatedStudentsState({
    this.students = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.searchQuery,
    this.filterClassId,
    this.filterSectionId,
  });

  PaginatedStudentsState copyWith({
    List<Student>? students,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? searchQuery,
    String? filterClassId,
    String? filterSectionId,
  }) =>
      PaginatedStudentsState(
        students: students ?? this.students,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
        filterClassId: filterClassId ?? this.filterClassId,
        filterSectionId: filterSectionId ?? this.filterSectionId,
      );
}

class PaginatedStudentsNotifier
    extends StateNotifier<PaginatedStudentsState> {
  final StudentRepository _repo;
  int _offset = 0;
  static const _pageSize = 25;

  PaginatedStudentsNotifier(this._repo)
      : super(const PaginatedStudentsState());

  Future<void> loadInitial({
    String? searchQuery,
    String? classId,
    String? sectionId,
  }) async {
    _offset = 0;
    state = PaginatedStudentsState(
      isLoading: true,
      searchQuery: searchQuery,
      filterClassId: classId,
      filterSectionId: sectionId,
    );
    try {
      final results = await _repo.getStudents(
        limit: _pageSize,
        offset: 0,
        searchQuery: searchQuery,
        classId: classId,
        sectionId: sectionId,
      );
      state = state.copyWith(
        students: results,
        isLoading: false,
        hasMore: results.length == _pageSize,
      );
      _offset = results.length;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final results = await _repo.getStudents(
        limit: _pageSize,
        offset: _offset,
        searchQuery: state.searchQuery,
        classId: state.filterClassId,
        sectionId: state.filterSectionId,
      );
      state = state.copyWith(
        students: [...state.students, ...results],
        isLoadingMore: false,
        hasMore: results.length == _pageSize,
      );
      _offset += results.length;
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void addStudent(Student student) {
    state = state.copyWith(students: [student, ...state.students]);
  }
}

final paginatedStudentsProvider =
    StateNotifierProvider<PaginatedStudentsNotifier, PaginatedStudentsState>(
  (ref) {
    final repo = ref.watch(studentRepositoryProvider);
    return PaginatedStudentsNotifier(repo);
  },
);
