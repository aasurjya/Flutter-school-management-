import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/assignment.dart';
import '../../../data/repositories/assignment_repository.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(ref.watch(supabaseProvider));
});

final assignmentsProvider = FutureProvider.family<List<Assignment>, AssignmentsFilter>(
  (ref, filter) async {
    final repository = ref.watch(assignmentRepositoryProvider);
    return repository.getAssignments(
      sectionId: filter.sectionId,
      subjectId: filter.subjectId,
      teacherId: filter.teacherId,
      status: filter.status,
      upcomingOnly: filter.upcomingOnly,
    );
  },
);

final studentAssignmentsProvider = FutureProvider.family<List<Assignment>, StudentAssignmentsFilter>(
  (ref, filter) async {
    final repository = ref.watch(assignmentRepositoryProvider);
    return repository.getStudentAssignments(
      sectionId: filter.sectionId,
      pendingOnly: filter.pendingOnly,
    );
  },
);

final assignmentByIdProvider = FutureProvider.family<Assignment?, String>(
  (ref, assignmentId) async {
    final repository = ref.watch(assignmentRepositoryProvider);
    return repository.getAssignmentById(assignmentId);
  },
);

final submissionsProvider = FutureProvider.family<List<Submission>, SubmissionsFilter>(
  (ref, filter) async {
    final repository = ref.watch(assignmentRepositoryProvider);
    return repository.getSubmissions(
      assignmentId: filter.assignmentId,
      status: filter.status,
    );
  },
);

final studentSubmissionProvider = FutureProvider.family<Submission?, StudentSubmissionFilter>(
  (ref, filter) async {
    final repository = ref.watch(assignmentRepositoryProvider);
    return repository.getStudentSubmission(
      assignmentId: filter.assignmentId,
      studentId: filter.studentId,
    );
  },
);

final assignmentSummariesProvider = FutureProvider.family<List<AssignmentSummary>, AssignmentSummaryFilter>(
  (ref, filter) async {
    final repository = ref.watch(assignmentRepositoryProvider);
    return repository.getAssignmentSummaries(
      sectionId: filter.sectionId,
      teacherId: filter.teacherId,
    );
  },
);

class AssignmentsFilter {
  final String? sectionId;
  final String? subjectId;
  final String? teacherId;
  final String? status;
  final bool upcomingOnly;

  const AssignmentsFilter({
    this.sectionId,
    this.subjectId,
    this.teacherId,
    this.status,
    this.upcomingOnly = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignmentsFilter &&
          other.sectionId == sectionId &&
          other.subjectId == subjectId &&
          other.teacherId == teacherId &&
          other.status == status &&
          other.upcomingOnly == upcomingOnly;

  @override
  int get hashCode => Object.hash(sectionId, subjectId, teacherId, status, upcomingOnly);
}

class StudentAssignmentsFilter {
  final String sectionId;
  final bool pendingOnly;

  const StudentAssignmentsFilter({
    required this.sectionId,
    this.pendingOnly = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAssignmentsFilter &&
          other.sectionId == sectionId &&
          other.pendingOnly == pendingOnly;

  @override
  int get hashCode => Object.hash(sectionId, pendingOnly);
}

class SubmissionsFilter {
  final String assignmentId;
  final String? status;

  const SubmissionsFilter({
    required this.assignmentId,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmissionsFilter &&
          other.assignmentId == assignmentId &&
          other.status == status;

  @override
  int get hashCode => Object.hash(assignmentId, status);
}

class StudentSubmissionFilter {
  final String assignmentId;
  final String studentId;

  const StudentSubmissionFilter({
    required this.assignmentId,
    required this.studentId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentSubmissionFilter &&
          other.assignmentId == assignmentId &&
          other.studentId == studentId;

  @override
  int get hashCode => Object.hash(assignmentId, studentId);
}

class AssignmentSummaryFilter {
  final String? sectionId;
  final String? teacherId;

  const AssignmentSummaryFilter({
    this.sectionId,
    this.teacherId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignmentSummaryFilter &&
          other.sectionId == sectionId &&
          other.teacherId == teacherId;

  @override
  int get hashCode => Object.hash(sectionId, teacherId);
}

class AssignmentsNotifier extends StateNotifier<AsyncValue<List<Assignment>>> {
  final AssignmentRepository _repository;

  AssignmentsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadAssignments({
    String? sectionId,
    String? subjectId,
    String? teacherId,
    String? status,
    bool upcomingOnly = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final assignments = await _repository.getAssignments(
        sectionId: sectionId,
        subjectId: subjectId,
        teacherId: teacherId,
        status: status,
        upcomingOnly: upcomingOnly,
      );
      state = AsyncValue.data(assignments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Assignment> createAssignment(Map<String, dynamic> data) async {
    final assignment = await _repository.createAssignment(data);
    await loadAssignments();
    return assignment;
  }

  Future<Assignment> updateAssignment(String assignmentId, Map<String, dynamic> data) async {
    final assignment = await _repository.updateAssignment(assignmentId, data);
    await loadAssignments();
    return assignment;
  }

  Future<void> publishAssignment(String assignmentId) async {
    await _repository.publishAssignment(assignmentId);
    await loadAssignments();
  }

  Future<void> closeAssignment(String assignmentId) async {
    await _repository.closeAssignment(assignmentId);
    await loadAssignments();
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _repository.deleteAssignment(assignmentId);
    await loadAssignments();
  }
}

final assignmentsNotifierProvider =
    StateNotifierProvider<AssignmentsNotifier, AsyncValue<List<Assignment>>>((ref) {
  final repository = ref.watch(assignmentRepositoryProvider);
  return AssignmentsNotifier(repository);
});

class SubmissionNotifier extends StateNotifier<AsyncValue<Submission?>> {
  final AssignmentRepository _repository;

  SubmissionNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final submission = await _repository.getStudentSubmission(
        assignmentId: assignmentId,
        studentId: studentId,
      );
      state = AsyncValue.data(submission);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Submission> submitAssignment({
    required String assignmentId,
    required String studentId,
    String? content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final submission = await _repository.submitAssignment(
      assignmentId: assignmentId,
      studentId: studentId,
      content: content,
      attachments: attachments,
    );
    state = AsyncValue.data(submission);
    return submission;
  }

  Future<Submission> gradeSubmission({
    required String submissionId,
    required double marksObtained,
    String? feedback,
  }) async {
    final submission = await _repository.gradeSubmission(
      submissionId: submissionId,
      marksObtained: marksObtained,
      feedback: feedback,
    );
    state = AsyncValue.data(submission);
    return submission;
  }

  Future<Submission> returnSubmission({
    required String submissionId,
    String? feedback,
  }) async {
    final submission = await _repository.returnSubmission(
      submissionId: submissionId,
      feedback: feedback,
    );
    state = AsyncValue.data(submission);
    return submission;
  }
}

final submissionNotifierProvider =
    StateNotifierProvider<SubmissionNotifier, AsyncValue<Submission?>>((ref) {
  final repository = ref.watch(assignmentRepositoryProvider);
  return SubmissionNotifier(repository);
});
