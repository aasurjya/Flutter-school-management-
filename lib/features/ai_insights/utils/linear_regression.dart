import 'dart:math';

class LinearRegression {
  final double slope;
  final double intercept;
  final double rSquared;

  const LinearRegression({
    required this.slope,
    required this.intercept,
    required this.rSquared,
  });

  factory LinearRegression.fit(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) {
      return const LinearRegression(slope: 0, intercept: 0, rSquared: 0);
    }

    final n = x.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;

    for (var i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
      sumY2 += y[i] * y[i];
    }

    final meanX = sumX / n;
    final meanY = sumY / n;
    final denominator = sumX2 - n * meanX * meanX;

    if (denominator.abs() < 1e-10) {
      return LinearRegression(slope: 0, intercept: meanY, rSquared: 0);
    }

    final slope = (sumXY - n * meanX * meanY) / denominator;
    final intercept = meanY - slope * meanX;

    // R-squared
    double ssRes = 0, ssTot = 0;
    for (var i = 0; i < n; i++) {
      final predicted = slope * x[i] + intercept;
      ssRes += pow(y[i] - predicted, 2);
      ssTot += pow(y[i] - meanY, 2);
    }

    final rSquared = ssTot.abs() < 1e-10 ? 0.0 : max(0.0, 1 - ssRes / ssTot);

    return LinearRegression(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared,
    );
  }

  double predict(double x) {
    return (slope * x + intercept).clamp(0, 100);
  }

  List<double> predictFuture(int count, double startX) {
    return List.generate(
      count,
      (i) => predict(startX + i + 1),
    );
  }
}
