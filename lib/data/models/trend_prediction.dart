class TrendPrediction {
  final String entityType;
  final String entityId;
  final String metricType;
  final List<DataPoint> historicalData;
  final List<DataPoint> predictedData;
  final double slope;
  final double intercept;
  final double rSquared;

  const TrendPrediction({
    required this.entityType,
    required this.entityId,
    required this.metricType,
    this.historicalData = const [],
    this.predictedData = const [],
    this.slope = 0,
    this.intercept = 0,
    this.rSquared = 0,
  });

  factory TrendPrediction.fromJson(Map<String, dynamic> json) {
    return TrendPrediction(
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'] ?? '',
      metricType: json['metric_type'] ?? '',
      historicalData: (json['historical_data'] as List?)
              ?.map((d) => DataPoint.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      predictedData: (json['predicted_data'] as List?)
              ?.map((d) => DataPoint.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      slope: (json['slope'] as num?)?.toDouble() ?? 0,
      intercept: (json['intercept'] as num?)?.toDouble() ?? 0,
      rSquared: (json['r_squared'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'entity_type': entityType,
        'entity_id': entityId,
        'metric_type': metricType,
        'historical_data': historicalData.map((d) => d.toJson()).toList(),
        'predicted_data': predictedData.map((d) => d.toJson()).toList(),
        'slope': slope,
        'intercept': intercept,
        'r_squared': rSquared,
      };

  String get trendDirection {
    if (slope > 1) return 'improving';
    if (slope < -1) return 'declining';
    return 'stable';
  }

  double get confidencePercent => (rSquared * 100).clamp(0, 100);

  String get confidenceLabel {
    if (rSquared >= 0.7) return 'High';
    if (rSquared >= 0.4) return 'Medium';
    return 'Low';
  }

  bool get hasEnoughData => historicalData.length >= 3;
}

class DataPoint {
  final double x;
  final double y;
  final String? label;

  const DataPoint({
    required this.x,
    required this.y,
    this.label,
  });

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        if (label != null) 'label': label,
      };
}
