// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MediMind Pro';

  @override
  String get today => 'Today';

  @override
  String get medications => 'Medications';

  @override
  String get reports => 'Reports';

  @override
  String get tasker => 'Tasker';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get symptomDiary => 'Symptom Diary';

  @override
  String get caregiver => 'Caregiver';

  @override
  String get dashboard => 'Today\'s Dashboard';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get todayAdherence => 'Today\'s Adherence';

  @override
  String get noMedicationsDue => 'No medications due today';

  @override
  String get allDoneForToday => 'All done for today! 🎉';

  @override
  String get takeDose => 'Take';

  @override
  String get snoozeDose => 'Snooze';

  @override
  String get skipDose => 'Skip';

  @override
  String get taken => 'Taken';

  @override
  String get skipped => 'Skipped';

  @override
  String get snoozed => 'Snoozed';

  @override
  String get missed => 'Missed';

  @override
  String get addMedication => 'Add Medication';

  @override
  String get editMedication => 'Edit Medication';

  @override
  String get medicationName => 'Medication Name';

  @override
  String get strength => 'Strength / Concentration';

  @override
  String get dosage => 'Dosage';

  @override
  String get frequency => 'Frequency';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get scheduleTimes => 'Schedule Times';

  @override
  String get instructions => 'Administration Instructions';

  @override
  String get notes => 'Clinical Notes';

  @override
  String get inventory => 'Inventory';

  @override
  String get refillAt => 'Refill Alert At';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get openedDate => 'Date Opened';

  @override
  String get afterOpeningDays => 'Days After Opening';

  @override
  String get eyeDropProtocol => 'Eye Drop Protocol';

  @override
  String get eyeTarget => 'Eye (OS/OD/OU)';

  @override
  String get gapMinutes => 'Minimum Gap (minutes)';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get adherence => 'Adherence';

  @override
  String streakDays(int count) {
    return '$count day streak';
  }

  @override
  String bestStreak(int days) {
    return 'Best: $days days';
  }

  @override
  String get weeklyAdherence => 'Weekly Adherence';

  @override
  String get monthlyAdherence => 'Monthly Adherence';

  @override
  String refillWarning(String name) {
    return 'Running low on $name';
  }

  @override
  String expiryWarning(String name) {
    return '$name expires soon';
  }

  @override
  String afterOpeningWarning(String name, int days) {
    return '$name opened window closes in $days days';
  }

  @override
  String get eyeDropActive => 'Eye Drop Protocol Active';

  @override
  String eyeDropTimer(int minutes, int seconds) {
    return 'Next drop in ${minutes}m ${seconds}s';
  }

  @override
  String get eyeDropReady => 'Ready to apply';

  @override
  String get startProtocol => 'Start Protocol';

  @override
  String get completeProtocol => 'Complete';

  @override
  String get logSymptom => 'Log Symptom';

  @override
  String get severity => 'Severity';

  @override
  String get symptomType => 'Symptom Type';

  @override
  String get affectedEye => 'Affected Eye';

  @override
  String get urgentSymptomWarning =>
      'This symptom severity may require professional attention. Please contact your doctor.';

  @override
  String get contactDoctor => 'Contact Doctor';

  @override
  String get aiTitle => 'MediMind AI';

  @override
  String get aiOffline => 'Offline • On-Device';

  @override
  String get aiDisclaimer =>
      'Information only — not medical advice. Consult your doctor for medical decisions.';

  @override
  String get aiInputHint => 'Ask about your medication...';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get appLock => 'App Lock';

  @override
  String get biometric => 'Biometric Authentication';

  @override
  String get privacyMode => 'Privacy Mode Notifications';

  @override
  String get notificationSounds => 'Notification Sounds';

  @override
  String get bypassDnD => 'Bypass Do Not Disturb';

  @override
  String get voiceAssistant => 'Voice Assistant';

  @override
  String get showStreaks => 'Adherence Streaks';

  @override
  String get caregiverAlerts => 'Caregiver Alerts';

  @override
  String get exportData => 'Export Data';

  @override
  String get clearLogs => 'Clear All Logs';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get disclaimer => 'Medical Disclaimer';

  @override
  String get dataPrivacy => 'Data Privacy';

  @override
  String get dataPrivacyBody =>
      'All your medication data is stored locally on this device. Nothing is sent to any server.';

  @override
  String get disclaimerBody =>
      'This app is for medication tracking and information purposes only. It is NOT a diagnostic tool. Always consult your doctor for medical decisions.';

  @override
  String get patientProfile => 'Patient Profile';

  @override
  String get fullName => 'Full Name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get bloodGroup => 'Blood Group';

  @override
  String get primaryDoctor => 'Primary Doctor';

  @override
  String get emergencyContact => 'Emergency Contact';

  @override
  String get knownAllergies => 'Known Allergies';

  @override
  String get medicalConditions => 'Medical Conditions';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get profileSaved => 'Profile saved!';

  @override
  String get generateReport => 'Generate PDF Report';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get drugInteractions => 'Drug Interaction Advisories';

  @override
  String get noInteractions => 'No known interactions detected';

  @override
  String get taskerAutomation => 'Tasker Automation';

  @override
  String get addRule => 'Add Rule';

  @override
  String get testTrigger => 'Test Trigger';

  @override
  String get ruleActive => 'Active';

  @override
  String get ruleInactive => 'Inactive';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionDenied =>
      'Permission denied. Please enable in system settings.';

  @override
  String get ocrScanPrescription => 'Scan Prescription';

  @override
  String get ocrReview => 'Review Scanned Prescription';

  @override
  String get ocrConfirm => 'Confirm & Add Medication';

  @override
  String get ocrRetry => 'Retake Photo';

  @override
  String get voiceListening => 'Listening...';

  @override
  String voiceResult(String text) {
    return 'I heard: $text';
  }

  @override
  String get voiceConfirm => 'Is this correct?';

  @override
  String get voiceCancel => 'Cancel';

  @override
  String get caregiverName => 'Caregiver Name';

  @override
  String get caregiverRelationship => 'Relationship';

  @override
  String get caregiverPhone => 'Phone Number';

  @override
  String get caregiverEmail => 'Email Address';

  @override
  String get alertAfterMisses => 'Alert After Missed Doses';

  @override
  String get addCaregiver => 'Add Caregiver';

  @override
  String get criticalAlarm => 'CRITICAL MEDICATION ALARM';

  @override
  String get takeDoseNow => 'TAKE DOSE NOW';

  @override
  String get snooze15 => 'Snooze 15m';

  @override
  String daysSupplyLeft(int days) {
    return '$days days supply left';
  }

  @override
  String dosesRemaining(int count) {
    return '$count doses remaining';
  }

  @override
  String get noMedications => 'No Medications Yet';

  @override
  String get addFirstMedication => 'Tap + to add your first medication';

  @override
  String get noLogsYet => 'No dose logs yet';

  @override
  String get noSymptomsYet => 'No symptoms logged';

  @override
  String get logSymptomPrompt => 'Tap + to log eye or medication side effects';

  @override
  String get confirmDelete => 'Delete Medication?';

  @override
  String confirmDeleteBody(String name) {
    return 'This will permanently delete $name and all its dose history.';
  }

  @override
  String deleteConfirmed(String name) {
    return '$name deleted.';
  }
}
