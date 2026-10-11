/// Next-Gen Real-Time Stress Monitor
/// Calculates psychological/physiological stress (0.0 to 3.0)
/// by analyzing HR/HRV against baselines, strictly filtering out physical activity.

class StressResult {
  final double stressScore; // 0.0 to 3.0
  final String category; // Low, Medium, High
  final bool
      isExercise; // If true, stress is 0 because user is physically active

  StressResult({
    required this.stressScore,
    required this.category,
    required this.isExercise,
  });

  @override
  String toString() {
    if (isExercise) return 'Stress: N/A (Exercising)';
    return 'Stress: ${stressScore.toStringAsFixed(2)} ($category)';
  }
}

class StressMonitorEngine {
  /// Calculates the real-time stress score (0.0 to 3.0).
  /// [currentHr] The user's heart rate in the current minute.
  /// [baselineRhr] The user's resting heart rate (from sleep).
  /// [currentHrv] (Optional) The user's RMSSD in the current minute if available.
  /// [baselineHrv] The user's baseline HRV.
  /// [activityLevel] Accelerometer magnitude or activity classification (0.0 = still, 1.0 = intense movement).
  static StressResult calculateStress({
    required double currentHr,
    required double baselineRhr,
    double? currentHrv,
    double? baselineHrv,
    required double activityLevel,
  }) {
    // 1. Filter out physical activity
    // If the user is moving significantly (e.g., walking, running), elevated HR
    // is due to mechanical work, not psychological stress.
    if (activityLevel > 0.3) {
      return StressResult(
        stressScore: 0.0,
        category: 'Active',
        isExercise: true,
      );
    }

    // 2. HR Component (Primary driver)
    // How elevated is the current HR compared to the absolute resting baseline?
    // E.g., RHR = 50. Current = 85. Ratio = 1.7.
    double hrRatio = currentHr / baselineRhr;

    // Normal awake HR is usually 1.2x to 1.5x RHR.
    // Anything above 1.5x while sitting still is physiological stress.
    double hrStress = 0.0;
    if (hrRatio > 1.2) {
      // Scale it so that 2.0x RHR gives max HR stress component
      hrStress = ((hrRatio - 1.2) / 0.8) * 3.0;
    }

    // 3. HRV Component (Secondary driver, if available)
    double hrvStress = 0.0;
    if (currentHrv != null && baselineHrv != null && baselineHrv > 0) {
      // Lower HRV means higher sympathetic nervous system (stress) activity.
      double hrvRatio = currentHrv / baselineHrv;

      if (hrvRatio < 0.9) {
        // If HRV is dropped by half (0.5x), that's max stress
        hrvStress = ((0.9 - hrvRatio) / 0.4) * 3.0;
      }
    }

    // 4. Composite Score (0.0 to 3.0 scale)
    double finalScore = 0.0;
    if (currentHrv != null) {
      // Blend HR (60%) and HRV (40%) if both are available
      finalScore = (hrStress * 0.6) + (hrvStress * 0.4);
    } else {
      // Rely purely on HR if HRV isn't calculated this minute
      finalScore = hrStress;
    }

    // Clamp between 0.0 and 3.0
    finalScore = finalScore.clamp(0.0, 3.0);

    // 5. Categorization matching Whoop's UI
    String cat = 'Low';
    if (finalScore >= 2.0) {
      cat = 'High';
    } else if (finalScore >= 1.0) {
      cat = 'Medium';
    }

    return StressResult(
      stressScore: finalScore,
      category: cat,
      isExercise: false,
    );
  }
}
