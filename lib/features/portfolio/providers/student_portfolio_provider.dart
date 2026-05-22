import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/student_portfolio.dart';
import '../../../data/repositories/student_portfolio_repository.dart';

final studentPortfolioRepositoryProvider =
    Provider<StudentPortfolioRepository>((ref) {
  return StudentPortfolioRepository(ref.watch(supabaseProvider));
});

final portfolioSummaryProvider =
    FutureProvider.autoDispose.family<PortfolioSummary, String>((ref, studentId) async {
  final repo = ref.watch(studentPortfolioRepositoryProvider);
  return repo.getPortfolioSummary(studentId);
});

final portfolioWorkProvider =
    FutureProvider.autoDispose.family<List<PortfolioWork>, String>((ref, studentId) async {
  final repo = ref.watch(studentPortfolioRepositoryProvider);
  return repo.getPortfolioWork(studentId);
});
