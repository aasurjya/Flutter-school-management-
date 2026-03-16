import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/ai_providers.dart';
import '../../../data/models/report_commentary.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../exams/providers/exams_provider.dart';
import '../../students/providers/students_provider.dart';

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
    final studentRepo = ref.watch(studentRepositoryProvider);
    final examRepo = ref.watch(examRepositoryProvider);
    final attendanceRepo = ref.watch(attendanceRepositoryProvider);

    // Fetch real students from the section.
    final students = await studentRepo.getStudentsBySection(filter.sectionId);

    if (students.isEmpty) return [];

    final remarks = <ReportCommentary>[];

    for (final student in students) {
      // Fetch exam performance for this student and exam.
      double avgPercentage = 0;
      try {
        final performances = await examRepo.getStudentPerformance(
          studentId: student.id,
          examId: filter.examId,
        );
        if (performances.isNotEmpty) {
          final total = performances
              .where((p) => !p.isAbsent)
              .fold<double>(0, (sum, p) => sum + p.percentage);
          final count = performances.where((p) => !p.isAbsent).length;
          avgPercentage = count > 0 ? total / count : 0;
        }
      } catch (_) {
        // Exam data unavailable — use 0.
      }

      // Fetch attendance stats.
      double attendancePercent = 0;
      try {
        final stats = await attendanceRepo.getAttendanceStats(
          studentId: student.id,
        );
        attendancePercent = (stats['attendance_percentage'] ?? 0).toDouble();
      } catch (_) {
        // Attendance data unavailable — use 0.
      }

      final name = student.fullName;
      final avg = avgPercentage.round();
      final attendance = attendancePercent.round();

      final fallback = '$name has achieved an average of $avg% this term with '
          '$attendance% attendance. '
          '${avg >= 85 ? 'Excellent performance! Keep up the outstanding work.' : avg >= 70 ? 'Good effort. Focus on weaker subjects to improve further.' : 'Needs improvement in academics. Regular revision and attendance will help.'}';

      try {
        final result = await aiTextGenerator.generateReportRemark(
          studentName: name,
          attendancePercent: attendancePercent,
          averagePercentage: avgPercentage,
          fallback: fallback,
        );

        remarks.add(ReportCommentary(
          studentId: student.id,
          studentName: name,
          remark: result.text,
          isLLMGenerated: result.isLLMGenerated,
        ));
      } catch (_) {
        remarks.add(ReportCommentary(
          studentId: student.id,
          studentName: name,
          remark: fallback,
        ));
      }

      // Rate limit: 100ms between LLM calls.
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
