import 'package:supabase_flutter/supabase_flutter.dart';

import '../ai_tool.dart';

/// Fetches basic student information by student ID or name search.
class FetchStudentTool extends AiTool {
  final SupabaseClient _client;

  FetchStudentTool(this._client);

  @override
  String get name => 'fetch_student';

  @override
  String get description =>
      'Look up a student by ID or name. Returns name, class, section, '
      'admission number, and payment status.';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'student_id': {
            'type': 'string',
            'description': 'UUID of the student (if known)',
          },
          'student_name': {
            'type': 'string',
            'description': 'Name to search for (if ID not known)',
          },
        },
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    final studentId = params['student_id'] as String?;
    final studentName = params['student_name'] as String?;

    Map<String, dynamic>? result;

    if (studentId != null && studentId.isNotEmpty) {
      result = await _client
          .from('students')
          .select('''
            id, first_name, last_name, admission_number, payment_status,
            student_enrollments(
              classes(name),
              sections(name)
            )
          ''')
          .eq('id', studentId)
          .maybeSingle();
    } else if (studentName != null && studentName.isNotEmpty) {
      // Search by name (first match).
      final results = await _client
          .from('students')
          .select('''
            id, first_name, last_name, admission_number, payment_status,
            student_enrollments(
              classes(name),
              sections(name)
            )
          ''')
          .or('first_name.ilike.%$studentName%,last_name.ilike.%$studentName%')
          .limit(1);

      final resultList = results as List;
      if (resultList.isNotEmpty) {
        result = resultList.first as Map<String, dynamic>;
      }
    }

    if (result == null) {
      return {'error': 'Student not found'};
    }

    // Flatten enrollment data.
    String className = '';
    String sectionName = '';
    final enrollments = result['student_enrollments'] as List?;
    if (enrollments != null && enrollments.isNotEmpty) {
      final enrollment = enrollments.first as Map<String, dynamic>;
      className = (enrollment['classes'] as Map?)?['name'] ?? '';
      sectionName = (enrollment['sections'] as Map?)?['name'] ?? '';
    }

    return {
      'student_id': result['id'],
      'name': '${result['first_name']} ${result['last_name']}'.trim(),
      'class': className,
      'section': sectionName,
      'admission_number': result['admission_number'] ?? '',
      'payment_status': result['payment_status'] ?? 'unknown',
    };
  }
}
