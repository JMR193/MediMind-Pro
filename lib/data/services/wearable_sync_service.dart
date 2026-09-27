import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/models/medication.dart';
import '../../domain/models/medication_log.dart';

/// Form factor for smartwatch visual simulation.
enum WearableWatchShape {
  circular, // Pixel Watch, Galaxy Watch (Wear OS)
  roundedRect, // Apple Watch Ultra / Series 9 (watchOS)
}

/// Wrist haptic feedback profile for alarms and timers.
enum WearableHapticPattern {
  subtleTick,
  gentlePulse,
  strongAlert,
  emergencyStaccato,
}

/// Data payload staged for smartwatch sync.
class WearableMedicationTile {
  final String id;
  final String name;
  final String strength;
  final String scheduledTime;
  final String categoryName;
  final String colorHex;
  final bool isEyeDrop;
  final bool isTakenToday;

  const WearableMedicationTile({
    required this.id,
    required this.name,
    required this.strength,
    required this.scheduledTime,
    required this.categoryName,
    required this.colorHex,
    required this.isEyeDrop,
    required this.isTakenToday,
  });
}

/// Complete wearable state payload transmitted via Bluetooth/Wi-Fi companion sync.
class WearableSyncPayload {
  final DateTime lastSyncedAt;
  final int totalScheduledToday;
  final int totalTakenToday;
  final double adherencePercentage;
  final List<WearableMedicationTile> upcomingTiles;
  final String? activeTimerTitle;
  final int? activeTimerSecondsRemaining;
  final bool isPunctalOcclusionActive;

  const WearableSyncPayload({
    required this.lastSyncedAt,
    required this.totalScheduledToday,
    required this.totalTakenToday,
    required this.adherencePercentage,
    required this.upcomingTiles,
    this.activeTimerTitle,
    this.activeTimerSecondsRemaining,
    this.isPunctalOcclusionActive = false,
  });
}

/// Service handling background synchronization and wrist notifications
/// for Wear OS (Google Pixel Watch, Samsung Galaxy Watch) and watchOS (Apple Watch).
class WearableSyncService extends ChangeNotifier {
  static final WearableSyncService _instance = WearableSyncService._internal();
  factory WearableSyncService() => _instance;
  WearableSyncService._internal();

  bool _isWearableSyncEnabled = true;
  bool _wristHapticsEnabled = true;
  bool _screenWakeOnAlarm = true;
  WearableHapticPattern _hapticPattern = WearableHapticPattern.strongAlert;
  WearableWatchShape _preferredShape = WearableWatchShape.circular;
  DateTime? _lastSyncTimestamp;

  bool get isWearableSyncEnabled => _isWearableSyncEnabled;
  bool get wristHapticsEnabled => _wristHapticsEnabled;
  bool get screenWakeOnAlarm => _screenWakeOnAlarm;
  WearableHapticPattern get hapticPattern => _hapticPattern;
  WearableWatchShape get preferredShape => _preferredShape;
  DateTime? get lastSyncTimestamp => _lastSyncTimestamp;

  void toggleWearableSync(bool enabled) {
    _isWearableSyncEnabled = enabled;
    if (enabled) {
      triggerSync();
    }
    notifyListeners();
  }

  void toggleWristHaptics(bool enabled) {
    _wristHapticsEnabled = enabled;
    notifyListeners();
  }

  void toggleScreenWake(bool enabled) {
    _screenWakeOnAlarm = enabled;
    notifyListeners();
  }

  void setHapticPattern(WearableHapticPattern pattern) {
    _hapticPattern = pattern;
    triggerWristHapticFeedback(pattern);
    notifyListeners();
  }

  void setPreferredShape(WearableWatchShape shape) {
    _preferredShape = shape;
    notifyListeners();
  }

  /// Trigger tactile wrist vibration mirroring smartwatch haptic motors
  static Future<void> triggerWristHapticFeedback([WearableHapticPattern? pattern]) async {
    final pat = pattern ?? WearableHapticPattern.strongAlert;
    switch (pat) {
      case WearableHapticPattern.subtleTick:
        await HapticFeedback.selectionClick();
        break;
      case WearableHapticPattern.gentlePulse:
        await HapticFeedback.mediumImpact();
        break;
      case WearableHapticPattern.strongAlert:
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        break;
      case WearableHapticPattern.emergencyStaccato:
        for (int i = 0; i < 3; i++) {
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
        }
        break;
    }
  }

  /// Triggers a simulated or Bluetooth channel sync with paired smartwatches
  Future<void> triggerSync() async {
    _lastSyncTimestamp = DateTime.now();
    await triggerWristHapticFeedback(WearableHapticPattern.gentlePulse);
    notifyListeners();
  }

  /// Compiles a structured payload ready for Wear OS DataClient or Apple Watch Connectivity
  WearableSyncPayload buildSyncPayload({
    required List<Medication> medications,
    required List<MedicationLog> logs,
    String? activeTimerTitle,
    int? activeTimerSeconds,
    bool isPunctalActive = false,
  }) {
    final now = DateTime.now();
    final todayLogs = logs.where((l) =>
        l.timestamp.year == now.year &&
        l.timestamp.month == now.month &&
        l.timestamp.day == now.day);

    final takenCount = todayLogs.where((l) => l.status == LogStatus.taken).length;
    final totalScheduled = medications.fold<int>(0, (sum, m) => sum + m.scheduleTimes.length);
    final adherence = totalScheduled > 0 ? (takenCount / totalScheduled).clamp(0.0, 1.0) * 100 : 100.0;

    final tiles = medications.map((m) {
      final isTaken = todayLogs.any((l) => l.medicationId == m.id && l.status == LogStatus.taken);
      final isEyeDrop = m.category == MedCategory.eyeDrop || m.category == MedCategory.eyeOintment;
      return WearableMedicationTile(
        id: m.id,
        name: m.name,
        strength: m.strength,
        scheduledTime: m.scheduleTimes.isNotEmpty ? m.scheduleTimes.first : '08:00',
        categoryName: isEyeDrop ? 'Eye Drop' : 'Oral Dose',
        colorHex: m.colorHex,
        isEyeDrop: isEyeDrop,
        isTakenToday: isTaken,
      );
    }).toList();

    return WearableSyncPayload(
      lastSyncedAt: _lastSyncTimestamp ?? DateTime.now(),
      totalScheduledToday: totalScheduled,
      totalTakenToday: takenCount,
      adherencePercentage: adherence,
      upcomingTiles: tiles,
      activeTimerTitle: activeTimerTitle,
      activeTimerSecondsRemaining: activeTimerSeconds,
      isPunctalOcclusionActive: isPunctalActive,
    );
  }
}
