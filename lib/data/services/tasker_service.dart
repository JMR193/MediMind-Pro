import 'package:flutter/foundation.dart';
import '../../domain/models/tasker_event.dart';

class TaskerService {
  List<TaskerRule> getDefaultRules() {
    return [
      TaskerRule(
        id: 'rule_1',
        title: 'Snooze Until Home',
        description: 'Auto-snoozes medication alarms until phone connects to Home Wi-Fi or GPS zone.',
        action: TaskerAction.snoozeAllUntilHome,
        intentActionName: 'com.medimind.TASKER_SNOOZE_HOME',
      ),
      TaskerRule(
        id: 'rule_2',
        title: 'Night Override Critical Alarm',
        description: 'Overrides Do Not Disturb mode for essential cardiac & insulin medications.',
        action: TaskerAction.nightQuietModeOverride,
        intentActionName: 'com.medimind.TASKER_NIGHT_OVERRIDE',
      ),
      TaskerRule(
        id: 'rule_3',
        title: 'Smart Dispenser Webhook Trigger',
        description: 'Receives external webhook signal when automatic pill dispenser door opens.',
        action: TaskerAction.logDoseExternal,
        intentActionName: 'com.medimind.TASKER_SMART_DISPENSER',
      ),
      TaskerRule(
        id: 'rule_4',
        title: 'Auto Refill Doctor Webhook',
        description: 'Sends automated refill request email/SMS to pharmacy when stock drops below threshold.',
        action: TaskerAction.requestRefillWebhook,
        intentActionName: 'com.medimind.TASKER_REFILL_ALERT',
      ),
    ];
  }

  Future<void> simulateIntentTrigger(TaskerRule rule) async {
    debugPrint("Tasker Intent Fired: ${rule.intentActionName} -> ${rule.title}");
  }
}
