import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/medication.dart';
import '../../domain/models/medication_log.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/symptom_log.dart';
import '../../domain/models/clinical_vitals.dart';

class BackupVaultData {
  final int schemaVersion;
  final String createdAtIso;
  final List<Medication> medications;
  final List<MedicationLog> logs;
  final List<UserProfile> profiles;
  final List<SymptomLog> symptoms;
  final List<ClinicalVitalRecord> vitals;

  const BackupVaultData({
    this.schemaVersion = 2,
    required this.createdAtIso,
    required this.medications,
    required this.logs,
    required this.profiles,
    required this.symptoms,
    required this.vitals,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'createdAtIso': createdAtIso,
    'medications': medications.map((m) => m.toJson()).toList(),
    'logs': logs.map((l) => l.toJson()).toList(),
    'profiles': profiles.map((p) => p.toJson()).toList(),
    'symptoms': symptoms.map((s) => s.toJson()).toList(),
    'vitals': vitals.map((v) => v.toJson()).toList(),
  };

  factory BackupVaultData.fromJson(Map<String, dynamic> json) {
    return BackupVaultData(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      createdAtIso: json['createdAtIso'] as String? ?? DateTime.now().toIso8601String(),
      medications: (json['medications'] as List<dynamic>?)
              ?.map((e) => Medication.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => MedicationLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      profiles: (json['profiles'] as List<dynamic>?)
              ?.map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => SymptomLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      vitals: (json['vitals'] as List<dynamic>?)
              ?.map((e) => ClinicalVitalRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OfflineBackupVaultService {
  /// Generates full snapshot payload
  static String generateVaultJson({
    required List<Medication> medications,
    required List<MedicationLog> logs,
    required List<UserProfile> profiles,
    required List<SymptomLog> symptoms,
    required List<ClinicalVitalRecord> vitals,
  }) {
    final vault = BackupVaultData(
      createdAtIso: DateTime.now().toIso8601String(),
      medications: medications,
      logs: logs,
      profiles: profiles,
      symptoms: symptoms,
      vitals: vitals,
    );
    return jsonEncode(vault.toJson());
  }

  /// Exports vault payload to an on-device file and triggers Share
  static Future<File> exportVaultFile({
    required List<Medication> medications,
    required List<MedicationLog> logs,
    required List<UserProfile> profiles,
    required List<SymptomLog> symptoms,
    required List<ClinicalVitalRecord> vitals,
  }) async {
    final jsonStr = generateVaultJson(
      medications: medications,
      logs: logs,
      profiles: profiles,
      symptoms: symptoms,
      vitals: vitals,
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/medimind_vault_backup_$timestamp.json');
    await file.writeAsString(jsonStr);

    SharePlus.instance.share(ShareParams(
      text: jsonStr,
      subject: 'MediMind Pro 2.0 Offline Clinical Backup Vault ($timestamp)',
    ));

    return file;
  }

  /// Parses and validates imported JSON data
  static BackupVaultData? restoreFromJson(String rawJson) {
    try {
      final Map<String, dynamic> map = jsonDecode(rawJson) as Map<String, dynamic>;
      return BackupVaultData.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
