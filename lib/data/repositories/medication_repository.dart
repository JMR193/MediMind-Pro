import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/medication.dart';
import '../../domain/models/medication_log.dart';
import '../../domain/models/eye_drop_protocol.dart';
import '../../domain/models/tasker_event.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/symptom_log.dart';
import '../../domain/models/caregiver.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/models/clinical_vitals.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/tasker_service.dart';
import '../services/offline_backup_vault_service.dart';

class MedicationRepository extends ChangeNotifier {
  final StorageService _storageService;
  final NotificationService _notificationService;
  final TaskerService _taskerService;
  final Uuid _uuid = const Uuid();

  List<Medication> _medications = [];
  List<MedicationLog> _logs = [];
  List<TaskerRule> _taskerRules = [];
  List<SymptomLog> _symptomLogs = [];
  List<Caregiver> _caregivers = [];
  List<UserProfile> _profiles = [];
  List<ClinicalVitalRecord> _vitals = [];
  String _activeProfileId = 'default_profile';
  UserProfile? _userProfile;
  AppSettings _settings = const AppSettings();
  StreakData _streakData = const StreakData();
  EyeDropProtocolSession? _activeEyeDropSession;

  MedicationRepository({
    required this._storageService,
    required this._notificationService,
    required this._taskerService,
  }) {
    _initData();
  }

  List<Medication> get medications => List.unmodifiable(_medications);
  List<Medication> get activeMedications => _medications
      .where((m) => m.profileId == _activeProfileId || _profiles.length <= 1)
      .toList();
  List<MedicationLog> get logs => List.unmodifiable(_logs);
  List<TaskerRule> get taskerRules => List.unmodifiable(_taskerRules);
  List<SymptomLog> get symptomLogs => List.unmodifiable(_symptomLogs);
  List<Caregiver> get caregivers => List.unmodifiable(_caregivers);
  List<UserProfile> get profiles => List.unmodifiable(_profiles);
  List<ClinicalVitalRecord> get vitals => List.unmodifiable(_vitals);
  List<ClinicalVitalRecord> get activeVitals => _vitals
      .where((v) => v.profileId == _activeProfileId || _profiles.length <= 1)
      .toList();
  String get activeProfileId => _activeProfileId;
  UserProfile get activeProfile => _profiles.firstWhere(
        (p) => p.id == _activeProfileId,
        orElse: () => _userProfile ?? const UserProfile(id: 'default_profile', name: 'Patient'),
      );
  UserProfile? get userProfile => _userProfile;
  AppSettings get settings => _settings;
  StreakData get streakData => _streakData;
  EyeDropProtocolSession? get activeEyeDropSession => _activeEyeDropSession;

  // Digital 4-Slot Daily Pillbox Getters
  List<Medication> get morningMeds => activeMedications.where((m) => m.scheduleTimes.any((t) {
        final h = int.tryParse(t.split(':')[0]) ?? 8;
        return h >= 5 && h < 11;
      })).toList();

  List<Medication> get afternoonMeds => activeMedications.where((m) => m.scheduleTimes.any((t) {
        final h = int.tryParse(t.split(':')[0]) ?? 12;
        return h >= 11 && h < 16;
      })).toList();

  List<Medication> get eveningMeds => activeMedications.where((m) => m.scheduleTimes.any((t) {
        final h = int.tryParse(t.split(':')[0]) ?? 18;
        return h >= 16 && h < 21;
      })).toList();

  List<Medication> get nightMeds => activeMedications.where((m) => m.scheduleTimes.any((t) {
        final h = int.tryParse(t.split(':')[0]) ?? 22;
        return h >= 21 || h < 5;
      })).toList();

  void _initData() {
    _medications = _storageService.loadMedications();
    _logs = _storageService.loadLogs();
    _taskerRules = _storageService.loadTaskerRules();
    _symptomLogs = _storageService.loadSymptomLogs();
    _caregivers = _storageService.loadCaregivers();
    _profiles = _storageService.loadProfiles();
    if (_profiles.isEmpty) {
      final initialProf = _storageService.loadProfile() ??
          UserProfile(
            id: 'profile_primary',
            name: 'Patient (Self)',
            relationship: 'Self',
            isPrimaryUser: true,
            colorHex: '#0284C7',
            primaryDoctorName: 'Dr. Sarah Lin (Ophthalmology)',
            emergencyContactName: 'Family Member',
            emergencyContactPhone: '+1-555-0199',
          );
      _profiles = [initialProf];
      _storageService.saveProfiles(_profiles);
      _userProfile = initialProf;
    } else {
      _userProfile = _profiles.firstWhere((p) => p.isPrimaryUser, orElse: () => _profiles.first);
    }
    _activeProfileId = _storageService.loadActiveProfileId() ?? _userProfile?.id ?? _profiles.first.id;
    _vitals = _storageService.loadVitals();
    _settings = _storageService.loadSettings();
    _streakData = _storageService.loadStreaks();

    if (_medications.isEmpty) {
      _seedDefaultMedications();
    }
    if (_taskerRules.isEmpty) {
      _taskerRules = _taskerService.getDefaultRules();
      _storageService.saveTaskerRules(_taskerRules);
    }
    if (_caregivers.isEmpty) {
      _caregivers = [
        Caregiver(
          id: _uuid.v4(),
          name: 'Elena Rostova',
          relationship: 'Spouse / Caregiver',
          phone: '+1-555-0144',
          email: 'elena.caregiver@example.com',
          missedDosesBeforeAlert: 2,
          isActive: true,
          addedAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];
      _storageService.saveCaregivers(_caregivers);
    }
    _recalculateStreaks();
    notifyListeners();
  }

  void _seedDefaultMedications() {
    _medications = [
      Medication(
        id: 'default_1',
        name: 'Latanoprost Ophthalmic',
        strength: '0.005%',
        category: MedCategory.eyeDrop,
        dosageUnit: DosageUnit.drops,
        dosageAmount: 1,
        instruction: AdminInstruction.atBedtime,
        frequency: 'Once daily',
        scheduleTimes: ['21:00'],
        startDate: DateTime.now().subtract(const Duration(days: 14)),
        expiryDate: DateTime.now().add(const Duration(days: 180)),
        openedDate: DateTime.now().subtract(const Duration(days: 10)),
        afterOpeningDays: 28,
        totalInventoryCount: 22,
        refillThreshold: 7,
        prescribingDoctor: 'Dr. Sarah Lin (Ophthalmology)',
        rxNumber: 'RX-99201',
        clinicalNotes: 'Administer 1 drop in Left Eye (OS). Wait 5-10 minutes before applying any secondary eye drop.',
        colorHex: '#0284C7',
        iconName: 'eye_drop',
        isHighPriorityAlarm: true,
        requiresEyeDropProtocol: true,
        eyeTarget: 'Left Eye (OS)',
        eyeDropGapMinutes: 5,
        contactLensWarning: true,
      ),
      Medication(
        id: 'default_2',
        name: 'Timolol Maleate',
        strength: '0.5%',
        category: MedCategory.eyeDrop,
        dosageUnit: DosageUnit.drops,
        dosageAmount: 1,
        instruction: AdminInstruction.beforeMeal,
        frequency: 'Twice daily',
        scheduleTimes: ['08:00', '20:00'],
        startDate: DateTime.now().subtract(const Duration(days: 14)),
        expiryDate: DateTime.now().add(const Duration(days: 210)),
        openedDate: DateTime.now().subtract(const Duration(days: 5)),
        afterOpeningDays: 28,
        totalInventoryCount: 35,
        refillThreshold: 10,
        prescribingDoctor: 'Dr. Sarah Lin (Ophthalmology)',
        rxNumber: 'RX-99204',
        clinicalNotes: 'Beta-blocker for intraocular pressure. Maintain 5-10 min gap if administering near other drops.',
        colorHex: '#7C3AED',
        iconName: 'eye_drop',
        isHighPriorityAlarm: true,
        requiresEyeDropProtocol: true,
        eyeTarget: 'Both Eyes (OU)',
        eyeDropGapMinutes: 10,
        contactLensWarning: true,
      ),
      Medication(
        id: 'default_3',
        name: 'Erythromycin Eye Ointment',
        strength: '0.5%',
        category: MedCategory.eyeOintment,
        dosageUnit: DosageUnit.applyTopical,
        dosageAmount: 1,
        instruction: AdminInstruction.atBedtime,
        frequency: 'Once daily',
        scheduleTimes: ['21:30'],
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        expiryDate: DateTime.now().add(const Duration(days: 90)),
        openedDate: DateTime.now().subtract(const Duration(days: 3)),
        afterOpeningDays: 28,
        totalInventoryCount: 15,
        refillThreshold: 5,
        prescribingDoctor: 'Dr. Sarah Lin (Ophthalmology)',
        rxNumber: 'RX-99210',
        clinicalNotes: 'Apply thin ribbon inside lower conjunctival sac. ALWAYS apply AFTER liquid eye drops.',
        colorHex: '#0D9488',
        iconName: 'eye_drop',
        isHighPriorityAlarm: false,
        requiresEyeDropProtocol: true,
        eyeTarget: 'Both Eyes (OU)',
        eyeDropGapMinutes: 15,
        contactLensWarning: true,
        isOintment: true,
      ),
      Medication(
        id: 'default_4',
        name: 'Atorvastatin',
        strength: '20 mg',
        category: MedCategory.oral,
        dosageUnit: DosageUnit.tablets,
        dosageAmount: 1,
        instruction: AdminInstruction.atBedtime,
        frequency: 'Once daily',
        scheduleTimes: ['22:00'],
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        totalInventoryCount: 28,
        refillThreshold: 5,
        prescribingDoctor: 'Dr. Marcus Vance (Cardiology)',
        rxNumber: 'RX-44102',
        clinicalNotes: 'Lipid-lowering agent. Avoid consuming grapefruit juice while taking this medication.',
        colorHex: '#059669',
        iconName: 'pill',
        isHighPriorityAlarm: false,
      ),
    ];
    _storageService.saveMedications(_medications);
  }

  // Medication CRUD
  Future<void> addMedication(Medication med) async {
    _medications.add(med);
    await _storageService.saveMedications(_medications);
    for (var time in med.scheduleTimes) {
      await _notificationService.scheduleMedicationReminder(med, time);
    }
    notifyListeners();
  }

  Future<void> addMultipleMedications(List<Medication> meds) async {
    _medications.addAll(meds);
    await _storageService.saveMedications(_medications);
    for (final med in meds) {
      for (final time in med.scheduleTimes) {
        await _notificationService.scheduleMedicationReminder(med, time);
      }
    }
    notifyListeners();
  }

  Future<void> updateMedication(Medication med) async {
    final idx = _medications.indexWhere((m) => m.id == med.id);
    if (idx != -1) {
      _medications[idx] = med;
      await _storageService.saveMedications(_medications);
      await _notificationService.cancelMedicationReminders(med.id);
      for (final time in med.scheduleTimes) {
        await _notificationService.scheduleMedicationReminder(med, time);
      }
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String id) async {
    final idx = _medications.indexWhere((m) => m.id == id);
    final times = idx != -1 ? _medications[idx].scheduleTimes : null;
    _medications.removeWhere((m) => m.id == id);
    await _storageService.saveMedications(_medications);
    await _notificationService.cancelMedicationReminders(id, times);
    notifyListeners();
  }

  Future<void> restockMedication(String id, int addedUnits) async {
    final idx = _medications.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final med = _medications[idx];
      final updated = med.copyWith(
        totalInventoryCount: med.totalInventoryCount + addedUnits,
      );
      _medications[idx] = updated;
      await _storageService.saveMedications(_medications);
      notifyListeners();
    }
  }

  // Dose Logging
  Future<void> logDose({
    required Medication medication,
    required String scheduledTime,
    required LogStatus status,
    String? skipReason,
    String? notes,
  }) async {
    final log = MedicationLog(
      id: _uuid.v4(),
      medicationId: medication.id,
      medicationName: medication.name,
      scheduledTime: scheduledTime,
      timestamp: DateTime.now(),
      status: status,
      skipReason: skipReason,
      notes: notes,
    );

    _logs.add(log);
    await _storageService.saveLogs(_logs);

    // Deduct stock if taken
    if (status == LogStatus.taken && medication.totalInventoryCount > 0) {
      final updatedMed = medication.copyWith(
        totalInventoryCount: (medication.totalInventoryCount - medication.dosageAmount.toInt()).clamp(0, 9999),
      );
      await updateMedication(updatedMed);
    }

    // Trigger Eye Drop Protocol session if needed
    if (status == LogStatus.taken && medication.requiresEyeDropProtocol) {
      startEyeDropProtocol(medication);
    }

    // Advance Tapering Step if active
    if (status == LogStatus.taken && medication.taperPlan != null && !medication.taperPlan!.isCompleted) {
      await _advanceTaperProgress(medication);
    }

    _recalculateStreaks();
    _checkCaregiverAlerts(medication, status);

    notifyListeners();
  }

  // Batch Taking for Digital 4-Slot Pillbox
  Future<void> takeAllSlotDoses(String slotName, {DateTime? date}) async {
    List<Medication> targetMeds = [];
    final nameLower = slotName.toLowerCase();
    if (nameLower.contains('morning')) {
      targetMeds = morningMeds;
    } else if (nameLower.contains('afternoon')) {
      targetMeds = afternoonMeds;
    } else if (nameLower.contains('evening')) {
      targetMeds = eveningMeds;
    } else {
      targetMeds = nightMeds;
    }

    for (final med in targetMeds) {
      final schedTime = med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '08:00';
      await logDose(
        medication: med,
        scheduledTime: schedTime,
        status: LogStatus.taken,
        notes: 'Pillbox Fast-Pass ($slotName)',
      );
    }
  }

  // Multi-Profile Management
  Future<void> switchProfile(String profileId) async {
    _activeProfileId = profileId;
    await _storageService.saveActiveProfileId(profileId);
    _userProfile = _profiles.firstWhere((p) => p.id == profileId, orElse: () => _profiles.first);
    notifyListeners();
  }

  Future<void> addProfile(UserProfile profile) async {
    _profiles.add(profile);
    await _storageService.saveProfiles(_profiles);
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx != -1) {
      _profiles[idx] = profile;
      if (profile.id == _activeProfileId) {
        _userProfile = profile;
      }
      await _storageService.saveProfiles(_profiles);
      notifyListeners();
    }
  }

  Future<void> deleteProfile(String profileId) async {
    if (_profiles.length <= 1) return; // Retain at least 1 profile
    _profiles.removeWhere((p) => p.id == profileId);
    if (_activeProfileId == profileId) {
      _activeProfileId = _profiles.first.id;
      _userProfile = _profiles.first;
      await _storageService.saveActiveProfileId(_activeProfileId);
    }
    await _storageService.saveProfiles(_profiles);
    notifyListeners();
  }

  // Clinical Taper Progress Engine
  Future<void> _advanceTaperProgress(Medication med) async {
    final plan = med.taperPlan;
    if (plan == null || plan.isCompleted) return;

    final currentStep = plan.currentStep;
    final newDaysInStep = plan.daysCompletedInCurrentStep + 1;

    if (newDaysInStep >= currentStep.durationDays) {
      // Step completed! Transition to next step
      final nextStepIndex = plan.currentStepIndex + 1;
      final isNowCompleted = nextStepIndex >= plan.steps.length;

      final updatedPlan = plan.copyWith(
        currentStepIndex: nextStepIndex,
        daysCompletedInCurrentStep: 0,
        isCompleted: isNowCompleted,
      );

      // If there's a next step, update medication dosage and frequency
      if (!isNowCompleted) {
        final nextStep = plan.steps[nextStepIndex];
        final updatedMed = med.copyWith(
          dosageAmount: nextStep.dosageAmount,
          frequency: nextStep.frequencyDescription,
          scheduleTimes: nextStep.timesOfDay,
          taperPlan: updatedPlan,
        );
        await updateMedication(updatedMed);
      } else {
        final updatedMed = med.copyWith(taperPlan: updatedPlan);
        await updateMedication(updatedMed);
      }
    } else {
      final updatedPlan = plan.copyWith(daysCompletedInCurrentStep: newDaysInStep);
      final updatedMed = med.copyWith(taperPlan: updatedPlan);
      await updateMedication(updatedMed);
    }
  }

  void clearAllLogs() async {
    _logs.clear();
    await _storageService.saveLogs(_logs);
    _recalculateStreaks();
    notifyListeners();
  }

  // Eye Drop Protocol Management
  void startEyeDropProtocol(Medication med) {
    _activeEyeDropSession = EyeDropProtocolSession(
      id: _uuid.v4(),
      medicationId: med.id,
      medicationName: med.name,
      targetEye: med.eyeTarget ?? 'Both Eyes (OU)',
      startTime: DateTime.now(),
      requiredGapMinutes: med.eyeDropGapMinutes,
      contactLensRemoved: med.contactLensWarning,
    );
    notifyListeners();
  }

  void completeEyeDropProtocol() {
    if (_activeEyeDropSession != null) {
      _activeEyeDropSession = null;
      notifyListeners();
    }
  }

  // Symptom Diary
  Future<void> addSymptomLog(SymptomLog log) async {
    _symptomLogs.add(log);
    await _storageService.saveSymptomLogs(_symptomLogs);
    notifyListeners();
  }

  Future<void> deleteSymptomLog(String id) async {
    _symptomLogs.removeWhere((s) => s.id == id);
    await _storageService.saveSymptomLogs(_symptomLogs);
    notifyListeners();
  }

  // Caregivers
  Future<void> addCaregiver(Caregiver caregiver) async {
    _caregivers.add(caregiver);
    await _storageService.saveCaregivers(_caregivers);
    notifyListeners();
  }

  Future<void> updateCaregiver(Caregiver caregiver) async {
    final idx = _caregivers.indexWhere((c) => c.id == caregiver.id);
    if (idx != -1) {
      _caregivers[idx] = caregiver;
      await _storageService.saveCaregivers(_caregivers);
      notifyListeners();
    }
  }

  Future<void> deleteCaregiver(String id) async {
    _caregivers.removeWhere((c) => c.id == id);
    await _storageService.saveCaregivers(_caregivers);
    notifyListeners();
  }

  // User Profile
  Future<void> updateUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _storageService.saveProfile(profile);
    notifyListeners();
  }

  // Settings
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _storageService.saveSettings(newSettings);
    notifyListeners();
  }

  // Tasker Rule Toggle & Trigger
  Future<void> toggleTaskerRule(String ruleId) async {
    final idx = _taskerRules.indexWhere((r) => r.id == ruleId);
    if (idx != -1) {
      final old = _taskerRules[idx];
      _taskerRules[idx] = TaskerRule(
        id: old.id,
        title: old.title,
        description: old.description,
        action: old.action,
        isEnabled: !old.isEnabled,
        intentActionName: old.intentActionName,
        lastTriggered: old.lastTriggered,
      );
      await _storageService.saveTaskerRules(_taskerRules);
      notifyListeners();
    }
  }

  Future<void> triggerTaskerRuleSimulated(String ruleId) async {
    final idx = _taskerRules.indexWhere((r) => r.id == ruleId);
    if (idx != -1) {
      final old = _taskerRules[idx];
      await _taskerService.simulateIntentTrigger(old);
      _taskerRules[idx] = TaskerRule(
        id: old.id,
        title: old.title,
        description: old.description,
        action: old.action,
        isEnabled: old.isEnabled,
        intentActionName: old.intentActionName,
        lastTriggered: DateTime.now(),
      );
      await _storageService.saveTaskerRules(_taskerRules);
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────
  // Clinical Ophthalmic Timing & Conflict Assistant
  // ──────────────────────────────────────────
  List<String> checkEyeMedicationConflicts() {
    final List<String> warnings = [];
    final eyeMeds = _medications.where((m) =>
        m.category == MedCategory.eyeDrop ||
        m.category == MedCategory.eyeOintment ||
        m.requiresEyeDropProtocol).toList();

    if (eyeMeds.length < 2) return warnings;

    // Check time proximity between eye medications
    for (int i = 0; i < eyeMeds.length; i++) {
      for (int j = i + 1; j < eyeMeds.length; j++) {
        final medA = eyeMeds[i];
        final medB = eyeMeds[j];

        for (final timeA in medA.scheduleTimes) {
          for (final timeB in medB.scheduleTimes) {
            final minutesA = _timeStringToMinutes(timeA);
            final minutesB = _timeStringToMinutes(timeB);
            final diff = (minutesA - minutesB).abs();
            final requiredGap = medA.eyeDropGapMinutes > medB.eyeDropGapMinutes
                ? medA.eyeDropGapMinutes
                : medB.eyeDropGapMinutes;

            if (diff < requiredGap) {
              warnings.add(
                '⚠️ Timing Proximity Alert: "${medA.name}" ($timeA) and "${medB.name}" ($timeB) are scheduled only $diff min apart. '
                'Ophthalmic guidelines suggest waiting at least $requiredGap minutes between drops to prevent wash-out.',
              );
            }
          }
        }

        // Check Eye Drop vs Eye Ointment rule
        if ((medA.isOintment || medA.category == MedCategory.eyeOintment) &&
            (!medB.isOintment && medB.category == MedCategory.eyeDrop)) {
          warnings.add(
            '👁️ Sequence Guidance: You take "${medB.name}" (drop) and "${medA.name}" (ointment). '
            'Always apply eye drops FIRST, wait 10-15 minutes, and apply eye ointment LAST.',
          );
        } else if ((medB.isOintment || medB.category == MedCategory.eyeOintment) &&
            (!medA.isOintment && medA.category == MedCategory.eyeDrop)) {
          warnings.add(
            '👁️ Sequence Guidance: You take "${medA.name}" (drop) and "${medB.name}" (ointment). '
            'Always apply eye drops FIRST, wait 10-15 minutes, and apply eye ointment LAST.',
          );
        }
      }
    }

    return warnings;
  }

  int _timeStringToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  // Refill & Expiry Filter Helpers
  List<Medication> get medicationsNeedingRefill =>
      _medications.where((m) => m.needsRefill).toList();

  List<Medication> get expiringMedications =>
      _medications.where((m) => m.isExpiringSoon || m.isExpired).toList();

  List<Medication> get openedWindowExpiringMedications =>
      _medications.where((m) => m.isOpenedWindowClosingSoon || m.isOpenedWindowExpired).toList();

  // Statistics
  double calculateAdherenceRate() {
    if (_logs.isEmpty) return 100.0;
    final takenCount = _logs.where((l) => l.status == LogStatus.taken).length;
    return (takenCount / _logs.length) * 100.0;
  }

  double calculateWeeklyAdherenceRate() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final weekLogs = _logs.where((l) => l.timestamp.isAfter(sevenDaysAgo)).toList();
    if (weekLogs.isEmpty) return 100.0;
    final taken = weekLogs.where((l) => l.status == LogStatus.taken).length;
    return (taken / weekLogs.length) * 100.0;
  }

  double calculateMonthlyAdherenceRate() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final monthLogs = _logs.where((l) => l.timestamp.isAfter(thirtyDaysAgo)).toList();
    if (monthLogs.isEmpty) return 100.0;
    final taken = monthLogs.where((l) => l.status == LogStatus.taken).length;
    return (taken / monthLogs.length) * 100.0;
  }

  void _recalculateStreaks() {
    if (_logs.isEmpty) {
      _streakData = const StreakData();
      _storageService.saveStreaks(_streakData);
      return;
    }

    // Sort logs chronologically
    final sorted = List<MedicationLog>.from(_logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    int streak = 0;
    final now = DateTime.now();
    DateTime currentDay = DateTime(now.year, now.month, now.day);

    while (true) {
      final dayLogs = sorted.where((l) {
        final d = DateTime(l.timestamp.year, l.timestamp.month, l.timestamp.day);
        return d == currentDay;
      }).toList();

      if (dayLogs.isEmpty) {
        if (currentDay == DateTime(now.year, now.month, now.day)) {
          // Today might have no doses yet; step back to yesterday
          currentDay = currentDay.subtract(const Duration(days: 1));
          continue;
        } else {
          break;
        }
      }

      final allTaken = dayLogs.every((l) => l.status == LogStatus.taken);
      if (allTaken) {
        streak++;
        currentDay = currentDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    final best = streak > _streakData.bestStreak ? streak : _streakData.bestStreak;
    _streakData = StreakData(
      currentStreak: streak,
      bestStreak: best,
      lastFullAdherenceDay: streak > 0 ? now : _streakData.lastFullAdherenceDay,
      totalDaysWith100Percent: _streakData.totalDaysWith100Percent + (streak > 0 ? 1 : 0),
    );
    _storageService.saveStreaks(_streakData);
  }

  void _checkCaregiverAlerts(Medication med, LogStatus status) {
    if (!_settings.caregiverAlertsEnabled || _caregivers.isEmpty) return;
    if (status != LogStatus.skipped && status != LogStatus.missed) return;

    // Check consecutive missed doses for this medication
    final medLogs = _logs.where((l) => l.medicationId == med.id).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    int consecutiveMisses = 0;
    for (final l in medLogs) {
      if (l.status == LogStatus.skipped || l.status == LogStatus.missed) {
        consecutiveMisses++;
      } else {
        break;
      }
    }

    for (final caregiver in _caregivers) {
      if (caregiver.isActive && consecutiveMisses >= caregiver.missedDosesBeforeAlert) {
        // Send / log simulated notification for caregiver
        debugPrint('🚨 CAREGIVER ALERT: ${caregiver.name} notified! Medication "${med.name}" missed $consecutiveMisses times in a row.');
      }
    }
  }

  // Clinical Vitals & Glaucoma IOP Management
  Future<void> addVitalRecord(ClinicalVitalRecord record) async {
    _vitals.insert(0, record);
    await _storageService.saveVitals(_vitals);
    notifyListeners();
  }

  Future<void> deleteVitalRecord(String id) async {
    _vitals.removeWhere((v) => v.id == id);
    await _storageService.saveVitals(_vitals);
    notifyListeners();
  }

  // Backup Vault Restore
  Future<bool> restoreVault(BackupVaultData vault) async {
    try {
      if (vault.medications.isNotEmpty) {
        _medications = vault.medications;
        await _storageService.saveMedications(_medications);
      }
      if (vault.logs.isNotEmpty) {
        _logs = vault.logs;
        await _storageService.saveLogs(_logs);
      }
      if (vault.profiles.isNotEmpty) {
        _profiles = vault.profiles;
        await _storageService.saveProfiles(_profiles);
        _userProfile = _profiles.firstWhere((p) => p.isPrimaryUser, orElse: () => _profiles.first);
        _activeProfileId = _userProfile?.id ?? _profiles.first.id;
        await _storageService.saveActiveProfileId(_activeProfileId);
      }
      if (vault.symptoms.isNotEmpty) {
        _symptomLogs = vault.symptoms;
        await _storageService.saveSymptomLogs(_symptomLogs);
      }
      if (vault.vitals.isNotEmpty) {
        _vitals = vault.vitals;
        await _storageService.saveVitals(_vitals);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Vault restore failed: $e');
      return false;
    }
  }

  /// GDPR Right to be Forgotten: Immediately clears in-memory state and purges all disk stores
  Future<void> purgeAllData() async {
    _medications = [];
    _logs = [];
    _taskerRules = [];
    _symptomLogs = [];
    _caregivers = [];
    _profiles = [];
    _vitals = [];
    _userProfile = null;
    _activeProfileId = 'default_profile';
    _activeEyeDropSession = null;
    _streakData = const StreakData();
    _settings = const AppSettings();

    await _notificationService.cancelAllNotifications();
    await _storageService.purgeAllData();
    notifyListeners();
  }
}
