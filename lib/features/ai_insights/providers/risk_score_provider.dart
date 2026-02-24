import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/student_risk_score.dart';
import '../../../data/repositories/risk_score_repository.dart';

final riskScoreRepositoryProvider = Provider<RiskScoreRepository>((ref) {
  return RiskScoreRepository(ref.watch(supabaseProvider));
});

// --- Filter classes ---

class SectionRiskFilter {
  final String sectionId;
  final String academicYearId;

  const SectionRiskFilter({
    required this.sectionId,
    required this.academicYearId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionRiskFilter &&
          other.sectionId == sectionId &&
          other.academicYearId == academicYearId;

  @override
  int get hashCode => Object.hash(sectionId, academicYearId);
}

class StudentRiskFilter {
  final String studentId;
  final String academicYearId;

  const StudentRiskFilter({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentRiskFilter &&
          other.studentId == studentId &&
          other.academicYearId == academicYearId;

  @override
  int get hashCode => Object.hash(studentId, academicYearId);
}

class AtRiskFilter {
  final String academicYearId;
  final String? riskLevel;
  final int limit;

  const AtRiskFilter({
    required this.academicYearId,
    this.riskLevel,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtRiskFilter &&
          other.academicYearId == academicYearId &&
          other.riskLevel == riskLevel &&
          other.limit == limit;

  @override
  int get hashCode => Object.hash(academicYearId, riskLevel, limit);
}

class RiskDistributionFilter {
  final String academicYearId;
  final String? sectionId;

  const RiskDistributionFilter({
    required this.academicYearId,
    this.sectionId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskDistributionFilter &&
          other.academicYearId == academicYearId &&
          other.sectionId == sectionId;

  @override
  int get hashCode => Object.hash(academicYearId, sectionId);
}

// --- Providers ---

final sectionRiskScoresProvider =
    FutureProvider.family<List<StudentRiskScore>, SectionRiskFilter>(
  (ref, filter) async {
    final repo = ref.watch(riskScoreRepositoryProvider);
    return repo.getSectionRiskScores(filter.sectionId, filter.academicYearId);
  },
);

final studentRiskScoreProvider =
    FutureProvider.family<StudentRiskScore?, StudentRiskFilter>(
  (ref, filter) async {
    final repo = ref.watch(riskScoreRepositoryProvider);
    return repo.getStudentRiskScore(filter.studentId, filter.academicYearId);
  },
);

final atRiskStudentsProvider =
    FutureProvider.family<List<StudentRiskScore>, AtRiskFilter>(
  (ref, filter) async {
    final repo = ref.watch(riskScoreRepositoryProvider);
    return repo.getAtRiskStudents(
      filter.academicYearId,
      riskLevel: filter.riskLevel,
      limit: filter.limit,
    );
  },
);

final riskDistributionProvider =
    FutureProvider.family<Map<String, int>, RiskDistributionFilter>(
  (ref, filter) async {
    final repo = ref.watch(riskScoreRepositoryProvider);
    return repo.getRiskDistribution(
      filter.academicYearId,
      sectionId: filter.sectionId,
    );
  },
);

/// Enriches the base risk score with an LLM-generated explanation.
/// Falls back to null explanation if LLM is unavailable.
final enrichedStudentRiskProvider =
    FutureProvider.family<StudentRiskScore?, StudentRiskFilter>(
  (ref, filter) async {
    final risk = await ref.watch(studentRiskScoreProvider(filter).future);
    if (risk == null) return null;

    final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

    final result = await aiTextGenerator.generateRiskExplanation(
      studentName: risk.studentName ?? 'Student',
      riskLevel: risk.riskLevel,
      overallScore: risk.overallRiskScore,
      attendanceScore: risk.attendanceScore,
      academicScore: risk.academicScore,
      feeScore: risk.feeScore,
      engagementScore: risk.engagementScore,
      flags: risk.flags,
      fallback: '',
    );

    if (result.text.isEmpty) return risk;
    return risk.copyWith(riskExplanation: result.text);
  },
);
