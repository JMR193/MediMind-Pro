import 'package:flutter_test/flutter_test.dart';
import 'package:medimind_app/domain/models/medication.dart';
import 'package:medimind_app/domain/models/medication_log.dart';
import 'package:medimind_app/data/services/clinical_expert_ai_service.dart';
import 'package:medimind_app/data/services/behavioral_ml_engine.dart';

void main() {
  group('ClinicalExpertAiService - Chronotherapy & Pharmacokinetics', () {
    test('Identifies statin and PPI circadian rules properly', () {
      final statinMed = Medication(
        id: 'med_statin',
        name: 'Atorvastatin 20mg',
        strength: '20mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1.0,
        instruction: AdminInstruction.atBedtime,
        scheduleTimes: ['21:30'],
        totalInventoryCount: 30,
        refillThreshold: 5,
        colorHex: '#0284C7',
        iconName: 'pill',
      );

      final ppiMedMisaligned = Medication(
        id: 'med_ppi',
        name: 'Omeprazole 20mg',
        strength: '20mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.capsules,
        dosageAmount: 1.0,
        instruction: AdminInstruction.withMeal,
        scheduleTimes: ['21:00'], // Suboptimal evening time for PPI
        totalInventoryCount: 30,
        refillThreshold: 5,
        colorHex: '#0D9488',
        iconName: 'pill',
      );

      final evals = ClinicalExpertAiService.evaluateRegimen([statinMed, ppiMedMisaligned]);
      expect(evals.length, 2);

      final statinEval = evals.firstWhere((e) => e.medication.id == 'med_statin');
      expect(statinEval.isOptimallyAligned, isTrue);

      final ppiEval = evals.firstWhere((e) => e.medication.id == 'med_ppi');
      expect(ppiEval.isOptimallyAligned, isFalse);
      expect(ppiEval.recommendedTime, '07:00');
    });

    test('Evaluates missed dose safety using Half-Interval Rule', () {
      final oralMed = Medication(
        id: 'med_oral',
        name: 'Metformin 500mg',
        strength: '500mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1.0,
        instruction: AdminInstruction.withMeal,
        scheduleTimes: ['08:00', '20:00'],
        totalInventoryCount: 30,
        refillThreshold: 5,
        colorHex: '#0284C7',
        iconName: 'pill',
      );

      final sched = DateTime(2026, 9, 27, 8, 0);
      final nextSched = DateTime(2026, 9, 27, 20, 0);

      // Within 50% (3 hours late) -> Safe to take
      final safeAssess = ClinicalExpertAiService.evaluateMissedDose(
        medication: oralMed,
        scheduledTime: sched,
        currentTime: DateTime(2026, 9, 27, 11, 0),
        nextScheduledTime: nextSched,
      );
      expect(safeAssess.canTakeImmediately, isTrue);

      // Past 50% (8 hours late) -> Skip dose
      final unsafeAssess = ClinicalExpertAiService.evaluateMissedDose(
        medication: oralMed,
        scheduledTime: sched,
        currentTime: DateTime(2026, 9, 27, 16, 0),
        nextScheduledTime: nextSched,
      );
      expect(unsafeAssess.canTakeImmediately, isFalse);
    });

    test('Parses complex doctor Sig shorthand into clinical structure', () {
      const rawSig = 'Amoxicillin 500mg 1 TAB PO TID PC';
      final parsed = ClinicalExpertAiService.parseDoctorSig(rawSig);

      expect(parsed.medicationName, 'Amoxicillin');
      expect(parsed.dosageAmount, 1.0);
      expect(parsed.dosageUnit, DosageUnit.tablets);
      expect(parsed.category, MedCategory.oral);
      expect(parsed.instruction, AdminInstruction.afterMeal); // PC = after meals
      expect(parsed.frequency, 'Three times daily'); // TID
      expect(parsed.scheduleTimes.length, 3);
    });

    test('Parses ophthalmic eye drop doctor Sig code', () {
      const rawSig = 'Latanoprost 0.005% 1 GTT OS QHS';
      final parsed = ClinicalExpertAiService.parseDoctorSig(rawSig);

      expect(parsed.category, MedCategory.eyeDrop);
      expect(parsed.dosageUnit, DosageUnit.drops);
      expect(parsed.dosageAmount, 1.0);
      expect(parsed.instruction, AdminInstruction.atBedtime); // QHS
    });
  });

  group('BehavioralMlEngine - Predictive Risk & Latency Anomaly', () {
    test('Analyzes adherence risk across days of week', () {
      final now = DateTime.now();
      final med = Medication(
        id: 'med_test',
        name: 'Lisinopril 10mg',
        strength: '10mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1.0,
        instruction: AdminInstruction.withMeal,
        scheduleTimes: ['08:00'],
        totalInventoryCount: 30,
        refillThreshold: 5,
        colorHex: '#0284C7',
        iconName: 'pill',
      );

      final logs = List.generate(
        14,
        (i) => MedicationLog(
          id: 'log_$i',
          medicationId: 'med_test',
          medicationName: 'Lisinopril 10mg',
          scheduledTime: '08:00',
          timestamp: now.subtract(Duration(days: i)),
          status: i % 7 == 6 ? LogStatus.missed : LogStatus.taken, // miss Sundays
        ),
      );

      final profile = BehavioralMlEngine.analyzeAdherenceRisk(medications: [med], logs: logs);
      expect(profile.dayRiskFactors.length, 7);
      expect(profile.predictedPdcPercentage, greaterThan(70.0));
    });
  });
}
