import 'package:flutter_test/flutter_test.dart';
import 'package:medimind_app/data/services/prescription_parser_service.dart';
import 'package:medimind_app/domain/models/medication.dart';

void main() {
  late PrescriptionParserService parser;

  setUp(() {
    parser = PrescriptionParserService();
  });

  group('RxNLP 2.0 Prescription Understanding Algorithm Tests', () {
    test('1. Cleans OCR de-mangle noise correctly', () {
      const corruptedText = 'Tab Augmentin S00mg 1-O-1 8D x 5d';
      final cleaned = parser.cleanOcrDeMangle(corruptedText);

      expect(cleaned, contains('500 mg'));
      expect(cleaned, contains('1 - 0 - 1'));
      expect(cleaned, contains('BD'));
    });

    test('2. Parses Indian Matrix Notation (1-0-1, 1-1-1, 1-0-0)', () {
      const rxText = '''
Rx:
1. Tab Augmentin 625mg 1-0-1 after food x 5 days
2. Cap Pan 40mg 1-0-0 before breakfast x 7 days
3. Tab Dolo 650mg 1-1-1 SOS for fever x 3 days
''';
      final drafts = parser.parsePrescription(rxText);

      expect(drafts.length, 3);

      final augmentin = drafts.firstWhere((d) => d.name == 'Augmentin');
      expect(augmentin.strength, contains('625'));
      expect(augmentin.frequencyLabel, contains('Twice daily'));
      expect(augmentin.scheduleTimes, ['08:00', '20:00']);
      expect(augmentin.durationDays, 5);
      expect(augmentin.instruction, AdminInstruction.afterMeal);

      final pan = drafts.firstWhere((d) => d.name == 'Pan');
      expect(pan.strength, contains('40'));
      expect(pan.frequencyLabel, contains('Once daily'));
      expect(pan.scheduleTimes, ['07:00']); // Fasting chronotherapy
      expect(pan.instruction, AdminInstruction.beforeMeal);

      final dolo = drafts.firstWhere((d) => d.name == 'Dolo');
      expect(dolo.strength, contains('650'));
      expect(dolo.frequencyLabel, contains('Three times daily'));
      expect(dolo.durationDays, 3);
    });

    test('3. Parses Latin Sigs & Chronotherapy Schedules (Q6H, TID, QHS)', () {
      const rxText = '''
1. Moxifloxacin 0.5% Eye Drops - 1 drop QID in right eye (OD) x 14 days
2. Latanoprost 0.005% Eye Drops - 1 drop at bedtime (OU) x 30 days
3. Atorvastatin 20mg - 1 tab QHS x 30 days
''';
      final drafts = parser.parsePrescription(rxText);
      expect(drafts.length, 3);

      final moxi = drafts.firstWhere((d) => d.name.contains('Moxifloxacin'));
      expect(moxi.isEyeMedication, true);
      expect(moxi.eyeTarget, 'Right Eye (OD)');
      expect(moxi.scheduleTimes.length, 4);

      final latanoprost = drafts.firstWhere((d) => d.name == 'Latanoprost');
      expect(latanoprost.isEyeMedication, true);
      expect(latanoprost.eyeTarget, 'Both Eyes (OU)');
      expect(latanoprost.scheduleTimes, ['21:30']); // Optimal evening chronotherapy

      final atorva = drafts.firstWhere((d) => d.name == 'Atorvastatin');
      expect(atorva.scheduleTimes, ['21:30']);
      expect(atorva.clinicalNotes, contains('grapefruit'));
    });

    test('4. Safety Radar triggers Ophthalmic Washout & Bleed Risk Warnings', () {
      const rxWithDdi = '''
Rx:
1. Moxifloxacin 0.5% Eye Drops - 1 drop TID (OD) x 10 days
2. Pred Forte 1% Eye Drops - 1 drop TID (OD) x 10 days
3. Tab Warfarin 2.5mg - 1 tab at 18:00 x 30 days
4. Tab Aspirin 81mg - 1 tab morning after food x 30 days
''';
      final drafts = parser.parsePrescription(rxWithDdi);
      expect(drafts.length, 4);

      // Verify Ophthalmic Washout Warning on multiple eye drops
      final moxi = drafts.firstWhere((d) => d.name.contains('Moxifloxacin'));
      final pred = drafts.firstWhere((d) => d.name.contains('Pred Forte'));
      expect(moxi.safetyWarning, contains('OPHTHALMIC SPACING'));
      expect(pred.safetyWarning, contains('OPHTHALMIC SPACING'));

      // Verify Major Bleed DDI Warning on Warfarin + Aspirin
      final warfarin = drafts.firstWhere((d) => d.name.contains('Warfarin'));
      final aspirin = drafts.firstWhere((d) => d.name.contains('Aspirin'));
      expect(warfarin.safetyWarning, contains('MAJOR DDI BLEED HAZARD'));
      expect(aspirin.safetyWarning, contains('MAJOR DDI BLEED HAZARD'));
      expect(warfarin.isNarrowTherapeuticIndex, true);
    });

    test('5. Typo & Handwriting Levenshtein Fuzzy Correction', () {
      const misspelledRx = 'Tab Atorvastatn 20mg 1 tab OD x 30 days';
      final drafts = parser.parsePrescription(misspelledRx);

      expect(drafts.length, 1);
      final draft = drafts.first;
      expect(draft.name, 'Atorvastatin');
      expect(draft.correctedFrom, 'atorvastatn');
      expect(draft.confidence, greaterThanOrEqualTo(0.85));
    });

    test('6. Converts ParsedMedicationDraft to production Medication model seamlessly', () {
      final draft = ParsedMedicationDraft(
        rawLine: 'Tab Metformin 500mg 1-0-1 after food x 30 days',
        name: 'Metformin',
        strength: '500mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1.0,
        frequencyPattern: '1-0-1',
        frequencyLabel: 'Twice daily',
        scheduleTimes: ['08:00', '20:00'],
        durationDays: 30,
        instruction: AdminInstruction.afterMeal,
        totalQuantity: 60,
      );

      final med = draft.toMedication(doctorName: 'Dr. Williams');
      expect(med.name, 'Metformin');
      expect(med.strength, '500mg');
      expect(med.prescribingDoctor, 'Dr. Williams');
      expect(med.totalInventoryCount, 60);
      expect(med.endDate, isNotNull);
      expect(med.scheduleTimes, ['08:00', '20:00']);
    });
  });
}
