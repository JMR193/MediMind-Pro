import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../domain/models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Android Notification Channels
  static const String channelCriticalId = 'medimind_critical_alarms';
  static const String channelCriticalName = 'Critical Medication Alarms';
  static const String channelCriticalDesc = 'High-priority alarms for life-critical medications and eye drops';

  static const String channelRoutineId = 'medimind_routine_reminders';
  static const String channelRoutineName = 'Routine Medication Reminders';
  static const String channelRoutineDesc = 'Reminders for daily oral supplements and vitamins';

  static const String channelTimerId = 'medimind_eyedrop_timer';
  static const String channelTimerName = 'Eye Drop Protocol Timer';
  static const String channelTimerDesc = 'Active countdowns for punctal occlusion and 5-min drop intervals';

  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Initialize Timezones
      tz.initializeTimeZones();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (e) {
        debugPrint('Could not set device timezone, fallback to UTC: $e');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // 2. Initialize Platform Settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification Action Tapped: ${response.actionId} payload: ${response.payload}');
        },
      );

      // 3. Create Android Channels
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            channelCriticalId,
            channelCriticalName,
            description: channelCriticalDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            channelRoutineId,
            channelRoutineName,
            description: channelRoutineDesc,
            importance: Importance.high,
            playSound: true,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            channelTimerId,
            channelTimerName,
            description: channelTimerDesc,
            importance: Importance.high,
            playSound: false,
          ),
        );
      }

      _initialized = true;
      debugPrint("NotificationService successfully initialized with timezone & actionable channels.");
    } catch (e) {
      debugPrint("NotificationService initialization failed: $e");
    }
  }

  /// Calculates a stable notification integer ID from medication ID and time
  int _generateNotificationId(String medId, String timeStr) {
    return (medId.hashCode ^ timeStr.hashCode) & 0x7FFFFFFF;
  }

  /// Schedules daily repeating medication reminders at exact scheduled times
  Future<void> scheduleMedicationReminder(Medication med, String timeStr) async {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final notificationId = _generateNotificationId(med.id, timeStr);
      final scheduledDate = _nextInstanceOfTime(hour, minute);

      final isCritical = med.isHighPriorityAlarm || med.requiresEyeDropProtocol;
      final channelId = isCritical ? channelCriticalId : channelRoutineId;
      final channelName = isCritical ? channelCriticalName : channelRoutineName;

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: isCritical ? Importance.max : Importance.high,
        priority: isCritical ? Priority.max : Priority.high,
        fullScreenIntent: isCritical,
        actions: const [
          AndroidNotificationAction('action_taken', 'Taken', showsUserInterface: true),
          AndroidNotificationAction('action_snooze', 'Snooze 10m', showsUserInterface: true),
          AndroidNotificationAction('action_skip', 'Skip', showsUserInterface: true),
        ],
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: isCritical ? '🚨 TIME FOR MEDICATION: ${med.name}' : '💊 Medication Reminder: ${med.name}',
        body: 'Take ${med.dosageAmount.toInt()} ${med.dosageUnit.name} (${med.strength}) ${med.instruction.name}.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: med.id,
      );

      debugPrint("Scheduled [${med.name}] at $timeStr (ID: $notificationId) repeats daily.");
    } catch (e) {
      debugPrint("Error scheduling notification for ${med.name}: $e");
    }
  }

  /// Cancels all scheduled reminders for a specific medication
  Future<void> cancelMedicationReminders(String medId, [List<String>? scheduledTimes]) async {
    try {
      if (scheduledTimes != null && scheduledTimes.isNotEmpty) {
        for (final timeStr in scheduledTimes) {
          final id = _generateNotificationId(medId, timeStr);
          await _notificationsPlugin.cancel(id: id);
        }
      }
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      for (final req in pending) {
        if (req.payload == medId) {
          await _notificationsPlugin.cancel(id: req.id);
        }
      }
      debugPrint("Cancelled notifications for Medication ID: $medId");
    } catch (e) {
      debugPrint("Error cancelling notifications for $medId: $e");
    }
  }

  /// Triggers an immediate emergency alarm notification
  Future<void> triggerEmergencyAlarmNotification(Medication med) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        channelCriticalId,
        channelCriticalName,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id: 999999,
        title: '🚨 CRITICAL MEDICAL ALARM',
        body: 'You have missed ${med.name} (${med.strength}). Take it immediately or contact your caregiver.',
        notificationDetails: notificationDetails,
        payload: med.id,
      );
    } catch (e) {
      debugPrint("Error triggering emergency notification: $e");
    }
  }

  /// Calculates the next occurrence of a given hour and minute in device local time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
