import 'dart:convert';
import '../../domain/models/medication.dart';
import '../../domain/models/medication_log.dart';
import '../../domain/models/user_profile.dart';

/// Service that serializes patient medication regimens into HL7 FHIR R4 JSON standard.
/// Ensures seamless interoperability with SMART on FHIR electronic health record systems (Epic, Cerner, OpenEMR).
class FhirExportService {
  /// Generates a valid HL7 FHIR R4 Bundle containing MedicationRequest and MedicationStatement resources.
  static Map<String, dynamic> generateFhirBundle({
    required UserProfile profile,
    required List<Medication> medications,
    required List<MedicationLog> logs,
  }) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final patientId = profile.id.isNotEmpty ? profile.id : 'patient-primary';

    final entries = <Map<String, dynamic>>[];

    // 1. FHIR Patient Resource
    entries.add({
      'fullUrl': 'urn:uuid:patient-$patientId',
      'resource': {
        'resourceType': 'Patient',
        'id': patientId,
        'active': true,
        'name': [
          {
            'use': 'official',
            'text': profile.name.isNotEmpty ? profile.name : 'Unknown Patient',
          }
        ],
        if (profile.dateOfBirth != null)
          'birthDate': profile.dateOfBirth!.toIso8601String().substring(0, 10),
      },
    });

    // 2. FHIR MedicationRequest Resources (Prescription Orders)
    for (final med in medications) {
      entries.add({
        'fullUrl': 'urn:uuid:med-request-${med.id}',
        'resource': {
          'resourceType': 'MedicationRequest',
          'id': med.id,
          'status': 'active',
          'intent': 'order',
          'medicationCodeableConcept': {
            'text': med.name,
            'coding': [
              {
                'system': 'http://www.nlm.nih.gov/research/umls/rxnorm',
                'display': '${med.name} ${med.strength}',
              }
            ],
          },
          'subject': {'reference': 'Patient/$patientId'},
          'dosageInstruction': [
            {
              'text': med.instruction.name,
              'timing': {
                'repeat': {
                  'frequency': med.scheduleTimes.length,
                  'period': 1,
                  'periodUnit': 'd',
                  'timeOfDay': med.scheduleTimes,
                }
              },
              'doseAndRate': [
                {
                  'doseQuantity': {
                    'value': med.dosageAmount,
                    'unit': med.dosageUnit.name,
                  }
                }
              ]
            }
          ],
          'dispenseRequest': {
            'quantity': {
              'value': med.totalInventoryCount,
              'unit': med.dosageUnit.name,
            }
          }
        },
      });
    }

    // 3. FHIR MedicationStatement Resources (Administration Intake History)
    for (final log in logs.take(100)) {
      entries.add({
        'fullUrl': 'urn:uuid:med-statement-${log.id}',
        'resource': {
          'resourceType': 'MedicationStatement',
          'id': log.id,
          'status': log.status == LogStatus.taken ? 'completed' : 'not-taken',
          'statusReason': [
            if (log.status == LogStatus.skipped)
              {'text': 'Patient skipped dose: ${log.skipReason ?? "Unspecified"}'}
          ],
          'medicationReference': {'reference': 'MedicationRequest/${log.medicationId}'},
          'subject': {'reference': 'Patient/$patientId'},
          'effectiveDateTime': log.timestamp.toUtc().toIso8601String(),
        },
      });
    }

    return {
      'resourceType': 'Bundle',
      'type': 'collection',
      'timestamp': nowIso,
      'total': entries.length,
      'entry': entries,
    };
  }

  /// Exports the FHIR bundle as a pretty-printed JSON string
  static String exportAsJson({
    required UserProfile profile,
    required List<Medication> medications,
    required List<MedicationLog> logs,
  }) {
    final bundle = generateFhirBundle(profile: profile, medications: medications, logs: logs);
    return const JsonEncoder.withIndent('  ').convert(bundle);
  }
}
