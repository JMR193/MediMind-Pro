import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/data/services/drug_food_interaction_ai.dart';
import 'package:medication_reminder/data/services/pharmacokinetic_simulator.dart';

void main() {
  group('DrugFoodInteractionAiService Unit Tests', () {
    test('Identifies Grapefruit juice and Statin CYP3A4 interaction', () {
      final alerts = DrugFoodInteractionAiService.scanCabinetForFoodInteractions(
        ['Atorvastatin 20mg', 'Lisinopril 10mg'],
      );

      expect(alerts, isNotEmpty);
      final statinAlert = alerts.firstWhere(
        (a) => a.medicationName.contains('Atorvastatin'),
      );
      expect(statinAlert.severity, equals(InteractionSeverity.major));
      expect(statinAlert.rule.mechanism, equals(InteractionMechanism.cyp3a4Inhibition));
      expect(statinAlert.rule.patientInstruction.toLowerCase(), contains('grapefruit'));
    });

    test('Identifies Dairy Chelation with Fluoroquinolones and Tetracyclines', () {
      final ciproAlerts = DrugFoodInteractionAiService.scanCabinetForFoodInteractions(
        ['Ciprofloxacin 500mg'],
      );

      expect(ciproAlerts, isNotEmpty);
      final alert = ciproAlerts.first;
      expect(alert.rule.mechanism, equals(InteractionMechanism.chelation));
      expect(alert.rule.requiredSpacingHours, equals(2));
      expect(alert.rule.patientInstruction, contains('2 hours'));
    });

    test('Flags Alcohol + Benzodiazepines / Opioids as Contraindicated', () {
      final alerts = DrugFoodInteractionAiService.scanCabinetForFoodInteractions(
        ['Alprazolam 0.5mg'],
      );

      expect(alerts, isNotEmpty);
      final alert = alerts.first;
      expect(alert.severity, equals(InteractionSeverity.contraindicated));
      expect(alert.rule.mechanism, equals(InteractionMechanism.cnsDepressionSynergy));
    });

    test('Flags Alcohol + Metronidazole disulfiram-like reaction with 72h buffer', () {
      final alerts = DrugFoodInteractionAiService.scanCabinetForFoodInteractions(
        ['Metronidazole 400mg'],
      );

      expect(alerts, isNotEmpty);
      final alert = alerts.first;
      expect(alert.severity, equals(InteractionSeverity.contraindicated));
      expect(alert.rule.mechanism, equals(InteractionMechanism.disulfiramReaction));
      expect(alert.rule.requiredSpacingHours, equals(72));
    });

    test('Interactive food item search against active cabinet', () {
      final activeCabinet = ['Warfarin 5mg', 'Metformin 500mg'];

      // Query Spinach
      final spinachResults = DrugFoodInteractionAiService.checkFoodItemAgainstCabinet(
        queryFood: 'spinach salad',
        activeMedications: activeCabinet,
      );
      expect(spinachResults, isNotEmpty);
      expect(spinachResults.first.medicationName, equals('Warfarin 5mg'));
      expect(spinachResults.first.rule.mechanism, equals(InteractionMechanism.pharmacodynamicAntagonism));

      // Query safe food
      final appleResults = DrugFoodInteractionAiService.checkFoodItemAgainstCabinet(
        queryFood: 'fresh apple',
        activeMedications: activeCabinet,
      );
      expect(appleResults, isEmpty);
    });
  });

  group('PharmacokineticSimulatorService Unit Tests', () {
    test('Calculates Single Dose Bateman Curve correctly', () {
      final profile = PharmacokineticSimulatorService.getProfileForMedication('Atorvastatin');
      expect(profile.halfLifeHours, equals(14.0));
      expect(profile.timeToPeakHours, equals(1.5));

      // At t = 0, concentration must be 0
      final c0 = PharmacokineticSimulatorService.calculateSingleDoseConcentration(
        profile: profile,
        doseMg: 20.0,
        hoursPostDose: 0.0,
      );
      expect(c0, equals(0.0));

      // Near Tmax (1.5h), concentration must rise significantly
      final cPeak = PharmacokineticSimulatorService.calculateSingleDoseConcentration(
        profile: profile,
        doseMg: 20.0,
        hoursPostDose: 1.5,
      );
      expect(cPeak, greaterThan(15.0));

      // At 5 half-lives (~70h), concentration must decline
      final cTrough = PharmacokineticSimulatorService.calculateSingleDoseConcentration(
        profile: profile,
        doseMg: 20.0,
        hoursPostDose: 70.0,
      );
      expect(cTrough, lessThan(cPeak));
    });

    test('Detects Narrow Therapeutic Index for Warfarin', () {
      final warfarin = PharmacokineticSimulatorService.getProfileForMedication('Warfarin');
      expect(warfarin.isNarrowTherapeuticIndex, isTrue);
      expect(warfarin.therapeuticIndex, lessThanOrEqualTo(2.5));
    });

    test('Simulates multi-dose regimen and calculates steady-state peak/trough', () {
      final profile = PharmacokineticSimulatorService.getProfileForMedication('Amlodipine');
      final now = DateTime.now();

      final result = PharmacokineticSimulatorService.simulateRegimen(
        profile: profile,
        doseMg: 5.0,
        pastDoseTimestamps: [
          now.subtract(const Duration(hours: 48)),
          now.subtract(const Duration(hours: 24)),
          now.subtract(const Duration(hours: 2)),
        ],
        now: now,
      );

      expect(result.curvePoints, isNotEmpty);
      expect(result.peakConcentrationCssMax, greaterThan(0.0));
      expect(result.currentConcentration, greaterThan(0.0));
      expect(result.timeAboveMecPercent, greaterThanOrEqualTo(50.0));
    });

    test('Simulates What-If double-dose scenario triggering elevated/toxic alert', () {
      final profile = PharmacokineticSimulatorService.getProfileForMedication('Warfarin');
      final now = DateTime.now();

      final normal = PharmacokineticSimulatorService.simulateWhatIfScenario(
        profile: profile,
        baseDoseMg: 5.0,
        now: now,
        scenarioType: 'on_time',
      );

      final doubleDose = PharmacokineticSimulatorService.simulateWhatIfScenario(
        profile: profile,
        baseDoseMg: 5.0,
        now: now,
        scenarioType: 'double_dose',
      );

      expect(doubleDose.currentConcentration, greaterThan(normal.currentConcentration));
    });
  });
}
