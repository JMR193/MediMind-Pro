import 'dart:math' as math;
import '../../domain/models/medication.dart';
import '../../domain/models/medication_log.dart';

enum AdherenceRiskLevel {
  low,      // 85%+ PDC, stable habit
  moderate, // 70-84% PDC, occasional drift
  high,     // 50-69% PDC, frequent missed doses
  critical, // <50% PDC, high risk of therapeutic failure
}

class DayRiskFactor {
  final int weekday; // 1 = Mon ... 7 = Sun
  final String dayName;
  final double adherenceRate; // 0.0 to 100.0
  final bool isHighRiskDropoff;

  const DayRiskFactor({
    required this.weekday,
    required this.dayName,
    required this.adherenceRate,
    required this.isHighRiskDropoff,
  });
}

class AdaptiveTimingRecommendation {
  final Medication medication;
  final String currentScheduledTime;
  final String proposedAdaptiveTime;
  final int meanDriftMinutes;
  final double varianceStandardDeviation;
  final String behavioralRationale;

  const AdaptiveTimingRecommendation({
    required this.medication,
    required this.currentScheduledTime,
    required this.proposedAdaptiveTime,
    required this.meanDriftMinutes,
    required this.varianceStandardDeviation,
    required this.behavioralRationale,
  });
}

class CognitiveLatencyAnomaly {
  final bool isAnomalyDetected;
  final double currentEmaLatencyMinutes;
  final double baselineLatencyMinutes;
  final double zScore;
  final String alertMessage;
  final String recommendedIntervention;

  const CognitiveLatencyAnomaly({
    required this.isAnomalyDetected,
    required this.currentEmaLatencyMinutes,
    required this.baselineLatencyMinutes,
    required this.zScore,
    required this.alertMessage,
    required this.recommendedIntervention,
  });
}

/// Behavioral Machine Learning Engine (Pseudo-AI Layer)
/// Analyzes longitudinal patient telemetry to discover habits, predict adherence risk,
/// adapt alarm timing, and detect cognitive drift anomalies.
class BehavioralMlEngine {
  /// Evaluates multi-dimensional adherence risk across days of week and times of day
  static AdherenceRiskProfile analyzeAdherenceRisk({
    required List<Medication> medications,
    required List<MedicationLog> logs,
    int observationDays = 30,
  }) {
    if (medications.isEmpty || logs.isEmpty) {
      return AdherenceRiskProfile(
        overallRisk: AdherenceRiskLevel.low,
        predictedPdcPercentage: 100.0,
        dayRiskFactors: _generateDefaultDayRisks(),
        highestRiskDay: 'None',
        highestRiskTimeOfDay: 'None',
        clinicalSummary: 'Insufficient baseline data. Continue logging doses to train predictive models.',
      );
    }

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: observationDays));
    final relevantLogs = logs.where((l) => l.timestamp.isAfter(cutoff)).toList();

    // 1. Group logs by day of week (1 = Monday ... 7 = Sunday)
    final Map<int, List<MedicationLog>> logsByDay = {
      for (int i = 1; i <= 7; i++) i: [],
    };

    for (final log in relevantLogs) {
      logsByDay[log.timestamp.weekday]?.add(log);
    }

    final dayFactors = <DayRiskFactor>[];
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    int worstDayIdx = 1;
    double lowestRate = 100.0;

    for (int d = 1; d <= 7; d++) {
      final dayLogs = logsByDay[d] ?? [];
      final taken = dayLogs.where((l) => l.status == LogStatus.taken).length;
      final rate = dayLogs.isNotEmpty ? (taken / dayLogs.length) * 100.0 : 100.0;

      if (rate < lowestRate) {
        lowestRate = rate;
        worstDayIdx = d;
      }

      dayFactors.add(
        DayRiskFactor(
          weekday: d,
          dayName: dayNames[d - 1],
          adherenceRate: rate,
          isHighRiskDropoff: rate < 75.0,
        ),
      );
    }

    // 2. Compute Overall Predicted PDC
    final totalTaken = relevantLogs.where((l) => l.status == LogStatus.taken).length;
    final pdc = relevantLogs.isNotEmpty ? (totalTaken / relevantLogs.length) * 100.0 : 100.0;

    AdherenceRiskLevel level = AdherenceRiskLevel.low;
    if (pdc < 50.0) {
      level = AdherenceRiskLevel.critical;
    } else if (pdc < 70.0) {
      level = AdherenceRiskLevel.high;
    } else if (pdc < 85.0) {
      level = AdherenceRiskLevel.moderate;
    }

    // 3. Time of day breakdown (Morning vs Afternoon vs Evening vs Night)
    final morningLogs = relevantLogs.where((l) => l.timestamp.hour >= 5 && l.timestamp.hour < 11).toList();
    final eveningLogs = relevantLogs.where((l) => l.timestamp.hour >= 17 && l.timestamp.hour < 22).toList();

    final morningRate = morningLogs.isNotEmpty
        ? (morningLogs.where((l) => l.status == LogStatus.taken).length / morningLogs.length) * 100
        : 100.0;
    final eveningRate = eveningLogs.isNotEmpty
        ? (eveningLogs.where((l) => l.status == LogStatus.taken).length / eveningLogs.length) * 100
        : 100.0;

    final worstTime = morningRate < eveningRate ? 'Morning (06:00–11:00)' : 'Evening (17:00–22:00)';

    return AdherenceRiskProfile(
      overallRisk: level,
      predictedPdcPercentage: pdc,
      dayRiskFactors: dayFactors,
      highestRiskDay: dayNames[worstDayIdx - 1],
      highestRiskTimeOfDay: worstTime,
      clinicalSummary: level == AdherenceRiskLevel.low
          ? 'Excellent adherence profile. Habit formation is strong with minimal variance.'
          : 'Elevated drop-off observed on ${dayNames[worstDayIdx - 1]}s and during $worstTime. Recommended targeted push reminders or caregiver nudges.',
    );
  }

  /// Discovers actual patient waking and meal routines to suggest smart adaptive notification shifts
  static List<AdaptiveTimingRecommendation> calculateAdaptiveSuggestions({
    required List<Medication> medications,
    required List<MedicationLog> logs,
  }) {
    final recommendations = <AdaptiveTimingRecommendation>[];
    final takenLogs = logs.where((l) => l.status == LogStatus.taken).toList();

    for (final med in medications) {
      final medLogs = takenLogs.where((l) => l.medicationId == med.id).toList();
      if (medLogs.length < 5) continue; // Need minimum 5 logs for statistical significance

      // Analyze drift for the primary scheduled time
      final scheduledStr = med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '08:00';
      final parts = scheduledStr.split(':');
      final schedH = int.tryParse(parts[0]) ?? 8;
      final schedM = int.tryParse(parts[1]) ?? 0;
      final schedMinutesFromMidnight = schedH * 60 + schedM;

      final driftList = <int>[];
      for (final log in medLogs) {
        final actualMinutes = log.timestamp.hour * 60 + log.timestamp.minute;
        final drift = actualMinutes - schedMinutesFromMidnight;
        // Filter out extreme outliers (> 4 hours)
        if (drift.abs() <= 240) {
          driftList.add(drift);
        }
      }

      if (driftList.length < 5) continue;

      // Compute Mean Drift and Standard Deviation
      final meanDrift = driftList.reduce((a, b) => a + b) / driftList.length;
      final variance = driftList.map((d) => math.pow(d - meanDrift, 2)).reduce((a, b) => a + b) / driftList.length;
      final stdDev = math.sqrt(variance);

      // If mean drift is consistently positive or negative (>= 25 min) with low standard deviation (<= 25 min),
      // it indicates the patient has a stable physiological habit that differs from the rigid schedule!
      if (meanDrift.abs() >= 25 && stdDev <= 30) {
        final proposedMinutes = (schedMinutesFromMidnight + meanDrift.round()).clamp(0, 1439);
        final propH = (proposedMinutes ~/ 60).toString().padLeft(2, '0');
        final propM = (proposedMinutes % 60).toString().padLeft(2, '0');
        final proposedTimeStr = '$propH:$propM';

        recommendations.add(
          AdaptiveTimingRecommendation(
            medication: med,
            currentScheduledTime: scheduledStr,
            proposedAdaptiveTime: proposedTimeStr,
            meanDriftMinutes: meanDrift.round(),
            varianceStandardDeviation: stdDev,
            behavioralRationale: meanDrift > 0
                ? 'Patient consistently takes this dose ${meanDrift.round()} minutes later ($proposedTimeStr) with high consistency (±${stdDev.round()}m). Shifting the reminder will eliminate false alerts.'
                : 'Patient consistently takes this dose ${meanDrift.abs().round()} minutes earlier ($proposedTimeStr). Synchronize alarm to preserve patient autonomy.',
          ),
        );
      }
    }

    return recommendations;
  }

  /// Detects cognitive drift or treatment fatigue using Exponential Moving Average (EMA) of response latency
  static CognitiveLatencyAnomaly detectCognitiveDrift({
    required List<MedicationLog> logs,
  }) {
    final takenLogs = logs.where((l) => l.status == LogStatus.taken).toList();
    if (takenLogs.length < 8) {
      return const CognitiveLatencyAnomaly(
        isAnomalyDetected: false,
        currentEmaLatencyMinutes: 0.0,
        baselineLatencyMinutes: 0.0,
        zScore: 0.0,
        alertMessage: 'Baseline latency model calibrating.',
        recommendedIntervention: 'Continue normal dose tracking.',
      );
    }

    // Sort chronologically
    takenLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate response latencies: minutes from scheduled time
    final latencies = <double>[];
    for (final log in takenLogs) {
      final schedParts = log.scheduledTime.split(':');
      final sH = int.tryParse(schedParts[0]) ?? 8;
      final sM = int.tryParse(schedParts.length > 1 ? schedParts[1].split(' ')[0] : '0') ?? 0;
      final schedMinutes = sH * 60 + sM;
      final actualMinutes = log.timestamp.hour * 60 + log.timestamp.minute;

      final diff = (actualMinutes - schedMinutes).abs().toDouble();
      latencies.add(diff.clamp(0.0, 360.0));
    }

    // Baseline calculation (first 60% of data) vs Recent (last 40%)
    final splitIdx = (latencies.length * 0.6).toInt();
    final baseline = latencies.sublist(0, splitIdx);
    final recent = latencies.sublist(splitIdx);

    final baselineMean = baseline.reduce((a, b) => a + b) / baseline.length;
    final baselineVariance = baseline.map((l) => math.pow(l - baselineMean, 2)).reduce((a, b) => a + b) / baseline.length;
    final baselineStdDev = math.sqrt(baselineVariance).clamp(5.0, 120.0);

    // Exponential Moving Average (EMA) on recent latencies with alpha = 0.35
    double ema = baselineMean;
    for (final l in recent) {
      ema = 0.35 * l + (1 - 0.35) * ema;
    }

    final zScore = (ema - baselineMean) / baselineStdDev;

    // Anomaly detected if recent latency has surged by more than 2.0 standard deviations
    final isAnomaly = zScore >= 2.0 && ema >= 45.0;

    return CognitiveLatencyAnomaly(
      isAnomalyDetected: isAnomaly,
      currentEmaLatencyMinutes: ema,
      baselineLatencyMinutes: baselineMean,
      zScore: zScore,
      alertMessage: isAnomaly
          ? 'Significant Cognitive Response Drift Detected (Z-Score: ${zScore.toStringAsFixed(1)}). Average intake response delayed from ${baselineMean.round()}m to ${ema.round()}m.'
          : 'Intake response latency is stable within normal limits (EMA: ${ema.round()}m vs Baseline: ${baselineMean.round()}m).',
      recommendedIntervention: isAnomaly
          ? 'Notify primary caregiver. Screen for medication side-effect fatigue, physical difficulty accessing pill containers, or early mild cognitive impairment.'
          : 'Maintain current reminder strategy.',
    );
  }

  static List<DayRiskFactor> _generateDefaultDayRisks() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return [
      for (int i = 1; i <= 7; i++)
        DayRiskFactor(
          weekday: i,
          dayName: days[i - 1],
          adherenceRate: 100.0,
          isHighRiskDropoff: false,
        ),
    ];
  }
}

class AdherenceRiskProfile {
  final AdherenceRiskLevel overallRisk;
  final double predictedPdcPercentage;
  final List<DayRiskFactor> dayRiskFactors;
  final String highestRiskDay;
  final String highestRiskTimeOfDay;
  final String clinicalSummary;

  const AdherenceRiskProfile({
    required this.overallRisk,
    required this.predictedPdcPercentage,
    required this.dayRiskFactors,
    required this.highestRiskDay,
    required this.highestRiskTimeOfDay,
    required this.clinicalSummary,
  });
}
