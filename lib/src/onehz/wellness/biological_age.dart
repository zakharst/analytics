/// Advanced Biological Age Calculator
/// Next-Gen OpenStrap Edge MOD feature replacing WHOOP Age.
/// Grounded in Cooper Institute & Uth–Sørensen–Overgaard–Pedersen models,
/// stratified by biological sex, and enriched with actionable reverse-aging guidance.

class BiologicalAgeResult {
  final double chronologicalAge;
  final double biologicalAge;
  final double ageDifference; // negative = younger than chronological age, positive = older
  final double vo2Modifier;
  final double hrvModifier;
  final double rhrModifier;
  final double lifestyleModifier;
  final double vo2MaxEst;
  final String sex; // 'm', 'f', 'other'

  // Human-readable pillar explanations
  final String heartInsight;
  final String hrvInsight;
  final String vo2Insight;
  final String lifestyleInsight;

  // Personalized reverse-aging guidance
  final List<String> actionableTips;

  BiologicalAgeResult({
    required this.chronologicalAge,
    required this.biologicalAge,
    required this.ageDifference,
    required this.vo2Modifier,
    required this.hrvModifier,
    required this.rhrModifier,
    required this.lifestyleModifier,
    required this.vo2MaxEst,
    this.sex = 'm',
    this.heartInsight = '',
    this.hrvInsight = '',
    this.vo2Insight = '',
    this.lifestyleInsight = '',
    this.actionableTips = const [],
  });

  bool get isYounger => ageDifference < 0;

  @override
  String toString() {
    return 'BioAge: ${biologicalAge.toStringAsFixed(1)} (CA: $chronologicalAge | Diff: ${ageDifference >= 0 ? "+" : ""}${ageDifference.toStringAsFixed(1)} | Sex: $sex | VO2: ${vo2Modifier.toStringAsFixed(1)} | HRV: ${hrvModifier.toStringAsFixed(1)} | RHR: ${rhrModifier.toStringAsFixed(1)} | Lifestyle: ${lifestyleModifier.toStringAsFixed(1)})';
  }
}

class BiologicalAgeCalculator {
  /// Calculates biological age based on 14-day average physiological markers
  /// with sex-specific normative benchmarks.
  static BiologicalAgeResult calculate({
    required double chronologicalAge,
    required double maxHr,
    required double avgRhr,
    required double avgHrv,
    required double sleepConsistency, // 0.0 to 1.0 (SRI)
    required double avgDailySteps,
    String sex = 'm',
  }) {
    final cleanSex = (sex.toLowerCase() == 'f') ? 'f' : 'm';
    final isFemale = cleanSex == 'f';

    // 1. VO2 Max Modifier (40% weight)
    // Uth–Sørensen–Overgaard–Pedersen formula: VO2max = 15.3 * (HRmax / HRrest)
    final double vo2MaxEst = (15.3 * (maxHr / avgRhr)).clamp(15.0, 85.0);

    // Sex-stratified normative VO2 max benchmark:
    // Males: ~45.0 ml/kg/min at 30, declining ~0.45 per year.
    // Females: ~37.5 ml/kg/min at 30, declining ~0.35 per year.
    final double expectedVo2Max = isFemale
        ? (37.5 - (chronologicalAge - 30) * 0.35).clamp(18.0, 55.0)
        : (45.0 - (chronologicalAge - 30) * 0.45).clamp(20.0, 65.0);

    final double vo2Diff = vo2MaxEst - expectedVo2Max;
    // Every 3.0 ml/kg above expected = -1 year rejuvenation
    double vo2Modifier = -(vo2Diff / 3.0);
    vo2Modifier = vo2Modifier.clamp(-5.0, 5.0);

    final String vo2Insight;
    if (vo2Modifier <= -1.0) {
      vo2Insight = 'Aerobic fitness (${vo2MaxEst.toStringAsFixed(1)} ml/kg) exceeds age-matched ${isFemale ? "female" : "male"} peers, shedding ${(-vo2Modifier).toStringAsFixed(1)} yrs.';
    } else if (vo2Modifier >= 1.0) {
      vo2Insight = 'Aerobic endurance (${vo2MaxEst.toStringAsFixed(1)} ml/kg) trails peers, adding ${vo2Modifier.toStringAsFixed(1)} yrs of biological load.';
    } else {
      vo2Insight = 'Aerobic capacity (${vo2MaxEst.toStringAsFixed(1)} ml/kg) aligns with your chronological age benchmark.';
    }

    // 2. Overnight HRV Modifier (30% weight)
    // Sex-stratified expected RMSSD:
    // Males: ~78.0 ms at 20, drops ~1.1 ms/yr.
    // Females: ~72.0 ms at 20, drops ~1.0 ms/yr.
    final double expectedHrv = isFemale
        ? (72.0 - (chronologicalAge - 20) * 1.0).clamp(20.0, 100.0)
        : (78.0 - (chronologicalAge - 20) * 1.1).clamp(20.0, 110.0);

    final double hrvDiff = avgHrv - expectedHrv;
    // Every 5 ms above expected = -1 year
    double hrvModifier = -(hrvDiff / 5.0);
    hrvModifier = hrvModifier.clamp(-4.0, 4.0);

    final String hrvInsight;
    if (hrvModifier <= -1.0) {
      hrvInsight = 'Overnight autonomic recovery (${avgHrv.toStringAsFixed(0)} ms) shows youthful parasympathetic resilience (-${(-hrvModifier).toStringAsFixed(1)} yrs).';
    } else if (hrvModifier >= 1.0) {
      hrvInsight = 'Overnight HRV (${avgHrv.toStringAsFixed(0)} ms) reflects elevated chronic fatigue or stress (+${hrvModifier.toStringAsFixed(1)} yrs).';
    } else {
      hrvInsight = 'HRV (${avgHrv.toStringAsFixed(0)} ms) reflects balanced autonomic recovery for your age.';
    }

    // 3. Resting Heart Rate Modifier (15% weight)
    // Stratified threshold (women typically have 2-3 bpm higher baseline due to ventricular volume)
    double rhrModifier = 0.0;
    final double rhrAthleticThreshold = isFemale ? 53.0 : 50.0;
    final double rhrGoodThreshold = isFemale ? 62.0 : 59.0;
    final double rhrHighThreshold = isFemale ? 77.0 : 74.0;
    final double rhrElevatedThreshold = isFemale ? 86.0 : 83.0;

    if (avgRhr < rhrAthleticThreshold) {
      rhrModifier = -2.0;
    } else if (avgRhr < rhrGoodThreshold) {
      rhrModifier = -1.0;
    } else if (avgRhr > rhrElevatedThreshold) {
      rhrModifier = 2.0;
    } else if (avgRhr > rhrHighThreshold) {
      rhrModifier = 1.0;
    }

    final String heartInsight;
    if (rhrModifier < 0) {
      heartInsight = 'Resting pulse (${avgRhr.toStringAsFixed(0)} bpm) indicates efficient stroke volume and cardiovascular health (-${(-rhrModifier).toStringAsFixed(0)} yrs).';
    } else if (rhrModifier > 0) {
      heartInsight = 'Elevated resting pulse (${avgRhr.toStringAsFixed(0)} bpm) puts extra cardiovascular demands (+${rhrModifier.toStringAsFixed(0)} yrs).';
    } else {
      heartInsight = 'Resting heart rate (${avgRhr.toStringAsFixed(0)} bpm) is in the optimal normal range.';
    }

    // 4. Lifestyle Modifier: Sleep Consistency & Steps (15% weight)
    double lifestyleModifier = 0.0;
    final tips = <String>[];

    // Sleep Consistency (SRI)
    if (sleepConsistency >= 0.85) {
      lifestyleModifier -= 1.0;
    } else if (sleepConsistency <= 0.65) {
      lifestyleModifier += 1.0;
      tips.add('Anchor your bedtime within a consistent 30-min window (Sleep Regularity >80%) to shed ~0.8 biological yrs.');
    } else {
      tips.add('Aim for >80% sleep consistency to earn extra cellular rejuvenation credits.');
    }

    // Daily Steps
    if (avgDailySteps >= 10000) {
      lifestyleModifier -= 1.0;
    } else if (avgDailySteps >= 7500) {
      lifestyleModifier -= 0.5;
    } else if (avgDailySteps <= 4500) {
      lifestyleModifier += 1.0;
      tips.add('Increase daily movement to 8,000–10,000 steps to reverse up to 1.0 biological year.');
    } else {
      tips.add('Reaching 10,000 steps daily boosts metabolic efficiency and reduces vascular aging.');
    }

    lifestyleModifier = lifestyleModifier.clamp(-3.0, 3.0);

    final String lifestyleInsight;
    if (lifestyleModifier < 0) {
      lifestyleInsight = 'Consistent circadian rhythm and healthy daily activity level (-${(-lifestyleModifier).toStringAsFixed(1)} yrs).';
    } else if (lifestyleModifier > 0) {
      lifestyleInsight = 'Irregular sleep schedule or low movement adds biological wear (+${lifestyleModifier.toStringAsFixed(1)} yrs).';
    } else {
      lifestyleInsight = 'Moderate daily movement and acceptable sleep stability.';
    }

    // VO2/cardio tip if VO2 is dragging score down
    if (vo2Modifier >= 0.0) {
      tips.add('Incorporate 1–2 Zone 4/5 HIIT or tempo sessions weekly to raise VO₂ Max and accelerate cardiovascular youth.');
    }
    // RHR tip if elevated
    if (rhrModifier > 0.0) {
      tips.add('Prioritize low-intensity Zone 2 cardio (30–45 min) to lower resting pulse and boost mitochondrial density.');
    }
    if (tips.isEmpty) {
      tips.add('Outstanding biological markers across all pillars! Maintain your sleep rhythm, activity, and cardiovascular conditioning.');
    }

    final double totalBiologicalAge = (chronologicalAge +
        vo2Modifier +
        hrvModifier +
        rhrModifier +
        lifestyleModifier).clamp(16.0, 95.0);

    final double ageDifference = totalBiologicalAge - chronologicalAge;

    return BiologicalAgeResult(
      chronologicalAge: chronologicalAge,
      biologicalAge: totalBiologicalAge,
      ageDifference: ageDifference,
      vo2Modifier: vo2Modifier,
      hrvModifier: hrvModifier,
      rhrModifier: rhrModifier,
      lifestyleModifier: lifestyleModifier,
      vo2MaxEst: vo2MaxEst,
      sex: cleanSex,
      heartInsight: heartInsight,
      hrvInsight: hrvInsight,
      vo2Insight: vo2Insight,
      lifestyleInsight: lifestyleInsight,
      actionableTips: tips,
    );
  }
}
