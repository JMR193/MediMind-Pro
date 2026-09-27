import 'package:flutter_test/flutter_test.dart';
import 'package:medimind_app/data/services/interaction_service.dart';
import 'package:medimind_app/data/services/chronotherapy_research_service.dart';
import 'package:medimind_app/domain/models/medication.dart';
import 'package:medimind_app/domain/models/medication_log.dart';
import 'package:medimind_app/domain/models/clinical_taper.dart';
import 'package:medimind_app/domain/models/clinical_vitals.dart';
import 'package:medimind_app/domain/models/user_profile.dart';
import 'package:medimind_app/data/services/renal_hepatic_calculator_service.dart';
import 'package:medimind_app/data/services/offline_backup_vault_service.dart';

void main() {
  group('InteractionService Clinical Unit Tests', () {
    final interactionService = InteractionService();

    test('Detects Warfarin and Aspirin bleeding interaction', () {
      final med1 = Medication(
        id: 'w1',
        name: 'Warfarin',
        strength: '5mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.atBedtime,
        scheduleTimes: ['20:00'],
        totalInventoryCount: 30,
        refillThreshold: 7,
        colorHex: '#DC2626',
        iconName: 'pill',
      );
      final med2 = Medication(
        id: 'w2',
        name: 'Aspirin',
        strength: '75mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.afterMeal,
        scheduleTimes: ['08:00'],
        totalInventoryCount: 30,
        refillThreshold: 7,
        colorHex: '#2563EB',
        iconName: 'pill',
      );

      final warnings = interactionService.checkInteractions(
        existingMedications: [med1, med2],
        newDrafts: [],
      );
      expect(warnings.isNotEmpty, isTrue);
      expect(warnings.any((w) => w.description.toLowerCase().contains('bleeding')), isTrue);
    });

    test('Detects Dual Beta-Blocker Heart Rate Warning (Ophthalmic + Oral)', () {
      final med1 = Medication(
        id: 'b1',
        name: 'Timolol 0.5%',
        strength: '5ml',
        category: MedCategory.eyeDrop,
        dosageUnit: DosageUnit.drops,
        dosageAmount: 1,
        instruction: AdminInstruction.beforeMeal,
        scheduleTimes: ['08:00', '20:00'],
        totalInventoryCount: 1,
        refillThreshold: 1,
        colorHex: '#7C3AED',
        iconName: 'eye_drop',
      );
      final med2 = Medication(
        id: 'b2',
        name: 'Metoprolol Tartrate',
        strength: '50mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.withMeal,
        scheduleTimes: ['08:00', '20:00'],
        totalInventoryCount: 60,
        refillThreshold: 10,
        colorHex: '#0D9488',
        iconName: 'pill',
      );

      final warnings = interactionService.checkInteractions(
        existingMedications: [med1, med2],
        newDrafts: [],
      );
      expect(warnings.isNotEmpty, isTrue);
      expect(warnings.any((w) => w.title.toLowerCase().contains('beta-blocker')), isTrue);
    });

    test('Detects Grapefruit conflict with Statins', () {
      final foodWarnings = interactionService.checkFoodInteractions([
        Medication(
          id: 'test_1',
          name: 'Atorvastatin',
          strength: '20mg',
          category: MedCategory.oral,
          dosageUnit: DosageUnit.tablets,
          dosageAmount: 1,
          instruction: AdminInstruction.atBedtime,
          scheduleTimes: ['21:00'],
          startDate: DateTime.now(),
          totalInventoryCount: 30,
          refillThreshold: 7,
          colorHex: '#0066FF',
          iconName: 'pill',
        ),
      ]);
      expect(foodWarnings.isNotEmpty, isTrue);
      expect(foodWarnings.any((w) => w.foodItem.toLowerCase().contains('grapefruit')), isTrue);
    });

    test('Detects Dairy / Calcium conflict with Ciprofloxacin', () {
      final foodWarnings = interactionService.checkFoodInteractions([
        Medication(
          id: 'test_2',
          name: 'Ciprofloxacin',
          strength: '500mg',
          category: MedCategory.oral,
          dosageUnit: DosageUnit.tablets,
          dosageAmount: 1,
          instruction: AdminInstruction.emptyStomach,
          scheduleTimes: ['08:00', '20:00'],
          startDate: DateTime.now(),
          totalInventoryCount: 14,
          refillThreshold: 5,
          colorHex: '#0066FF',
          iconName: 'pill',
        ),
      ]);
      expect(foodWarnings.isNotEmpty, isTrue);
      expect(foodWarnings.any((w) => w.foodItem.toLowerCase().contains('dairy')), isTrue);
    });

    test('Detects Beta-blocker contraindication in Asthmatic patient', () {
      final contraindications = interactionService.checkConditionContraindications(
        [
          Medication(
            id: 'test_3',
            name: 'Propranolol',
            strength: '40mg',
            category: MedCategory.oral,
            dosageUnit: DosageUnit.tablets,
            dosageAmount: 1,
            instruction: AdminInstruction.withMeal,
            scheduleTimes: ['08:00', '20:00'],
            startDate: DateTime.now(),
            totalInventoryCount: 60,
            refillThreshold: 10,
            colorHex: '#0066FF',
            iconName: 'pill',
          ),
        ],
        'Bronchial Asthma, seasonal allergies',
      );
      expect(contraindications.isNotEmpty, isTrue);
      expect(contraindications.any((c) => c.condition.toLowerCase().contains('asthma')), isTrue);
    });
  });

  group('Senior Pharmacovigilance & AGS Beers Criteria Tests', () {
    final interactionService = InteractionService();

    test('Identifies Diphenhydramine anticholinergic risk in senior patient (72yo)', () {
      final med = Medication(
        id: 'beers_1',
        name: 'Diphenhydramine',
        strength: '25mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.atBedtime,
        scheduleTimes: ['22:00'],
        totalInventoryCount: 20,
        refillThreshold: 5,
        colorHex: '#7C3AED',
        iconName: 'pill',
      );

      final warnings = interactionService.checkBeersCriteria(
        medications: [med],
        patientAge: 72,
      );

      expect(warnings.isNotEmpty, isTrue);
      expect(warnings.first.riskCategory.contains('Anticholinergic'), isTrue);
    });

    test('Returns no Beers Criteria warnings for young adult (30yo)', () {
      final med = Medication(
        id: 'beers_2',
        name: 'Alprazolam',
        strength: '0.5mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.asNeeded,
        scheduleTimes: ['22:00'],
        totalInventoryCount: 10,
        refillThreshold: 3,
        colorHex: '#DC2626',
        iconName: 'pill',
      );

      final warnings = interactionService.checkBeersCriteria(
        medications: [med],
        patientAge: 30,
      );

      expect(warnings.isEmpty, isTrue);
    });
  });

  group('Pharmacological Missed-Dose Decision Algorithm Tests', () {
    final interactionService = InteractionService();

    test('Anticoagulant within 6-hour window recommends taking dose immediately', () {
      final med = Medication(
        id: 'warfarin_test',
        name: 'Warfarin Sodium',
        strength: '5mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.atBedtime,
        scheduleTimes: ['18:00'],
        totalInventoryCount: 30,
        refillThreshold: 7,
        colorHex: '#DC2626',
        iconName: 'pill',
      );

      final scheduled = DateTime(2026, 9, 22, 18, 0);
      final current = DateTime(2026, 9, 22, 20, 30); // 2.5 hours late (< 6 hours)

      final advice = interactionService.evaluateMissedDose(
        medication: med,
        scheduledTime: scheduled,
        currentTime: current,
      );

      expect(advice.shouldTakeNow, isTrue);
      expect(advice.isUrgent, isTrue);
    });

    test('Anticoagulant >6 hours late recommends skipping dose to avoid hemorrhage', () {
      final med = Medication(
        id: 'warfarin_test',
        name: 'Warfarin Sodium',
        strength: '5mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.atBedtime,
        scheduleTimes: ['18:00'],
        totalInventoryCount: 30,
        refillThreshold: 7,
        colorHex: '#DC2626',
        iconName: 'pill',
      );

      final scheduled = DateTime(2026, 9, 22, 18, 0);
      final current = DateTime(2026, 9, 23, 2, 0); // 8 hours late (> 6 hours)

      final advice = interactionService.evaluateMissedDose(
        medication: med,
        scheduledTime: scheduled,
        currentTime: current,
      );

      expect(advice.shouldTakeNow, isFalse);
      expect(advice.isUrgent, isTrue);
    });

    test('Standard twice-daily medication applies 6-hour half-interval rule correctly', () {
      final med = Medication(
        id: 'bid_test',
        name: 'Amoxicillin',
        strength: '500mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.capsules,
        dosageAmount: 1,
        instruction: AdminInstruction.withMeal,
        scheduleTimes: ['08:00', '20:00'],
        totalInventoryCount: 20,
        refillThreshold: 5,
        colorHex: '#0D9488',
        iconName: 'pill',
      );

      final scheduled = DateTime(2026, 9, 22, 8, 0);
      
      // Case A: 3 hours late (<= 6 hour half-interval for BID) -> Take now
      final currentEarly = DateTime(2026, 9, 22, 11, 0);
      final adviceEarly = interactionService.evaluateMissedDose(
        medication: med,
        scheduledTime: scheduled,
        currentTime: currentEarly,
      );
      expect(adviceEarly.shouldTakeNow, isTrue);

      // Case B: 7 hours late (> 6 hour half-interval for BID) -> Skip and wait for 20:00
      final currentLate = DateTime(2026, 9, 22, 15, 0);
      final adviceLate = interactionService.evaluateMissedDose(
        medication: med,
        scheduledTime: scheduled,
        currentTime: currentLate,
      );
      expect(adviceLate.shouldTakeNow, isFalse);
    });
  });

  group('Ophthalmic Formulation Sequencing Tests', () {
    test('Ensures correct ophthalmic hierarchy (Solutions -> Suspensions -> Gels -> Ointments)', () {
      expect(OphthalmicFormulation.solution.index < OphthalmicFormulation.suspension.index, isTrue);
      expect(OphthalmicFormulation.suspension.index < OphthalmicFormulation.emulsion.index, isTrue);
      expect(OphthalmicFormulation.emulsion.index < OphthalmicFormulation.gel.index, isTrue);
      expect(OphthalmicFormulation.gel.index < OphthalmicFormulation.ointment.index, isTrue);
    });
  });

  group('Clinical Tapering & Titration Plan Tests', () {
    test('Calculates total duration and progression percentage accurately', () {
      final taper = ClinicalTaperPlan(
        id: 'taper_1',
        medicationName: 'Prednisolone Acetate 1%',
        indication: 'Post-Cataract Inflammation',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        currentStepIndex: 1,
        daysCompletedInCurrentStep: 3,
        steps: const [
          TitrationStep(
            stepNumber: 1,
            dosageAmount: 1.0,
            frequencyDescription: '4 times daily',
            timesOfDay: ['08:00', '12:00', '16:00', '20:00'],
            durationDays: 7,
            clinicalInstruction: 'Week 1: QID',
          ),
          TitrationStep(
            stepNumber: 2,
            dosageAmount: 1.0,
            frequencyDescription: '3 times daily',
            timesOfDay: ['08:00', '14:00', '20:00'],
            durationDays: 7,
            clinicalInstruction: 'Week 2: TID',
          ),
          TitrationStep(
            stepNumber: 3,
            dosageAmount: 1.0,
            frequencyDescription: '2 times daily',
            timesOfDay: ['08:00', '20:00'],
            durationDays: 7,
            clinicalInstruction: 'Week 3: BID',
          ),
          TitrationStep(
            stepNumber: 4,
            dosageAmount: 1.0,
            frequencyDescription: 'Once daily',
            timesOfDay: ['08:00'],
            durationDays: 7,
            clinicalInstruction: 'Week 4: OD',
          ),
        ],
      );

      expect(taper.totalPlanDays, equals(28));
      expect(taper.totalDaysCompletedSoFar, equals(10)); // 7 days (step 1) + 3 days (step 2)
      expect(taper.overallProgressPercentage, closeTo(10 / 28, 0.01));
      expect(taper.currentStep.frequencyDescription, equals('3 times daily'));
    });
  });

  group('ISPOR / WHO Chronotherapy & Adherence Metrics Tests', () {
    test('Computes PDC and MPR correctly for complete adherence', () {
      final med = Medication(
        id: 'chron_1',
        name: 'Latanoprost 0.005%',
        strength: '2.5ml',
        category: MedCategory.eyeDrop,
        dosageUnit: DosageUnit.drops,
        dosageAmount: 1,
        instruction: AdminInstruction.atBedtime,
        scheduleTimes: ['21:00'],
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        totalInventoryCount: 30,
        refillThreshold: 5,
        colorHex: '#059669',
        iconName: 'eye_drop',
      );

      final List<MedicationLog> perfectLogs = [];
      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final day = now.subtract(Duration(days: i));
        perfectLogs.add(MedicationLog(
          id: 'log_$i',
          medicationId: med.id,
          medicationName: med.name,
          scheduledTime: '21:00',
          timestamp: DateTime(day.year, day.month, day.day, 21, 5), // 5 min drift
          status: LogStatus.taken,
        ));
      }

      final metrics = ChronotherapyResearchService.analyzeAdherence(
        medications: [med],
        logs: perfectLogs,
        observationDays: 30,
      );

      expect(metrics.pdcPercentage, greaterThanOrEqualTo(90.0));
      expect(metrics.totalTakenDoses, equals(30));
      expect(metrics.totalMissedDoses, equals(0));
      expect(metrics.overallHealthScore, greaterThanOrEqualTo(90));
    });
  });

  group('Medication Inventory Calculation Tests', () {
    test('Calculates accurate days of supply remaining for once daily', () {
      final med = Medication(
        id: 'med_test',
        name: 'Lisinopril',
        strength: '10mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.beforeMeal,
        scheduleTimes: ['09:00'],
        startDate: DateTime.now(),
        totalInventoryCount: 20,
        refillThreshold: 7,
        colorHex: '#0066FF',
        iconName: 'pill',
      );

      expect(med.estimatedDaysSupplyRemaining, equals(20));
      expect(med.needsRefill, isFalse);
    });

    test('Flags medication needing refill when below threshold', () {
      final med = Medication(
        id: 'med_test_low',
        name: 'Metformin',
        strength: '500mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.withMeal,
        scheduleTimes: ['08:00', '20:00'],
        startDate: DateTime.now(),
        totalInventoryCount: 6, // 3 days remaining
        refillThreshold: 7,
        colorHex: '#0066FF',
        iconName: 'pill',
      );

      expect(med.estimatedDaysSupplyRemaining, equals(3));
      expect(med.needsRefill, isTrue);
    });
  });

  group('Renal & Hepatic Calculator Tests', () {
    test('Calculates Cockcroft-Gault CrCl accurately for elderly male patient', () {
      // Age 70, 70kg, Serum Cr 1.5 mg/dL -> (140-70)*70 / (72*1.5) = 4900 / 108 = 45.4 mL/min
      final crCl = RenalHepaticCalculatorService.calculateCockcroftGaultCrCl(
        age: 70,
        weightKg: 70,
        serumCreatinineMgDl: 1.5,
        isFemale: false,
      );
      expect(crCl, closeTo(45.4, 0.5));
    });

    test('Flags Metformin as contraindicated when CrCl < 30 mL/min', () {
      final med = Medication(
        id: 'met_renal',
        name: 'Metformin Hydrochloride',
        strength: '1000mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.withMeal,
        scheduleTimes: ['08:00', '20:00'],
        totalInventoryCount: 60,
        refillThreshold: 10,
        colorHex: '#0066FF',
        iconName: 'pill',
      );

      final guidelines = RenalHepaticCalculatorService.evaluateRenalAdjustments(
        medications: [med],
        crCl: 24.0, // Severe impairment
      );

      expect(guidelines.isNotEmpty, isTrue);
      expect(guidelines.first.isContraindicated, isTrue);
      expect(guidelines.first.recommendedRenalDose.contains('CONTRAINDICATED'), isTrue);
    });
  });

  group('Offline Backup Vault & Data Integrity Tests', () {
    test('Serializes and restores full multi-profile vault without data loss', () {
      final med = Medication(
        id: 'vault_med',
        name: 'Timolol 0.5%',
        strength: '5ml',
        category: MedCategory.eyeDrop,
        dosageUnit: DosageUnit.drops,
        dosageAmount: 1,
        instruction: AdminInstruction.beforeMeal,
        scheduleTimes: ['08:00', '20:00'],
        totalInventoryCount: 1,
        refillThreshold: 1,
        colorHex: '#7C3AED',
        iconName: 'eye_drop',
      );

      final profile = const UserProfile(
        id: 'vault_prof',
        name: 'Grandparent',
        relationship: 'Parent',
        isPrimaryUser: false,
        colorHex: '#0D9488',
      );

      final jsonStr = OfflineBackupVaultService.generateVaultJson(
        medications: [med],
        logs: [],
        profiles: [profile],
        symptoms: [],
        vitals: [],
      );

      expect(jsonStr.isNotEmpty, isTrue);

      final restored = OfflineBackupVaultService.restoreFromJson(jsonStr);
      expect(restored, isNotNull);
      expect(restored!.medications.length, equals(1));
      expect(restored.medications.first.name, equals('Timolol 0.5%'));
      expect(restored.profiles.first.name, equals('Grandparent'));
    });
  });

  group('Clinical Vitals & Blood Pressure Classification Tests', () {
    test('Categorizes Stage 2 Hypertension accurately (145/95 mmHg)', () {
      final vital = ClinicalVitalRecord(
        id: 'v1',
        profileId: 'default',
        timestamp: DateTime.now(),
        systolicBp: 145,
        diastolicBp: 95,
        heartRateBpm: 80,
      );

      expect(vital.bpCategory, equals(BpCategory.stage2Hypertension));
      expect(vital.bpCategoryLabel.contains('Stage 2'), isTrue);
    });

    test('Identifies Glaucoma IOP Spike (OD 26.0 mmHg)', () {
      final vital = ClinicalVitalRecord(
        id: 'v2',
        profileId: 'default',
        timestamp: DateTime.now(),
        iopRightEyeOd: 26.0,
        iopLeftEyeOs: 16.0,
      );

      expect(vital.iopCategory, equals(IopRiskCategory.highSpike));
    });
  });

  group('Advanced Multi-Regimen & Visual Pill Tests', () {
    test('Correctly filters scheduled days of week (Mon, Wed, Fri only)', () {
      final med = Medication(
        id: 'm_mwf',
        name: 'Methotrexate',
        strength: '15mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.withMeal,
        scheduleTimes: ['09:00'],
        totalInventoryCount: 30,
        refillThreshold: 5,
        colorHex: '#0284C7',
        iconName: 'pill',
        scheduledDaysOfWeek: [1, 3, 5], // Mon, Wed, Fri
      );

      final monday = DateTime(2026, 9, 21); // Monday (weekday == 1)
      final tuesday = DateTime(2026, 9, 22); // Tuesday (weekday == 2)
      final wednesday = DateTime(2026, 9, 23); // Wednesday (weekday == 3)

      expect(med.isScheduledForDay(monday), isTrue);
      expect(med.isScheduledForDay(tuesday), isFalse);
      expect(med.isScheduledForDay(wednesday), isTrue);
    });

    test('Evaluates Cyclic Regimens (21 Days On, 7 Days Off)', () {
      final startDate = DateTime(2026, 1, 1);
      final med = Medication(
        id: 'm_cycle',
        name: 'Chemo / Hormone Oral Therapy',
        strength: '100mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.capsules,
        dosageAmount: 1,
        instruction: AdminInstruction.beforeMeal,
        scheduleTimes: ['08:00'],
        startDate: startDate,
        cycleDaysOn: 21,
        cycleDaysOff: 7,
        totalInventoryCount: 60,
        refillThreshold: 10,
        colorHex: '#DC2626',
        iconName: 'pill',
      );

      final day10 = startDate.add(const Duration(days: 10)); // Day 11 of cycle -> ON
      final day25 = startDate.add(const Duration(days: 25)); // Day 26 of cycle -> OFF (21 to 27 is off)
      final day30 = startDate.add(const Duration(days: 30)); // Day 31 -> Day 3 of 2nd cycle -> ON

      expect(med.isScheduledForDay(day10), isTrue);
      expect(med.isScheduledForDay(day25), isFalse);
      expect(med.isScheduledForDay(day30), isTrue);
    });

    test('Serializes and deserializes Visual Pill Characteristics', () {
      final med = Medication(
        id: 'm_pill_visual',
        name: 'Atorvastatin',
        strength: '20mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.atBedtime,
        scheduleTimes: ['21:00'],
        totalInventoryCount: 30,
        refillThreshold: 5,
        colorHex: '#0284C7',
        iconName: 'pill',
        pillShape: PillShape.oval,
        pillScoring: PillScoring.singleScored,
        pillImprint: 'ATV 20',
        pillColorName: 'White',
        ophthalmicFormulation: OphthalmicFormulation.solution,
      );

      final json = med.toJson();
      final restored = Medication.fromJson(json);

      expect(restored.pillShape, equals(PillShape.oval));
      expect(restored.pillScoring, equals(PillScoring.singleScored));
      expect(restored.pillImprint, equals('ATV 20'));
      expect(restored.pillColorName, equals('White'));
    });
  });
}
