import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/lms.dart';
import '../../../data/repositories/lms_repository.dart';

/// Repository provider
final lmsRepositoryProvider = Provider<LmsRepository>((ref) {
  return LmsRepository(ref.watch(supabaseProvider));
});

// ============================================
// COURSE PROVIDERS
// ============================================

final lmsCoursesProvider =
    FutureProvider.family<List<Course>, CourseFilter>((ref, filter) async {
  final repository = ref.watch(lmsRepositoryProvider);
  return repository.getCourses(
    status: filter.status,
    teacherId: filter.teacherId,
    classId: filter.classId,
    subjectId: filter.subjectId,
    searchQuery: filter.searchQuery,
    limit: filter.limit,
    offset: filter.offset,
  );
});

final allCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(lmsRepositoryProvider);
  return repository.getCourses();
});

final publishedCoursesProvider =
    FutureProvider.family<List<Course>, CatalogFilter>((ref, filter) async {
  final repository = ref.watch(lmsRepositoryProvider);
  return repository.getPublishedCourses(
    classId: filter.classId,
    subjectId: filter.subjectId,
    searchQuery: filter.searchQuery,
    limit: filter.limit,
    offset: filter.offset,
  );
});

final courseByIdProvider =
    FutureProvider.family<Course?, String>((ref, courseId) async {
  final repository = ref.watch(lmsRepositoryProvider);
  return repository.getCourseById(courseId);
});

// ============================================
// ENROLLMENT PROVIDERS
// ============================================

final myEnrollmentsProvider =
    FutureProvider.family<List<CourseEnrollment>, EnrollmentFilter>(
  (ref, filter) async {
    final repository = ref.watch(lmsRepositoryProvider);
    return repository.getEnrollments(
      studentId: filter.studentId,
      status: filter.status,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final allMyEnrollmentsProvider =
    FutureProvider<List<CourseEnrollment>>((ref) async {
  final repository = ref.watch(lmsRepositoryProvider);
  final userId = repository.currentUserId;
  return repository.getEnrollments(studentId: userId);
});

final courseEnrollmentProvider =
    FutureProvider.family<CourseEnrollment?, String>((ref, courseId) async {
  final repository = ref.watch(lmsRepositoryProvider);
  return repository.getMyEnrollment(courseId);
});

final courseEnrollmentsListProvider =
    FutureProvider.family<List<CourseEnrollment>, String>(
  (ref, courseId) async {
    final repository = ref.watch(lmsRepositoryProvider);
    return repository.getEnrollments(courseId: courseId);
  },
);

// ============================================
// CONTENT PROGRESS PROVIDERS
// ============================================

final contentProgressProvider =
    FutureProvider.family<List<ContentProgress>, String>(
  (ref, enrollmentId) async {
    final repository = ref.watch(lmsRepositoryProvider);
    return repository.getContentProgress(enrollmentId);
  },
);

// ============================================
// MODULE PROVIDERS
// ============================================

final courseModulesProvider =
    FutureProvider.family<List<CourseModule>, String>((ref, courseId) async {
  final repository = ref.watch(lmsRepositoryProvider);
  return repository.getModules(courseId);
});

// ============================================
// FORUM PROVIDERS
// ============================================

final courseForumsProvider =
    FutureProvider.family<List<DiscussionForum>, String>(
  (ref, courseId) async {
    final repository = ref.watch(lmsRepositoryProvider);
    return repository.getForums(courseId);
  },
);

final forumPostsProvider =
    FutureProvider.family<List<ForumPost>, String>((ref, forumId) async {
  final repository = ref.watch(lmsRepositoryProvider);
  return repository.getForumPosts(forumId);
});

// ============================================
// CERTIFICATE PROVIDERS
// ============================================

final certificateProvider =
    FutureProvider.family<CourseCertificate?, String>(
  (ref, enrollmentId) async {
    final repository = ref.watch(lmsRepositoryProvider);
    return repository.getCertificate(enrollmentId);
  },
);

final myCertificatesProvider =
    FutureProvider<List<CourseCertificate>>((ref) async {
  final repository = ref.watch(lmsRepositoryProvider);
  return repository.getMyCertificates();
});

// ============================================
// STATS PROVIDER
// ============================================

final lmsStatsProvider = FutureProvider<LmsStats>((ref) async {
  final repository = ref.watch(lmsRepositoryProvider);
  return repository.getStats();
});

// ============================================
// STATE NOTIFIERS
// ============================================

class CourseNotifier extends StateNotifier<AsyncValue<List<Course>>> {
  final LmsRepository _repository;

  CourseNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadCourses({
    String? status,
    String? teacherId,
    String? searchQuery,
  }) async {
    state = const AsyncValue.loading();
    try {
      final courses = await _repository.getCourses(
        status: status,
        teacherId: teacherId,
        searchQuery: searchQuery,
      );
      state = AsyncValue.data(courses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Course> createCourse(Map<String, dynamic> data) async {
    final course = await _repository.createCourse(data);
    await loadCourses();
    return course;
  }

  Future<Course> updateCourse(String courseId, Map<String, dynamic> data) async {
    final course = await _repository.updateCourse(courseId, data);
    await loadCourses();
    return course;
  }

  Future<void> deleteCourse(String courseId) async {
    await _repository.deleteCourse(courseId);
    await loadCourses();
  }
}

final courseNotifierProvider =
    StateNotifierProvider<CourseNotifier, AsyncValue<List<Course>>>((ref) {
  final repository = ref.watch(lmsRepositoryProvider);
  return CourseNotifier(repository);
});

class EnrollmentNotifier
    extends StateNotifier<AsyncValue<List<CourseEnrollment>>> {
  final LmsRepository _repository;

  EnrollmentNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadEnrollments({String? studentId, String? status}) async {
    state = const AsyncValue.loading();
    try {
      final enrollments = await _repository.getEnrollments(
        studentId: studentId,
        status: status,
      );
      state = AsyncValue.data(enrollments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<CourseEnrollment> enroll(String courseId) async {
    final enrollment = await _repository.enrollInCourse(courseId);
    await loadEnrollments(studentId: _repository.currentUserId);
    return enrollment;
  }

  Future<void> drop(String enrollmentId) async {
    await _repository.dropCourse(enrollmentId);
    await loadEnrollments(studentId: _repository.currentUserId);
  }
}

final enrollmentNotifierProvider = StateNotifierProvider<EnrollmentNotifier,
    AsyncValue<List<CourseEnrollment>>>((ref) {
  final repository = ref.watch(lmsRepositoryProvider);
  return EnrollmentNotifier(repository);
});

// ============================================
// FILTER CLASSES
// ============================================

class CourseFilter {
  final String? status;
  final String? teacherId;
  final String? classId;
  final String? subjectId;
  final String? searchQuery;
  final int limit;
  final int offset;

  const CourseFilter({
    this.status,
    this.teacherId,
    this.classId,
    this.subjectId,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseFilter &&
          other.status == status &&
          other.teacherId == teacherId &&
          other.classId == classId &&
          other.subjectId == subjectId &&
          other.searchQuery == searchQuery &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode =>
      Object.hash(status, teacherId, classId, subjectId, searchQuery, limit, offset);
}

class CatalogFilter {
  final String? classId;
  final String? subjectId;
  final String? searchQuery;
  final int limit;
  final int offset;

  const CatalogFilter({
    this.classId,
    this.subjectId,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogFilter &&
          other.classId == classId &&
          other.subjectId == subjectId &&
          other.searchQuery == searchQuery &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode =>
      Object.hash(classId, subjectId, searchQuery, limit, offset);
}

class EnrollmentFilter {
  final String? studentId;
  final String? courseId;
  final String? status;
  final int limit;
  final int offset;

  const EnrollmentFilter({
    this.studentId,
    this.courseId,
    this.status,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnrollmentFilter &&
          other.studentId == studentId &&
          other.courseId == courseId &&
          other.status == status &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode =>
      Object.hash(studentId, courseId, status, limit, offset);
}
