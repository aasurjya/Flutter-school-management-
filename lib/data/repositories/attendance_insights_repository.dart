import '../models/attendance_insights.dart';
import 'base_repository.dart';

class AttendanceInsightsRepository extends BaseRepository {
  AttendanceInsightsRepository(super.client);

  Future<List<DayPattern>> getDayPatterns(String sectionId) async {
    try {
      final response = await client
          .from('v_attendance_day_patterns')
          .select()
          .eq('section_id', sectionId)
          .order('day_of_week');

      return (response as List)
          .map((json) => DayPattern.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ChronicAbsentee>> getChronicAbsentees(String sectionId) async {
    try {
      final response = await client
          .from('v_chronic_absentees')
          .select()
          .eq('section_id', sectionId)
          .order('absence_rate', ascending: false);

      return (response as List)
          .map((json) => ChronicAbsentee.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSectionDailyHistory(
    String sectionId, {
    int days = 30,
  }) async {
    try {
      final startDate =
          DateTime.now().subtract(Duration(days: days));

      final response = await client
          .from('v_section_daily_attendance')
          .select()
          .eq('section_id', sectionId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .order('date');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  List<AttendanceAnomaly> detectAnomalies(
    List<Map<String, dynamic>> dailyHistory,
  ) {
    if (dailyHistory.length < 8) return [];

    final anomalies = <AttendanceAnomaly>[];

    for (var i = 7; i < dailyHistory.length; i++) {
      // 7-day rolling average
      double sum = 0;
      for (var j = i - 7; j < i; j++) {
        sum += (dailyHistory[j]['attendance_percentage'] as num?)
                ?.toDouble() ??
            0;
      }
      final rollingAvg = sum / 7;
      final current =
          (dailyHistory[i]['attendance_percentage'] as num?)?.toDouble() ?? 0;
      final deviation = current - rollingAvg;

      // Flag if >15% deviation
      if (deviation.abs() > 15) {
        anomalies.add(AttendanceAnomaly(
          date: DateTime.parse(dailyHistory[i]['date']),
          attendancePercentage: current,
          expectedPercentage: rollingAvg,
          deviation: deviation,
          type: deviation < 0 ? 'drop' : 'spike',
        ));
      }
    }

    return anomalies;
  }

  Future<List<StudentStreak>> getStudentStreaks(String sectionId) async {
    try {
      // Get recent attendance ordered by student and date
      final response = await client
          .from('attendance')
          .select('''
            student_id, date, status,
            students!inner(first_name, last_name)
          ''')
          .eq('section_id', sectionId)
          .order('student_id')
          .order('date', ascending: false)
          .limit(500);

      final records = (response as List).cast<Map<String, dynamic>>();
      if (records.isEmpty) return [];

      final streaks = <StudentStreak>[];
      String? currentStudentId;
      String? currentStatus;
      int streakCount = 0;
      String studentName = '';
      DateTime? streakStart;
      DateTime? streakEnd;

      void saveStreak() {
        if (currentStudentId != null && streakCount >= 3) {
          streaks.add(StudentStreak(
            studentId: currentStudentId,
            studentName: studentName,
            streakType: currentStatus ?? 'present',
            streakLength: streakCount,
            streakStart: streakStart,
            streakEnd: streakEnd,
          ));
        }
      }

      for (final record in records) {
        final sid = record['student_id'] as String;
        final status = record['status'] as String;
        final date = DateTime.parse(record['date']);
        final student = record['students'];
        final name =
            '${student['first_name']} ${student['last_name'] ?? ''}'.trim();

        if (sid != currentStudentId) {
          // Save previous streak if meaningful
          saveStreak();
          // Reset
          currentStudentId = sid;
          currentStatus = status == 'absent' ? 'absent' : 'present';
          streakCount = 1;
          studentName = name;
          streakEnd = date;
          streakStart = date;
        } else {
          final normalizedStatus =
              status == 'absent' ? 'absent' : 'present';
          if (normalizedStatus == currentStatus) {
            streakCount++;
            streakStart = date;
          } else {
            saveStreak();
            currentStatus = normalizedStatus;
            streakCount = 1;
            streakEnd = date;
            streakStart = date;
          }
        }
      }
      saveStreak();

      // Sort by streak length descending
      streaks.sort((a, b) => b.streakLength.compareTo(a.streakLength));
      return streaks.take(20).toList();
    } catch (e) {
      return [];
    }
  }
}
