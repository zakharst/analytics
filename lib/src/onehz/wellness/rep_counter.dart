/// Next-Gen Bodyweight Rep Counter
/// Analyzes 100Hz IMU data to detect cyclical movements (Squats, Crunches, etc.)

import 'dart:math';

class RepCounterResult {
  final int reps;
  final double averageIntensity;
  final double timeUnderTensionSeconds;

  RepCounterResult({
    required this.reps,
    required this.averageIntensity,
    required this.timeUnderTensionSeconds,
  });

  @override
  String toString() {
    return 'Detected $reps reps. TUT: ${timeUnderTensionSeconds.toStringAsFixed(1)}s, Intensity: ${averageIntensity.toStringAsFixed(2)}g';
  }
}

class Vector3 {
  final double x, y, z;
  Vector3(this.x, this.y, this.z);

  double get magnitude => sqrt(x * x + y * y + z * z);
}

class RepCounterEngine {
  /// Basic peak detection algorithm for cyclical bodyweight exercises.
  /// [imuData] is a list of 3-axis accelerometer readings at 100Hz.
  /// [minTimeBetweenRepsMs] prevents double-counting the up/down phase.
  static RepCounterResult countReps({
    required List<Vector3> imuData,
    int sampleRateHz = 100,
    double noiseThresholdG = 1.15, // >1G (gravity) to count as a movement peak
    int minTimeBetweenRepsMs = 800, // min 0.8 seconds per rep
  }) {
    if (imuData.isEmpty) {
      return RepCounterResult(reps: 0, averageIntensity: 0, timeUnderTensionSeconds: 0);
    }

    final int minSamplesBetweenReps = (sampleRateHz * (minTimeBetweenRepsMs / 1000.0)).round();
    
    // 1. Calculate magnitude vector (removes orientation dependence)
    List<double> magnitudes = imuData.map((v) => v.magnitude).toList();

    // 2. Apply a simple Low-Pass Filter (Moving Average) to smooth out high-frequency noise
    final int windowSize = 10; // 0.1 second window at 100Hz
    List<double> smoothed = [];
    for (int i = 0; i < magnitudes.length; i++) {
      int start = max(0, i - windowSize ~/ 2);
      int end = min(magnitudes.length, i + windowSize ~/ 2);
      double sum = 0;
      for (int j = start; j < end; j++) {
        sum += magnitudes[j];
      }
      smoothed.add(sum / (end - start));
    }

    // 3. Peak Detection
    int repCount = 0;
    int lastPeakIndex = -minSamplesBetweenReps; // Allow peak at index 0
    double totalIntensity = 0.0;
    int activeSamples = 0;

    for (int i = 1; i < smoothed.length - 1; i++) {
      final double current = smoothed[i];
      
      // Calculate active intensity (above baseline gravity 1.0g)
      if (current > 1.05) {
        totalIntensity += (current - 1.0);
        activeSamples++;
      }

      // Check if it's a local maximum and above threshold
      if (current > noiseThresholdG && current > smoothed[i - 1] && current > smoothed[i + 1]) {
        // Check cooldown period
        if (i - lastPeakIndex >= minSamplesBetweenReps) {
          repCount++;
          lastPeakIndex = i;
        }
      }
    }

    // 4. Calculate Time Under Tension (TUT)
    // How many seconds was the user actually moving?
    final double tut = activeSamples / sampleRateHz;
    final double avgIntensity = activeSamples > 0 ? (totalIntensity / activeSamples) : 0.0;

    return RepCounterResult(
      reps: repCount,
      averageIntensity: avgIntensity,
      timeUnderTensionSeconds: tut,
    );
  }
}
