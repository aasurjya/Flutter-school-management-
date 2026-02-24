import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/data/models/fee_default_prediction.dart';
import 'package:school_management/features/fees/providers/fees_provider.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/provider_overrides.dart';
import '../helpers/test_data.dart';

void main() {
  late FakeFeeRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeFeeRepository();
    container = ProviderContainer(overrides: feeOverrides(fakeRepo));
  });

  tearDown(() => container.dispose());

  group('feeDefaultPredictionsProvider', () {
    test('returns predictions from the fake repo', () async {
      final predictions =
          await container.read(feeDefaultPredictionsProvider.future);

      expect(predictions, isA<List<FeeDefaultPrediction>>());
      expect(predictions, hasLength(2));
    });

    test('first prediction has high risk score', () async {
      final predictions =
          await container.read(feeDefaultPredictionsProvider.future);

      expect(predictions.first.riskScore, greaterThanOrEqualTo(71));
      expect(predictions.first.riskLevel, equals(FeeRiskLevel.high));
    });
  });

  group('FeeDefaultSummary.from', () {
    test('correctly counts high / medium / low risk entries', () {
      final predictions = [
        makeHighRiskPrediction(),
        makeHighRiskPrediction(
            studentId: '11111111-0000-0000-0000-000000000099',
            invoiceId: '22222222-0000-0000-0000-000000000099',
            riskScore: 90),
        makeMediumRiskPrediction(),
      ];

      final summary = FeeDefaultSummary.from(predictions);

      expect(summary.totalAtRisk, equals(3));
      expect(summary.highRiskCount, equals(2));
      expect(summary.mediumRiskCount, equals(1));
      expect(summary.lowRiskCount, equals(0));
    });

    test('formattedAmountAtRisk shows lakhs for large amounts', () {
      final predictions = [
        makeHighRiskPrediction(amountDue: 150000.0),
      ];

      final summary = FeeDefaultSummary.from(predictions);
      expect(summary.formattedAmountAtRisk, contains('L'));
    });

    test('formattedAmountAtRisk shows K for thousands', () {
      final predictions = [
        makeHighRiskPrediction(amountDue: 15000.0),
      ];

      final summary = FeeDefaultSummary.from(predictions);
      expect(summary.formattedAmountAtRisk, contains('K'));
    });

    test('totalAmountAtRisk sums all prediction amounts', () {
      final predictions = [
        makeHighRiskPrediction(amountDue: 10000.0),
        makeMediumRiskPrediction(),
      ];

      final summary = FeeDefaultSummary.from(predictions);
      expect(summary.totalAmountAtRisk, closeTo(18500.0, 0.01));
    });
  });

  group('FeeRiskLevel.fromScore', () {
    test('score >= 71 is high', () {
      expect(FeeRiskLevel.fromScore(71), equals(FeeRiskLevel.high));
      expect(FeeRiskLevel.fromScore(100), equals(FeeRiskLevel.high));
    });

    test('score 41-70 is medium', () {
      expect(FeeRiskLevel.fromScore(41), equals(FeeRiskLevel.medium));
      expect(FeeRiskLevel.fromScore(70), equals(FeeRiskLevel.medium));
    });

    test('score <= 40 is low', () {
      expect(FeeRiskLevel.fromScore(0), equals(FeeRiskLevel.low));
      expect(FeeRiskLevel.fromScore(40), equals(FeeRiskLevel.low));
    });
  });
}
