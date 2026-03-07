import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/student_portfolio.dart';
import '../../../data/repositories/student_portfolio_repository.dart';

// ============================================================
// Repository Provider
// ============================================================

final studentPortfolioRepositoryProvider =
    Provider<StudentPortfolioRepository>((ref) {
  return StudentPortfolioRepository(ref.watch(supabaseProvider));
});

// ============================================================
// Portfolio Summary
// ============================================================

final portfolioSummaryProvider =
    FutureProvider.family<PortfolioSummary, String>((ref, studentId) async {
  final repo = ref.watch(studentPortfolioRepositoryProvider);
  return repo.getPortfolioSummary(studentId);
});

// ============================================================
// Portfolio Work
// ============================================================

final portfolioWorkProvider =
    FutureProvider.family<List<PortfolioWork>, String>((ref, studentId) async {
  final repo = ref.watch(studentPortfolioRepositoryProvider);
  return repo.getPortfolioWork(studentId);
});
