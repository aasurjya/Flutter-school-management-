import '../models/trend_prediction.dart';
import '../../features/ai_insights/utils/linear_regression.dart';
import 'base_repository.dart';

class TrendPredictionRepository extends BaseRepository {
  TrendPredictionRepository(super.client);

  Future<List<DataPoint>> getStudentExamHistory(String studentId) async {
    try {
      final response = await client
          .from('v_student_overall_ranks')
          .select('exam_name, overall_percentage')
          .eq('student_id', studentId)
          .order('exam_id');

      final records = (response as List).cast<Map<String, dynamic>>();
      return records.asMap().entries.map((entry) {
        return DataPoint(
          x: entry.key.toDouble(),
          y: (entry.value['overall_percentage'] as num?)?.toDouble() ?? 0,
          label: entry.value['exam_name'] as String?,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<DataPoint>> getSectionAttendanceTrend(
    String sectionId,
  ) async {
    try {
      final response = await client
          .from('v_section_daily_attendance')
          .select('date, attendance_percentage')
          .eq('section_id', sectionId)
          .order('date');

      final records = (response as List).cast<Map<String, dynamic>>();

      // Group by month for smoother trend
      final monthlyData = <String, List<double>>{};
      for (final r in records) {
        final date = DateTime.parse(r['date']);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyData.putIfAbsent(monthKey, () => []);
        monthlyData[monthKey]!
            .add((r['attendance_percentage'] as num?)?.toDouble() ?? 0);
      }

      final sorted = monthlyData.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      return sorted.asMap().entries.map((entry) {
        final values = entry.value.value;
        final avg = values.reduce((a, b) => a + b) / values.length;
        return DataPoint(
          x: entry.key.toDouble(),
          y: double.parse(avg.toStringAsFixed(1)),
          label: entry.value.key,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<TrendPrediction> buildStudentExamPrediction(
    String studentId,
  ) async {
    final history = await getStudentExamHistory(studentId);

    if (history.length < 2) {
      return TrendPrediction(
        entityType: 'student',
        entityId: studentId,
        metricType: 'exam_performance',
        historicalData: history,
      );
    }

    final xValues = history.map((d) => d.x).toList();
    final yValues = history.map((d) => d.y).toList();
    final regression = LinearRegression.fit(xValues, yValues);

    // Predict next 3 exams
    final lastX = xValues.last;
    final predictedY = regression.predictFuture(3, lastX);
    final predicted = List.generate(3, (i) {
      return DataPoint(
        x: lastX + i + 1,
        y: predictedY[i],
        label: 'Predicted ${i + 1}',
      );
    });

    final prediction = TrendPrediction(
      entityType: 'student',
      entityId: studentId,
      metricType: 'exam_performance',
      historicalData: history,
      predictedData: predicted,
      slope: regression.slope,
      intercept: regression.intercept,
      rSquared: regression.rSquared,
    );

    // Cache result
    try {
      await client.from('trend_predictions').upsert({
        'tenant_id': tenantId,
        'entity_type': 'student',
        'entity_id': studentId,
        'metric_type': 'exam_performance',
        'slope': regression.slope,
        'intercept': regression.intercept,
        'r_squared': regression.rSquared,
        'historical_data':
            history.map((d) => d.toJson()).toList(),
        'predicted_data':
            predicted.map((d) => d.toJson()).toList(),
        'computed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'entity_type,entity_id,metric_type');
    } catch (_) {}

    return prediction;
  }

  Future<TrendPrediction> buildSectionAttendancePrediction(
    String sectionId,
  ) async {
    final history = await getSectionAttendanceTrend(sectionId);

    if (history.length < 2) {
      return TrendPrediction(
        entityType: 'section',
        entityId: sectionId,
        metricType: 'attendance',
        historicalData: history,
      );
    }

    final xValues = history.map((d) => d.x).toList();
    final yValues = history.map((d) => d.y).toList();
    final regression = LinearRegression.fit(xValues, yValues);

    final lastX = xValues.last;
    final predictedY = regression.predictFuture(3, lastX);
    final predicted = List.generate(3, (i) {
      return DataPoint(
        x: lastX + i + 1,
        y: predictedY[i],
        label: 'Month +${i + 1}',
      );
    });

    final prediction = TrendPrediction(
      entityType: 'section',
      entityId: sectionId,
      metricType: 'attendance',
      historicalData: history,
      predictedData: predicted,
      slope: regression.slope,
      intercept: regression.intercept,
      rSquared: regression.rSquared,
    );

    // Cache result
    try {
      await client.from('trend_predictions').upsert({
        'tenant_id': tenantId,
        'entity_type': 'section',
        'entity_id': sectionId,
        'metric_type': 'attendance',
        'slope': regression.slope,
        'intercept': regression.intercept,
        'r_squared': regression.rSquared,
        'historical_data':
            history.map((d) => d.toJson()).toList(),
        'predicted_data':
            predicted.map((d) => d.toJson()).toList(),
        'computed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'entity_type,entity_id,metric_type');
    } catch (_) {}

    return prediction;
  }
}
