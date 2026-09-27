import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import '../../domain/models/medication.dart';

class InAppNotificationEvent {
  final String title;
  final String message;
  final String? payload;
  final bool isEyeDrop;
  final bool isCritical;
  final DateTime timestamp;

  const InAppNotificationEvent({
    required this.title,
    required this.message,
    this.payload,
    this.isEyeDrop = false,
    this.isCritical = false,
    required this.timestamp,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Stream for In-App floating notifications & dynamic island heads-up alerts
  final StreamController<InAppNotificationEvent> _inAppNotificationStream = StreamController<InAppNotificationEvent>.broadcast();
  Stream<InAppNotificationEvent> get inAppNotificationStream => _inAppNotificationStream.stream;

  // Android Notification Channels
  static const String channelCriticalId = 'medimind_critical_alarms';
  static const String channelCriticalName = 'Critical Medication Alarms';
  static const String channelCriticalDesc = 'High-priority alarms for life-critical medications and eye drops';

  static const String channelRoutineId = 'medimind_routine_reminders';
  static const String channelRoutineName = 'Routine Medication Reminders';
  static const String channelRoutineDesc = 'Reminders for daily oral supplements and vitamins';

  static const String channelTimerId = 'medimind_eyedrop_timer';
  static const String channelTimerName = 'Eye Drop Protocol Timer';
  static const String channelTimerDesc = 'Active alarms for punctal occlusion and 5-min eye drop intervals (works in background & app closed)';

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
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
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

      // 3. Create Android Channels with Max Priority & Sound
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        // Request notification & exact alarm permissions for Android 13/14+
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();

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
            enableVibration: true,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            channelTimerId,
            channelTimerName,
            description: channelTimerDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
        );
      }

      _initialized = true;
      debugPrint("NotificationService successfully initialized with timezone, background channels & in-app stream.");
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

      final isEyeDrop = med.category == MedCategory.eyeDrop || med.category == MedCategory.eyeOintment;
      final title = isEyeDrop
          ? '👁️ TIME FOR EYE DROPS: ${med.name}'
          : (isCritical ? '🚨 CRITICAL ALARM: ${med.name}' : '💊 Medication Reminder: ${med.name}');
      final eyeTargetStr = med.eyeTarget != null ? ' in ${med.eyeTarget}' : '';
      final body = isEyeDrop
          ? 'Instill ${med.dosageAmount.toInt()} drop(s)$eyeTargetStr. Remember 60s punctal occlusion!'
          : 'Take ${med.dosageAmount.toInt()} ${med.dosageUnit.name} (${med.strength}) ${med.instruction.name}.';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: isCritical ? Importance.max : Importance.high,
        priority: isCritical ? Priority.max : Priority.high,
        fullScreenIntent: isCritical,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        actions: const [
          AndroidNotificationAction('action_taken', 'Taken ✅', showsUserInterface: true),
          AndroidNotificationAction('action_snooze', 'Snooze 10m ⏰', showsUserInterface: true),
          AndroidNotificationAction('action_skip', 'Skip ⏭️', showsUserInterface: true),
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
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: med.id,
      );

      debugPrint("Scheduled [${med.name}] at $timeStr (ID: $notificationId) repeats daily (Closed app exact alarm).");
    } catch (e) {
      debugPrint("Error scheduling notification for ${med.name}: $e");
    }
  }

  /// Schedules an exact background alarm for the 5-Minute Eye Drop Interval (Works when app is closed)
  Future<void> scheduleEyeDropIntervalTimer({
    required String firstMedName,
    required String secondMedName,
    int gapMinutes = 5,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: gapMinutes));
      const int timerId = 888881;

      const androidDetails = AndroidNotificationDetails(
        channelTimerId,
        channelTimerName,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        actions: [
          AndroidNotificationAction('action_take_second', 'Instill Second Drop 👁️', showsUserInterface: true),
        ],
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        id: timerId,
        title: '👁️ NEXT EYE DROP READY: $secondMedName',
        body: '$gapMinutes minutes have elapsed since $firstMedName. Instill $secondMedName now without drug washout.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'eyedrop_gap_timer',
      );

      // Also trigger in-app notification event
      _inAppNotificationStream.add(InAppNotificationEvent(
        title: 'Eye Drop Interval Active ($gapMinutes min)',
        message: 'Timer started for $secondMedName. Your phone will ring when ready even if the app is closed.',
        isEyeDrop: true,
        timestamp: DateTime.now(),
      ));

      debugPrint("Scheduled Eye Drop Gap Timer ($gapMinutes min) for $secondMedName (ID: $timerId).");
    } catch (e) {
      debugPrint("Error scheduling eye drop interval timer: $e");
    }
  }

  /// Schedules an exact one-off snooze alarm
  Future<void> scheduleSnoozeAlarm({
    required Medication med,
    required int minutes,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
      final snoozeId = med.id.hashCode.abs() + 70000;

      const androidDetails = AndroidNotificationDetails(
        channelCriticalId,
        channelCriticalName,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        id: snoozeId,
        title: '⏰ SNOOZED: ${med.name}',
        body: 'Time to take your scheduled dose of ${med.name} (${med.strength}).',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: med.id,
      );

      _inAppNotificationStream.add(InAppNotificationEvent(
        title: 'Alarm Snoozed for $minutes min',
        message: 'Reminder for ${med.name} will trigger in $minutes minutes.',
        isCritical: med.isHighPriorityAlarm,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Error scheduling snooze alarm: $e');
    }
  }

  /// Schedules a 60-Second Punctal Occlusion Alarm (Works when app is closed)
  Future<void> schedulePunctalOcclusionTimer({int seconds = 60}) async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
      const int punctalId = 888882;

      const androidDetails = AndroidNotificationDetails(
        channelTimerId,
        channelTimerName,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        id: punctalId,
        title: '⏱️ PUNCTAL OCCLUSION COMPLETE',
        body: '$seconds seconds elapsed! You can now safely release tear-duct pressure.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'punctal_timer',
      );

      _inAppNotificationStream.add(InAppNotificationEvent(
        title: 'Punctal Occlusion Timer ($seconds s)',
        message: 'Keep tear duct pressed. Phone will chime when complete.',
        isEyeDrop: true,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint("Error scheduling punctal occlusion timer: $e");
    }
  }

  /// Schedules a 10-Minute Smart Snooze Reminder (Works when app is closed)
  Future<void> scheduleSmartSnooze({required Medication med, int snoozeMinutes = 10}) async {
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: snoozeMinutes));
      final snoozeId = (_generateNotificationId(med.id, 'snooze') + 1000) & 0x7FFFFFFF;

      const androidDetails = AndroidNotificationDetails(
        channelCriticalId,
        channelCriticalName,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        actions: [
          AndroidNotificationAction('action_taken', 'Taken ✅', showsUserInterface: true),
          AndroidNotificationAction('action_snooze', 'Snooze 10m ⏰', showsUserInterface: true),
        ],
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.zonedSchedule(
        id: snoozeId,
        title: '⏰ SNOOZED DOSE DUE: ${med.name}',
        body: 'Your $snoozeMinutes-minute snooze has ended. Please take your prescribed dose now.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: med.id,
      );

      _inAppNotificationStream.add(InAppNotificationEvent(
        title: 'Snoozed for $snoozeMinutes Minutes',
        message: 'We will remind you for ${med.name} at ${DateFormat.jm().format(DateTime.now().add(Duration(minutes: snoozeMinutes)))}.',
        isCritical: true,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint("Error scheduling snooze: $e");
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

  /// Cancels all active and scheduled notifications across all channels
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint("Cancelled all scheduled notifications.");
    } catch (e) {
      debugPrint("Error cancelling all notifications: $e");
    }
  }

  /// Emits an In-App notification event directly to foreground listeners
  void showInAppBanner({
    required String title,
    required String message,
    bool isEyeDrop = false,
    bool isCritical = false,
    String? payload,
  }) {
    _inAppNotificationStream.add(InAppNotificationEvent(
      title: title,
      message: message,
      isEyeDrop: isEyeDrop,
      isCritical: isCritical,
      payload: payload,
      timestamp: DateTime.now(),
    ));
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
