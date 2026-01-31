import '../models/student_insights.dart';
import 'base_repository.dart';

class InsightsRepository extends BaseRepository {
  InsightsRepository(super.client);

  /// Get comprehensive student insights
  Future<StudentInsights> getStudentInsights(String studentId) async {
    // Get student basic info with enrollment
    final studentResponse = await client
        .from('students')
        .select('''
          id, first_name, last_name,
          student_enrollments!inner(
            section:sections!inner(
              id, name,
              class:classes!inner(id, name)
            )
          )
        ''')
        .eq('id', studentId)
        .eq('student_enrollments.status', 'active')
        .single();

    final studentName =
        '${studentResponse['first_name']} ${studentResponse['last_name'] ?? ''}'
            .trim();
    final enrollment = (studentResponse['student_enrollments'] as List).first;
    final section = enrollment['section'];
    final className = section['class']['name'];
    final sectionName = section['name'];
    final sectionId = section['id'];

    // Get performance data from view
    final performanceData =
        await _getPerformanceData(studentId, sectionId);

    // Get attendance stats
    final attendanceStats = await _getAttendanceStats(studentId);

    // Get subject-wise insights
    final subjectInsights =
        await _getSubjectInsights(studentId, sectionId);

    // Get performance trends
    final trends = await _getPerformanceTrends(studentId);

    // Calculate strengths and areas for improvement
    final strengths = <String>[];
    final areasForImprovement = <String>[];

    for (final subject in subjectInsights) {
      if (subject.isStrength) {
        strengths.add(subject.subjectName);
      } else if (subject.needsImprovement) {
        areasForImprovement.add(subject.subjectName);
      }
    }

    // Generate improvement tips
    final tips = _generateImprovementTips(
      subjectInsights,
      attendanceStats['attendance_percentage'] ?? 0.0,
    );

    // Get gamification data
    final gamificationData = await _getGamificationData(studentId);

    return StudentInsights(
      studentId: studentId,
      studentName: studentName,
      className: className,
      sectionName: sectionName,
      overallPercentage: performanceData['overall_percentage'] ?? 0.0,
      classRank: performanceData['class_rank'] ?? 0,
      totalInClass: performanceData['total_in_class'] ?? 0,
      attendancePercentage: attendanceStats['attendance_percentage'] ?? 0.0,
      subjectInsights: subjectInsights,
      classAveragePercentage: performanceData['class_average'] ?? 0.0,
      performanceVsClass: (performanceData['overall_percentage'] ?? 0.0) -
          (performanceData['class_average'] ?? 0.0),
      trends: trends,
      strengths: strengths,
      areasForImprovement: areasForImprovement,
      tips: tips,
      totalPoints: gamificationData['total_points'] ?? 0,
      achievementsCount: gamificationData['achievements_count'] ?? 0,
      schoolRank: gamificationData['school_rank'] ?? 0,
    );
  }

  Future<Map<String, dynamic>> _getPerformanceData(
    String studentId,
    String sectionId,
  ) async {
    try {
      // Get latest exam for the student
      final examResponse = await client
          .from('marks')
          .select('''
            exam_subjects!inner(
              exam:exams!inner(id, name, is_published)
            )
          ''')
          .eq('student_id', studentId)
          .eq('exam_subjects.exams.is_published', true)
          .order('entered_at', ascending: false)
          .limit(1);

      if (examResponse.isEmpty) {
        return {
          'overall_percentage': 0.0,
          'class_rank': 0,
          'total_in_class': 0,
          'class_average': 0.0,
        };
      }

      final examId = examResponse.first['exam_subjects']['exam']['id'];

      // Get student's overall performance in the exam
      final studentRankResponse = await client
          .from('v_student_overall_ranks')
          .select()
          .eq('student_id', studentId)
          .eq('exam_id', examId)
          .maybeSingle();

      if (studentRankResponse == null) {
        return {
          'overall_percentage': 0.0,
          'class_rank': 0,
          'total_in_class': 0,
          'class_average': 0.0,
        };
      }

      // Get class average
      final classStatsResponse = await client
          .from('v_student_overall_ranks')
          .select('overall_percentage')
          .eq('section_id', sectionId)
          .eq('exam_id', examId);

      double classAverage = 0;
      if ((classStatsResponse as List).isNotEmpty) {
        final total = classStatsResponse.fold<double>(
          0,
          (sum, r) => sum + ((r['overall_percentage'] as num?)?.toDouble() ?? 0),
        );
        classAverage = total / classStatsResponse.length;
      }

      return {
        'overall_percentage':
            (studentRankResponse['overall_percentage'] as num?)?.toDouble() ?? 0,
        'class_rank': studentRankResponse['class_rank'] ?? 0,
        'total_in_class': (classStatsResponse as List).length,
        'class_average': classAverage,
      };
    } catch (e) {
      return {
        'overall_percentage': 0.0,
        'class_rank': 0,
        'total_in_class': 0,
        'class_average': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _getAttendanceStats(String studentId) async {
    try {
      // Get attendance for current academic year
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);

      final response = await client
          .from('attendance')
          .select('status')
          .eq('student_id', studentId)
          .gte('date', startOfYear.toIso8601String().split('T')[0]);

      if ((response as List).isEmpty) {
        return {'attendance_percentage': 0.0};
      }

      final total = response.length;
      final present = response
          .where((r) => r['status'] == 'present' || r['status'] == 'late')
          .length;

      return {
        'attendance_percentage': (present / total) * 100,
        'total_days': total,
        'present_days': present,
      };
    } catch (e) {
      return {'attendance_percentage': 0.0};
    }
  }

  Future<List<SubjectInsight>> _getSubjectInsights(
    String studentId,
    String sectionId,
  ) async {
    try {
      // Get student performance by subject
      final response = await client
          .from('v_student_performance')
          .select()
          .eq('student_id', studentId)
          .order('percentage', ascending: false);

      if ((response as List).isEmpty) {
        return [];
      }

      // Group by subject and get latest scores
      final subjectMap = <String, List<Map<String, dynamic>>>{};
      for (final record in response) {
        final subjectId = record['subject_id'] as String;
        subjectMap.putIfAbsent(subjectId, () => []);
        subjectMap[subjectId]!.add(record);
      }

      final insights = <SubjectInsight>[];

      for (final entry in subjectMap.entries) {
        final records = entry.value;
        final latest = records.first;

        // Calculate class average for this subject
        final classResponse = await client
            .from('v_student_performance')
            .select('percentage')
            .eq('subject_id', entry.key)
            .eq('section_id', sectionId)
            .eq('exam_id', latest['exam_id']);

        double classAverage = 0;
        if ((classResponse as List).isNotEmpty) {
          final total = classResponse.fold<double>(
            0,
            (sum, r) => sum + ((r['percentage'] as num?)?.toDouble() ?? 0),
          );
          classAverage = total / classResponse.length;
        }

        // Get rank in subject
        final rankResponse = await client
            .from('v_student_ranks')
            .select('subject_rank, total_in_subject')
            .eq('student_id', studentId)
            .eq('subject_id', entry.key)
            .eq('exam_id', latest['exam_id'])
            .maybeSingle();

        // Determine trend
        String trend = 'stable';
        if (records.length >= 2) {
          final diff = (records[0]['percentage'] as num).toDouble() -
              (records[1]['percentage'] as num).toDouble();
          if (diff > 5) {
            trend = 'improving';
          } else if (diff < -5) {
            trend = 'declining';
          }
        }

        final percentage = (latest['percentage'] as num?)?.toDouble() ?? 0;

        insights.add(SubjectInsight(
          subjectId: entry.key,
          subjectName: latest['subject_name'],
          subjectCode: latest['subject_code'],
          percentage: percentage,
          classAverage: classAverage,
          subjectRank: rankResponse?['subject_rank'] ?? 0,
          totalInSubject: rankResponse?['total_in_subject'] ?? 0,
          performanceVsClass: percentage - classAverage,
          trend: trend,
          recentScores: records
              .take(5)
              .map((r) => (r['percentage'] as num).toDouble())
              .toList(),
        ));
      }

      return insights;
    } catch (e) {
      return [];
    }
  }

  Future<List<PerformanceTrend>> _getPerformanceTrends(String studentId) async {
    try {
      final response = await client
          .from('v_student_overall_ranks')
          .select()
          .eq('student_id', studentId)
          .order('exam_id', ascending: false)
          .limit(6);

      return (response as List).map((record) {
        return PerformanceTrend(
          examName: record['exam_name'],
          examType: record['exam_type'],
          examDate: DateTime.tryParse(record['created_at'] ?? '') ?? DateTime.now(),
          percentage: (record['overall_percentage'] as num?)?.toDouble() ?? 0,
          classRank: record['class_rank'] ?? 0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _getGamificationData(String studentId) async {
    try {
      final response = await client
          .from('v_student_leaderboard')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      if (response == null) {
        return {
          'total_points': 0,
          'achievements_count': 0,
          'school_rank': 0,
        };
      }

      // Get achievements count
      final achievementsResponse = await client
          .from('student_achievements')
          .select('id')
          .eq('student_id', studentId);

      return {
        'total_points': response['total_points'] ?? 0,
        'achievements_count': (achievementsResponse as List).length,
        'school_rank': response['tenant_rank'] ?? 0,
      };
    } catch (e) {
      return {
        'total_points': 0,
        'achievements_count': 0,
        'school_rank': 0,
      };
    }
  }

  List<ImprovementTip> _generateImprovementTips(
    List<SubjectInsight> subjectInsights,
    double attendancePercentage,
  ) {
    final tips = <ImprovementTip>[];

    // Add attendance tip
    tips.add(ImprovementTip.forAttendance(attendancePercentage));

    // Add subject-specific tips
    for (final subject in subjectInsights) {
      tips.add(ImprovementTip.forSubject(
        subjectName: subject.subjectName,
        percentage: subject.percentage,
        trend: subject.trend,
      ));
    }

    // Sort by priority
    tips.sort((a, b) => a.priority.compareTo(b.priority));

    return tips.take(5).toList(); // Return top 5 tips
  }

  /// Get monthly attendance summary for charts
  Future<List<MonthlyAttendanceSummary>> getMonthlyAttendance(
    String studentId, {
    int? year,
  }) async {
    final targetYear = year ?? DateTime.now().year;
    final startDate = DateTime(targetYear, 1, 1);
    final endDate = DateTime(targetYear, 12, 31);

    final response = await client
        .from('attendance')
        .select('date, status')
        .eq('student_id', studentId)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    // Group by month
    final monthlyData = <int, Map<String, int>>{};
    for (var i = 1; i <= 12; i++) {
      monthlyData[i] = {
        'total': 0,
        'present': 0,
        'absent': 0,
        'late': 0,
      };
    }

    for (final record in (response as List)) {
      final date = DateTime.parse(record['date']);
      final month = date.month;
      final status = record['status'] as String;

      monthlyData[month]!['total'] = monthlyData[month]!['total']! + 1;
      if (status == 'present') {
        monthlyData[month]!['present'] = monthlyData[month]!['present']! + 1;
      } else if (status == 'absent') {
        monthlyData[month]!['absent'] = monthlyData[month]!['absent']! + 1;
      } else if (status == 'late') {
        monthlyData[month]!['late'] = monthlyData[month]!['late']! + 1;
      }
    }

    return monthlyData.entries
        .where((e) => e.value['total']! > 0)
        .map((e) => MonthlyAttendanceSummary(
              month: e.key,
              year: targetYear,
              totalDays: e.value['total']!,
              presentDays: e.value['present']!,
              absentDays: e.value['absent']!,
              lateDays: e.value['late']!,
            ))
        .toList();
  }

  /// Get subject comparison data for radar chart
  Future<List<SubjectComparison>> getSubjectComparison(
    String studentId,
    String sectionId,
  ) async {
    try {
      // Get latest exam
      final examResponse = await client
          .from('marks')
          .select('''
            exam_subjects!inner(
              exam:exams!inner(id, is_published)
            )
          ''')
          .eq('student_id', studentId)
          .eq('exam_subjects.exams.is_published', true)
          .order('entered_at', ascending: false)
          .limit(1);

      if (examResponse.isEmpty) return [];

      final examId = examResponse.first['exam_subjects']['exam']['id'];

      // Get all subjects' performance for this exam
      final response = await client
          .from('v_student_performance')
          .select()
          .eq('exam_id', examId)
          .eq('section_id', sectionId);

      // Group by subject
      final subjectMap = <String, Map<String, dynamic>>{};
      for (final record in (response as List)) {
        final subjectId = record['subject_id'] as String;
        final subjectName = record['subject_name'] as String;
        final percentage = (record['percentage'] as num).toDouble();
        final isStudent = record['student_id'] == studentId;

        subjectMap.putIfAbsent(subjectId, () => {
          'subject_name': subjectName,
          'student_score': 0.0,
          'scores': <double>[],
          'topper_score': 0.0,
        });

        if (isStudent) {
          subjectMap[subjectId]!['student_score'] = percentage;
        }
        subjectMap[subjectId]!['scores'].add(percentage);
        if (percentage > subjectMap[subjectId]!['topper_score']) {
          subjectMap[subjectId]!['topper_score'] = percentage;
        }
      }

      return subjectMap.values.map((data) {
        final scores = data['scores'] as List<double>;
        final classAverage =
            scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0.0;

        return SubjectComparison(
          subjectName: data['subject_name'],
          studentScore: data['student_score'],
          classAverage: classAverage,
          topperScore: data['topper_score'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get children for a parent
  Future<List<Map<String, dynamic>>> getParentChildren(String parentId) async {
    final response = await client
        .from('student_parents')
        .select('''
          student:students!inner(
            id, first_name, last_name, photo_url,
            student_enrollments!inner(
              section:sections!inner(
                name,
                class:classes!inner(name)
              )
            )
          )
        ''')
        .eq('parent_id', parentId);

    return (response as List).map((record) {
      final student = record['student'];
      final enrollment = (student['student_enrollments'] as List).first;
      final section = enrollment['section'];

      return {
        'id': student['id'],
        'name': '${student['first_name']} ${student['last_name'] ?? ''}'.trim(),
        'photo_url': student['photo_url'],
        'class_name': section['class']['name'],
        'section_name': section['name'],
      };
    }).toList();
  }
}
