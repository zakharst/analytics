/// Advanced Biological Age Calculator
/// Next-Gen OpenStrap feature replacing WHOOP Age.
/// Based on Cooper Institute & Uth–Sørensen–Overgaard–Pedersen models.

class BiologicalAgeResult {
  final double chronologicalAge;
  final double biologicalAge;
  final double vo2Modifier;
  final double hrvModifier;
  final double rhrModifier;
  final double lifestyleModifier;

  BiologicalAgeResult({
    required this.chronologicalAge,
    required this.biologicalAge,
    required this.vo2Modifier,
    required this.hrvModifier,
    required this.rhrModifier,
    required this.lifestyleModifier,
  });

  @override
  String toString() {
    return 'BioAge: ${biologicalAge.toStringAsFixed(1)} (CA: $chronologicalAge | VO2: ${vo2Modifier.toStringAsFixed(1)} | HRV: ${hrvModifier.toStringAsFixed(1)} | RHR: ${rhrModifier.toStringAsFixed(1)} | Lifestyle: ${lifestyleModifier.toStringAsFixed(1)})';
  }
}

class BiologicalAgeCalculator {
  /// Calculates the biological age based on 14-day average physiological markers.
  static BiologicalAgeResult calculate({
    required double chronologicalAge,
    required double maxHr,
    required double avgRhr,
    required double avgHrv,
    required double sleepConsistency, // 0.0 to 1.0
    required double avgDailySteps,
  }) {
    // 1. VO2 Max Modifier (40% weight)
    // Uth–Sørensen–Overgaard–Pedersen formula
    final double vo2MaxEst = 15.3 * (maxHr / avgRhr);

    // Simplistic normative VO2 max calculation (baseline ~45 for a 30yo, drops by ~0.5 per year)
    final double expectedVo2Max = 45.0 - (chronologicalAge - 30) * 0.5;
    final double vo2Diff = vo2MaxEst - expectedVo2Max;
    // Every 3 points above expected = -1 year
    double vo2Modifier = -(vo2Diff / 3.0);
    // Cap modifier to prevent extreme outliers
    vo2Modifier = vo2Modifier.clamp(-5.0, 5.0);

    // 2. HRV Modifier (30% weight)
    // Expected HRV drops roughly 1.2ms per year after 20.
    final double expectedHrv = 80.0 - (chronologicalAge - 20) * 1.2;
    final double hrvDiff = avgHrv - expectedHrv;
    // Every 5ms above expected = -1 year
    double hrvModifier = -(hrvDiff / 5.0);
    hrvModifier = hrvModifier.clamp(-4.0, 4.0);

    // 3. RHR Modifier (15% weight)
    double rhrModifier = 0.0;
    if (avgRhr < 50) {
      rhrModifier = -2.0;
    } else if (avgRhr < 60) {
      rhrModifier = -1.0;
    } else if (avgRhr > 85) {
      rhrModifier = 2.0;
    } else if (avgRhr > 75) {
      rhrModifier = 1.0;
    }

    // 4. Lifestyle Modifier (Sleep & Steps) (15% weight)
    double lifestyleModifier = 0.0;
    if (sleepConsistency >= 0.85) lifestyleModifier -= 1.0;
    if (sleepConsistency <= 0.60) lifestyleModifier += 1.0;

    if (avgDailySteps >= 10000) lifestyleModifier -= 1.0;
    if (avgDailySteps <= 4000) lifestyleModifier += 1.0;

    final double totalBiologicalAge = chronologicalAge +
        vo2Modifier +
        hrvModifier +
        rhrModifier +
        lifestyleModifier;

    return BiologicalAgeResult(
      chronologicalAge: chronologicalAge,
      biologicalAge: totalBiologicalAge,
      vo2Modifier: vo2Modifier,
      hrvModifier: hrvModifier,
      rhrModifier: rhrModifier,
      lifestyleModifier: lifestyleModifier,
    );
  }
}
