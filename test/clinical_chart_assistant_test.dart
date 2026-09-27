import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/data/services/clinical_chart_assistant_service.dart';
import 'package:medication_reminder/domain/models/medication.dart';
import 'package:medication_reminder/domain/models/dose_log.dart';

void main() {
  group('ClinicalChartAssistantService Unit Tests', () {
    final sampleMeds = [
      Medication(
        id: 'med_1',
        name: 'Latanoprost 0.005%',
        dosage: '1 Drop',
        frequency: MedFrequency.onceDaily,
        category: MedCategory.eyeDrop,
        scheduleTimes: ['21:00'],
      ),
      Medication(
        id: 'med_2',
        name: 'Metformin 500mg',
        dosage: '1 Tablet',
        frequency: MedFrequency.twiceDaily,
        category: MedCategory.tablet,
        scheduleTimes: ['08:00', '20:00'],
      ),
    ];

    final now = DateTime(2026, 9, 27, 12, 0);

    final sampleLogs = [
      // Day 1: Perfect adherence
      DoseLog(
        id: 'log_1',
        medicationId: 'med_1',
        medicationName: 'Latanoprost 0.005%',
        timestamp: now.subtract(const Duration(days: 6, hours: 3)),
        scheduledTime: '21:00',
        status: DoseStatus.taken,
      ),
      DoseLog(
        id: 'log_2',
        medicationId: 'med_2',
        medicationName: 'Metformin 500mg',
        timestamp: now.subtract(const Duration(days: 6, hours: 16)),
        scheduledTime: '08:00',
        status: DoseStatus.taken,
      ),
      // Day 2: One taken, one missed
      DoseLog(
        id: 'log_3',
        medicationId: 'med_1',
        medicationName: 'Latanoprost 0.005%',
        timestamp: now.subtract(const Duration(days: 5, hours: 3)),
        scheduledTime: '21:00',
        status: DoseStatus.skipped,
      ),
      DoseLog(
        id: 'log_4',
        medicationId: 'med_2',
        medicationName: 'Metformin 500mg',
        timestamp: now.subtract(const Duration(days: 5, hours: 16)),
        scheduledTime: '08:00',
        status: DoseStatus.taken,
      ),
    ];

    test('Generates 7-Day Chart Telemetry Report with valid points', () {
      final report = ClinicalChartAssistantService.analyzeChartTelemetry(
        medications: sampleMeds,
        logs: sampleLogs,
        timeframe: ChartTimeframe.sevenDays,
        referenceDate: now,
      );

      expect(report.timeframe, equals(ChartTimeframe.sevenDays));
      expect(report.dailyPoints.length, equals(7));
      expect(report.overallAdherencePercent, inInclusiveRange(0.0, 100.0));
      expect(report.adherenceForecastPercent, inInclusiveRange(40.0, 100.0));
      expect(report.timeDistribution.total, greaterThan(0));
      expect(report.clinicalInsights, isNotEmpty);
      expect(report.actionableRecommendations, isNotEmpty);
    });

    test('Generates 14-Day and 30-Day reports accurately', () {
      final report14 = ClinicalChartAssistantService.analyzeChartTelemetry(
        medications: sampleMeds,
        logs: sampleLogs,
        timeframe: ChartTimeframe.fourteenDays,
        referenceDate: now,
      );
      expect(report14.dailyPoints.length, equals(14));

      final report30 = ClinicalChartAssistantService.analyzeChartTelemetry(
        medications: sampleMeds,
        logs: sampleLogs,
        timeframe: ChartTimeframe.thirtyDays,
        referenceDate: now,
      );
      expect(report30.dailyPoints.length, equals(30));
    });

    test('Computes Linear Regression Trajectory and Forecast', () {
      final report = ClinicalChartAssistantService.analyzeChartTelemetry(
        medications: sampleMeds,
        logs: sampleLogs,
        timeframe: ChartTimeframe.sevenDays,
        referenceDate: now,
      );

      expect(report.trajectorySlope, isA<double>());
      expect(report.adherenceForecastPercent, isA<double>());
    });

    test('Answers Chart Inquiries with statistical grounding', () {
      final report = ClinicalChartAssistantService.analyzeChartTelemetry(
        medications: sampleMeds,
        logs: sampleLogs,
        timeframe: ChartTimeframe.sevenDays,
        referenceDate: now,
      );

      final forecastAnswer = ClinicalChartAssistantService.answerChartInquiry(
        query: 'What is my forecast?',
        report: report,
      );
      expect(forecastAnswer, contains('Adherence Forecast'));
      expect(forecastAnswer, contains('%'));

      final jitterAnswer = ClinicalChartAssistantService.answerChartInquiry(
        query: 'timing jitter',
        report: report,
      );
      expect(jitterAnswer, contains('Circadian Timing Jitter'));
      expect(jitterAnswer, contains('minutes'));

      final doctorAnswer = ClinicalChartAssistantService.answerChartInquiry(
        query: 'doctor summary digest',
        report: report,
      );
      expect(doctorAnswer, contains('Clinical Telemetry Digest for Doctor'));
    });
  });
}
