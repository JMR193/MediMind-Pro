enum AppThemeMode { system, light, dark }

/// Design language aesthetic style
enum UiDesignStyle {
  auto,            // Automatically adapts to OS (Samsung, iOS, or Android)
  samsungOneUi,    // Samsung One UI 6/7 (One-handed reachability, squircle cards, Quick Settings pills)
  appleIosGlass,   // Apple iOS 18 (Dynamic Island pill, Liquid Glass frosted blur, SF typography)
  material3,       // Classic Google Material 3 (Standard elevation, adaptive colors)
}

class AppSettings {
  final AppThemeMode themeMode;
  final UiDesignStyle uiDesignStyle;
  final String languageCode; // e.g. 'en', 'ar', 'fr'
  final bool appLockEnabled;
  final bool biometricEnabled;
  final String? appPin;
  final int autoLockMinutes; // 0 = never
  final bool privacyModeNotifications; // hide med name in notifications
  final bool caregiverAlertsEnabled;
  final bool voiceAssistantEnabled;
  final bool showStreaks;
  final bool notificationSoundEnabled;
  final bool criticalAlarmBypassDnD;
  final String patientName;
  final bool onboardingComplete;
  final bool dynamicIslandEnabled;
  final bool hapticFeedbackEnabled;
  final bool oemOptimizationPromptDismissed;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.uiDesignStyle = UiDesignStyle.auto,
    this.languageCode = 'en',
    this.appLockEnabled = false,
    this.biometricEnabled = false,
    this.appPin,
    this.autoLockMinutes = 5,
    this.privacyModeNotifications = false,
    this.caregiverAlertsEnabled = false,
    this.voiceAssistantEnabled = true,
    this.showStreaks = true,
    this.notificationSoundEnabled = true,
    this.criticalAlarmBypassDnD = true,
    this.patientName = 'Patient',
    this.onboardingComplete = false,
    this.dynamicIslandEnabled = true,
    this.hapticFeedbackEnabled = true,
    this.oemOptimizationPromptDismissed = false,
  });

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'uiDesignStyle': uiDesignStyle.index,
        'languageCode': languageCode,
        'appLockEnabled': appLockEnabled,
        'biometricEnabled': biometricEnabled,
        'appPin': appPin,
        'autoLockMinutes': autoLockMinutes,
        'privacyModeNotifications': privacyModeNotifications,
        'caregiverAlertsEnabled': caregiverAlertsEnabled,
        'voiceAssistantEnabled': voiceAssistantEnabled,
        'showStreaks': showStreaks,
        'notificationSoundEnabled': notificationSoundEnabled,
        'criticalAlarmBypassDnD': criticalAlarmBypassDnD,
        'patientName': patientName,
        'onboardingComplete': onboardingComplete,
        'dynamicIslandEnabled': dynamicIslandEnabled,
        'hapticFeedbackEnabled': hapticFeedbackEnabled,
        'oemOptimizationPromptDismissed': oemOptimizationPromptDismissed,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.values[json['themeMode'] as int? ?? 0],
        uiDesignStyle: UiDesignStyle.values[
            (json['uiDesignStyle'] as int? ?? 0).clamp(0, UiDesignStyle.values.length - 1)],
        languageCode: json['languageCode'] as String? ?? 'en',
        appLockEnabled: json['appLockEnabled'] as bool? ?? false,
        biometricEnabled: json['biometricEnabled'] as bool? ?? false,
        appPin: json['appPin'] as String?,
        autoLockMinutes: json['autoLockMinutes'] as int? ?? 5,
        privacyModeNotifications:
            json['privacyModeNotifications'] as bool? ?? false,
        caregiverAlertsEnabled:
            json['caregiverAlertsEnabled'] as bool? ?? false,
        voiceAssistantEnabled: json['voiceAssistantEnabled'] as bool? ?? true,
        showStreaks: json['showStreaks'] as bool? ?? true,
        notificationSoundEnabled:
            json['notificationSoundEnabled'] as bool? ?? true,
        criticalAlarmBypassDnD:
            json['criticalAlarmBypassDnD'] as bool? ?? true,
        patientName: json['patientName'] as String? ?? 'Patient',
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        dynamicIslandEnabled: json['dynamicIslandEnabled'] as bool? ?? true,
        hapticFeedbackEnabled: json['hapticFeedbackEnabled'] as bool? ?? true,
        oemOptimizationPromptDismissed:
            json['oemOptimizationPromptDismissed'] as bool? ?? false,
      );

  AppSettings copyWith({
    AppThemeMode? themeMode,
    UiDesignStyle? uiDesignStyle,
    String? languageCode,
    bool? appLockEnabled,
    bool? biometricEnabled,
    String? appPin,
    int? autoLockMinutes,
    bool? privacyModeNotifications,
    bool? caregiverAlertsEnabled,
    bool? voiceAssistantEnabled,
    bool? showStreaks,
    bool? notificationSoundEnabled,
    bool? criticalAlarmBypassDnD,
    String? patientName,
    bool? onboardingComplete,
    bool? dynamicIslandEnabled,
    bool? hapticFeedbackEnabled,
    bool? oemOptimizationPromptDismissed,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        uiDesignStyle: uiDesignStyle ?? this.uiDesignStyle,
        languageCode: languageCode ?? this.languageCode,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        appPin: appPin ?? this.appPin,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
        privacyModeNotifications:
            privacyModeNotifications ?? this.privacyModeNotifications,
        caregiverAlertsEnabled:
            caregiverAlertsEnabled ?? this.caregiverAlertsEnabled,
        voiceAssistantEnabled:
            voiceAssistantEnabled ?? this.voiceAssistantEnabled,
        showStreaks: showStreaks ?? this.showStreaks,
        notificationSoundEnabled:
            notificationSoundEnabled ?? this.notificationSoundEnabled,
        criticalAlarmBypassDnD:
            criticalAlarmBypassDnD ?? this.criticalAlarmBypassDnD,
        patientName: patientName ?? this.patientName,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        dynamicIslandEnabled: dynamicIslandEnabled ?? this.dynamicIslandEnabled,
        hapticFeedbackEnabled:
            hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
        oemOptimizationPromptDismissed:
            oemOptimizationPromptDismissed ?? this.oemOptimizationPromptDismissed,
      );
}

/// Supported languages in MediMind Pro
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final bool isRtl;
  final String flagEmoji;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    this.isRtl = false,
    required this.flagEmoji,
  });

  static const List<AppLanguage> supported = [
    AppLanguage(code: 'en', name: 'English', nativeName: 'English', flagEmoji: '🇬🇧'),
    AppLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', isRtl: true, flagEmoji: '🇸🇦'),
    AppLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flagEmoji: '🇮🇳'),
    AppLanguage(code: 'zh', name: 'Chinese (Simplified)', nativeName: '简体中文', flagEmoji: '🇨🇳'),
    AppLanguage(code: 'nl', name: 'Dutch', nativeName: 'Nederlands', flagEmoji: '🇳🇱'),
    AppLanguage(code: 'fr', name: 'French', nativeName: 'Français', flagEmoji: '🇫🇷'),
    AppLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', flagEmoji: '🇩🇪'),
    AppLanguage(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', flagEmoji: '🇮🇳'),
    AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flagEmoji: '🇮🇳'),
    AppLanguage(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia', flagEmoji: '🇮🇩'),
    AppLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano', flagEmoji: '🇮🇹'),
    AppLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語', flagEmoji: '🇯🇵'),
    AppLanguage(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', flagEmoji: '🇮🇳'),
    AppLanguage(code: 'ko', name: 'Korean', nativeName: '한국어', flagEmoji: '🇰🇷'),
    AppLanguage(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', flagEmoji: '🇮🇳'),
    AppLanguage(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu', flagEmoji: '🇲🇾'),
    AppLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी', flagEmoji: '🇮🇳'),
    AppLanguage(code: 'fa', name: 'Persian', nativeName: 'فارسی', isRtl: true, flagEmoji: '🇮🇷'),
    AppLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português', flagEmoji: '🇧🇷'),
    AppLanguage(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', flagEmoji: '🇮🇳'),
    AppLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский', flagEmoji: '🇷🇺'),
    AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', flagEmoji: '🇪🇸'),
    AppLanguage(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flagEmoji: '🇮🇳'),
    AppLanguage(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flagEmoji: '🇮🇳'),
    AppLanguage(code: 'th', name: 'Thai', nativeName: 'ภาษาไทย', flagEmoji: '🇹🇭'),
    AppLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flagEmoji: '🇹🇷'),
    AppLanguage(code: 'ur', name: 'Urdu', nativeName: 'اردو', isRtl: true, flagEmoji: '🇵🇰'),
  ];
}
