import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum DeviceBrand {
  samsung,
  vivo,
  xiaomi,
  oppoRealme,
  onePlus,
  apple,
  googlePixel,
  other,
}

class OemOptimizationGuide {
  final DeviceBrand brand;
  final String brandName;
  final String osName;
  final String iconAsset;
  final List<String> steps;
  final String whyNeeded;

  const OemOptimizationGuide({
    required this.brand,
    required this.brandName,
    required this.osName,
    required this.iconAsset,
    required this.steps,
    required this.whyNeeded,
  });
}

class DeviceIntegrationService extends ChangeNotifier {
  DeviceBrand _detectedBrand = DeviceBrand.other;
  bool _isBatteryOptimizationIgnored = false;
  bool _isExactAlarmGranted = false;
  bool _isNotificationGranted = false;
  bool _isLoading = false;

  DeviceBrand get detectedBrand => _detectedBrand;
  bool get isBatteryOptimizationIgnored => _isBatteryOptimizationIgnored;
  bool get isExactAlarmGranted => _isExactAlarmGranted;
  bool get isNotificationGranted => _isNotificationGranted;
  bool get isLoading => _isLoading;

  /// Overall reliability percentage (0 - 100)
  int get reliabilityScore {
    if (!_isNotificationGranted) return 10;
    int score = 40;
    if (_isExactAlarmGranted) score += 30;
    if (_isBatteryOptimizationIgnored) score += 30;
    return score;
  }

  bool get isFullyOptimized => reliabilityScore >= 95;

  DeviceIntegrationService() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _detectBrand();
    await checkStatuses();

    _isLoading = false;
    notifyListeners();
  }

  void _detectBrand() {
    if (kIsWeb) {
      _detectedBrand = DeviceBrand.other;
      return;
    }

    if (Platform.isIOS) {
      _detectedBrand = DeviceBrand.apple;
      return;
    }

    if (Platform.isAndroid) {
      // Default to Samsung as the most common flagship, or detect via environment / properties
      // Users can also manually toggle their brand in the optimization screen.
      _detectedBrand = DeviceBrand.samsung;
    }
  }

  void setBrand(DeviceBrand brand) {
    _detectedBrand = brand;
    notifyListeners();
  }

  Future<void> checkStatuses() async {
    if (kIsWeb) {
      _isBatteryOptimizationIgnored = true;
      _isExactAlarmGranted = true;
      _isNotificationGranted = true;
      notifyListeners();
      return;
    }

    try {
      if (Platform.isAndroid) {
        _isBatteryOptimizationIgnored =
            await Permission.ignoreBatteryOptimizations.isGranted;
        _isExactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
        _isNotificationGranted = await Permission.notification.isGranted;
      } else if (Platform.isIOS) {
        _isBatteryOptimizationIgnored = true;
        _isExactAlarmGranted = true;
        _isNotificationGranted = await Permission.notification.isGranted;
      }
    } catch (e) {
      debugPrint("Error checking device permissions: $e");
    }
    notifyListeners();
  }

  Future<bool> requestBatteryOptimizationBypass() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      _isBatteryOptimizationIgnored = status.isGranted;
      notifyListeners();
      return status.isGranted;
    } catch (e) {
      debugPrint("Error requesting battery optimization: $e");
      return false;
    }
  }

  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final status = await Permission.scheduleExactAlarm.request();
      _isExactAlarmGranted = status.isGranted;
      notifyListeners();
      return status.isGranted;
    } catch (e) {
      debugPrint("Error requesting exact alarm permission: $e");
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      _isNotificationGranted = status.isGranted;
      notifyListeners();
      return status.isGranted;
    } catch (e) {
      debugPrint("Error requesting notification permission: $e");
      return false;
    }
  }

  Future<void> openAppSettingsMenu() async {
    await openAppSettings();
  }

  /// Get OEM-tailored step-by-step instructions
  OemOptimizationGuide getGuide(DeviceBrand brand) {
    switch (brand) {
      case DeviceBrand.samsung:
        return const OemOptimizationGuide(
          brand: DeviceBrand.samsung,
          brandName: 'Samsung Galaxy',
          osName: 'One UI 5 / 6 / 7',
          iconAsset: 'samsung',
          whyNeeded:
              'Samsung One UI automatically puts apps to sleep and disables background alarms after 3 days of low usage.',
          steps: [
            '1. Open device Settings ➔ Apps ➔ MediMind Pro.',
            '2. Tap "Battery" and set to "Unrestricted" (crucial for exact alarms).',
            '3. Go to Settings ➔ Device Care ➔ Battery ➔ Background usage limits.',
            '4. Tap "Never sleeping apps" and tap (+) to add MediMind Pro.',
            '5. Under Lock screen settings, ensure "Show on Lock screen" is Enabled.',
          ],
        );

      case DeviceBrand.vivo:
        return const OemOptimizationGuide(
          brand: DeviceBrand.vivo,
          brandName: 'Vivo & iQOO',
          osName: 'Funtouch OS / OriginOS',
          iconAsset: 'vivo',
          whyNeeded:
              'Vivo iManager forcefully kills apps running in the background to preserve battery unless Autostart is permitted.',
          steps: [
            '1. Open device Settings ➔ Apps / Application Manager.',
            '2. Tap "Special app access" ➔ "High background power consumption" ➔ Enable MediMind Pro.',
            '3. Open the "iManager" app on your home screen.',
            '4. Tap "App Manager" ➔ "Autostart management" ➔ Turn MediMind Pro ON.',
            '5. In recent apps screen, swipe down on MediMind Pro and tap the Lock icon 🔒.',
          ],
        );

      case DeviceBrand.xiaomi:
        return const OemOptimizationGuide(
          brand: DeviceBrand.xiaomi,
          brandName: 'Xiaomi, Redmi & POCO',
          osName: 'MIUI / Xiaomi HyperOS',
          iconAsset: 'xiaomi',
          whyNeeded:
              'Xiaomi HyperOS aggressively stops background alarms and blocks lock-screen alarm windows without special permissions.',
          steps: [
            '1. Open Settings ➔ Apps ➔ Manage apps ➔ MediMind Pro.',
            '2. Enable "Autostart" (toggle ON).',
            '3. Tap "Battery saver" and select "No restrictions".',
            '4. Tap "Other permissions" and grant "Show on Lock screen" & "Display pop-up windows while running in the background".',
            '5. Lock MediMind in recent apps drawer with the lock symbol 🔒.',
          ],
        );

      case DeviceBrand.oppoRealme:
        return const OemOptimizationGuide(
          brand: DeviceBrand.oppoRealme,
          brandName: 'OPPO & Realme',
          osName: 'ColorOS / Realme UI',
          iconAsset: 'oppo',
          whyNeeded:
              'ColorOS automatically kills background services when the screen turns off.',
          steps: [
            '1. Open Settings ➔ Apps ➔ App Management ➔ MediMind Pro.',
            '2. Tap "Battery usage" ➔ Allow background activity & Allow auto-launch.',
            '3. Go to Settings ➔ Battery ➔ More settings ➔ Optimize battery use ➔ MediMind Pro ➔ Don\'t optimize.',
            '4. Lock MediMind in recent apps drawer so it stays resident.',
          ],
        );

      case DeviceBrand.onePlus:
        return const OemOptimizationGuide(
          brand: DeviceBrand.onePlus,
          brandName: 'OnePlus',
          osName: 'OxygenOS',
          iconAsset: 'oneplus',
          whyNeeded:
              'OxygenOS deep optimization can delay medication alerts when device is in sleep state.',
          steps: [
            '1. Open Settings ➔ Apps ➔ App management ➔ MediMind Pro.',
            '2. Tap "Battery" ➔ Select "Unrestricted".',
            '3. Tap "Auto-launch" and ensure it is switched ON.',
            '4. In Settings ➔ Battery ➔ Advanced settings ➔ Optimize battery use ➔ Set MediMind Pro to "Don\'t optimize".',
          ],
        );

      case DeviceBrand.apple:
        return const OemOptimizationGuide(
          brand: DeviceBrand.apple,
          brandName: 'Apple iPhone',
          osName: 'iOS 17 / iOS 18',
          iconAsset: 'apple',
          whyNeeded:
              'iOS requires notification permissions, Time Sensitive alerts, and Background App Refresh.',
          steps: [
            '1. Open iPhone Settings ➔ MediMind Pro.',
            '2. Ensure "Background App Refresh" is toggled ON.',
            '3. Tap "Notifications" and enable "Time-Sensitive Notifications".',
            '4. In Settings ➔ Focus / Do Not Disturb, add MediMind Pro to allowed apps list.',
            '5. Keep critical alarm sounds enabled in app settings.',
          ],
        );

      case DeviceBrand.googlePixel:
        return const OemOptimizationGuide(
          brand: DeviceBrand.googlePixel,
          brandName: 'Google Pixel',
          osName: 'Stock Android 14 / 15',
          iconAsset: 'google',
          whyNeeded:
              'Adaptive Battery can defer exact reminders when battery saver is active.',
          steps: [
            '1. Open Settings ➔ Apps ➔ See all apps ➔ MediMind Pro.',
            '2. Tap "App battery usage" ➔ Select "Unrestricted".',
            '3. Tap "Alarms & reminders" ➔ Ensure "Allow setting alarms" is toggled ON.',
            '4. Ensure "Pause app activity if unused" is turned OFF.',
          ],
        );

      case DeviceBrand.other:
        return const OemOptimizationGuide(
          brand: DeviceBrand.other,
          brandName: 'Android Device',
          osName: 'Android OS',
          iconAsset: 'android',
          whyNeeded:
              'Battery optimization must be unrestricted to ensure critical alarms trigger on time.',
          steps: [
            '1. Open device Settings ➔ Apps ➔ MediMind Pro.',
            '2. Tap "Battery" or "Power" ➔ Select "Unrestricted" or "Don\'t optimize".',
            '3. Check "Special App Access" ➔ "Alarms & Reminders" ➔ Enable.',
            '4. Enable Autostart or background running if your device supports it.',
          ],
        );
    }
  }
}
