enum LogStatus {
  taken,
  skipped,
  snoozed,
  delayed,
  missed,
}

class MedicationLog {
  final String id;
  final String medicationId;
  final String medicationName;
  final String scheduledTime; // "HH:mm"
  final DateTime timestamp;
  final LogStatus status;
  final String? skipReason;
  final String? notes;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.timestamp,
    required this.status,
    this.skipReason,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': scheduledTime,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
      'skipReason': skipReason,
      'notes': notes,
    };
  }

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      scheduledTime: json['scheduledTime'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: LogStatus.values[json['status'] as int? ?? 0],
      skipReason: json['skipReason'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
