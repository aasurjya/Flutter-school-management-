import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/report_card_full.dart';
import '../../../data/repositories/report_card_full_repository.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------
final rcFullRepositoryProvider = Provider<ReportCardFullRepository>((ref) {
  return ReportCardFullRepository(ref.watch(supabaseProvider));
});

// ---------------------------------------------------------------------------
// Grading Scales
// ---------------------------------------------------------------------------
final gradingScalesProvider = FutureProvider<List<GradingScale>>((ref) async {
  final repo = ref.watch(rcFullRepositoryProvider);
  return repo.getGradingScales();
});

// ---------------------------------------------------------------------------
// Templates
// ---------------------------------------------------------------------------
final rcTemplatesProvider =
    FutureProvider<List<ReportCardTemplateFull>>((ref) async {
  final repo = ref.watch(rcFullRepositoryProvider);
  return repo.getTemplates();
});

final rcTemplateByIdProvider =
    FutureProvider.family<ReportCardTemplateFull?, String>((ref, id) async {
  final repo = ref.watch(rcFullRepositoryProvider);
  return repo.getTemplateById(id);
});

final rcDefaultTemplateProvider =
    FutureProvider<ReportCardTemplateFull?>((ref) async {
  final repo = ref.watch(rcFullRepositoryProvider);
  return repo.getDefaultTemplate();
});

// ---------------------------------------------------------------------------
// Report Cards
// ---------------------------------------------------------------------------
final rcListProvider =
    FutureProvider.family<List<ReportCardFull>, ReportCardFullFilter>(
  (ref, filter) async {
    final repo = ref.watch(rcFullRepositoryProvider);
    return repo.getReportCards(filter);
  },
);

final rcByIdProvider =
    FutureProvider.family<ReportCardFull?, String>((ref, id) async {
  final repo = ref.watch(rcFullRepositoryProvider);
  return repo.getReportCardById(id);
});

final rcStudentProvider =
    FutureProvider.family<List<ReportCardFull>, String>((ref, studentId) async {
  final repo = ref.watch(rcFullRepositoryProvider);
  return repo.getStudentReportCards(studentId);
});

// ---------------------------------------------------------------------------
// Dashboard Summary
// ---------------------------------------------------------------------------
final rcDashboardSummaryProvider =
    FutureProvider.family<List<ReportCardSummary>, RCDashboardParams>(
  (ref, params) async {
    final repo = ref.watch(rcFullRepositoryProvider);
    return repo.getDashboardSummary(
      academicYearId: params.academicYearId,
      termId: params.termId,
    );
  },
);

class RCDashboardParams {
  final String academicYearId;
  final String termId;

  const RCDashboardParams({
    required this.academicYearId,
    required this.termId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RCDashboardParams &&
          other.academicYearId == academicYearId &&
          other.termId == termId;

  @override
  int get hashCode => Object.hash(academicYearId, termId);
}

// ---------------------------------------------------------------------------
// Filter State Providers
// ---------------------------------------------------------------------------
final rcSelectedAcademicYearProvider = StateProvider<String?>((ref) => null);
final rcSelectedTermProvider = StateProvider<String?>((ref) => null);
final rcSelectedSectionProvider = StateProvider<String?>((ref) => null);
final rcSelectedStatusProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Bulk Generation Notifier
// ---------------------------------------------------------------------------
class RCGenerationState {
  final bool isGenerating;
  final int progress;
  final int total;
  final String? currentStudent;
  final String? error;
  final List<ReportCardFull> generatedReports;

  const RCGenerationState({
    this.isGenerating = false,
    this.progress = 0,
    this.total = 0,
    this.currentStudent,
    this.error,
    this.generatedReports = const [],
  });

  RCGenerationState copyWith({
    bool? isGenerating,
    int? progress,
    int? total,
    String? currentStudent,
    String? error,
    List<ReportCardFull>? generatedReports,
  }) {
    return RCGenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      progress: progress ?? this.progress,
      total: total ?? this.total,
      currentStudent: currentStudent,
      error: error,
      generatedReports: generatedReports ?? this.generatedReports,
    );
  }

  double get progressPercent => total > 0 ? (progress / total) * 100 : 0;
}

class RCGenerationNotifier extends StateNotifier<RCGenerationState> {
  final ReportCardFullRepository _repository;

  RCGenerationNotifier(this._repository) : super(const RCGenerationState());

  Future<List<ReportCardFull>> generateBulk({
    required String sectionId,
    required String academicYearId,
    required String termId,
    required String templateId,
    required List<String> examIds,
  }) async {
    try {
      state = state.copyWith(
        isGenerating: true,
        progress: 0,
        error: null,
        generatedReports: [],
      );

      final reports = await _repository.bulkGenerateForClass(
        sectionId: sectionId,
        academicYearId: academicYearId,
        termId: termId,
        templateId: templateId,
        examIds: examIds,
        onProgress: (current, total, name) {
          state = state.copyWith(
            progress: current,
            total: total,
            currentStudent: name,
          );
        },
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

  Future<void> publishAll() async {
    if (state.generatedReports.isEmpty) return;

    try {
      state = state.copyWith(isGenerating: true, error: null);
      final ids = state.generatedReports.map((r) => r.id).toList();
      await _repository.publishReportCards(ids);
      state = state.copyWith(isGenerating: false);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  void reset() => state = const RCGenerationState();
}

final rcGenerationProvider =
    StateNotifierProvider<RCGenerationNotifier, RCGenerationState>((ref) {
  final repo = ref.watch(rcFullRepositoryProvider);
  return RCGenerationNotifier(repo);
});

// ---------------------------------------------------------------------------
// Template Editor State
// ---------------------------------------------------------------------------
class TemplateEditorState {
  final String name;
  final String layout;
  final Map<String, dynamic> headerConfig;
  final List<TemplateSectionConfig> sections;
  final String? gradingScaleId;
  final String? footerText;
  final bool isDefault;
  final String pageSize;

  const TemplateEditorState({
    this.name = '',
    this.layout = 'standard',
    this.headerConfig = const {},
    this.sections = const [],
    this.gradingScaleId,
    this.footerText,
    this.isDefault = false,
    this.pageSize = 'A4',
  });

  TemplateEditorState copyWith({
    String? name,
    String? layout,
    Map<String, dynamic>? headerConfig,
    List<TemplateSectionConfig>? sections,
    String? gradingScaleId,
    String? footerText,
    bool? isDefault,
    String? pageSize,
  }) {
    return TemplateEditorState(
      name: name ?? this.name,
      layout: layout ?? this.layout,
      headerConfig: headerConfig ?? this.headerConfig,
      sections: sections ?? this.sections,
      gradingScaleId: gradingScaleId ?? this.gradingScaleId,
      footerText: footerText ?? this.footerText,
      isDefault: isDefault ?? this.isDefault,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  static TemplateEditorState fromTemplate(ReportCardTemplateFull t) {
    return TemplateEditorState(
      name: t.name,
      layout: t.layout,
      headerConfig: t.headerConfig,
      sections: t.sections,
      gradingScaleId: t.gradingScaleId,
      footerText: t.footerText,
      isDefault: t.isDefault,
      pageSize: t.pageSize,
    );
  }

  static TemplateEditorState defaultState() {
    return const TemplateEditorState(
      name: '',
      layout: 'standard',
      headerConfig: {
        'school_name': '',
        'address': '',
        'motto': '',
        'affiliation_no': '',
      },
      sections: [
        TemplateSectionConfig(type: 'grades', enabled: true, order: 0),
        TemplateSectionConfig(
            type: 'attendance', enabled: true, order: 1),
        TemplateSectionConfig(
            type: 'teacher_comment', enabled: true, order: 2),
        TemplateSectionConfig(
            type: 'principal_comment', enabled: true, order: 3),
        TemplateSectionConfig(type: 'skills', enabled: false, order: 4),
        TemplateSectionConfig(
            type: 'activities', enabled: false, order: 5),
        TemplateSectionConfig(
            type: 'behavior', enabled: false, order: 6),
      ],
    );
  }
}

final templateEditorProvider =
    StateProvider<TemplateEditorState>((ref) => TemplateEditorState.defaultState());
