import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/report_card.dart';
import '../../../data/repositories/report_card_repository.dart';

final reportCardRepositoryProvider = Provider<ReportCardRepository>((ref) {
  return ReportCardRepository(Supabase.instance.client);
});

final reportCardsProvider =
    FutureProvider.family<List<ReportCard>, ReportCardFilter>(
  (ref, filter) async {
    final repository = ref.watch(reportCardRepositoryProvider);
    return repository.getReportCards(
      academicYearId: filter.academicYearId,
      termId: filter.termId,
      classId: filter.classId,
      sectionId: filter.sectionId,
      studentId: filter.studentId,
      status: filter.status,
    );
  },
);

final reportCardByIdProvider =
    FutureProvider.family<ReportCard?, String>((ref, id) async {
  final repository = ref.watch(reportCardRepositoryProvider);
  return repository.getReportCardById(id);
});

final studentReportCardProvider =
    FutureProvider.family<ReportCard?, StudentReportCardParams>(
  (ref, params) async {
    final repository = ref.watch(reportCardRepositoryProvider);
    return repository.getStudentReportCard(
      studentId: params.studentId,
      academicYearId: params.academicYearId,
      termId: params.termId,
    );
  },
);

final reportCardDataProvider =
    FutureProvider.family<ReportCardData, StudentReportCardParams>(
  (ref, params) async {
    final repository = ref.watch(reportCardRepositoryProvider);
    return repository.generateReportCardData(
      studentId: params.studentId,
      academicYearId: params.academicYearId,
      termId: params.termId,
    );
  },
);

final reportCardTemplatesProvider =
    FutureProvider<List<ReportCardTemplate>>((ref) async {
  final repository = ref.watch(reportCardRepositoryProvider);
  return repository.getTemplates();
});

final defaultTemplateProvider =
    FutureProvider<ReportCardTemplate?>((ref) async {
  final repository = ref.watch(reportCardRepositoryProvider);
  return repository.getDefaultTemplate();
});

// Parameters class for student report card lookup
class StudentReportCardParams {
  final String studentId;
  final String academicYearId;
  final String termId;

  const StudentReportCardParams({
    required this.studentId,
    required this.academicYearId,
    required this.termId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentReportCardParams &&
          other.studentId == studentId &&
          other.academicYearId == academicYearId &&
          other.termId == termId;

  @override
  int get hashCode => Object.hash(studentId, academicYearId, termId);
}

// Generation state management
class ReportGenerationState {
  final bool isGenerating;
  final int progress;
  final int total;
  final String? currentStudent;
  final String? error;
  final List<ReportCard> generatedReports;

  const ReportGenerationState({
    this.isGenerating = false,
    this.progress = 0,
    this.total = 0,
    this.currentStudent,
    this.error,
    this.generatedReports = const [],
  });

  ReportGenerationState copyWith({
    bool? isGenerating,
    int? progress,
    int? total,
    String? currentStudent,
    String? error,
    List<ReportCard>? generatedReports,
  }) {
    return ReportGenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      progress: progress ?? this.progress,
      total: total ?? this.total,
      currentStudent: currentStudent,
      error: error,
      generatedReports: generatedReports ?? this.generatedReports,
    );
  }

  double get progressPercentage =>
      total > 0 ? (progress / total) * 100 : 0;
}

class ReportGenerationNotifier extends StateNotifier<ReportGenerationState> {
  final ReportCardRepository _repository;

  ReportGenerationNotifier(this._repository)
      : super(const ReportGenerationState());

  Future<List<ReportCard>> generateBulkReports({
    required String sectionId,
    required String academicYearId,
    required String termId,
    required String templateId,
  }) async {
    try {
      state = state.copyWith(
        isGenerating: true,
        progress: 0,
        error: null,
        generatedReports: [],
      );

      final reports = await _repository.generateBulkReportCards(
        sectionId: sectionId,
        academicYearId: academicYearId,
        termId: termId,
        templateId: templateId,
      );

      state = state.copyWith(
        isGenerating: false,
        progress: reports.length,
        total: reports.length,
        generatedReports: reports,
      );

      return reports;
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
      return [];
    }
  }

  Future<void> publishReports(List<String> reportIds) async {
    try {
      state = state.copyWith(isGenerating: true, error: null);
      await _repository.publishBulkReportCards(reportIds);
      state = state.copyWith(isGenerating: false);
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const ReportGenerationState();
  }
}

final reportGenerationProvider =
    StateNotifierProvider<ReportGenerationNotifier, ReportGenerationState>(
  (ref) {
    final repository = ref.watch(reportCardRepositoryProvider);
    return ReportGenerationNotifier(repository);
  },
);

// Filter state providers
final selectedAcademicYearProvider = StateProvider<String?>((ref) => null);
final selectedTermProvider = StateProvider<String?>((ref) => null);
final selectedClassFilterProvider = StateProvider<String?>((ref) => null);
final selectedSectionFilterProvider = StateProvider<String?>((ref) => null);
