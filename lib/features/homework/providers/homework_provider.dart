import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/homework.dart';
import '../../../data/repositories/homework_repository.dart';

// ============================================================
// Repository Provider
// ============================================================

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  return HomeworkRepository(ref.watch(supabaseProvider));
});

// ============================================================
// Dashboard Stats
// ============================================================

final homeworkDashboardStatsProvider =
    FutureProvider.family<HomeworkDashboardStats, String?>(
  (ref, sectionId) async {
    final repo = ref.watch(homeworkRepositoryProvider);
    return repo.getDashboardStats(sectionId: sectionId);
  },
);

// ============================================================
// Homework List
// ============================================================

final homeworkListProvider =
    FutureProvider.family<List<Homework>, HomeworkListFilter>(
  (ref, filter) async {
    final repo = ref.watch(homeworkRepositoryProvider);
    return repo.getHomeworkList(
      sectionId: filter.sectionId,
      subjectId: filter.subjectId,
      status: filter.status,
      assignedBy: filter.assignedBy,
    );
  },
);

final homeworkByIdProvider = FutureProvider.family<Homework?, String>(
  (ref, id) async {
    final repo = ref.watch(homeworkRepositoryProvider);
    return repo.getHomeworkById(id);
  },
);

// ============================================================
// Student Homework
// ============================================================

final studentHomeworkProvider =
    FutureProvider.family<List<Homework>, String>(
  (ref, studentId) async {
    final repo = ref.watch(homeworkRepositoryProvider);
    return repo.getStudentHomework(studentId: studentId);
  },
);

// ============================================================
// Submissions
// ============================================================

final homeworkSubmissionsProvider =
    FutureProvider.family<List<HomeworkSubmission>, String>(
  (ref, homeworkId) async {
    final repo = ref.watch(homeworkRepositoryProvider);
    return repo.getSubmissions(homeworkId);
  },
);

final studentSubmissionProvider =
    FutureProvider.family<HomeworkSubmission?, StudentSubmissionParams>(
  (ref, params) async {
    final repo = ref.watch(homeworkRepositoryProvider);
    return repo.getStudentSubmission(params.homeworkId, params.studentId);
  },
);

// ============================================================
// Homework Notifier (CRUD)
// ============================================================

class HomeworkNotifier extends StateNotifier<AsyncValue<List<Homework>>> {
  final HomeworkRepository _repository;

  HomeworkNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> load({
    String? sectionId,
    String? subjectId,
    HomeworkStatus? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getHomeworkList(
        sectionId: sectionId,
        subjectId: subjectId,
        status: status,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Homework> create(Map<String, dynamic> data) async {
    final hw = await _repository.createHomework(data);
    await load();
    return hw;
  }

  Future<Homework> update(String id, Map<String, dynamic> data) async {
    final hw = await _repository.updateHomework(id, data);
    await load();
    return hw;
  }

  Future<void> delete(String id) async {
    await _repository.deleteHomework(id);
    await load();
  }

  Future<Homework> publish(String id) async {
    final hw = await _repository.publishHomework(id);
    await load();
    return hw;
  }

  Future<Homework> close(String id) async {
    final hw = await _repository.closeHomework(id);
    await load();
    return hw;
  }
}

final homeworkNotifierProvider =
    StateNotifierProvider<HomeworkNotifier, AsyncValue<List<Homework>>>((ref) {
  final repo = ref.watch(homeworkRepositoryProvider);
  return HomeworkNotifier(repo);
});

// ============================================================
// Submissions Notifier
// ============================================================

class SubmissionsNotifier
    extends StateNotifier<AsyncValue<List<HomeworkSubmission>>> {
  final HomeworkRepository _repository;
  final String homeworkId;

  SubmissionsNotifier(this._repository, this.homeworkId)
      : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getSubmissions(homeworkId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<HomeworkSubmission> grade({
    required String submissionId,
    required int marks,
    String? feedback,
  }) async {
    final sub = await _repository.gradeSubmission(
      submissionId: submissionId,
      marks: marks,
      feedback: feedback,
    );
    await load();
    return sub;
  }

  Future<HomeworkSubmission> returnSubmission({
    required String submissionId,
    String? feedback,
  }) async {
    final sub = await _repository.returnSubmission(
      submissionId: submissionId,
      feedback: feedback,
    );
    await load();
    return sub;
  }
}

final submissionsNotifierProvider = StateNotifierProvider.family<
    SubmissionsNotifier, AsyncValue<List<HomeworkSubmission>>, String>(
  (ref, homeworkId) {
    final repo = ref.watch(homeworkRepositoryProvider);
    return SubmissionsNotifier(repo, homeworkId);
  },
);

// ============================================================
// Filter classes & Params
// ============================================================

class HomeworkListFilter {
  final String? sectionId;
  final String? subjectId;
  final HomeworkStatus? status;
  final String? assignedBy;

  const HomeworkListFilter({
    this.sectionId,
    this.subjectId,
    this.status,
    this.assignedBy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkListFilter &&
          other.sectionId == sectionId &&
          other.subjectId == subjectId &&
          other.status == status &&
          other.assignedBy == assignedBy;

  @override
  int get hashCode => Object.hash(sectionId, subjectId, status, assignedBy);
}

class StudentSubmissionParams {
  final String homeworkId;
  final String studentId;

  const StudentSubmissionParams({
    required this.homeworkId,
    required this.studentId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentSubmissionParams &&
          other.homeworkId == homeworkId &&
          other.studentId == studentId;

  @override
  int get hashCode => Object.hash(homeworkId, studentId);
}

// ============================================================
// Selected filter state
// ============================================================

final selectedHomeworkSectionProvider = StateProvider<String?>((ref) => null);
final selectedHomeworkSubjectProvider = StateProvider<String?>((ref) => null);
final selectedHomeworkStatusProvider = StateProvider<HomeworkStatus?>((ref) => null);
