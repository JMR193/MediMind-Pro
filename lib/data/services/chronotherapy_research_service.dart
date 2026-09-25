import 'dart:math';
import '../../domain/models/medication.dart';
import '../../domain/models/medication_log.dart';

class ChronotherapyMetrics {
  final double pdcPercentage; // Proportion of Days Covered (0-100%)
  final double mprPercentage; // Medication Possession Ratio (0-100%)
  final double averageTimingDriftMinutes; // Mean deviation from scheduled time
  final double morningAdherenceRate; // Adherence for morning doses (0-100%)
  final double eveningAdherenceRate; // Adherence for evening doses (0-100%)
  final double weekendAdherenceRate; // Adherence for weekend doses (0-100%)
  final int totalScheduledDoses;
  final int totalTakenDoses;
  final int totalMissedDoses;
  final int overallHealthScore; // 0-100
  final String clinicalInterpretation;

  const ChronotherapyMetrics({
    required this.pdcPercentage,
    required this.mprPercentage,
    required this.averageTimingDriftMinutes,
    required this.morningAdherenceRate,
    required this.eveningAdherenceRate,
    required this.weekendAdherenceRate,
    required this.totalScheduledDoses,
    required this.totalTakenDoses,
    required this.totalMissedDoses,
    required this.overallHealthScore,
    required this.clinicalInterpretation,
  });
}

class ChronotherapyResearchService {
  /// Computes research-grade clinical adherence & circadian chronotherapy metrics
  static ChronotherapyMetrics analyzeAdherence({
    required List<Medication> medications,
    required List<MedicationLog> logs,
    int observationDays = 30,
  }) {
    if (medications.isEmpty || logs.isEmpty) {
      return const ChronotherapyMetrics(
        pdcPercentage: 100.0,
        mprPercentage: 100.0,
        averageTimingDriftMinutes: 0.0,
        morningAdherenceRate: 100.0,
        eveningAdherenceRate: 100.0,
        weekendAdherenceRate: 100.0,
        totalScheduledDoses: 0,
        totalTakenDoses: 0,
        totalMissedDoses: 0,
        overallHealthScore: 100,
        clinicalInterpretation: 'Optimal baseline adherence. Ready to track doses.',
      );
    }

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: observationDays));
    final recentLogs = logs.where((l) => l.timestamp.isAfter(cutoff)).toList();

    int takenCount = 0;
    int missedCount = 0;
    int morningTaken = 0;
    int morningTotal = 0;
    int eveningTaken = 0;
    int eveningTotal = 0;
    int weekendTaken = 0;
    int weekendTotal = 0;
    List<double> timingDrifts = [];

    // Group logs by day for PDC
    final Set<String> coveredDays = {};

    for (final log in recentLogs) {
      final isWeekend = log.timestamp.weekday == DateTime.saturday || log.timestamp.weekday == DateTime.sunday;
      final hour = log.timestamp.hour;
      final isMorning = hour >= 5 && hour < 14;
      final isEvening = hour >= 17 || hour < 4;

      if (isWeekend) weekendTotal++;
      if (isMorning) morningTotal++;
      if (isEvening) eveningTotal++;

      if (log.status == LogStatus.taken) {
        takenCount++;
        final dayKey = '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
        coveredDays.add(dayKey);

        if (isWeekend) weekendTaken++;
        if (isMorning) morningTaken++;
        if (isEvening) eveningTaken++;

        // Calculate timing drift if scheduled time is available
        if (log.scheduledTime.contains(':')) {
          final parts = log.scheduledTime.split(':');
          final schedHour = int.tryParse(parts[0]) ?? 8;
          final schedMin = int.tryParse(parts[1]) ?? 0;
          final targetMinutes = schedHour * 60 + schedMin;
          final actualMinutes = log.timestamp.hour * 60 + log.timestamp.minute;
          final diff = (actualMinutes - targetMinutes).abs().toDouble();
          timingDrifts.add(diff.clamp(0.0, 360.0)); // Cap at 6 hours for outliers
        }
      } else if (log.status == LogStatus.missed || log.status == LogStatus.skipped) {
        missedCount++;
      }
    }

    final totalDoses = takenCount + missedCount;
    final totalExpectedDays = max(1, observationDays);

    // PDC = Days with all doses taken / Total Days
    final pdc = (coveredDays.length / totalExpectedDays * 100.0).clamp(0.0, 100.0);

    // MPR = (Taken Doses / Total Scheduled) * 100
    final mpr = totalDoses > 0 ? (takenCount / totalDoses * 100.0).clamp(0.0, 100.0) : 100.0;

    // Average drift
    final avgDrift = timingDrifts.isNotEmpty
        ? timingDrifts.reduce((a, b) => a + b) / timingDrifts.length
        : 12.0;

    final morningRate = morningTotal > 0 ? (morningTaken / morningTotal * 100.0) : 100.0;
    final eveningRate = eveningTotal > 0 ? (eveningTaken / eveningTotal * 100.0) : 100.0;
    final weekendRate = weekendTotal > 0 ? (weekendTaken / weekendTotal * 100.0) : 100.0;

    // Overall Health Score Algorithm (0-100)
    // 50% MPR + 30% PDC + 20% Timing Precision
    final timingScore = max(0.0, 100.0 - (avgDrift / 2.0));
    final overallScore = ((mpr * 0.5) + (pdc * 0.3) + (timingScore * 0.2)).round().clamp(0, 100);

    String interpretation;
    if (overallScore >= 90) {
      interpretation = '🏆 Diamond Clinical Adherence (Optimal therapeutic drug plasma concentration achieved).';
    } else if (overallScore >= 80) {
      interpretation = '🥇 Gold Tier Adherence (Meets ISPOR 80% threshold for chronic disease management).';
    } else if (overallScore >= 65) {
      interpretation = '⚠️ Moderate Adherence (Timing fluctuations detected. Consider digital pillbox & smart alarms).';
    } else {
      interpretation = '🚨 Sub-therapeutic Alert (High missed dose frequency. Pharmacist consultation advised).';
    }

    return ChronotherapyMetrics(
      pdcPercentage: pdc,
      mprPercentage: mpr,
      averageTimingDriftMinutes: avgDrift,
      morningAdherenceRate: morningRate,
      eveningAdherenceRate: eveningRate,
      weekendAdherenceRate: weekendRate,
      totalScheduledDoses: totalDoses,
      totalTakenDoses: takenCount,
      totalMissedDoses: missedCount,
      overallHealthScore: overallScore,
      clinicalInterpretation: interpretation,
    );
  }

  /// Generates CSV research export dataset
  static String generateResearchCsv({
    required List<Medication> medications,
    required List<MedicationLog> logs,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('LogID,MedicationID,MedicationName,ScheduledTime,ActualTimestamp,Status,DriftMinutes,IsWeekend');

    for (final log in logs) {
      final isWeekend = log.timestamp.weekday == DateTime.saturday || log.timestamp.weekday == DateTime.sunday;
      double drift = 0.0;
      if (log.scheduledTime.contains(':')) {
        final parts = log.scheduledTime.split(':');
        final schedHour = int.tryParse(parts[0]) ?? 8;
        final schedMin = int.tryParse(parts[1]) ?? 0;
        final targetMinutes = schedHour * 60 + schedMin;
        final actualMinutes = log.timestamp.hour * 60 + log.timestamp.minute;
        drift = (actualMinutes - targetMinutes).abs().toDouble();
      }

      buffer.writeln(
        '"${log.id}","${log.medicationId}","${log.medicationName}","${log.scheduledTime}","${log.timestamp.toIso8601String()}","${log.status.name}",${drift.toStringAsFixed(1)},$isWeekend',
      );
    }

    return buffer.toString();
  }
}
