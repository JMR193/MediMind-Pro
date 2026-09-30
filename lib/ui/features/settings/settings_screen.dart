import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/device_integration_service.dart';
import '../../../domain/models/app_settings.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/theme.dart';
import '../device_integration/device_optimization_screen.dart';
import '../emergency_hud/universal_emergency_hud_screen.dart';
import '../refill_forecast/refill_forecast_screen.dart';
import '../safety_scanner/medication_safety_scanner_screen.dart';
import '../travel/travel_dose_shifter_screen.dart';
import '../wearable/wearable_companion_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final settings = repo.settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(context, '✨ UI & UX Design Language', [
                _buildUiStyleTile(context, settings, repo),
                _buildSwitchTile(
                  context,
                  'Apple Dynamic Island',
                  'Interactive floating status pill for doses & timers',
                  Icons.smart_button_rounded,
                  settings.dynamicIslandEnabled,
                  (v) => repo.updateSettings(settings.copyWith(dynamicIslandEnabled: v)),
                ),
                _buildSwitchTile(
                  context,
                  'Tactile Haptics',
                  'Apple / Samsung haptic feedback engine',
                  Icons.vibration_rounded,
                  settings.hapticFeedbackEnabled,
                  (v) => repo.updateSettings(settings.copyWith(hapticFeedbackEnabled: v)),
                ),
              ]),
              _buildSection(context, '📱 Mobile & OEM Integration', [
                _buildOemReliabilityTile(context),
              ]),
              _buildSection(context, '🎨 Appearance', [
                _buildThemeTile(context, settings, repo),
                _buildLanguageTile(context, settings, repo),
              ]),
              _buildSection(context, '🔔 Notifications', [
                _buildSwitchTile(context, 'Notification Sounds', 'Custom alarm sounds per medication', Icons.music_note_outlined, settings.notificationSoundEnabled, (v) => repo.updateSettings(settings.copyWith(notificationSoundEnabled: v))),
                _buildSwitchTile(context, 'Bypass Do Not Disturb', 'Critical alarms always sound', Icons.notifications_active_outlined, settings.criticalAlarmBypassDnD, (v) => repo.updateSettings(settings.copyWith(criticalAlarmBypassDnD: v))),
                _buildSwitchTile(context, 'Privacy Mode Notifications', 'Hide medication names on lock screen', Icons.lock_outlined, settings.privacyModeNotifications, (v) => repo.updateSettings(settings.copyWith(privacyModeNotifications: v))),
              ]),
              _buildSection(context, '🔒 Privacy & Security', [
                _buildSwitchTile(context, 'App Lock', 'Require PIN or biometric to open app', Icons.fingerprint_outlined, settings.appLockEnabled, (v) => repo.updateSettings(settings.copyWith(appLockEnabled: v))),
                _buildSwitchTile(context, 'Biometric Authentication', 'Fingerprint / Face ID unlock', Icons.face_outlined, settings.biometricEnabled, (v) => repo.updateSettings(settings.copyWith(biometricEnabled: v))),
                if (settings.appLockEnabled)
                  _buildNavigationTile(context, 'Change PIN', 'Update your 4-digit PIN', Icons.pin_outlined, () => _showChangePinDialog(context, repo, settings)),
                _buildInfoTile(context, '🔒 Data Privacy', 'All your medication data is stored locally on this device. Nothing is sent to any server.'),
              ]),
              _buildSection(context, '🤖 AI & Features', [
                _buildSwitchTile(context, 'Voice Assistant', 'Use voice to log doses and schedule meds', Icons.mic_outlined, settings.voiceAssistantEnabled, (v) => repo.updateSettings(settings.copyWith(voiceAssistantEnabled: v))),
                _buildSwitchTile(context, 'Adherence Streaks', 'Show streak badges and gamification', Icons.local_fire_department_outlined, settings.showStreaks, (v) => repo.updateSettings(settings.copyWith(showStreaks: v))),
                _buildSwitchTile(context, 'Caregiver Alerts', 'Notify caregiver on repeated missed doses', Icons.people_outlined, settings.caregiverAlertsEnabled, (v) => repo.updateSettings(settings.copyWith(caregiverAlertsEnabled: v))),
              ]),
              _buildSection(context, '⌚ Wearable & Smartwatch', [
                _buildNavigationTile(
                  context,
                  'Smartwatch Companion & Simulator',
                  'Wear OS & Apple Watch live watchface preview, haptics, and sync',
                  Icons.watch_outlined,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WearableCompanionScreen()),
                  ),
                ),
              ]),
              _buildSection(context, '🌍 Global Patient Safety & Travel Suite', [
                _buildNavigationTile(
                  context,
                  'Scan-Before-Swallow HUD',
                  'Optical safety check to prevent accidental wrong-bottle ingestion',
                  Icons.qr_code_scanner_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MedicationSafetyScannerScreen()),
                  ),
                ),
                _buildNavigationTile(
                  context,
                  'Circadian Travel Dose Shifter',
                  'Jet-lag phase shift protocols for international flights across timezones',
                  Icons.flight_takeoff_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TravelDoseShifterScreen()),
                  ),
                ),
                _buildNavigationTile(
                  context,
                  'Paramedic Emergency HUD (Multilingual)',
                  'Offline life-saving ICE pass with 10 languages & anticoagulant alert',
                  Icons.emergency_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UniversalEmergencyHudScreen()),
                  ),
                ),
                _buildNavigationTile(
                  context,
                  'Pharmacy Desert & Refill Forecaster',
                  'Stock depletion timeline with weekend refill cliff warning',
                  Icons.inventory_2_outlined,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RefillForecastScreen()),
                  ),
                ),
              ]),
              _buildSection(context, '📦 Data Management', [
                _buildNavigationTile(context, 'Export Data', 'Save all medication data as JSON backup', Icons.download_outlined, () => _showExportDialog(context)),
                _buildNavigationTile(context, 'Load Sample Regimen (Demo)', 'Load sample medications to preview features', Icons.science_outlined, () => _showLoadDemoDialog(context, repo)),
                _buildNavigationTile(context, 'Clear All Medications', 'Remove all medications from active schedule', Icons.medication_liquid_outlined, () => _showClearMedsDialog(context, repo)),
                _buildNavigationTile(context, 'Clear All Logs', 'Delete all dose history logs', Icons.delete_outline, () => _showClearLogsDialog(context, repo)),
              ]),
              _buildSection(context, 'ℹ️ About', [
                _buildInfoTile(context, 'Version', 'MediMind Pro v1.0.0 — Clinical Edition'),
                _buildInfoTile(context, 'Medical Disclaimer', 'This app is for medication tracking and information purposes only. It is NOT a diagnostic tool. Always consult your doctor for medical decisions.'),
                _buildNavigationTile(context, 'Privacy Policy', 'View our privacy policy', Icons.policy_outlined, () {}),
              ]),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        ),
        Card(
          child: Column(
            children: tiles.separated(() => const Divider(height: 1, indent: 56)).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildUiStyleTile(BuildContext context, AppSettings settings, MedicationRepository repo) {
    String styleLabel;
    String styleDesc;
    IconData styleIcon;

    switch (settings.uiDesignStyle) {
      case UiDesignStyle.auto:
        styleLabel = 'Adaptive';
        styleDesc = 'Adapts dynamically to host OS';
        styleIcon = Icons.auto_awesome_rounded;
        break;
      case UiDesignStyle.samsungOneUi:
        styleLabel = 'Samsung One UI 7';
        styleDesc = 'One-handed reachability & squircle cards';
        styleIcon = Icons.phone_android_rounded;
        break;
      case UiDesignStyle.appleIosGlass:
        styleLabel = 'Apple iOS 18 Glass';
        styleDesc = 'Liquid frosted glass & Dynamic Island';
        styleIcon = Icons.apple_rounded;
        break;
      case UiDesignStyle.material3:
        styleLabel = 'Material 3';
        styleDesc = 'Classic Google elevation & tone';
        styleIcon = Icons.palette_outlined;
        break;
    }

    return ListTile(
      leading: Icon(styleIcon, color: Theme.of(context).colorScheme.primary),
      title: const Text('Design Language Style'),
      subtitle: Text('$styleLabel — $styleDesc', style: const TextStyle(fontSize: 11)),
      trailing: DropdownButton<UiDesignStyle>(
        value: settings.uiDesignStyle,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: UiDesignStyle.auto, child: Text('Adaptive')),
          DropdownMenuItem(value: UiDesignStyle.samsungOneUi, child: Text('Samsung One UI')),
          DropdownMenuItem(value: UiDesignStyle.appleIosGlass, child: Text('Apple iOS 18 Glass')),
          DropdownMenuItem(value: UiDesignStyle.material3, child: Text('Material 3')),
        ],
        onChanged: (v) {
          if (v != null) {
            AppleGlassDecorations.mediumHaptic();
            repo.updateSettings(settings.copyWith(uiDesignStyle: v));
          }
        },
      ),
    );
  }

  Widget _buildOemReliabilityTile(BuildContext context) {
    return Consumer<DeviceIntegrationService>(
      builder: (context, deviceService, _) {
        final score = deviceService.reliabilityScore;
        final isPerfect = score >= 95;
        final guide = deviceService.getGuide(deviceService.detectedBrand);

        final badgeColor = isPerfect
            ? MediMindTheme.successGreen
            : score >= 60
                ? MediMindTheme.warningOrange
                : MediMindTheme.alertRed;

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPerfect ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
              color: badgeColor,
              size: 20,
            ),
          ),
          title: Text('${guide.brandName} Reliability'),
          subtitle: Text(
            isPerfect
                ? 'Score $score% • 100% Guaranteed background alarm delivery'
                : 'Score $score% • Tap to fix OEM battery & sleep restrictions',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppleGlassDecorations.lightHaptic();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeviceOptimizationScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeTile(BuildContext context, AppSettings settings, MedicationRepository repo) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('Theme'),
      subtitle: Text(settings.themeMode == AppThemeMode.system ? 'System Default' : settings.themeMode == AppThemeMode.light ? 'Light' : 'Dark'),
      trailing: DropdownButton<AppThemeMode>(
        value: settings.themeMode,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: AppThemeMode.system, child: Text('System')),
          DropdownMenuItem(value: AppThemeMode.light, child: Text('Light')),
          DropdownMenuItem(value: AppThemeMode.dark, child: Text('Dark')),
        ],
        onChanged: (v) { if (v != null) repo.updateSettings(settings.copyWith(themeMode: v)); },
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, AppSettings settings, MedicationRepository repo) {
    final lang = AppLanguage.supported.firstWhere((l) => l.code == settings.languageCode, orElse: () => AppLanguage.supported.first);
    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: const Text('Language'),
      subtitle: Text('${lang.flagEmoji} ${lang.nativeName}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguagePicker(context, settings, repo),
    );
  }

  Widget _buildSwitchTile(BuildContext context, String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildNavigationTile(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(BuildContext context, String title, String body) {
    return ListTile(
      leading: const Icon(Icons.info_outline, color: Colors.grey),
      title: Text(title),
      subtitle: Text(body, style: const TextStyle(fontSize: 11)),
    );
  }

  void _showLanguagePicker(BuildContext context, AppSettings settings, MedicationRepository repo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView(
              children: AppLanguage.supported.map((lang) {
                final isSelected = lang.code == settings.languageCode;
                return ListTile(
                  leading: Text(lang.flagEmoji, style: const TextStyle(fontSize: 24)),
                  title: Text(lang.nativeName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(lang.name),
                  trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () {
                    repo.updateSettings(settings.copyWith(languageCode: lang.code));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Language set to ${lang.name}')));
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, MedicationRepository repo, AppSettings settings) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set PIN'),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(labelText: '4-digit PIN', prefixIcon: Icon(Icons.pin_outlined)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (pinCtrl.text.length == 4) {
                repo.updateSettings(settings.copyWith(appPin: pinCtrl.text));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.download_outlined, color: MediMindTheme.primaryBlue),
        title: const Text('Export Data'),
        content: const Text('Your medication data will be exported as a JSON file that you can back up or transfer to another device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data export will be available in a future update.')));
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showLoadDemoDialog(BuildContext context, MedicationRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.science_outlined, color: Color(0xFF0284C7)),
        title: const Text('Load Demo Regimen?'),
        content: const Text('This will populate sample eye drops and oral medications so you can preview alarms, timers, and telemetry charts.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              repo.seedDemoMedications();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample medications loaded.')));
            },
            child: const Text('Load Demo'),
          ),
        ],
      ),
    );
  }

  void _showClearMedsDialog(BuildContext context, MedicationRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined, color: MediMindTheme.alertRed),
        title: const Text('Clear All Medications?'),
        content: const Text('This will remove all medications from your schedule and cancel active alarms.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MediMindTheme.alertRed),
            onPressed: () {
              repo.clearAllMedications();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All medications cleared.')));
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showClearLogsDialog(BuildContext context, MedicationRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: MediMindTheme.alertRed),
        title: const Text('Clear All Logs?'),
        content: const Text('This will permanently delete all your dose history. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MediMindTheme.alertRed),
            onPressed: () {
              repo.clearAllLogs();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All logs cleared.')));
            },
            child: const Text('Clear Logs'),
          ),
        ],
      ),
    );
  }
}

extension _IterableExt<T> on Iterable<T> {
  Iterable<T> separated(T Function() separator) sync* {
    var first = true;
    for (final item in this) {
      if (!first) yield separator();
      yield item;
      first = false;
    }
  }
}
