import '../models/student_risk_score.dart';
import 'base_repository.dart';

class RiskScoreRepository extends BaseRepository {
  RiskScoreRepository(super.client);

  Future<List<StudentRiskScore>> getSectionRiskScores(
    String sectionId,
    String academicYearId,
  ) async {
    try {
      final response = await client
          .from('student_risk_scores')
          .select('''
            *,
            students!inner(
              id, first_name, last_name, admission_number,
              student_enrollments!inner(
                section_id,
                sections!inner(name, classes!inner(name))
              )
            )
          ''')
          .eq('academic_year_id', academicYearId)
          .eq('students.student_enrollments.section_id', sectionId)
          .order('overall_risk_score', ascending: false);

      return (response as List).map((json) {
        // Flatten joined data
        final student = json['students'];
        final enrollment =
            (student['student_enrollments'] as List?)?.firstOrNull;
        final section = enrollment?['sections'];
        json['student_name'] =
            '${student['first_name']} ${student['last_name'] ?? ''}'.trim();
        json['admission_number'] = student['admission_number'];
        json['section_name'] = section?['name'];
        json['class_name'] = section?['classes']?['name'];
        return StudentRiskScore.fromJson(json);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<StudentRiskScore?> getStudentRiskScore(
    String studentId,
    String academicYearId,
  ) async {
    try {
      final response = await client
          .from('student_risk_scores')
          .select()
          .eq('student_id', studentId)
          .eq('academic_year_id', academicYearId)
          .maybeSingle();

      if (response == null) return null;
      return StudentRiskScore.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<StudentRiskScore>> getAtRiskStudents(
    String academicYearId, {
    String? riskLevel,
    int limit = 20,
  }) async {
    try {
      var query = client
          .from('student_risk_scores')
          .select('''
            *,
            students!inner(
              id, first_name, last_name, admission_number,
              student_enrollments!inner(
                section_id,
                sections!inner(name, classes!inner(name))
              )
            )
          ''')
          .eq('academic_year_id', academicYearId);

      if (riskLevel != null) {
        query = query.eq('risk_level', riskLevel);
      } else {
        query = query.inFilter('risk_level', ['high', 'critical']);
      }

      final response = await query
          .order('overall_risk_score', ascending: false)
          .limit(limit);

      return (response as List).map((json) {
        final student = json['students'];
        final enrollment =
            (student['student_enrollments'] as List?)?.firstOrNull;
        final section = enrollment?['sections'];
        json['student_name'] =
            '${student['first_name']} ${student['last_name'] ?? ''}'.trim();
        json['admission_number'] = student['admission_number'];
        json['section_name'] = section?['name'];
        json['class_name'] = section?['classes']?['name'];
        return StudentRiskScore.fromJson(json);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> computeRiskScore(
    String studentId,
    String academicYearId,
  ) async {
    await client.rpc('compute_student_risk_score', params: {
      'p_student_id': studentId,
      'p_academic_year_id': academicYearId,
    });
  }

  Future<Map<String, int>> getRiskDistribution(
    String academicYearId, {
    String? sectionId,
  }) async {
    try {
      final distribution = <String, int>{
        'low': 0,
        'medium': 0,
        'high': 0,
        'critical': 0,
      };

      for (final level in distribution.keys.toList()) {
        var query = client
            .from('student_risk_scores')
            .select('id')
            .eq('academic_year_id', academicYearId)
            .eq('risk_level', level);

        if (sectionId != null) {
          // Filter by section via students join
          query = query.inFilter('student_id', []);
          // Use a subquery approach instead
        }

        final response = await query;
        distribution[level] = (response as List).length;
      }

      return distribution;
    } catch (e) {
      return {'low': 0, 'medium': 0, 'high': 0, 'critical': 0};
    }
  }
}
