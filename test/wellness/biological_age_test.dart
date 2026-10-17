import 'package:openstrap_analytics/src/onehz/wellness/biological_age.dart';
import 'package:test/test.dart';

void main() {
  group('BiologicalAgeCalculator', () {
    test('calculates biological age for male with athletic inputs', () {
      final res = BiologicalAgeCalculator.calculate(
        chronologicalAge: 30,
        maxHr: 195,
        avgRhr: 48,
        avgHrv: 85,
        sleepConsistency: 0.90,
        avgDailySteps: 11000,
        sex: 'm',
      );

      expect(res.isYounger, isTrue);
      expect(res.biologicalAge, lessThan(30.0));
      expect(res.vo2Modifier, lessThan(0));
      expect(res.hrvModifier, lessThan(0));
      expect(res.rhrModifier, equals(-2.0));
      expect(res.lifestyleModifier, lessThan(0));
      expect(res.heartInsight, isNotEmpty);
      expect(res.actionableTips, isNotEmpty);
    });

    test('calculates biological age for female with normative female benchmarks', () {
      // For a 28 yo female with 42 ml/kg VO2 (185/67), she should be younger, not penalized for not having male 48 ml/kg
      final resFemale = BiologicalAgeCalculator.calculate(
        chronologicalAge: 28,
        maxHr: 185,
        avgRhr: 58,
        avgHrv: 75,
        sleepConsistency: 0.88,
        avgDailySteps: 9500,
        sex: 'f',
      );

      expect(resFemale.sex, equals('f'));
      expect(resFemale.isYounger, isTrue);
      expect(resFemale.biologicalAge, lessThan(28.0));
    });
  });
}
