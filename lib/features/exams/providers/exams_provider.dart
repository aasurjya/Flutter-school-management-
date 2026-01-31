import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/exam_statistics.dart';
import '../../../data/repositories/exam_repository.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository(Supabase.instance.client);
});

final examsProvider = FutureProvider.family<List<Exam>, ExamsFilter>(
  (ref, filter) async {
    final repository = ref.watch(examRepositoryProvider);
    return repository.getExams(
      academicYearId: filter.academicYearId,
      termId: filter.termId,
      publishedOnly: filter.publishedOnly,
    );
  },
);

final examByIdProvider = FutureProvider.family<Exam?, String>(
  (ref, examId) async {
    final repository = ref.watch(examRepositoryProvider);
    return repository.getExamById(examId);
  },
);

final examSubjectsProvider = FutureProvider.family<List<ExamSubject>, String>(
  (ref, examId) async {
    final repository = ref.watch(examRepositoryProvider);
    return repository.getExamSubjects(examId);
  },
);

final marksProvider = FutureProvider.family<List<Mark>, MarksFilter>(
  (ref, filter) async {
    final repository = ref.watch(examRepositoryProvider);
    return repository.getMarks(
      examSubjectId: filter.examSubjectId,
      studentId: filter.studentId,
    );
  },
);

final studentPerformanceProvider = FutureProvider.family<List<StudentPerformance>, StudentPerformanceFilter>(
  (ref, filter) async {
    final repository = ref.watch(examRepositoryProvider);
    return repository.getStudentPerformance(
      studentId: filter.studentId,
      examId: filter.examId,
      subjectId: filter.subjectId,
    );
  },
);

final studentRanksProvider = FutureProvider.family<List<StudentRank>, StudentRankFilter>(
  (ref, filter) async {
    final repository = ref.watch(examRepositoryProvider);
    return repository.getStudentRanks(
      studentId: filter.studentId,
      examId: filter.examId,
    );
  },
);

final studentOverallRankProvider = FutureProvider.family<StudentOverallRank?, StudentExamFilter>(
  (ref, filter) async {
    final repository = ref.watch(examRepositoryProvider);
    return repository.getStudentOverallRank(
      studentId: filter.studentId,
      examId: filter.examId,
    );
  },
);

final classExamStatsProvider = FutureProvider.family<List<ClassExamStats>, ClassStatsFilter>(
  (ref, filter) async {
    final repository = ref.watch(examRepositoryProvider);
    return repository.getClassExamStats(
      examId: filter.examId,
      sectionId: filter.sectionId,
      subjectId: filter.subjectId,
    );
  },
);

final gradeScalesProvider = FutureProvider<List<GradeScale>>((ref) async {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getGradeScales();
});

final examToppersProvider = FutureProvider.family<List<StudentOverallRank>, ExamToppersFilter>(
  (ref, filter) async {
    final repository = ref.watch(examRepositoryProvider);
    return repository.getExamToppers(
      examId: filter.examId,
      sectionId: filter.sectionId,
      limit: filter.limit,
    );
  },
);

class ExamsFilter {
  final String? academicYearId;
  final String? termId;
  final bool publishedOnly;

  const ExamsFilter({
    this.academicYearId,
    this.termId,
    this.publishedOnly = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamsFilter &&
          other.academicYearId == academicYearId &&
          other.termId == termId &&
          other.publishedOnly == publishedOnly;

  @override
  int get hashCode => Object.hash(academicYearId, termId, publishedOnly);
}

class MarksFilter {
  final String examSubjectId;
  final String? studentId;

  const MarksFilter({
    required this.examSubjectId,
    this.studentId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarksFilter &&
          other.examSubjectId == examSubjectId &&
          other.studentId == studentId;

  @override
  int get hashCode => Object.hash(examSubjectId, studentId);
}

class StudentPerformanceFilter {
  final String studentId;
  final String? examId;
  final String? subjectId;

  const StudentPerformanceFilter({
    required this.studentId,
    this.examId,
    this.subjectId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentPerformanceFilter &&
          other.studentId == studentId &&
          other.examId == examId &&
          other.subjectId == subjectId;

  @override
  int get hashCode => Object.hash(studentId, examId, subjectId);
}

class StudentRankFilter {
  final String studentId;
  final String? examId;

  const StudentRankFilter({
    required this.studentId,
    this.examId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentRankFilter &&
          other.studentId == studentId &&
          other.examId == examId;

  @override
  int get hashCode => Object.hash(studentId, examId);
}

class StudentExamFilter {
  final String studentId;
  final String examId;

  const StudentExamFilter({
    required this.studentId,
    required this.examId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentExamFilter &&
          other.studentId == studentId &&
          other.examId == examId;

  @override
  int get hashCode => Object.hash(studentId, examId);
}

class ClassStatsFilter {
  final String examId;
  final String? sectionId;
  final String? subjectId;

  const ClassStatsFilter({
    required this.examId,
    this.sectionId,
    this.subjectId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassStatsFilter &&
          other.examId == examId &&
          other.sectionId == sectionId &&
          other.subjectId == subjectId;

  @override
  int get hashCode => Object.hash(examId, sectionId, subjectId);
}

class ExamToppersFilter {
  final String examId;
  final String? sectionId;
  final int limit;

  const ExamToppersFilter({
    required this.examId,
    this.sectionId,
    this.limit = 10,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamToppersFilter &&
          other.examId == examId &&
          other.sectionId == sectionId &&
          other.limit == limit;

  @override
  int get hashCode => Object.hash(examId, sectionId, limit);
}

class ExamsNotifier extends StateNotifier<AsyncValue<List<Exam>>> {
  final ExamRepository _repository;

  ExamsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadExams({
    String? academicYearId,
    String? termId,
    bool publishedOnly = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final exams = await _repository.getExams(
        academicYearId: academicYearId,
        termId: termId,
        publishedOnly: publishedOnly,
      );
      state = AsyncValue.data(exams);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Exam> createExam(Map<String, dynamic> data) async {
    final exam = await _repository.createExam(data);
    await loadExams();
    return exam;
  }

  Future<Exam> updateExam(String examId, Map<String, dynamic> data) async {
    final exam = await _repository.updateExam(examId, data);
    await loadExams();
    return exam;
  }

  Future<void> publishExam(String examId) async {
    await _repository.publishExam(examId);
    await loadExams();
  }
}

final examsNotifierProvider =
    StateNotifierProvider<ExamsNotifier, AsyncValue<List<Exam>>>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return ExamsNotifier(repository);
});

class MarksEntryNotifier extends StateNotifier<AsyncValue<List<Mark>>> {
  final ExamRepository _repository;

  MarksEntryNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadMarks(String examSubjectId) async {
    state = const AsyncValue.loading();
    try {
      final marks = await _repository.getMarks(examSubjectId: examSubjectId);
      state = AsyncValue.data(marks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> enterMark({
    required String examSubjectId,
    required String studentId,
    double? marksObtained,
    bool isAbsent = false,
    String? remarks,
  }) async {
    await _repository.enterMark(
      examSubjectId: examSubjectId,
      studentId: studentId,
      marksObtained: marksObtained,
      isAbsent: isAbsent,
      remarks: remarks,
    );
    await loadMarks(examSubjectId);
  }

  Future<void> enterBulkMarks(List<Map<String, dynamic>> marks) async {
    await _repository.enterBulkMarks(marks);
    if (marks.isNotEmpty && marks.first.containsKey('exam_subject_id')) {
      await loadMarks(marks.first['exam_subject_id'] as String);
    }
  }
}

final marksEntryNotifierProvider =
    StateNotifierProvider<MarksEntryNotifier, AsyncValue<List<Mark>>>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return MarksEntryNotifier(repository);
});
