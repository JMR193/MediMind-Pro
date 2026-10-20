import 'package:flutter_test/flutter_test.dart';
import 'package:medimind_app/data/services/prescription_parser_service.dart';
import 'package:medimind_app/domain/models/medication.dart';

void main() {
  late PrescriptionParserService parser;

  setUp(() {
    parser = PrescriptionParserService();
  });

  group('Eye Hospital & Post-Op Regimen Tests', () {
    test('1. Parses Post-Cataract Phaco Regimen with Combination Drops & Indian Matrix', () {
      const rxText = '''
ARAVIND EYE HOSPITAL & POST-GRADUATE INSTITUTE OF OPHTHALMOLOGY
Dr. M. Srinivasan, MS (Ophthalmology), Senior Cornea & Cataract Consultant
Patient: Meenakshi S. | Age: 66 | Reg No: 89432/2026
Diagnosis: Post-Op Phacoemulsification with Foldable IOL (Left Eye)

Rx (Left Eye / OS):
1. Moxicip D Eye Drops - 1 drop 4 times daily (OS) x 14 days
2. Pred Forte 1% Eye Drops - 1 drop QID with 4-3-2-1 weekly taper (OS) x 28 days
3. Nevanac 0.1% Eye Drops - 1 drop 1-1-1 (OS) x 30 days
4. Refresh Tears Eye Drops - 1 drop 4 times daily PRN (OS) x 30 days
''';

      final results = parser.parsePrescription(rxText);
      expect(results.length, equals(4));

      // 1. Moxicip D (Moxifloxacin + Dexamethasone Combo Drop)
      final moxiD = results.firstWhere((r) => r.name.toLowerCase().contains('moxicip'));
      expect(moxiD.isEyeMedication, isTrue);
      expect(moxiD.eyeTarget, equals('Left Eye (OS)'));
      expect(moxiD.frequencyPattern, equals('QID'));
      expect(moxiD.scheduleTimes.length, equals(4));

      // 2. Pred Forte 1% with 4-3-2-1 Weekly Taper
      final predForte = results.firstWhere((r) => r.name.toLowerCase().contains('pred'));
      expect(predForte.isEyeMedication, isTrue);
      expect(predForte.eyeTarget, equals('Left Eye (OS)'));
      expect(predForte.ophthalmicFormulation, equals(OphthalmicFormulation.suspension));
      expect(predForte.taperPlan, isNotNull);
      expect(predForte.taperPlan!.steps.length, equals(4));
      expect(predForte.taperPlan!.steps[0].frequencyDescription, contains('4 times daily'));
      expect(predForte.taperPlan!.steps[1].frequencyDescription, contains('3 times daily'));
      expect(predForte.taperPlan!.steps[2].frequencyDescription, contains('Twice daily'));
      expect(predForte.taperPlan!.steps[3].frequencyDescription, contains('Once daily'));

      // 3. Nevanac 0.1% (Nepafenac suspension)
      final nevanac = results.firstWhere((r) => r.name.toLowerCase().contains('nevanac'));
      expect(nevanac.isEyeMedication, isTrue);
      expect(nevanac.ophthalmicFormulation, equals(OphthalmicFormulation.suspension));
      expect(nevanac.frequencyPattern, equals('1-1-1'));
      expect(nevanac.scheduleTimes.length, equals(3));

      // 4. Washout Spacing Safety Radar
      expect(moxiD.safetyWarning, contains('OPHTHALMIC SPACING'));
      expect(predForte.safetyWarning, contains('OPHTHALMIC SPACING'));
    });

    test('2. Correctly Identifies Eye Targets (RE, LE, BE, OD, OS, OU)', () {
      const rxOd = 'RE: Vigamox 0.5% - 1 drop QID x 7 days';
      const rxOs = 'LE: Tobradex - 1 drop BD x 10 days';
      const rxOu = 'BE: Latanoprost 0.005% - 1 drop QHS x 30 days';

      final resOd = parser.parsePrescription(rxOd);
      final resOs = parser.parsePrescription(rxOs);
      final resOu = parser.parsePrescription(rxOu);

      expect(resOd.first.eyeTarget, equals('Right Eye (OD)'));
      expect(resOs.first.eyeTarget, equals('Left Eye (OS)'));
      expect(resOu.first.eyeTarget, equals('Both Eyes (OU)'));
    });

    test('3. Correctly Classifies Formulation Hierarchy (Solution -> Suspension -> Emulsion -> Gel -> Ointment)', () {
      const rxText = '''
1. Moxifloxacin 0.5% Eye Drops - 1 drop QID
2. Pred Forte 1% Ophthalmic Suspension - 1 drop QID (shake well)
3. Durezol 0.05% Ophthalmic Emulsion - 1 drop BD
4. Viscotears Eye Gel - 1 application at bedtime
5. Tobradex Eye Ointment - Apply thin ribbon at bedtime
''';

      final results = parser.parsePrescription(rxText);
      expect(results.length, equals(5));

      final solution = results.firstWhere((r) => r.name.toLowerCase().contains('moxi'));
      final suspension = results.firstWhere((r) => r.name.toLowerCase().contains('pred'));
      final emulsion = results.firstWhere((r) => r.name.toLowerCase().contains('durezol'));
      final gel = results.firstWhere((r) => r.name.toLowerCase().contains('viscotears'));
      final ointment = results.firstWhere((r) => r.name.toLowerCase().contains('tobradex'));

      expect(solution.ophthalmicFormulation, equals(OphthalmicFormulation.solution));
      expect(suspension.ophthalmicFormulation, equals(OphthalmicFormulation.suspension));
      expect(emulsion.ophthalmicFormulation, equals(OphthalmicFormulation.emulsion));
      expect(gel.ophthalmicFormulation, equals(OphthalmicFormulation.gel));
      expect(ointment.ophthalmicFormulation, equals(OphthalmicFormulation.ointment));
      expect(ointment.isOintment, isTrue);
    });

    test('4. Parses High-Frequency Eye Hospital Sigs (Q1H, Q2H, 6x daily)', () {
      const rxHourly = 'Natamycin 5% eye drops - 1 drop every 1 hour (q1h) x 7 days';
      const rxTwoHourly = 'Fortified Cefazolin - 1 drop q2h x 5 days';
      const rxSixTimes = 'Prednisolone acetate 1% - 1 drop 6 times daily x 3 days';

      final resHourly = parser.parsePrescription(rxHourly);
      final resTwoHourly = parser.parsePrescription(rxTwoHourly);
      final resSixTimes = parser.parsePrescription(rxSixTimes);

      expect(resHourly.first.scheduleTimes.length, equals(13)); // 08:00 to 20:00 every hour
      expect(resTwoHourly.first.scheduleTimes.length, equals(8)); // 08:00 to 22:00 every 2 hours
      expect(resSixTimes.first.scheduleTimes.length, equals(6));
    });

    test('5. Safety Radar enforces Punctal Occlusion for Timolol & Beta-Blockers', () {
      const rxGlaucoma = '''
1. Cosopt Eye Drops (Dorzolamide/Timolol) - 1 drop BD (OU)
2. Alphagan 0.2% Eye Drops - 1 drop BD (OU)
''';

      final results = parser.parsePrescription(rxGlaucoma);
      final cosopt = results.firstWhere((r) => r.name.toLowerCase().contains('cosopt'));

      expect(cosopt.clinicalNotes, contains('punctal occlusion'));
      expect(cosopt.clinicalNotes, contains('systemic beta-blocker absorption'));
    });

    test('6. Converts ParsedMedicationDraft directly to production Medication model preserving taper plan & formulation', () {
      const rxPred = 'Pred Forte 1% - 1 drop QID with weekly taper (4-3-2-1) (OD) x 28 days';
      final draft = parser.parsePrescription(rxPred).first;

      final med = draft.toMedication(doctorName: 'Dr. Venkatesh');
      expect(med.isOphthalmic, isTrue);
      expect(med.requiresEyeDropProtocol, isTrue);
      expect(med.eyeTarget, equals('Right Eye (OD)'));
      expect(med.afterOpeningDays, equals(28));
      expect(med.ophthalmicFormulation, equals(OphthalmicFormulation.suspension));
      expect(med.taperPlan, isNotNull);
      expect(med.taperPlan!.steps.length, equals(4));
    });
  });
}
