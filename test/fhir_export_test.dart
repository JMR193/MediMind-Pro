import 'package:flutter_test/flutter_test.dart';
import 'package:medimind_app/data/services/fhir_export_service.dart';
import 'package:medimind_app/domain/models/medication.dart';
import 'package:medimind_app/domain/models/medication_log.dart';
import 'package:medimind_app/domain/models/user_profile.dart';

void main() {
  group('FhirExportService Unit Tests', () {
    test('Generates valid HL7 FHIR R4 Bundle with MedicationRequest and MedicationStatement', () {
      final profile = const UserProfile(
        id: 'patient-test-101',
        name: 'Jane Doe',
      );

      final med = Medication(
        id: 'med-101',
        name: 'Atorvastatin',
        strength: '20mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1.0,
        instruction: AdminInstruction.atBedtime,
        scheduleTimes: ['21:30'],
        totalInventoryCount: 30,
        refillThreshold: 5,
        colorHex: '#4A90E2',
        iconName: 'pill',
      );

      final log = MedicationLog(
        id: 'log-101',
        medicationId: 'med-101',
        medicationName: 'Atorvastatin',
        scheduledTime: '21:30',
        timestamp: DateTime.now(),
        status: LogStatus.taken,
      );

      final bundle = FhirExportService.generateFhirBundle(
        profile: profile,
        medications: [med],
        logs: [log],
      );

      expect(bundle['resourceType'], equals('Bundle'));
      expect(bundle['type'], equals('collection'));
      expect(bundle['entry'], isNotEmpty);

      // Check Patient resource
      final entries = bundle['entry'] as List;
      final patientEntry = entries.firstWhere((e) => e['resource']['resourceType'] == 'Patient');
      expect(patientEntry['resource']['id'], equals('patient-test-101'));

      // Check MedicationRequest resource
      final medRequestEntry = entries.firstWhere((e) => e['resource']['resourceType'] == 'MedicationRequest');
      expect(medRequestEntry['resource']['medicationCodeableConcept']['text'], equals('Atorvastatin'));

      // Check MedicationStatement resource
      final medStatementEntry = entries.firstWhere((e) => e['resource']['resourceType'] == 'MedicationStatement');
      expect(medStatementEntry['resource']['status'], equals('completed'));

      // Verify JSON serialization
      final jsonString = FhirExportService.exportAsJson(
        profile: profile,
        medications: [med],
        logs: [log],
      );
      expect(jsonString, contains('"resourceType": "Bundle"'));
    });
  });
}
