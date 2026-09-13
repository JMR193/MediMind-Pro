enum TaskerAction {
  snoozeAllUntilHome,
  nightQuietModeOverride,
  triggerCriticalAlarm,
  logDoseExternal,
  requestRefillWebhook,
}

class TaskerRule {
  final String id;
  final String title;
  final String description;
  final TaskerAction action;
  final bool isEnabled;
  final String intentActionName; // e.g. "com.medimind.TASKER_SNOOZE_HOME"
  final DateTime? lastTriggered;

  TaskerRule({
    required this.id,
    required this.title,
    required this.description,
    required this.action,
    this.isEnabled = true,
    required this.intentActionName,
    this.lastTriggered,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'action': action.index,
      'isEnabled': isEnabled,
      'intentActionName': intentActionName,
      'lastTriggered': lastTriggered?.toIso8601String(),
    };
  }

  factory TaskerRule.fromJson(Map<String, dynamic> json) {
    return TaskerRule(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      action: TaskerAction.values[json['action'] as int? ?? 0],
      isEnabled: json['isEnabled'] as bool? ?? true,
      intentActionName: json['intentActionName'] as String,
      lastTriggered: json['lastTriggered'] != null ? DateTime.parse(json['lastTriggered'] as String) : null,
    );
  }
}
