class EyeDropProtocolSession {
  final String id;
  final String medicationId;
  final String medicationName;
  final String targetEye; // "Left Eye (OS)", "Right Eye (OD)", "Both Eyes (OU)"
  final DateTime startTime;
  final int requiredGapMinutes; // e.g. 5, 10
  final bool contactLensRemoved;
  final bool isCompleted;

  EyeDropProtocolSession({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.targetEye,
    required this.startTime,
    this.requiredGapMinutes = 5,
    this.contactLensRemoved = true,
    this.isCompleted = false,
  });

  DateTime get nextSafeDropTime => startTime.add(Duration(minutes: requiredGapMinutes));

  bool get canAdministerNext => DateTime.now().isAfter(nextSafeDropTime);

  int get secondsRemaining {
    final diff = nextSafeDropTime.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'targetEye': targetEye,
      'startTime': startTime.toIso8601String(),
      'requiredGapMinutes': requiredGapMinutes,
      'contactLensRemoved': contactLensRemoved,
      'isCompleted': isCompleted,
    };
  }

  factory EyeDropProtocolSession.fromJson(Map<String, dynamic> json) {
    return EyeDropProtocolSession(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      targetEye: json['targetEye'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      requiredGapMinutes: json['requiredGapMinutes'] as int? ?? 5,
      contactLensRemoved: json['contactLensRemoved'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
