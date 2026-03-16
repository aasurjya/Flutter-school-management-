import 'package:supabase_flutter/supabase_flutter.dart';

import '../ai_tool.dart';

/// Fetches attendance statistics for a student.
class FetchAttendanceTool extends AiTool {
  final SupabaseClient _client;

  FetchAttendanceTool(this._client);

  @override
  String get name => 'fetch_attendance';

  @override
  String get description =>
      'Get attendance statistics for a student: total days, present days, '
      'absent days, and percentage. Requires student_id.';

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
      final records = await _client
          .from('attendance')
          .select('status')
          .eq('student_id', studentId);

      final recordList = records as List;
      final total = recordList.length;
      final present = recordList
          .where((r) {
            final status = (r as Map<String, dynamic>)['status'];
            return status == 'present' || status == 'late';
          })
          .length;
      final absent = total - present;
      final percentage = total > 0 ? (present / total * 100) : 0.0;

      return {
        'student_id': studentId,
        'total_days': total,
        'present_days': present,
        'absent_days': absent,
        'attendance_percentage': double.parse(percentage.toStringAsFixed(1)),
      };
    } catch (e) {
      return {'error': 'Failed to fetch attendance: $e'};
    }
  }
}
