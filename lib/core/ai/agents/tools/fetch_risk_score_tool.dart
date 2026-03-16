import 'package:supabase_flutter/supabase_flutter.dart';

import '../ai_tool.dart';

/// Fetches a student's risk score breakdown.
class FetchRiskScoreTool extends AiTool {
  final SupabaseClient _client;

  FetchRiskScoreTool(this._client);

  @override
  String get name => 'fetch_risk_score';

  @override
  String get description =>
      'Get a student\'s risk assessment score including overall risk level, '
      'attendance risk, academic risk, fee risk, and engagement risk.';

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
      final result = await _client
          .from('student_risk_scores')
          .select()
          .eq('student_id', studentId)
          .order('calculated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (result == null) {
        return {
          'student_id': studentId,
          'message': 'No risk score calculated yet',
          'risk_level': 'unknown',
        };
      }

      return {
        'student_id': studentId,
        'risk_level': result['risk_level'] ?? 'unknown',
        'overall_score': result['overall_score'] ?? 0,
        'attendance_score': result['attendance_score'] ?? 0,
        'academic_score': result['academic_score'] ?? 0,
        'fee_score': result['fee_score'] ?? 0,
        'engagement_score': result['engagement_score'] ?? 0,
        'flags': result['flags'] ?? [],
        'calculated_at': result['calculated_at'],
      };
    } catch (e) {
      return {'error': 'Failed to fetch risk score: $e'};
    }
  }
}
