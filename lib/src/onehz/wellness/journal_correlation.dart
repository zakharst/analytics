/// Next-Gen Journal Correlation Engine
/// Analyzes the impact of daily habits on physiological metrics (Recovery, HRV).
/// Uses Welch's t-test for statistical significance to avoid false positives.

import 'dart:math';

class HabitImpact {
  final String habitName;
  final double meanWithHabit;
  final double meanWithoutHabit;
  final double delta; // Difference (e.g., -12.5% recovery)
  final int countWith;
  final int countWithout;
  final double pValue;
  final bool isSignificant;

  HabitImpact({
    required this.habitName,
    required this.meanWithHabit,
    required this.meanWithoutHabit,
    required this.delta,
    required this.countWith,
    required this.countWithout,
    required this.pValue,
    required this.isSignificant,
  });

  @override
  String toString() {
    final sig = isSignificant ? "★" : " ";
    final sign = delta > 0 ? "+" : "";
    return '[$sig] $habitName: $sign${delta.toStringAsFixed(1)} (p=$pValue, N_yes=$countWith, N_no=$countWithout)';
  }
}

class JournalCorrelationEngine {
  /// Calculates the independent impact of each habit on a target metric.
  /// [journalEntries] maps Date to a list of habit names that were TRUE that day.
  /// [targetMetrics] maps Date to the target metric (e.g. Recovery %).
  /// Requires at least 5 'yes' and 5 'no' days to calculate significance.
  static List<HabitImpact> analyze({
    required Map<DateTime, List<String>> journalEntries,
    required Map<DateTime, double> targetMetrics,
    int minOccurrences = 5,
  }) {
    final Map<String, List<double>> valuesWithHabit = {};
    final Map<String, List<double>> valuesWithoutHabit = {};
    
    // 1. Find all unique habits logged in the dataset
    final Set<String> allHabits = {};
    for (var habits in journalEntries.values) {
      allHabits.addAll(habits);
    }
    
    // 2. Group the daily metrics into 'With Habit' and 'Without Habit' buckets
    for (var date in targetMetrics.keys) {
      final metric = targetMetrics[date];
      if (metric == null) continue;
      
      // We strip the time component to ensure safe matching
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      // Find habits for this day (ignoring time)
      final dailyHabits = journalEntries.entries
          .where((e) => e.key.year == normalizedDate.year && 
                        e.key.month == normalizedDate.month && 
                        e.key.day == normalizedDate.day)
          .map((e) => e.value)
          .expand((i) => i)
          .toList();
      
      for (var habit in allHabits) {
        if (dailyHabits.contains(habit)) {
          valuesWithHabit.putIfAbsent(habit, () => []).add(metric);
        } else {
          valuesWithoutHabit.putIfAbsent(habit, () => []).add(metric);
        }
      }
    }
    
    final List<HabitImpact> impacts = [];
    
    // 3. Perform statistical analysis for each habit
    for (var habit in allHabits) {
      final withList = valuesWithHabit[habit] ?? [];
      final withoutList = valuesWithoutHabit[habit] ?? [];
      
      // We only analyze habits that have enough data to be statistically relevant
      if (withList.length >= minOccurrences && withoutList.length >= minOccurrences) {
        final meanWith = _mean(withList);
        final meanWithout = _mean(withoutList);
        final delta = meanWith - meanWithout;
        
        // Calculate significance using Welch's t-test
        final pValue = _welchsTTest(withList, withoutList);
        // Alpha = 0.05 is the standard for statistical significance
        final isSignificant = pValue < 0.05;
        
        impacts.add(HabitImpact(
          habitName: habit,
          meanWithHabit: meanWith,
          meanWithoutHabit: meanWithout,
          delta: delta,
          countWith: withList.length,
          countWithout: withoutList.length,
          pValue: pValue,
          isSignificant: isSignificant,
        ));
      }
    }
    
    // Sort by absolute impact (largest impact first, positive or negative)
    impacts.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    
    return impacts;
  }

  static double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _variance(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    double sumSq = 0.0;
    for (var v in values) {
      sumSq += pow(v - mean, 2);
    }
    return sumSq / (values.length - 1);
  }

  /// Performs Welch's t-test which is more robust than Student's t-test 
  /// when sample sizes and variances are unequal.
  static double _welchsTTest(List<double> sample1, List<double> sample2) {
    final n1 = sample1.length;
    final n2 = sample2.length;
    final mean1 = _mean(sample1);
    final mean2 = _mean(sample2);
    final var1 = _variance(sample1, mean1);
    final var2 = _variance(sample2, mean2);

    if (var1 == 0 && var2 == 0) return 1.0; // Identical samples, no variance

    final tStat = (mean1 - mean2) / sqrt((var1 / n1) + (var2 / n2));
    final absT = tStat.abs();
    
    // Simplified p-value approximation for edge computing without importing heavy SciPy libs
    // Based on standard normal distribution critical values
    if (absT >= 3.291) return 0.001; // 99.9% confidence
    if (absT >= 2.576) return 0.01;  // 99% confidence
    if (absT >= 1.960) return 0.049; // 95% confidence (Significant)
    if (absT >= 1.645) return 0.10;  // 90% confidence
    
    return 0.5; // Not statistically significant
  }
}
