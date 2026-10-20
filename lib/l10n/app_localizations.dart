import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'MediMind Pro'**
  String get appTitle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @tasker.
  ///
  /// In en, this message translates to:
  /// **'Tasker'**
  String get tasker;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @symptomDiary.
  ///
  /// In en, this message translates to:
  /// **'Symptom Diary'**
  String get symptomDiary;

  /// No description provided for @caregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get caregiver;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Dashboard'**
  String get dashboard;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @todayAdherence.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Adherence'**
  String get todayAdherence;

  /// No description provided for @noMedicationsDue.
  ///
  /// In en, this message translates to:
  /// **'No medications due today'**
  String get noMedicationsDue;

  /// No description provided for @allDoneForToday.
  ///
  /// In en, this message translates to:
  /// **'All done for today! 🎉'**
  String get allDoneForToday;

  /// No description provided for @takeDose.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get takeDose;

  /// No description provided for @snoozeDose.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snoozeDose;

  /// No description provided for @skipDose.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipDose;

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @snoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get snoozed;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @editMedication.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get editMedication;

  /// No description provided for @medicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength / Concentration'**
  String get strength;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @scheduleTimes.
  ///
  /// In en, this message translates to:
  /// **'Schedule Times'**
  String get scheduleTimes;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Administration Instructions'**
  String get instructions;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Clinical Notes'**
  String get notes;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @refillAt.
  ///
  /// In en, this message translates to:
  /// **'Refill Alert At'**
  String get refillAt;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @openedDate.
  ///
  /// In en, this message translates to:
  /// **'Date Opened'**
  String get openedDate;

  /// No description provided for @afterOpeningDays.
  ///
  /// In en, this message translates to:
  /// **'Days After Opening'**
  String get afterOpeningDays;

  /// No description provided for @eyeDropProtocol.
  ///
  /// In en, this message translates to:
  /// **'Eye Drop Protocol'**
  String get eyeDropProtocol;

  /// No description provided for @eyeTarget.
  ///
  /// In en, this message translates to:
  /// **'Eye (OS/OD/OU)'**
  String get eyeTarget;

  /// No description provided for @gapMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minimum Gap (minutes)'**
  String get gapMinutes;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @adherence.
  ///
  /// In en, this message translates to:
  /// **'Adherence'**
  String get adherence;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String streakDays(int count);

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best: {days} days'**
  String bestStreak(int days);

  /// No description provided for @weeklyAdherence.
  ///
  /// In en, this message translates to:
  /// **'Weekly Adherence'**
  String get weeklyAdherence;

  /// No description provided for @monthlyAdherence.
  ///
  /// In en, this message translates to:
  /// **'Monthly Adherence'**
  String get monthlyAdherence;

  /// No description provided for @refillWarning.
  ///
  /// In en, this message translates to:
  /// **'Running low on {name}'**
  String refillWarning(String name);

  /// No description provided for @expiryWarning.
  ///
  /// In en, this message translates to:
  /// **'{name} expires soon'**
  String expiryWarning(String name);

  /// No description provided for @afterOpeningWarning.
  ///
  /// In en, this message translates to:
  /// **'{name} opened window closes in {days} days'**
  String afterOpeningWarning(String name, int days);

  /// No description provided for @eyeDropActive.
  ///
  /// In en, this message translates to:
  /// **'Eye Drop Protocol Active'**
  String get eyeDropActive;

  /// No description provided for @eyeDropTimer.
  ///
  /// In en, this message translates to:
  /// **'Next drop in {minutes}m {seconds}s'**
  String eyeDropTimer(int minutes, int seconds);

  /// No description provided for @eyeDropReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to apply'**
  String get eyeDropReady;

  /// No description provided for @startProtocol.
  ///
  /// In en, this message translates to:
  /// **'Start Protocol'**
  String get startProtocol;

  /// No description provided for @completeProtocol.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeProtocol;

  /// No description provided for @logSymptom.
  ///
  /// In en, this message translates to:
  /// **'Log Symptom'**
  String get logSymptom;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @symptomType.
  ///
  /// In en, this message translates to:
  /// **'Symptom Type'**
  String get symptomType;

  /// No description provided for @affectedEye.
  ///
  /// In en, this message translates to:
  /// **'Affected Eye'**
  String get affectedEye;

  /// No description provided for @urgentSymptomWarning.
  ///
  /// In en, this message translates to:
  /// **'This symptom severity may require professional attention. Please contact your doctor.'**
  String get urgentSymptomWarning;

  /// No description provided for @contactDoctor.
  ///
  /// In en, this message translates to:
  /// **'Contact Doctor'**
  String get contactDoctor;

  /// No description provided for @aiTitle.
  ///
  /// In en, this message translates to:
  /// **'MediMind AI'**
  String get aiTitle;

  /// No description provided for @aiOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline • On-Device'**
  String get aiOffline;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Information only — not medical advice. Consult your doctor for medical decisions.'**
  String get aiDisclaimer;

  /// No description provided for @aiInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your medication...'**
  String get aiInputHint;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @biometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometric;

  /// No description provided for @privacyMode.
  ///
  /// In en, this message translates to:
  /// **'Privacy Mode Notifications'**
  String get privacyMode;

  /// No description provided for @notificationSounds.
  ///
  /// In en, this message translates to:
  /// **'Notification Sounds'**
  String get notificationSounds;

  /// No description provided for @bypassDnD.
  ///
  /// In en, this message translates to:
  /// **'Bypass Do Not Disturb'**
  String get bypassDnD;

  /// No description provided for @voiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant'**
  String get voiceAssistant;

  /// No description provided for @showStreaks.
  ///
  /// In en, this message translates to:
  /// **'Adherence Streaks'**
  String get showStreaks;

  /// No description provided for @caregiverAlerts.
  ///
  /// In en, this message translates to:
  /// **'Caregiver Alerts'**
  String get caregiverAlerts;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear All Logs'**
  String get clearLogs;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Medical Disclaimer'**
  String get disclaimer;

  /// No description provided for @dataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data Privacy'**
  String get dataPrivacy;

  /// No description provided for @dataPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'All your medication data is stored locally on this device. Nothing is sent to any server.'**
  String get dataPrivacyBody;

  /// No description provided for @disclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'This app is for medication tracking and information purposes only. It is NOT a diagnostic tool. Always consult your doctor for medical decisions.'**
  String get disclaimerBody;

  /// No description provided for @patientProfile.
  ///
  /// In en, this message translates to:
  /// **'Patient Profile'**
  String get patientProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get bloodGroup;

  /// No description provided for @primaryDoctor.
  ///
  /// In en, this message translates to:
  /// **'Primary Doctor'**
  String get primaryDoctor;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// No description provided for @knownAllergies.
  ///
  /// In en, this message translates to:
  /// **'Known Allergies'**
  String get knownAllergies;

  /// No description provided for @medicalConditions.
  ///
  /// In en, this message translates to:
  /// **'Medical Conditions'**
  String get medicalConditions;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved!'**
  String get profileSaved;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF Report'**
  String get generateReport;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @drugInteractions.
  ///
  /// In en, this message translates to:
  /// **'Drug Interaction Advisories'**
  String get drugInteractions;

  /// No description provided for @noInteractions.
  ///
  /// In en, this message translates to:
  /// **'No known interactions detected'**
  String get noInteractions;

  /// No description provided for @taskerAutomation.
  ///
  /// In en, this message translates to:
  /// **'Tasker Automation'**
  String get taskerAutomation;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add Rule'**
  String get addRule;

  /// No description provided for @testTrigger.
  ///
  /// In en, this message translates to:
  /// **'Test Trigger'**
  String get testTrigger;

  /// No description provided for @ruleActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get ruleActive;

  /// No description provided for @ruleInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get ruleInactive;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please enable in system settings.'**
  String get permissionDenied;

  /// No description provided for @ocrScanPrescription.
  ///
  /// In en, this message translates to:
  /// **'Scan Prescription'**
  String get ocrScanPrescription;

  /// No description provided for @ocrReview.
  ///
  /// In en, this message translates to:
  /// **'Review Scanned Prescription'**
  String get ocrReview;

  /// No description provided for @ocrConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Add Medication'**
  String get ocrConfirm;

  /// No description provided for @ocrRetry.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get ocrRetry;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get voiceListening;

  /// No description provided for @voiceResult.
  ///
  /// In en, this message translates to:
  /// **'I heard: {text}'**
  String voiceResult(String text);

  /// No description provided for @voiceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Is this correct?'**
  String get voiceConfirm;

  /// No description provided for @voiceCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get voiceCancel;

  /// No description provided for @caregiverName.
  ///
  /// In en, this message translates to:
  /// **'Caregiver Name'**
  String get caregiverName;

  /// No description provided for @caregiverRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get caregiverRelationship;

  /// No description provided for @caregiverPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get caregiverPhone;

  /// No description provided for @caregiverEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get caregiverEmail;

  /// No description provided for @alertAfterMisses.
  ///
  /// In en, this message translates to:
  /// **'Alert After Missed Doses'**
  String get alertAfterMisses;

  /// No description provided for @addCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Add Caregiver'**
  String get addCaregiver;

  /// No description provided for @criticalAlarm.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL MEDICATION ALARM'**
  String get criticalAlarm;

  /// No description provided for @takeDoseNow.
  ///
  /// In en, this message translates to:
  /// **'TAKE DOSE NOW'**
  String get takeDoseNow;

  /// No description provided for @snooze15.
  ///
  /// In en, this message translates to:
  /// **'Snooze 15m'**
  String get snooze15;

  /// No description provided for @daysSupplyLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days supply left'**
  String daysSupplyLeft(int days);

  /// No description provided for @dosesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} doses remaining'**
  String dosesRemaining(int count);

  /// No description provided for @noMedications.
  ///
  /// In en, this message translates to:
  /// **'No Medications Yet'**
  String get noMedications;

  /// No description provided for @addFirstMedication.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first medication'**
  String get addFirstMedication;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No dose logs yet'**
  String get noLogsYet;

  /// No description provided for @noSymptomsYet.
  ///
  /// In en, this message translates to:
  /// **'No symptoms logged'**
  String get noSymptomsYet;

  /// No description provided for @logSymptomPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap + to log eye or medication side effects'**
  String get logSymptomPrompt;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Medication?'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete {name} and all its dose history.'**
  String confirmDeleteBody(String name);

  /// No description provided for @deleteConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted.'**
  String deleteConfirmed(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
