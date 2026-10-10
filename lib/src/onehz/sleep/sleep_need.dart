/// Next-Gen Sleep Planner (Need & Debt)
/// Calculates the total sleep required based on baseline, strain, and accumulated debt.

import 'dart:math';

class SleepNeedResult {
  final double baselineMinutes;
  final double strainMinutes;
  final double debtMinutes;
  final double totalNeedMinutes;
  final double napCreditMinutes;

  SleepNeedResult({
    required this.baselineMinutes,
    required this.strainMinutes,
    required this.debtMinutes,
    required this.totalNeedMinutes,
    required this.napCreditMinutes,
  });

  @override
  String toString() {
    return 'Total Sleep Need: ${totalNeedMinutes.toStringAsFixed(0)} min '
        '(Base: $baselineMinutes, Strain: ${strainMinutes.toStringAsFixed(0)}, '
        'Debt: ${debtMinutes.toStringAsFixed(0)}, NapCredit: -$napCreditMinutes)';
  }
}

class SleepNeedCalculator {
  /// The absolute maximum sleep debt that can be carried over (e.g., 2 hours).
  static const double maxDebtMinutes = 120.0;
  
  /// Standard adult baseline (7 hours 40 minutes).
  static const double standardBaseline = 460.0;

  /// Calculates the sleep need for TONIGHT.
  /// 
  /// [strain] The day's cardiovascular strain (0.0 to 21.0).
  /// [previousDebt] The sleep debt carried over from yesterday (min).
  /// [previousActualSleep] How much the user actually slept last night (min).
  /// [previousTotalNeed] How much the user needed to sleep last night (min).
  /// [napMinutes] Any sleep taken during the day today (min).
  static SleepNeedResult calculate({
    required double strain,
    required double previousTotalNeed,
    required double previousActualSleep,
    double napMinutes = 0.0,
    double customBaseline = standardBaseline,
  }) {
    // 1. Baseline
    final double baseline = customBaseline;

    // 2. Strain Need (Exponential curve maxing out around ~110 minutes at Strain 21)
    // Strain 10 -> ~25 mins
    // Strain 15 -> ~56 mins
    // Strain 21 -> ~110 mins
    final double safeStrain = strain.clamp(0.0, 21.0);
    final double strainNeed = pow(safeStrain / 21.0, 1.8) * 110.0;

    // 3. Sleep Debt Calculation
    // Debt = What you needed yesterday - What you actually got
    double newDebt = previousTotalNeed - previousActualSleep;
    
    // You cannot bank sleep (debt doesn't go below 0)
    if (newDebt < 0) newDebt = 0;
    
    // Debt caps out (you can only physiologically recover so much in one night)
    if (newDebt > maxDebtMinutes) newDebt = maxDebtMinutes;

    // 4. Total Need
    double totalNeed = baseline + strainNeed + newDebt;

    // 5. Nap Credit
    // Naps directly subtract from tonight's total need.
    totalNeed -= napMinutes;

    // Floor the need so it doesn't go below baseline (unless naps cover it)
    if (totalNeed < 0) totalNeed = 0;

    return SleepNeedResult(
      baselineMinutes: baseline,
      strainMinutes: strainNeed,
      debtMinutes: newDebt,
      totalNeedMinutes: totalNeed,
      napCreditMinutes: napMinutes,
    );
  }
}
