import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/ai_providers.dart';
import '../../../data/models/report_commentary.dart';

class SectionExamFilter {
  final String sectionId;
  final String examId;

  const SectionExamFilter({required this.sectionId, required this.examId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionExamFilter &&
          sectionId == other.sectionId &&
          examId == other.examId;

  @override
  int get hashCode => Object.hash(sectionId, examId);
}

final generateSectionRemarksProvider =
    FutureProvider.family<List<ReportCommentary>, SectionExamFilter>(
  (ref, filter) async {
    final aiTextGenerator = ref.watch(aiTextGeneratorProvider);

    // Mock student list — in production, fetch from student repository
    final students = [
      {'id': '1', 'name': 'Aarav Sharma', 'attendance': 95, 'avg': 88},
      {'id': '2', 'name': 'Priya Patel', 'attendance': 92, 'avg': 91},
      {'id': '3', 'name': 'Rahul Kumar', 'attendance': 78, 'avg': 72},
      {'id': '4', 'name': 'Sneha Gupta', 'attendance': 98, 'avg': 95},
      {'id': '5', 'name': 'Arjun Singh', 'attendance': 85, 'avg': 80},
    ];

    final remarks = <ReportCommentary>[];

    for (final student in students) {
      final name = student['name'] as String;
      final attendance = student['attendance'] as int;
      final avg = student['avg'] as int;

      final fallback = '$name has achieved an average of $avg% this term with '
          '$attendance% attendance. ${avg >= 85 ? 'Excellent performance! Keep up the outstanding work.' : avg >= 70 ? 'Good effort. Focus on weaker subjects to improve further.' : 'Needs improvement in academics. Regular revision and attendance will help.'}';

      try {
        final result = await aiTextGenerator.generateReportRemark(
          studentName: name,
          attendancePercent: attendance.toDouble(),
          averagePercentage: avg.toDouble(),
          fallback: fallback,
        );

        remarks.add(ReportCommentary(
          studentId: student['id'] as String,
          studentName: name,
          remark: result.text,
          isLLMGenerated: result.isLLMGenerated,
        ));
      } catch (_) {
        remarks.add(ReportCommentary(
          studentId: student['id'] as String,
          studentName: name,
          remark: fallback,
        ));
      }

      // Rate limit: 100ms between LLM calls
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return remarks;
  },
);

class RemarksNotifier extends StateNotifier<List<ReportCommentary>> {
  RemarksNotifier() : super([]);

  void setRemarks(List<ReportCommentary> remarks) => state = remarks;

  void updateRemark(String studentId, String newRemark) {
    state = [
      for (final r in state)
        if (r.studentId == studentId)
          r.copyWith(remark: newRemark, isEdited: true)
        else
          r,
    ];
  }

  void toggleApproval(String studentId) {
    state = [
      for (final r in state)
        if (r.studentId == studentId)
          r.copyWith(isApproved: !r.isApproved)
        else
          r,
    ];
  }

  void approveAll() {
    state = [for (final r in state) r.copyWith(isApproved: true)];
  }

  List<ReportCommentary> get approved =>
      state.where((r) => r.isApproved).toList();
}

final remarksNotifierProvider =
    StateNotifierProvider<RemarksNotifier, List<ReportCommentary>>(
  (ref) => RemarksNotifier(),
);
