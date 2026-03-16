import 'package:supabase_flutter/supabase_flutter.dart';

import '../ai_tool.dart';

/// Fetches academic performance (marks) for a student.
class FetchMarksTool extends AiTool {
  final SupabaseClient _client;

  FetchMarksTool(this._client);

  @override
  String get name => 'fetch_marks';

  @override
  String get description =>
      'Get exam marks and subject-wise performance for a student. '
      'Returns subject names, marks obtained, total marks, and percentages.';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'student_id': {
            'type': 'string',
            'description': 'UUID of the student',
          },
        },
        'required': ['student_id'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    final studentId = params['student_id'] as String?;
    if (studentId == null || studentId.isEmpty) {
      return {'error': 'student_id is required'};
    }

    try {
      final marks = await _client
          .from('marks')
          .select('''
            marks_obtained, total_marks,
            exam_subjects(
              subjects(name),
              exams(name, exam_type)
            )
          ''')
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .limit(20);

      final markList = marks as List;
      if (markList.isEmpty) {
        return {
          'student_id': studentId,
          'message': 'No exam records found',
          'subjects': [],
        };
      }

      final subjects = <Map<String, dynamic>>[];
      double totalObtained = 0;
      double totalMax = 0;

      for (final mark in markList) {
        final m = mark as Map<String, dynamic>;
        final obtained = (m['marks_obtained'] as num?)?.toDouble() ?? 0;
        final total = (m['total_marks'] as num?)?.toDouble() ?? 0;
        final examSubject = m['exam_subjects'] as Map<String, dynamic>?;
        final subjectName =
            (examSubject?['subjects'] as Map?)?['name'] ?? 'Unknown';
        final examName =
            (examSubject?['exams'] as Map?)?['name'] ?? 'Unknown';

        totalObtained += obtained;
        totalMax += total;

        subjects.add({
          'subject': subjectName,
          'exam': examName,
          'obtained': obtained,
          'total': total,
          'percentage':
              total > 0 ? double.parse((obtained / total * 100).toStringAsFixed(1)) : 0,
        });
      }

      final overallPct = totalMax > 0
          ? double.parse((totalObtained / totalMax * 100).toStringAsFixed(1))
          : 0.0;

      return {
        'student_id': studentId,
        'overall_percentage': overallPct,
        'subjects': subjects,
      };
    } catch (e) {
      return {'error': 'Failed to fetch marks: $e'};
    }
  }
}
