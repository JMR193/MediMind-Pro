import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/medication.dart';
import '../../domain/models/medication_log.dart';
import '../../domain/models/tasker_event.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/symptom_log.dart';
import '../../domain/models/caregiver.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/models/clinical_vitals.dart';
import 'resilient_storage_engine.dart';
class StorageService {
  static const String _medsKey = 'medimind_medications_v2';
  static const String _logsKey = 'medimind_logs_v2';
  static const String _taskerRulesKey = 'medimind_tasker_rules_v2';
  static const String _profileKey = 'medimind_profile_v2';
  static const String _settingsKey = 'medimind_settings_v2';
  static const String _symptomsKey = 'medimind_symptoms_v2';
  static const String _caregiversKey = 'medimind_caregivers_v2';
  static const String _streaksKey = 'medimind_streaks_v2';
  static const String _vitalsKey = 'medimind_vitals_v1';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Medication persistence
  Future<void> saveMedications(List<Medication> meds) async {
    final listJson = meds.map((m) => m.toJson()).toList();
    await _prefs.setString(_medsKey, jsonEncode(listJson));
    ResilientStorageEngine().commitTable('medications', listJson);
  }

  List<Medication> loadMedications() {
    final rawJson = _prefs.getString(_medsKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((item) => Medication.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Logs persistence
  Future<void> saveLogs(List<MedicationLog> logs) async {
    final listJson = logs.map((l) => l.toJson()).toList();
    await _prefs.setString(_logsKey, jsonEncode(listJson));
    ResilientStorageEngine().commitTable('logs', listJson);
  }

  List<MedicationLog> loadLogs() {
    final rawJson = _prefs.getString(_logsKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((item) => MedicationLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Tasker Rules persistence
  Future<void> saveTaskerRules(List<TaskerRule> rules) async {
    final listJson = rules.map((r) => r.toJson()).toList();
    await _prefs.setString(_taskerRulesKey, jsonEncode(listJson));
  }

  List<TaskerRule> loadTaskerRules() {
    final rawJson = _prefs.getString(_taskerRulesKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((item) => TaskerRule.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  static const String _profilesKey = 'medimind_profiles_multi_v1';
  static const String _activeProfileKey = 'medimind_active_profile_id_v1';

  // User Profile persistence (Single & Multi-Profile)
  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  UserProfile? loadProfile() {
    final rawJson = _prefs.getString(_profileKey);
    if (rawJson == null || rawJson.isEmpty) return null;
    try {
      return UserProfile.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveProfiles(List<UserProfile> profiles) async {
    final listJson = profiles.map((p) => p.toJson()).toList();
    await _prefs.setString(_profilesKey, jsonEncode(listJson));
    ResilientStorageEngine().commitTable('profiles', listJson);
  }

  List<UserProfile> loadProfiles() {
    final rawJson = _prefs.getString(_profilesKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((item) => UserProfile.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveActiveProfileId(String id) async {
    await _prefs.setString(_activeProfileKey, id);
  }

  String? loadActiveProfileId() {
    return _prefs.getString(_activeProfileKey);
  }

  // Settings persistence
  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  AppSettings loadSettings() {
    final rawJson = _prefs.getString(_settingsKey);
    if (rawJson == null || rawJson.isEmpty) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
    } catch (e) {
      return const AppSettings();
    }
  }

  // Symptom Logs persistence
  Future<void> saveSymptomLogs(List<SymptomLog> logs) async {
    final listJson = logs.map((l) => l.toJson()).toList();
    await _prefs.setString(_symptomsKey, jsonEncode(listJson));
  }

  List<SymptomLog> loadSymptomLogs() {
    final rawJson = _prefs.getString(_symptomsKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((item) => SymptomLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Caregiver persistence
  Future<void> saveCaregivers(List<Caregiver> caregivers) async {
    final listJson = caregivers.map((c) => c.toJson()).toList();
    await _prefs.setString(_caregiversKey, jsonEncode(listJson));
  }

  List<Caregiver> loadCaregivers() {
    final rawJson = _prefs.getString(_caregiversKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((item) => Caregiver.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Streak persistence
  Future<void> saveStreaks(StreakData streaks) async {
    await _prefs.setString(_streaksKey, jsonEncode(streaks.toJson()));
  }

  StreakData loadStreaks() {
    final rawJson = _prefs.getString(_streaksKey);
    if (rawJson == null || rawJson.isEmpty) return const StreakData();
    try {
      return StreakData.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
    } catch (e) {
      return const StreakData();
    }
  }

  // Clinical Vitals persistence
  Future<void> saveVitals(List<ClinicalVitalRecord> vitals) async {
    final listJson = vitals.map((v) => v.toJson()).toList();
    await _prefs.setString(_vitalsKey, jsonEncode(listJson));
    // Asynchronously commit to WAL
    ResilientStorageEngine().commitTable('vitals', listJson);
  }

  List<ClinicalVitalRecord> loadVitals() {
    final rawJson = _prefs.getString(_vitalsKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((item) => ClinicalVitalRecord.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Right to be Forgotten (GDPR) & System Reset
  /// Purges all local SharedPreferences and WAL database files.
  Future<void> purgeAllData() async {
    await _prefs.clear();
    await ResilientStorageEngine().purgeAllTables();
  }
}
